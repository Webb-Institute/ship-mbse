% This Section finds all Components with a specific Property, but only sums if the component is ON 
% inputs can be character arrays or strings
function [PropValueSumON, numCompFoundON] = sumPropIfOn(targetPropName, targetStereotypeName, targetProfileName)

    % Model Name
    modelName = 'SYSTEM';

    % Convert to Character Arrays
    modelName = char(modelName);
    status = char("Status");

    targetProfileName = char(targetProfileName);
    targetStereotypeName = char(targetStereotypeName);
    targetPropName = char(targetPropName);

    % Create Property Paths
    propertyPath = [targetProfileName, '.', targetStereotypeName, '.', targetPropName];
    statusPath = [targetProfileName, '.', targetStereotypeName, '.', status];

    % Checks if Model is Open, and opens the model if it is closed
    if ~bdIsLoaded(modelName)
        open_system(modelName);
    end

    % Creating Model Object
    modelObj = systemcomposer.loadModel(modelName);

    % Initializing Property Sum and Number of Components
    PropValueSumON = 0;
    numCompFoundON = 0;

    % Initialize a stack for depth-first traversal starting from top architecture
    archStack = {modelObj.Architecture};

    % Traverse the active model hierarchy
    while ~isempty(archStack)
        % Pop current architecture from the stack
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
                % Skip the variant container, get ONLY the active choice
                targetComp = comp.getActiveChoice();
            else
                % Standard component
                targetComp = comp;
            end

            % Process target component if valid
            if ~isempty(targetComp)
                
                % Evaluate property if status is ON
                if targetComp.hasProperty(statusPath)
                    
                    isON = targetComp.getEvaluatedPropertyValue(statusPath);
                    
                    if isON   
                        rawVal = targetComp.getProperty(propertyPath);

                        if ischar(rawVal) || isstring(rawVal)
                            splitText = split(string(rawVal));
                            numValue = str2double(splitText(1));
                        else
                            numValue = double(rawVal);
                        end 
                    
                        if ~isnan(numValue)
                            PropValueSumON = PropValueSumON + numValue;
                            numCompFoundON = numCompFoundON + 1;
                        end
                    end
                end

                % Push sub-architecture onto the stack to recurse into child levels
                if ~isempty(targetComp.Architecture)
                    archStack{end+1} = targetComp.Architecture; %#ok<AGROW>
                end
            end
        end
    end
end