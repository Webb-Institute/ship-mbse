function [reqs, comps] = verifyRequirementAllocations()
%VERIFYREQUIREMENTALLOCATIONS Two-way traceability audit with a written report.
%   [reqs, comps] = verifyRequirementAllocations() checks that every
%   requirement needing allocation is implemented by an architecture
%   component, lists which requirements are verified by tests, and checks
%   that every component (all variant choices) implements at least one
%   requirement. Writes outputs/reports/TraceabilityReport.txt and prints a
%   summary. Returns the tables from shipmbse.traceability.
%
%   This report does not modify the model or the requirements.
%
%   See also shipmbse.traceability.

[reqs, comps] = shipmbse.traceability();
cfg = shipmbse.config();

need = reqs(reqs.NeedsAllocation, :);
missingImpl = need(~need.Implemented, :);
verified = reqs(reqs.Verified, :);
missingComp = comps(~comps.Allocated, :);

fileName = fullfile(getOutputDir("reports"), "TraceabilityReport.txt");
fid = fopen(fileName, "wt");
if fid == -1
    error("verifyRequirementAllocations:CannotWrite", "Could not open ""%s"" for writing.", fileName);
end
closeFile = onCleanup(@() fclose(fid));
out = @(varargin) [fprintf(varargin{:}), fprintf(fid, varargin{:})];

line = repmat('-', 1, 70);
out("=== TRACEABILITY REPORT ===\n");
out("Requirement set: %s   Model: %s   Generated: %s\n\n", cfg.RequirementSet, cfg.ModelName, ...
    string(datetime("now", "Format", "yyyy-MM-dd HH:mm")));

out("%s\n1. REQUIREMENTS -> ARCHITECTURE (Implement links)\n%s\n", line, line);
out("Requirements:                 %d (%d containers/informational excluded)\n", height(reqs), height(reqs) - height(need));
out("Implemented by a component:   %d of %d\n", sum(need.Implemented), height(need));
out("Unresolved links:             %d\n", sum(reqs.Unresolved));
printList(out, "Requirements with NO implementing component:", ...
    "[" + missingImpl.Id + "] " + missingImpl.Summary);

out("\n%s\n2. REQUIREMENTS -> TESTS (Verify links)\n%s\n", line, line);
out("Verified by a test:           %d of %d\n", height(verified), height(need));
printList(out, "Verified requirements:", "[" + verified.Id + "] " + verified.Summary + "  <- " + verified.VerifiedBy);

out("\n%s\n3. ARCHITECTURE -> REQUIREMENTS (all variant choices)\n%s\n", line, line);
out("Components:                   %d\n", height(comps));
out("Implementing a requirement:   %d\n", sum(comps.Allocated));
printList(out, "Components with NO requirement:", replace(extractAfter(missingComp.Path, cfg.ModelName + "/"), "//", "/"));

fprintf('\nTraceability report written to "%s".\n', fileName);

end

function printList(out, heading, items)
if isempty(items)
    out("  None.\n");
    return
end
out("%s\n", heading);
for k = 1:numel(items)
    out("  - %s\n", items(k));
end
end
