function results = runAllTests()
%RUNALLTESTS Run every test in scripts/tests and display a summary table.
%   results = runAllTests() runs the ship-mbse test suite and returns the
%   matlab.unittest.TestResult array. Open the ship-mbse project first so
%   the model, requirements, and utilities are on the path.
%
%   See also runtests.

testFolder = fullfile(fileparts(mfilename("fullpath")), "tests");
results = runtests(testFolder);
disp(table(results));

end
