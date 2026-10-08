function [value, unit, isDefault] = getProp(comp, propPath, opts)
%GETPROP Read a stereotype property value from a component, typed and with units.
%   value = shipmbse.getProp(comp, "Profile.Stereotype.Property") returns the
%   evaluated value: double for numeric properties, logical for booleans,
%   string for text.
%
%   [value, unit, isDefault] = shipmbse.getProp(...) also returns the unit
%   from the profile definition and whether the stored value still equals
%   the profile's default (i.e. it was probably never set).
%
%   Name-value options:
%     Unit   ("")  Expected unit. Errors (shipmbse:getProp:UnitMismatch) if
%                  the profile defines a different unit. No conversion is done.
%     Model  model containing the profile (default: shipmbse.loadModel()).
%
%   Errors with id shipmbse:getProp:NoProperty if the component does not
%   have the property (the stereotype is not applied), and
%   shipmbse:getProp:BadValue if the stored value cannot be evaluated.
%
%   Limitation: for numeric properties whose profile default is "0", an unset
%   value reads as 0. isDefault reports this, but cannot distinguish an
%   unset value from an explicitly entered default.
%
%   See also shipmbse.propertyInfo, shipmbse.sumProperty.

arguments
    comp (1,1) systemcomposer.arch.Component
    propPath (1,1) string
    opts.Unit (1,1) string = ""
    opts.Model systemcomposer.arch.Model {mustBeScalarOrEmpty} = systemcomposer.arch.Model.empty
end

if ~comp.hasProperty(propPath)
    error("shipmbse:getProp:NoProperty", "Component ""%s"" has no property ""%s"".", ...
        comp.Name, propPath);
end

try
    value = comp.getEvaluatedPropertyValue(propPath);
catch cause
    err = MException("shipmbse:getProp:BadValue", ...
        "Cannot evaluate property ""%s"" on component ""%s"" (stored value ""%s"").", ...
        propPath, comp.Name, string(comp.getProperty(propPath)));
    throw(addCause(err, cause));
end
if ischar(value)
    value = string(value);
end

if nargout > 1 || opts.Unit ~= ""
    model = opts.Model;
    if isempty(model)
        model = shipmbse.loadModel();
    end
    info = shipmbse.propertyInfo(propPath, model);
    unit = info.Units;
    if opts.Unit ~= "" && unit ~= opts.Unit
        error("shipmbse:getProp:UnitMismatch", ...
            "Property ""%s"" is defined in ""%s"", expected ""%s"".", propPath, unit, opts.Unit);
    end
    isDefault = strtrim(string(comp.getProperty(propPath))) == strtrim(info.DefaultValue);
end

end
