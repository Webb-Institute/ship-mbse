function [days, byFuel, consumers] = fuelEndurance(model)
%FUELENDURANCE Fuel endurance of the active configuration, in days.
%   days = shipmbse.fuelEndurance() returns the limiting endurance: for each
%   fuel type demanded by an active, On FuelConsumer, usable storage divided
%   by demand rate, converted to days with the profile units. The result is
%   the minimum over fuel types.
%
%   [days, byFuel, consumers] = shipmbse.fuelEndurance(...) also returns
%     byFuel     one row per fuel type: Fuel, Storage, StorageUnit, Demand,
%                DemandUnit, Days
%     consumers  one row per FuelConsumer: Path, Fuel, Rate, On
%
%   Storage source:
%     * Tank components (FuelComponentProfile.Tank): capacity per fluid from
%       the Primary/Secondary/Tertiary fluid and capacity properties.
%       Consumers draw only on tanks holding their FuelType.
%     * Otherwise FuelProducer.FuelStored, treated as one pool usable by all
%       fuel types.
%
%   A consumer with a blank FuelType is listed as "UNSPECIFIED". With tank
%   storage it matches no tank, so endurance for it is 0 days.
%   Returns Inf (with a warning) if no consumer is on.
%
%   See also shipmbse.durationToDays, shipmbse.sumProperty.

arguments
    model (1,1) systemcomposer.arch.Model = shipmbse.loadModel()
end

st = shipmbse.config().Stereotypes;

% --- Demand per fuel type -------------------------------------------------
[cComps, cPaths] = shipmbse.activeComponents(model, Stereotype=st.FuelConsumer);
n = numel(cComps);
fuel = strings(n, 1); rate = zeros(n, 1); on = false(n, 1);
for k = 1:n
    fuel(k) = normaliseFuel(shipmbse.getProp(cComps(k), st.FuelConsumer + ".FuelType"));
    rate(k) = shipmbse.getProp(cComps(k), st.FuelConsumer + ".FuelRequired");
    on(k) = shipmbse.getProp(cComps(k), st.FuelConsumer + ".Status");
end
consumers = table(cPaths, fuel, rate, on, 'VariableNames', {'Path', 'Fuel', 'Rate', 'On'});
rateUnit = shipmbse.propertyInfo(st.FuelConsumer + ".FuelRequired", model).Units;

demandFuels = unique(fuel(on & rate > 0));
if isempty(demandFuels)
    warning("shipmbse:fuelEndurance:NoDemand", "No active fuel consumer is on; endurance is infinite.");
    days = Inf;
    byFuel = table();
    return
end

% --- Storage per fluid ----------------------------------------------------
tanks = shipmbse.activeComponents(model, Stereotype=st.Tank);
if ~isempty(tanks)
    layers = ["PriFluid", "PrimaryFluidCapacity"; "SecFluid", "SecondaryFluidCapacity"; "TerFluid", "TertiaryFluidCapacity"];
    storage = dictionary(string.empty, double.empty);
    for t = 1:numel(tanks)
        for L = 1:size(layers, 1)
            f = normaliseFuel(shipmbse.getProp(tanks(t), st.Tank + "." + layers(L, 1)));
            cap = shipmbse.getProp(tanks(t), st.Tank + "." + layers(L, 2));
            if ismember(f, ["", "UNSPECIFIED", "N/A", "NONE"]) || ~(cap > 0)
                continue
            end
            if isKey(storage, f)
                storage(f) = storage(f) + cap;
            else
                storage(f) = cap;
            end
        end
    end
    storageUnit = shipmbse.propertyInfo(st.Tank + ".PrimaryFluidCapacity", model).Units;
    pooled = false;
else
    [pool, pDet] = shipmbse.sumProperty(st.FuelProducer + ".FuelStored", Model=model);
    if isempty(pDet) || pool <= 0
        error("shipmbse:fuelEndurance:NoStorage", ...
            "No fuel storage found (no Tank components and no FuelProducer.FuelStored).");
    end
    storageUnit = pDet.Unit(1);
    pooled = true;
end

% --- Endurance per fuel type ----------------------------------------------
m = numel(demandFuels);
byFuel = table(demandFuels, zeros(m, 1), repmat(storageUnit, m, 1), zeros(m, 1), ...
    repmat(rateUnit, m, 1), zeros(m, 1), ...
    'VariableNames', {'Fuel', 'Storage', 'StorageUnit', 'Demand', 'DemandUnit', 'Days'});
for k = 1:m
    byFuel.Demand(k) = sum(rate(on & fuel == demandFuels(k)));
    if pooled
        byFuel.Storage(k) = pool;
    elseif isKey(storage, demandFuels(k))
        byFuel.Storage(k) = storage(demandFuels(k));
    end
end
if pooled
    % One shared pool: every fuel type lasts as long as the pool at total demand
    byFuel.Days(:) = shipmbse.durationToDays(pool, storageUnit, sum(byFuel.Demand), rateUnit);
else
    byFuel.Days = shipmbse.durationToDays(byFuel.Storage, storageUnit, byFuel.Demand, rateUnit);
end
days = min(byFuel.Days);

end

function f = normaliseFuel(value)
f = upper(strtrim(string(value)));
if f == ""
    f = "UNSPECIFIED";
end
end
