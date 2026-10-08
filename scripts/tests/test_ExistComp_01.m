function tests = test_ExistComp_01
%TEST_EXISTCOMP_01 Verifies that the component named by the linked requirement exists and is active.
%   The linked requirement (REQ-104 Shore Power) names the required
%   component in its RequiredComponent attribute. The test fails if that component
%   does not exist in any variant choice, or exists only in an inactive
%   choice.
tests = functiontests(localfunctions);
end

function test_VerifyComponentExistsAndIsActive(testCase)
[componentName, req] = shipmbse.reqValue(mfilename, "RequiredComponent");

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
