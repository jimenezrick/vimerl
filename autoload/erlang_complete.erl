#!/usr/bin/env escript

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2010 Pawel 'kTT' Salata
% Copyright 2011 Ricardo Catalinas Jimenéz
%
% This file is part of Vimerl.
%
% Vimerl is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Vimerl is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Vimerl.  If not, see <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
