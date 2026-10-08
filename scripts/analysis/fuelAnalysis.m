function [links, rollup] = fuelAnalysis()
%FUELANALYSIS Validate fuel-system connections and compare child roll-ups with the parent.
%   [links, rollup] = fuelAnalysis() analyses the active fuel system (the
%   active choice of shipmbse.config().Paths.Fuel) and writes
%   outputs/reports/FuelAnalysisReport.txt.
%
%   1. Connection checks: for every connector between two components inside
%      the fuel system (variant components resolved to their active choice):
%        * skipped if either end is off (Status false) or has no stereotype
%          (e.g. an ABSENT choice);
%        * a pipe's Fluid must match one of the fluids defined on the
%          component at the other end;
%        * shared fluid and flow-rate properties (PriFluid, SecFluid,
%          TerFluid, PriFlowRate, SecFlowRate, TerFlowRate) must be equal.
%      links: one row per check (Ends, Check, Result, Detail).
%
%   2. Roll-up comparison: sums (or weight-averaged centres) of child
%      properties over children that are on, compared with the value held
%      on the fuel system component itself. Nothing is written to the
%      model. rollup: Property, ChildRollup, ParentProperty, ParentValue,
%      Difference.
%
%   Run propagatePipeFluids first to copy consumer fuel types onto pipes.
%   This analysis does not modify the model.
%
%   See also propagatePipeFluids, shipmbse.activeComponents.

cfg = shipmbse.config();
st = cfg.Stereotypes;
model = shipmbse.loadModel();
fuelPath = cfg.ModelName + "/" + cfg.Paths.Fuel;
fuel = lookup(model, 'Path', fuelPath);
if isa(fuel, 'systemcomposer.arch.VariantComponent')
    fuel = fuel.getActiveChoice();
end
if isempty(fuel.Architecture) || isempty(fuel.Architecture.Components)
    error("fuelAnalysis:NoFuelSystem", "Active fuel system choice ""%s"" has no components.", fuel.Name);
end
arch = fuel.Architecture;

% --- 1. Connection checks ---------------------------------------------------
links = table('Size', [0 4], 'VariableTypes', {'string', 'string', 'string', 'string'}, ...
    'VariableNames', {'Ends', 'Check', 'Result', 'Detail'});
conns = arch.Connectors;
seen = strings(0);
for k = 1:numel(conns)
    ends = endComponents(conns(k));
    for i = 1:numel(ends)
        for j = i+1:numel(ends)
            [a, b] = deal(ends{i}, ends{j});
            label = sort([string(a.Name), string(b.Name)]);
            key = join(label, " <-> ");
            if ismember(key, seen)
                continue
            end
            seen(end+1) = key; %#ok<AGROW>
            links = [links; checkPair(key, a, b, st)]; %#ok<AGROW>
        end
    end
end

% --- 2. Roll-up comparison -----------------------------------------------------
%            Child property      Operation  Parent property
rules = ["PowerRequired",    "SUM", st.ElectricalConsumer + ".PowerRequired";
         "Weight",           "SUM", st.WeightsCenters + ".Weight";
         "LubeConsumption",  "SUM", st.LubeConsumer + ".LubeRequired";
         "CoolConsumption",  "SUM", st.CoolConsumer + ".CoolConsumed";
         "WasteOilProduced", "SUM", st.WasteOilProducer + ".WOProduced";
         "HeatConsumed",     "SUM", st.HeatConsumer + ".HeatConsumed";
         "FlowRate",         "SUM", st.FuelProducer + ".FuelProduced";
         "LCG",              "COG", st.WeightsCenters + ".LCG";
         "VCG",              "COG", st.WeightsCenters + ".VCG";
         "TCG",              "COG", st.WeightsCenters + ".TCG"];
[children, cpaths] = shipmbse.activeComponents(model);
inFuel = startsWith(cpaths, fuelPath + "/" + escape(fuel.Name) + "/");
children = children(inFuel);
childProps = arrayfun(@readAll, children, 'UniformOutput', false);
childOn = cellfun(@isOn, childProps);
childWeight = cellfun(@(p) firstNumber(p, "Weight"), childProps);

