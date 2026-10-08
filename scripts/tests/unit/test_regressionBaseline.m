classdef test_regressionBaseline < matlab.unittest.TestCase
    %TEST_REGRESSIONBASELINE Pins analysis results of the SYSTEM model.
    %   These values capture the current PLACEHOLDER data. They were verified
    %   by hand against the pre-Phase-1 scripts, then updated for the Phase 1b
    %   data migration (2026-10): units converted, and the fuel system's
    %   summary values replaced by its components (weight 401 t -> 239.61 t,
    %   electrical +14 kW, cooling +18 kW). When the model or the property
    %   tables change on purpose, update the expected values here in the same
    %   commit and say why in the commit message.

    properties
        Model
    end

    methods (TestClassSetup)
        function loadSystem(testCase)
            testCase.Model = shipmbse.loadModel();
        end
    end

    methods (Test)
        function massProperties(testCase)
            mp = shipmbse.massProperties(Model=testCase.Model);
            testCase.verifyEqual(mp.Weight, 18871 - 401 + 239.61, AbsTol=1e-6);
            testCase.verifyEqual(mp.WeightWithMargin, 20633.6 - (401 - 239.61) * 1.09, AbsTol=1e-6);
            testCase.verifyEqual([mp.LCG, mp.VCG, mp.TCG], [112.0885, 16.8694, -0.1267], AbsTol=5e-4);
            testCase.verifyEqual(mp.NumComponents, 44);
        end

        function serviceBalance(testCase)
            r = shipmbse.serviceBalance(testCase.Model);
            testCase.verifyTrue(all(r.Modeled));
            elec = r(r.Domain == "ELECTRICAL", :);
            testCase.verifyEqual([elec.Demand, elec.Capacity, elec.NumDemand], [203, 572, 21]);
            testCase.verifyEqual(r.Unit(r.Domain == "FUEL OIL"), "t/h");
            testCase.verifyEqual(r.Domain(r.Shortfall), "WASTE WATER");
        end

        function fuelEndurance(testCase)
            [days, byFuel] = shipmbse.fuelEndurance(testCase.Model);
            % Heavy fuel oil limits: 3500 m^3 x 0.98 t/m^3 / (25.2 m^3/h x 0.98 t/m^3) = 138.9 h
            testCase.verifyEqual(days, 3500 / 25.2 / 24, RelTol=1e-9);
            testCase.verifyEqual(byFuel.StorageUnit(1), "t");
            testCase.verifyEqual(height(byFuel), 3);
        end

        function everyDataComponentHasMaturity(testCase)
            rec = shipmbse.dataMaturity(testCase.Model);
            testCase.verifyFalse(any(rec.Maturity == "<none>"), "Components with data but no DataRecord: " + ...
                strjoin(shipmbse.pathLeaf(rec.Path(rec.Maturity == "<none>")), ", "));
            testCase.verifyTrue(all(ismember(rec.Maturity, shipmbse.config().MaturityLevels)));
        end

        function fuelSystemIsComponentSum(testCase)
            % Decision 2026-10-08: the fuel system's values are the sum of its components
            cfg = shipmbse.config();
            fuel = lookup(testCase.Model, 'Path', cfg.ModelName + "/" + cfg.Paths.Fuel + "/52X FUEL");
            testCase.verifyEmpty(setdiff(string(fuel.getStereotypes()), cfg.Stereotypes.DataRecord), ...
                "52X FUEL must not carry its own summary values.");
        end

        function noStereotypeOverlaps(testCase)
            testCase.verifyEmpty(shipmbse.findStereotypeOverlaps(testCase.Model), ...
                "A component and its descendant share a stereotype: totals may double-count.");
        end

        function interfaces(testCase)
            C = shipmbse.interfaceConnections(testCase.Model);
            testCase.verifyEqual(height(C), 269);
            testCase.verifyTrue(all(C.InterfaceMatch | C.EndB == "<external>"), "Interface mismatch between connected ports.");
        end

        function traceability(testCase)
            [reqs, comps] = shipmbse.traceability(testCase.Model);
            testCase.verifyEqual(sum(reqs.Unresolved), 0, "Unresolved requirement links.");
            need = reqs(reqs.NeedsAllocation, :);
            testCase.verifyTrue(all(need.Implemented), "Requirement(s) without an implementing component: " + ...
                strjoin(need.Id(~need.Implemented), ", "));
            testCase.verifyEqual(sum(reqs.Verified), 8);
            testCase.verifyEqual(height(comps), 69);
        end

        function linkedRequirements(testCase)
            testCase.verifyEqual(string({shipmbse.linkedRequirements("test_elec").Id}), "REQ-103");
            testCase.verifyEmpty(shipmbse.linkedRequirements("test_shipmbse"));
            testCase.verifyError(@() shipmbse.linkedRequirements("no_such_test_file"), ...
                "shipmbse:linkedRequirements:NotFound");
        end

        function requirementValues(testCase)
            testCase.verifyEqual(shipmbse.reqValue("REQ-402", "Threshold", Units="day"), 100);
            testCase.verifyEqual(shipmbse.reqValue("test_Req_FuelEndurance_02", "Threshold"), 1);
            testCase.verifyEqual(shipmbse.reqValue("test_ExistComp_01", "RequiredComponent"), "33X (SHORE POWER)");
            testCase.verifyError(@() shipmbse.reqValue("REQ-402", "Threshold", Units="h"), "shipmbse:reqValue:UnitMismatch");
            testCase.verifyError(@() shipmbse.reqValue("REQ-101", "Threshold"), "shipmbse:reqValue:Empty");
            testCase.verifyError(@() shipmbse.reqValue("REQ-402", "PerfVal1"), "shipmbse:reqValue:NoAttribute");
            testCase.verifyError(@() shipmbse.reqValue("REQ-999", "Threshold"), "shipmbse:reqValue:NoRequirement");
            testCase.verifyError(@() shipmbse.reqValue("test_shipmbse", "Threshold"), "shipmbse:reqValue:NoRequirement");
        end

        function snapshotAndReportFiles(testCase)
            snap = shipmbse.snapshot("regression", Model=testCase.Model);   % not saved
            testCase.verifyEqual(snap.Mass.Weight, 18709.61, AbsTol=1e-6);
            testCase.verifyGreaterThan(height(snap.Configuration), 0);
            prefix = "ZZTestReport";
            f1 = shipmbse.reportFile(prefix);
            testCase.verifyTrue(endsWith(f1, prefix + "_Run_001.txt"));
            fclose(fopen(f1, "w"));
            f2 = shipmbse.reportFile(prefix);
            testCase.verifyTrue(endsWith(f2, prefix + "_Run_002.txt"));
            fclose(fopen(f2, "w"));
            testCase.verifyTrue(endsWith(shipmbse.reportFile(prefix), prefix + "_Run_003.txt"), ...
                "Run numbering must continue past several existing runs.");
            shipmbse.reportFile(prefix, "clear");
            testCase.verifyEmpty(dir(fullfile(getOutputDir("reports"), prefix + "_Run_*.txt")));
        end
    end
end
