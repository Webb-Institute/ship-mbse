function minDays = getFuelSystemEndurance(modelName)
if ~bdIsLoaded(modelName)
    open_system(modelName);
end
modelObj = systemcomposer.loadModel(modelName);

SECONDS_PER_DAY    = 86400;
tankStereotype     = 'Tank';
consumerStereotype = 'FuelConsumer';

% Get all components recursively
allComps = systemcomposer.arch.Component.empty;
if ~isempty(modelObj.Architecture)
    queue = modelObj.Architecture.Components;
    while ~isempty(queue)
        c = queue(1); queue(1) = [];
        allComps(end+1) = c; %#ok<AGROW>
        if ~isempty(c.Architecture) && ~isempty(c.Architecture.Components)
            queue = [queue, c.Architecture.Components]; %#ok<AGROW>
        end
    end
end

% 1. Sum Tank Capacities per Fluid
tankCaps = containers.Map('KeyType', 'char', 'ValueType', 'double');
for i = 1:length(allComps)
    c = allComps(i); stList = getStereotypes(c);
    if ~any(endsWith(stList, tankStereotype)), continue; end
    st = stList{find(endsWith(stList, tankStereotype), 1)};

    for layer = {'PriFluid', 'PrimaryFluidCapacity'; 'SecFluid', 'SecondaryFluidCapacity'; 'TerFluid', 'TertiaryFluidCapacity'}'
        try
            fluid = upper(strtrim(char(string(c.getEvaluatedPropertyValue([st '.' layer{1}])))));
            cap   = double(c.getEvaluatedPropertyValue([st '.' layer{2}]));
            if ~isempty(fluid) && ~isnan(cap) && cap > 0
                if isKey(tankCaps, fluid), tankCaps(fluid) = tankCaps(fluid) + cap;
                else, tankCaps(fluid) = cap; end
            end
        catch; end
    end
end

% 2. Sum Consumer Demands per Fluid
dailyDemand = containers.Map('KeyType', 'char', 'ValueType', 'double');
for i = 1:length(allComps)
    c = allComps(i); stList = getStereotypes(c);
    if ~any(endsWith(stList, consumerStereotype)), continue; end
    st = stList{find(endsWith(stList, consumerStereotype), 1)};

    try
        fuel = upper(strtrim(char(string(c.getEvaluatedPropertyValue([st '.FuelType'])))));
        rate = double(c.getEvaluatedPropertyValue([st '.FuelRequired']));
        if ~isempty(fuel) && ~isnan(rate) && rate > 0
            dRate = rate * SECONDS_PER_DAY;
            if isKey(dailyDemand, fuel), dailyDemand(fuel) = dailyDemand(fuel) + dRate;
            else, dailyDemand(fuel) = dRate; end
        end
    catch; end
end

% 3. Calculate Limiting Days
activeFuels = keys(dailyDemand);
minDays = Inf;
for i = 1:length(activeFuels)
    f = activeFuels{i};
    if isKey(tankCaps, f)
        days = tankCaps(f) / dailyDemand(f);
        if days < minDays, minDays = days; end
    else
        minDays = 0;
    end
end
end