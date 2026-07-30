function applyPortProp()
    % System Composer Profile and Interface Assignment Script
    modelName = 'SYSTEM';

    if ~bdIsLoaded(modelName)
        open_system(modelName);
    end

    modelObj = systemcomposer.loadModel(modelName);

    % 1. Ensure Profile is attached safely
    try
        isProfileAttached = false;
        if isprop(modelObj, 'Profiles') && ~isempty(modelObj.Profiles)
            isProfileAttached = any(strcmp({modelObj.Profiles.Name}, 'PortProfile'));
        end
        
        if ~isProfileAttached
            modelObj.applyProfile('PortProfile');
            fprintf('Applied profile "PortProfile" to model "%s".\n', modelName);
        end
    catch err
        warning('Could not attach profile "PortProfile": %s', err.message);
    end

    % Profile, Stereotype, and Property Definitions
    currentProfile        = 'PortProfile';
    currentStereotype     = 'Redundancy';
    currentProperty       = 'RedundancyScore';
    currentStereotypePath = [currentProfile, '.', currentStereotype];
    currentPropertyPath   = [currentProfile, '.', currentStereotype, '.', currentProperty];
    propValue             = 1;

    % Fetch Interface Dictionary handle safely
    dictObj = [];
    try
        if isprop(modelObj, 'InterfaceDictionary') && ~isempty(modelObj.InterfaceDictionary)
            dictObj = modelObj.InterfaceDictionary;
        elseif ismethod(modelObj, 'getInterfaceDictionary')
            dictObj = modelObj.getInterfaceDictionary();
        end
    catch err
        warning('Could not retrieve Interface Dictionary: %s', err.message);
    end

    % 2. Collect ALL ports recursively using an iterative queue (no subfunctions)
    allPorts = {};
    if isprop(modelObj, 'Architecture')
        rootArch = modelObj.Architecture;
    else
        rootArch = modelObj;
    end

    if ~isempty(rootArch) && isprop(rootArch, 'Ports')
        for i = 1:numel(rootArch.Ports)
            allPorts{end+1} = rootArch.Ports(i); %#ok<AGROW>
        end
    end

    compQueue = {};
    if ~isempty(rootArch) && isprop(rootArch, 'Components')
        for i = 1:numel(rootArch.Components)
            compQueue{end+1} = rootArch.Components(i); %#ok<AGROW>
        end
    end

    while ~isempty(compQueue)
        c = compQueue{1};
        compQueue(1) = [];

        if isprop(c, 'Ports')
            for p = 1:numel(c.Ports)
                allPorts{end+1} = c.Ports(p); %#ok<AGROW>
            end
        end

        if isprop(c, 'Architecture') && ~isempty(c.Architecture)
            arch = c.Architecture;
            if isprop(arch, 'Ports')
                for p = 1:numel(arch.Ports)
                    allPorts{end+1} = arch.Ports(p); %#ok<AGROW>
                end
            end
            if isprop(arch, 'Components')
                for sub = 1:numel(arch.Components)
                    compQueue{end+1} = arch.Components(sub); %#ok<AGROW>
                end
            end
        end

        if isprop(c, 'Choices') && ~isempty(c.Choices)
            for v = 1:numel(c.Choices)
                choiceArch = c.Choices(v).Architecture;
                if ~isempty(choiceArch)
                    if isprop(choiceArch, 'Ports')
                        for p = 1:numel(choiceArch.Ports)
                            allPorts{end+1} = choiceArch.Ports(p); %#ok<AGROW>
                        end
                    end
                    if isprop(choiceArch, 'Components')
                        for sub = 1:numel(choiceArch.Components)
                            compQueue{end+1} = choiceArch.Components(sub); %#ok<AGROW>
                        end
                    end
                end
            end
        end
    end

    fprintf('Found %d total ports to process.\n', numel(allPorts));

    assignedCount = 0;
    failedCount   = 0;

    % 3. First Pass: Determine and assign interfaces individually
    for k = 1:numel(allPorts)
        targetPort = allPorts{k};
        
        if isempty(targetPort) || ~isvalid(targetPort)
            continue;
        end

        pName = strtrim(char(targetPort.Name));
        
        portDir = '';
        if isprop(targetPort, 'Direction')
            portDir = char(targetPort.Direction);
        end

        % Check explicit physical or signal suffix at end of name
        hasExplicitP = endsWith(pName, '_P', 'IgnoreCase', true);
        hasExplicitS = endsWith(pName, '_S', 'IgnoreCase', true);

        % Strip trailing _P or _S to reveal base alphabetic designation
        baseName = pName;
        if hasExplicitP || hasExplicitS
            baseName = pName(1:end-2);
        end
        baseName = strtrim(baseName);

        isPhysicalPort = strcmpi(portDir, 'Physical') || ...
                         isa(targetPort, 'systemcomposer.arch.PhysicalPort') || ...
                         (isprop(targetPort, 'IsPhysical') && targetPort.IsPhysical) || ...
                         hasExplicitP;

        if hasExplicitS
            isPhysicalPort = false;
        end

        baseInterface = "";

        % Alphabetic Designation Matching
        if endsWith(baseName, 'CFW', 'IgnoreCase', true)
            baseInterface = "CoolingFW";

        elseif endsWith(baseName, 'CA', 'IgnoreCase', true)
            baseInterface = "CompAir";

        elseif endsWith(baseName, 'FO', 'IgnoreCase', true)
            baseInterface = "FuelOil";

        elseif endsWith(baseName, 'LO', 'IgnoreCase', true)
            baseInterface = "LubeOil";

        elseif endsWith(baseName, 'SW', 'IgnoreCase', true)
            baseInterface = "SaltWater";

        elseif endsWith(baseName, 'WG', 'IgnoreCase', true)
            baseInterface = "WasteGas";

        elseif endsWith(baseName, 'WW', 'IgnoreCase', true)
            baseInterface = "WasteWater";

        elseif endsWith(baseName, 'WS', 'IgnoreCase', true)
            baseInterface = "WasteSolid";

        elseif endsWith(baseName, 'WO', 'IgnoreCase', true)
            baseInterface = "WasteOil";

        elseif endsWith(baseName, 'HP', 'IgnoreCase', true)
            baseInterface = "Heat";

        elseif endsWith(baseName, 'C', 'IgnoreCase', true)
            baseInterface = "Control";

        elseif endsWith(baseName, 'P', 'IgnoreCase', true)
            baseInterface = "Power";

        elseif endsWith(baseName, 'X', 'IgnoreCase', true)
            baseInterface = "Physical";
            isPhysicalPort = true;

        else
            if isPhysicalPort
                baseInterface = "Physical";
            else
                baseInterface = "Control";
            end
        end

        % Domain Suffixing (_P or _S) except for Physical / 'X' ports
        if baseInterface == "Physical" || endsWith(pName, 'X', 'IgnoreCase', true)
            assignedInterface = "Physical";
            isPhysicalPort = true;
        elseif isPhysicalPort
            if ~endsWith(baseInterface, "_P")
                assignedInterface = baseInterface + "_P";
            else
                assignedInterface = baseInterface;
            end
        else
            if ~endsWith(baseInterface, "_S")
                assignedInterface = baseInterface + "_S";
            else
                assignedInterface = baseInterface;
            end
        end

        if assignedInterface == ""
            continue;
        end

        ifName = char(assignedInterface);

        % Ensure Interface Exists in Interface Dictionary
        if ~isempty(dictObj)
            try
                dictObj.getInterface(ifName);
            catch
                try
                    if isPhysicalPort || strcmp(ifName, 'Physical')
                        dictObj.addPhysicalInterface(ifName);
                        fprintf('Created missing PhysicalInterface "%s" in dictionary.\n', ifName);
                    else
                        dictObj.addInterface(ifName);
                        fprintf('Created missing DataInterface "%s" in dictionary.\n', ifName);
                    end
                catch err
                    warning('Could not create interface "%s": %s', ifName, err.message);
                end
            end
        end

        % Disable InheritsInterface so assignment is forcibly applied
        if isprop(targetPort, 'InheritsInterface')
            try
                targetPort.InheritsInterface = false;
            catch
            end
        end

        % Assign Interface safely
        try
            targetPort.setInterface(ifName);
            assignedCount = assignedCount + 1;
        catch
            try
                ifaceObj = dictObj.getInterface(ifName);
                targetPort.setInterface(ifaceObj);
                assignedCount = assignedCount + 1;
            catch err2
                failedCount = failedCount + 1;
                warning('Failed to assign interface "%s" to port "%s": %s', ifName, pName, err2.message);
            end
        end

        % Apply Stereotype and Property
        try
            if ~targetPort.hasStereotype(currentStereotypePath)
                targetPort.applyStereotype(currentStereotypePath);
            end
        catch
        end

        try
            targetPort.setProperty(currentPropertyPath, propValue);
        catch
            try
                targetPort.setProperty(currentPropertyPath, num2str(propValue));
            catch
            end
        end
    end

    % 4. Second Pass: Synchronize interfaces across connectors iteratively
    if ~isempty(dictObj)
        fprintf('Synchronizing connector endpoints...\n');

        archQueue = {};
        if isprop(modelObj, 'Architecture') && ~isempty(modelObj.Architecture)
            archQueue{end+1} = modelObj.Architecture; %#ok<AGROW>
        end

        while ~isempty(archQueue)
            archObj = archQueue{1};
            archQueue(1) = [];

            if isempty(archObj)
                continue;
            end

            % Process connectors in current architecture
            if isprop(archObj, 'Connectors')
                conns = archObj.Connectors;
                for c = 1:numel(conns)
                    conn = conns(c);
                    p1 = [];
                    p2 = [];

                    if isprop(conn, 'SourcePort') && isprop(conn, 'DestinationPort')
                        p1 = conn.SourcePort;
                        p2 = conn.DestinationPort;
                    elseif isprop(conn, 'Ports') && numel(conn.Ports) >= 2
                        p1 = conn.Ports(1);
                        p2 = conn.Ports(2);
                    end

                    if isempty(p1) || isempty(p2), continue; end

                    % Extract interface names
                    if1 = "";
                    try
                        if isprop(p1, 'Interface') && ~isempty(p1.Interface)
                            if1 = string(p1.Interface.Name);
                        end
                    catch
                    end

                    if2 = "";
                    try
                        if isprop(p2, 'Interface') && ~isempty(p2.Interface)
                            if2 = string(p2.Interface.Name);
                        end
                    catch
                    end

                    % Sync endpoint interface mismatches
                    targetSyncPort = [];
                    syncIfName = "";

                    if if1 ~= "" && (if2 == "" || ~strcmp(if1, if2))
                        targetSyncPort = p2;
                        syncIfName = if1;
                    elseif if2 ~= "" && (if1 == "" || ~strcmp(if1, if2))
                        targetSyncPort = p1;
                        syncIfName = if2;
                    end

                    if ~isempty(targetSyncPort)
                        try
                            if isprop(targetSyncPort, 'InheritsInterface')
                                targetSyncPort.InheritsInterface = false;
                            end
                            targetSyncPort.setInterface(char(syncIfName));
                        catch
                            try
                                ifaceObj = dictObj.getInterface(char(syncIfName));
                                targetSyncPort.setInterface(ifaceObj);
                            catch
                            end
                        end
                    end
                end
            end

            % Queue child architectures
            if isprop(archObj, 'Components')
                comps = archObj.Components;
                for i = 1:numel(comps)
                    comp = comps(i);
                    if isprop(comp, 'Architecture') && ~isempty(comp.Architecture)
                        archQueue{end+1} = comp.Architecture; %#ok<AGROW>
                    end
                    if isprop(comp, 'Choices') && ~isempty(comp.Choices)
                        choices = comp.Choices;
                        for v = 1:numel(choices)
                            if ~isempty(choices(v).Architecture)
                                archQueue{end+1} = choices(v).Architecture; %#ok<AGROW>
                            end
                        end
                    end
                end
            end
        end
    end

    % 5. Save changes
    try
        if ~isempty(dictObj) && ismethod(dictObj, 'save')
            dictObj.save();
        end
        save_system(modelName);
        fprintf('Model "%s" saved successfully.\n', modelName);
    catch err
        warning('Could not save model: %s', err.message);
    end

    fprintf('=== COMPLETE: Processed %d ports (%d assigned, %d failed) ===\n', ...
        numel(allPorts), assignedCount, failedCount);
end