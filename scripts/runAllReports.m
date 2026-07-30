function runAllReports()

clc

fprintf('\n');
fprintf('==================================================================\n');
fprintf('                 SHIP MBSE REPORT GENERATOR                        \n');
fprintf('==================================================================\n\n');


%% Setup Paths

runnerPath = fileparts(mfilename('fullpath'));

fprintf('Project Root Initialized:\n%s\n\n', runnerPath);


% Add plugin folder
pluginPath = fullfile(runnerPath,'plugins');

if isfolder(pluginPath)

    addpath(pluginPath);

else

    fprintf('FAILED: Plugin folder not found:\n%s\n', pluginPath);
    return

end



%% Load Model

modelName = 'SYSTEM';

fprintf('Loading System Composer Model: %s\n\n', modelName);

try

    if ~bdIsLoaded(modelName)
        open_system(modelName);
    end

    systemcomposer.loadModel(modelName);

catch ME

    fprintf('FAILED TO LOAD MODEL:\n%s\n\n', ME.message);
    return

end



%% REPORT 1

fprintf('------------------------------------------------------------\n');
fprintf('RUNNING REPORT 1/5: System Report\n');
fprintf('------------------------------------------------------------\n');

try

    systemsReport();

    fprintf('[SUCCESS] System Report Complete\n\n');

catch ME

    fprintf('[FAILED] System Report:\n%s\n\n', ME.message);

end



%% REPORT 2

fprintf('------------------------------------------------------------\n');
fprintf('RUNNING REPORT 2/5: Requirement Allocation Verification\n');
fprintf('------------------------------------------------------------\n');

try

    verifyRequirementAllocations();

    fprintf('[SUCCESS] Requirement Verification Complete\n\n');

catch ME

    fprintf('[FAILED] Requirement Verification:\n%s\n\n', ME.message);

end



%% REPORT 3

fprintf('------------------------------------------------------------\n');
fprintf('RUNNING REPORT 3/5: Fuel Analysis\n');
fprintf('------------------------------------------------------------\n');

try

    fuelAnalysis();

    fprintf('[SUCCESS] Fuel Analysis Complete\n\n');

catch ME

    fprintf('[FAILED] Fuel Analysis:\n%s\n\n', ME.message);

end



%% REPORT 4

fprintf('------------------------------------------------------------\n');
fprintf('RUNNING REPORT 4/5: Interface Report\n');
fprintf('------------------------------------------------------------\n');

try

    reportTable = generateInterfaceReport();

    fprintf('[SUCCESS] Interface Report Complete\n\n');

catch ME

    fprintf('[FAILED] Interface Report:\n%s\n\n', ME.message);

end



%% REPORT 5

fprintf('------------------------------------------------------------\n');
fprintf('RUNNING REPORT 5/5: Weight Report\n');
fprintf('------------------------------------------------------------\n');

try

    weightTable = GenerateWeightTableReport();

    fprintf('[SUCCESS] Weight Report Complete\n');
    fprintf('Components Reported: %d\n\n', height(weightTable));

catch ME

    fprintf('[FAILED] Weight Report:\n%s\n\n', ME.message);

end



%% COMPLETE

fprintf('==================================================================\n');
fprintf('                 ALL REPORTS COMPLETE                             \n');
fprintf('==================================================================\n\n');


end