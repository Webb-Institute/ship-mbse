function reportTable = generateInterfaceReport()
    % GENERATEINTERFACEREPORT Traverses System Composer architecture connections
    % and follows port connectors across boundaries to report end-to-end 
    % connections between ultimate leaf components.
    % - Strips '_S' and '_P' suffixes from interface names for report output.
    % - Deep-scans INTO variant child components and architecture ports 
    % (e.g., port 'FROM 22X' inside '21X (PROPULSORS)') to extract stereotype properties.
    % - Uses getStereotypeProperties() to target exact FQNs like 'Redundancy.RedundancyScore'.
    % - Returns and exports: SourceComponent, TargetComponent, InterfaceSpecification, CriticalityScore.
    
     % 1. Target open model automatically (Default: SYSTEM)
    if ~isempty(bdroot)
        modelName = bdroot;
    else
        modelName = 'SYSTEM';
    end

    % Ensure model is open
    if ~bdIsLoaded(modelName)
        try
            open_system(modelName);
        catch
            error('Could not open model "%s". Check file name.', modelName);
        end
    end
 
    model = systemcomposer.loadModel(modelName);

    % =================================================================
    % 2. COMPREHENSIVE CONNECTOR SEARCH (STACK CRAWLER + QUERY ENGINE)
    % =================================================================
    rawConnections = {};

    % Crawl the full architecture hierarchy manually to find nested connectors
    archStack = {model.Architecture};
    while ~isempty(archStack)
        currArch = archStack{1};
        archStack(1) = []; % Pop top architecture
 
        if isempty(currArch), continue; end
 
        % Collect connectors from current architecture level
        currConn = currArch.Connectors;
        if ~isempty(currConn)
            if ~iscell(currConn)
                currConn = num2cell(currConn(:));
            end
            rawConnections = [rawConnections; currConn(:)]; %#ok<AGROW>
        end
 
        % Push child component architectures onto stack
        comps = currArch.Components;
        for cIdx = 1:numel(comps)
            try
                if ~isempty(comps(cIdx).Architecture)
                    archStack{end+1} = comps(cIdx).Architecture; %#ok<AGROW>
                end
            catch
            end
        end
    end

    % Supplement with System Composer query engine if available
    try
        import systemcomposer.query.*
        [~, rawConnList] = find(model, IsConnector, Recurse=true, IncludeReferenceModels=true, ElementType="Connector");
        if ~isempty(rawConnList)
            if ~iscell(rawConnList)
                rawConnList = num2cell(rawConnList);
            end
            rawConnections = [rawConnections; rawConnList(:)]; %#ok<AGROW>
        end
    catch
    end

    % Unique connectors list by handle/object identity
    if ~isempty(rawConnections)
        rawConnections = rawConnections(~cellfun(@isempty, rawConnections));
    end

    numConn = numel(rawConnections);

    if numConn == 0
        fprintf('No connections found in model "%s".\n', modelName);
        reportTable = table();
    return;
    end

    % Preallocate storage
    sourceComp = {};
    targetComp = {};
    interfaceName = {};
    redundancyScore = {};

    % =================================================================
    % 3. LOOP THROUGH EVERY DISCOVERED CONNECTION
    % =================================================================
    for idx = 1:numConn
        if iscell(rawConnections)
            conn = rawConnections{idx};
        else
            conn = rawConnections(idx);
        end

        % Extract starting ports
        srcPortWrapper = [];
        tgtPortWrapper = [];

        if isprop(conn, 'SourcePort') && ~isempty(conn.SourcePort) && ...
            isprop(conn, 'DestinationPort') && ~isempty(conn.DestinationPort)
            srcPortWrapper = conn.SourcePort;
            tgtPortWrapper = conn.DestinationPort;
        elseif isprop(conn, 'Ports') && numel(conn.Ports) >= 2
            srcPortWrapper = conn.Ports(1);
            tgtPortWrapper = conn.Ports(2);
        end

        if isempty(srcPortWrapper) || isempty(tgtPortWrapper)
            continue;
        end

        % =================================================================
        % 4. TRACE CONNECTORS FORWARD & BACKWARD ACROSS BOUNDARIES & VARIANTS
        % =================================================================
 
        % Trace SOURCE port backwards to true leaf component
        actualSrcPort = srcPortWrapper;
        visitedSrc = {actualSrcPort};
        while ~isempty(actualSrcPort)
            pObj = [];
            if isprop(actualSrcPort, 'Parent') && ~isempty(actualSrcPort.Parent)
                pObj = actualSrcPort.Parent;
            end
 
            isVarComp = false;
            if ~isempty(pObj)
                if isa(pObj, 'systemcomposer.arch.VariantComponent') || ...
                    (isprop(pObj, 'IsVariant') && pObj.IsVariant) || ...
                        ismethod(pObj, 'getActiveChoice')
                    isVarComp = true;
                end
            end
 
            % Stop if pObj is a leaf component (and NOT a variant shell)
            isLeafComp = false;
            if ~isempty(pObj) && isa(pObj, 'systemcomposer.arch.Component') && ~isVarComp
                try
                    if isempty(pObj.Architecture) || isempty(pObj.Architecture.Components)
                        isLeafComp = true;
                    end
                catch
                    isLeafComp = true;
                end
            end
 
            if isLeafComp
                break;
            end

            nextPort = [];
 
            % Step IN to Variant Component active choice architecture/ports
            if isVarComp
                try
                    candidates = getActiveVariantPorts(actualSrcPort, pObj);
                    for candIdx = 1:numel(candidates)
                        cPort = candidates{candIdx};
                        if ~any(cellfun(@(x) x == cPort, visitedSrc))
                            nextPort = cPort;
                            break;
                        end
                    end
                catch
                end
            end

            % Step OUT of ArchitecturePort
            if isempty(nextPort) && isprop(actualSrcPort, 'ArchitecturePort') && ~isempty(actualSrcPort.ArchitecturePort)
                archP = actualSrcPort.ArchitecturePort;
                if ~any(cellfun(@(x) x == archP, visitedSrc))
                    nextPort = archP;
                end
            end

            % Step along connected Connectors
            if isempty(nextPort) && isprop(actualSrcPort, 'Connectors') && ~isempty(actualSrcPort.Connectors)
                pConns = actualSrcPort.Connectors;
                for cI = 1:numel(pConns)
                    cObj = pConns(cI);
                    candidate = [];
                    if isprop(cObj, 'SourcePort') && ~isempty(cObj.SourcePort) && cObj.SourcePort ~= actualSrcPort
                        candidate = cObj.SourcePort;
                    elseif isprop(cObj, 'DestinationPort') && ~isempty(cObj.DestinationPort) && cObj.DestinationPort ~= actualSrcPort
                        candidate = cObj.DestinationPort;
                    elseif isprop(cObj, 'Ports') && numel(cObj.Ports) >= 2
                        if cObj.Ports(1) ~= actualSrcPort
                            candidate = cObj.Ports(1);
                        elseif cObj.Ports(2) ~= actualSrcPort
                            candidate = cObj.Ports(2);
                        end
                    end
                    if ~isempty(candidate) && ~any(cellfun(@(x) x == candidate, visitedSrc))
                        nextPort = candidate;
                        break;
                    end
                end
            end

            if isempty(nextPort), break; end
            actualSrcPort = nextPort;
            visitedSrc{end+1} = actualSrcPort; %#ok<AGROW>
        end

        % Trace TARGET port forwards to true leaf component
        actualTgtPort = tgtPortWrapper;
        visitedTgt = {actualTgtPort};
        while ~isempty(actualTgtPort)
            pObj = [];
            if isprop(actualTgtPort, 'Parent') && ~isempty(actualTgtPort.Parent)
                pObj = actualTgtPort.Parent;
            end
 
            isVarComp = false;
            if ~isempty(pObj)
                if isa(pObj, 'systemcomposer.arch.VariantComponent') || ...
                   (isprop(pObj, 'IsVariant') && pObj.IsVariant) || ...
                    ismethod(pObj, 'getActiveChoice')
                    isVarComp = true;
                end
            end
 
            % Stop if pObj is a leaf component (and NOT a variant shell)
            isLeafComp = false;
            if ~isempty(pObj) && isa(pObj, 'systemcomposer.arch.Component') && ~isVarComp
                try
                    if isempty(pObj.Architecture) || isempty(pObj.Architecture.Components)
                        isLeafComp = true;
                    end
                catch
                    isLeafComp = true;
                end
            end
 
            if isLeafComp
                break;
            end

            nextPort = [];
 
            % Step IN to Variant Component active choice architecture/ports
            if isVarComp
                try
                    candidates = getActiveVariantPorts(actualTgtPort, pObj);
                    for candIdx = 1:numel(candidates)
                        cPort = candidates{candIdx};
                        if ~any(cellfun(@(x) x == cPort, visitedTgt))
                            nextPort = cPort;
                            break;
                        end
                     end
                catch
                end
            end

            % Step OUT of ArchitecturePort
            if isempty(nextPort) && isprop(actualTgtPort, 'ArchitecturePort') && ~isempty(actualTgtPort.ArchitecturePort)
                archP = actualTgtPort.ArchitecturePort;
                if ~any(cellfun(@(x) x == archP, visitedTgt))
                    nextPort = archP;
                end
            end
            % Step along connected Connectors
            if isempty(nextPort) && isprop(actualTgtPort, 'Connectors') && ~isempty(actualTgtPort.Connectors)
                pConns = actualTgtPort.Connectors;
                for cI = 1:numel(pConns)
                    cObj = pConns(cI);
                    candidate = [];
                    if isprop(cObj, 'DestinationPort') && ~isempty(cObj.DestinationPort) && cObj.DestinationPort ~= actualTgtPort
                        candidate = cObj.DestinationPort;
                    elseif isprop(cObj, 'SourcePort') && ~isempty(cObj.SourcePort) && cObj.SourcePort ~= actualTgtPort
                        candidate = cObj.SourcePort;
                    elseif isprop(cObj, 'Ports') && numel(cObj.Ports) >= 2
                        if cObj.Ports(1) ~= actualTgtPort
                            candidate = cObj.Ports(1);
                        elseif cObj.Ports(2) ~= actualTgtPort
                            candidate = cObj.Ports(2);
                        end
                    end
                    if ~isempty(candidate) && ~any(cellfun(@(x) x == candidate, visitedTgt))
                        nextPort = candidate;
                        break;
                    end
                end
            end

            if isempty(nextPort), break; end
            actualTgtPort = nextPort;
            visitedTgt{end+1} = actualTgtPort; %#ok<AGROW>
        end

        srcCompObj = [];
        if ~isempty(actualSrcPort) && isprop(actualSrcPort, 'Parent')
            srcCompObj = actualSrcPort.Parent;
        end
        tgtCompObj = [];
        if ~isempty(actualTgtPort) && isprop(actualTgtPort, 'Parent')
            tgtCompObj = actualTgtPort.Parent;
        end
        if isempty(srcCompObj) || isempty(tgtCompObj)
            continue;
        end

        ultimateSrcComp = char(srcCompObj.Name);
        ultimateTgtComp = char(tgtCompObj.Name);
        if strcmp(ultimateSrcComp, ultimateTgtComp)
            continue;
        end
        % =================================================================
        % 5. PATH-WIDE SCAN FOR VALID INTERFACE & REDUNDANCY SCORE
        % =================================================================
        allVisitedPorts = [visitedSrc, visitedTgt];
        % 5A. EXTRACT INTERFACE NAME (PORTS ONLY)
        intNameStr = '';
        for vIdx = 1:numel(allVisitedPorts)
            p = allVisitedPorts{vIdx};
            if isempty(p), continue; end
            intNameStr = extractValidInterfaceName(p);
            if ~isempty(intNameStr), break; end
        end
        if isempty(intNameStr)
           intNameStr = 'Unassigned';
        else
           intNameStr = regexprep(intNameStr, '(_[PS])$', '', 'ignorecase');
        end
        % 5B. EXTRACT REDUNDANCY / CRITICALITY SCORE ACROSS ALL CANDIDATES
        candidateElements = {};
        % 1. Add all visited Ports & Architecture Ports
        for vIdx = 1:numel(allVisitedPorts)
            p = allVisitedPorts{vIdx};
            if ~isempty(p)
                candidateElements{end+1} = p; %#ok<AGROW>
                if isprop(p, 'ArchitecturePort') && ~isempty(p.ArchitecturePort)
                    candidateElements{end+1} = p.ArchitecturePort; %#ok<AGROW>
                end
            end
        end

        % 2. Parent Components & Parent Architecture Ports of visited ports
        for vIdx = 1:numel(allVisitedPorts)
            p = allVisitedPorts{vIdx};
            if ~isempty(p) && isprop(p, 'Parent') && ~isempty(p.Parent)
                candidateElements{end+1} = p.Parent; %#ok<AGROW>
                if isprop(p.Parent, 'Architecture') && ~isempty(p.Parent.Architecture)
                    archObj = p.Parent.Architecture;
                    if isprop(archObj, 'Ports') && ~isempty(archObj.Ports)
                        for apI = 1:numel(archObj.Ports)
                           candidateElements{end+1} = archObj.Ports(apI); %#ok<AGROW>
                        end
                    end
                end
            end
        end

        % 3. Source & Target Component Objects & Ancestors
        if ~isempty(srcCompObj)
            candidateElements{end+1} = srcCompObj;
            candidateElements = [candidateElements, getComponentAncestors(srcCompObj)];
        end
        if ~isempty(tgtCompObj)
            candidateElements{end+1} = tgtCompObj;
            candidateElements = [candidateElements, getComponentAncestors(tgtCompObj)];
        end
        % 4. Deep expansion into active architecture elements of any Variant Components
        expandedCandidates = {};
        for cI = 1:numel(candidateElements)
            elem = candidateElements{cI};
            if isempty(elem), continue; end
            expandedCandidates{end+1} = elem; %#ok<AGROW>
            varComps = findVariantComponentsInElement(elem);
            for vI = 1:numel(varComps)
                vComp = varComps{vI};
                internalElems = deepScanVariantComponent(vComp);
                expandedCandidates = [expandedCandidates, internalElems]; %#ok<AGROW>
            end
        end
    
        scoreStr = extractRedundancyScore(expandedCandidates);
        sourceComp{end+1, 1} = ultimateSrcComp; %#ok<AGROW>
        targetComp{end+1, 1} = ultimateTgtComp; %#ok<AGROW>
        interfaceName{end+1, 1} = intNameStr; %#ok<AGROW>
        redundancyScore{end+1, 1}= scoreStr; %#ok<AGROW>
    end

    % =================================================================
    % 6. PACKAGE TABLE & DEDUPLICATE TRACED PATHS
    % =================================================================
    reportTable = table(sourceComp, targetComp, interfaceName, redundancyScore, ...
        'VariableNames', {'SourceComponent', 'TargetComponent', 'InterfaceSpecification', 'CriticalityScore'});

    if ~isempty(reportTable)
        reportTable = unique(reportTable, 'rows');

        sortNumbers = str2double(regexp(reportTable.InterfaceSpecification, '^\d+', 'match', 'once'));
        sortNumbers(isnan(sortNumbers)) = Inf;
        reportTable.SortKey = sortNumbers;
 
        reportTable = sortrows(reportTable, {'SortKey', 'InterfaceSpecification', 'SourceComponent', 'TargetComponent'});
        reportTable.SortKey = [];
    end

    % =================================================================
    % 7. WRITE OUTPUT TO TEXT FILE
    % =================================================================
    fileName = 'InterfaceReport.txt';
    outputDir = 'Reports';
    filePath = fullfile(outputDir, fileName);
    fileID = fopen(filePath, 'wt');

    if fileID == -1
        error('Could not open file "%s" for writing.', filePath);
    end

    sepLine = repmat('=', 1, 100);
    dashLine = repmat('-', 1, 100);
    headerFormat = '%-38s | %-38s | %-10s | %-6s\n';
    rowFormat = '%-38s | %-38s | %-10s | %-6s\n';

    fprintf(fileID, '%s\n', sepLine);
    fprintf(fileID, ' VESSEL INTERFACE REPORT (NESTED LEAF & VARIANT COMPONENTS) \n');
    fprintf(fileID, '%s\n\n', sepLine);

    fprintf(fileID, headerFormat, 'Source Component', 'Target Component', 'Interface', 'Crit');
    fprintf(fileID, '%s\n', dashLine);

    for i = 1:height(reportTable)
        scomp = string(reportTable.SourceComponent(i));
        tcomp = string(reportTable.TargetComponent(i));
        intFace = string(reportTable.InterfaceSpecification(i));
        crit = string(reportTable.CriticalityScore(i));
        fprintf(fileID, rowFormat, scomp, tcomp, intFace, crit);
    end

    fclose(fileID);
    fprintf('SUCCESS: Found %d leaf-to-leaf active connections. Written to "%s".\n', height(reportTable), fileName);
