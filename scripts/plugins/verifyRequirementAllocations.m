function verifyRequirementAllocations()
    
    reqSetName = 'ShipRequirements';
    sysComposerModel = 'SYSTEM';
    outputFileName = 'UnallocatedReq.txt';
    
    % Open output text file for writing
    fid = fopen(outputFileName, 'w');
    if fid == -1
        error('Could not open file %s for writing. Check permissions.', outputFileName);
    end
    
    % Automatically close the file on function completion or error
    cleanUpFile = onCleanup(@() fclose(fid));
    
    % 1. Load Requirement Set
    reqSet = slreq.load(reqSetName);
    if isempty(reqSet)
        error('Could not load requirement set: %s. Check the file name and path.', reqSetName);
    end
    
    % Strip extension from model name
    [~, cleanModelName, ~] = fileparts(sysComposerModel);
    
    % Load System Composer model
    sysModelObj = systemcomposer.loadModel(cleanModelName);
    
    logPrint(fid, '=== BI-DIRECTIONAL ALLOCATION VERIFICATION ===\n');
    logPrint(fid, 'Requirements Set: [%s]\n', reqSetName);
    logPrint(fid, 'System Model:     [%s]\n\n', cleanModelName);
    
    % =========================================================================
    % PART 1: Verify Requirements -> Components Allocation
    % =========================================================================
    queue = reqSet.children;
    unallocatedReqs = {};
    totalReqCount = 0;
    allocatedReqCount = 0;
    
    while ~isempty(queue)
        req = queue(1);
        queue(1) = [];
        totalReqCount = totalReqCount + 1;
        
        % Add child requirements to queue if they exist
        childReqs = req.children;
        for c = 1:length(childReqs)
            queue = [queue, childReqs(c)]; %#ok<AGROW>
        end
        
        % Get incoming and outgoing links
        incomingLinks = slreq.inLinks(req);
        outgoingLinks = slreq.outLinks(req);
        allLinks = [incomingLinks, outgoingLinks];
        
        hasAllocation = false;
        if ~isempty(allLinks)
            for i = 1:length(allLinks)
                if checkLinkArtifact(allLinks(i), cleanModelName)
                    hasAllocation = true;
                    break;
                end
            end
        end
        
        if hasAllocation
            allocatedReqCount = allocatedReqCount + 1;
        else
            reqID = req.Id;
            if isempty(reqID)
                reqID = sprintf('Req #%d', totalReqCount);
            end
            unallocatedReqs{end+1} = struct('ID', string(reqID), 'Summary', string(req.Summary)); %#ok<AGROW>
        end
    end
    
    % Sort unallocated requirements numerically by ID
    if ~isempty(unallocatedReqs)
        allIDs = arrayfun(@(x) x.ID, [unallocatedReqs{:}]);
        nums = nan(1, length(allIDs));
        for k = 1:length(allIDs)
            d = extract(allIDs(k), digitsPattern);
            if ~isempty(d)
                nums(k) = str2double(d{1}); % Safely extract first set of digits
            end
        end
        [~, sortIdx] = sort(nums);
        unallocatedReqs = unallocatedReqs(sortIdx);
    end
    
    % =========================================================================
    % PART 2: Verify Components -> Requirements Allocation
    % =========================================================================
    % Collect all components in the System Composer model hierarchy
    allComps = getAllComponents(sysModelObj.Architecture);
    totalCompCount = length(allComps);
    allocatedCompCount = 0;
    unallocatedComps = {};
    
    for k = 1:totalCompCount
        compObj = allComps(k);
        
        % Check links on component itself or parent VARIANT components
        hasReqLink = checkCompAndParentsHasReqLink(compObj, reqSetName);
        
        if hasReqLink
            allocatedCompCount = allocatedCompCount + 1;
        else
            % Extract only the component's own name (lowest level subdivision)
            unallocatedComps{end+1} = compObj.Name; %#ok<AGROW>
        end
    end
    
    % Sort unallocated component names alphabetically
    unallocatedComps = sort(unallocatedComps);
    
    % =========================================================================
    % PART 3: Print Output Summary to Screen & File
    % =========================================================================
    logPrint(fid, '-----------------------------------------------------------\n');
    logPrint(fid, '1. REQUIREMENTS COVERAGE REPORT\n');
    logPrint(fid, '-----------------------------------------------------------\n');
    logPrint(fid, 'Total Requirements Checked: %d\n', totalReqCount);
    logPrint(fid, 'Allocated Requirements:     %d\n', allocatedReqCount);
    logPrint(fid, 'Unallocated Requirements:   %d\n\n', length(unallocatedReqs));
    
    if isempty(unallocatedReqs)
        logPrint(fid, ' SUCCESS: Every requirement is allocated to at least one component.\n\n');
    else
        logPrint(fid, ' WARNING: The following requirements have NO allocations:\n');
        for k = 1:length(unallocatedReqs)
            logPrint(fid, '  • [%s] %s\n', unallocatedReqs{k}.ID, unallocatedReqs{k}.Summary);
        end
        logPrint(fid, '\n');
    end
    
    logPrint(fid, '-----------------------------------------------------------\n');
    logPrint(fid, '2. ARCHITECTURE COMPONENT COVERAGE REPORT\n');
    logPrint(fid, '-----------------------------------------------------------\n');
    logPrint(fid, 'Total Components Checked:   %d\n', totalCompCount);
    logPrint(fid, 'Allocated Components:       %d\n', allocatedCompCount);
    logPrint(fid, 'Unallocated Components:     %d\n\n', length(unallocatedComps));
    
    if isempty(unallocatedComps)
        logPrint(fid, ' SUCCESS: Every component is allocated to at least one requirement.\n\n');
    else
        logPrint(fid, ' WARNING: The following components have NO requirement allocations:\n');
        for k = 1:length(unallocatedComps)
            logPrint(fid, '  • %s\n', unallocatedComps{k});
        end
        logPrint(fid, '-----------------------------------------------------------\n');
    end
    
    fprintf('\nReport successfully saved to: %s\n', outputFileName);
    
