function [propValueSumOn, numCompFoundOn] = sumPropIfOn(targetPropName, targetStereotypeName, targetProfileName)
%SUMPROPIFON Sum a stereotype property over active components whose Status is on.
%   [propValueSumOn, numCompFoundOn] = sumPropIfOn(prop, stereotype, profile)
%   sums Profile.Stereotype.Property over every active component carrying
%   the stereotype whose Profile.Stereotype.Status is true, and returns how
%   many components contributed.
%
%   Wrapper around shipmbse.sumProperty(..., OnlyIfOn=true).
%
%   See also sumProp, shipmbse.sumProperty.

arguments
    targetPropName (1,1) string
    targetStereotypeName (1,1) string
    targetProfileName (1,1) string
end

[propValueSumOn, details] = shipmbse.sumProperty( ...
    targetProfileName + "." + targetStereotypeName + "." + targetPropName, OnlyIfOn=true);
numCompFoundOn = sum(details.Included);

end
