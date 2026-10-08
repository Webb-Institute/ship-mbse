function impact = changeImpactReport(baseline, current)
%CHANGEIMPACTREPORT Compare two analysis snapshots and report what changed.
%   impact = changeImpactReport() compares the two most recent snapshots in
%   outputs/snapshots (saved by runAllReports or shipmbse.snapshot).
%   impact = changeImpactReport(baseline, current) compares the named
%   snapshots, given as labels (e.g. "Run_003") or snapshot structs.
%
%   Writes outputs/reports/Change_Impact_<baseline>_vs_<current>.txt and
%   outputs/figures/Change_Impact_<baseline>_vs_<current>.png, and returns a
%   struct with tables Configuration, Mass, Components, Balance, Endurance.
%
%   See also shipmbse.snapshot, runAllReports.

arguments
    baseline = ""
    current = ""
end

[base, curr] = resolveSnapshots(baseline, current);
tag = base.Label + "_vs_" + curr.Label;

% --- Variant configuration ----------------------------------------------------
cfgT = outerjoin(base.Configuration, curr.Configuration, 'Keys', 'Variant', 'MergeKeys', true);
cfgT.Properties.VariableNames = {'Variant', 'Baseline', 'Current'};
cfgT = cfgT(cfgT.Baseline ~= cfgT.Current | ismissing(cfgT.Baseline) | ismissing(cfgT.Current), :);

% --- Mass totals and per-component weights -------------------------------------
fields = ["Weight", "WeightWithMargin", "LCG", "VCG", "TCG", "LCGWithMargin", "VCGWithMargin", "TCGWithMargin"];
massT = table(fields', arrayfun(@(f) base.Mass.(f), fields)', arrayfun(@(f) curr.Mass.(f), fields)', ...
    'VariableNames', {'Quantity', 'Baseline', 'Current'});
massT.Change = massT.Current - massT.Baseline;
compT = outerjoin(base.MassDetails(:, {'Path', 'Weight'}), curr.MassDetails(:, {'Path', 'Weight'}), ...
    'Keys', 'Path', 'MergeKeys', true);
compT.Properties.VariableNames = {'Path', 'Baseline', 'Current'};
compT.Change = fillmissing(compT.Current, 'constant', 0) - fillmissing(compT.Baseline, 'constant', 0);
compT = compT(compT.Change ~= 0 | xor(isnan(compT.Baseline), isnan(compT.Current)), :);

% --- Service balances -----------------------------------------------------------
balT = table(base.Balance.Domain, base.Balance.Margin, base.Balance.Unit, curr.Balance.Margin, curr.Balance.Unit, ...
    'VariableNames', {'Domain', 'BaselineMargin', 'BaselineUnit', 'CurrentMargin', 'Unit'});
balT.Change = balT.CurrentMargin - balT.BaselineMargin;
balT.Change(balT.BaselineUnit ~= balT.Unit) = NaN;   % units changed: no meaningful difference

% --- Endurance -------------------------------------------------------------------
endT = table(base.EnduranceDays, curr.EnduranceDays, curr.EnduranceDays - base.EnduranceDays, ...
    'VariableNames', {'BaselineDays', 'CurrentDays', 'Change'});

impact = struct('Baseline', base.Label, 'Current', curr.Label, 'Configuration', cfgT, ...
    'Mass', massT, 'Components', compT, 'Balance', balT, 'Endurance', endT);

writeText(impact, base, curr, fullfile(getOutputDir("reports"), "Change_Impact_" + tag + ".txt"));
writeFigure(impact, fullfile(getOutputDir("figures"), "Change_Impact_" + tag + ".png"));

end

% ---------------------------------------------------------------------------
function [base, curr] = resolveSnapshots(baseline, current)
folder = getOutputDir("snapshots");
if isequal(baseline, "") && isequal(current, "")
    files = dir(fullfile(folder, "Snapshot_*.mat"));
    if numel(files) < 2
        error("changeImpactReport:NotEnoughSnapshots", ...
            "Need at least two snapshots in ""%s"" (run runAllReports twice).", folder);
    end
    [~, order] = sort([files.datenum]);
    files = files(order);
    baseline = string(extractBetween(files(end-1).name, "Snapshot_", ".mat"));
    current = string(extractBetween(files(end).name, "Snapshot_", ".mat"));
