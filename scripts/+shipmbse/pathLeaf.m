function [names, parents] = pathLeaf(paths)
%PATHLEAF Component names and parent paths from Simulink block paths.
%   [names, parents] = shipmbse.pathLeaf(paths) splits each block path at its
%   last separator. A "/" inside a component name is written "//" in a
%   Simulink path (e.g. "SYSTEM/SHIP/500 (AUX)/55X (CARGO//MISSION)"); names
%   are returned unescaped ("55X (CARGO/MISSION)"), parents stay escaped.

arguments
    paths string
end

leaf = regexp(paths, "(?:[^/]|//)+$", "match", "once");
names = replace(leaf, "//", "/");
parents = strings(size(paths));
for k = 1:numel(paths)
    sep = strlength(paths(k)) - strlength(leaf(k));   % index of the separating "/"
    if sep > 1
        parents(k) = extractBefore(paths(k), sep);
    end
end

end
