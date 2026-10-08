function results = systemsReport(cmd)
%SYSTEMSREPORT Demand versus capacity for each ship service domain.
%   results = systemsReport() writes outputs/reports/SystemsReport_Run_NNN.txt
%   with, for each domain (electrical, fuel, lube, cooling, compressed air,
%   heat, and each waste stream), the demand and capacity components in the
%   active configuration with value, unit and status, the totals of
%   components that are on, and the margin (capacity - demand). Returns the
%   table from shipmbse.serviceBalance; Shortfall is true when the margin is
%   negative.
%
%   systemsReport("clear") deletes previous SystemsReport runs.
%
%   This report does not modify the model.
%
%   See also shipmbse.serviceBalance, generateWeightTableReport.

arguments
    cmd (1,1) string {mustBeMember(cmd, ["", "clear", "reset"])} = ""
end

if cmd ~= ""
    shipmbse.reportFile("SystemsReport", cmd);
    results = table();
    return
end

model = shipmbse.loadModel();
[results, details] = shipmbse.serviceBalance(model);

fileName = shipmbse.reportFile("SystemsReport");
fid = fopen(fileName, "wt");
if fid == -1
    error("systemsReport:CannotWrite", "Could not open ""%s"" for writing.", fileName);
end
closeFile = onCleanup(@() fclose(fid));

width = 90;
fprintf(fid, "%s\n%s\n%s\n", repmat('=', 1, width), centre("VESSEL SYSTEMS REPORT", width), repmat('=', 1, width));
fprintf(fid, "Model: %s   Generated: %s\n", model.Name, string(datetime("now", "Format", "yyyy-MM-dd HH:mm")));
fprintf(fid, "Totals include only components in the active configuration whose Status is On.\n");
fprintf(fid, "Margin = capacity - demand; a negative margin is a shortfall.\n");
[~, maturity] = shipmbse.dataMaturity(model);
fprintf(fid, "%s\n", maturity);

for d = 1:numel(details)
    fprintf(fid, "\n\n%s\n%s\n", centre(details(d).Domain, width), repmat('-', 1, width));
    if ~results.Modeled(d)
        fprintf(fid, "Not modeled: the profile for this domain is not attached to the model.\n");
        continue
    end
    unit = results.Unit(d);
    printSection(fid, "DEMAND: " + details(d).DemandLabel, details(d).DemandProperty, ...
        details(d).Demand, results.Demand(d), width);
    printSection(fid, "CAPACITY: " + details(d).CapacityLabel, details(d).CapacityProperty, ...
        details(d).Capacity, results.Capacity(d), width);
    if isnan(results.Margin(d))
        fprintf(fid, "\nMARGIN not computed: demand and capacity units differ.\n");
    else
        flag = "";
        if results.Shortfall(d)
            flag = "   ** SHORTFALL **";
        end
        fprintf(fid, "\n%-50s | %14.6g %s%s\n", "MARGIN (capacity - demand, On only)", results.Margin(d), unit, flag);
    end
end
fprintf(fid, "\n%s\n", repmat('=', 1, width));

fprintf('Systems report written to "%s".\n', fileName);

end

function printSection(fid, title, propPath, details, total, width)
fprintf(fid, "\n%s  (%s)\n", title, propPath);
if isempty(details)
    fprintf(fid, "  No active component carries this stereotype.\n");
    return
end
unit = details.Unit(1);
details = shipmbse.sortByModelId(details);
fprintf(fid, "%-50s | %14s | %-6s\n", "Component", "Value [" + unit + "]", "Status");
fprintf(fid, "%s\n", repmat('-', 1, width));
for k = 1:height(details)
    fprintf(fid, "%-50s | %14.6g | %-6s\n", shipmbse.pathLeaf(details.Path(k)), details.Value(k), ...
        onOff(details.StatusOn(k)));
end
fprintf(fid, "%-50s | %14.6g %s  (%d of %d on)\n", "TOTAL (On)", total, unit, ...
    sum(details.Included), height(details));
end

function s = onOff(tf)
if tf
    s = "On";
else
    s = "Off";
end
end

function s = centre(text, width)
s = blanks(floor((width - strlength(text)) / 2)) + text;
end