n = size(rules, 1);
rollup = table(rules(:, 1), nan(n, 1), rules(:, 3), nan(n, 1), nan(n, 1), ...
    'VariableNames', {'Property', 'ChildRollup', 'ParentProperty', 'ParentValue', 'Difference'});
for r = 1:n
    vals = cellfun(@(p) firstNumber(p, rules(r, 1)), childProps);
    use = childOn & ~isnan(vals);
    if rules(r, 2) == "COG"
        use = use & childWeight > 0;
        if any(use)
            rollup.ChildRollup(r) = sum(vals(use) .* childWeight(use)) / sum(childWeight(use));
        end
    elseif any(use)
        rollup.ChildRollup(r) = sum(vals(use));
    end
    if fuel.hasProperty(rules(r, 3))
        rollup.ParentValue(r) = shipmbse.getProp(fuel, rules(r, 3));
    end
end
rollup.Difference = rollup.ChildRollup - rollup.ParentValue;

writeReport(fuel, links, rollup, sum(~childOn), numel(children));

end

% ---------------------------------------------------------------------------
function ends = endComponents(conn)
% Components at the ends of a connector, variant containers resolved
ends = {};
ports = conn.Ports;
for p = 1:numel(ports)
    c = ports(p).Parent;
    if isa(c, 'systemcomposer.arch.VariantComponent')
        c = c.getActiveChoice();
    end
    if isa(c, 'systemcomposer.arch.Component') && ~isempty(c)
        ends{end+1} = c; %#ok<AGROW>
    end
end
end

function rows = checkPair(key, a, b, st)
rows = table('Size', [0 4], 'VariableTypes', {'string', 'string', 'string', 'string'}, ...
    'VariableNames', {'Ends', 'Check', 'Result', 'Detail'});
pa = readAll(a); pb = readAll(b);
if numEntries(pa) == 0 || numEntries(pb) == 0
    rows(end+1, :) = {key, "connection", "SKIPPED", "an end has no stereotype (e.g. ABSENT)"};
    return
end
if ~isOn(pa) || ~isOn(pb)
    rows(end+1, :) = {key, "connection", "SKIPPED", "an end is off (Status false)"};
    return
end

% Pipe fluid vs. the other end's fluids
isPipeA = any(string(a.getStereotypes()) == st.Pipe);
isPipeB = any(string(b.getStereotypes()) == st.Pipe);
if xor(isPipeA, isPipeB)
    if isPipeA
        [pipeP, other, otherName] = deal(pa, pb, b.Name);
    else
        [pipeP, other, otherName] = deal(pb, pa, a.Name);
    end
    pipeFluid = firstText(pipeP, "Fluid");
    fluids = strings(0);
    for f = ["PriFluid", "SecFluid", "TerFluid", "Fluid", "FuelType"]
        v = firstText(other, f);
        if ~ismember(upper(v), ["", "N/A", "NONE"])
            fluids(end+1) = v; %#ok<AGROW>
        end
    end
    if pipeFluid == "" || isempty(fluids)
        rows(end+1, :) = {key, "pipe fluid", "SKIPPED", "pipe fluid or component fluids not defined"};
    elseif any(strcmpi(pipeFluid, fluids))
        rows(end+1, :) = {key, "pipe fluid", "PASS", sprintf('"%s" carried by %s', pipeFluid, otherName)};
    else
        rows(end+1, :) = {key, "pipe fluid", "FAIL", sprintf('pipe carries "%s"; %s defines %s', ...
            pipeFluid, otherName, strjoin('"' + fluids + '"', ", "))};
    end
end

