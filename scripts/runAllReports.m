function status = runAllReports()
%RUNALLREPORTS Run every report and save an analysis snapshot.
%   status = runAllReports() runs, in order: systemsReport,
%   generateWeightTableReport, verifyRequirementAllocations, fuelAnalysis
%   and generateInterfaceReport, then saves a snapshot of the active
%   configuration (outputs/snapshots) for changeImpactReport. Every report
%   runs even if an earlier one fails; returns a table of outcomes and
%   errors at the end if any report failed.
%
%   None of these reports modifies the model. Open the ship-mbse project
%   first.
%
%   See also changeImpactReport, shipmbse.snapshot.

reports = {
    "Systems report",      @() systemsReport();
    "Weight report",       @() generateWeightTableReport();
    "Traceability report", @() verifyRequirementAllocations();
    "Fuel analysis",       @() fuelAnalysis();
    "Interface report",    @() generateInterfaceReport();
    "Snapshot",            @() shipmbse.snapshot(Save=true) };

n = size(reports, 1);
status = table(string(reports(:, 1)), strings(n, 1), zeros(n, 1), ...
    'VariableNames', {'Report', 'Result', 'Seconds'});
fprintf('Running %d reports on model "%s"...\n', n, shipmbse.config().ModelName);
for k = 1:n
    fprintf('\n--- %s ---\n', reports{k, 1});
    t = tic;
    try
        reports{k, 2}();
        status.Result(k) = "OK";
    catch err
        status.Result(k) = "FAILED: " + err.message;
        fprintf(2, '%s FAILED: %s\n', reports{k, 1}, err.message);
    end
    status.Seconds(k) = toc(t);
end

fprintf('\n');
disp(status);
failed = ~startsWith(status.Result, "OK");
if any(failed)
    error("runAllReports:Failed", "%d of %d reports failed: %s", sum(failed), n, ...
        strjoin(status.Report(failed), ", "));
end
fprintf('All %d reports completed. Output: %s\n', n, getOutputDir("reports"));

end
