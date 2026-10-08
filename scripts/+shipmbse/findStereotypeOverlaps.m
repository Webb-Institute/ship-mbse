function overlaps = findStereotypeOverlaps(model)
%FINDSTEREOTYPEOVERLAPS Active components that share a stereotype with a descendant.
%   overlaps = shipmbse.findStereotypeOverlaps() returns a table with one row
%   per (ancestor, descendant, stereotype) where both the ancestor and one
%   of its active descendants carry the same stereotype. Summing that
%   stereotype over the active configuration counts both, which is a
%   double-counting risk unless the ancestor's values are deliberately
%   separate from its children's.
%
%   Columns: Stereotype, Ancestor, Descendant.
%
%   See also shipmbse.activeComponents, shipmbse.sumProperty.

arguments
    model (1,1) systemcomposer.arch.Model = shipmbse.loadModel()
end

[comps, paths] = shipmbse.activeComponents(model);
st = cell(numel(comps), 1);
for k = 1:numel(comps)
    st{k} = string(comps(k).getStereotypes());
end

overlaps = table('Size', [0 3], 'VariableTypes', {'string', 'string', 'string'}, ...
    'VariableNames', {'Stereotype', 'Ancestor', 'Descendant'});
for a = 1:numel(comps)
    if isempty(st{a}), continue, end
    isDescendant = startsWith(paths, paths(a) + "/") & ~startsWith(paths, paths(a) + "//");
    for d = find(isDescendant)'
        shared = intersect(st{a}, st{d});
        for s = 1:numel(shared)
            overlaps(end+1, :) = {shared(s), paths(a), paths(d)}; %#ok<AGROW>
        end
    end
end

end
