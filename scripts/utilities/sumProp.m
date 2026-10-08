function [propValueSum, numCompFound] = sumProp(targetPropName, targetStereotypeName, targetProfileName)
%SUMPROP Sum a stereotype property over the active configuration.
%   [propValueSum, numCompFound] = sumProp(prop, stereotype, profile) sums
%   Profile.Stereotype.Property over every active component carrying the
%   stereotype, and returns how many components contributed.
%
%   Wrapper around shipmbse.sumProperty, which defines the traversal rules
%   and returns per-component details.
%
%   See also sumPropIfOn, shipmbse.sumProperty.

arguments
    targetPropName (1,1) string
    targetStereotypeName (1,1) string
    targetProfileName (1,1) string
end

[propValueSum, details] = shipmbse.sumProperty( ...
    targetProfileName + "." + targetStereotypeName + "." + targetPropName);
numCompFound = sum(details.Included);

end