end

% =================================================================
% HELPER 1: FIND ALL CONNECTED PORTS INSIDE ACTIVE VARIANT CHOICE
% =================================================================
function matchingPorts = getActiveVariantPorts(outerPort, vComp)
    matchingPorts = {};
    if isempty(outerPort) || isempty(vComp), return; end

    portName = '';
    if isprop(outerPort, 'Name') && ~isempty(outerPort.Name)
        portName = char(outerPort.Name);
    end

    % 1. Inspect Active Choice Architecture Ports directly
    if isprop(vComp, 'Architecture') && ~isempty(vComp.Architecture)
        actArch = vComp.Architecture;
        if isprop(actArch, 'Ports') && ~isempty(actArch.Ports)
            for k = 1:numel(actArch.Ports)
                p = actArch.Ports(k);
                if strcmp(char(p.Name), portName)
                    matchingPorts{end+1} = p; %#ok<AGROW>
                end
            end
        end
    end

    % 2. Inspect active choice component ports via getActiveChoice()
    if ismethod(vComp, 'getActiveChoice')
        try
            ac = vComp.getActiveChoice();
            if ~isempty(ac)
                if isprop(ac, 'Ports') && ~isempty(ac.Ports)
                    for k = 1:numel(ac.Ports)
                        p = ac.Ports(k);
                        if strcmp(char(p.Name), portName)
                            matchingPorts{end+1} = p; %#ok<AGROW>
                        end
                    end
                end
                if isprop(ac, 'Architecture') && ~isempty(ac.Architecture) && ...
                    isprop(ac.Architecture, 'Ports') && ~isempty(ac.Architecture.Ports)
                    for k = 1:numel(ac.Architecture.Ports)
                        p = ac.Architecture.Ports(k);
                        if strcmp(char(p.Name), portName)
                            matchingPorts{end+1} = p; %#ok<AGROW>
                        end
                    end
                end
            end
        catch
        end
    end

    % 3. Index matching fallback
    if isempty(matchingPorts) && isprop(vComp, 'Ports') && ~isempty(vComp.Ports) && ...
        isprop(vComp, 'Architecture') && ~isempty(vComp.Architecture) && ...
        isprop(vComp.Architecture, 'Ports') && ~isempty(vComp.Architecture.Ports)
        vPorts = vComp.Ports;
        acPorts = vComp.Architecture.Ports;
        for idx = 1:numel(vPorts)
            if vPorts(idx) == outerPort && idx <= numel(acPorts)
                matchingPorts{end+1} = acPorts(idx); %#ok<AGROW>
            end
        end
    end
