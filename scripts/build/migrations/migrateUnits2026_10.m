function migrateUnits2026_10(step)
%MIGRATEUNITS2026_10 One-off migration (Phase 1b, October 2026). Kept for the record.
%   migrateUnits2026_10("profiles") updates units and defaults in the
%   profiles and creates ShipElementProfile.
%   migrateUnits2026_10("tables") converts Properties.xlsx and FuelProp.xlsx.
%   Both refuse to run twice (they check for the old units).
%
%   Unit decisions (2026-10-08):
%     fuel and lube rates t/h, fuel stored t, tank volumes m^3, pipe/pump
%     flows m^3/h, compressed air Nm^3/h, waste gas kg/h, waste water and
%     waste oil m^3/day, solid waste kg/day. Cooling/heat stay kW,
%     electrical kW, weights t, centres m.
%
%   Conversion of the existing values (all Maturity = Placeholder):
%     1 kL = 1 m^3. Volume -> mass with shipmbse.config().FluidDensity
%     (fuel by FuelType, lube 0.90 t/m^3). Compressed air: kL taken as
%     normal m^3. Waste gas: 1.2 kg/m^3 nominal. Solid waste: 0.2 t/m^3 bulk.
%
%   Fuel system (decision: component sum is authoritative): the summary
%   values on "52X FUEL" are removed; its parts (520-529) carry the
%   ship-level stereotypes, built from their component data:
%     WeightsCenters    <- FuelComponentProfile.Weights (+ WeightMargin 9 %,
%                          the margin previously on 52X FUEL)
%     ElectricalConsumer, CoolConsumer, LubeConsumer, HeatConsumer,
%     WasteOilProducer  <- the matching Controller/FluidConditioner/Pump values
%     FuelProducer.FuelProduced (pipes 525-527) <- Pipe.FlowRate x fluid density
%   The duplicated FuelComponentProfile columns are dropped from the table.

arguments
    step (1,1) string {mustBeMember(step, ["profiles", "tables"])}
end

switch step
    case "profiles"
        migrateProfiles();
    case "tables"
        migrateProperties();
        migrateFuelProp();
end
end

% =============================================================================
function migrateProfiles()
cfg = shipmbse.config();
units = [ ...
    "FuelProfile",          "FuelConsumer",       "FuelRequired",           "t/h";
    "FuelProfile",          "FuelProducer",       "FuelProduced",           "t/h";
    "FuelProfile",          "FuelProducer",       "FuelStored",             "t";
    "LubeProfile",          "LubeConsumer",       "LubeRequired",           "t/h";
    "LubeProfile",          "LubeProducer",       "LubeProduced",           "t/h";
    "LubeProfile",          "LubeProducer",       "LubeStored",             "m^3";
    "CompAirProfile",       "AirConsumer",        "AirConsumed",            "Nm^3/h";
    "CompAirProfile",       "AirProducer",        "AirProduced",            "Nm^3/h";
    "WasteProfile",         "WasteGasProducer",   "WGProduced",             "kg/h";
    "WasteProfile",         "WasteOilProducer",   "WOProduced",             "m^3/day";
    "WasteProfile",         "WasteWaterProducer", "WWProduced",             "m^3/day";
    "WasteProfile",         "WasteSolidProducer", "WSProduced",             "kg/day";
    "WasteProfile",         "WasteReceiver",      "WGReceived",             "kg/h";
    "WasteProfile",         "WasteReceiver",      "WOReceived",             "m^3/day";
    "WasteProfile",         "WasteReceiver",      "WWReceived",             "m^3/day";
    "WasteProfile",         "WasteReceiver",      "WSReceived",             "kg/day"];
fc = "FuelComponentProfile";
for s = ["FluidConditioner", "Pump"]
    for p = ["MaxFlowCapacity", "PriFlowRate", "SecFlowRate", "TerFlowRate"]
        units(end+1, :) = [fc, s, p, "m^3/h"]; %#ok<AGROW>
    end
    units(end+1, :) = [fc, s, "LubeConsumption", "t/h"]; %#ok<AGROW>
