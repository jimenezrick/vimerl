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
    RebarOpts = rebar_opts(RebarFile),
    EmakefileOpts = emakefile_opts(File, 'Emakefile'),
    code:add_patha(filename:absname("ebin")),
    compile:file(File, Defs ++ RebarOpts ++ EmakefileOpts);
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

emakefile_opts(File, Emakefile) ->
    Mods = [filename:rootname(File, ".erl")],
    [{_, EmakeOpts}] = get_opts_from_emakefile(Mods, Emakefile, []),
    EmakeOpts.

get_opts_from_emakefile(Mods,Emakefile,Opts) ->
    case file:consult(Emakefile) of
    {ok,Emake} ->
        Modsandopts = transform(Emake,Opts,[],[]),
        ModStrings = [coerce_2_list(M) || M <- Mods],
        get_opts_from_emakefile2(Modsandopts,ModStrings,Opts,[]); 
    {error,enoent} ->
        [{Mods, Opts}];
    {error,Other} ->
        io:format("make: Trouble reading 'Emakefile':~n~tp~n",[Other]),
        error
    end.

get_opts_from_emakefile2([{MakefileMods,O}|Rest],Mods,Opts,Result) ->
    case members(Mods,MakefileMods,[],Mods) of
    {[],_} -> 
        get_opts_from_emakefile2(Rest,Mods,Opts,Result);
    {I,RestOfMods} ->
        get_opts_from_emakefile2(Rest,RestOfMods,Opts,[{I,O}|Result])
    end;
get_opts_from_emakefile2([],[],_Opts,Result) ->
    Result;
get_opts_from_emakefile2([],RestOfMods,Opts,Result) ->
    [{RestOfMods,Opts}|Result].

transform([{Mod,ModOpts}|Emake],Opts,Files,Already) ->
    case expand(Mod,Already) of
    [] -> 
        transform(Emake,Opts,Files,Already);
    Mods -> 
        transform(Emake,Opts,[{Mods,ModOpts++Opts}|Files],Mods++Already)
    end;
transform([Mod|Emake],Opts,Files,Already) ->
    case expand(Mod,Already) of
    [] -> 
        transform(Emake,Opts,Files,Already);
    Mods ->
        transform(Emake,Opts,[{Mods,Opts}|Files],Mods++Already)
    end;
transform([],_Opts,Files,_Already) ->
    lists:reverse(Files).

expand(Mod,Already) when is_atom(Mod) ->
    expand(atom_to_list(Mod),Already);
expand(Mods,Already) when is_list(Mods), not is_integer(hd(Mods)) ->
    lists:concat([expand(Mod,Already) || Mod <- Mods]);
expand(Mod,Already) ->
    case lists:member($*,Mod) of
    true -> 
        Fun = fun(F,Acc) -> 
              M = filename:rootname(F),
              case lists:member(M,Already) of
                  true -> Acc;
                  false -> [M|Acc]
              end
          end,
        lists:foldl(Fun, [], filelib:wildcard(Mod++".erl"));
    false ->
        Mod2 = filename:rootname(Mod, ".erl"),
        case lists:member(Mod2,Already) of
        true -> [];
        false -> [Mod2]
        end
    end.
    
members([H|T],MakefileMods,I,Rest) ->
    case lists:member(H,MakefileMods) of
    true ->
        members(T,MakefileMods,[H|I],lists:delete(H,Rest));
    false ->
        members(T,MakefileMods,I,Rest)
    end;
members([],_MakefileMods,I,Rest) ->
    {I,Rest}.

coerce_2_list(X) when is_atom(X) ->
    atom_to_list(X);
coerce_2_list(X) ->
    X.

rebar_opts(RebarFile) ->
    Dir = get_root(filename:dirname(RebarFile)),
    case file:consult(RebarFile) of
        {ok, Terms} ->
            RebarLibDirs = proplists:get_value(lib_dirs, Terms, []),
            lists:foreach(
                fun(LibDir) ->
                        code:add_pathsa(filelib:wildcard(LibDir ++ "/*/ebin"))
                end, RebarLibDirs),
            RebarDepsDir = proplists:get_value(deps_dir, Terms, "deps"),
            code:add_pathsa(filelib:wildcard(RebarDepsDir ++ "/*/ebin")),
            IncludeDeps = {i, filename:join(Dir, RebarDepsDir)},
            proplists:get_value(erl_opts, Terms, []) ++ [IncludeDeps];
        {error, _} when RebarFile == "rebar.config" ->
            [];
        {error, _} ->
            rebar_opts("rebar.config")
    end.

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
