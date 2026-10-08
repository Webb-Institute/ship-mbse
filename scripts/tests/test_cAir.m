function tests = test_cAir
%TEST_CAIR Verifies REQ-113 Compressed Air Service: capacity that is on covers demand that is on.
tests = functiontests(localfunctions);
end

function test_CompAirSupplyVersusDemand(testCase)
st = shipmbse.config().Stereotypes;
verifyServiceBalance(testCase, st.AirConsumer + ".AirConsumed", st.AirProducer + ".AirProduced", "Compressed air");
end