end
base = loadSnapshot(baseline, folder);
curr = loadSnapshot(current, folder);
end

function s = loadSnapshot(x, folder)
if isstruct(x)
    s = x;
    return
end
file = fullfile(folder, "Snapshot_" + string(x) + ".mat");
if ~isfile(file)
    error("changeImpactReport:NoSnapshot", "Snapshot ""%s"" not found in ""%s"".", x, folder);
end
s = load(file).snap;
end

function writeText(impact, base, curr, fileName)
fid = fopen(fileName, "wt");
if fid == -1
    error("changeImpactReport:CannotWrite", "Could not open ""%s"" for writing.", fileName);
end
closeFile = onCleanup(@() fclose(fid));
line = repmat('=', 1, 100);
fprintf(fid, "%s\nCHANGE IMPACT: %s (%s, %s) -> %s (%s, %s)\n%s\n", line, ...
    base.Label, string(base.Created, "yyyy-MM-dd HH:mm"), base.GitCommit, ...
    curr.Label, string(curr.Created, "yyyy-MM-dd HH:mm"), curr.GitCommit, line);

fprintf(fid, "\n1. VARIANT CONFIGURATION CHANGES (%d)\n", height(impact.Configuration));
for k = 1:height(impact.Configuration)
    fprintf(fid, "  %s: %s -> %s\n", shipmbse.pathLeaf(impact.Configuration.Variant(k)), ...
        impact.Configuration.Baseline(k), impact.Configuration.Current(k));
end

fprintf(fid, "\n2. MASS PROPERTIES\n%-20s | %12s | %12s | %12s\n", "Quantity", "Baseline", "Current", "Change");
for k = 1:height(impact.Mass)
    fprintf(fid, "%-20s | %12.3f | %12.3f | %+12.3f\n", impact.Mass.Quantity(k), impact.Mass.Baseline(k), ...
        impact.Mass.Current(k), impact.Mass.Change(k));
end
fprintf(fid, "\n   Components whose weight changed, appeared or disappeared (%d):\n", height(impact.Components));
for k = 1:height(impact.Components)
    fprintf(fid, "   %-45s %10.2f -> %10.2f t (%+.2f)\n", shipmbse.pathLeaf(impact.Components.Path(k)), ...
        impact.Components.Baseline(k), impact.Components.Current(k), impact.Components.Change(k));
end

fprintf(fid, "\n3. SERVICE BALANCE MARGINS (capacity - demand)\n%-16s | %12s | %12s | %12s | %s\n", ...
    "Domain", "Baseline", "Current", "Change", "Unit");
for k = 1:height(impact.Balance)
    b = impact.Balance(k, :);
    if b.BaselineUnit == b.Unit
        fprintf(fid, "%-16s | %12.6g | %12.6g | %+12.6g | %s\n", b.Domain, b.BaselineMargin, ...
            b.CurrentMargin, b.Change, b.Unit);
    else
        fprintf(fid, "%-16s | %12.6g | %12.6g | %12s | %s -> %s (units changed; not comparable)\n", ...
            b.Domain, b.BaselineMargin, b.CurrentMargin, "-", b.BaselineUnit, b.Unit);
    end
end

fprintf(fid, "\n4. FUEL ENDURANCE\n  %.3f -> %.3f days (%+.3f)\n%s\n", impact.Endurance.BaselineDays, ...
    impact.Endurance.CurrentDays, impact.Endurance.Change, line);
fprintf('Change impact report written to "%s".\n', fileName);
end

function writeFigure(impact, fileName)
fig = figure("Visible", "off");
closeFig = onCleanup(@() close(fig));
tiledlayout(fig, 1, 2);
nexttile;
bar(categorical(impact.Balance.Domain), [impact.Balance.BaselineMargin, impact.Balance.CurrentMargin]);
title("Service margins (capacity - demand)");
legend(impact.Baseline, impact.Current, "Location", "best", "Interpreter", "none");
nexttile;
w = impact.Mass(ismember(impact.Mass.Quantity, ["Weight", "WeightWithMargin"]), :);
bar(categorical(w.Quantity), [w.Baseline, w.Current]);
ylabel("t");
title("Ship weight");
exportgraphics(fig, fileName);
end
