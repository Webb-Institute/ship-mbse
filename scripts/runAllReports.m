function runAllReports()

clc

fprintf('\n');
fprintf('==================================================================\n');
fprintf('                 SHIP MBSE REPORT GENERATOR                        \n');
fprintf('==================================================================\n\n');


%% Setup Paths

runnerPath = fileparts(mfilename('fullpath'));

fprintf('Runner Location:\n%s\n\n', runnerPath);


% Add plugin folder
pluginPath = fullfile(runnerPath,'plugins');

fprintf('Plugin Location:\n%s\n\n', pluginPath);

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

    fprintf('[SUCCESS] Model Loaded\n\n');

catch ME

    fprintf('FAILED TO LOAD MODEL:\n%s\n\n', ME.message);
    return

end



%% Reports To Run

reports = {
    'systemsReport.mlx'
    'verifyRequirementAllocations.mlx'
    'fuelAnalysis.mlx'
    'generateInterfaceReport.mlx'
    'GenerateWeightTableReport.mlx'
};



%% Execute Reports

for i = 1:length(reports)

    fprintf('------------------------------------------------------------\n');
    fprintf('RUNNING REPORT %d/%d: %s\n', i, length(reports), reports{i});
    fprintf('------------------------------------------------------------\n');


    try

        run(reports{i});

        fprintf('[SUCCESS] %s Complete\n\n', reports{i});


    catch ME

        fprintf('[FAILED] %s\n', reports{i});
        fprintf('%s\n\n', ME.message);

    end

end



%% Complete

fprintf('==================================================================\n');
fprintf('                 ALL REPORTS COMPLETE                             \n');
fprintf('==================================================================\n\n');


end