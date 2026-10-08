function changes = applyProperties(filename, opts)
%APPLYPROPERTIES Apply stereotypes and property values from an Excel property table.
%   changes = applyProperties(filename) validates the table against the
%   model's profiles and components, then applies it to the model named in
%   shipmbse.config. Returns one row per component: Component, Applied,
%   Removed, ValuesSet. This MODIFIES THE MODEL; it does not save.
%
%   changes = applyProperties(filename, DryRun=true) validates only.
%
%   Table layout (sheet 1):
%     Row 1  profile name          (e.g. WeightsCentersProfile)
%     Row 2  stereotype name       (e.g. WeightsCenters)
%     Row 3  property name         (e.g. Weight)
%     Row 4  units: must equal the profile's units for numeric properties
%            ("(t)" and "t" are both accepted); "On/Off" for booleans;
%            "string" (or a list of allowed values) for text
%     Row 5+ column A: component or variant-choice name; then values.
%            "N/A" or an empty cell = no value.
%
%   Rules (applying a table twice, or disjoint tables in any order, gives
%   the same model):
%     * A stereotype is applied to a component if the row has at least one
%       value for it, and REMOVED if all its columns are N/A.
%     * In an applied stereotype, an N/A property is reset to the profile
%       default (NaN for numbers once profiles default to NaN).
%     * Rows must name a component or a variant CHOICE, never a variant
%       container (containers are not counted by analyses).
%     * DataRecord.Maturity must be one of shipmbse.config().MaturityLevels.
%   All validation errors are reported together, before anything changes.
%
%   See also rebuildProperties, stripProperties, shipmbse.config.

arguments
    filename (1,1) string
    opts.DryRun (1,1) logical = false
end

cfg = shipmbse.config();
model = shipmbse.loadModel(cfg.ModelName);
raw = readcell(filename);
problems = strings(0);

% --- Columns ----------------------------------------------------------------
nCols = size(raw, 2);
cols = struct('Index', {}, 'Stereotype', {}, 'Property', {}, 'Path', {}, 'Type', {}, 'Default', {});
for j = 2:nCols
    head = arrayfun(@(r) cellText(raw{r, j}), 1:4);
    if all(head(1:3) == "")
        continue
    end
    stereo = head(1) + "." + head(2);
    path = stereo + "." + head(3);
    try
        propInfo = shipmbse.propertyInfo(path, model);
    catch err
        problems(end+1) = sprintf("Column %d: %s", j, err.message); %#ok<AGROW>
        continue
    end
    unitHead = erase(head(4), ["(", ")", " "]);
    if isNumericType(propInfo.Type) && unitHead ~= erase(propInfo.Units, " ")
        problems(end+1) = sprintf("Column %d (%s): unit header ""%s"" does not match profile unit ""%s"".", ...
            j, path, head(4), propInfo.Units); %#ok<AGROW>
    end
    cols(end+1) = struct('Index', j, 'Stereotype', stereo, 'Property', head(3), ...
        'Path', path, 'Type', propInfo.Type, 'Default', propInfo.DefaultValue); %#ok<AGROW>
end
stereotypes = unique(string({cols.Stereotype}), 'stable');

% --- Components -------------------------------------------------------------
everyComp = shipmbse.allComponents(model);
names = string(arrayfun(@(c) string(c.Name), everyComp));
isContainer = arrayfun(@(c) isa(c, 'systemcomposer.arch.VariantComponent'), everyComp);
rows = struct('Row', {}, 'Name', {}, 'Component', {});
for r = 5:size(raw, 1)
    name = cellText(raw{r, 1});
    if name == ""
        continue
    end
    hit = find(names == name);
    if isempty(hit)
        problems(end+1) = sprintf("Row %d: component ""%s"" not found in the model.", r, name); %#ok<AGROW>
    elseif numel(hit) > 1
        problems(end+1) = sprintf("Row %d: component name ""%s"" is not unique in the model.", r, name); %#ok<AGROW>
    elseif isContainer(hit)
        problems(end+1) = sprintf("Row %d: ""%s"" is a variant container; give values for its choices instead.", r, name); %#ok<AGROW>
    else
        rows(end+1) = struct('Row', r, 'Name', name, 'Component', everyComp(hit)); %#ok<AGROW>
    end
end
if numel(unique(string({rows.Name}))) < numel(rows)
    problems(end+1) = "A component appears in more than one row.";
