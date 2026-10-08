function changeImpactReport(optArg)
    % Optional input argument:
    %   optArg (string/char): Pass 'clear' to delete the intermediate source 
    %                        report text files after generating the Change 
    %                        Impact Report.
    
    shouldClear = false;
    if nargin >= 1 && (ischar(optArg) || isstring(optArg))
        if strcmpi(strtrim(optArg), 'clear')
            shouldClear = true;
        end
    end

    % =========================================================================
    % CONFIGURATION & FILE DISCOVERY
    % =========================================================================
    reportsDir = getOutputDir('reports');

    if ~exist(reportsDir, 'dir')
        error('Directory "%s" does not exist. Run report generation first.', reportsDir);
    end

    % Find all text report files while excluding summary/comparison outputs
    allFiles = dir(fullfile(reportsDir, '*.txt'));
    excludeMask = arrayfun(@(f) startsWith(f.name, 'Change_Impact_') || ...
                               startsWith(f.name, 'Comparison_') || ...
                               startsWith(f.name, 'Fuel') || ...
                               startsWith(f.name, 'Unallocated') || ...
                               startsWith(f.name, 'Interface') || ...
                               startsWith(f.name, 'Summary_'), allFiles);
    files = allFiles(~excludeMask);

    if isempty(files)
        error('No report text files found in "%s/".', reportsDir);
    end

    % Group files by unique Run IDs
    runIDsMap = containers.Map();
    for f = 1:length(files)
        fname = files(f).name;
        tok = regexp(fname, '^(?:SystemsReport_|WeightsAndMarginsReport_|WeightsReport_|WeightsAndCenters_|WeightReport_)?(.+)\.txt$', 'tokens');
        if ~isempty(tok)
            runID = tok{1}{1};
        else
            [~, runID, ~] = fileparts(fname);
        end

        fullPath = fullfile(files(f).folder, fname);
        if isKey(runIDsMap, runID)
            runIDsMap(runID) = [runIDsMap(runID), {fullPath}];
        else
            runIDsMap(runID) = {fullPath};
        end
    end

    runIDs = runIDsMap.keys();
    [~, sortIdx] = sort(runIDs);
    runIDs = runIDs(sortIdx);

    numRuns = length(runIDs);
    fprintf('Found %d iteration run ID(s) for Change Impact Analysis...\n\n', numRuns);

    % =========================================================================
    % DATA STRUCTURES FOR SYSTEMS & WEIGHTS
    % =========================================================================
    sysSectionsList   = {};
    sysSectionPropMap = containers.Map();
    sysSectionKeysMap = containers.Map();
    sysDataMap        = containers.Map();

    weightsDataMap    = containers.Map(); 

    weightSummaryKeys = {};
    weightSummaryMap  = containers.Map();

    plotDataMap       = containers.Map(); 

    % =========================================================================
    % PARSE REPORT FILES
    % =========================================================================
    for r = 1:numRuns
        runID     = runIDs{r};
        filePaths = runIDsMap(runID);

        weightRunData         = struct();
        weightRunData.hasData = false;
        weightRunData.rows    = {};

        for fIdx = 1:length(filePaths)
            filePath    = filePaths{fIdx};
            fileContent = fileread(filePath);
            lines       = splitlines(fileContent);

            isWeightFile = contains(filePath, 'WeightsAndMarginsReport_') || ...
                           contains(filePath, 'WeightsReport_') || ...
                           contains(filePath, 'WeightsAndCenters_');

            currentSection = '';

            dispWith = NaN; dispNo = NaN;
            summaryMode = '';

            for l = 1:length(lines)
                rawLine = lines{l};
                lineStr = strtrim(rawLine);

                if isempty(lineStr)
                    continue;
                end

                % -------------------------------------------------------------
                % PARSE WEIGHT & CENTER OF GRAVITY REPORT
                % -------------------------------------------------------------
                if isWeightFile
                    if contains(lineStr, 'Component Name') && contains(lineStr, '|')
                        weightRunData.hasData = true;
                        continue;
                    end

                    if contains(lineStr, 'Total Ship Displacement (with margins)')
                        summaryMode = 'with_margins';
                        dispWith = extractNumericVal(lineStr);
                        valStr   = extractValueStr(lineStr);
                        paramKey = 'Total Ship Displacement (with margins)';
                        weightSummaryKeys = addWeightSummaryEntry(paramKey, runID, valStr, weightSummaryKeys, weightSummaryMap);
                        continue;
                    elseif contains(lineStr, 'Total Ship Displacement (without margins)')
                        summaryMode = 'without_margins';
                        dispNo   = extractNumericVal(lineStr);
                        valStr   = extractValueStr(lineStr);
                        paramKey = 'Total Ship Displacement (without margins)';
                        weightSummaryKeys = addWeightSummaryEntry(paramKey, runID, valStr, weightSummaryKeys, weightSummaryMap);
                        continue;
                    elseif contains(lineStr, 'Global Center of Gravity - X (Longitudinal)')
                        valStr = extractValueStr(lineStr);
                        if strcmp(summaryMode, 'with_margins')
                            paramKey = 'Global Center of Gravity - X (Longitudinal) [With Margins]';
                        else
                            paramKey = 'Global Center of Gravity - X (Longitudinal) [Without Margins]';
                        end
                        weightSummaryKeys = addWeightSummaryEntry(paramKey, runID, valStr, weightSummaryKeys, weightSummaryMap);
                        continue;
                    elseif contains(lineStr, 'Global Center of Gravity - Y (Transverse)')
                        valStr = extractValueStr(lineStr);
                        if strcmp(summaryMode, 'with_margins')
                            paramKey = 'Global Center of Gravity - Y (Transverse) [With Margins]';
                        else
                            paramKey = 'Global Center of Gravity - Y (Transverse) [Without Margins]';
                        end
                        weightSummaryKeys = addWeightSummaryEntry(paramKey, runID, valStr, weightSummaryKeys, weightSummaryMap);
                        continue;
                    elseif contains(lineStr, 'Global Center of Gravity - Z (Vertical)')
                        valStr = extractValueStr(lineStr);
                        if strcmp(summaryMode, 'with_margins')
                            paramKey = 'Global Center of Gravity - Z (Vertical) [With Margins]';
                        else
                            paramKey = 'Global Center of Gravity - Z (Vertical) [Without Margins]';
                        end
                        weightSummaryKeys = addWeightSummaryEntry(paramKey, runID, valStr, weightSummaryKeys, weightSummaryMap);
                        continue;
                    end

                    if contains(lineStr, '|') && ~contains(lineStr, '=') && ~contains(lineStr, '-')
                        parts = strsplit(rawLine, '|');
                        if length(parts) >= 7
                            weightRunData.rows{end+1} = struct(...
                                'Name', strtrim(parts{1}), ...
                                'BaseWt', strtrim(parts{2}), ...
                                'Margin', strtrim(parts{3}), ...
                                'TotalWt', strtrim(parts{4}), ...
                                'LCG', strtrim(parts{5}), ...
                                'TCG', strtrim(parts{6}), ...
                                'VCG', strtrim(parts{7}));
                            weightRunData.hasData = true;
                        end
                    end
                    continue;
                end

                % -------------------------------------------------------------
                % PARSE SYSTEMS REPORT
                % -------------------------------------------------------------
                if ~contains(lineStr, '|') && ~contains(lineStr, '=') && ~contains(lineStr, '-')
                    secName = cleanSectionName(lineStr);
                    if ~isempty(secName)
                        currentSection = secName;
                        if ~ismember(currentSection, sysSectionsList)
                            sysSectionsList{end+1} = currentSection; %#ok<AGROW>
                            sysSectionKeysMap(currentSection) = {};
                        end
                        continue;
                    end
                end

                if isempty(currentSection), continue; end

                if contains(lineStr, 'Component Name') && contains(lineStr, '|')
                    parts = strsplit(rawLine, '|');
                    if length(parts) >= 3
                        valPropHeader = strtrim(parts{2});
                        if ~isKey(sysSectionPropMap, currentSection) && ~isempty(valPropHeader)
                            sysSectionPropMap(currentSection) = valPropHeader;
                        end
                    end
                    continue;
                end

                if startsWith(lineStr, 'TOTAL') && contains(lineStr, '|')
                    parts = strsplit(rawLine, '|');
                    if length(parts) >= 2
                        addSysEntry(currentSection, strtrim(parts{1}), runID, strtrim(parts{2}), sysSectionKeysMap, sysDataMap);
                    end
                    continue;
                end

                if contains(lineStr, '|') && ~contains(lineStr, '=') && ~contains(lineStr, '-')
                    parts = strsplit(rawLine, '|');
                    if length(parts) == 3
                        addSysEntry(currentSection, strtrim(parts{1}), runID, strtrim(parts{2}), sysSectionKeysMap, sysDataMap);
                    elseif length(parts) >= 4
                        compKey = sprintf('%s (%s)', strtrim(parts{1}), strtrim(parts{3}));
                        addSysEntry(currentSection, compKey, runID, strtrim(parts{2}), sysSectionKeysMap, sysDataMap);
                    end
                end
            end

            if ~isnan(dispWith)
                plotDataMap(sprintf('Weights_Plot_Data::DISPLACEMENT (WITH MARGINS)::%s', runID)) = num2str(dispWith);
            end
            if ~isnan(dispNo)
                plotDataMap(sprintf('Weights_Plot_Data::DISPLACEMENT (WITHOUT MARGINS)::%s', runID)) = num2str(dispNo);
            end
        end

        weightsDataMap(runID) = weightRunData;
    end

    combinedPlotMap = [sysDataMap; plotDataMap];

    % =========================================================================
    % WRITE CHANGE IMPACT SUMMARY REPORT
    % =========================================================================
    summaryFile = fullfile(reportsDir, 'Change_Impact_Summary.txt');
    fileID = fopen(summaryFile, 'wt');

    if fileID == -1
        error('Could not open file "%s" for writing.', summaryFile);
    end
    cleanUp = onCleanup(@() fclose(fileID));

    titleText = 'CHANGE IMPACT REPORT';
    sepLine110 = repmat('=', 1, 110);
    leftPad    = floor((110 - length(titleText)) / 2);

    fprintf('%s\n', sepLine110);
    fprintf('%*s%s\n', leftPad, '', titleText);
    fprintf('%s\n\n', sepLine110);

    fprintf(fileID, '%s\n', sepLine110);
    fprintf(fileID, '%*s%s\n', leftPad, '', titleText);
    fprintf(fileID, '%s\n\n', sepLine110);

    % SECTION 1: SYSTEMS TABLES
    for s = 1:length(sysSectionsList)
        secName = sysSectionsList{s};
        rowKeys = sysSectionKeysMap(secName);

        if isempty(rowKeys), continue; end

        if isKey(sysSectionPropMap, secName)
            propLabel = sysSectionPropMap(secName);
        else
            propLabel = '';
        end

        printSysSectionTable(fileID, secName, propLabel, rowKeys, runIDs, sysDataMap);
    end

    % SECTION 2: ITERATION WEIGHT REPORTS
    printWeightsAndCentersSection(fileID, runIDs, weightsDataMap);

    % SECTION 3: CONSOLIDATED WEIGHT & COG SUMMARY TABLE
    printConsolidatedWeightSummaryTable(fileID, runIDs, weightSummaryKeys, weightSummaryMap);

    fprintf('Change Impact summary report written to: "%s"\n\n', summaryFile);

    % =========================================================================
    % GENERATE VISUALIZATIONS & CHARTS
    % =========================================================================
    generateImpactPlotsFromMap(runIDs, combinedPlotMap, reportsDir);

    % =========================================================================
    % OPTIONAL CLEANUP OF SOURCE REPORTS
    % =========================================================================
    if shouldClear
        fprintf('Executing report cleanup...\n');

        for fIdx = 1:length(files)
            srcPath = fullfile(files(fIdx).folder, files(fIdx).name);
            if exist(srcPath, 'file')
                delete(srcPath);
            end
        end

        fprintf('Source report files in "%s/" have been cleared.\n\n', reportsDir);
    end

    fprintf('SUCCESS: Change Impact Report successfully generated.\n');