% Shared fluid / flow properties must agree
for prop = ["PriFluid", "SecFluid", "TerFluid", "PriFlowRate", "SecFlowRate", "TerFlowRate"]
    if isKey(pa, prop) && isKey(pb, prop)
        va = pa{prop}; vb = pb{prop};
        if isequal(va{1}, vb{1})
            rows(end+1, :) = {key, prop, "PASS", string(va{1})}; %#ok<AGROW>
        else
            rows(end+1, :) = {key, prop, "FAIL", sprintf('%s = %s, %s = %s', ...
                a.Name, string(va{1}), b.Name, string(vb{1}))}; %#ok<AGROW>
        end
    end
end
if isempty(rows)
    rows(end+1, :) = {key, "connection", "INFO", "no comparable properties"};
end
end

function props = readAll(c)
% Dictionary: short property name -> cell array of values, one per stereotype
% that defines it. Read values with props{name}.
props = dictionary(string.empty, cell.empty);
names = string(c.getStereotypeProperties());
for k = 1:numel(names)
    short = extractAfter(names(k), asManyOfPattern(wildcardPattern + "."));
    v = c.getEvaluatedPropertyValue(names(k));
    if ischar(v)
        v = string(v);
    end
    if isKey(props, short)
        props(short) = {[props{short}, {v}]};
    else
        props(short) = {{v}};
    end
end
end

function tf = isOn(props)
% Off if any stereotype on the component has Status false
tf = true;
if isKey(props, "Status")
    s = props{"Status"};
    tf = all(cellfun(@(v) logical(v), s));
end
end

function v = firstNumber(props, name)
v = NaN;
if isKey(props, name)
    vals = props{name};
    if isnumeric(vals{1})
        v = double(vals{1});
    end
end
end

function v = firstText(props, name)
v = "";
if isKey(props, name)
    vals = props{name};
    v = strtrim(string(vals{1}));
end
end

function s = escape(name)
s = replace(string(name), "/", "//");
end

function writeReport(fuel, links, rollup, numOff, numChildren)
fileName = fullfile(getOutputDir("reports"), "FuelAnalysisReport.txt");
fid = fopen(fileName, "wt");
if fid == -1
    error("fuelAnalysis:CannotWrite", "Could not open ""%s"" for writing.", fileName);
end
closeFile = onCleanup(@() fclose(fid));
line = repmat('=', 1, 100);
fprintf(fid, "%s\nFUEL SYSTEM ANALYSIS: %s\nGenerated: %s\n%s\n", line, fuel.Name, ...
    string(datetime("now", "Format", "yyyy-MM-dd HH:mm")), line);

fprintf(fid, "\n1. CONNECTION CHECKS\n%s\n", repmat('-', 1, 100));
for k = 1:height(links)
    fprintf(fid, "%-8s %-55s %-12s %s\n", links.Result(k), links.Ends(k), links.Check(k), links.Detail(k));
end
nFail = sum(links.Result == "FAIL");
fprintf(fid, "\n%d checks: %d pass, %d fail, %d skipped.\n", height(links), ...
    sum(links.Result == "PASS"), nFail, sum(links.Result == "SKIPPED"));

fprintf(fid, "\n2. ROLL-UP OF %d CHILD COMPONENTS (%d off, excluded) vs. %s\n%s\n", ...
    numChildren, numOff, fuel.Name, repmat('-', 1, 100));
fprintf(fid, "%-18s | %14s | %14s | %14s | %s\n", "Child property", "Child roll-up", "Parent value", "Difference", "Parent property");
for k = 1:height(rollup)
    fprintf(fid, "%-18s | %14.6g | %14.6g | %14.6g | %s\n", rollup.Property(k), rollup.ChildRollup(k), ...
        rollup.ParentValue(k), rollup.Difference(k), rollup.ParentProperty(k));
end
fprintf(fid, "\nThe parent's own values are what ship-level reports use. A non-zero difference means\n");
fprintf(fid, "the fuel system's summary values and its component data disagree.\n%s\n", line);

fprintf('Fuel analysis: %d connection checks (%d fail). Report written to "%s".\n', height(links), nFail, fileName);
end
