classdef test_shipmbse < matlab.unittest.TestCase
    %TEST_SHIPMBSE Unit tests for the +shipmbse package against the MiniShip fixture.
    %   The fixture (buildMiniShip) has hand-calculated answers; see its help.

    properties
        Model
    end

    methods (TestClassSetup)
        function buildFixture(testCase)
            testCase.Model = buildMiniShip();
            testCase.addTeardown(@() bdclose("MiniShip"));
        end
    end

    methods (Test)
        % --- Traversal -------------------------------------------------------
        function activeComponentsSkipsContainersAndInactiveChoices(testCase)
            [~, paths] = shipmbse.activeComponents(testCase.Model);
            names = shipmbse.pathLeaf(paths);
            testCase.verifyEqual(sort(names), sort(["HULL"; "PLATE"; "FRAME"; "DIESEL"; "GEN"; "LOADS"; "LOADS2"; "FUEL"]));
            testCase.verifyFalse(any(names == "PROP"), "Variant container must not be returned.");
            testCase.verifyFalse(any(names == "ELECTRIC"), "Inactive choice must not be returned.");
        end

        function activeComponentsOptions(testCase)
            [~, leaves] = shipmbse.activeComponents(testCase.Model, LeavesOnly=true);
            testCase.verifyFalse(any(shipmbse.pathLeaf(leaves) == "HULL"));
            testCase.verifyNumElements(leaves, 7);
            [~, every] = shipmbse.activeComponents(testCase.Model, AllVariantChoices=true);
            testCase.verifyTrue(any(shipmbse.pathLeaf(every) == "ELECTRIC"));
            testCase.verifyFalse(any(shipmbse.pathLeaf(every) == "PROP"));
            [~, gens] = shipmbse.activeComponents(testCase.Model, Stereotype="ElectricalProfile.ElectricalGenerator");
            testCase.verifyEqual(shipmbse.pathLeaf(gens), "GEN");
        end

        function allComponentsIncludesEverything(testCase)
            names = string(arrayfun(@(c) string(c.Name), shipmbse.allComponents(testCase.Model)));
            testCase.verifyTrue(all(ismember(["PROP", "DIESEL", "ELECTRIC", "PLATE"], names)));
        end

        % --- Properties ------------------------------------------------------
        function getPropTypedValuesAndUnits(testCase)
            gen = lookup(testCase.Model, 'Path', "MiniShip/GEN");
            [v, u] = shipmbse.getProp(gen, "ElectricalProfile.ElectricalGenerator.PowerGenerated", Model=testCase.Model);
            testCase.verifyEqual(v, 20);
            testCase.verifyEqual(u, "kW");
            testCase.verifyClass(shipmbse.getProp(gen, "ElectricalProfile.ElectricalGenerator.Status"), 'logical');
            testCase.verifyEqual(shipmbse.getProp(gen, "FuelProfile.FuelConsumer.FuelType"), "F76");
        end

        function getPropErrors(testCase)
            gen = lookup(testCase.Model, 'Path', "MiniShip/GEN");
            testCase.verifyError(@() shipmbse.getProp(gen, "CoolingProfile.CoolConsumer.CoolConsumed"), ...
                "shipmbse:getProp:NoProperty");
            testCase.verifyError(@() shipmbse.getProp(gen, "ElectricalProfile.ElectricalGenerator.PowerGenerated", ...
                Unit="MW", Model=testCase.Model), "shipmbse:getProp:UnitMismatch");
            testCase.verifyError(@() shipmbse.propertyInfo("No.Such.Thing", testCase.Model), ...
                "shipmbse:propertyInfo:Unknown");
            testCase.verifyError(@() shipmbse.propertyInfo("TooShort", testCase.Model), ...
                "shipmbse:propertyInfo:BadPath");
        end

        function propertyInfoForTextProperty(testCase)
            info = shipmbse.propertyInfo("FuelProfile.FuelConsumer.FuelType", testCase.Model);
            testCase.verifySize(info, [1 1], "propertyInfo must return a scalar struct for text properties.");
            testCase.verifyEqual(info.Type, "string");
        end

        function unsetValuesAreNaN(testCase)
            % Numeric profile defaults are NaN, so a value never entered is distinguishable from 0
            diesel = lookup(testCase.Model, 'Path', "MiniShip/PROP/DIESEL");
            [v, ~, isDefault] = shipmbse.getProp(diesel, "ElectricalProfile.ElectricalConsumer.PowerFactor", Model=testCase.Model);
            testCase.verifyTrue(isnan(v));
            testCase.verifyTrue(isDefault);
            gen = lookup(testCase.Model, 'Path', "MiniShip/GEN");
            [v, ~, isDefault] = shipmbse.getProp(gen, "WeightsCentersProfile.WeightsCenters.TCG", Model=testCase.Model);
            testCase.verifyEqual(v, 0);
            testCase.verifyFalse(isDefault, "An entered 0 is not the (NaN) default.");
        end

        function sumPropertyExcludesMissing(testCase)
            diesel = lookup(testCase.Model, 'Path', "MiniShip/PROP/DIESEL");
            p = "ElectricalProfile.ElectricalConsumer.PowerRequired";
            diesel.setProperty(p, "NaN");
            testCase.addTeardown(@() diesel.setProperty(p, "5"));
            [total, det] = shipmbse.sumProperty(p, OnlyIfOn=true, Model=testCase.Model);
            testCase.verifyEqual(total, 8);   % DIESEL missing, LOADS2 off
            testCase.verifyEqual(sum(det.Missing), 1);
        end

        function dataMaturitySummary(testCase)
            [rec, summary] = shipmbse.dataMaturity(testCase.Model);
            testCase.verifyEqual(rec.Maturity(shipmbse.pathLeaf(rec.Path) == "PLATE"), "Vendor");
            testCase.verifyEqual(sum(rec.Maturity == "<none>"), height(rec) - 1);
            testCase.verifySubstring(summary, "1 Vendor");
        end

        % --- Sums and balances ---------------------------------------------------
        function sumPropertyOnlyIfOn(testCase)
            p = "ElectricalProfile.ElectricalConsumer.PowerRequired";
            [total, det] = shipmbse.sumProperty(p, Model=testCase.Model);
            [on, detOn] = shipmbse.sumProperty(p, OnlyIfOn=true, Model=testCase.Model);
            testCase.verifyEqual(total, 113);        % 5 + 8 + 100 (inactive ELECTRIC 500 excluded)
            testCase.verifyEqual(on, 13);          % LOADS2 is off
            testCase.verifyEqual(height(det), 3);
            testCase.verifyEqual(sum(detOn.Included), 2);
            testCase.verifyEqual(det.Unit(1), "kW");
        end

        function serviceBalanceMargin(testCase)
            results = shipmbse.serviceBalance(testCase.Model);
            elec = results(results.Domain == "ELECTRICAL", :);
            testCase.verifyEqual([elec.Demand, elec.Capacity, elec.Margin], [13, 20, 7]);
            testCase.verifyFalse(elec.Shortfall);
        end

        % --- Mass properties -----------------------------------------------------
        function massPropertiesHandValues(testCase)
            mp = shipmbse.massProperties(Model=testCase.Model);
            testCase.verifyEqual(mp.Weight, 200);
            testCase.verifyEqual(mp.WeightWithMargin, 216, AbsTol=1e-9);
            testCase.verifyEqual([mp.LCG, mp.VCG, mp.TCG], [19, 4.85, 0.35], AbsTol=1e-9);
            testCase.verifyEqual(mp.LCGWithMargin, 4140/216, AbsTol=1e-9);
            testCase.verifyEqual(mp.NumComponents, 4);
        end

        % --- Fuel endurance ------------------------------------------------------
        function fuelEndurancePooledStorage(testCase)
            [days, byFuel, consumers] = shipmbse.fuelEndurance(testCase.Model);
            testCase.verifyEqual(days, 1, RelTol=1e-12);   % 36 t / (1.0 + 0.5) t/h = 24 h
            testCase.verifyEqual(byFuel.Fuel, "F76");
            testCase.verifyEqual(height(consumers), 2);   % DIESEL and GEN; ELECTRIC inactive
        end

        function durationToDaysUnits(testCase)
            testCase.verifyEqual(shipmbse.durationToDays(86400, "kL", 1, "kL/s"), 1);
            testCase.verifyEqual(shipmbse.durationToDays(24, "m3", 1, "m3/h"), 1);
            testCase.verifyEqual(shipmbse.durationToDays(10, "kL", 2, "kL/day"), 5);
            testCase.verifyEqual(shipmbse.durationToDays(48, "t", 2, "t/h"), 1);
            testCase.verifyError(@() shipmbse.durationToDays(1, "t", 1, "kL/s"), ...
                "shipmbse:durationToDays:UnitMismatch");
            testCase.verifyError(@() shipmbse.durationToDays(1, "kL", 1, "kL/week"), ...
                "shipmbse:durationToDays:UnitMismatch");
        end

        % --- Interfaces and overlaps -----------------------------------------------
        function interfaceConnectionsThroughVariant(testCase)
            C = shipmbse.interfaceConnections(testCase.Model);
            ends = shipmbse.pathLeaf(C.EndA) + "." + C.PortA + "->" + shipmbse.pathLeaf(C.EndB) + "." + C.PortB;
            testCase.verifyEqual(sort(ends), sort(["GEN.P->LOADS.P"; "GEN.Q->DIESEL.Q"]));
            testCase.verifyEqual(C.RedundancyA(C.PortA == "P"), 2);
        end

        function findStereotypeOverlapsDetectsNesting(testCase)
            testCase.verifyEmpty(shipmbse.findStereotypeOverlaps(testCase.Model));
            hull = lookup(testCase.Model, 'Path', "MiniShip/HULL");
            hull.applyStereotype("WeightsCentersProfile.WeightsCenters");
            testCase.addTeardown(@() hull.removeStereotype("WeightsCentersProfile.WeightsCenters"));
            ov = shipmbse.findStereotypeOverlaps(testCase.Model);
            testCase.verifyEqual(height(ov), 2);   % HULL over PLATE and FRAME
            testCase.verifyEqual(unique(ov.Stereotype), "WeightsCentersProfile.WeightsCenters");
        end

        % --- Path helpers ---------------------------------------------------------
        function pathLeafHandlesEscapedSlash(testCase)
            [n, p] = shipmbse.pathLeaf(["SYSTEM/SHIP/55X (CARGO//MISSION)"; "SYSTEM"]);
            testCase.verifyEqual(n, ["55X (CARGO/MISSION)"; "SYSTEM"]);
            testCase.verifyEqual(p, ["SYSTEM/SHIP"; ""]);
        end

        function sortByModelIdOrder(testCase)
            T = table(["S/53X (AIR)"; "S/521 (STORE)"; "S/52X (FUEL)"; "S/ENV"; "S/10X (PLATE)"], 'VariableNames', {'Path'});
            T = shipmbse.sortByModelId(T);
            testCase.verifyEqual(shipmbse.pathLeaf(T.Path), ...
                ["10X (PLATE)"; "52X (FUEL)"; "521 (STORE)"; "53X (AIR)"; "ENV"]);
        end
    end
end