end

% =================================================================
% HELPER 2: IDENTIFY VARIANT COMPONENTS FROM AN ELEMENT
% =================================================================
function varComps = findVariantComponentsInElement(elem)
    varComps = {};
    if isempty(elem) || ~isobject(elem), return; end

    vCand = [];
    if isa(elem, 'systemcomposer.arch.VariantComponent') || (isprop(elem, 'IsVariant') && elem.IsVariant)
        vCand = elem;
    elseif isprop(elem, 'Parent') && ~isempty(elem.Parent)
        p = elem.Parent;
        if isa(p, 'systemcomposer.arch.VariantComponent') || (isprop(p, 'IsVariant') && p.IsVariant)
            vCand = p;
        end
    end

    if ~isempty(vCand)
        varComps{end+1} = vCand;
    end
end

% =================================================================
% HELPER 3: DEEP SCAN ACTIVE CHOICE ARCHITECTURE FOR ALL ELEMENTS
% =================================================================
function elems = deepScanVariantComponent(vComp)
    elems = {};
    if isempty(vComp) || ~isobject(vComp), return; end

    % Add Variant Component itself
    elems{end+1} = vComp;

    % 1. Active Choice via getActiveChoice()
    if ismethod(vComp, 'getActiveChoice')
        try
            ac = vComp.getActiveChoice();
            if ~isempty(ac) && isobject(ac)
                elems{end+1} = ac;
                if isprop(ac, 'Ports') && ~isempty(ac.Ports)
                    for k = 1:numel(ac.Ports)
                        elems{end+1} = ac.Ports(k); %#ok<AGROW>
                    end
                end
            end
        catch
        end
    end

    % 2. Active Architecture via vComp.Architecture
    if isprop(vComp, 'Architecture') && ~isempty(vComp.Architecture)
        actArch = vComp.Architecture;
        elems{end+1} = actArch;

        % Add all internal active choice architecture ports (e.g. 'FROM 22X')
        if isprop(actArch, 'Ports') && ~isempty(actArch.Ports)
            subPorts = actArch.Ports;
            for k = 1:numel(subPorts)
                elems{end+1} = subPorts(k); %#ok<AGROW>
            end
        end

        % Add all internal active choice components & their ports
        if isprop(actArch, 'Components') && ~isempty(actArch.Components)
            subComps = actArch.Components;
            for k = 1:numel(subComps)
                sComp = subComps(k);
                elems{end+1} = sComp; %#ok<AGROW>
                if isprop(sComp, 'Ports') && ~isempty(sComp.Ports)
                    for pI = 1:numel(sComp.Ports)
                        elems{end+1} = sComp.Ports(pI); %#ok<AGROW>
                    end
                end
            end
        end

        % Add all internal connectors
        if isprop(actArch, 'Connectors') && ~isempty(actArch.Connectors)
            subConns = actArch.Connectors;
            if ~iscell(subConns), subConns = num2cell(subConns); end
            for k = 1:numel(subConns)
                if ~isempty(subConns{k})
                    elems{end+1} = subConns{k}; %#ok<AGROW>
                end
            end
        end
    end
