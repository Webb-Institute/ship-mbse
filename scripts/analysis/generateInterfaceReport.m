function reportTable = generateInterfaceReport()
%GENERATEINTERFACEREPORT End-to-end interface report between leaf components.
%   reportTable = generateInterfaceReport() traces every port of every leaf
%   component in the active configuration through composite boundaries and
%   variant containers to the leaf component at the other end, and writes
%   outputs/reports/InterfaceReport.txt grouped by interface. Returns the
%   connection table from shipmbse.interfaceConnections.
%
%   The redundancy columns are the PortProfile.Redundancy.RedundancyScore of
%   each end's own port. Connections whose two ends use different
%   interfaces are listed separately.
%
%   This report does not modify the model.
%
%   See also shipmbse.interfaceConnections.

reportTable = shipmbse.interfaceConnections();
T = reportTable;
T.EndA = shipmbse.pathLeaf(T.EndA);
T.EndB = shipmbse.pathLeaf(T.EndB);

fileName = fullfile(getOutputDir("reports"), "InterfaceReport.txt");
fid = fopen(fileName, "wt");
if fid == -1
    error("generateInterfaceReport:CannotWrite", "Could not open ""%s"" for writing.", fileName);
end
closeFile = onCleanup(@() fclose(fid));

width = 130;
fprintf(fid, "%s\nINTERFACE REPORT: %d end-to-end leaf connections   Generated: %s\n%s\n", ...
    repmat('=', 1, width), height(T), string(datetime("now", "Format", "yyyy-MM-dd HH:mm")), repmat('=', 1, width));
fmt = "%-40s | %-14s | %-40s | %-14s | %5s | %5s\n";
for iface = unique(T.Interface)'
    rows = T(T.Interface == iface, :);
    fprintf(fid, "\n%s  (%d)\n%s\n", iface, height(rows), repmat('-', 1, width));
    fprintf(fid, fmt, "End A", "Port A", "End B", "Port B", "Red A", "Red B");
    for k = 1:height(rows)
        fprintf(fid, fmt, rows.EndA(k), rows.PortA(k), rows.EndB(k), rows.PortB(k), ...
            string(rows.RedundancyA(k)), string(rows.RedundancyB(k)));
    end
end

mismatch = T(~T.InterfaceMatch & T.EndB ~= "<external>", :);
fprintf(fid, "\n%s\nINTERFACE MISMATCHES (ends use different interfaces): %d\n", repmat('=', 1, width), height(mismatch));
for k = 1:height(mismatch)
    fprintf(fid, "  %s.%s <-> %s.%s\n", mismatch.EndA(k), mismatch.PortA(k), mismatch.EndB(k), mismatch.PortB(k));
end

fprintf('Interface report: %d connections, %d interface mismatches. Written to "%s".\n', ...
    height(T), height(mismatch), fileName);

end