end

% =========================================================================
% PRINTING HELPERS
% =========================================================================

function printConsolidatedWeightSummaryTable(fileID, runIDs, summaryKeys, summaryMap)
    if isempty(summaryKeys)
        return;
    end

    mainHeader = 'WEIGHT & CENTER OF GRAVITY SUMMARY COMPARISON';
    numRuns    = length(runIDs);

    maxKeyLen = max(cellfun(@length, summaryKeys));
    maxKeyLen = max(maxKeyLen, length('Parameter / Metric'));
    col1Width = max(maxKeyLen + 1, 55);

    colWidths = zeros(1, numRuns);
    for r = 1:numRuns
        cLen = length(runIDs{r});
        for k = 1:length(summaryKeys)
            dKey = sprintf('%s::%s', summaryKeys{k}, runIDs{r});
            if isKey(summaryMap, dKey)
                cLen = max(cLen, length(summaryMap(dKey)));
            end
        end
        colWidths(r) = max(cLen + 1, 12);
    end

    totalWidth = col1Width + sum(colWidths) + 3 * numRuns + 1;
    dashLine   = repmat('-', 1, totalWidth);
    sepLine    = repmat('=', 1, totalWidth);

    sPad = floor((totalWidth - length(mainHeader)) / 2);
    if sPad < 0, sPad = 0; end

    fprintf('%s\n', sepLine);
    fprintf('%*s%s\n', sPad, '', mainHeader);
    fprintf('%s\n', sepLine);

    fprintf(fileID, '%s\n', sepLine);
    fprintf(fileID, '%*s%s\n', sPad, '', mainHeader);
    fprintf(fileID, '%s\n', sepLine);

    headerStr = sprintf('%-*s', col1Width, 'Parameter / Metric');
    for r = 1:numRuns
        headerStr = [headerStr, sprintf(' | %-*s', colWidths(r), runIDs{r})]; %#ok<AGROW>
    end
    fprintf('%s\n', headerStr);
    fprintf('%s\n', dashLine);
    fprintf(fileID, '%s\n', headerStr);
    fprintf(fileID, '%s\n', dashLine);

    for k = 1:length(summaryKeys)
        paramKey = summaryKeys{k};
        rowStr   = sprintf('%-*s', col1Width, paramKey);
        for r = 1:numRuns
            dKey = sprintf('%s::%s', paramKey, runIDs{r});
            if isKey(summaryMap, dKey)
                valStr = summaryMap(dKey);
            else
                valStr = '-';
            end
            rowStr = [rowStr, sprintf(' | %-*s', colWidths(r), valStr)]; %#ok<AGROW>
        end
        fprintf('%s\n', rowStr);
        fprintf(fileID, '%s\n', rowStr);
    end

    fprintf('%s\n\n', sepLine);
    fprintf(fileID, '%s\n\n', sepLine);
