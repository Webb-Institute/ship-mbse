function changes = updateTestLinkRanges()
%UPDATETESTLINKRANGES Re-anchor each test's requirement link range to its test function.
%   changes = updateTestLinkRanges() visits every test file in scripts/tests
%   that has a link set (<test>~m.slmx). Requirements Toolbox stores each
%   link source as a character range in the file, so editing a test outside
%   the MATLAB Editor shifts the range. This sets each test's single linked
%   range to the lines of its test function (from "function test_..." to
%   that function's closing "end") and saves the link set.
%
%   Run after editing a linked test file outside the MATLAB Editor. Errors
%   if a file has more than one linked range or more than one test function.
%   This MODIFIES the .slmx link sets.
%
%   See also shipmbse.linkedRequirements.

testDir = fullfile(shipmbse.config().RootFolder, "scripts", "tests");
linkFiles = dir(fullfile(testDir, "test_*~m.slmx"));
changes = table('Size', [0 3], 'VariableTypes', {'string', 'string', 'string'}, ...
    'VariableNames', {'Test', 'OldLines', 'NewLines'});
for k = 1:numel(linkFiles)
    testName = extractBefore(string(linkFiles(k).name), "~m.slmx");
    mFile = fullfile(testDir, testName + ".m");
    linkSet = slreq.load(fullfile(linkFiles(k).folder, linkFiles(k).name));

    code = splitlines(string(fileread(mFile)));
    starts = find(startsWith(strtrim(code), "function test_"));
    if numel(starts) ~= 1
        error("updateTestLinkRanges:TestFunctions", ...
            "%s has %d test functions; expected exactly 1.", testName, numel(starts));
    end
    lineNo = (1:numel(code))';
    nextFcn = find(startsWith(strtrim(code), "function ") & lineNo > starts, 1);
    if isempty(nextFcn)
        nextFcn = numel(code) + 1;
    end
    stop = find(strtrim(code) == "end" & lineNo > starts & lineNo < nextFcn, 1, 'last');

    ranges = slreq.getTextRange(char(mFile));
    if numel(ranges) ~= 1
        error("updateTestLinkRanges:Ranges", "%s has %d linked ranges; expected exactly 1.", ...
            testName, numel(ranges));
    end
    old = ranges.getLineRange();
    ranges.setLineRange([starts stop]);
    linkSet.save();
    changes(end+1, :) = {testName, mat2str(old), mat2str([starts stop])}; %#ok<AGROW>
end
disp(changes);

end
