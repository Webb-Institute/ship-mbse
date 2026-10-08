function fileName = reportFile(prefix, cmd)
%REPORTFILE Path for the next numbered report run, or clear previous runs.
%   fileName = shipmbse.reportFile(prefix) returns
%   outputs/reports/<prefix>_Run_NNN.txt, where NNN is one more than the
%   highest existing run number for that prefix (starting at 001).
%
%   fileName = shipmbse.reportFile(prefix, "clear") (or "reset") deletes all
%   <prefix>_Run_*.txt files and returns "".
%
%   See also getOutputDir.

arguments
    prefix (1,1) string
    cmd (1,1) string {mustBeMember(cmd, ["", "clear", "reset"])} = ""
end

outputDir = getOutputDir("reports");
existing = dir(fullfile(outputDir, prefix + "_Run_*.txt"));

if cmd ~= ""
    for k = 1:numel(existing)
        delete(fullfile(existing(k).folder, existing(k).name));
    end
    fprintf('Cleared %d previous %s reports from "%s".\n', numel(existing), prefix, outputDir);
    fileName = "";
    return
end

runNums = str2double(regexp(string({existing.name}), prefix + "_Run_(\d+)\.txt", "tokens", "once"));
nextNum = max([0, runNums(~isnan(runNums))]) + 1;
fileName = fullfile(outputDir, sprintf("%s_Run_%03d.txt", prefix, nextNum));

end
