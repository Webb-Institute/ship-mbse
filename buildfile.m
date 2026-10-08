function plan = buildfile
%BUILDFILE ship-mbse build plan (run with buildtool from the project root).
%   buildtool            check + test (default)
%   buildtool check      Code Analyzer over scripts/ (fails on any warning)
%   buildtool test       code tests: +shipmbse unit tests and SYSTEM
%                        regression baseline, with JUnit and coverage output
%   buildtool verify     requirement verification tests (does the DESIGN
%                        meet its requirements?), with JUnit output
%   buildtool trace      traceability audit; fails on unresolved links or a
%                        requirement with no implementing component
%   buildtool reports    all reports plus an analysis snapshot
%   buildtool all        check test verify trace reports
%
%   "test" failures mean the tools are wrong. "verify" failures mean the
%   design (with its current, partly placeholder data) does not meet a
%   requirement; they are reported separately and are not part of the
%   default build.
%
%   Results go to outputs/test-results/ and outputs/reports/.

import matlab.buildtool.tasks.CodeIssuesTask
import matlab.buildtool.tasks.TestTask

plan = buildplan(localfunctions);
results = fullfile("outputs", "test-results");

plan("check") = CodeIssuesTask("scripts", WarningThreshold=0);

plan("test") = TestTask(fullfile("scripts", "tests", "unit"), ...
    SourceFiles=fullfile("scripts", "+shipmbse"), ...
    TestResults=fullfile(results, "unit.xml"), ...
    CodeCoverageResults=[fullfile(results, "coverage.xml"), fullfile(results, "coverage", "index.html")]);
plan("test").Description = "Run code tests (+shipmbse unit tests, SYSTEM regression baseline)";

plan("verify") = TestTask(fullfile("scripts", "tests"), IncludeSubfolders=false, ...
    TestResults=fullfile(results, "verification.xml"));
plan("verify").Description = "Run requirement verification tests against SYSTEM";

plan("trace").Description = "Traceability audit (unresolved links, unimplemented requirements)";
plan("reports").Description = "Run all reports and save an analysis snapshot";
plan("all").Description = "Run every task";
plan("all").Dependencies = ["check", "test", "verify", "trace", "reports"];

plan.DefaultTasks = ["check", "test"];

end

function traceTask(~)
% Traceability audit (unresolved links, unimplemented requirements)
[reqs, ~] = verifyRequirementAllocations();
need = reqs(reqs.NeedsAllocation, :);
problems = strings(0);
if any(reqs.Unresolved > 0)
    problems(end+1) = sum(reqs.Unresolved) + " unresolved requirement link(s)";
end
if any(~need.Implemented)
    problems(end+1) = "not implemented by any component: " + strjoin(need.Id(~need.Implemented), ", ");
end
if ~isempty(problems)
    error("buildfile:Traceability", "Traceability audit failed: %s", strjoin(problems, "; "));
end
end

function reportsTask(~)
% Run all reports and save an analysis snapshot
runAllReports();
end

function allTask(~)
% Run every task
end
