function applyProperties(filename)
    % Necessary for the findElementsOfType command later in the script
    import systemcomposer.query.*

    modelName = 'SYSTEM';
    rawCellData = readcell(filename, 'Range', 'A1');
    profileNames = rawCellData(1, 2:end);
    stereotypeNames = rawCellData(2, 2:end);
    propertyNames = rawCellData(3, 2:end);
    componentNames = rawCellData(5:end, 1);

    if ~bdIsLoaded(modelName)
        open_system(modelName);
    end

    % Creating Model Object
    modelObj = systemcomposer.loadModel(modelName);

    % findElementsOfType returns standard components & VariantComponent objects
    compAll = findElementsOfType(modelObj, 'Component');

    % ---------------- EFFICIENT ELEMENT INDEXING ----------------
    % Build a unique list of all model elements, including individual variant choices
    allElements = {};
    seenUUIDs = containers.Map('KeyType', 'char', 'ValueType', 'logical');

    for k = 1:length(compAll)
        comp = compAll(k);
        compUUID = char(comp.UUID);

        if ~isKey(seenUUIDs, compUUID)
            allElements{end+1} = comp; %#ok<AGROW>
            seenUUIDs(compUUID) = true;
        end
        
        % If component is a Variant Container, extract all individual choices
        if isa(comp, 'systemcomposer.arch.VariantComponent')
            choices = comp.getChoices();
            for c = 1:length(choices)
                choiceComp = choices(c);
                choiceUUID = char(choiceComp.UUID);
                
                if ~isKey(seenUUIDs, choiceUUID)
                    allElements{end+1} = choiceComp; %#ok<AGROW>
                    seenUUIDs(choiceUUID) = true;
                end
            end
        end
    end
    % ------------------------------------------------------------

    % Loop through each property column in spreadsheet
    for i = 1:length(propertyNames)

        % Set Current Names and Values
        currentProfile = char(profileNames(i));
        currentStereotype = char(stereotypeNames(i));
        currentProperty = char(propertyNames(i));
        currentPropertyValues = rawCellData(5:end, 1+i);

        % Create Stereotype Path as a character array
        currentStereotypePath = [currentProfile, '.', currentStereotype];

        % Create Property Path as a character array
        currentPropertyPath = [currentProfile, '.', currentStereotype, '.', currentProperty];

        % Loop through each component row in spreadsheet
        for j = 1:length(componentNames)

            % Set Component Name from Spreadsheet
            currentComponentName = char(componentNames{j});

            % Check if N/A — if so, skip to next row
            prop = string(currentPropertyValues(j));
            if prop == "N/A" || ismissing(prop)
                continue;
            end

            for k = 1:length(allElements)
                comp = allElements{k};

                % Check if short name or full path matches
                isMatch = strcmp(comp.Name, currentComponentName) || ...
                    strcmp(comp.getQualifiedName, currentComponentName);

                if isMatch
                    if isa(comp, 'systemcomposer.arch.VariantComponent')
                        % ---------------- VARIANT CONTAINER MATCH ----------------
                        % Spreadsheet targeted the container name: apply to ALL choices inside
                        choices = comp.getChoices();

                        for c = 1:length(choices)
                            choiceComp = choices(c);

                            if ~choiceComp.hasStereotype(currentStereotypePath)
                                choiceComp.applyStereotype(currentStereotypePath);
                            end

                            choiceComp.setProperty(currentPropertyPath, prop);
                        end

                    else
                        % ---------------- STANDARD COMPONENT / SPECIFIC VARIANT CHOICE ----------------
                        % Spreadsheet targeted a standard component OR a specific variant choice
                        if ~comp.hasStereotype(currentStereotypePath)
                            comp.applyStereotype(currentStereotypePath);
                        end

                        comp.setProperty(currentPropertyPath, prop);
                    end
                end
            end 
        end
    end
    disp("Done")
end