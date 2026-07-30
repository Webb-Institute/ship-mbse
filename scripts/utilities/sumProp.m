% This Section finds all Components with a specific Property 
% inputs can be character arrays or strings
function [PropValueSum, numCompFound] = sumProp(targetPropName, targetStereotypeName, targetProfileName)

    % Model Name
    modelName = 'SYSTEM';

    % Convert to Character Arrays
    modelName = char(modelName);
    profileName = char(targetProfileName);
    targetStereotypeName = char(targetStereotypeName);
    targetPropName = char(targetPropName);

    % Create Property Path
    propertyPath = [profileName, '.', targetStereotypeName, '.', targetPropName];

    % Checks if Model is Open, and opens the model if it is closed
    if ~bdIsLoaded(modelName)
        open_system(modelName);
    end

    % Creating Model Object
    modelObj = systemcomposer.loadModel(modelName);

    % Initializing Property Sum and Number of Components
    PropValueSum = 0;
    numCompFound = 0;

    % Initialize a stack for traversal starting from top architecture
    archStack = {modelObj.Architecture};

    % Traverse the active model hierarchy directly in the main body
    while ~isempty(archStack)
        % Pop current architecture from stack
        currentArch = archStack{end};
        archStack(end) = [];

        if isempty(currentArch)
            continue;
        end

        childComps = currentArch.Components;

        for i = 1:length(childComps)
            comp = childComps(i);

            % Handle Variant Components vs Standard Components
            if isa(comp, 'systemcomposer.arch.VariantComponent')
                % Skip the variant container, evaluate ONLY the active choice
                targetComp = comp.getActiveChoice();
            else
                % Standard component
                targetComp = comp;
            end

            % Process target component if valid
            if ~isempty(targetComp)
                
                % Check and evaluate property
                if targetComp.hasProperty(propertyPath)

                    rawVal = targetComp.getProperty(propertyPath);

                    if ischar(rawVal) || isstring(rawVal)
                        splitText = split(string(rawVal));
                        numValue = str2double(splitText(1));
                    else
                        numValue = double(rawVal);
                    end

                    if ~isnan(numValue)
                        PropValueSum = PropValueSum + numValue;
                        numCompFound = numCompFound + 1;
                    end
                end

                % Push sub-architecture onto stack to recurse into active child levels
                if ~isempty(targetComp.Architecture)
                    archStack{end+1} = targetComp.Architecture; %#ok<AGROW>
                end
            end
        end
    end
end