function [results, details] = serviceBalance(model)
%SERVICEBALANCE Demand versus capacity for each ship service domain.
%   results = shipmbse.serviceBalance() returns one row per domain
%   (electrical, fuel, lube, cooling, compressed air, heat, and each waste
%   stream) with Demand, NumDemand, Capacity, NumCapacity, Margin, Unit and
%   Shortfall, summing only active components whose Status is on.
%   Margin = capacity - demand, so a negative margin is a shortfall in every
%   domain. For waste streams the producers are the demand and the
%   receivers are the capacity.
%
%   [results, details] also returns a struct array (one per domain) with
%   fields Domain, DemandProperty, CapacityProperty, DemandLabel,
%   CapacityLabel, Demand and Capacity (per-component tables from
%   shipmbse.sumProperty).
%
%   See also systemsReport, shipmbse.sumProperty.

arguments
    model (1,1) systemcomposer.arch.Model = shipmbse.loadModel()
end

st = shipmbse.config().Stereotypes;
%          Domain            Demand property                            Capacity property                           Demand label        Capacity label
domains = ["ELECTRICAL",     st.ElectricalConsumer + ".PowerRequired",  st.ElectricalGenerator + ".PowerGenerated", "CONSUMERS",        "GENERATORS";
           "FUEL OIL",       st.FuelConsumer + ".FuelRequired",         st.FuelProducer + ".FuelProduced",          "CONSUMERS",        "PRODUCERS";
           "LUBE OIL",       st.LubeConsumer + ".LubeRequired",         st.LubeProducer + ".LubeProduced",          "CONSUMERS",        "PRODUCERS";
           "COOLING / FW",   st.CoolConsumer + ".CoolConsumed",         st.CoolProducer + ".CoolProduced",          "CONSUMERS",        "PRODUCERS";
           "COMPRESSED AIR", st.AirConsumer + ".AirConsumed",           st.AirProducer + ".AirProduced",            "CONSUMERS",        "PRODUCERS";
           "HEAT",           st.HeatConsumer + ".HeatConsumed",         st.HeatProducer + ".HeatProduced",          "CONSUMERS",        "PRODUCERS";
           "WASTE GAS",      st.WasteGasProducer + ".WGProduced",       st.WasteReceiver + ".WGReceived",           "WASTE PRODUCERS",  "WASTE RECEIVERS";
           "WASTE OIL",      st.WasteOilProducer + ".WOProduced",       st.WasteReceiver + ".WOReceived",           "WASTE PRODUCERS",  "WASTE RECEIVERS";
           "WASTE WATER",    st.WasteWaterProducer + ".WWProduced",     st.WasteReceiver + ".WWReceived",           "WASTE PRODUCERS",  "WASTE RECEIVERS";
           "WASTE SOLID",    st.WasteSolidProducer + ".WSProduced",     st.WasteReceiver + ".WSReceived",           "WASTE PRODUCERS",  "WASTE RECEIVERS"];

n = size(domains, 1);
results = table('Size', [n 8], ...
    'VariableTypes', {'string', 'double', 'double', 'double', 'double', 'double', 'string', 'logical'}, ...
    'VariableNames', {'Domain', 'Demand', 'NumDemand', 'Capacity', 'NumCapacity', 'Margin', 'Unit', 'Shortfall'});
details = struct('Domain', cell(n, 1), 'DemandProperty', [], 'CapacityProperty', [], ...
    'DemandLabel', [], 'CapacityLabel', [], 'Demand', [], 'Capacity', []);
for d = 1:n
    [demand, dDet] = shipmbse.sumProperty(domains(d, 2), OnlyIfOn=true, Model=model);
    [capacity, cDet] = shipmbse.sumProperty(domains(d, 3), OnlyIfOn=true, Model=model);
    dUnit = shipmbse.propertyInfo(domains(d, 2), model).Units;
    cUnit = shipmbse.propertyInfo(domains(d, 3), model).Units;
    if dUnit == cUnit
        margin = capacity - demand;
    else
        margin = NaN;   % units differ: no margin without conversion
    end
    results(d, :) = {domains(d, 1), demand, sum(dDet.Included), capacity, sum(cDet.Included), ...
        margin, cUnit, margin < 0};
    details(d) = struct('Domain', domains(d, 1), 'DemandProperty', domains(d, 2), ...
        'CapacityProperty', domains(d, 3), 'DemandLabel', domains(d, 4), ...
        'CapacityLabel', domains(d, 5), 'Demand', dDet, 'Capacity', cDet);
end

end
