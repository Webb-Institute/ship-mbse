function systemsReport(cmd)
    % =========================================================================
    % FILE MANAGEMENT & AUTOMATIC RUN ID GENERATION
    % =========================================================================
    outputDir = 'Reports';
    modelName = 'SYSTEM';

    % Ensure output directory exists
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % --- SPECIAL COMMAND: Clear previous runs on demand ---
    if nargin > 0 && ~isempty(cmd)
        cmdStr = string(cmd);
        if any(strcmpi(cmdStr, ["reset", "clear"]))
            existingFiles = dir(fullfile(outputDir, 'SystemsReport_*.txt'));
            for k = 1:length(existingFiles)
                delete(fullfile(existingFiles(k).folder, existingFiles(k).name));
            end
            fprintf('SUCCESS: Cleared all previous iteration reports from "%s/".\n', outputDir);
            return; % Exit early after wiping directory
        else
            error('Invalid command "%s". The only optional argument supported is "clear" or "reset".', cmdStr);
        end
    end

    % --- AUTO-INCREMENT RUN COUNTER (Starts at 1) ---
    existingFiles = dir(fullfile(outputDir, 'SystemsReport_Run_*.txt'));
    runNums = [];
    for k = 1:length(existingFiles)
        tok = regexp(existingFiles(k).name, 'SystemsReport_Run_(\d+)', 'tokens');
        if ~isempty(tok)
            runNums(end+1) = str2double(tok{1}{1}); %#ok<AGROW>
        end
    end

    if isempty(runNums)
        nextNum = 1;
    else
        nextNum = max(runNums) + 1;
    end
    
    runID    = sprintf('Run_%03d', nextNum); % Generates Run_001, Run_002, ...
    fileName = fullfile(outputDir, sprintf('SystemsReport_%s.txt', runID));

    % =========================================================================
    % DOMAIN TOGGLES & FORMATTING SETUP
    % =========================================================================
    elec   = true; 
    fuel   = true;
    lube   = true;
    fwCool = true;
    cAir   = true;
    waste  = true;

    sepLine  = repmat('=', 1, 82);
    dashLine = repmat('-', 1, 82);

    % Column formats for standard (3-column) and waste (4-column) tables
    headerFormat  = '%-40s | %-25s | %-10s\n';
    rowFormat     = '%-40s | %-25s | %-10s\n';
    headerFormat2 = '%-35s | %-20s | %-12s | %-8s\n';
    rowFormat2    = '%-35s | %-20s | %-12s | %-8s\n';

    % =========================================================================
    % SYSTEM COMPOSER MODEL LOADING & VARIANT FILTERING
    % =========================================================================
    import systemcomposer.query.*

    if ~bdIsLoaded(modelName)
        open_system(modelName);
    end

    modelObj = systemcomposer.loadModel(modelName);
    compAllRaw = findElementsOfType(modelObj, 'Component');
   
    % --- INLINE FILTER: Exclude inactive variant components ---
    compAll = [];
    for i = 1:length(compAllRaw)
        comp = compAllRaw(i);

        % 1. Skip top-level Variant Component containers directly
        if isa(comp, 'systemcomposer.arch.VariantComponent')
            continue;
        end

        % 2. Resolve parent Variant Component container
        variantParent = [];
        if isprop(comp, 'Parent') && ~isempty(comp.Parent)
            if isa(comp.Parent, 'systemcomposer.arch.VariantComponent')
                variantParent = comp.Parent;
            elseif isprop(comp.Parent, 'Parent') && isa(comp.Parent.Parent, 'systemcomposer.arch.VariantComponent')
                variantParent = comp.Parent.Parent;
            end
        end

        % 3. Check active choice matching via UUID/SimulinkHandle comparison
        if ~isempty(variantParent)
            activeChoice = getActiveChoice(variantParent);
            if ~isempty(activeChoice)
                isSameComp = false;
                if isprop(comp, 'UUID') && isprop(activeChoice, 'UUID')
                    isSameComp = strcmp(comp.UUID, activeChoice.UUID);
                elseif isprop(comp, 'SimulinkHandle') && isprop(activeChoice, 'SimulinkHandle')
                    isSameComp = (comp.SimulinkHandle == activeChoice.SimulinkHandle);
                else
                    isSameComp = strcmp(comp.Name, activeChoice.Name);
                end

                % Skip if this component is NOT the active choice
                if ~isSameComp
                    continue;
                end
            end
        end

        % 4. Keep valid active or non-variant component
        compAll = [compAll; comp]; %#ok<AGROW>
    end

    % =========================================================================
    % FILE WRITING SETUP
    % =========================================================================
    fileID = fopen(fileName, 'wt');

    if fileID == -1
        error('Could not open file "%s" for writing. Check folder permissions.', fileName);
    end    

    % File handle cleanup guard
    cleanUp = onCleanup(@() fclose(fileID));

    titleText = 'VESSEL SYSTEMS REPORT';
    leftPad = floor((82 - length(titleText)) / 2);
    fprintf(fileID, '%s\n', sepLine);
    fprintf(fileID, '%*s%s\n', leftPad, '', titleText);
    fprintf(fileID, '%s\n\n', sepLine);

    % =========================================================================
    % STANDARD SINGLE-PROPERTY DOMAIN REPORTS
    % =========================================================================
    if elec
        processStandardDomain(fileID, compAll, 'ELECTRICAL REPORT', 'ElectricalProfile', ...
            'ElectricalConsumer', 'PowerRequired', 'Power Required (kW)', 'TOTAL POWER REQUIRED', ...
            'ElectricalGenerator', 'PowerGenerated', 'Power Generated (kW)', 'TOTAL POWER GENERATED', ...
            headerFormat, rowFormat);
    end

    if fuel
        processStandardDomain(fileID, compAll, 'FUEL REPORT', 'FuelProfile', ...
            'FuelConsumer', 'FuelRequired', 'Fuel Required (m^3/s)', 'TOTAL FUEL OIL REQUIRED', ...
            'FuelProducer', 'FuelProduced', 'Fuel Dispersed (m^3/s)', 'TOTAL FUEL OIL GENERATED', ...
            headerFormat, rowFormat);
    end

    if lube
        processStandardDomain(fileID, compAll, 'LUBE REPORT', 'LubeProfile', ...
            'LubeConsumer', 'LubeRequired', 'Lube Required (m^3/s)', 'TOTAL LUBE OIL REQUIRED', ...
            'LubeProducer', 'LubeProduced', 'Lube Dispersed (m^3/s)', 'TOTAL LUBE OIL GENERATED', ...
            headerFormat, rowFormat);
    end

    if fwCool
        processStandardDomain(fileID, compAll, 'COOLING/FW REPORT', 'CoolingProfile', ...
            'CoolConsumer', 'CoolConsumed', 'Cooling/FW Required (m^3/s)', 'TOTAL COOLING REQUIRED', ...
            'CoolProducer', 'CoolProduced', 'Cooling/FW Produced (m^3/s)', 'TOTAL COOLING GENERATED', ...
            headerFormat, rowFormat);
    end

    if cAir
        processStandardDomain(fileID, compAll, 'COMPRESSED AIR REPORT', 'CompAirProfile', ...
            'AirConsumer', 'AirConsumed', 'Comp Air Required (m^3/s)', 'TOTAL COMPRESSED AIR REQUIRED', ...
            'AirProducer', 'AirProduced', 'Comp Air Produced (m^3/s)', 'TOTAL COMPRESSED AIR GENERATED', ...
            headerFormat, rowFormat);
    end

    % =========================================================================
    % WASTE REPORT (4-Column Multi-Stream Layout)
    % =========================================================================
    if waste   
        profileName        = 'WasteProfile';
        consumerStereotype = 'WasteReceiver';
        statusProperty     = 'Status';

        wasteStreams = {
            'WGReceived', 'WGProduced', 'WasteGasProducer',   'Waste Gas',   'TOTAL WASTE GAS CONSUMED',   'TOTAL WASTE GAS GENERATED';
            'WOReceived', 'WOProduced', 'WasteOilProducer',   'Waste Oil',   'TOTAL WASTE OIL CONSUMED',   'TOTAL WASTE OIL GENERATED';
            'WWReceived', 'WWProduced', 'WasteWaterProducer', 'Waste Water', 'TOTAL WASTE WATER CONSUMED', 'TOTAL WASTE WATER GENERATED';
            'WSReceived', 'WSProduced', 'WasteSolidProducer', 'Waste Solid', 'TOTAL WASTE SOLID CONSUMED', 'TOTAL WASTE SOLID GENERATED'
        };

        fprintf(fileID, '\n\n');
        secTitle = 'WASTE REPORT';
        secPad   = floor((82 - length(secTitle)) / 2);
        fprintf(fileID, '%*s%s\n', secPad, '', secTitle);
        fprintf(fileID, '%s\n\n', dashLine);

        % --- WASTE CONSUMERS ---
        fprintf(fileID, '\n');
        subTitle = 'WASTE CONSUMERS';
        subPad   = floor((82 - length(subTitle)) / 2);
        fprintf(fileID, '%*s%s\n', subPad, '', subTitle);
        fprintf(fileID, '%s\n', dashLine);

        compNames  = string.empty(0, 1);
        conProp    = double.empty(0, 1);
        wasteType  = string.empty(0, 1);
        statusProp = string.empty(0, 1);

        for i = 1:length(compAll)
            comp = compAll(i);
            conStereoPath = [profileName, '.', consumerStereotype];
            if comp.hasStereotype(conStereoPath)
                for s = 1:size(wasteStreams, 1)
                    propName  = wasteStreams{s, 1};
                    typeLabel = wasteStreams{s, 4};
                    propPath  = [profileName, '.', consumerStereotype, '.', propName];
                    statPath  = [profileName, '.', consumerStereotype, '.', statusProperty];

                    compNames(end+1, 1)  = string(comp.Name); %#ok<AGROW>
                    conProp(end+1, 1)    = str2double(comp.getProperty(propPath)); %#ok<AGROW>
                    wasteType(end+1, 1)  = string(typeLabel); %#ok<AGROW>
                    statusProp(end+1, 1) = string(comp.getProperty(statPath)); %#ok<AGROW>
                end
            end
        end

        if ~isempty(compNames)
            printTable = table(compNames, conProp, wasteType, statusProp, ...
                'VariableNames', {'ComponentName', 'Consumer', 'Type', 'Status'});
            sortNumbers = str2double(regexp(printTable.ComponentName, '^\d+', 'match', 'once'));
            sortNumbers(isnan(sortNumbers)) = Inf;
            printTable.SortKey = sortNumbers;
            printTable = sortrows(printTable, {'SortKey', 'ComponentName'});

            fprintf(fileID, headerFormat2, 'Component Name', 'Waste Intake (m^3/s)', 'Waste Type', 'Status');
            fprintf(fileID, '%s\n', dashLine);

            for i = 1:height(printTable)
                nComp = string(printTable.ComponentName{i});
                prop  = string(printTable.Consumer(i));
                type  = string(printTable.Type(i));
                stat  = string(printTable.Status{i});
                if stat == "true", stat = 'On'; elseif stat == "false", stat = 'Off'; end
                fprintf(fileID, rowFormat2, nComp, prop, type, stat);
            end

            fprintf(fileID, '%s\n', dashLine);
            for s = 1:size(wasteStreams, 1)
                val = sumPropIfOn(compAll, profileName, consumerStereotype, wasteStreams{s, 1});
                fprintf(fileID, '%-35s | %-20.4f |\n', wasteStreams{s, 5}, val);
            end
            fprintf(fileID, '%s\n', sepLine);
        end

        % --- WASTE PRODUCERS ---
        fprintf(fileID, '\n');
        subTitle = 'WASTE PRODUCERS';
        subPad   = floor((82 - length(subTitle)) / 2);
        fprintf(fileID, '%*s%s\n', subPad, '', subTitle);
        fprintf(fileID, '%s\n', dashLine);

        compNames  = string.empty(0, 1);
        proProp    = double.empty(0, 1);
        statusProp = string.empty(0, 1);
        wasteType  = string.empty(0, 1);

        for i = 1:length(compAll)
            comp = compAll(i);
            for s = 1:size(wasteStreams, 1)
                proStereo = wasteStreams{s, 3};
                proPropN  = wasteStreams{s, 2};
                typeLabel = wasteStreams{s, 4};
                
                proStereoPath = [profileName, '.', proStereo];
                proPropPath   = [profileName, '.', proStereo, '.', proPropN];
                statusProPath = [profileName, '.', proStereo, '.', statusProperty];

                if comp.hasStereotype(proStereoPath)
                    compNames(end+1, 1)  = string(comp.Name); %#ok<AGROW>
                    proProp(end+1, 1)    = str2double(comp.getProperty(proPropPath)); %#ok<AGROW>
                    wasteType(end+1, 1)  = string(typeLabel); %#ok<AGROW>
                    statusProp(end+1, 1) = string(comp.getProperty(statusProPath)); %#ok<AGROW>
                end
            end
        end

        if ~isempty(compNames)
            printTable = table(compNames, proProp, wasteType, statusProp, ...
                'VariableNames', {'ComponentName', 'Producer', 'Type', 'Status'});
            sortNumbers = str2double(regexp(printTable.ComponentName, '^\d+', 'match', 'once'));
            sortNumbers(isnan(sortNumbers)) = Inf;
            printTable.SortKey = sortNumbers;
            printTable = sortrows(printTable, {'SortKey', 'ComponentName'});

            fprintf(fileID, headerFormat2, 'Component Name', 'Waste Output (m^3/s)', 'Waste Type', 'Status');
            fprintf(fileID, '%s\n', dashLine);

            for i = 1:height(printTable)
                nComp = string(printTable.ComponentName{i});
                prop  = string(printTable.Producer(i));
                type  = string(printTable.Type(i));
                stat  = string(printTable.Status{i});
                if stat == "true", stat = 'On'; elseif stat == "false", stat = 'Off'; end
                fprintf(fileID, rowFormat2, nComp, prop, type, stat);
            end
        end

        fprintf(fileID, '%s\n', dashLine);
        for s = 1:size(wasteStreams, 1)
            val = sumPropIfOn(compAll, profileName, wasteStreams{s, 3}, wasteStreams{s, 2});
            fprintf(fileID, '%-35s | %-20.4f |\n', wasteStreams{s, 6}, val);
        end
        fprintf(fileID, '%s\n', sepLine);
    end

    fprintf('SUCCESS: Report written to text file "%s".\n', fileName);    
