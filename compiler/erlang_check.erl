#!/usr/bin/env escript

main([Filename]) ->
    Directory = filename:dirname(Filename),
    Defaults = [strong_validation,
        warn_export_all,
        warn_export_vars,
        warn_shadow_vars,
        warn_obsolete_guard,
        warn_unused_import,
        report,
        {i, Directory ++ "/include"},
        {i, Directory ++ "/../include"},
        {d, 'TEST'}, {d, 'DEBUG'}],
    case file:consult("rebar.config") of
        {ok, Terms} ->
            RebarOpts = proplists:get_value(erl_opts, Terms, []),
            compile:file(Filename, Defaults ++ RebarOpts);
        _ ->
            compile:file(Filename, Defaults)
    end.
