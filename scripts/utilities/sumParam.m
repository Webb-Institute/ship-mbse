
% This Section finds all Components with a specific Parameter 
function [ParamValueSum, numCompFound] = sumParam(targetParamName)

    %change to be for the correct system composer architecture
    modelName = "SYSTEM"

    % Necessary for the findElementsOfType command later in the script
    import systemcomposer.query.*

    % Checks if Model is Open, and opens the model if it is closed
    if ~bdIsLoaded(modelName)
        open_system(modelName);
    end

    % Creating Model Object and Creating an Array of All Components
    modelObj= systemcomposer.loadModel(modelName);
    compAll = findElementsOfType(modelObj, 'Component');

    % Initializing Parameter Sum and Number of Components
    ParamValueSum = 0
    numCompFound = 0

    % Iterating through the component array
    for i =1:length(compAll)
        comp=compAll(i)
        
        % Checks to see if compnent has a parameter
        if isempty(comp.Parameters)
            continue;
        end
        
        % Creates array of the parameter names in a specific component 
        parameterNames =string({comp.Parameters.Name});
        targetParamName = string(targetParamName);

        % Looks to see if any of the parameter names match the target name
        if any(parameterNames == targetParamName)
            
            % Retrieve the parameter object and get its value 
            paramObj = comp.getParameter(targetParamName);
            rawValueText = paramObj.Value;

            % Convert to a clean number (stripping units like "W" or "mW")
            splitText = split(rawValueText);
            numValue = str2double(splitText(1));

            % Adds the Parameter Value if it is numerical
            if ~isnan(numValue)
                ParamValueSum = ParamValueSum + numValue;
                numCompFound = numCompFound + 1;
                fprintf('Added %g from component: %s\n', numValue, comp.Name);
            end
        end
    end
end