end

function printWeightsAndCentersSection(fileID, runIDs, weightsDataMap)
    sepLine110 = repmat('=', 1, 110);
    dashLine110 = repmat('-', 1, 110);

    mainHeader = 'WEIGHTS AND CENTERS REPORTS BY ITERATION';
    padLen = floor((110 - length(mainHeader)) / 2);

    fprintf('%s\n', sepLine110);
    fprintf('%*s%s\n', padLen, '', mainHeader);
    fprintf('%s\n\n', sepLine110);

    fprintf(fileID, '%s\n', sepLine110);
    fprintf(fileID, '%*s%s\n', padLen, '', mainHeader);
    fprintf(fileID, '%s\n\n', sepLine110);

    for r = 1:length(runIDs)
        runID = runIDs{r};
        runHeader = sprintf('WEIGHT & CENTER OF GRAVITY REPORT: %s', runID);
        rPad = floor((110 - length(runHeader)) / 2);

        fprintf('%s\n', dashLine110);
        fprintf('%*s%s\n', rPad, '', runHeader);
        fprintf('%s\n\n', dashLine110);

        fprintf(fileID, '%s\n', dashLine110);
        fprintf(fileID, '%*s%s\n', rPad, '', runHeader);
        fprintf(fileID, '%s\n\n', dashLine110);

        if ~isKey(weightsDataMap, runID)
            printNoDataNotice(fileID);
            continue;
        end

        wData = weightsDataMap(runID);
        if ~wData.hasData || isempty(wData.rows)
            printNoDataNotice(fileID);
            continue;
        end

        headerStr = sprintf('%-40s | %-10s | %-10s | %-9s | %-8s | %-8s | %-8s', ...
            'Component Name', 'Weight (t)', 'Margin (%)', 'Total (t)', 'LCG (m)', 'TCG (m)', 'VCG (m)');

        fprintf('%s\n', headerStr);
        fprintf('%s\n', dashLine110);
        fprintf(fileID, '%s\n', headerStr);
        fprintf(fileID, '%s\n', dashLine110);

        for i = 1:length(wData.rows)
            row = wData.rows{i};
            rowStr = sprintf('%-40s | %10s | %10s | %9s | %8s | %8s | %8s', ...
                row.Name, row.BaseWt, row.Margin, row.TotalWt, row.LCG, row.TCG, row.VCG);

            fprintf('%s\n', rowStr);
            fprintf(fileID, '%s\n', rowStr);
        end

        fprintf('%s\n\n', sepLine110);
        fprintf(fileID, '%s\n\n', sepLine110);
    end
