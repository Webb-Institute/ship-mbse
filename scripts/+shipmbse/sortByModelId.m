function [T, idx] = sortByModelId(T, pathVar)
%SORTBYMODELID Sort table rows by the leading model ID of each component name.
%   T = shipmbse.sortByModelId(T) sorts by the number at the start of the last
%   segment of T.Path (e.g. "52X (FUEL)" -> 52, "521 (FUEL STORAGE)" -> 521),
%   then by name. Names without a leading number sort last.
%
%   T = shipmbse.sortByModelId(T, pathVar) uses the named variable instead
%   of "Path". [T, idx] also returns the row order applied.

arguments
    T table
    pathVar (1,1) string = "Path"
end

names = componentName(T.(pathVar));
key = str2double(regexp(names, "^\d+", "match", "once"));
key(isnan(key)) = Inf;
% Two-digit group IDs (e.g. 52X -> 52) sort with their three-digit members (520-529)
key(key < 100) = key(key < 100) * 10;
[~, idx] = sortrows(table(key, names));
T = T(idx, :);

end

function names = componentName(paths)
names = string(paths);
for k = 1:numel(names)
    parts = split(names(k), "/");
    names(k) = parts(end);
end
end
