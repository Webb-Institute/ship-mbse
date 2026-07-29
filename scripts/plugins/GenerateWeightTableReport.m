function weightTable = GenerateWeightTableReport()


    import systemcomposer.query.*

    modelName = 'SYSTEM';
    
    weightPath = 'WeightsCentersProfile.WeightsCenters.Weight';
    marginPath = 'WeightsCentersProfile.WeightsCenters.WeightMargin';
    LCGPath = 'WeightsCentersProfile.WeightsCenters.LCG';
    VCGPath = 'WeightsCentersProfile.WeightsCenters.VCG';
    TCGPath = 'WeightsCentersProfile.WeightsCenters.TCG';

    if ~bdIsLoaded(modelName)
        open_system(modelName);
    end

    applyProperties();

    % Creating Model Object and Creating an Array of All Components
    modelObj= systemcomposer.loadModel(modelName);
    compAll = findElementsOfType(modelObj, 'Component');

    % Initialize empty arrays to store table data
    compNames   = string.empty;
    baseWeights = double.empty;
    marginWts   = double.empty;
    totalWts    = double.empty;
    xCoGs       = double.empty;
    yCoGs       = double.empty;
    zCoGs       = double.empty;

    for i =1:length(compAll)
        comp =compAll(i);

        if comp.hasStereotype('WeightsCentersProfile.WeightsCenters')
            compNames(end+1, 1)   = comp.Name;
            baseWeights(end+1, 1) = str2double(comp.getProperty(weightPath));
            marginWts(end+1, 1)   = str2double(comp.getProperty(marginPath));
            totalWts(end+1, 1)    = round(str2double(comp.getProperty(weightPath)) * (1 + str2double(comp.getProperty(marginPath))/100));
            xCoGs(end+1, 1)       = str2double(comp.getProperty(LCGPath));
            yCoGs(end+1, 1)       = str2double(comp.getProperty(TCGPath));
            zCoGs(end+1, 1)       = str2double(comp.getProperty(VCGPath));
        end
    end

    % Build the MATLAB Table
    weightTable = table(compNames, baseWeights, marginWts, totalWts, xCoGs, yCoGs, zCoGs, ...
        'VariableNames', {'ComponentName', 'BaseWeight_t', 'MarginWeight_per', 'TotalWeight_t', 'LCG_m', 'TCG_m', 'VCG_m'});

    if ~isempty(weightTable)
        % 1. Extract leading numeric digits from ComponentName (e.g., "12_Pump" -> 12)
        % '^\d+' matches consecutive digits at the beginning of the string
        sortNumbers = str2double(regexp(weightTable.ComponentName, '^\d+', 'match', 'once'));
        
        % Replace any components without leading numbers with Inf so they appear at the bottom
        sortNumbers(isnan(sortNumbers)) = Inf;
        
        % 2. Temporarily attach the sort index to the table
        weightTable.SortKey = sortNumbers;
        
        % 3. Sort by the numeric key first, and component name second (for tie-breakers)
        weightTable = sortrows(weightTable, {'SortKey', 'ComponentName'});
        
        % 4. Remove the temporary helper column
        weightTable.SortKey = [];
    end

    % --- CALCULATE SHIP TOTALS (Displacement & Global CoG) ---
    [shipDisplacement, shipCoG_X, shipCoG_Z, shipCoG_Y]= calcShipDisp_CoG();
    [mshipDisplacement, mshipCoG_X, mshipCoG_Z, mshipCoG_Y]= marginCalcShipDisp_CoG();

 
    % --- OPEN FILE FOR WRITING ---
    fileID = fopen('WeightsAndMarginsReport.txt', 'wt');
    if fileID == -1
        error('Could not open file "%s" for writing. Check folder permissions.', 'WeightsAndMarginsReport.txt');
    end    

    for t = fileID
        fprintf(t, '%s\n\n', repmat('=', 1, 104));
        fprintf(t, '                                VESSEL WEIGHT & CENTER OF GRAVITY REPORT                            \n');
        fprintf(t, '%s\n\n', repmat('=', 1, 104));

        % Table Header with Fixed Width Columns
        fprintf(t, '%-28s | %-10s | %-10s | %-10s | %-9s | %-9s | %-9s\n', ...
            'Component Name', 'Weight (t)', 'Margin (%)', 'Total (t)', 'LCG (m)', 'TCG (m)', 'VCG (m)');
        fprintf(t, '%s\n', repmat('-', 1, 104));

        % Table Rows
        for i = 1:height(weightTable)
            fprintf(t, '%-28s | %10.2f | %10.2f | %10.2f | %9.2f | %9.2f | %9.2f\n', ...
                weightTable.ComponentName(i), ...
                weightTable.BaseWeight_t(i), ...
                weightTable.MarginWeight_per(i), ...
                weightTable.TotalWeight_t(i), ...
                weightTable.LCG_m(i), ...
                weightTable.TCG_m(i), ...
                weightTable.VCG_m(i));
        end

        fprintf(t, '%s\n\n', repmat('=', 1, 104));
        fprintf(t, '%s\n\n', repmat('-', 1, 104));
        fprintf(t, '                                       TOTAL SHIP SUMMARY                                           \n');
        fprintf(t, '%s\n\n', repmat('-', 1, 104));
        fprintf(t, ' Total Ship Displacement (with margins) : %10.2f tons\n', mshipDisplacement);
        fprintf(t, ' Global Center of Gravity - X (Longitudinal): %10.2f m\n', mshipCoG_X);
        fprintf(t, ' Global Center of Gravity - Y (Transverse)  : %10.2f m\n', mshipCoG_Y);
        fprintf(t, ' Global Center of Gravity - Z (Vertical)    : %10.2f m\n', mshipCoG_Z);
        fprintf(t, ' Total Ship Displacement (without margins) : %10.2f tons\n', shipDisplacement);
        fprintf(t, ' Global Center of Gravity - X (Longitudinal): %10.2f m\n', shipCoG_X);
        fprintf(t, ' Global Center of Gravity - Y (Transverse)  : %10.2f m\n', shipCoG_Y);
        fprintf(t, ' Global Center of Gravity - Z (Vertical)    : %10.2f m\n', shipCoG_Z);
        fprintf(t, '%s\n\n', repmat('=', 1, 104));

    end
    % Close the text file
    fclose(fileID);
    fprintf('SUCCESS: Report written to text file "%s" in your current directory.\n\n', 'WeightsAndMarginsReport.txt');
end