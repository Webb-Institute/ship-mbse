function weightTable = GenerateWeightTableReport(cmd)
    % =========================================================================
    % FILE MANAGEMENT & AUTOMATIC RUN ID GENERATION
    % =========================================================================
    outputDir = 'Reports';
    modelName = 'SYSTEM';

    % Ensure output directory exists
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % --- SPECIAL COMMAND: Clear previous weight reports on demand ---
    if nargin > 0 && ~isempty(cmd)
        cmdStr = string(cmd);
        if any(strcmpi(cmdStr, ["reset", "clear"]))
            existingFiles = dir(fullfile(outputDir, 'WeightsAndMarginsReport_*.txt'));
            for k = 1:length(existingFiles)
                delete(fullfile(existingFiles(k).folder, existingFiles(k).name));
            end
            fprintf('SUCCESS: Cleared all previous weight iteration reports from "%s/".\n', outputDir);
            weightTable = table();
            return; % Exit early after wiping directory
        else
            error('Invalid command "%s". The only optional argument supported is "clear" or "reset".', cmdStr);
        end
    end

    % --- AUTO-INCREMENT RUN COUNTER (Starts at 1) ---
    existingFiles = dir(fullfile(outputDir, 'WeightsAndMarginsReport_Run_*.txt'));
    runNums = [];
    for k = 1:length(existingFiles)
        tok = regexp(existingFiles(k).name, 'WeightsAndMarginsReport_Run_(\d+)', 'tokens');
        if ~isempty(tok)
            runNums(end+1) = str2double(tok{1}{1}); %#ok<AGROW>
        end
    end

    if isempty(runNums)
        nextNum = 1;
    else
        nextNum = max(runNums) + 1;
    end
    
    runID    = sprintf('Run_%03d', nextNum);
    fileName = fullfile(outputDir, sprintf('WeightsAndMarginsReport_%s.txt', runID));

    % =========================================================================
    % SYSTEM COMPOSER MODEL LOADING & VARIANT FILTERING
    % =========================================================================
    import systemcomposer.query.*

    weightPath = 'WeightsCentersProfile.WeightsCenters.Weight';
    marginPath = 'WeightsCentersProfile.WeightsCenters.WeightMargin';
    LCGPath    = 'WeightsCentersProfile.WeightsCenters.LCG';
    VCGPath    = 'WeightsCentersProfile.WeightsCenters.VCG';
    TCGPath    = 'WeightsCentersProfile.WeightsCenters.TCG';

    if ~bdIsLoaded(modelName)
        open_system(modelName);
    end
    

    modelObj   = systemcomposer.loadModel(modelName);
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
    % DATA EXTRACTION
    % =========================================================================
    compNames   = string.empty;
    baseWeights = double.empty;
    marginWts   = double.empty;
    totalWts    = double.empty;
    xCoGs       = double.empty;
    yCoGs       = double.empty;
    zCoGs       = double.empty;

    for i = 1:length(compAll)
        comp = compAll(i);
        if comp.hasStereotype('WeightsCentersProfile.WeightsCenters')
            compNames(end+1, 1)   = comp.Name; %#ok<AGROW>
            baseWeights(end+1, 1) = str2double(comp.getProperty(weightPath)); %#ok<AGROW>
            marginWts(end+1, 1)   = str2double(comp.getProperty(marginPath)); %#ok<AGROW>
            totalWts(end+1, 1)    = round(str2double(comp.getProperty(weightPath)) * (1 + str2double(comp.getProperty(marginPath))/100)); %#ok<AGROW>
            xCoGs(end+1, 1)       = str2double(comp.getProperty(LCGPath)); %#ok<AGROW>
            yCoGs(end+1, 1)       = str2double(comp.getProperty(TCGPath)); %#ok<AGROW>
            zCoGs(end+1, 1)       = str2double(comp.getProperty(VCGPath)); %#ok<AGROW>
        end
    end

    % Build the MATLAB Table
    weightTable = table(compNames, baseWeights, marginWts, totalWts, xCoGs, yCoGs, zCoGs, ...
        'VariableNames', {'ComponentName', 'BaseWeight_t', 'MarginWeight_per', 'TotalWeight_t', 'LCG_m', 'TCG_m', 'VCG_m'});

    if ~isempty(weightTable)
        sortNumbers = str2double(regexp(weightTable.ComponentName, '^\d+', 'match', 'once'));
        sortNumbers(isnan(sortNumbers)) = Inf;
        weightTable.SortKey = sortNumbers;
        weightTable = sortrows(weightTable, {'SortKey', 'ComponentName'});
        weightTable.SortKey = [];
    end

    % --- CALCULATE SHIP TOTALS (Displacement & Global CoG) ---
    [shipDisplacement, shipCoG_X, shipCoG_Z, shipCoG_Y]     = calcShipDisp_CoG('WeightsCenters', 'WeightsCentersProfile');
    [mshipDisplacement, mshipCoG_X, mshipCoG_Z, mshipCoG_Y] = marginCalcShipDisp_CoG('WeightsCenters', 'WeightsCentersProfile');

    % =========================================================================
    % FILE WRITING SETUP
    % =========================================================================
    fileID = fopen(fileName, 'wt');

    if fileID == -1
        error('Could not open file "%s" for writing. Check folder permissions.', fileName);
    end    

    % File handle cleanup guard
    cleanUp = onCleanup(@() fclose(fileID));

    fprintf(fileID, '%s\n\n', repmat('=', 1, 110));
    fprintf(fileID, '                                   VESSEL WEIGHT & CENTER OF GRAVITY REPORT                               \n');
    fprintf(fileID, '%s\n\n', repmat('=', 1, 110));
    
    % Table Header
    fprintf(fileID, '%-40s | %-10s | %-10s | %-9s | %-8s | %-8s | %-8s\n', ...
        'Component Name', 'Weight (t)', 'Margin (%)', 'Total (t)', 'LCG (m)', 'TCG (m)', 'VCG (m)');
    fprintf(fileID, '%s\n', repmat('-', 1, 110));
    
    % Table Rows
    for i = 1:height(weightTable)
        fprintf(fileID, '%-40s | %10.2f | %10.2f | %9.2f | %8.2f | %8.2f | %8.2f\n', ...
            weightTable.ComponentName(i), ...
            weightTable.BaseWeight_t(i), ...
            weightTable.MarginWeight_per(i), ...
            weightTable.TotalWeight_t(i), ...
            weightTable.LCG_m(i), ...
            weightTable.TCG_m(i), ...
            weightTable.VCG_m(i));
    end
    
    fprintf(fileID, '%s\n\n', repmat('=', 1, 110));
    fprintf(fileID, '%s\n\n', repmat('-', 1, 110));
    fprintf(fileID, '                                          TOTAL SHIP SUMMARY                                              \n');
    fprintf(fileID, '%s\n\n', repmat('-', 1, 110));
    fprintf(fileID, ' Total Ship Displacement (with margins) : %10.2f t\n', mshipDisplacement);
    fprintf(fileID, ' Global Center of Gravity - X (Longitudinal): %10.2f m\n', mshipCoG_X);
    fprintf(fileID, ' Global Center of Gravity - Y (Transverse)  : %10.2f m\n', mshipCoG_Y);
    fprintf(fileID, ' Global Center of Gravity - Z (Vertical)    : %10.2f m\n', mshipCoG_Z);
    fprintf(fileID, ' Total Ship Displacement (without margins) : %10.2f t\n', shipDisplacement);
    fprintf(fileID, ' Global Center of Gravity - X (Longitudinal): %10.2f m\n', shipCoG_X);
    fprintf(fileID, ' Global Center of Gravity - Y (Transverse)  : %10.2f m\n', shipCoG_Y);
    fprintf(fileID, ' Global Center of Gravity - Z (Vertical)    : %10.2f m\n', shipCoG_Z);
    fprintf(fileID, '%s\n\n', repmat('=', 1, 110));

    fprintf('SUCCESS: Report written to text file "%s".\n\n', fileName);
end