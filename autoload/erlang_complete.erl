#!/usr/bin/env escript

main([ModuleName]) ->
    code:add_path("ebin"),
    case file:consult("rebar.config") of
        {ok, Terms} ->
            RebarDeps = proplists:get_value(deps_dir, Terms, "deps"),
            code:add_paths(filelib:wildcard(RebarDeps ++ "/*/ebin"));
        _ ->
            ok
    end,
    Module = erlang:list_to_atom(ModuleName),
    try Module:module_info(exports) of
        Functions ->
            lists:foreach(
                fun({FunctionName, ArgumentsCount}) ->
                        io:format("~s/~B~n", [FunctionName, ArgumentsCount])
                end,
                Functions)
    catch
        error:undef ->
            bad_module
    end;
main(_) ->
    bad_module.
