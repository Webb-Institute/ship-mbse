function reqs = linkedRequirements(testName)
%LINKEDREQUIREMENTS Requirements verified by a test file (its Verify links).
%   reqs = shipmbse.linkedRequirements(testName) loads the link set of the
%   test file (e.g. "test_elec" -> test_elec~m.slmx next to test_elec.m)
%   and returns the slreq.Requirement objects that its Verify links point
%   to, in link order. Returns an empty array if the test has no links.
%
%   Errors with id shipmbse:linkedRequirements:NotFound if the test file is
%   not on the path.
%
%   See also shipmbse.traceability.

arguments
    testName (1,1) string
end

testFile = string(which(testName));
if testFile == ""
    error("shipmbse:linkedRequirements:NotFound", "Test file ""%s"" is not on the path.", testName);
end
[folder, name] = fileparts(testFile);
linkFile = fullfile(folder, name + "~m.slmx");
reqs = slreq.Requirement.empty;
if ~isfile(linkFile)
    return
end
linkSet = slreq.load(linkFile);
links = linkSet.getLinks();
for k = 1:numel(links)
    if links(k).Type == "Verify" && links(k).isResolvedDestination
        dest = links(k).destination;
        reqSet = slreq.load(dest.reqSet);
        reqs(end+1) = reqSet.find('Type', 'Requirement', 'Id', dest.id); %#ok<AGROW>
    end
end

end
