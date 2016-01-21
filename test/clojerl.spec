%% Specific modules to include in cover.
{
  incl_mods,
  [
    'clj_analyzer',
    'clj_compiler',
    'clj_core',
    'clj_emitter',
    'clj_env',
    'clj_namespace',
    'clj_reader',
    'clj_utils',
    'clojerl',
    'clojerl.Boolean',
    'clojerl.Counted',
    'clojerl.IColl',
    'clojerl.IDeref',
    'clojerl.ILookup',
    'clojerl.IMeta',
    'clojerl.ISeq',
    'clojerl.Integer',
    'clojerl.Keyword',
    'clojerl.List',
    'clojerl.Map',
    'clojerl.Named',
    'clojerl.Seqable',
    'clojerl.Set',
    'clojerl.String',
    'clojerl.Stringable',
    'clojerl.Symbol',
    'clojerl.Var',
    'clojerl.Vector',
    'clojerl.erlang.Atom',
    'clojerl.erlang.List',
    'clojerl.erlang.Map',
    'clojerl.nil',
    'clojerl.protocol',
    'cover_report',

  ]
}.
%% Export coverage data for jenkins.
{export, "../logs/cover.data"}.
