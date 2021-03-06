%% @doc Clojure multimethod.
%%
%% Implements the creation and update of a multimethod's dispatch map.
%% The dispatch map is kept in its own BEAM module so that it can be
%% updated at runtime independently. This eliminates the risk of
%% killing processes that might be currently using the module where
%% the dispatch map is kept.
%%
%% There is some name mangling when generating the name of the module
%% for the dispatch map to avoid using invalid filename characters.
%%
%% The code in this module should only be used by the multimethod
%% related functions in the `clojure.core' namespace.
-module(clj_multimethod).

-include("clojerl.hrl").

-export([ init/1
        , is_init/1
        , get_method/2
        , get_method/4
        , get_method_table/1
        , get_dispatch_fun/1
        , add_method/3
        , remove_all/1
        , remove_method/2
        ]).

-define(DISPATCH_MAP_VAR, 'dispatch-map-var').
-define(DISPATCH_FN_VAR, 'dispatch-fn-var').

%%------------------------------------------------------------------------------
%% API
%%------------------------------------------------------------------------------

%% @private
-spec init('clojerl.Symbol':type()) -> map().
init(MultiFnSym0) ->
  DispatchMapVar = build_var(MultiFnSym0, ?DISPATCH_MAP_VAR),
  DispatchFnVar  = build_var(MultiFnSym0, ?DISPATCH_FN_VAR),
  EmptyMap       = 'clojerl.Map':?CONSTRUCTOR([]),
  Meta           = #{ ?DISPATCH_MAP_VAR => DispatchMapVar
                    , ?DISPATCH_FN_VAR  => DispatchFnVar
                    },
  MultiFnSym1    = clj_rt:with_meta(MultiFnSym0, Meta),
  ok             = generate_module(MultiFnSym1, EmptyMap),
  #{ 'init-meta'         => Meta
   , 'dispatch-map-name' => var_symbol(DispatchMapVar)
   , 'dispatch-fn-name'  => var_symbol(DispatchFnVar)
   }.

%% @private
-spec is_init('clojerl.Symbol':type()) -> boolean().
is_init(MultiFnSym) ->
  case 'clojerl.Namespace':find_var(MultiFnSym) of
    ?NIL -> false;
    Var  -> clj_rt:get('clojerl.Var':meta(Var), 'multi-method')
  end.

%% @private
-spec get_dispatch_fun('clojerl.Var':type()) -> any().
get_dispatch_fun(MultiFnVar) ->
  DispatchFnVar = var_meta(MultiFnVar, ?DISPATCH_FN_VAR),
  'clojerl.IFn':apply(DispatchFnVar, []).

%% @private
-spec get_method('clojerl.Var':type(), any()) -> any().
get_method(Var, Value) ->
  get_method(Var, Value, default, ?NIL).

%% @private
-spec get_method('clojerl.Var':type(), any(), any(), map() | ?NIL) -> any().
get_method(MultiFnVar, Value, Default, _Hierarchy) ->
  Map = dispatch_map(MultiFnVar),
  case clj_rt:get(Map, Value) of
    ?NIL -> clj_rt:get(Map, Default);
    X -> X
  end.

%% @private
-spec get_method_table('clojerl.Var':type()) -> any().
get_method_table(MultiFnVar) ->
  dispatch_map(MultiFnVar).

%% @private
-spec add_method('clojerl.Var':type(), any(), any()) -> 'clojerl.Var':type().
add_method(MultiFnVar, DispatchValue, Method0) ->
  Assoc  = fun clj_rt:assoc/3,
  %% When Method is a var we need to make sure it's not
  %% marked as a fake function.
  Method = case clj_rt:'var?'(Method0) of
             true  -> 'clojerl.Var':fake_fun(Method0, false);
             false -> Method0
           end,
  Args   = [DispatchValue, Method],
  update_dispatch_map(MultiFnVar, Assoc, Args).

%% @private
-spec remove_all('clojerl.Var':type()) -> 'clojerl.Var':type().
remove_all(MultiFnVar) ->
  Fun    = fun(_) -> clj_rt:hash_map([]) end,
  update_dispatch_map(MultiFnVar, Fun, []).

%% @private
-spec remove_method('clojerl.Var':type(), any()) -> 'clojerl.Var':type().
remove_method(MultiFnVar, DispatchValue) ->
  Dissoc = fun clj_rt:dissoc/2,
  update_dispatch_map(MultiFnVar, Dissoc, [DispatchValue]).

%%------------------------------------------------------------------------------
%% Internal functions
%%------------------------------------------------------------------------------

-spec build_var( 'clojerl.INamed':type()
               , ?DISPATCH_MAP_VAR | ?DISPATCH_FN_VAR
               ) ->
  'clojerl.Var':type().
build_var(VarOrSymbol, ?DISPATCH_MAP_VAR) ->
  Ns      = var_namespace(VarOrSymbol),
  Name    = clj_rt:name(VarOrSymbol),
  MapNs0  = <<Ns/binary, ".", Name/binary, "__dispatch__">>,
  MapNs   = munge(MapNs0),
  'clojerl.Var':?CONSTRUCTOR(MapNs, <<"map">>);
build_var(VarOrSymbol, ?DISPATCH_FN_VAR) ->
  Ns      = var_namespace(VarOrSymbol),
  Prefix  = clj_rt:name(VarOrSymbol),
  VarName = <<Prefix/binary, "__dispatch-fn__">>,
  'clojerl.Var':?CONSTRUCTOR(Ns, VarName).

-spec var_namespace('clojerl.INamed':type()) -> binary().
var_namespace(VarOrSymbol) ->
  case clj_rt:namespace(VarOrSymbol) of
    ?NIL ->
      CurrentNs = 'clojerl.Namespace':current(),
      'clojerl.Namespace':str(CurrentNs);
    X -> X
  end.

-spec var_symbol('clojerl.Var':type()) -> 'clojerl.Symbol':type().
var_symbol(Var) ->
  Name = clj_rt:name(Var),
  Ns   = clj_rt:namespace(Var),
  clj_rt:symbol(Ns, Name).

-spec update_dispatch_map('clojerl.Var':type(), function(), [any()]) -> any().
update_dispatch_map(MultiFnVar, Fun, Args) ->
  Map0           = dispatch_map(MultiFnVar),
  Map            = apply(Fun, [Map0 | Args]),
  ok             = generate_module(MultiFnVar, Map),
  MultiFnVar.

-spec var_meta('clojerl.Var':type(), atom()) -> 'clojerl.Var':type().
var_meta(MultiFnVar, Key) ->
  Meta = clj_rt:meta(MultiFnVar),
  clj_rt:get(Meta, Key).

-spec dispatch_map('clojerl.Var':type()) -> any().
dispatch_map(MultiFnVar) ->
  'clojerl.Var':deref(var_meta(MultiFnVar, ?DISPATCH_MAP_VAR)).

-spec generate_module('clojerl.Var':type(), any()) -> ok.
generate_module(MultiFnSym, Map) ->
  DispatchMapVar = var_meta(MultiFnSym, ?DISPATCH_MAP_VAR),
  Module = 'clojerl.Var':module(DispatchMapVar),
  clj_module:ensure_loaded(<<>>, Module),

  generate_dispatch_map(DispatchMapVar, Module, Map),

  CljModule = clj_module:get_module(Module),
  clj_compiler:module(CljModule),

  ok.

-spec generate_dispatch_map('clojerl.Var':type(), any(), any()) -> ok.
generate_dispatch_map(DispatchMapVar, Module, Map) ->
  ValName   = 'clojerl.Var':val_function(DispatchMapVar),
  ValAst    = cerl:abstract(Map),
  ValFunAst = clj_emitter:function_form(ValName, [], [], ValAst),

  clj_module:add_mappings([DispatchMapVar], Module),
  clj_module:add_functions([ValFunAst], Module),
  clj_module:add_exports([{ValName, 0}], Module),

  ok.

-define( REPLACE
       , #{ <<"?">> => <<"__QUESTION__">>
          , <<"*">> => <<"__ASTERISK__">>
          , <<"|">> => <<"__PIPE__">>
          , <<"<">> => <<"__LT__">>
          , <<">">> => <<"__GT__">>
          , <<":">> => <<"__COLON__">>
          , <<"\"">> => <<"__DOUBLE_QUOTE__">>
          , <<"/">> => <<"__SLASH__">>
          , <<"\\">> => <<"__BACKSLASH__">>
          }
       ).

-spec munge(binary()) -> binary().
munge(X) ->
  maps:fold(fun replace_char/3, X, ?REPLACE).

-spec replace_char(binary(), binary(), binary()) -> binary().
replace_char(K, V, X) ->
  binary:replace(X, K, V, [global]).