end

function printNoDataNotice(fileID)
    msg = '[ No Weight & Margin Report found for this run ]';
    fprintf('  %s\n\n', msg);
    fprintf(fileID, '  %s\n\n', msg);
end

function printSysSectionTable(fileID, secName, propLabel, rowKeys, runIDs, dataMap)
    isTotal  = cellfun(@(k) startsWith(k, 'TOTAL'), rowKeys);
    compKeys = rowKeys(~isTotal);
    compKeys = sort(compKeys);
    rowKeys  = [compKeys, rowKeys(isTotal)];

    maxKeyLen = max(cellfun(@length, rowKeys));
    maxKeyLen = max(maxKeyLen, length('Component Name'));
    col1Width = max(maxKeyLen + 1, 22);

    numRuns   = length(runIDs);
    colWidths = zeros(1, numRuns);
    for r = 1:numRuns
        cLen = length(runIDs{r});
        for k = 1:length(rowKeys)
            dKey = sprintf('%s::%s::%s', secName, rowKeys{k}, runIDs{r});
            if isKey(dataMap, dKey)
                cLen = max(cLen, length(dataMap(dKey)));
            end
        end
        colWidths(r) = max(cLen + 1, 10);
    end

    totalWidth = col1Width + sum(colWidths) + 3 * numRuns + 1;
    dashLine   = repmat('-', 1, totalWidth);
    sepLine    = repmat('=', 1, totalWidth);

    if isempty(propLabel)
        secHeader = secName;
    else
        secHeader = sprintf('%s  [ Property: %s ]', secName, propLabel);
    end

    secPad = floor((totalWidth - length(secHeader)) / 2);
    if secPad < 0, secPad = 0; end

    fprintf('%*s%s\n', secPad, '', secHeader);
    fprintf('%s\n', dashLine);
    fprintf(fileID, '%*s%s\n', secPad, '', secHeader);
    fprintf(fileID, '%s\n', dashLine);

    headerStr = sprintf('%-*s', col1Width, 'Component Name');
    for r = 1:numRuns
        headerStr = [headerStr, sprintf(' | %-*s', colWidths(r), runIDs{r})]; %#ok<AGROW>
    end
    fprintf('%s\n', headerStr);
    fprintf('%s\n', dashLine);
    fprintf(fileID, '%s\n', headerStr);
    fprintf(fileID, '%s\n', dashLine);

    for k = 1:length(rowKeys)
        rKey = rowKeys{k};

        if startsWith(rKey, 'TOTAL')
            fprintf('%s\n', dashLine);
            fprintf(fileID, '%s\n', dashLine);
        end

        rowStr = sprintf('%-*s', col1Width, rKey);
        for r = 1:numRuns
            dKey = sprintf('%s::%s::%s', secName, rKey, runIDs{r});
            if isKey(dataMap, dKey)
                valStr = dataMap(dKey);
            else
                valStr = '-';
            end
            rowStr = [rowStr, sprintf(' | %-*s', colWidths(r), valStr)]; %#ok<AGROW>
        end

        fprintf('%s\n', rowStr);
        fprintf(fileID, '%s\n', rowStr);
    end

    fprintf('%s\n\n', sepLine);
    fprintf(fileID, '%s\n\n', sepLine);
