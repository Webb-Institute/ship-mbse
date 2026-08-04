function fuelAnalysis()

    % =========================================================================
    % 1. MODEL & PROFILE SETUP
    % =========================================================================
    modelName   = 'SYSTEM';
    profileName = 'FuelComponentProfile';
    outputDir = 'Reports';

    % Ensure output directory exists
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    
    % Open and Load Model
    if ~bdIsLoaded(modelName)
        open_system(modelName);
    end
    modelObj = systemcomposer.loadModel(modelName);

    % Import System Composer API query namespace
    import systemcomposer.query.*

    % =========================================================================
    % 1B. PROPERTY EXTRACTION & PIPELINE MAPPING (SOURCE TO PIPE WIRING)
    % =========================================================================
    fprintf('\n==================================================================\n');
    fprintf('           FUEL PROPERTY AUTOMATIC PASS-THROUGH SETUP              \n');
    fprintf('==================================================================\n');

    sourceToPipeMap = { ...
        '20X (MAIN ENGINE)',     '525 (ME FO PIPING)';   ... 
        '30X (GENERATOR SETS)',  '526 (GS FO PIPING)';   ... 
        '55X (CARGO/MISSION)',   '527 (MISSION FO PIPING)'       
    };

    % Fully-qualified property paths (Profile.Stereotype.Property)
    sourcePropertyPath = 'FuelProfile.FuelConsumer.FuelType';
    pipePropertyPath   = 'FuelComponentProfile.Pipe.Fluid';
    pipeStereotypePath = 'FuelComponentProfile.Pipe';

    % Retrieve ALL components across all hierarchy levels in the model
    allComps = findElementsOfType(modelObj, 'Component');
    totalUpdatedPipes = 0;

    for m = 1:size(sourceToPipeMap, 1)
        sourceName  = sourceToPipeMap{m, 1};
        pipePattern = sourceToPipeMap{m, 2};

        fprintf('\nProcessing Mapping: Source [%s] --> Target Pattern [%s]\n', sourceName, pipePattern);

        % A. LOCATE SOURCE COMPONENT
        sourceComp = [];
        for c = 1:length(allComps)
            if strcmp(allComps(c).Name, sourceName) || contains(allComps(c).Name, sourceName, 'IgnoreCase', true)
                sourceComp = allComps(c);
                break;
            end
        end

        if isempty(sourceComp)
            warning('Source component "%s" was not found in the model.', sourceName);
            continue;
        end

        % B. SOURCE VARIANT RESOLUTION
        if isa(sourceComp, 'systemcomposer.arch.VariantComponent')
            activeChoice = getActiveChoice(sourceComp);
            if ~isempty(activeChoice)
                fprintf('  Source "%s" is a Variant Container. Active choice resolved to: %s\n', ...
                    sourceName, activeChoice.Name);
                sourceComp = activeChoice; % Redirect pointer to active choice
            else
                warning('Source "%s" is a Variant Container, but no active choice is selected.', sourceName);
                continue;
            end
        end

        % C. EXTRACT FUEL TYPE FROM RESOLVED SOURCE COMPONENT
        fuelTypeVal = [];
        appliedSts = {};
        if isprop(sourceComp, 'AppliedStereotypes')
            appliedSts = sourceComp.AppliedStereotypes;
        end

        fprintf('  Resolved Source Component: %s\n', sourceComp.Name);

        % Primary property lookup path
        try
            rawVal = sourceComp.getProperty(sourcePropertyPath);
            if ~isempty(rawVal)
                fuelTypeVal = string(rawVal);
            end
        catch
        end

        % Fallback 1: Stereotype relative path
        if isempty(fuelTypeVal) || strcmp(fuelTypeVal, "")
            for stIdx = 1:length(appliedSts)
                stName = appliedSts{stIdx};
                try
                    altPath = sprintf('%s.FuelType', stName);
                    rawVal = sourceComp.getProperty(altPath);
                    if ~isempty(rawVal)
                        fuelTypeVal = string(rawVal);
                        fprintf('  [V] Retrieved value via fallback path: %s\n', altPath);
                        break;
                    end
                catch
                end
            end
        end

        % Fallback 2: Direct property short name
        if isempty(fuelTypeVal) || strcmp(fuelTypeVal, "")
            try
                rawVal = sourceComp.getProperty('FuelType');
                if ~isempty(rawVal)
                    fuelTypeVal = string(rawVal);
                    fprintf('  [V] Retrieved value via direct path: FuelType\n');
                end
            catch
            end
        end

        if isempty(fuelTypeVal) || strcmp(fuelTypeVal, "")
            warning('FuelType property is empty or not set on source "%s". Skipping mapping.', sourceComp.Name);
            continue;
        else
            fprintf('  [V] Resolved FuelType: "%s"\n', fuelTypeVal);
        end

        % D. FIND AND UPDATE MATCHING ACTIVE PIPE COMPONENTS ONLY
        matchCount = 0;
        processedContainers = {}; % Prevents duplicate container iteration

        for i = 1:length(allComps)
            comp = allComps(i);
            if ~isvalid(comp), continue; end

            % Check if component or variant container name matches pattern
            if contains(comp.Name, pipePattern, 'IgnoreCase', true)
                
                % --- CASE 1: Pipe is a Variant Component Container ---
                if isa(comp, 'systemcomposer.arch.VariantComponent')
                    
                    containerPath = comp.getQualifiedName;
                    if ismember(containerPath, processedContainers)
                        continue;
                    end
                    processedContainers{end+1} = containerPath; %#ok<AGROW>

                    fprintf('  Found Variant Pipe Container: %s\n', comp.Name);
                    
                    % EXCLUSIVELY get the single active choice
                    activeChoice = getActiveChoice(comp);
                    
                    if ~isempty(activeChoice)
                        % Check if active choice is an "absent" variant
                        if contains(activeChoice.Name, 'absent', 'IgnoreCase', true) || ...
                           contains(activeChoice.Name, 'none', 'IgnoreCase', true)
                            fprintf('    -> Active Choice [%s] is designated ABSENT/NONE. Skipping update.\n', activeChoice.Name);
                        
                        % Apply property if active choice has the Pipe stereotype
                        elseif activeChoice.hasStereotype(pipeStereotypePath)
                            try
                                activeChoice.setProperty(pipePropertyPath, fuelTypeVal);
                                fprintf('    [V] Updated Active Choice [%s]: set %s = "%s"\n', ...
                                    activeChoice.Name, pipePropertyPath, fuelTypeVal);
                                matchCount = matchCount + 1;
                            catch ME
                                warning('Failed to set property on active choice "%s": %s', activeChoice.Name, ME.message);
                            end
                        else
                            fprintf('    [!] Active Choice [%s] missing stereotype %s\n', activeChoice.Name, pipeStereotypePath);
                        end
                    else
                        warning('Variant Container "%s" has no active choice selected.', comp.Name);
                    end

                % --- CASE 2: Pipe is a Standalone Component ---
                elseif isa(comp, 'systemcomposer.arch.Component') && comp.hasStereotype(pipeStereotypePath)
                    
                    % PREVENT DOUBLE-COUNTING:
                    % Skip if this component is inside a Variant Container or inside an Active Choice
                    if isprop(comp, 'Parent') && ~isempty(comp.Parent) && ...
                       (isa(comp.Parent, 'systemcomposer.arch.VariantComponent') || ...
                       (isprop(comp.Parent, 'Parent') && isa(comp.Parent.Parent, 'systemcomposer.arch.VariantComponent')))
                        continue; 
                    end
                    
                    % Skip absent components
                    if contains(comp.Name, 'absent', 'IgnoreCase', true) || ...
                       contains(comp.Name, 'none', 'IgnoreCase', true)
                        continue;
                    end
                    
                    try
                        comp.setProperty(pipePropertyPath, fuelTypeVal);
                        fprintf('  [V] Applied "%s" to Standalone Pipe Component: %s\n', fuelTypeVal, comp.Name);
                        matchCount = matchCount + 1;
                    catch ME
                        warning('Failed to update pipe "%s": %s', comp.Name, ME.message);
                    end
                end
            end
        end

        if matchCount == 0
            fprintf('  [!] No valid active pipes found matching pattern "%s" with stereotype "%s".\n', ...
                pipePattern, pipeStereotypePath);
        end

        totalUpdatedPipes = totalUpdatedPipes + matchCount;
    end

    % Save updated properties to model before validation runs
    modelObj.save;
    fprintf('\nSuccessfully updated %d total active pipe choice(s).\n', totalUpdatedPipes);

    % =========================================================================
    % 2. NAVIGATE TO 52X (FUEL) LEVEL
    % =========================================================================
    rootArch = modelObj.Architecture;
    shipComp = getComponent(rootArch, 'SHIP');
    auxComp  = getComponent(shipComp.Architecture, '500 (AUXILLIARY SYSTEMS)');
    fuelComp = getComponent(auxComp.Architecture, '52X (FUEL)');
    parentStatusPropPath = "FuelProfile.FuelProducer.Status";

    % Grab ONLY components directly at 52X (FUEL) level
    compAll = fuelComp.Architecture.Components;

    propsToCompare = ["PriFluid", "SecFluid", "TerFluid", "PriFlowRate", "SecFlowRate", "TerFlowRate"];
    outputFileName = "FuelValidationReport.txt";
    outputFilePath = fullfile(outputDir,outputFileName);
    numComps = length(compAll);

    % Open file for writing (clears previous run)
    fileID = fopen(outputFilePath, 'w');
    if fileID == -1
        error('Could not open file %s for writing.', outputFilePath);
    end

    % Cleanup object to safely close file handle even if an error occurs
    fileCleaner = onCleanup(@() fclose(fileID));

    % Inline macro function to write to BOTH Command Window and File
    writeLog = @(fmt, varargin) ...
        (fprintf(fmt, varargin{:}) + fprintf(fileID, fmt, varargin{:}));

    % Print Header
    writeLog('\n==================================================================\n');
    writeLog('     PHYSICAL CONNECTIONS PROPERTY VALIDATION (LOCAL LEVEL)       \n');
    writeLog('==================================================================\n\n');

    % =========================================================================
    % 3. CHECK PARENT / HOUSING COMPONENT STATUS (EXACT PATH)
    % =========================================================================
    isParentActive = true;
    parentName = "Parent Component";

    if numComps > 0 && isvalid(compAll(1)) && ~isempty(compAll(1).Parent)
        parentObj = compAll(1).Parent;
        parentName = string(parentObj.Name);
        try
            valRaw = getEvaluatedPropertyValue(parentObj, parentStatusPropPath);
            valStr = lower(strip(string(valRaw)));
            if strcmp(valStr, "false") || strcmp(valStr, "0")
                isParentActive = false;
            end
        catch
            % If status property doesn't exist on parent, default to active
        end
    end

    % Status Tracker
    compStatusNames  = strings(0,1);
    compStatusValues = strings(0,1);

    % If Parent is OFF, log warning, record all components as false, and bypass
    if ~isParentActive
        writeLog('[!] WARNING: Housing Component [%s] is INACTIVE (Status = false).\n', parentName);
        writeLog('    All child component connections are disabled and will not be established.\n\n');
    
        for i = 1:numComps
            if isvalid(compAll(i))
                compStatusNames(end+1,1)  = string(compAll(i).Name); %#ok<AGROW>
                compStatusValues(end+1,1) = "false (Parent Inactive)"; %#ok<AGROW>
            end
        end
    else
        % =========================================================================
        % 4. MAIN VALIDATION LOOP (Only runs if Parent is Active)
        % =========================================================================
        errorCount = 0;
        blockedLinkCount = 0;
        checkedLinks = strings(0, 2);

        for i = 1:numComps
            compA = compAll(i);
            if ~isvalid(compA), continue; end
        
            for p = 1:length(compA.Ports)
                portA = compA.Ports(p);
                if ~isvalid(portA), continue; end
            
                % Check for physical ports
                dirStr = string(portA.Direction);
                isPhysical = strcmp(dirStr, "Physical") || strcmp(dirStr, "Bidirectional") || ~isempty(portA.Interface);
                if ~isPhysical, continue; end
            
                % Check connectors on Port A
                for c = 1:length(portA.Connectors)
                    conn = portA.Connectors(c);
                    if ~isvalid(conn) || length(conn.Ports) < 2, continue; end
                
                    if conn.Ports(1).SimulinkHandle == portA.SimulinkHandle
                        otherPort = conn.Ports(2);
                    else
                        otherPort = conn.Ports(1);
                    end
                
                    if isempty(otherPort) || ~isvalid(otherPort) || isempty(otherPort.Parent) || ~isvalid(otherPort.Parent)
                        continue;
                    end
                
                    compB = otherPort.Parent;
                    isComponent = isa(compB, 'systemcomposer.arch.Component');
                
                    isLocalComp = false;
                    if isComponent
                        for k = 1:numComps
                            if isvalid(compAll(k)) && compAll(k).SimulinkHandle == compB.SimulinkHandle
                                isLocalComp = true;
                                break;
                            end
                        end
                    end
                
                    if ~isComponent || ~isLocalComp || (compA.SimulinkHandle == compB.SimulinkHandle)
                        continue; % Ignores connections leading out of this level
                    end
                
                    % Deduplicate links
                    linkID1 = [string(compA.Name), string(compB.Name)];
                    linkID2 = [string(compB.Name), string(compA.Name)];
                
                    isAlreadyDone = ~isempty(checkedLinks) && ...
                    (any(all(checkedLinks == linkID1, 2)) || any(all(checkedLinks == linkID2, 2)));
                    if isAlreadyDone, continue; end
                
                    checkedLinks(end+1, :) = linkID1; %#ok<AGROW>
                
                    % --- EXTRACT PROPERTIES FOR COMPONENT A ---
                    propsA_short = strings(0,1); valsA = strings(0,1);
                    try
                        fullPropsA = string(getStereotypeProperties(compA));
                        for pa = 1:length(fullPropsA)
                            parts = split(fullPropsA(pa), '.');
                            propsA_short(end+1,1) = parts(end); %#ok<AGROW>
                            valsA(end+1,1) = string(getEvaluatedPropertyValue(compA, fullPropsA(pa))); %#ok<AGROW>
                        end
                    catch
                    end
                
                    % --- EXTRACT PROPERTIES FOR COMPONENT B ---
                    propsB_short = strings(0,1); valsB = strings(0,1);
                    try
                        fullPropsB = string(getStereotypeProperties(compB));
                        for pb = 1:length(fullPropsB)
                            parts = split(fullPropsB(pb), '.');
                            propsB_short(end+1,1) = parts(end); %#ok<AGROW>
                            valsB(end+1,1) = string(getEvaluatedPropertyValue(compB, fullPropsB(pb))); %#ok<AGROW>
                        end
                    catch
                    end
                
                    % --- RESOLVE STATUS FOR SUB-COMPONENTS ---
                    isAActive = true; statusDisplayA = "N/A (No Status Prop)";
                    idxA_status = find(strcmpi(propsA_short, "Status"), 1, 'first');
                    if ~isempty(idxA_status)
                        vStr = lower(strip(valsA(idxA_status)));
                        if strcmp(vStr, "false") || strcmp(vStr, "0")
                            isAActive = false; statusDisplayA = "false";
                        else
                            statusDisplayA = "true";
                        end
                    end
                
                    isBActive = true; statusDisplayB = "N/A (No Status Prop)";
                    idxB_status = find(strcmpi(propsB_short, "Status"), 1, 'first');
                    if ~isempty(idxB_status)
                        vStr = lower(strip(valsB(idxB_status)));
                        if strcmp(vStr, "false") || strcmp(vStr, "0")
                            isBActive = false; statusDisplayB = "false";
                        else
                            statusDisplayB = "true";
                        end
                    end
                
                    % Record Status for Summary Table
                    if ~any(compStatusNames == string(compA.Name))
                        compStatusNames(end+1,1)  = string(compA.Name); %#ok<AGROW>
                        compStatusValues(end+1,1) = statusDisplayA; %#ok<AGROW>
                    end
                    if ~any(compStatusNames == string(compB.Name))
                        compStatusNames(end+1,1)  = string(compB.Name); %#ok<AGROW>
                        compStatusValues(end+1,1) = statusDisplayB; %#ok<AGROW>
                    end
                
                    % --- GUARD CHECK: SILENTLY SKIP IF SUB-COMPONENT STATUS IS FALSE ---
                    if ~isAActive || ~isBActive
                        blockedLinkCount = blockedLinkCount + 1;
                        continue;
                    end
                
                    writeLog('LINK FOUND: (%s):  %s <---> %s\n', ...
                    portA.Name, compA.Name, compB.Name);

                    % =========================================================
                    % 4B. PIPE FLUID vs FuelComponentProfile STEREOTYPE CHECK
                    % =========================================================
                    isAPipe = compA.hasStereotype(pipeStereotypePath) || contains(compA.Name, "PIPING", "IgnoreCase", true);
                    isBPipe = compB.hasStereotype(pipeStereotypePath) || contains(compB.Name, "PIPING", "IgnoreCase", true);

                    if isAPipe || isBPipe
                        pipeComp  = compA; pipeProps  = propsA_short; pipeVals  = valsA;
                        otherComp = compB; otherProps = propsB_short; otherVals = valsB;
                        if isBPipe && ~isAPipe
                            pipeComp  = compB; pipeProps  = propsB_short; pipeVals  = valsB;
                            otherComp = compA; otherProps = propsA_short; otherVals = valsA;
                        end

                        % Read Pipe's fluid property ("Fluid" or fallback to "PriFluid")
                        pipeFluid = "";
                        idxPipeFluid = find(strcmpi(pipeProps, "Fluid"), 1, 'first');
                        if isempty(idxPipeFluid)
                            idxPipeFluid = find(strcmpi(pipeProps, "PriFluid"), 1, 'first');
                        end
                        if ~isempty(idxPipeFluid)
                            pipeFluid = strip(pipeVals(idxPipeFluid));
                        end

                        % Collect fluid property values across ALL stereotypes on Fuel Component (Pump, Conditioner, etc.)
                        fuelFluids = strings(0,1);
                        
                        % 1. Check direct standard properties (PriFluid, SecFluid, TerFluid)
                        fluidCheckNames = ["PriFluid", "SecFluid", "TerFluid"];
                        for fIdx = 1:length(fluidCheckNames)
                            fName = fluidCheckNames(fIdx);
                            idxF = find(strcmpi(otherProps, fName), 1, 'first');
                            if ~isempty(idxF)
                                fVal = strip(otherVals(idxF));
                                if fVal ~= "" && ~strcmpi(fVal, "n/a") && ~strcmpi(fVal, "none")
                                    fuelFluids(end+1, 1) = fVal; %#ok<AGROW>
                                end
                            end
                        end

                        % 2. Dynamic Stereotype Search: Check any property with "Fluid" or "Fuel" in its name
                        for pIdx = 1:length(otherProps)
                            pName = otherProps(pIdx);
                            if (contains(pName, "Fluid", "IgnoreCase", true) || contains(pName, "Fuel", "IgnoreCase", true)) ...
                               && ~strcmpi(pName, "Status")
                                fVal = strip(otherVals(pIdx));
                                if fVal ~= "" && ~strcmpi(fVal, "n/a") && ~strcmpi(fVal, "none") ...
                                   && ~any(strcmpi(fuelFluids, fVal))
                                    fuelFluids(end+1, 1) = fVal; %#ok<AGROW>
                                end
                            end
                        end

                        % Validate Pipe Fluid matches at least one candidate from the Fuel Component
                        if pipeFluid ~= "" && ~isempty(fuelFluids)
                            if any(strcmpi(pipeFluid, fuelFluids))
                                writeLog('  [V] PASSED: Pipe fluid "%s" matches a [%s] fluid profile.\n', ...
                                    pipeFluid, otherComp.Name);
                            else
                                errorCount = errorCount + 1;
                                writeLog('  [X] ERROR: Pipe Fluid Mismatch!\n');
                                writeLog('      - Pipe [%s] Fluid: "%s"\n', pipeComp.Name, pipeFluid);
                                writeLog('      - Component [%s] Defined Fluids: [%s]\n', otherComp.Name, join(fuelFluids, ', '));
                            end
                        end
                    end
                
                    % --- COMPARE USER TARGET PROPERTIES (STANDARD MATCHING) ---
                    commonProps = intersect(propsA_short, propsB_short);
                    propsToTest = intersect(commonProps, string(propsToCompare));
                
                    if isempty(propsToTest) && ~(isAPipe || isBPipe)
                        writeLog('      INFO: None of the target properties were shared by both components.\n\n');
                        continue;
                    end
                
                    for sp = 1:length(propsToTest)
                        targetProp = propsToTest(sp);
                        valA = valsA(find(propsA_short == targetProp, 1, 'first'));
                        valB = valsB(find(propsB_short == targetProp, 1, 'first'));
                    
                        if valA ~= valB
                            errorCount = errorCount + 1;
                            writeLog('  [X] ERROR: Property mismatch on [%s]!\n', targetProp);
                            writeLog('      - %s: "%s"\n      - %s: "%s"\n', compA.Name, valA, compB.Name, valB);
                        else
                            writeLog('  [V] PASSED: %s matches ("%s")\n', targetProp, valA);
                        end
                    end
                    writeLog('\n');
                end
            end
        end
    end

    % =========================================================================
    % 5. SUMMARY REPORT & STATUS TABLE
    % =========================================================================
    writeLog('==================================================================\n');
    writeLog('                    COMPONENT STATUS SUMMARY                      \n');
    writeLog('==================================================================\n');
    writeLog('| %-35s | %-25s |\n', 'Component Name', 'Status');
    writeLog('|-------------------------------------|---------------------------|\n');

    if isempty(compStatusNames)
        writeLog('| %-35s | %-25s |\n', 'No physical components checked', 'N/A');
    else
        for s = 1:length(compStatusNames)
            writeLog('| %-35s | %-25s |\n', compStatusNames(s), compStatusValues(s));
        end
    end

    writeLog('\n==================================================================\n');
    if ~isParentActive
        writeLog('SKIPPED: Parent container [%s] status is false. No links established.\n', parentName);
    elseif errorCount == 0
        writeLog('SUCCESS: All active physical connections pass property validation.\n');
    else
        writeLog('VALIDATION FAILED: Found %d property mismatch error(s).\n', errorCount);
    end

    if isParentActive && blockedLinkCount > 0
        writeLog('NOTE: %d link(s) were NOT established because at least one connected component was inactive (Status = false).\n', blockedLinkCount);
    end
    writeLog('==================================================================\n');
    fprintf('Report saved to: %s\n\n', fullfile(outputDir, outputFileName));
   
    % =========================================================================
    % 6. ROLLUP CONFIGURATION: OPERATION TYPES & PARENT PROPERTY PATHS
    % =========================================================================
    rollupMap = containers.Map();

    rollupMap('PowerRequired')    = "SUM"; 
    rollupMap('Weight')           = "SUM"; 
    rollupMap('LubeConsumption')  = "SUM"; 
    rollupMap('CoolConsumption')  = "SUM"; 
    rollupMap('WasteOilProduced') = "SUM"; 
    rollupMap('HeatConsumed')     = "SUM"; 
    rollupMap('FlowRate')         = "SUM";         
    rollupMap('LCG')              = "COG"; 
    rollupMap('VCG')              = "COG";
    rollupMap('TCG')              = "COG";

    parentPropPaths = containers.Map(...
        {'PowerRequired',   'Weight', 'LubeConsumption', 'CoolConsumption', 'WasteOilProduced', ...
        'HeatConsumed', 'FlowRate', 'LCG', 'VCG', 'TCG'}, ...
        { ...
            'ElectricalProfile.ElectricalConsumer.PowerRequired', ...
            'WeightsCentersProfile.WeightsCenters.Weight', ...
            'LubeProfile.LubeConsumer.LubeRequired', ...
            'CoolingProfile.CoolConsumer.CoolConsumed', ...
            'WasteProfile.WasteOilProducer.WOProduced', ...
            'HeatProfile.HeatConsumer.HeatConsumed', ...
            'FuelProfile.FuelProducer.FuelProduced', ...
            'WeightsCentersProfile.WeightsCenters.LCG', ...
            'WeightsCentersProfile.WeightsCenters.VCG', ...
            'WeightsCentersProfile.WeightsCenters.TCG', ...
        } ...
    );

    % Output logging setup
    summaryFileName = "FuelSystemSummary.txt";
    summaryFilePath =  fullfile(outputDir,summaryFileName);
    fileID_summary = -1;

    try
        fileID_summary = fopen(summaryFilePath, 'w');
        if fileID_summary == -1, error('Could not open file %s', summaryFilePath); end

        writeLogSummary = @(fmt, varargin) (fprintf(fmt, varargin{:}) + fprintf(fileID_summary, fmt, varargin{:}));

        writeLogSummary('\n==================================================================\n');
        writeLogSummary('                        FUEL SYSTEM REPORT                          \n');
        writeLogSummary('==================================================================\n\n');

        % Identify Parent Component
        if numComps > 0 && isvalid(compAll(1)) && ~isempty(compAll(1).Parent)
            parentObj = compAll(1).Parent;
            parentName = string(parentObj.Name);
        else
            error('Could not determine parent component from compAll.');
        end

        writeLogSummary('Component : %s\n', parentName);
        writeLogSummary('Sub-Components : %d found\n\n', numComps);

        % =========================================================================
        % 7. COLLECT VALUES AND WEIGHTS (STEREOTYPE-AGNOSTIC LOOP)
        % =========================================================================
        targetProps = keys(rollupMap);
        childDataMap = containers.Map();
    
        for k = 1:length(targetProps)
            childDataMap(targetProps{k}) = struct('Val', {}, 'Weight', {}); 
        end

        for i = 1:numComps
            comp = compAll(i);
            if ~isvalid(comp), continue; end
        
            props_short = strings(0,1);
            vals_raw    = strings(0,1);
        
            % Extract all properties on this child component
            try
                fullProps = string(getStereotypeProperties(comp));
                for p = 1:length(fullProps)
                    parts = split(fullProps(p), '.');
                    props_short(end+1,1) = parts(end); %#ok<AGROW>
                    vals_raw(end+1,1)    = string(getEvaluatedPropertyValue(comp, fullProps(p))); %#ok<AGROW>
                end
            catch
                continue;
            end
        
            % Check if child component is active
            isActive = true;
            idxStatus = find(strcmpi(props_short, "Status"), 1, 'first');
            if ~isempty(idxStatus)
                vStr = lower(strip(vals_raw(idxStatus)));
                if strcmp(vStr, "false") || strcmp(vStr, "0")
                    isActive = false;
                end
            end
        
            if ~isActive
                writeLogSummary('  [-] Skipping inactive child component: %s\n', comp.Name);
                continue;
            end
        
            % Extract 'Weight' property for this child if present (default to 1.0)
            childWeight = 1.0;
            idxWeight = find(strcmpi(props_short, "Weight"), 1, 'first');
            if ~isempty(idxWeight)
                wNum = str2double(vals_raw(idxWeight));
                if ~isnan(wNum)
                    childWeight = wNum;
                end
            end
        
            % Match and collect target property values + weight
            for k = 1:length(targetProps)
                prop = targetProps{k};
                idx = find(strcmpi(props_short, prop), 1, 'first');
            
                if ~isempty(idx)
                    valNum = str2double(vals_raw(idx));
                    if ~isnan(valNum)
                        currentStructArr = childDataMap(prop);
                    
                        newEntry = struct('Val', valNum, 'Weight', childWeight);
                        childDataMap(prop) = [currentStructArr, newEntry];
                    end
                end
            end
        end

        % =========================================================================
        % 8. EXECUTE ROLLUP OPERATIONS IN SWITCH BLOCK
        % =========================================================================
        writeLogSummary('\n==================================================================\n');
        writeLogSummary('                         ASSIGNMENT REPORT                          \n');
        writeLogSummary('==================================================================\n');
        writeLogSummary('| %-16s | %-16s | %-16s | %-12s |\n', ...
            'Property', 'Calculated Total', 'Old Parent Val', 'Assignment');
        writeLogSummary('|------------------|------------------|------------------|--------------|\n');

        for k = 1:length(targetProps)
            prop = targetProps{k};
            dataEntries = childDataMap(prop);
            calcVal = NaN;
        
            if ~isempty(dataEntries)
                vals    = [dataEntries.Val];
                weights = [dataEntries.Weight];
                totalWeight = sum(weights);
            
                operation = upper(rollupMap(prop));
            
                switch operation
                    case "SUM"
                        calcVal = sum(vals);
                    
                    case "COG"
                        if totalWeight > 0
                            calcVal = sum(vals .* weights) / totalWeight;
                        else
                            calcVal = mean(vals);
                        end
                    
                    case "FLOWRATE"
                        calcVal = max(vals);
                    
                    otherwise
                        writeLogSummary('  [!] Unknown operation [%s] for property [%s]\n', operation, prop);
                end
            end
        
            if isnan(calcVal) || isinf(calcVal)
                calcValStr = "N/A";
            else
                calcValStr = sprintf('%.4f', calcVal);
            end
        
            oldParentValStr = "N/A";
            assignmentStatus = "SKIPPED";
        
            if isKey(parentPropPaths, prop)
                parentPath = string(parentPropPaths(prop));
            
                pathParts = string(split(parentPath, '.'));
                shortStereoPath = parentPath;
                if length(pathParts) >= 3
                    shortStereoPath = join(pathParts(end-1:end), '.');
                end
            
                try
                    rawOld = getEvaluatedPropertyValue(parentObj, parentPath);
                    if isempty(rawOld)
                        rawOld = getEvaluatedPropertyValue(parentObj, shortStereoPath);
                    end
                    if ~isempty(rawOld)
                        oldParentValStr = string(rawOld);
                    end
                catch
                end
            
                if ~isnan(calcVal)
                    success = false;
                    lastErrorMsg = "";
                
                    try
                        setValuedPropertyValue(parentObj, parentPath, calcVal);
                        success = true;
                    catch ME1
                        lastErrorMsg = ME1.message;
                    end
                
                    if ~success
                        try
                            setValuedPropertyValue(parentObj, shortStereoPath, calcVal);
                            success = true;
                        catch ME2
                            lastErrorMsg = ME2.message;
                        end
                    end
                
                    if ~success
                        try
                            setProperty(parentObj, parentPath, calcValStr);
                            success = true;
                        catch ME3
                            lastErrorMsg = ME3.message;
                        end
                    end
                
                    if success
                        assignmentStatus = "[V] UPDATED";
                    else
                        assignmentStatus = "[X] FAILED";
                        writeLogSummary('\n  [!] Error setting [%s]: %s\n', parentPath, lastErrorMsg);
                    end
                end
            else
                assignmentStatus = "NO PATH";
            end
        
            writeLogSummary('| %-16s | %-16s | %-16s | %-12s |\n', ...
                prop, calcValStr, oldParentValStr, assignmentStatus);
        end

        writeLogSummary('==================================================================\n');
        fprintf('Summary report saved to: %s\n\n', fullfile(outputDir, summaryFileName));

    catch ME
        rethrow(ME);
    
    finally
        if exist('fileID_summary', 'var') && fileID_summary ~= -1
            fclose(fileID_summary);
        end
    end    
end