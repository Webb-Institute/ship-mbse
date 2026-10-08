function [total, details] = sumProperty(propPath, opts)
%SUMPROPERTY Sum a numeric stereotype property over the active configuration.
%   total = shipmbse.sumProperty("Profile.Stereotype.Property") sums the
%   property over every active component with that stereotype
%   (see shipmbse.activeComponents for the traversal rules).
%
%   [total, details] = shipmbse.sumProperty(...) also returns a table with
%   one row per component carrying the stereotype:
%     Path, Value, Unit, IsDefault, StatusOn, Included
%
%   Name-value options:
%     OnlyIfOn   (false) Include only components whose Status property in
%                the same stereotype is true. Components without a Status
%                property are excluded when OnlyIfOn is true.
%     Model      Model to read (default: shipmbse.loadModel()).
%
%   Use height(details) or sum(details.Included) to check that components
%   were actually found. A total of 0 with no contributors is not evidence
%   that a balance is satisfied.
%
%   See also shipmbse.getProp, shipmbse.activeComponents.

arguments
    propPath (1,1) string
    opts.OnlyIfOn (1,1) logical = false
    opts.Model (1,1) systemcomposer.arch.Model = shipmbse.loadModel()
end

parts = split(propPath, ".");
if numel(parts) ~= 3
    error("shipmbse:sumProperty:BadPath", ...
        "Property path must be ""Profile.Stereotype.Property"", got ""%s"".", propPath);
end
stereotype = parts(1) + "." + parts(2);
statusPath = stereotype + "." + shipmbse.config().StatusProperty;

info = shipmbse.propertyInfo(propPath, opts.Model);   % errors on unknown property
[comps, paths] = shipmbse.activeComponents(opts.Model, Stereotype=stereotype);

n = numel(comps);
value = nan(n, 1);
isDefault = false(n, 1);
statusOn = false(n, 1);
for k = 1:n
    [v, ~, isDefault(k)] = shipmbse.getProp(comps(k), propPath, Model=opts.Model);
    value(k) = double(v);
    if comps(k).hasProperty(statusPath)
        statusOn(k) = logical(shipmbse.getProp(comps(k), statusPath));
    end
end

if opts.OnlyIfOn
    included = statusOn;
else
    included = true(n, 1);
end
total = sum(value(included));

details = table(paths, value, repmat(info.Units, n, 1), isDefault, statusOn, included, ...
    'VariableNames', {'Path', 'Value', 'Unit', 'IsDefault', 'StatusOn', 'Included'});

end