end

% =================================================================
% HELPER 4: RETRIEVE PARENT COMPONENT ANCESTORS UP TO MODEL ROOT
% =================================================================
function ancestors = getComponentAncestors(comp)
    ancestors = {};
    if isempty(comp) || ~isobject(comp), return; end
 
    curr = comp;
    while ~isempty(curr) && isobject(curr)
        p = [];
        if isprop(curr, 'Parent') && ~isempty(curr.Parent)
            p = curr.Parent;
        elseif isprop(curr, 'Architecture') && ~isempty(curr.Architecture) && ...
            isprop(curr.Architecture, 'Parent') && ~isempty(curr.Architecture.Parent)
            p = curr.Architecture.Parent;
        end

        if isempty(p) || ~isobject(p)
            break;
        end

        if isa(p, 'systemcomposer.arch.Model') || isa(p, 'systemcomposer.Architecture')
            break;
        end

        if any(cellfun(@(x) x == p, ancestors))
            break;
        end

        ancestors{end+1} = p; %#ok<AGROW>
        curr = p;
    end
end

% =================================================================
% HELPER 5: STEREOTYPE PROPERTY EXTRACTION WITH DYNAMIC FQN DETECTOR
% =================================================================
function scoreStr = extractRedundancyScore(candidateElements)
    scoreStr = 'N/A';

    for eIdx = 1:numel(candidateElements)
        elem = candidateElements{eIdx};
        if isempty(elem) || ~isobject(elem), continue; end

        keysToTry = {};

        % 1. DYNAMIC DETECTION: Extract exact property FQNs via getStereotypeProperties()
        if ismethod(elem, 'getStereotypeProperties')
            try
                stProps = elem.getStereotypeProperties();
                if ischar(stProps) || isstring(stProps), stProps = cellstr(stProps); end
                for spI = 1:numel(stProps)
                    pName = char(stProps{spI});
                    if contains(pName, 'Redundancy', 'IgnoreCase', true) || ...
                        contains(pName, 'Criticality', 'IgnoreCase', true) || ...
                        contains(pName, 'Score', 'IgnoreCase', true)
                        keysToTry{end+1} = pName; %#ok<AGROW>
                    end
                end
            catch
            end
        end

        % 2. DYNAMIC DETECTION: Build FQNs from getAppliedStereotypes()
        try
            stList = [];
            if ismethod(elem, 'getAppliedStereotypes')
                stList = elem.getAppliedStereotypes();
            elseif isprop(elem, 'AppliedStereotypes') && ~isempty(elem.AppliedStereotypes)
                stList = elem.AppliedStereotypes;
            end

            if ischar(stList) || isstring(stList), stList = cellstr(stList); end

            for sIdx = 1:numel(stList)
                stName = char(stList{sIdx});
                if isempty(stName), continue; end

                propNames = {'RedundancyScore', 'CriticalityScore', 'Criticality', 'Redundancy', 'Score'};
                for prI = 1:numel(propNames)
                    keysToTry{end+1} = [stName, '.', propNames{prI}]; %#ok<AGROW>
                end
            end
        catch
        end

        % 3. Standard fallback property names
        genericNames = {'RedundancyScore', 'CriticalityScore', 'Criticality', 'Redundancy', 'Score'};
        for gI = 1:numel(genericNames)
            keysToTry{end+1} = genericNames{gI}; %#ok<AGROW>
        end

        keysToTry = unique(keysToTry, 'stable');

        % Query element using discovered property keys
        for kIdx = 1:numel(keysToTry)
            key = keysToTry{kIdx};
            rawVal = [];

            if ismethod(elem, 'getValue')
                try, rawVal = elem.getValue(key); catch; end
            end

            if isempty(rawVal) && ismethod(elem, 'getPropertyValue')
                try, rawVal = elem.getPropertyValue(key); catch; end
            end

            if isempty(rawVal) && ismethod(elem, 'getEvaluatedPropertyValue')
                try, rawVal = elem.getEvaluatedPropertyValue(key); catch; end
            end

            if isempty(rawVal) && ismethod(elem, 'getProperty')
                try, [rawVal, ~] = elem.getProperty(key); catch; end
            end

            % Fallback: Simulink Handle Parameter Direct Query
            if isempty(rawVal) && isprop(elem, 'SimulinkHandle') && ~isempty(elem.SimulinkHandle)
                try
                    sh = elem.SimulinkHandle;
                    if sh > 0
                        shortKey = key;
                        if contains(shortKey, '.')
                            parts = strsplit(shortKey, '.');
                            shortKey = parts{end};
                        end
                        if isparam(sh, shortKey)
                            rawVal = get_param(sh, shortKey);
                        end
                    end
                catch
                end
            end

            if ~isempty(rawVal)
                res = cleanValueString(rawVal);
                if ~isempty(res) && ~strcmpi(res, 'N/A') && ~strcmpi(res, 'empty') && ~strcmpi(res, '[]')
                    scoreStr = res;
                    return;
                end
            end
        end
    end
