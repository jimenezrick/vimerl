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
            {i, Dir ++ "/include"}],
    RebarFile = rebar_file(Dir),
    RebarOpts0 = rebar_opts(filename:join(Dir, RebarFile)),
    RebarOpts = case lists:reverse(filename:split(Dir)) of
                    [_, "apps" | AppsRootRev] ->
                        %% We are only a subapp!
                        AppsRoot = filename:join(lists:reverse(AppsRootRev)),
                        AppsDir = filename:join(lists:reverse(["apps" | AppsRootRev])),
                        code:add_pathsa(filelib:wildcard(filename:join([AppsDir, "*", "ebin"]))),
                        [{i, AppsDir} | RebarOpts0]
                        ++ rebar_opts(filename:join(AppsRoot, rebar_file(AppsRoot)));
                    _ ->
                        RebarOpts0
                end,

    code:add_patha(filename:absname("ebin")),
    compile:file(filename:absname(File), Defs ++ RebarOpts);
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
    Dir = get_root(filename:dirname(RebarFile)),
    case file:consult(RebarFile) of
        {ok, Terms} ->
            RebarLibDirs = proplists:get_value(lib_dirs, Terms, []),
            lists:foreach(
                fun(LibDir) ->
                        code:add_pathsa(filelib:wildcard(filename:join([LibDir, "*", "ebin"])))
                end, RebarLibDirs),
            RebarDepsDir = proplists:get_value(deps_dir, Terms, "deps"), 
            IncludeDeps = process_deps(filename:join(Dir, RebarDepsDir)),
            proplists:get_value(erl_opts, Terms, []) ++ IncludeDeps;
        {error, _} when RebarFile == "rebar.config" ->
            [];
        {error, _} ->
            rebar_opts("rebar.config")
    end.

process_deps(DepsDir) ->
    code:add_pathsa(filelib:wildcard(filename:join([DepsDir, "*", "ebin"]))),
    [{i, DepsDir} |
     lists:flatmap(
       fun(SubAppsDir) ->
               process_deps(SubAppsDir)
       end, filelib:wildcard(filename:join(DepsDir, "*/apps")))].

get_root(Dir) ->
    Path = filename:split(filename:absname(Dir)),
    filename:join(get_root(lists:reverse(Path), Path)).

get_root([], Path) ->
    Path;
get_root(["src" | Tail], _Path) ->
    lists:reverse(Tail);
get_root(["test" | Tail], _Path) ->
    lists:reverse(Tail);
get_root([_ | Tail], Path) ->
    get_root(Tail, Path).
