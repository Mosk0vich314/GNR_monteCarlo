% =========================================================================
% BATCH PLOTTER FOR ALL SIMULATION FOLDERS
% =========================================================================

clear; clc; close all;

fprintf('\n==========================================\n');
fprintf('STARTING MASS DATA ANALYSIS\n');
fprintf('==========================================\n');

% 1. Open a UI dialog box to select the parent folder
parent_dir = uigetdir('', 'Select the folder containing your SimRun downloads');

% Check if the user clicked "Cancel"
if isequal(parent_dir, 0)
    fprintf('Operation canceled. No folder selected.\n');
    return;
end

fprintf('Target Directory: %s\n', parent_dir);

% 2. Find all folders in the selected directory that start with 'SimRun_'
search_path = fullfile(parent_dir, 'SimRun_*');
folders = dir(search_path);
success_count = 0;
fail_count = 0;

for i = 1:length(folders)
    if folders(i).isdir
        % Construct the absolute path to the specific SimRun folder
        target_folder = fullfile(parent_dir, folders(i).name);
        fprintf('\n---> Analyzing: %s\n', folders(i).name);
        
        % Check if the 128-core data file actually exists inside
        if ~exist(fullfile(target_folder, 'SimulationData.mat'), 'file')
            fprintf('Skipping: No SimulationData.mat found in this folder.\n');
            continue;
        end
        
        try
            % Call your existing plot function using the absolute path
            plot_gnr_data(target_folder, true);
            fprintf('Plots generated and saved successfully!\n');
            success_count = success_count + 1;
        catch ME
            warning('Failed to plot! Error: %s', ME.message);
            fail_count = fail_count + 1;
        end
        
        % Close figures to prevent your local PC's RAM from overloading
        close all; 
    end
end

fprintf('\n==========================================\n');
fprintf('BATCH ANALYSIS COMPLETE.\n');
fprintf('Successfully plotted: %d folders\n', success_count);
if fail_count > 0
    fprintf('Failed to plot: %d folders (Check warning logs above)\n', fail_count);
end
fprintf('==========================================\n');