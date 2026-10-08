function tests = test_ExistComp_01
%TEST_EXISTCOMP_01 Verifies that the component named by the linked requirement exists and is active.
%   The linked requirement (REQ-104 Shore Power) names the required
%   component in its PerfVal1 attribute. The test fails if that component
%   does not exist in any variant choice, or exists only in an inactive
%   choice.
tests = functiontests(localfunctions);
end

function test_VerifyComponentExistsAndIsActive(testCase)
reqs = shipmbse.linkedRequirements(mfilename);
testCase.assertNotEmpty(reqs, "No requirement is linked to this test.");
testCase.assertNumElements(reqs, 1, "This test must verify exactly one requirement.");
req = reqs(1);

testCase.assertTrue(ismember("PerfVal1", string(req.getAttributeNames())), ...
    sprintf("Requirement %s has no PerfVal1 attribute naming the required component.", req.Id));
componentName = strtrim(erase(string(req.getAttribute("PerfVal1")), ["'", '"']));
testCase.assertNotEqual(componentName, "", ...
    sprintf("Requirement %s: PerfVal1 (required component name) is empty.", req.Id));

model = shipmbse.loadModel();
[~, allPaths] = shipmbse.activeComponents(model, AllVariantChoices=true);
[~, activePaths] = shipmbse.activeComponents(model);
exists = any(shipmbse.pathLeaf(allPaths) == componentName);
active = any(shipmbse.pathLeaf(activePaths) == componentName);

testCase.verifyTrue(exists, sprintf("Requirement %s: component ""%s"" does not exist in the model.", ...
    req.Id, componentName));
testCase.verifyTrue(~exists || active, sprintf( ...
    "Requirement %s: component ""%s"" exists only in an inactive variant choice.", req.Id, componentName));
end