end

% Helper Function: Print formatted text to both Command Window and Output File
function logPrint(fid, formatSpec, varargin)
    fprintf(formatSpec, varargin{:});      % Display in MATLAB Command Window
    if fid > 0
        fprintf(fid, formatSpec, varargin{:}); % Write to UnallocatedReq.txt
    end
end

% Helper Function: Safely check if a link connects to a target artifact name
function tf = checkLinkArtifact(linkObj, artifactName)
    tf = false;
    
    % Check Source struct
    src = linkObj.source;
    if isstruct(src) && isfield(src, 'artifact') && contains(src.artifact, artifactName, 'IgnoreCase', true)
        tf = true;
        return;
    end
    
    % Check Destination struct
    dest = linkObj.destination;
    if isstruct(dest) && isfield(dest, 'artifact') && contains(dest.artifact, artifactName, 'IgnoreCase', true)
        tf = true;
        return;
    end
end

% Helper Function: Recursively fetch all components in System Composer architecture
function comps = getAllComponents(arch)
    comps = reshape(arch.Components, 1, []);
    for i = 1:length(arch.Components)
        subArch = arch.Components(i).OwnedArchitecture;
        if ~isempty(subArch) && ~isempty(subArch.Components)
            comps = [comps, getAllComponents(subArch)]; %#ok<AGROW>
        end
    end
end

% Helper Function: Check if component or parent VARIANT component is linked
function hasReqLink = checkCompAndParentsHasReqLink(compObj, reqSetName)
    hasReqLink = false;
    
    % 1. Check direct link on component itself
    compPath = compObj.getQualifiedName();
    if checkPathLinks(compPath, reqSetName)
        hasReqLink = true;
        return;
    end
    
    % 2. Object-based traversal (Only inherit from parent if parent is a Variant Component)
    currComp = compObj;
    while ~isempty(currComp)
        parentComp = getParentComponent(currComp);
        if isempty(parentComp)
            break;
        end
        
        if isVariantComponent(parentComp, [])
            parentPath = parentComp.getQualifiedName();
            if checkPathLinks(parentPath, reqSetName)
                hasReqLink = true;
                return;
            end
            currComp = parentComp; % Continue checking if nested in another variant
        else
            break; % Stop climbing if parent is NOT a variant component
        end
    end
    
    % 3. String path-based traversal fallback (Variant Components ONLY)
    pathParts = strsplit(compPath, '/');
    for i = (length(pathParts)-1):-1:2
        parentPath = strjoin(pathParts(1:i), '/');
        if isVariantComponent([], parentPath)
            if checkPathLinks(parentPath, reqSetName)
                hasReqLink = true;
                return;
            end
        else
            break; % Stop climbing if path parent is NOT a variant component
        end
    end
end

% Helper Function: Safely check if a component is a Variant Component
function tf = isVariantComponent(compObj, compPath)
    tf = false;
    
    % Check System Composer class type or property
    if ~isempty(compObj)
        if isa(compObj, 'systemcomposer.arch.VariantComponent')
            tf = true;
            return;
        end
        if isprop(compObj, 'IsVariant') && compObj.IsVariant
            tf = true;
            return;
        end
        if isempty(compPath) && ismethod(compObj, 'getQualifiedName')
            compPath = compObj.getQualifiedName();
        end
    end
    
    % Fallback: Check Simulink block parameters if path is available
    if ~isempty(compPath)
        try
            if bdIsLoaded(bdroot(compPath))
                varParam = get_param(compPath, 'Variant');
                if strcmp(varParam, 'on')
                    tf = true;
                    return;
                end
            end
        catch
            % Block is not a variant component or path invalid
        end
    end
end

% Helper Function: Get parent component object from child component
function parentComp = getParentComponent(compObj)
    parentComp = [];
    if isprop(compObj, 'Parent') && ~isempty(compObj.Parent)
        arch = compObj.Parent;
        if isprop(arch, 'Parent') && ~isempty(arch.Parent)
            parentComp = arch.Parent;
        end
    end
end

% Helper Function: Check if a qualified path string has links to target requirement set
function tf = checkPathLinks(compPath, reqSetName)
    tf = false;
    compIn = slreq.inLinks(compPath);
    compOut = slreq.outLinks(compPath);
    compLinks = [compIn, compOut];
    
    if ~isempty(compLinks)
        for l = 1:length(compLinks)
            if checkLinkArtifact(compLinks(l), reqSetName)
                tf = true;
                return;
            end
        end
    end
end