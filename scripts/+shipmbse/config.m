function cfg = config()
%CONFIG Central ship-mbse configuration: model, component paths, profiles, data files.
%   cfg = shipmbse.config() returns a struct holding every name that scripts
%   would otherwise hard-code. Change names here, not in individual scripts.
%
%   Fields:
%     ModelName       Architecture model name
%     RequirementSet  Requirement set name
%     Paths           Component paths relative to the model root
%     Stereotypes     Fully qualified stereotype names (Profile.Stereotype)
%     Excel           Property table file names (on the project path)
%
%   See also shipmbse.loadModel, getOutputDir.

cfg.ModelName      = "SYSTEM";
cfg.RequirementSet = "ShipRequirements";

% Component paths, relative to the model root (lookup with "<ModelName>/<path>")
ship = "SHIP";
aux  = ship + "/500 (AUXILLIARY SYSTEMS)";
cfg.Paths.Ship        = ship;
cfg.Paths.Propulsion  = ship + "/200 (PROPULSION)";
cfg.Paths.Auxiliary   = aux;
cfg.Paths.Fuel        = aux + "/52X (FUEL)";
cfg.Paths.FuelActive  = aux + "/52X (FUEL)/52X FUEL";

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

% Name of the on/off property shared by resource stereotypes
cfg.StatusProperty = "Status";

% Excel property tables (resolved on the project path)
cfg.Excel.Properties = "Properties.xlsx";
cfg.Excel.FuelProp   = "FuelProp.xlsx";

end
