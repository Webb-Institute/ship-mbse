function info = propertyInfo(propPath, model)
%PROPERTYINFO Definition of a stereotype property from the model's profiles.
%   info = shipmbse.propertyInfo("Profile.Stereotype.Property") returns a
%   struct with fields Name, Type, Units, DefaultValue, Min and Max, read
%   from the profile attached to the model in shipmbse.config.
%
%   Errors with id shipmbse:propertyInfo:Unknown if the profile, stereotype,
%   or property does not exist.
%
%   See also shipmbse.getProp.

arguments
    propPath (1,1) string
    model (1,1) systemcomposer.arch.Model = shipmbse.loadModel()
end

parts = split(propPath, ".");
if numel(parts) ~= 3
    error("shipmbse:propertyInfo:BadPath", ...
        "Property path must be ""Profile.Stereotype.Property"", got ""%s"".", propPath);
end

profiles = model.Profiles;
prof = profiles(string({profiles.Name}) == parts(1));
if isempty(prof)
    error("shipmbse:propertyInfo:Unknown", "Profile ""%s"" is not attached to model ""%s"".", ...
        parts(1), model.Name);
end
sts = prof.Stereotypes;
st = sts(string({sts.Name}) == parts(2));
if isempty(st)
    error("shipmbse:propertyInfo:Unknown", "Stereotype ""%s"" not found in profile ""%s"".", ...
        parts(2), parts(1));
end
props = st.Properties;
p = props(string({props.Name}) == parts(3));
if isempty(p)
    error("shipmbse:propertyInfo:Unknown", "Property ""%s"" not found in stereotype ""%s.%s"".", ...
        parts(3), parts(1), parts(2));
end

% Min/Max are empty cells for text properties; wrap them so struct() stays scalar
info = struct("Name", string(p.Name), "Type", string(p.Type), "Units", string(p.Units), ...
    "DefaultValue", string(p.DefaultValue), "Min", {p.Min}, "Max", {p.Max});

end
