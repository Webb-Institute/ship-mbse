function tests = test_cAir
tests = functiontests(localfunctions);
end

function test_CompAirSupplyVersusDemand(testCase)
% 1. Define values

[airReq, ~] =sumPropIfOn('AirConsumed', 'AirConsumer', 'CompAirProfile');
[airGen, ~] =sumPropIfOn('AirProduced', 'AirProducer', 'CompAirProfile');


% 2. Use the test framework assertion
verifyGreaterThanOrEqual(testCase, airGen, airReq, ...
    'Insufficient Compressed Air Supply');

end