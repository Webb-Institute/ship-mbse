function cfg = config()
%CONFIG Central ship-mbse configuration: model, component paths, profiles, data files.
%   cfg = shipmbse.config() returns a struct holding every name that scripts
%   would otherwise hard-code. Change names here, not in individual scripts.
%
%   Fields:
%     ModelName       Architecture model name
%     RequirementSet  Requirement set name
%     RootFolder      Repository root folder
%     Paths           Component paths relative to the model root
%     FuelSupplyPipes Fuel consumer path -> supplying pipe path (N-by-2)
%     Stereotypes     Fully qualified stereotype names (Profile.Stereotype)
%     Excel           Property table file names (on the project path)
%     MaturityLevels  Allowed DataRecord.Maturity values
%     FluidDensity    Nominal fluid densities (t/m^3) by upper-case fluid name
%
%   See also shipmbse.loadModel, getOutputDir.

cfg.ModelName      = "SYSTEM";
cfg.RequirementSet = "ShipRequirements";
cfg.RootFolder     = string(fileparts(fileparts(fileparts(mfilename("fullpath")))));

% Component paths, relative to the model root (lookup with "<ModelName>/<path>").
% These are Simulink block paths: write a "/" inside a component name as "//".
ship = "SHIP";
aux  = ship + "/500 (AUXILLIARY SYSTEMS)";
cfg.Paths.Ship        = ship;
cfg.Paths.Propulsion  = ship + "/200 (PROPULSION)";
cfg.Paths.Auxiliary   = aux;
cfg.Paths.Fuel        = aux + "/52X (FUEL)";

% Fuel consumers and the fuel-system pipe that supplies each one. Used by
% propagatePipeFluids to copy the consumer's FuelType onto the pipe's Fluid.
cfg.FuelSupplyPipes = [ ...
    ship + "/200 (PROPULSION)/20X (MAIN ENGINE)",   cfg.Paths.Fuel + "/52X FUEL/525 (ME FO PIPING)";
    ship + "/300 (ELECTRICAL)/30X (GENERATOR SETS)", cfg.Paths.Fuel + "/52X FUEL/526 (GS FO PIPING)";
    aux + "/55X (CARGO//MISSION)",                   cfg.Paths.Fuel + "/52X FUEL/527 (MISSION FO PIPING)"];

% Stereotypes (Profile.Stereotype)
cfg.Stereotypes.WeightsCenters      = "WeightsCentersProfile.WeightsCenters";
cfg.Stereotypes.ElectricalConsumer  = "ElectricalProfile.ElectricalConsumer";
cfg.Stereotypes.ElectricalGenerator = "ElectricalProfile.ElectricalGenerator";
cfg.Stereotypes.FuelConsumer        = "FuelProfile.FuelConsumer";
cfg.Stereotypes.FuelProducer        = "FuelProfile.FuelProducer";
cfg.Stereotypes.CoolConsumer        = "CoolingProfile.CoolConsumer";
cfg.Stereotypes.CoolProducer        = "CoolingProfile.CoolProducer";
cfg.Stereotypes.LubeConsumer        = "LubeProfile.LubeConsumer";
cfg.Stereotypes.LubeProducer        = "LubeProfile.LubeProducer";
cfg.Stereotypes.AirConsumer         = "CompAirProfile.AirConsumer";
cfg.Stereotypes.AirProducer         = "CompAirProfile.AirProducer";
cfg.Stereotypes.HeatConsumer        = "HeatProfile.HeatConsumer";
cfg.Stereotypes.HeatProducer        = "HeatProfile.HeatProducer";
cfg.Stereotypes.WasteGasProducer    = "WasteProfile.WasteGasProducer";
cfg.Stereotypes.WasteOilProducer    = "WasteProfile.WasteOilProducer";
cfg.Stereotypes.WasteWaterProducer  = "WasteProfile.WasteWaterProducer";
cfg.Stereotypes.WasteSolidProducer  = "WasteProfile.WasteSolidProducer";
cfg.Stereotypes.WasteReceiver       = "WasteProfile.WasteReceiver";
cfg.Stereotypes.Tank                = "FuelComponentProfile.Tank";
cfg.Stereotypes.Pump                = "FuelComponentProfile.Pump";
cfg.Stereotypes.Pipe                = "FuelComponentProfile.Pipe";
cfg.Stereotypes.FluidConditioner    = "FuelComponentProfile.FluidConditioner";
cfg.Stereotypes.Controller          = "FuelComponentProfile.Controller";
cfg.Stereotypes.FuelComponentWeight = "FuelComponentProfile.Weights";
cfg.Stereotypes.Criticality         = "CritRelRedProfile.Criticality";
cfg.Stereotypes.Redundancy          = "CritRelRedProfile.Redundancy";
cfg.Stereotypes.PortRedundancy      = "PortProfile.Redundancy";

cfg.Stereotypes.DataRecord          = "ShipElementProfile.DataRecord";

% Name of the on/off property shared by resource stereotypes
cfg.StatusProperty = "Status";

% Allowed values of DataRecord.Maturity, least to most mature
cfg.MaturityLevels = ["Placeholder", "Parametric", "Calculated", "Vendor", "Measured"];

% Nominal fluid densities at 15 degC (t/m^3), used to convert tank volumes
% (m^3) to fuel mass (t). Keys are upper-case fluid names as entered in the
% model. Assumptions; replace with project values when known.
cfg.FluidDensity = dictionary( ...
    ["HEAVY FUEL OIL", "MARINE DIESEL OIL", "F-76", "F76", "JP-5", "LUBE OIL"], ...
    [0.98,             0.89,                0.85,   0.85,  0.81,   0.90]);

% Excel property tables (resolved on the project path)
cfg.Excel.Properties = "Properties.xlsx";
cfg.Excel.FuelProp   = "FuelProp.xlsx";

end