end

% =========================================================================
% GENERAL UTILITIES
% =========================================================================

function keysList = addWeightSummaryEntry(paramKey, runID, valStr, keysList, summaryMap)
    if ~ismember(paramKey, keysList)
        keysList{end+1} = paramKey; %#ok<AGROW>
    end
    dataKey = sprintf('%s::%s', paramKey, runID);
    summaryMap(dataKey) = valStr;
end

function valStr = extractValueStr(lineStr)
    parts = strsplit(lineStr, ':');
    if length(parts) >= 2
        valStr = strtrim(strjoin(parts(2:end), ':'));
    else
        valStr = strtrim(lineStr);
    end
end

function numVal = extractNumericVal(lineStr)
    tokens = regexp(lineStr, ':\s*([-\d\.]+)', 'tokens');
    if ~isempty(tokens)
        numVal = str2double(tokens{1}{1});
    else
        numVal = NaN;
    end
end

function addSysEntry(sec, rowKey, runID, val, sectionKeysMap, dataMap)
    if isKey(sectionKeysMap, sec)
        currentKeys = sectionKeysMap(sec);
    else
        currentKeys = {};
    end

    if ~ismember(rowKey, currentKeys)
        currentKeys{end+1} = rowKey; %#ok<AGROW>
        sectionKeysMap(sec) = currentKeys;
    end
    
    dataKey = sprintf('%s::%s::%s', sec, rowKey, runID);
    dataMap(dataKey) = val;
