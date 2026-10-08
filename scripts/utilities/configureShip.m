function configureShip()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SHIP CONFIGURATION SCRIPT
%
% Configures System Composer variants for ship architecture selection
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% ================= USER CONFIGURATION ================================

% Ship architecture
% Options:
%   "DIESEL"
%   "HYBRID"
%   "ELECTRIC"

Architecture = "DIESEL";


% Power Take-Off
% Options:
%   "NONE"
%   "PTO"

PTO = "PTO";


% Propulsor type
% Options:
%   "SHAFT"
%   "ELECTRIC"
%   "WATERJET"

Propulsor = "SHAFT";


% Maneuvering thruster
% true  = installed
% false = absent

ManeuveringThruster = true;


% Fuel consumers

MainEngine = true;

DieselGenerators = true;

MissionFuel = true;



%% ================= LOAD MODEL =========================================

model = systemcomposer.loadModel("SYSTEM");

root = model.Architecture;



%% ================= GET SHIP ===========================================

ship = root.Components(...
    strcmp({root.Components.Name},"SHIP"));


shipComponents = ship.OwnedArchitecture.Components;



%% ================= PROPULSION =========================================

propulsion = shipComponents(...
    strcmp({shipComponents.Name},"200 (PROPULSION)"));


propComponents = propulsion.OwnedArchitecture.Components;


mainEngine = propComponents(...
    strcmp({propComponents.Name},"20X (MAIN ENGINE)"));


propulsors = propComponents(...
    strcmp({propComponents.Name},"21X (PROPULSORS)"));


shafting = propComponents(...
    strcmp({propComponents.Name},"22X (SHAFTING)"));


powerTransmission = propComponents(...
    strcmp({propComponents.Name},"23X (POWER TRANSMISSION)"));



%% ================= MAIN ENGINE ========================================

if MainEngine

    selectVariant(mainEngine,"20X DIESEL ENGINE");

else

    selectVariant(mainEngine,"20X ABSENT");

end



%% ================= PROPULSORS =========================================

switch Propulsor

    case "SHAFT"

        if ManeuveringThruster
            propulsorChoice = "21X SHAFT DRIVE + MANEUVERING THRUSTER";
        else
            propulsorChoice = "21X SHAFT DRIVE";
        end


    case "ELECTRIC"

        if ManeuveringThruster
            propulsorChoice = "21X ELECTRIC DRIVE + MANEUVERING THRUSTER";
        else
            propulsorChoice = "21X ELECTRIC DRIVE";
        end


    case "WATERJET"

        if ManeuveringThruster
            propulsorChoice = "21X WATER JET + MANEUVERING THRUSTER";
        else
            propulsorChoice = "21X WATER JET";
        end


    otherwise

        error("Invalid propulsor selection")

end


selectVariant(propulsors,propulsorChoice)



%% ================= SHAFTING ===========================================

if Propulsor == "WATERJET"

    selectVariant(shafting,"22X ABSENT");

else

    selectVariant(shafting,"22X MECHANICAL");

end



%% ================= POWER TRANSMISSION ================================

if Architecture == "ELECTRIC"

    selectVariant(powerTransmission,...
        "23X ABSENT");


elseif PTO == "PTO"

    selectVariant(powerTransmission,...
        "23X MECHANICAL WITH POWER TAKEOFF");


elseif PTO == "NONE"

    selectVariant(powerTransmission,...
        "23X MECHANICAL");


else

    error("Invalid PTO selection")

end



%% ================= FUEL SYSTEM =========================================

auxiliary = shipComponents(...
    strcmp({shipComponents.Name},"500 (AUXILLIARY SYSTEMS)"));


auxComponents = auxiliary.OwnedArchitecture.Components;


fuel = auxComponents(...
    strcmp({auxComponents.Name},"52X (FUEL)"));


fuelRequired = MainEngine || DieselGenerators || MissionFuel;



if fuelRequired

    selectVariant(fuel,"52X FUEL");

else

    selectVariant(fuel,"52X ABSENT");

    model.save();

    disp("==============================")
    disp("SHIP CONFIGURATION COMPLETE")
    disp("==============================")

    return

end



%% ================= FUEL PIPING ========================================

activeFuel = fuel.getActiveChoice();


fuelComponents = activeFuel.OwnedArchitecture.Components;



MEFuel = fuelComponents(...
    strcmp({fuelComponents.Name},"525 (ME FO PIPING)"));


GSFuel = fuelComponents(...
    strcmp({fuelComponents.Name},"526 (GS FO PIPING)"));


MissionFuelPipe = fuelComponents(...
    strcmp({fuelComponents.Name},"527 (MISSION FO PIPING)"));



% Main engine fuel

if MainEngine

    selectVariant(MEFuel,...
        "525 ME FO PIPING");

else

    selectVariant(MEFuel,...
        "525 ABSENT");

end



% Generator fuel

if DieselGenerators

    selectVariant(GSFuel,...
        "526 GS FO PIPING");

else

    selectVariant(GSFuel,...
        "526 ABSENT");

end



% Mission fuel

if MissionFuel

    selectVariant(MissionFuelPipe,...
        "527 MISSION FO PIPING");

else

    selectVariant(MissionFuelPipe,...
        "527 ABSENT");

end



%% ================= SAVE ================================================

model.save();


disp("==============================")
disp("SHIP CONFIGURATION COMPLETE")
disp("==============================")


end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VARIANT SELECTION FUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function selectVariant(component,choiceName)


choices = component.getChoices();


for i = 1:length(choices)

    if strcmp(choices(i).Name,choiceName)

        component.setActiveChoice(choices(i));

        fprintf("%s --> %s\n",...
            component.Name,...
            choiceName);

        return

    end

end


disp("Available choices for:")
disp(component.Name)

for i = 1:length(choices)

    disp("   " + choices(i).Name)

end


error("Variant choice not found: %s",choiceName)


end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright"}
%---
