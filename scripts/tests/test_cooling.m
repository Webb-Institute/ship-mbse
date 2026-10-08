function tests = test_cooling
%TEST_COOLING Verifies REQ-109 Primary Cooling Service: capacity that is on covers demand that is on.
tests = functiontests(localfunctions);
end

function test_CoolingSupplyVersusDemand(testCase)
st = shipmbse.config().Stereotypes;
verifyServiceBalance(testCase, st.CoolConsumer + ".CoolConsumed", st.CoolProducer + ".CoolProduced", "Cooling");
end
