#!/usr/bin/env escript

main([File]) ->
    Dir = get_root(filename:dirname(File)),
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
            {i, Dir ++ "/../../../include"},
            {i, Dir ++ "/lib"},
            {i, Dir ++ "/deps"}],
    RebarFile = rebar_file(Dir),
    RebarOpts = rebar_opts(RebarFile),
    Libs = filelib:wildcard(filename:join(Dir, "{lib,deps}/*/ebin")),
    [ true = code:add_patha(Ebin) || Ebin <- Libs ],
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

get_root(Dir) ->
    Path = filename:split(filename:absname(Dir)),
    filename:join(get_root(lists:reverse(Path), Path)).

get_root([], Path) ->
    Path;
get_root(["src" | Tail], _Path) ->
    lists:reverse(Tail);
get_root([_ | Tail], Path) ->
    get_root(Tail, Path).

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
            IncludeDeps = {i, RebarDepsDir},
            proplists:get_value(erl_opts, Terms, []) ++ [IncludeDeps];
        {error, _} when RebarFile == "rebar.config" ->
            [];
        {error, _} ->
            rebar_opts("rebar.config")
    end.