end


% =========================================================================
% HELPER SUBFUNCTIONS
% =========================================================================

function processStandardDomain(fileID, compAll, reportTitle, profile, conStereo, conProp, conLabel, conTotalLabel, proStereo, proProp, proLabel, proTotalLabel, headerFmt, rowFmt)
    dashLine = repmat('-', 1, 82);
    sepLine  = repmat('=', 1, 82);

    fprintf(fileID, '\n\n');
    secPad = floor((82 - length(reportTitle)) / 2);
    fprintf(fileID, '%*s%s\n', secPad, '', reportTitle);
    fprintf(fileID, '%s\n\n', dashLine);

    % Consumers
    printStandardSubSection(fileID, compAll, profile, conStereo, conProp, conLabel, conTotalLabel, headerFmt, rowFmt);
    fprintf(fileID, '%s\n', sepLine);

    % Producers
    printStandardSubSection(fileID, compAll, profile, proStereo, proProp, proLabel, proTotalLabel, headerFmt, rowFmt);
    fprintf(fileID, '%s\n', sepLine);
end


function printStandardSubSection(fileID, compAll, profile, stereotype, property, columnHeader, totalLabel, headerFmt, rowFmt)
    dashLine = repmat('-', 1, 82);

    stPath     = [profile, '.', stereotype];
    propPath   = [profile, '.', stereotype, '.', property];
    statusPath = [profile, '.', stereotype, '.Status'];

    subTitle = upper([stereotype, 'S']);
    subPad   = floor((82 - length(subTitle)) / 2);
    fprintf(fileID, '\n%*s%s\n', subPad, '', subTitle);
    fprintf(fileID, '%s\n', dashLine);

    compNames  = string.empty(0, 1);
    propVals   = double.empty(0, 1);
    statusVals = string.empty(0, 1);

    for i = 1:length(compAll)
        comp = compAll(i);
        if comp.hasStereotype(stPath)
            compNames(end+1, 1)  = string(comp.Name); %#ok<AGROW>
            propVals(end+1, 1)   = str2double(comp.getProperty(propPath)); %#ok<AGROW>
            statusVals(end+1, 1) = string(comp.getProperty(statusPath)); %#ok<AGROW>
        end
    end

    if ~isempty(compNames)
        t = table(compNames, propVals, statusVals, 'VariableNames', {'ComponentName', 'Value', 'Status'});
        sortNumbers = str2double(regexp(t.ComponentName, '^\d+', 'match', 'once'));
        sortNumbers(isnan(sortNumbers)) = Inf;
        t.SortKey = sortNumbers;
        t = sortrows(t, {'SortKey', 'ComponentName'});

        fprintf(fileID, headerFmt, 'Component Name', columnHeader, 'Status');
        fprintf(fileID, '%s\n', dashLine);

        for i = 1:height(t)
            stat = t.Status{i};
            if stat == "true", stat = 'On'; elseif stat == "false", stat = 'Off'; end
            fprintf(fileID, rowFmt, string(t.ComponentName{i}), string(t.Value(i)), stat);
        end
    end

    fprintf(fileID, '%s\n', dashLine);
    val = sumPropIfOn(compAll, profile, stereotype, property);
    fprintf(fileID, '%-40s | %-25.4f |\n', totalLabel, val);
end


function total = sumPropIfOn(compAll, profile, stereotype, property)
    total = 0;
    stPath     = [profile, '.', stereotype];
    propPath   = [profile, '.', stereotype, '.', property];
    statusPath = [profile, '.', stereotype, '.Status'];

    for i = 1:length(compAll)
        comp = compAll(i);
        if comp.hasStereotype(stPath)
            statVal = string(comp.getProperty(statusPath));
            if statVal == "true" || statVal == "1" || strcmpi(statVal, "on")
                val = str2double(comp.getProperty(propPath));
                if ~isnan(val)
                    total = total + val;
                end
            end
        end
    end
end