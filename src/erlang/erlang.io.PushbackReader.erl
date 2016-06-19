-module('erlang.io.PushbackReader').

-include("clojerl.hrl").

-behaviour('clojerl.Closeable').
-behaviour('clojerl.Stringable').
-behaviour('clojerl.IReader').

-export([new/1, at_line_start/1]).
-export([ start_link/1
        , init/1
        , loop/1
        , skip/3
        ]).

-export(['clojerl.Closeable.close'/1]).
-export([ 'clojerl.IReader.read'/1
        , 'clojerl.IReader.read'/2
        , 'clojerl.IReader.read_line'/1
        , 'clojerl.IReader.skip'/2
        , 'clojerl.IReader.unread'/2
        ]).
-export(['clojerl.Stringable.str'/1]).

-type type() :: #?TYPE{data :: pid()}.

-spec new('clojerl.IReader':type()) -> type().
new(Reader) ->
  #?TYPE{data = start_link(Reader)}.

-spec at_line_start('clojerl.IReader':type()) -> type().
at_line_start(#?TYPE{name = ?M, data = Pid}) ->
  case send_command(Pid, at_line_start) of
    {error, _} -> error(<<"Can't determine if at line start">>);
    Result     -> Result
  end.

%%------------------------------------------------------------------------------
%% Protocols
%%------------------------------------------------------------------------------

'clojerl.Closeable.close'(#?TYPE{name = ?M, data = Pid}) ->
  case send_command(Pid, close) of
    {error, _} -> error(<<"Couldn't close clojerl.PushbackReader">>);
    _          -> undefined
  end.

'clojerl.Stringable.str'(#?TYPE{name = ?M, data = Pid}) ->
  TypeName = atom_to_binary(?MODULE, utf8),
  <<"<", PidStr/binary>> = erlang:list_to_binary(erlang:pid_to_list(Pid)),
  <<"#<", TypeName/binary, " ", PidStr/binary>>.

'clojerl.IReader.read'(#?TYPE{name = ?M, data = Pid}) ->
  io:get_chars(Pid, "", 1).

'clojerl.IReader.read'(#?TYPE{name = ?M, data = Pid}, Length) ->
  io:get_chars(Pid, "", Length).

'clojerl.IReader.read_line'(#?TYPE{name = ?M, data = Pid}) ->
  io:request(Pid, {get_line, unicode, ""}).

'clojerl.IReader.skip'(#?TYPE{name = ?M, data = Pid}, Length) ->
  io:request(Pid, {get_until, unicode, "", ?MODULE, skip, [Length]}).

'clojerl.IReader.unread'(#?TYPE{name = ?M, data = Pid} = Reader, Str) ->
  case send_command(Pid, {unread, Str}) of
    {error, _} -> error(<<"Couldn't close clojerl.StringReader">>);
    ok -> Reader
  end.

%%------------------------------------------------------------------------------
%% IO server
%%
%% Implementation of a subset of the io protocol in order to only support
%% writing operations.
%%------------------------------------------------------------------------------

-type state() :: #{ reader => 'clojerl.IReader':type()
                  , buffer => binary()
                  }.

-spec send_command(pid(), any()) -> any().
send_command(Pid, Cmd) ->
  Ref = erlang:monitor(process, Pid),
  Pid ! {self(), Ref, Cmd},
  receive
    {Ref, Result} ->
      erlang:demonitor(Ref, [flush]),
      Result;
    {'DOWN', Ref, _, _, _} ->
      {error, terminated}
  end.

-spec start_link('clojerl.IReader':type()) -> pid().
start_link(Reader) ->
  spawn_link(?MODULE, init, [Reader]).

-spec init('clojerl.IReader':type()) -> no_return().
init(Reader) ->
  State = #{ reader        => Reader
           , buffer        => <<>>
           , at_line_start => true
           },
  ?MODULE:loop(State).

-spec loop(state()) -> ok.
loop(State) ->
  receive
    {io_request, From, ReplyAs, Request} ->
      {Reply, NewState} = request(Request, State),
      reply(From, ReplyAs, Reply),
      ?MODULE:loop(NewState);
    {From, Ref, close} ->
      From ! {Ref, ok};
    {From, Ref, {unread, Str}} ->
      NewState = unread(State, Str),
      From ! {Ref, ok},
      ?MODULE:loop(NewState);
    {From, Ref, at_line_start} ->
      #{at_line_start := AtLineStart} = State,
      From ! {Ref, AtLineStart},
      ?MODULE:loop(State);
    _Unknown ->
      ?MODULE:loop(State)
  end.

reply(From, ReplyAs, Reply) ->
  From ! {io_reply, ReplyAs, Reply}.

request({get_chars, Encoding, _Prompt, N}, State) ->
  maybe_encode_result(Encoding, get_chars(N, State));
request({get_line, Encoding, _Prompt}, State) ->
  maybe_encode_result(Encoding, get_line(State));
request({get_until, Encoding, _Prompt, Module, Function, Xargs}, State) ->
  maybe_encode_result(Encoding, get_until(Module, Function, Xargs, State));
request(_Other, State) ->
  {{error, request}, State}.

-spec maybe_encode_result(atom(), {term(), state()}) -> {term(), state()}.
maybe_encode_result(Encoding, {Result, NewState}) when is_binary(Result) ->
  { unicode:characters_to_binary(Result, unicode, Encoding)
  , update_at_line_start(Result, NewState)
  };
maybe_encode_result(_, X) ->
  X.

-spec update_at_line_start(binary(), state()) -> state().
update_at_line_start(Result, State) ->
  State#{at_line_start := clj_utils:ends_with(Result, <<"\n">>)}.

-spec get_chars(integer(), state()) -> {binary() | eof, binary()}.
get_chars(N, #{reader := Reader, buffer := <<>>} = State) ->
  {'clojerl.IReader':read(Reader, N), State};
get_chars(1, #{buffer := <<Ch/utf8, Str/binary>>} = State) ->
  {<<Ch/utf8>>, State#{buffer => Str}};
get_chars(1, #{reader := Reader} = State) ->
  {'clojerl.IReader':read(Reader, 1), State};
get_chars(N, State) ->
  do_get_chars(N, State, <<>>).

-spec do_get_chars(integer(), state(), binary()) -> {binary(), state()}.
do_get_chars(0, State, Result) ->
  {Result, State};
do_get_chars(N, #{buffer := <<Ch/utf8, Rest/binary>>} = State, Result) ->
  do_get_chars(N - 1, State#{buffer := Rest}, <<Result/binary, Ch/utf8>>);
do_get_chars(N, #{reader := Reader} = State, Result) ->
  case 'clojerl.IReader':read(Reader, N) of
    eof when Result =:= <<>> ->
      {eof, State};
    Str ->
      {<<Result/binary, Str/binary>>, State}
  end.

-spec get_line(state()) -> {binary() | eof, state()}.
get_line(State) ->
  do_get_line(State, <<>>).

-spec do_get_line(state(), binary()) -> {binary() | eof, state()}.
do_get_line(#{buffer := <<"\r\n"/utf8, RestStr/binary>>} = State, Result) ->
  {Result, State#{buffer := RestStr}};
do_get_line(#{buffer := <<"\n"/utf8, RestStr/binary>>} = State, Result) ->
  {Result, State#{buffer := RestStr}};
do_get_line(#{buffer := <<"\r"/utf8, RestStr/binary>>} = State, Result) ->
  {Result, State#{buffer := RestStr}};
do_get_line(#{buffer := <<Ch/utf8, RestStr/binary>>} = State, Result) ->
  do_get_line(State#{buffer := RestStr}, <<Result/binary, Ch/utf8>>);
do_get_line(#{reader := Reader} = State, Result) ->
  case 'clojerl.IReader':read_line(Reader) of
    eof when Result =:= <<>> ->
      {eof, State};
    Str ->
      {<<Result/binary, Str/binary>>, State}
  end.

-spec get_until(module(), atom(), list(), term()) ->
  {term(), binary()}.
get_until(Module, Function, XArgs, State) ->
  case apply(Module, Function, [State, undefined | XArgs]) of
    {done, Result, NewStr} -> {Result, NewStr};
    {more, NewState} -> get_until(Module, Function, XArgs, NewState)
  end.

-spec skip(state() | {cont, integer(), state()}, term(), integer()) ->
  {more, {cont, integer(), binary()}} | {done, integer(), binary()}.
skip(State, _Data, Length) when is_map(State) ->
  {more, {cont, Length, State}};
skip({cont, 0, State}, _Data, Length) ->
  {done, Length, State};
skip({cont, Length, #{buffer := <<>>} = State}, _Data, _Length) ->
  #{reader := Reader} = State,
  {done, 'clojerl.IReader':skip(Reader, Length), State};
skip( {cont, Length, #{buffer := <<_/utf8, RestStr/binary>>} = State}
    , _Data
    , _Length
    ) ->
  {more, {cont, Length - 1, State#{buffer := RestStr}}}.

-spec unread(state(), binary()) -> ok.
unread(State = #{buffer := Buffer}, Str) ->
  State#{buffer := <<Str/binary, Buffer/binary>>}.
