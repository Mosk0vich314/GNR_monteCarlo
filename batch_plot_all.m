% =========================================================================
% BATCH PLOTTER FOR ALL SIMULATION FOLDERS
% =========================================================================

clear; clc; close all;

fprintf('\n==========================================\n');
fprintf('STARTING MASS DATA ANALYSIS\n');
fprintf('==========================================\n');

% Find all folders in the current directory that start with 'SimRun_'
folders = dir('SimRun_*');
success_count = 0;
fail_count = 0;

for i = 1:length(folders)
    if folders(i).isdir
        target_folder = folders(i).name;
        fprintf('\n---> Analyzing Folder: %s\n', target_folder);
        
        % Check if the 128-core data file actually exists inside
        if ~exist(fullfile(target_folder, 'SimulationData.mat'), 'file')
            fprintf('Skipping: No SimulationData.mat found in this folder.\n');
            continue;
        end
        
        try
            % Call your existing plot function and tell it to save the figures (true)
            plot_gnr_data(target_folder, true);
            fprintf('Plots generated and saved successfully!\n');
            success_count = success_count + 1;
        catch ME
            warning('Failed to plot %s! Error: %s', target_folder, ME.message);
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