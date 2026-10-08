function [snap, fileName] = snapshot(label, opts)
%SNAPSHOT Capture the analysis state of the active configuration for comparison.
%   snap = shipmbse.snapshot() returns a struct with:
%     Label, Created, GitCommit
%     Configuration  table of variant components and their active choice
%     Balance        shipmbse.serviceBalance results
%     Mass           shipmbse.massProperties summary struct
%     MassDetails    per-component weight table
%     EnduranceDays  shipmbse.fuelEndurance limiting endurance
%     EnduranceByFuel
%
%   [snap, fileName] = shipmbse.snapshot(label, Save=true) also saves it to
%   outputs/snapshots/Snapshot_<label>.mat. With no label, the next
%   "Run_NNN" label is used.
%
%   See also changeImpactReport.

arguments
    label (1,1) string = ""
    opts.Save (1,1) logical = false
    opts.Model (1,1) systemcomposer.arch.Model = shipmbse.loadModel()
end

model = opts.Model;
folder = getOutputDir("snapshots");
if label == ""
    existing = dir(fullfile(folder, "Snapshot_Run_*.mat"));
    nums = str2double(regexp(string({existing.name}), "Snapshot_Run_(\d+)\.mat", "tokens", "once"));
    label = sprintf("Run_%03d", max([0, nums(~isnan(nums))]) + 1);
end

snap.Label = label;
snap.Created = datetime("now");
snap.GitCommit = gitCommit(shipmbse.config().RootFolder);
snap.Configuration = variantConfiguration(model.Architecture, string(model.Name));
snap.Balance = shipmbse.serviceBalance(model);
[snap.Mass, snap.MassDetails] = shipmbse.massProperties(Model=model);
warnState = warning("off", "shipmbse:fuelEndurance:NoDemand");
restoreWarn = onCleanup(@() warning(warnState));
[snap.EnduranceDays, snap.EnduranceByFuel] = shipmbse.fuelEndurance(model);

fileName = "";
if opts.Save
    fileName = fullfile(folder, "Snapshot_" + label + ".mat");
    save(fileName, "snap");
    fprintf('Snapshot "%s" saved to "%s".\n', label, fileName);
end

end

function T = variantConfiguration(arch, archPath)
T = table('Size', [0 2], 'VariableTypes', {'string', 'string'}, 'VariableNames', {'Variant', 'ActiveChoice'});
comps = arch.Components;
for k = 1:numel(comps)
    c = comps(k);
    cPath = archPath + "/" + replace(string(c.Name), "/", "//");
    if isa(c, 'systemcomposer.arch.VariantComponent')
        active = c.getActiveChoice();
        choiceName = "<none>";
        if ~isempty(active)
            choiceName = string(active.Name);
        end
        T(end+1, :) = {cPath, choiceName}; %#ok<AGROW>
        if ~isempty(active) && ~isempty(active.Architecture)
            T = [T; variantConfiguration(active.Architecture, cPath + "/" + replace(choiceName, "/", "//"))]; %#ok<AGROW>
        end
    elseif ~isempty(c.Architecture)
        T = [T; variantConfiguration(c.Architecture, cPath)]; %#ok<AGROW>
    end
end
end

function commit = gitCommit(root)
[status, out] = system(sprintf('git -C "%s" rev-parse --short HEAD', root));
commit = "";
if status == 0
    commit = strtrim(string(out));
end
end