end

% --- Values -----------------------------------------------------------------
values = strings(numel(rows), numel(cols));   % "" = N/A; otherwise the expression to set
for i = 1:numel(rows)
    for k = 1:numel(cols)
        [values(i, k), msg] = toExpression(raw{rows(i).Row, cols(k).Index}, cols(k), cfg);
        if msg ~= ""
            problems(end+1) = sprintf("Row %d (%s), %s: %s", rows(i).Row, rows(i).Name, cols(k).Path, msg); %#ok<AGROW>
        end
    end
end

if ~isempty(problems)
    error("applyProperties:Invalid", "%s has %d problem(s); nothing was changed:\n  %s", ...
        filename, numel(problems), strjoin(problems, newline + "  "));
end

% --- Apply ------------------------------------------------------------------
changes = table('Size', [numel(rows) 4], 'VariableTypes', {'string', 'double', 'double', 'double'}, ...
    'VariableNames', {'Component', 'Applied', 'Removed', 'ValuesSet'});
for i = 1:numel(rows)
    c = rows(i).Component;
    applied = string(c.getStereotypes());
    changes.Component(i) = rows(i).Name;
    for s = stereotypes
        inS = string({cols.Stereotype}) == s;
        rowVals = values(i, inS);
        if all(rowVals == "")
            if ismember(s, applied) && ~opts.DryRun
                c.removeStereotype(s);
            end
            changes.Removed(i) = changes.Removed(i) + ismember(s, applied);
            continue
        end
        if ~ismember(s, applied) && ~opts.DryRun
            c.applyStereotype(s);
        end
        changes.Applied(i) = changes.Applied(i) + 1;
        sCols = cols(inS);
        for k = 1:numel(sCols)
            expr = rowVals(k);
            if expr == ""
                expr = sCols(k).Default;
            end
            if ~opts.DryRun
                c.setProperty(sCols(k).Path, expr);
            end
            changes.ValuesSet(i) = changes.ValuesSet(i) + (rowVals(k) ~= "");
        end
    end
end
fprintf('%s: %d components, %d stereotype(s) applied, %d removed, %d values set%s.\n', filename, ...
    height(changes), sum(changes.Applied), sum(changes.Removed), sum(changes.ValuesSet), ...
    repmat(" (dry run, nothing changed)", 1, opts.DryRun));

end

% ---------------------------------------------------------------------------
function [expr, msg] = toExpression(cellValue, col, cfg)
% Property expression for a cell, "" for N/A; msg is non-empty if invalid
expr = "";
msg = "";
if isMissingCell(cellValue)
    return
end
switch col.Type
    case "boolean"
        if islogical(cellValue) || isnumeric(cellValue)
            tf = logical(cellValue);
        else
            t = lower(strtrim(string(cellValue)));
            if ismember(t, ["true", "on", "yes", "1"])
                tf = true;
            elseif ismember(t, ["false", "off", "no", "0"])
                tf = false;
            else
                msg = sprintf("""%s"" is not true/false/On/Off.", string(cellValue));
                return
            end
        end
        expr = lower(string(tf));
    case "string"
        t = strtrim(string(cellValue));
        if col.Path == cfg.Stereotypes.DataRecord + ".Maturity" && ~ismember(t, cfg.MaturityLevels)
            msg = sprintf("Maturity ""%s"" is not one of: %s.", t, strjoin(cfg.MaturityLevels, ", "));
            return
        end
        expr = "'" + replace(t, "'", "''") + "'";
    otherwise   % numeric types
        if isnumeric(cellValue) && isscalar(cellValue) && isfinite(cellValue)
            expr = string(sprintf('%.15g', cellValue));
        else
            v = str2double(string(cellValue));
            if isnan(v)
                msg = sprintf("""%s"" is not a number.", string(cellValue));
                return
            end
            expr = string(sprintf('%.15g', v));
        end
end
end

function tf = isNumericType(typeName)
tf = ~ismember(typeName, ["boolean", "string", "stringArray"]);
end

function tf = isMissingCell(v)
tf = isempty(v) || (isscalar(v) && ismissing(v)) || ...
    ((ischar(v) || isstring(v)) && ismember(upper(strtrim(string(v))), ["", "N/A", "NA"]));
end

function t = cellText(v)
if isMissingCell(v) && ~(isnumeric(v) || islogical(v))
    t = "";
else
    t = strtrim(string(v));
end
end