end
units = [units; fc, "FluidConditioner", "WasteOilProduced", "m^3/day";
                fc, "Pipe", "FlowRate", "m^3/h";
                fc, "Pipe", "FluidDensity", "kg/m^3"];
for p = ["PrimaryFluidCapacity", "SecondaryFluidCapacity", "TertiaryFluidCapacity", ...
         "PrimaryFluidLevel", "SecondaryFluidLevel", "TertiaryFluidLevel"]
    units(end+1, :) = [fc, "Tank", p, "m^3"]; %#ok<AGROW>
end

profileDir = fullfile(cfg.RootFolder, "model", "profiles");
changed = unique(units(:, 1));
allProfiles = string({dir(fullfile(profileDir, "*.xml")).name});
allProfiles = erase(allProfiles, ".xml");
for name = allProfiles
    prof = systemcomposer.profile.Profile.load(name);
    for st = prof.Stereotypes
        for p = st.Properties
            row = units(:, 1) == name & units(:, 2) == st.Name & units(:, 3) == p.Name;
            if any(row) && string(p.Units) ~= units(row, 4)
                if ~ismember(string(p.Units), ["kL/s", "kL", "kg/kL"])
                    error("migrate:UnexpectedUnit", "%s.%s.%s has units ""%s"", expected the old kL-based unit.", ...
                        name, st.Name, p.Name, p.Units);
                end
                factor = profileFactor(string(p.Units), units(row, 4));
                p.Units = char(units(row, 4));
                if ~isempty(p.Max) && isnumeric(p.Max) && p.Max < realmax / factor
                    p.Max = p.Max * factor;   % leave realmax limits alone
                end
            end
            if ismember(string(p.Type), ["double", "single"]) && string(p.DefaultValue) == "0"
                p.DefaultValue = 'NaN';
            end
        end
    end
    prof.save(char(profileDir));
    fprintf('Profile %s updated%s.\n', name, repmat(" (units)", 1, ismember(name, changed)));
end

% DataRecord: maturity and source of each component's data
if ~isfile(fullfile(profileDir, "ShipElementProfile.xml"))
    prof = systemcomposer.profile.Profile.createProfile("ShipElementProfile");
    st = prof.addStereotype("DataRecord", "AppliesTo", "Component", ...
        "Description", "Maturity and source of the component's property data.");
    % Maturity: one of shipmbse.config().MaturityLevels; DataSource: where the values came from
    st.addProperty("Maturity", "Type", "string");
    st.addProperty("DataSource", "Type", "string");
    prof.save(char(profileDir));
    disp("Created ShipElementProfile.DataRecord.");
end
model = shipmbse.loadModel();
if ~ismember("ShipElementProfile", string({model.Profiles.Name}))
    model.applyProfile("ShipElementProfile");
    disp("Attached ShipElementProfile to the model (save the model to keep it).");
end
end

function f = profileFactor(oldUnit, newUnit)
% Scale for Min/Max: the largest magnitude factor used for that unit change
switch oldUnit + "->" + newUnit
    case {"kL/s->t/h", "kL/s->m^3/h", "kL/s->Nm^3/h", "kL/s->kg/h"}
        f = 3600 * 1.2;
    case {"kL/s->m^3/day", "kL/s->kg/day"}
        f = 86400 * 200;
    otherwise   % kL -> t, kL -> m^3, kg/kL -> kg/m^3
        f = 1;
end
end

% =============================================================================
function migrateProperties()
file = which("Properties.xlsx");
raw = readcell(file);
paths = columnPaths(raw);
checkOld(raw, paths, "FuelProfile.FuelConsumer.FuelRequired", file);
density = shipmbse.config().FluidDensity;

