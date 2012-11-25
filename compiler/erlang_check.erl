#!/usr/bin/env escript

main([File]) ->
    Dir = filename:dirname(File),
    Defs = [strong_validation,
            warn_export_all,
            warn_export_vars,
            warn_shadow_vars,
            warn_obsolete_guard,
            warn_unused_import,
            report,
            {i, Dir ++ "/include"},
            {i, Dir ++ "/../include"},
            {i, Dir ++ "/../../include"},
            {i, Dir ++ "/../../../include"}],
    RebarFile = rebar_file(Dir),
    RebarOpts = rebar_opts(RebarFile),
    code:add_patha(filename:absname("ebin")),
    compile:file(File, Defs ++ RebarOpts);
main(_) ->
    io:format("Usage: ~s <file>~n", [escript:script_name()]),
    halt(1).

rebar_file(Dir) ->
    DirList = filename:split(Dir),
    case lists:last(DirList) of
        "test" ->
            "rebar.test.config";
        _ ->
            "rebar.config"
    end.

rebar_opts(RebarFile) ->
   case file:consult(RebarFile) of
        {ok, Terms} ->
            RebarLibDirs = proplists:get_value(lib_dirs, Terms, []),
            lists:foreach(
                fun(LibDir) ->
                        code:add_pathsa(filelib:wildcard(LibDir ++ "/*/ebin"))
                end, RebarLibDirs),
            RebarDepsDir = proplists:get_value(deps_dir, Terms, "deps"),
            code:add_pathsa(filelib:wildcard(RebarDepsDir ++ "/*/ebin")),
            proplists:get_value(erl_opts, Terms, []);
        {error, _} when RebarFile == "rebar.config" ->
            [];
        {error, _} ->
            rebar_opts("rebar.config")
    end.

