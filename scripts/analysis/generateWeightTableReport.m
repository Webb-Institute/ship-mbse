function weightTable = generateWeightTableReport(cmd)
%GENERATEWEIGHTTABLEREPORT Weight, margin and centre-of-gravity report.
%   weightTable = generateWeightTableReport() writes
%   outputs/reports/WeightsAndMarginsReport_Run_NNN.txt listing every active
%   component with the WeightsCenters stereotype (weight, margin, weight with
%   margin, LCG, TCG, VCG), followed by ship totals with and without margin.
%   Returns the component table.
%
%   generateWeightTableReport("clear") deletes previous runs.
%
%   Table rows and both sets of totals come from the same component set
%   (shipmbse.massProperties). This report does not modify the model.
%
%   See also shipmbse.massProperties, calcShipDisp_CoG, marginCalcShipDisp_CoG.

arguments
    cmd (1,1) string {mustBeMember(cmd, ["", "clear", "reset"])} = ""
end

prefix = "WeightsAndMarginsReport";
if cmd ~= ""
    shipmbse.reportFile(prefix, cmd);
    weightTable = table();
    return
end

[mp, details] = shipmbse.massProperties();
details = shipmbse.sortByModelId(details);
names = shipmbse.pathLeaf(details.Path);
weightTable = table(names, details.Weight, details.MarginPct, details.WeightWithMargin, ...
    details.LCG, details.TCG, details.VCG, ...
    'VariableNames', {'ComponentName', 'BaseWeight_t', 'Margin_pct', 'TotalWeight_t', 'LCG_m', 'TCG_m', 'VCG_m'});

fileName = shipmbse.reportFile(prefix);
fid = fopen(fileName, "wt");
if fid == -1
    error("generateWeightTableReport:CannotWrite", "Could not open ""%s"" for writing.", fileName);
end
closeFile = onCleanup(@() fclose(fid));

width = 110;
fprintf(fid, "%s\n%s\n%s\n", repmat('=', 1, width), ...
    blanks(34) + "VESSEL WEIGHT & CENTER OF GRAVITY REPORT", repmat('=', 1, width));
fprintf(fid, "Model: %s   Generated: %s   Active components with weight data: %d\n\n", ...
    shipmbse.config().ModelName, string(datetime("now", "Format", "yyyy-MM-dd HH:mm")), mp.NumComponents);
[~, maturity] = shipmbse.dataMaturity();
fprintf(fid, "%s\n\n", maturity);

fprintf(fid, "%-40s | %10s | %10s | %10s | %8s | %8s | %8s\n", ...
    "Component Name", "Weight (t)", "Margin (%)", "Total (t)", "LCG (m)", "TCG (m)", "VCG (m)");
fprintf(fid, "%s\n", repmat('-', 1, width));
for k = 1:height(weightTable)
    fprintf(fid, "%-40s | %10.2f | %10.2f | %10.2f | %8.2f | %8.2f | %8.2f\n", ...
        weightTable.ComponentName(k), weightTable.BaseWeight_t(k), weightTable.Margin_pct(k), ...
        weightTable.TotalWeight_t(k), weightTable.LCG_m(k), weightTable.TCG_m(k), weightTable.VCG_m(k));
end

fprintf(fid, "%s\n\n%s\n", repmat('=', 1, width), blanks(42) + "TOTAL SHIP SUMMARY");
fprintf(fid, "%s\n", repmat('-', 1, width));
fprintf(fid, "%-24s | %14s | %14s\n", "", "With margin", "Without margin");
fprintf(fid, "%-24s | %14.2f | %14.2f\n", "Weight (t)", mp.WeightWithMargin, mp.Weight);
fprintf(fid, "%-24s | %14.3f | %14.3f\n", "LCG - longitudinal (m)", mp.LCGWithMargin, mp.LCG);
fprintf(fid, "%-24s | %14.3f | %14.3f\n", "TCG - transverse (m)", mp.TCGWithMargin, mp.TCG);
fprintf(fid, "%-24s | %14.3f | %14.3f\n", "VCG - vertical (m)", mp.VCGWithMargin, mp.VCG);
if mp.WeightWithCenters < mp.Weight
    fprintf(fid, "\nNOTE: %.2f t of %.2f t has incomplete centre data and is excluded from the CoG.\n", ...
        mp.Weight - mp.WeightWithCenters, mp.Weight);
end
fprintf(fid, "%s\n", repmat('=', 1, width));

fprintf('Weight report written to "%s".\n', fileName);

end