fuelTypeCol = paths == "FuelProfile.FuelConsumer.FuelType";
for j = find(paths ~= "")'
    [factor, unit, perFuel] = valueFactor(paths(j));
    if isempty(factor)
        continue
    end
    raw{4, j} = char(unit);
    for r = 5:size(raw, 1)
        v = raw{r, j};
        if ~(isnumeric(v) && isscalar(v))
            continue
        end
        if perFuel
            raw{r, j} = v * factor * density(upper(strtrim(string(raw{r, fuelTypeCol}))));
        else
            raw{r, j} = v * factor;
        end
    end
end

% Component sum is authoritative for the fuel system: drop 52X FUEL's own values
fuelRow = cellfun(@(c) isequal(string(c), "52X FUEL"), raw(:, 1));
for j = find(paths ~= "")'
    raw{fuelRow, j} = 'N/A';
end

raw = addDataRecord(raw, "Placeholder", "Student team placeholder values (2026); units converted 2026-10");
writeTable(raw, file);
end

function migrateFuelProp()
file = which("FuelProp.xlsx");
raw = readcell(file);
paths = columnPaths(raw);
checkOld(raw, paths, "FuelComponentProfile.Pipe.FlowRate", file);
cfg = shipmbse.config();
nRows = size(raw, 1);

% 1. Convert units in place
for j = find(paths ~= "")'
    [factor, unit, perFuel] = valueFactor(paths(j));
    if isempty(factor)
        continue
    end
    raw{4, j} = char(unit);
    for r = 5:nRows
        v = raw{r, j};
        if isnumeric(v) && isscalar(v)
            if perFuel
                raw{r, j} = v * factor * cfg.FluidDensity("LUBE OIL");   % only lube consumption here
            else
                raw{r, j} = v * factor;
            end
        end
    end
end

% 2. Ship-level columns built from the component data
get = @(r, path) cellAt(raw, r, find(paths == path, 1));
fcp = "FuelComponentProfile.";
srcStereos = ["Controller", "FluidConditioner", "Pump"];
newCols = { ...
    "WeightsCentersProfile", "WeightsCenters", "Weight",       "(t)",     @(r) get(r, fcp + "Weights.Weight");
    "WeightsCentersProfile", "WeightsCenters", "LCG",          "(m)",     @(r) get(r, fcp + "Weights.LCG");
    "WeightsCentersProfile", "WeightsCenters", "VCG",          "(m)",     @(r) get(r, fcp + "Weights.VCG");
    "WeightsCentersProfile", "WeightsCenters", "TCG",          "(m)",     @(r) get(r, fcp + "Weights.TCG");
    "WeightsCentersProfile", "WeightsCenters", "WeightMargin", "%",       @(r) ifValue(get(r, fcp + "Weights.Weight"), 9);
    "ElectricalProfile",     "ElectricalConsumer", "PowerRequired", "(kW)", @(r) firstOf(get, r, fcp + srcStereos + ".PowerRequired");
    "ElectricalProfile",     "ElectricalConsumer", "Status",   "On/Off",  @(r) statusFor(get, r, fcp + srcStereos, ".PowerRequired");
    "CoolingProfile",        "CoolConsumer",   "CoolConsumed", "kW",      @(r) firstOf(get, r, fcp + srcStereos + ".CoolConsumption");
    "CoolingProfile",        "CoolConsumer",   "Status",       "On/Off",  @(r) statusFor(get, r, fcp + srcStereos, ".CoolConsumption");
    "LubeProfile",           "LubeConsumer",   "LubeRequired", "t/h",     @(r) firstOf(get, r, fcp + ["FluidConditioner", "Pump"] + ".LubeConsumption");
    "LubeProfile",           "LubeConsumer",   "Status",       "On/Off",  @(r) statusFor(get, r, fcp + ["FluidConditioner", "Pump"], ".LubeConsumption");
    "HeatProfile",           "HeatConsumer",   "HeatConsumed", "kW",      @(r) get(r, fcp + "FluidConditioner.HeatConsumed");
    "HeatProfile",           "HeatConsumer",   "Status",       "On/Off",  @(r) statusFor(get, r, fcp + "FluidConditioner", ".HeatConsumed");
    "WasteProfile",          "WasteOilProducer", "WOProduced", "m^3/day", @(r) get(r, fcp + "FluidConditioner.WasteOilProduced");
    "WasteProfile",          "WasteOilProducer", "Status",     "On/Off",  @(r) statusFor(get, r, fcp + "FluidConditioner", ".WasteOilProduced");
    "FuelProfile",           "FuelProducer",   "FuelProduced", "t/h",     @(r) pipeFuelMass(get, r, cfg);
    "FuelProfile",           "FuelProducer",   "Status",       "On/Off",  @(r) statusFor(get, r, fcp + "Pipe", ".FlowRate")};