end

function secName = cleanSectionName(rawStr)
    rawUpper = upper(strtrim(rawStr));
    switch rawUpper
        case {'ELECTRICALCONSUMERS', 'ELECTRICAL CONSUMERS'}
            secName = 'Electrical Consumers';
        case {'ELECTRICALGENERATORS', 'ELECTRICAL GENERATORS'}
            secName = 'Electrical Generators';
        case {'FUELCONSUMERS', 'FUEL CONSUMERS'}
            secName = 'Fuel Consumers';
        case {'FUELPRODUCERS', 'FUEL PRODUCERS'}
            secName = 'Fuel Producers';
        case {'LUBECONSUMERS', 'LUBE CONSUMERS'}
            secName = 'Lube Consumers';
        case {'LUBEPRODUCERS', 'LUBE PRODUCERS'}
            secName = 'Lube Producers';
        case {'COOLCONSUMERS', 'COOLING CONSUMERS', 'COOLING/FW CONSUMERS'}
            secName = 'Cooling/FW Consumers';
        case {'COOLPRODUCERS', 'COOLING PRODUCERS', 'COOLING/FW PRODUCERS'}
            secName = 'Cooling/FW Producers';
        case {'AIRCONSUMERS', 'COMPRESSED AIR CONSUMERS'}
            secName = 'Compressed Air Consumers';
        case {'AIRPRODUCERS', 'COMPRESSED AIR PRODUCERS'}
            secName = 'Compressed Air Producers';
        case 'WASTE CONSUMERS'
            secName = 'Waste Consumers';
        case 'WASTE PRODUCERS'
            secName = 'Waste Producers';
        otherwise
            secName = '';
    end
end

% =========================================================================
% OVERLAID PLOT GENERATION FUNCTIONS
% =========================================================================

function generateImpactPlotsFromMap(runIDs, dataMap, outputDir)
    runLabels = categorical(runIDs);
    runLabels = reordercats(runLabels, runIDs);

    pdfPath = fullfile(outputDir, 'Change_Impact_Plots.pdf');
    psPath  = fullfile(outputDir, 'Change_Impact_Plots.ps');

    if exist(pdfPath, 'file'), delete(pdfPath); end
    if exist(psPath, 'file'),  delete(psPath);  end

    hasExportGraphics = (exist('exportgraphics', 'file') > 0) || (exist('exportgraphics', 'builtin') > 0);

    % 1. Total Ship Displacement Impact (With Margins = Background, Without Margins = Foreground)
    plotGroupFromMap(runLabels, runIDs, dataMap, ...
        {'Weights_Plot_Data', 'Weights_Plot_Data'}, ...
        {'DISPLACEMENT (WITH MARGINS)', 'DISPLACEMENT (WITHOUT MARGINS)'}, ...
        'Total Ship Displacement Impact', 'Displacement (tons)', ...
        pdfPath, psPath, hasExportGraphics);

    % 2. Electrical & Power Impact (Generated = Background, Required = Foreground)
    plotGroupFromMap(runLabels, runIDs, dataMap, ...
        {'Electrical Generators', 'Electrical Consumers'}, ...
        {'TOTAL POWER GENERATED', 'TOTAL POWER REQUIRED'}, ...
        'Electrical System Change Impact', 'Power (kW)', ...
        pdfPath, psPath, hasExportGraphics);

    % 3. Fuel System Impact (Generated = Background, Required = Foreground)
    plotGroupFromMap(runLabels, runIDs, dataMap, ...
        {'Fuel Producers', 'Fuel Consumers'}, ...
        {'TOTAL FUEL OIL GENERATED', 'TOTAL FUEL OIL REQUIRED'}, ...
        'Fuel System Change Impact', 'Flow Rate (m^3/s)', ...
        pdfPath, psPath, hasExportGraphics);

    % 4. Lube Oil System Impact (Generated = Background, Required = Foreground)
    plotGroupFromMap(runLabels, runIDs, dataMap, ...
        {'Lube Producers', 'Lube Consumers'}, ...
        {'TOTAL LUBE OIL GENERATED', 'TOTAL LUBE OIL REQUIRED'}, ...
        'Lube Oil System Change Impact', 'Flow Rate (m^3/s)', ...
        pdfPath, psPath, hasExportGraphics);

    % 5. Cooling / FW System Impact (Generated = Background, Required = Foreground)
    plotGroupFromMap(runLabels, runIDs, dataMap, ...
        {'Cooling/FW Producers', 'Cooling/FW Consumers'}, ...
        {'TOTAL COOLING GENERATED', 'TOTAL COOLING REQUIRED'}, ...
        'Cooling System Change Impact', 'Flow Rate (m^3/s)', ...
        pdfPath, psPath, hasExportGraphics);

    % 6. Compressed Air System Impact (Generated = Background, Required = Foreground)
    plotGroupFromMap(runLabels, runIDs, dataMap, ...
        {'Compressed Air Producers', 'Compressed Air Consumers'}, ...
        {'TOTAL COMPRESSED AIR GENERATED', 'TOTAL COMPRESSED AIR REQUIRED'}, ...
        'Compressed Air System Change Impact', 'Flow Rate (m^3/s)', ...
        pdfPath, psPath, hasExportGraphics);

    % 7. Waste Generation Impact (4 Bars -> Grouped)
    plotGroupFromMap(runLabels, runIDs, dataMap, ...
        {'Waste Producers', 'Waste Producers', 'Waste Producers', 'Waste Producers'}, ...
        {'TOTAL WASTE GAS GENERATED', 'TOTAL WASTE OIL GENERATED', 'TOTAL WASTE WATER GENERATED', 'TOTAL WASTE SOLID GENERATED'}, ...
        'Waste Generation Change Impact', 'Rate (m^3/s or kg/s)', ...
        pdfPath, psPath, hasExportGraphics);

    if hasExportGraphics
        fprintf('Compiled all graph pages into a single file: "%s"\n\n', pdfPath);
    else
        [status, ~] = system(sprintf('ps2pdf "%s" "%s"', psPath, pdfPath));
        if status == 0 && exist(pdfPath, 'file')
            delete(psPath);
            fprintf('Compiled all graph pages into a single file: "%s"\n\n', pdfPath);
        else
            fprintf('Compiled all graph pages into a single multi-page PostScript file: "%s"\n\n', psPath);
        end
    end
