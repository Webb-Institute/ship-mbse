function tests = test_lube
tests = functiontests(localfunctions);
end

function test_LubeSupplyVersusDemand(testCase)
% 1. Define values

[lubeReq, ~] =sumPropIfOn('LubeRequired', 'LubeConsumer', 'LubeProfile');
[lubeGen, ~] =sumPropIfOn('LubeProduced', 'LubeProducer', 'LubeProfile');


% 2. Use the test framework assertion
verifyGreaterThanOrEqual(testCase, lubeGen, lubeReq, ...
    'Insufficient Lube Oil Supply');

end