added = cell(nRows, size(newCols, 1));
for k = 1:size(newCols, 1)
    added(1:4, k) = cellfun(@char, newCols(k, 1:4), 'UniformOutput', false)';
    for r = 5:nRows
        added{r, k} = newCols{k, 5}(r);
    end
end

% 3. Drop the duplicated component columns
drop = startsWith(paths, fcp + "Weights.") | ...
    ismember(paths, [fcp + srcStereos + ".PowerRequired", fcp + srcStereos + ".CoolConsumption", ...
                     fcp + ["FluidConditioner", "Pump"] + ".LubeConsumption", ...
                     fcp + "FluidConditioner." + ["HeatConsumed", "WasteOilProduced"]]);
raw = [raw(:, ~drop'), added];
raw{1, 1} = 'Profile-->';
raw = addDataRecord(raw, "Placeholder", "Student team placeholder values (2026); units converted 2026-10");
writeTable(raw, file);
end

% =============================================================================
function [factor, unit, perFuel] = valueFactor(path)
% Conversion of a column's values; empty factor = unchanged
perFuel = false;
p = extractAfter(path, ".");   % Stereotype.Property
switch p
    case "FuelConsumer.FuelRequired"
        [factor, unit, perFuel] = deal(3600, "t/h", true);        % kL/s -> m^3/h x density(FuelType)
    case {"FuelProducer.FuelProduced"}
        [factor, unit] = deal(3600 * 0.98, "t/h");                 % only on 52X FUEL (removed)
    case "FuelProducer.FuelStored"
        [factor, unit] = deal(0.98, "t");                          % only on 52X FUEL (removed)
    case {"LubeConsumer.LubeRequired", "LubeProducer.LubeProduced"}
        [factor, unit] = deal(3600 * 0.90, "t/h");
    case {"AirConsumer.AirConsumed", "AirProducer.AirProduced"}
        [factor, unit] = deal(3600, "Nm^3/h");
    case {"WasteGasProducer.WGProduced", "WasteReceiver.WGReceived"}
        [factor, unit] = deal(3600 * 1.2, "kg/h");
    case {"WasteOilProducer.WOProduced", "WasteReceiver.WOReceived", ...
          "WasteWaterProducer.WWProduced", "WasteReceiver.WWReceived", ...
          "FluidConditioner.WasteOilProduced"}
        [factor, unit] = deal(86400, "m^3/day");
    case {"WasteSolidProducer.WSProduced", "WasteReceiver.WSReceived"}
        [factor, unit] = deal(86400 * 200, "kg/day");
    case {"FluidConditioner.MaxFlowCapacity", "FluidConditioner.PriFlowRate", "FluidConditioner.SecFlowRate", ...
          "FluidConditioner.TerFlowRate", "Pump.MaxFlowCapacity", "Pump.PriFlowRate", "Pump.SecFlowRate", ...
          "Pump.TerFlowRate", "Pipe.FlowRate"}
        [factor, unit] = deal(3600, "m^3/h");
    case {"FluidConditioner.LubeConsumption", "Pump.LubeConsumption"}
        [factor, unit, perFuel] = deal(3600, "t/h", true);         % x lube density
    case "Pipe.FluidDensity"
        [factor, unit] = deal(1, "kg/m^3");
    case {"Tank.PrimaryFluidCapacity", "Tank.SecondaryFluidCapacity", "Tank.TertiaryFluidCapacity", ...
          "Tank.PrimaryFluidLevel", "Tank.SecondaryFluidLevel", "Tank.TertiaryFluidLevel"}
        [factor, unit] = deal(1, "m^3");
    otherwise
        [factor, unit] = deal([], "");
end
end

function paths = columnPaths(raw)
paths = strings(size(raw, 2), 1);
for j = 2:size(raw, 2)
    h = cellfun(@(c) string(c), raw(1:3, j));
    if all(~ismissing(h)) && all(h ~= "")
        paths(j) = strjoin(h, ".");
    end
end
end

function checkOld(raw, paths, probe, file)
unit = erase(string(raw{4, find(paths == probe, 1)}), ["(", ")"]);
if ~ismember(unit, ["kL/s", "kL"])
    error("migrate:AlreadyDone", "%s: %s is in ""%s"", not kL/s; already migrated?", file, probe, unit);
end
end

function v = cellAt(raw, r, j)
v = 'N/A';
if ~isempty(j)
    v = raw{r, j};
end
end

function tf = hasValue(v)
tf = (isnumeric(v) || islogical(v)) && isscalar(v) && ~ismissing(v);
end

function v = ifValue(src, value)
v = 'N/A';
if hasValue(src)
    v = value;
end
end

function v = firstOf(get, r, paths)
v = 'N/A';
for p = paths
    x = get(r, p);
    if hasValue(x)
        v = x;
        return
    end
end
end

function v = statusFor(get, r, stereos, valueProp)
% Status of the first stereotype that has a value for valueProp
v = 'N/A';
for s = stereos
    if hasValue(get(r, s + valueProp))
        st = get(r, s + ".Status");
        if hasValue(st)
            v = logical(st);
        else
            v = true;
        end
        return
    end
end
end

function v = pipeFuelMass(get, r, cfg)
v = 'N/A';
flow = get(r, "FuelComponentProfile.Pipe.FlowRate");      % already m^3/h
fluid = upper(strtrim(string(get(r, "FuelComponentProfile.Pipe.Fluid"))));
if hasValue(flow) && isKey(cfg.FluidDensity, fluid)
    v = flow * cfg.FluidDensity(fluid);
end
end

function raw = addDataRecord(raw, maturity, source)
hasData = false(size(raw, 1), 1);
for r = 5:size(raw, 1)
    hasData(r) = any(cellfun(@(c) (isnumeric(c) || islogical(c)) && isscalar(c) && ~ismissing(c) ...
        || ((ischar(c) || isstring(c)) && ~ismember(upper(strtrim(string(c))), ["", "N/A"])), raw(r, 2:end)));
end
rec = cell(size(raw, 1), 2);
rec(1:4, :) = {'ShipElementProfile', 'ShipElementProfile'; 'DataRecord', 'DataRecord'; ...
               'Maturity', 'DataSource'; strjoin(shipmbse.config().MaturityLevels, ' | '), 'string'};
for r = 5:size(raw, 1)
    if hasData(r)
        rec(r, :) = {char(maturity), char(source)};
    else
        rec(r, :) = {'N/A', 'N/A'};
    end
end
raw = [raw(:, 1), rec, raw(:, 2:end)];
end

function writeTable(raw, file)
raw(cellfun(@(c) isscalar(c) && ismissing(c), raw)) = {''};
tmp = [tempname, '.xlsx'];
writecell(raw, tmp);
movefile(tmp, file, 'f');
fprintf('Rewrote %s (%d rows x %d columns).\n', file, size(raw, 1), size(raw, 2));
end
