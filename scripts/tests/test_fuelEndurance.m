function tests = test_fuelEndurance
    tests = functiontests(localfunctions);
end

function test_FuelSupplyVersusDemand(testCase)
    modelName = 'SYSTEM';
    
    % Checks if Model is Open, and opens the model if it is closed
    if ~bdIsLoaded(modelName)
        open_system(modelName);
    end
    
    % Creating Model Object
    modelObj = systemcomposer.loadModel(modelName);
    
    % Target Requirement (Days)
    totalEndurance = 100; % days
    
    % Unit Conversion Factor: 86,400 seconds in 1 day
    SECONDS_PER_DAY = 86400; 
    
    % Stereotype and Property Names
    consumerStereotype = 'FuelConsumer';
    compFuelProp       = 'FuelType';                            
    compRateProp       = 'FuelRequired'; % Expects flow rate in m^3/s
    
    tankStereotype     = 'Tank';        
    primaryCapProp     = 'PrimaryFluidCapacity';   % Expects capacity in m^3
    secondaryCapProp   = 'SecondaryFluidCapacity'; % Expects capacity in m^3
    tertiaryCapProp    = 'TertiaryFluidCapacity';  % Expects capacity in m^3
    
    tankPrimaryFluid   = 'PriFluid';
    tankSecondaryFluid = 'SecFluid';
    tankTertiaryFluid  = 'TerFluid';

    % Get All Model Components Recursively (Inline Queue)
    allComps = systemcomposer.arch.Component.empty;
    
    if ~isempty(modelObj.Architecture)
        queue = modelObj.Architecture.Components;
        
        while ~isempty(queue)
            c = queue(1);
            queue(1) = []; % Pop top component
            
            allComps(end+1) = c; %#ok<AGROW>
            
            if ~isempty(c.Architecture) && ~isempty(c.Architecture.Components)
                queue = [queue, c.Architecture.Components]; %#ok<AGROW>
            end
        end
    end

    % 1. Query Tank Capacities per Fluid Type (Active Components Only)
    tankCapacities = containers.Map('KeyType', 'char', 'ValueType', 'double');

    for i = 1:length(allComps)
        c = allComps(i);
        
        % Robust Stereotype Check
        stList = getStereotypes(c);
        if ~any(endsWith(stList, tankStereotype))
            continue;
        end
        
        % Robust Active Variant Check (Traverse Component -> Architecture -> Parent Component)
        isActive = true;
        curr = c;
        while ~isempty(curr)
            parentArch = curr.Parent;
            if isempty(parentArch) || ~isa(parentArch, 'systemcomposer.arch.Architecture')
                break;
            end
            
            parentComp = parentArch.Parent;
            if isempty(parentComp)
                break;
            end
            
            if isa(parentComp, 'systemcomposer.arch.VariantComponent')
                activeChoice = getActiveChoice(parentComp);
                if isempty(activeChoice) || activeChoice ~= curr
                    isActive = false;
                    break;
                end
            end
            curr = parentComp;
        end
        
        if ~isActive
            continue;
        end
        
        % Identify fully qualified stereotype string for properties
        stIdx = find(endsWith(stList, tankStereotype), 1);
        qualStereotype = stList{stIdx};
        
        % Check Primary Tank Layer (m^3)
        try
            pFluid = char(string(c.getEvaluatedPropertyValue([qualStereotype '.' tankPrimaryFluid])));
            pCap   = double(c.getEvaluatedPropertyValue([qualStereotype '.' primaryCapProp]));
            if ~isempty(pFluid) && ~isnan(pCap) && pCap > 0
                if isKey(tankCapacities, pFluid)
                    tankCapacities(pFluid) = tankCapacities(pFluid) + pCap;
                else
                    tankCapacities(pFluid) = pCap;
                end
            end
        catch; end

        % Check Secondary Tank Layer (m^3)
        try
            sFluid = char(string(c.getEvaluatedPropertyValue([qualStereotype '.' tankSecondaryFluid])));
            sCap   = double(c.getEvaluatedPropertyValue([qualStereotype '.' secondaryCapProp]));
            if ~isempty(sFluid) && ~isnan(sCap) && sCap > 0
                if isKey(tankCapacities, sFluid)
                    tankCapacities(sFluid) = tankCapacities(sFluid) + sCap;
                else
                    tankCapacities(sFluid) = sCap;
                end
            end
        catch; end

        % Check Tertiary Tank Layer (m^3)
        try
            tFluid = char(string(c.getEvaluatedPropertyValue([qualStereotype '.' tankTertiaryFluid])));
            tCap   = double(c.getEvaluatedPropertyValue([qualStereotype '.' tertiaryCapProp]));
            if ~isempty(tFluid) && ~isnan(tCap) && tCap > 0
                if isKey(tankCapacities, tFluid)
                    tankCapacities(tFluid) = tankCapacities(tFluid) + tCap;
                else
                    tankCapacities(tFluid) = tCap;
                end
            end
        catch; end
    end

    % 2. Query Consumer Demands per Fuel Type (Active Components Only)
    dailyDemandPerFuel = containers.Map('KeyType', 'char', 'ValueType', 'double');

    for i = 1:length(allComps)
        c = allComps(i);
        
        % Robust Stereotype Check
        stList = getStereotypes(c);
        if ~any(endsWith(stList, consumerStereotype))
            continue;
        end

        % Robust Active Variant Check
        isActive = true;
        curr = c;
        while ~isempty(curr)
            parentArch = curr.Parent;
            if isempty(parentArch) || ~isa(parentArch, 'systemcomposer.arch.Architecture')
                break;
            end
            
            parentComp = parentArch.Parent;
            if isempty(parentComp)
                break;
            end
            
            if isa(parentComp, 'systemcomposer.arch.VariantComponent')
                activeChoice = getActiveChoice(parentComp);
                if isempty(activeChoice) || activeChoice ~= curr
                    isActive = false;
                    break;
                end
            end
            curr = parentComp;
        end
        
        if ~isActive
            continue;
        end

        % Identify fully qualified stereotype string for properties
        stIdx = find(endsWith(stList, consumerStereotype), 1);
        qualStereotype = stList{stIdx};

        try
            cFuelVal = c.getEvaluatedPropertyValue([qualStereotype '.' compFuelProp]);
            cFuel    = char(string(cFuelVal));
            
            cRateVal = c.getEvaluatedPropertyValue([qualStereotype '.' compRateProp]);
            cRate    = double(cRateVal); % Flow rate in m^3/s
            
            if ~isempty(cFuel) && ~isnan(cRate) && cRate > 0
                % Convert m^3/s to m^3/day
                cDaily = cRate * SECONDS_PER_DAY;
                
                if isKey(dailyDemandPerFuel, cFuel)
                    dailyDemandPerFuel(cFuel) = dailyDemandPerFuel(cFuel) + cDaily;
                else
                    dailyDemandPerFuel(cFuel) = cDaily;
                end
            end
        catch
            % Ignore components where property extraction fails
        end
    end

    % 3. Calculate Operational Endurance and Evaluate Test
    activeFuelTypes = keys(dailyDemandPerFuel);
    
    testCase.verifyNotEmpty(activeFuelTypes, 'No active fuel consumer components were found in the model!');

    minSystemDays = Inf;
    limitingFuelType = 'None';

    for i = 1:length(activeFuelTypes)
        fType = activeFuelTypes{i};
        dailyDemand = dailyDemandPerFuel(fType); % In m^3/day
        
        if isKey(tankCapacities, fType)
            totalCap = tankCapacities(fType);    % In m^3
            days = totalCap / dailyDemand;
            
            if days < minSystemDays
                minSystemDays = days;
                limitingFuelType = fType;
            end
        else
            minSystemDays = 0;
            limitingFuelType = fType;
        end
    end

    % Diagnostic Output
    fprintf('\n--------------------------------------------------\n');
    fprintf('Limiting Fuel Type  : %s\n', limitingFuelType);
    fprintf('Calculated Endurance: %.2f Days\n', minSystemDays);
    fprintf('Required Endurance  : %d Days\n', totalEndurance);
    fprintf('--------------------------------------------------\n');

    % 4. Assertion
    testCase.assertGreaterThanOrEqual(minSystemDays, totalEndurance, ...
        sprintf('FAIL: Endurance of %.2f days is below the %d-day requirement due to %s capacity!', ...
        minSystemDays, totalEndurance, limitingFuelType));
end