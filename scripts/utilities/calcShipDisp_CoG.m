function [displacement, LCG, VCG, TCG] = calcShipDisp_CoG(stereotypeName, profileName)
    import systemcomposer.query.*

    stereotypeName = char(stereotypeName);
    profileName = char(profileName);
    
    modelName = 'SYSTEM';
    if ~bdIsLoaded(modelName)
        open_system(modelName);
    end

    % Load System Composer model
    modelObj = systemcomposer.loadModel(modelName);

    % Get ONLY active components by traversing down from top architecture
    compAll = getActiveComponentsRecursive(modelObj.Architecture);

    % Initialize output variables
    displacement = 0;
    LCG = 0;
    VCG = 0;
    TCG = 0;

    % Construct property paths
    stereotypePath = [profileName, '.', stereotypeName];
    weightPath     = [profileName, '.', stereotypeName, '.Weight'];
    LCGPath        = [profileName, '.', stereotypeName, '.LCG'];
    VCGPath        = [profileName, '.', stereotypeName, '.VCG'];
    TCGPath        = [profileName, '.', stereotypeName, '.TCG'];

    % Loop through active components only
    for i = 1:length(compAll)
        comp = compAll(i);
        stereotypes = string(comp.getStereotypes());

        % Check if component has the specified stereotype
        if any(ismember(stereotypes, string(stereotypePath)))

            % Retrieve property values safely
            weight = str2double(string(getProperty(comp, weightPath)));
            long   = str2double(string(getProperty(comp, LCGPath)));
            vert   = str2double(string(getProperty(comp, VCGPath)));
            tran   = str2double(string(getProperty(comp, TCGPath)));

            % Skip components with missing/invalid numbers
            if isnan(weight) || isnan(long) || isnan(vert) || isnan(tran)
                continue;
            end

            % Accumulate total weight (displacement)
            displacement = displacement + weight;

            % Accumulate moments
            LCG = LCG + (weight * long);
            VCG = VCG + (weight * vert);
            TCG = TCG + (weight * tran);
        end
    end

    % Calculate Center of Gravity: CoG = Total Moments / Displacement
    if displacement > 0
        LCG = LCG / displacement;
        VCG = VCG / displacement;
        TCG = TCG / displacement;
    else
        LCG = 0; 
        VCG = 0; 
        TCG = 0;
    end

    % =========================================================================
    % EMBEDDED NESTED FUNCTION
    % Recursively collects only active implementation components across sub-architectures
    % =========================================================================
    function activeComps = getActiveComponentsRecursive(archObj)
        activeComps = [];
        if isempty(archObj)
            return;
        end
        
        childComps = archObj.Components;
        for cIdx = 1:length(childComps)
            child = childComps(cIdx);
            
            if isa(child, 'systemcomposer.arch.VariantComponent')
                % 1. VARIANT COMPONENT: Skip container, fetch ONLY Active Choice
                activeChoice = child.getActiveChoice();
                if ~isempty(activeChoice)
                    activeComps = [activeComps; activeChoice]; %#ok<AGROW>
                    
                    % Recurse into sub-architecture of active choice if nested
                    if ~isempty(activeChoice.Architecture)
                        subComps = getActiveComponentsRecursive(activeChoice.Architecture);
                        activeComps = [activeComps; subComps]; %#ok<AGROW>
                    end
                end
            else
                % 2. STANDARD COMPONENT: Add component
                activeComps = [activeComps; child]; %#ok<AGROW>
                
                % Recurse into sub-architecture if nested
                if ~isempty(child.Architecture)
                    subComps = getActiveComponentsRecursive(child.Architecture);
                    activeComps = [activeComps; subComps]; %#ok<AGROW>
                end
            end
        end
    end

end