end

% Helper function to convert property value object to string
function res = cleanValueString(rawVal)
    res = '';
    if isempty(rawVal), return; end
    if isobject(rawVal) || isstruct(rawVal)
        if isprop(rawVal, 'Expression') && ~isempty(rawVal.Expression)
            res = char(string(rawVal.Expression));
        elseif isprop(rawVal, 'Value') && ~isempty(rawVal.Value)
            res = char(string(rawVal.Value));
        elseif isfield(rawVal, 'Value') && ~isempty(rawVal.Value)
            res = char(string(rawVal.Value));
        else
            res = char(string(rawVal));
        end
    else
        res = char(string(rawVal));
    end
    res = strtrim(res);
end

% =================================================================
% HELPER 6: EXTRACT VALID INTERFACE NAME
% =================================================================
function nameStr = extractValidInterfaceName(obj)
    nameStr = '';
    if isempty(obj), return; end

    function n = cleanName(val)
        n = '';
        if isempty(val), return; end
        try
            if (isobject(val) || isstruct(val)) && isprop(val, 'Name') && ~isempty(val.Name)
                n = strtrim(char(val.Name));
            elseif isprop(val, 'Domain') && ~isempty(val.Domain)
                n = strtrim(char(val.Domain));
            elseif ismethod(val, 'Name')
                n = strtrim(char(val.Name()));
            else
                n = strtrim(char(string(val)));
            end
        catch
            n = strtrim(char(string(val)));
        end
 
        if strcmpi(n, 'unassigned') || strcmpi(n, 'empty') || strcmpi(n, '<unassigned>') || ...
            strcmpi(n, 'inherit') || strcmpi(n, 'inherited') || strcmpi(n, '<inherited>') || strcmpi(n, 'auto')
            n = '';
        end
    end

    if ismethod(obj, 'getInterface')
        try
            nameStr = cleanName(obj.getInterface());
        catch
        end
    end

    if isempty(nameStr) && isprop(obj, 'Interface') && ~isempty(obj.Interface)
        nameStr = cleanName(obj.Interface);
    end

    if isempty(nameStr) && isprop(obj, 'PhysicalDomain') && ~isempty(obj.PhysicalDomain)
        nameStr = cleanName(obj.PhysicalDomain);
    end

    if isempty(nameStr) && isprop(obj, 'SpecifiedInterface') && ~isempty(obj.SpecifiedInterface)
        nameStr = cleanName(obj.SpecifiedInterface);
    end

    if isempty(nameStr) && isprop(obj, 'Type') && ~isempty(obj.Type)
        nameStr = cleanName(obj.Type);
    end

    if isempty(nameStr) && isprop(obj, 'ArchitecturePort') && ~isempty(obj.ArchitecturePort)
        archP = obj.ArchitecturePort;
        if isprop(archP, 'Interface') && ~isempty(archP.Interface)
            nameStr = cleanName(archP.Interface);
        end
        if isempty(nameStr) && isprop(archP, 'SpecifiedInterface') && ~isempty(archP.SpecifiedInterface)
            nameStr = cleanName(archP.SpecifiedInterface);
        end
    end
end