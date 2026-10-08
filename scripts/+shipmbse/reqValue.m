function [value, req] = reqValue(source, attribute, opts)
%REQVALUE Read a custom attribute from a requirement, strictly.
%   value = shipmbse.reqValue(testName, attribute) reads the attribute from
%   the single requirement that the test file verifies (its Verify link).
%   value = shipmbse.reqValue(reqId, attribute) reads it from the
%   requirement with that Id (e.g. "REQ-402") in the configured set.
%
%   Numeric attributes (Threshold, Objective) are returned as double and
%   must parse completely as a number: "100" -> 100; "100 days", "REQ-406"
%   or "" are errors, never silently converted. Other attributes are
%   returned as string.
%
%   [value, req] also returns the slreq.Requirement.
%
%   Name-value options:
%     Units  ("")  Expected units. Errors if the requirement's Units
%                  attribute differs.
%
%   Error ids: shipmbse:reqValue:NoRequirement, :Ambiguous, :NoAttribute,
%   :Empty, :NotNumeric, :UnitMismatch.
%
%   See also shipmbse.linkedRequirements.

arguments
    source (1,1) string
    attribute (1,1) string
    opts.Units (1,1) string = ""
end

if startsWith(source, "test_")
    reqs = shipmbse.linkedRequirements(source);
    if isempty(reqs)
        error("shipmbse:reqValue:NoRequirement", "Test ""%s"" verifies no requirement.", source);
    elseif numel(reqs) > 1
        error("shipmbse:reqValue:Ambiguous", "Test ""%s"" verifies %d requirements (%s); expected one.", ...
            source, numel(reqs), strjoin(string({reqs.Id}), ", "));
    end
    req = reqs(1);
else
    reqSet = slreq.load(shipmbse.config().RequirementSet);
    req = reqSet.find('Type', 'Requirement', 'Id', source);
    if isempty(req)
        error("shipmbse:reqValue:NoRequirement", "Requirement ""%s"" not found.", source);
    end
end

reqSet = req.reqSet;
if ~ismember(attribute, string(reqSet.CustomAttributeNames))
    error("shipmbse:reqValue:NoAttribute", "Requirement set ""%s"" has no attribute ""%s"".", ...
        reqSet.Name, attribute);
end
raw = strtrim(string(req.getAttribute(attribute)));
if raw == "" || raw == "Unset"
    error("shipmbse:reqValue:Empty", "Requirement %s: attribute ""%s"" is not set.", req.Id, attribute);
end

if ismember(attribute, ["Threshold", "Objective"])
    value = str2double(raw);
    if isnan(value) || ~isfinite(value)
        error("shipmbse:reqValue:NotNumeric", "Requirement %s: %s = ""%s"" is not a number.", ...
            req.Id, attribute, raw);
    end
else
    value = raw;
end

if opts.Units ~= ""
    units = strtrim(string(req.getAttribute("Units")));
    if units ~= opts.Units
        error("shipmbse:reqValue:UnitMismatch", "Requirement %s: Units is ""%s"", expected ""%s"".", ...
            req.Id, units, opts.Units);
    end
end

end
