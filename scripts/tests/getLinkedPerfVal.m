function perfVal = getLinkedPerfVal(testFileName, attrName)
    perfVal = NaN;

    % Get full file path
    testFile = which(testFileName);
    if isempty(testFile)
        testFile = testFileName;
    end

    % Temporarily suppress harmless slreq link-type lookup warnings
    warnState = warning('off', 'all');
    cleanupWarn = onCleanup(@() warning(warnState));

    % 1. Auto-load requirement sets (.slreqx) and link sets (.slmx)
    reqFiles = dir('*.slreqx');
    for f = 1:length(reqFiles)
        try slreq.load(reqFiles(f).name); catch; end
    end

    linkFiles = dir('*.slmx');
    for f = 1:length(linkFiles)
        try slreq.load(linkFiles(f).name); catch; end
    end
    
    % 2. Retrieve incoming/outgoing links connected to this test file
    links = [];
    try links = [slreq.outLinks(testFile); slreq.inLinks(testFile)]; catch; end

    % Fallback: search global links if file-specific search returned empty
    if isempty(links)
        try
            allLinks = slreq.find('Type', 'Link');
            [~, bName, ext] = fileparts(testFile);
            fWithExt = [bName, ext];

            for k = 1:length(allLinks)
                lk = allLinks(k);
                sInfo = source(lk); dInfo = destination(lk);
                sArt = ''; dArt = '';
                if isstruct(sInfo) && isfield(sInfo, 'artifact'), sArt = char(sInfo.artifact); end
                if isstruct(dInfo) && isfield(dInfo, 'artifact'), dArt = char(dInfo.artifact); end

                if contains(sArt, fWithExt) || contains(dArt, fWithExt) || ...
                        contains(sArt, bName)    || contains(dArt, bName)
                    links = [links; lk]; %#ok<AGROW>
                end
            end
        catch; end
    end

    % 3. Extract PerfVal1 from link or destination requirement
    for k = 1:length(links)
        lk = links(k);
        rawVal = [];

        % Check link custom attribute
        try rawVal = lk.getAttribute(attrName); catch; end

        % Check requirement object attribute
        if isempty(rawVal)
            reqObj = [];
            try
                dObj = destination(lk);
                if isstruct(dObj), dObj = slreq.structToObj(dObj); end
                if isa(dObj, 'slreq.Requirement') || isa(dObj, 'slreq.Reference'), reqObj = dObj; end
            catch; end

            if isempty(reqObj)
                try
                    sObj = source(lk);
                    if isstruct(sObj), sObj = slreq.structToObj(sObj); end
                    if isa(sObj, 'slreq.Requirement') || isa(sObj, 'slreq.Reference'), reqObj = sObj; end
                catch; end
            end

            if ~isempty(reqObj)
                try rawVal = reqObj.getAttribute(attrName); catch; end
                if isempty(rawVal)
                    try rawVal = reqObj.(attrName); catch; end
                end
            end
        end

        % Parse numeric value
        if ~isempty(rawVal)
            if isnumeric(rawVal) || islogical(rawVal)
                perfVal = double(rawVal(1));
            elseif ischar(rawVal) || isstring(rawVal)
                matchStr = regexp(char(string(rawVal)), '[-+]?\d*\.?\d+', 'match', 'once');
                if ~isempty(matchStr)
                    perfVal = str2double(matchStr);
                end
            end

            if ~isnan(perfVal)
                return; % Found valid threshold value
            end
        end
    end
end