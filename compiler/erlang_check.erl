#!/usr/bin/env escript

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2010 Pawel 'kTT' Salata
% Copyright 2011 Ricardo Catalinas Jiménez
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
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the-
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Vimerl.  If not, see <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

main([Filename]) ->
    Dir  = filename:dirname(Filename),
    Opts = [strong_validation,
            warn_export_all,
            warn_export_vars,
            warn_shadow_vars,
            warn_obsolete_guard,
            warn_unused_import,
            report,
            {i, Dir ++ "/include"},
            {i, Dir ++ "/../include"},
            {d, 'TEST'}, {d, 'DEBUG'}],
    compile:file(Filename, Opts).
