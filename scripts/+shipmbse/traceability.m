function [reqs, comps] = traceability(model)
%TRACEABILITY Requirement allocation and verification coverage.
%   [reqs, comps] = shipmbse.traceability() checks the requirement set and
%   the architecture model named in shipmbse.config in both directions.
%
%   reqs  one row per requirement:
%           Id, Summary, Type, NeedsAllocation, ImplementedBy, VerifiedBy,
%           Implemented, Verified, Unresolved
%         Implemented: has an incoming Implement link from a component in
%         the architecture (the model or a model it references).
%         Verified: has an incoming Verify link (e.g. from a test).
%         NeedsAllocation is false for Container and Informational items.
%         Unresolved counts links to this requirement that do not resolve.
%
%   comps one row per component, covering EVERY variant choice (each design
%         alternative must trace): Path, Requirements, Allocated.
%         A variant choice counts as allocated if it, or its variant
%         container, has an Implement link.
%
%   See also verifyRequirementAllocations, shipmbse.activeComponents.

arguments
    model (1,1) systemcomposer.arch.Model = shipmbse.loadModel()
end

cfg = shipmbse.config();
reqSet = slreq.load(cfg.RequirementSet);
% Load every link set in the repository (model and test links)
linkFiles = dir(fullfile(cfg.RootFolder, "**", "*.slmx"));
for k = 1:numel(linkFiles)
    slreq.load(fullfile(linkFiles(k).folder, linkFiles(k).name));
end
archModels = string(find_mdlrefs(model.Name, 'MatchFilter', @Simulink.match.allVariants));

% --- Requirements -> architecture / tests ---------------------------------
allReqs = reqSet.find('Type', 'Requirement');
n = numel(allReqs);
id = strings(n, 1); summary = strings(n, 1); type = strings(n, 1);
implBy = strings(n, 1); verBy = strings(n, 1); unresolved = zeros(n, 1);
for k = 1:n
    r = allReqs(k);
    id(k) = string(r.Id); summary(k) = string(r.Summary); type(k) = string(r.Type);
    in = slreq.inLinks(r);
    impl = strings(0); ver = strings(0);
    for L = 1:numel(in)
        lk = in(L);
        if ~lk.isResolvedSource
            unresolved(k) = unresolved(k) + 1;
            continue
        end
        src = lk.source;
        [~, srcName] = fileparts(string(src.artifact));
        if lk.Type == "Implement" && ismember(srcName, archModels)
            impl(end+1) = blockName(src); %#ok<AGROW>
        elseif lk.Type == "Verify"
            ver(end+1) = srcName; %#ok<AGROW>
        end
    end
    implBy(k) = strjoin(unique(impl), "; ");
    verBy(k) = strjoin(unique(ver), "; ");
end
needs = ~ismember(type, ["Container", "Informational"]);
reqs = table(id, summary, type, needs, implBy, verBy, implBy ~= "", verBy ~= "", unresolved, ...
    'VariableNames', {'Id', 'Summary', 'Type', 'NeedsAllocation', 'ImplementedBy', 'VerifiedBy', ...
                      'Implemented', 'Verified', 'Unresolved'});

% --- Architecture -> requirements -----------------------------------------
[cs, paths] = shipmbse.activeComponents(model, AllVariantChoices=true);
m = numel(cs);
reqsOf = strings(m, 1);
for k = 1:m
    ids = implementedIds(cs(k).SimulinkHandle);
    [~, parentPath] = shipmbse.pathLeaf(paths(k));
    if contains(parentPath, "/") && isVariantBlock(parentPath)
        ids = [ids, implementedIds(get_param(parentPath, 'Handle'))]; %#ok<AGROW>
    end
    reqsOf(k) = strjoin(unique(ids), "; ");
end
comps = table(paths, reqsOf, reqsOf ~= "", 'VariableNames', {'Path', 'Requirements', 'Allocated'});

end

function ids = implementedIds(handle)
ids = strings(1, 0);
out = slreq.outLinks(handle);
for L = 1:numel(out)
    if out(L).Type == "Implement" && out(L).isResolvedDestination
        ids(end+1) = string(out(L).destination.id); %#ok<AGROW>
    end
end
end

function tf = isVariantBlock(blockPath)
try
    tf = strcmp(get_param(blockPath, 'Variant'), 'on');
catch
    tf = false;   % not a block (e.g. the model root)
end
end

function name = blockName(src)
name = string(src.artifact);
try
    [~, mdl] = fileparts(name);
    name = string(get_param(Simulink.ID.getHandle(mdl + string(src.id)), 'Name'));
    name = replace(name, newline, " ");
catch
    % keep the artifact name if the block cannot be resolved
end
end
