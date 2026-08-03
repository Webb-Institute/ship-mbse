function tests = test_cooling
tests = functiontests(localfunctions);
end

function test_CoolingSupplyVersusDemand(testCase)
% 1. Define values

[coolReq, ~] =sumPropIfOn('CoolConsumed', 'CoolConsumer', 'CoolingProfile');
[coolGen, ~] =sumPropIfOn('CoolProduced', 'CoolProducer', 'CoolingProfile');


% 2. Use the test framework assertion
verifyGreaterThanOrEqual(testCase, coolGen, coolReq, ...
    'Insufficient Cooling Supply');

end