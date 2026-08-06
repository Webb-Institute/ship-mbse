function minDays = getFuelSystemEndurance(modelName)
% GETFUELSYSTEMENDURANCE Calculates operational fuel endurance in days.
%
% Syntax:
%   minDays = getFuelSystemEndurance(modelName)
%
% Workflow:
%   1. Load model and query components using System Composer query engine.
%   2. Check 'FuelComponentProfile' ('Tank' stereotype) for tank capacities.
%   3. If NO 'FuelComponentProfile' components exist:
%      - Read 'FuelProfile' for FuelStored (de-duplicated across reference handles).
%   4. Check 'FuelProfile' ('FuelConsumer' stereotype) for active consumers.
%   5. Compute operational days remaining.

    import systemcomposer.query.*
    modelName = 'SYSTEM';
    % 1. Load Model and Query All Components
    if ~bdIsLoaded(modelName)
        open_system(modelName);
    end
    modelObj = systemcomposer.loadModel(modelName);

    rawComps = findElementsOfType(modelObj, 'Component');

    tankCaps = containers.Map('KeyType', 'char', 'ValueType', 'double');
    dailyDemand = containers.Map('KeyType', 'char', 'ValueType', 'double');
    hasComponentProfileStorage = false;

    % 2. Check FuelComponentProfile for 'Tank' Stereotypes
    for i = 1:length(rawComps)
        c = rawComps(i);
        stList = getCompStereotypes(c);
        
        tankIdx = find(contains(stList, 'FuelComponentProfile', 'IgnoreCase', true) | ...
                       endsWith(stList, 'Tank', 'IgnoreCase', true), 1);
        
        if isempty(tankIdx)
            continue;
        end

        st = stList{tankIdx};
        hasComponentProfileStorage = true;

        % Evaluate Primary, Secondary, and Tertiary fluid layers
        layers = {'PriFluid', 'PrimaryFluidCapacity'; ...
                  'SecFluid', 'SecondaryFluidCapacity'; ...
                  'TerFluid', 'TertiaryFluidCapacity'};

        for L = 1:size(layers, 1)
            fluidProp    = [st '.' layers{L, 1}];
            capacityProp = [st '.' layers{L, 2}];
            try
                rawFluid = strtrim(char(string(c.getEvaluatedPropertyValue(fluidProp))));
                fluid    = upper(rawFluid);
                cap      = double(c.getEvaluatedPropertyValue(capacityProp));

                if ~isempty(fluid) && ~strcmpi(fluid, 'N/A') && ~strcmpi(fluid, 'NONE') && ~isnan(cap) && cap > 0
                    if isKey(tankCaps, fluid)
                        tankCaps(fluid) = tankCaps(fluid) + cap;
                    else
                        tankCaps(fluid) = cap;
                    end
                end
            catch
            end
        end
    end

    % 3. Check FuelProfile for FuelStored (If FuelComponentProfile was absent)
    totalProducerStorage = 0;

    if ~hasComponentProfileStorage
        % A. Check workspace 'FuelProfile' struct first
        FuelProfile = getWorkspaceVariable('FuelProfile');
        
        if ~isempty(FuelProfile) && isstruct(FuelProfile)
            if isfield(FuelProfile, 'FuelProducer') && ~isempty(FuelProfile.FuelProducer)
                producers = FuelProfile.FuelProducer;
                for p = 1:numel(producers)
                    if isfield(producers(p), 'FuelStored') && ~isempty(producers(p).FuelStored)
                        totalProducerStorage = totalProducerStorage + sum(double(producers(p).FuelStored(:)));
                    end
                end
            elseif isfield(FuelProfile, 'FuelStored') && ~isempty(FuelProfile.FuelStored)
                totalProducerStorage = sum(double(FuelProfile.FuelStored(:)));
            end
        end

        % B. Check model components ONLY IF workspace yielded no stored fuel
        if totalProducerStorage == 0
            producerVals = [];

            for i = 1:length(rawComps)
                c = rawComps(i);
                stList = getCompStereotypes(c);

                % Match components that explicitly have FuelProducer attached
                pIdx = find(endsWith(stList, 'FuelProducer', 'IgnoreCase', true) | ...
                            contains(stList, 'FuelProducer', 'IgnoreCase', true), 1);

                if ~isempty(pIdx)
                    st = stList{pIdx};
                    try
                        val = double(c.getEvaluatedPropertyValue([st '.FuelStored']));
                        if ~isnan(val) && val > 0
                            producerVals(end+1) = val; %#ok<AGROW>
                        end
                    catch
                    end
                end
            end

            % De-duplicate storage values across instance/definition handle pairs
            if ~isempty(producerVals)
                totalProducerStorage = sum(unique(producerVals));
            end
        end

        if totalProducerStorage <= 0
            error('getFuelSystemEndurance:NoStorageFound', ...
                'No valid fuel storage found in FuelComponentProfile or FuelProfile.');
        end
    end

    % 4. Check FuelProfile.FuelConsumer for Consumer Demand
    % A. Check workspace FuelProfile.FuelConsumer struct first
    FuelProfile = getWorkspaceVariable('FuelProfile');
    
    if ~isempty(FuelProfile) && isstruct(FuelProfile) && ...
       isfield(FuelProfile, 'FuelConsumer') && ~isempty(FuelProfile.FuelConsumer)
        
        consumers = FuelProfile.FuelConsumer;
        for cIdx = 1:numel(consumers)
            cObj = consumers(cIdx);

            % Check Status ('On' / 'Off')
            isOn = true;
            if isfield(cObj, 'Status')
                stVal = cObj.Status;
                if islogical(stVal) || isnumeric(stVal)
                    isOn = logical(stVal);
                else
                    isOn = strcmpi(strtrim(char(string(stVal))), 'On');
                end
            end

            if ~isOn
                continue; % Skip inactive consumer
            end

            if isfield(cObj, 'FuelRequired') && ~isempty(cObj.FuelRequired) && cObj.FuelRequired > 0
                reqRate = sum(double(cObj.FuelRequired(:)));
                fType = 'PRIMARY';
                if isfield(cObj, 'FuelType') && ~isempty(cObj.FuelType)
                    fType = upper(strtrim(char(string(cObj.FuelType))));
                end

                if isKey(dailyDemand, fType)
                    dailyDemand(fType) = dailyDemand(fType) + reqRate;
                else
                    dailyDemand(fType) = reqRate;
                end
            end
        end
    end

    % B. Fallback to model components if workspace FuelConsumer was empty
    if dailyDemand.Count == 0
        seenConsumerComps = containers.Map('KeyType', 'char', 'ValueType', 'logical');

        for i = 1:length(rawComps)
            c = rawComps(i);
            stList = getCompStereotypes(c);

            cIdx = find(endsWith(stList, 'FuelConsumer', 'IgnoreCase', true) | ...
                        contains(stList, 'FuelConsumer', 'IgnoreCase', true), 1);
            if isempty(cIdx)
                continue;
            end

            compName = char(string(c.Name));
            if isKey(seenConsumerComps, compName)
                continue; % Prevent counting reference instance + definition twice
            end

            st = stList{cIdx};

            try
                reqRate = double(c.getEvaluatedPropertyValue([st '.FuelRequired']));
                if ~isnan(reqRate) && reqRate > 0
                    isOn = true;
                    try
                        statusVal = c.getEvaluatedPropertyValue([st '.Status']);
                        if islogical(statusVal) || isnumeric(statusVal)
                            isOn = logical(statusVal);
                        else
                            isOn = strcmpi(strtrim(char(string(statusVal))), 'On');
                        end
                    catch
                    end

                    if ~isOn
                        continue;
                    end

                    fuelType = 'PRIMARY';
                    try
                        ftVal = char(string(c.getEvaluatedPropertyValue([st '.FuelType'])));
                        if ~isempty(strtrim(ftVal))
                            fuelType = upper(strtrim(ftVal));
                        end
                    catch
                    end

                    if isKey(dailyDemand, fuelType)
                        dailyDemand(fuelType) = dailyDemand(fuelType) + reqRate;
                    else
                        dailyDemand(fuelType) = reqRate;
                    end

                    seenConsumerComps(compName) = true;
                end
            catch
            end
        end
    end

    % 5. Compute Operational Days
    minDays = Inf;
    activeFuels = keys(dailyDemand);

    if isempty(activeFuels)
        warning('getFuelSystemEndurance:NoActiveDemand', ...
            'No active fuel consumers found. Endurance is infinite.');
        return;
    end

    if hasComponentProfileStorage
        % Compute limiting days across active fluid types in tanks
        for k = 1:length(activeFuels)
            f = activeFuels{k};
            demand = dailyDemand(f);

            if isKey(tankCaps, f)
                days = tankCaps(f) / demand;
            else
                days = 0; % Consumer needs a fluid type not present in tank storage
            end

            if days < minDays
                minDays = days;
            end
        end
    else
        % Compute days using single producer storage total
        totalDemand = 0;
        for k = 1:length(activeFuels)
            totalDemand = totalDemand + dailyDemand(activeFuels{k});
        end
        
        if totalDemand > 0
            minDays = totalProducerStorage / totalDemand;
        end
    end
end

% Helper Functions
function stList = getCompStereotypes(c)
    stList = {};
    try
        stList = c.getStereotypes();
    catch
        try
            stList = getStereotypes(c);
        catch
        end
    end
    if isstring(stList)
        stList = cellstr(stList);
    elseif ischar(stList)
        stList = {stList};
    end
end

function val = getWorkspaceVariable(varName)
    if evalin('caller', sprintf('exist(''%s'', ''var'')', varName))
        val = evalin('caller', varName);
    elseif evalin('base', sprintf('exist(''%s'', ''var'')', varName))
        val = evalin('base', varName);
    else
        val = [];
    end
end