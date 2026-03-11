% =========================================================================
% QUICK MULTI-FOLDER PLOTTER (CHECKLIST MENU VERSION)
% =========================================================================
clear; clc; close all;

fprintf('\n==========================================\n');
fprintf('--- SELECT RUNS TO PLOT ---\n');
fprintf('==========================================\n\n');

% 1. Ask the user for the parent directory where all the runs are stored
parent_dir = uigetdir('', 'Select the Parent Folder containing your SimRun folders');

% Check if the user clicked "Cancel"
if isequal(parent_dir, 0)
    fprintf('Operation canceled. No parent folder selected.\n');
    return;
end

% 2. Automatically find all 'SimRun_' folders inside that directory
search_path = fullfile(parent_dir, 'SimRun_*');
items = dir(search_path);

folder_names = {};
for i = 1:length(items)
    if items(i).isdir
        folder_names{end+1} = items(i).name;
    end
end

if isempty(folder_names)
    fprintf('No "SimRun_" folders found inside the selected directory.\n');
    return;
end

% 3. Pop up a checklist menu so you can cherry-pick the runs
[selection_idx, ok] = listdlg('PromptString', 'Select the runs you want to plot (Hold CTRL or Shift to pick multiple):', ...
                              'SelectionMode', 'multiple', ...
                              'ListString', folder_names, ...
                              'Name', 'Select Runs to Plot', ...
                              'ListSize', [600, 300]);

% Check if the user clicked "Cancel" on the menu
if ~ok
    fprintf('Operation canceled. No runs selected.\n');
    return;
end

success_count = 0;
fail_count = 0;

fprintf('\nStarting plotting sequence...\n');

% 4. Loop through ONLY the runs you selected from the menu
for i = 1:length(selection_idx)
    selected_folder = folder_names{selection_idx(i)};
    full_folder_path = fullfile(parent_dir, selected_folder);
    data_file = fullfile(full_folder_path, 'SimulationData.mat');
    
    fprintf('\n---> Analyzing: %s\n', selected_folder);
    
    if ~exist(data_file, 'file')
        warning('     Skipping: No SimulationData.mat found inside this folder.');
        continue;
    end
    
    try
        % Call your upgraded plotting function! (true = generate schematic)
        plot_gnr_data(full_folder_path, true);
        fprintf('     Plots successfully generated and saved.\n');
        success_count = success_count + 1;
    catch ME
        warning('     Failed to plot! Error: %s', ME.message);
        fail_count = fail_count + 1;
    end
    
    % Close all invisible figures to prevent your PC's RAM from overloading
    close all; 
end

fprintf('\n==========================================\n');
fprintf('BATCH PLOTTING COMPLETE.\n');
fprintf('Successfully plotted: %d folders\n', success_count);
if fail_count > 0
    fprintf('Failed to plot: %d folders (Check logs above)\n', fail_count);
end
fprintf('==========================================\n');