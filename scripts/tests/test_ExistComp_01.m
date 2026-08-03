function tests = test_ExistComp_01
% TEST_EXISTENCE_01 Verifies component existence and active variant status
tests = functiontests(localfunctions);
end

function test_VerifyComponentExistsAndIsActive(testCase)
    % --- CONFIGURATION ---
    modelName = 'SYSTEM'; % Top-level model name
    
    if ~bdIsLoaded(modelName)
        load_system(modelName);
    end

    % 1. LOCATE LINKED REQUIREMENT VIA HELPER
    linkedReq = fetchLinkedRequirement();
    testCase.verifyNotEmpty(linkedReq, ...
        'Verification Failed: Could not resolve a linked requirement for this test script.');

    % 2. READ & CLEAN CUSTOM ATTRIBUTE
    rawTarget = string(linkedReq.getAttribute('PerfVal1'));
    componentName = erase(strtrim(rawTarget), ["'", '"']); % Strips quotes and whitespace
    
    testCase.verifyNotEmpty(componentName, ...
        sprintf('Requirement ID "%s" Failed: "PerfVal1" custom attribute is empty.', linkedReq.Id));

    [~, cleanBlockName] = fileparts(componentName);

    % 3. SEARCH MODEL FOR ALL INSTANCES (Active + Inactive)
    foundAll = find_system(modelName, ...
        'MatchFilter', @Simulink.match.allVariants, ...
        'Name', cleanBlockName);

    if isempty(foundAll) && contains(componentName, '/')
        if bdIsLoaded(strtok(componentName, '/'))
            foundAll = find_system(modelName, ...
                'MatchFilter', @Simulink.match.allVariants, ...
                'Path', componentName);
        end
    end

    % FAIL CONDITION 1: Component does not exist anywhere in the model
    testCase.verifyNotEmpty(foundAll, ...
        sprintf('Requirement ID "%s" Failed: Component "%s" does not exist anywhere in model "%s".', ...
        linkedReq.Id, cleanBlockName, modelName));

    if isempty(foundAll)
        return;
    end

    % 4. VERIFY ACTIVE STATUS AT EDIT-TIME
    hasActiveInstance = false;
    for k = 1:length(foundAll)
        if isBlockActiveAtEditTime(foundAll{k})
            hasActiveInstance = true;
            break;
        end
    end

    % FAIL CONDITION 2: Component exists, but is an inactive variant choice
    testCase.verifyTrue(hasActiveInstance, ...
        sprintf('Requirement ID "%s" Failed: Component "%s" exists in model "%s", but it is currently an INACTIVE variant choice.', ...
        linkedReq.Id, cleanBlockName, modelName));
end

% =========================================================================
% HELPER: EDIT-TIME ACTIVE PATH INSPECTOR
% =========================================================================
function isActive = isBlockActiveAtEditTime(blkPath)
    isActive = true;
    currentPath = blkPath;
    
    % Traverse up the model hierarchy checking every parent subsystem
    while true
        parentPath = get_param(currentPath, 'Parent');
        if isempty(parentPath)
            break;
        end
        
        % If parent is a Variant Subsystem, verify active choice
        if strcmp(get_param(parentPath, 'Type'), 'block') && strcmp(get_param(parentPath, 'BlockType'), 'SubSystem')
            try
                isVar = strcmp(get_param(parentPath, 'Variant'), 'on');
            catch
                isVar = false;
            end
            
            if isVar
                % Retrieve active choice setting from parent
                activeChoice = get_param(parentPath, 'ActiveVariant');
                if isempty(activeChoice)
                    try
                        activeChoice = get_param(parentPath, 'LabelModeActiveChoice');
                    catch
                    end
                end
                
                childName = get_param(currentPath, 'Name');
                
                % If active choice is designated and does not match this branch, mark inactive
                if ~isempty(activeChoice) && ~strcmp(activeChoice, childName)
                    isActive = false;
                    return;
                end
            end
        end
        
        currentPath = parentPath;
        if ~contains(currentPath, '/')
            break;
        end
    end
end

% =========================================================================
% HELPER: SAFELY RESOLVES LINKED REQUIREMENT FROM SLREQ LINK SETS
% =========================================================================
function req = fetchLinkedRequirement()
    testFileName = [mfilename, '.m'];
    allLinks = slreq.find('Type', 'Link');
    req = [];
    
    for k = 1:length(allLinks)
        lk = allLinks(k);
        srcStruct = source(lk);
        dstStruct = destination(lk);
        
        if isstruct(srcStruct) && isfield(srcStruct, 'artifact') && ~isempty(srcStruct.artifact)
            if contains(string(srcStruct.artifact), testFileName) && isstruct(dstStruct)
                try
                    reqObj = slreq.structToObj(dstStruct);
                    if isa(reqObj, 'slreq.Requirement')
                        req = reqObj;
                        break;
                    end
                catch
                end
            end
        end
        
        if isstruct(dstStruct) && isfield(dstStruct, 'artifact') && ~isempty(dstStruct.artifact)
            if contains(string(dstStruct.artifact), testFileName) && isstruct(srcStruct)
                try
                    reqObj = slreq.structToObj(srcStruct);
                    if isa(reqObj, 'slreq.Requirement')
                        req = reqObj;
                        break;
                    end
                catch
                end
            end
        end
    end
end