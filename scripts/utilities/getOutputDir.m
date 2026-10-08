function outputDir = getOutputDir(subfolder)
%GETOUTPUTDIR Absolute path to a ship-mbse output folder, created if needed.
%   outputDir = getOutputDir() returns <repo>/outputs/reports.
%   outputDir = getOutputDir(subfolder) returns <repo>/outputs/<subfolder>,
%   e.g. "reports", "tables", "figures", or "case_study".
%
%   The path is resolved from this file's location, so results do not
%   depend on the current folder or on the MATLAB Project being open.

arguments
    subfolder (1,1) string = "reports"
end

repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
outputDir = char(fullfile(repoRoot, "outputs", subfolder));
if ~isfolder(outputDir)
    mkdir(outputDir);
end

end
