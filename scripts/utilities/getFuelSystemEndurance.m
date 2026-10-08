function minDays = getFuelSystemEndurance(modelName)
%GETFUELSYSTEMENDURANCE Limiting fuel endurance of the active configuration, in days.
%   minDays = getFuelSystemEndurance() computes endurance for the model
%   named in shipmbse.config; getFuelSystemEndurance(modelName) for another
%   model. For each fuel type demanded by an active, On FuelConsumer,
%   endurance is usable storage divided by demand rate (with unit
%   conversion to days); the minimum over fuel types is returned.
%
%   Wrapper around shipmbse.fuelEndurance, which also returns the per-fuel
%   breakdown.
%
%   See also shipmbse.fuelEndurance.

arguments
    modelName (1,1) string = shipmbse.config().ModelName
end

minDays = shipmbse.fuelEndurance(shipmbse.loadModel(modelName));

end
