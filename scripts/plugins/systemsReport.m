function results = systemsReport(cmd)
%SYSTEMSREPORT Demand versus capacity for each ship service domain.
%   results = systemsReport() writes outputs/reports/SystemsReport_Run_NNN.txt
%   with, for each domain (electrical, fuel, lube, cooling, compressed air,
%   heat, and each waste stream), the demand and capacity components in the
%   active configuration with value, unit and status, the totals of
%   components that are on, and the margin (capacity - demand). Returns a
%   table with one row per domain; Shortfall is true when the margin is
%   negative.
%
%   systemsReport("clear") deletes previous SystemsReport runs.
%
%   This report does not modify the model.
%
%   See also shipmbse.sumProperty, GenerateWeightTableReport.

arguments
    cmd (1,1) string {mustBeMember(cmd, ["", "clear", "reset"])} = ""
end

if cmd ~= ""
    shipmbse.reportFile("SystemsReport", cmd);
    results = table();
    return
end

st = shipmbse.config().Stereotypes;
% Each domain compares DEMAND with CAPACITY; Margin = capacity - demand, so a
% negative margin is a shortfall in every domain. For waste streams the
% producers are the demand and the receivers are the capacity.
%          Domain            Demand property                            Capacity property                           Demand label        Capacity label
domains = ["ELECTRICAL",     st.ElectricalConsumer + ".PowerRequired",  st.ElectricalGenerator + ".PowerGenerated", "CONSUMERS",        "GENERATORS";
           "FUEL OIL",       st.FuelConsumer + ".FuelRequired",         st.FuelProducer + ".FuelProduced",          "CONSUMERS",        "PRODUCERS";
           "LUBE OIL",       st.LubeConsumer + ".LubeRequired",         st.LubeProducer + ".LubeProduced",          "CONSUMERS",        "PRODUCERS";
           "COOLING / FW",   st.CoolConsumer + ".CoolConsumed",         st.CoolProducer + ".CoolProduced",          "CONSUMERS",        "PRODUCERS";
           "COMPRESSED AIR", st.AirConsumer + ".AirConsumed",           st.AirProducer + ".AirProduced",            "CONSUMERS",        "PRODUCERS";
           "HEAT",           st.HeatConsumer + ".HeatConsumed",         st.HeatProducer + ".HeatProduced",          "CONSUMERS",        "PRODUCERS";
           "WASTE GAS",      st.WasteGasProducer + ".WGProduced",       st.WasteReceiver + ".WGReceived",           "WASTE PRODUCERS",  "WASTE RECEIVERS";
           "WASTE OIL",      st.WasteOilProducer + ".WOProduced",       st.WasteReceiver + ".WOReceived",           "WASTE PRODUCERS",  "WASTE RECEIVERS";
           "WASTE WATER",    st.WasteWaterProducer + ".WWProduced",     st.WasteReceiver + ".WWReceived",           "WASTE PRODUCERS",  "WASTE RECEIVERS";
           "WASTE SOLID",    st.WasteSolidProducer + ".WSProduced",     st.WasteReceiver + ".WSReceived",           "WASTE PRODUCERS",  "WASTE RECEIVERS"];

model = shipmbse.loadModel();
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

n = size(domains, 1);
results = table('Size', [n 8], ...
    'VariableTypes', {'string', 'double', 'double', 'double', 'double', 'double', 'string', 'logical'}, ...
    'VariableNames', {'Domain', 'Demand', 'NumDemand', 'Capacity', 'NumCapacity', 'Margin', 'Unit', 'Shortfall'});
for d = 1:n
    [demand, dDet] = shipmbse.sumProperty(domains(d, 2), OnlyIfOn=true, Model=model);
    [capacity, cDet] = shipmbse.sumProperty(domains(d, 3), OnlyIfOn=true, Model=model);
    dUnit = unitOf(dDet, domains(d, 2), model);
    cUnit = unitOf(cDet, domains(d, 3), model);

    fprintf(fid, "\n\n%s\n%s\n", centre(domains(d, 1), width), repmat('-', 1, width));
    printSection(fid, "DEMAND: " + domains(d, 4), domains(d, 2), dDet, dUnit, demand, width);
    printSection(fid, "CAPACITY: " + domains(d, 5), domains(d, 3), cDet, cUnit, capacity, width);
    if dUnit == cUnit
        margin = capacity - demand;
        flag = "";
        if margin < 0
            flag = "   ** SHORTFALL **";
        end
        fprintf(fid, "\n%-50s | %14.6g %s%s\n", "MARGIN (capacity - demand, On only)", margin, cUnit, flag);
    else
        margin = NaN;
        fprintf(fid, "\nMARGIN not computed: demand unit ""%s"" differs from capacity unit ""%s"".\n", dUnit, cUnit);
    end
    results(d, :) = {domains(d, 1), demand, sum(dDet.Included), capacity, sum(cDet.Included), ...
        margin, cUnit, margin < 0};
end
fprintf(fid, "\n%s\n", repmat('=', 1, width));

fprintf('Systems report written to "%s".\n', fileName);

end

function printSection(fid, title, propPath, details, unit, total, width)
fprintf(fid, "\n%s  (%s)\n", title, propPath);
if isempty(details)
    fprintf(fid, "  No active component carries this stereotype.\n");
    return
end
details = shipmbse.sortByModelId(details);
fprintf(fid, "%-50s | %14s | %-6s\n", "Component", "Value [" + unit + "]", "Status");
fprintf(fid, "%s\n", repmat('-', 1, width));
for k = 1:height(details)
    name = shipmbse.pathLeaf(details.Path(k));
    fprintf(fid, "%-50s | %14.6g | %-6s\n", name, details.Value(k), onOff(details.StatusOn(k)));
end
fprintf(fid, "%-50s | %14.6g %s  (%d of %d on)\n", "TOTAL (On)", total, unit, ...
    sum(details.Included), height(details));
end

function unit = unitOf(details, propPath, model)
if ~isempty(details)
    unit = details.Unit(1);
else
    unit = shipmbse.propertyInfo(propPath, model).Units;
end
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