end

function plotGroupFromMap(runLabels, runIDs, dataMap, targetSecs, targetTotals, plotTitle, yLabelText, pdfPath, psPath, hasExportGraphics)
    numRuns = length(runIDs);
    validLabels = {};
    dataMatrix = [];

    for i = 1:length(targetTotals)
        sec = targetSecs{i};
        totLabel = targetTotals{i};

        vals = nan(numRuns, 1);
        hasData = false;

        for r = 1:numRuns
            dKey = sprintf('%s::%s::%s', sec, totLabel, runIDs{r});

            if ~isKey(dataMap, dKey) && contains(totLabel, 'COOLING REQUIRED')
                dKeyAlt = sprintf('%s::%s::%s', sec, 'TOTAL COOLING/FW REQUIRED', runIDs{r});
                if isKey(dataMap, dKeyAlt), dKey = dKeyAlt; end
            end

            if isKey(dataMap, dKey)
                numVal = str2double(dataMap(dKey));
                if ~isnan(numVal)
                    vals(r) = numVal;
                    hasData = true;
                end
            end
        end

        if hasData
            dataMatrix = [dataMatrix, vals]; %#ok<AGROW>
            validLabels{end+1} = totLabel; %#ok<AGROW>
        end
    end

    if isempty(dataMatrix)
        return;
    end

    % 1. Create figure locked to solid white background
    f = figure('Name', plotTitle, 'Position', [150, 150, 850, 500], ...
               'Color', [1 1 1], 'InvertHardcopy', 'off', 'Visible', 'off');

    ax = axes('Parent', f);

    numGroups = size(dataMatrix, 1);
    numBars   = size(dataMatrix, 2);

    maxVal = max(dataMatrix(:), [], 'omitnan');
    minVal = min(dataMatrix(:), [], 'omitnan');
    if isnan(minVal) || minVal > 0, minVal = 0; end
    if isempty(maxVal) || isnan(maxVal) || maxVal == 0, maxVal = 1; end

    valRange = maxVal - minVal;
    if valRange == 0, valRange = maxVal; end
    if valRange == 0, valRange = 1; end

    % -------------------------------------------------------------------------
    % OVERLAID SPECIFIC PLOTTING FOR 2-BAR CHARTS
    % -------------------------------------------------------------------------
    if numBars == 2
        x = 1:numGroups;

        % Outer/Background Bar (Wider) -> Generated / Capacity
        b1 = bar(ax, x, dataMatrix(:,1), 0.52, 'FaceColor', [0.2 0.45 0.75], 'EdgeColor', [0.1 0.3 0.6]);
        hold(ax, 'on');
        
        % Foreground Bar (Narrower inside) -> Required / Demand
        b2 = bar(ax, x, dataMatrix(:,2), 0.28, 'FaceColor', [0.85 0.35 0.25], 'EdgeColor', [0.6 0.15 0.1]);
        hold(ax, 'off');

        xticks(ax, x);
        xticklabels(ax, runIDs);
        ax.TickLabelInterpreter = 'none';
        xlim(ax, [0.4, numGroups + 0.6]);

        % Data annotations positioned clearly above each bar top (NUMERIC ONLY, SOLID BLACK)
        for g = 1:numGroups
            v1 = dataMatrix(g, 1);
            v2 = dataMatrix(g, 2);

            if ~isnan(v1) && v1 ~= 0
                txt1 = sprintf('%.2f', v1);
                text(ax, g - 0.14, v1 + 0.02 * valRange, txt1, ...
                    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                    'FontSize', 8, 'FontWeight', 'bold', 'Color', [0 0 0], 'Interpreter', 'none');
            end

            if ~isnan(v2) && v2 ~= 0
                txt2 = sprintf('%.2f', v2);
                text(ax, g + 0.14, v2 + 0.02 * valRange, txt2, ...
                    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                    'FontSize', 8, 'FontWeight', 'bold', 'Color', [0 0 0], 'Interpreter', 'none');
            end
        end

        lgd = legend(ax, [b1, b2], validLabels, 'Interpreter', 'none', 'Location', 'northeastoutside');

    % -------------------------------------------------------------------------
    % STANDARD GROUPED PLOTTING FOR 1 OR >2 BARS
    % -------------------------------------------------------------------------
    else
        b = bar(ax, runLabels, dataMatrix, 'grouped');
        ax.TickLabelInterpreter = 'none';

        for g = 1:numGroups
            for barIdx = 1:numBars
                val = dataMatrix(g, barIdx);
                if ~isnan(val) && val ~= 0
                    if numBars == 1
                        xPos = g;
                    else
                        xPos = b(barIdx).XEndPoints(g);
                    end

                    txtLabel = sprintf('%.2f', val);

                    text(ax, xPos, val + 0.02 * valRange, txtLabel, ...
                        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                        'FontSize', 8, 'FontWeight', 'bold', 'Color', [0 0 0], 'Interpreter', 'none');
                end
            end
        end

        lgd = legend(ax, validLabels, 'Interpreter', 'none', 'Location', 'northeastoutside');
    end

    % -------------------------------------------------------------------------
    % FORCE AXES GRAPH CANVAS TO WHITE (AFTER BAR COMMANDS EXECUTE)
    % -------------------------------------------------------------------------
    set(ax, 'Color', [1 1 1], ...
            'XColor', [0 0 0], ...
            'YColor', [0 0 0], ...
            'Box', 'on', ...
            'FontSize', 10, ...
            'GridColor', [0.8 0.8 0.8], ...
            'GridAlpha', 0.7, ...
            'MinorGridColor', [0.9 0.9 0.9], ...
            'MinorGridAlpha', 0.6);

    grid(ax, 'on');
    ax.YMinorGrid = 'on';

    % Y-AXIS HEADROOM (35% top space)
    yUpper = maxVal + 0.35 * valRange;
    ylim(ax, [minVal, yUpper]);

    title(ax, plotTitle, 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0 0 0], 'Interpreter', 'none');
    xlabel(ax, 'Design Iteration / Run ID', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0 0 0], 'Interpreter', 'none');
    ylabel(ax, yLabelText, 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0 0 0], 'Interpreter', 'none');

    if ~isempty(lgd)
        set(lgd, 'Color', [1 1 1], 'TextColor', [0 0 0], 'EdgeColor', [0.8 0.8 0.8]);
    end

    drawnow;

    % EXPORT WITH HARDCODED PURE WHITE BACKGROUND
    if hasExportGraphics
        exportgraphics(f, pdfPath, 'Append', true, 'BackgroundColor', [1 1 1]);
    else
        set(f, 'PaperPositionMode', 'auto');
        print(f, psPath, '-dpsc', '-append');
    end

    close(f);
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright"}
%---
