% GNR Contact Yield - Batch Controller & Plotting Master
clear; clc;

% =========================================================================
% EXPERIMENT 1: The Massive 3D Polydomain Run (Overnight)
% =========================================================================
% Sweeping Gap vs Defect vs Angle
trials = 250; 
morphology = 'aligned';

folder_1 = run_gnr_sweep('L_gap', 5:5:35, ...
                         'mean_defect_distance', 3:2:11, ...
                         'apex_angle', 10:30:100, ...
                         trials, morphology);

% Plot all the 3D slices immediately after it finishes
plot_gnr_data(folder_1);

%%
% =========================================================================
% EXPERIMENT 2: A quick 2D Run
% =========================================================================
trials = 50; 
morphology = 'aligned';

% Notice we leave Z ('D_tip') as a single number to make it a 2D sweep!
folder_2 = run_gnr_sweep('L_gap', 10:2:20, ...
                         'L_gnr_mean', 30:5:50, ...
                         'D_tip', [10], ...
                         trials, morphology);

plot_gnr_data(folder_2);

%%
% =========================================================================
% EXPERIMENT 3: Plotting Already Existing Data (No Simulation)
% =========================================================================
% If you already ran a simulation and just want to generate the plots again 
% (or if you accidentally closed the figures), just paste the folder name here!

existing_folder = 'SimRun_POLYDOMAIN_gnr_spacing_vs_mean_defect_distance_vs_apex_angle_20260224_031945'; % <-- Replace with your folder name

% use the 'true' flag to plot an example schematics too
plot_gnr_data(existing_folder);
% plot_gnr_data(existing_folder, true);

%%
% =========================================================================
% EXPERIMENT 4: The Physics Sandbox (Quick Check)
% =========================================================================
% Instantly generate and visualize one single layout to check physical parameters

% --- Core Parameters ---
L_gap = 25;
apex_angle = 30;
D_tip = 5;
L_gnr_mean = 35; 
avg_domain_size = 35;
target_angle = 0;
mean_defect_distance = 0;
morphology = 'polydomain';

% --- The Fine-Tuning Constraints ---
L_gnr_std = 10.0;     % Gamma distribution standard deviation
min_gnr_length = 4;  % Hard cutoff for smallest fragment
gnr_spacing = 1;    % Inter-ribbon spacing (lateral packing)
end_to_end_gap = 1.0; % Spacing between ribbons in the same track
angle_variance = 3.0; % Wobble alignment inside the domains
slide_step = 0.5;     % Granularity of the collision solver

% Mode 1: Quick visual check (displays on screen, does NOT search for bridges)
search_perfect = false; 
save_file = ''; % Leave empty to just show on screen

generate_gnr_schematic(L_gap, apex_angle, D_tip, L_gnr_mean, avg_domain_size, target_angle, mean_defect_distance, L_gnr_std, min_gnr_length, gnr_spacing, end_to_end_gap, angle_variance, slide_step, morphology, search_perfect, save_file);

%%
% =========================================================================
% EXPERIMENT 5: The Full Analyzer
% =========================================================================
% Go in depth with the analyisis of the simulation.mat files

to_analyzeFolder = 'SimRun_ALIGNED_gnr_spacing_vs_mean_defect_distance_vs_apex_angle_20260223_154744';
analyze_gnr_results(to_analyzeFolder);

%%
% =========================================================================
% QUICK VISUAL TEST (ROUNDED TIPS)
% =========================================================================

clear; clc; close all;

% --- Core Parameters ---
L_gap = 15;
apex_angle = 45;       
D_tip = 15;            % Set your rounded EBL resolution here
L_gnr_mean = 40;       
L_gnr_std = 20;        
avg_domain_size = 35;
target_angle = 0;
mean_defect_distance = 25;
morphology = 'aligned';

min_gnr_length = 10; 
gnr_spacing = 1.0;    
end_to_end_gap = 1.0; 
angle_variance = 2.0; 
slide_step = 0.5;     

% Instantly plot the new rounded schematic to screen
generate_gnr_schematic(L_gap, apex_angle, D_tip, L_gnr_mean, avg_domain_size, ...
    target_angle, mean_defect_distance, L_gnr_std, min_gnr_length, ...
    gnr_spacing, end_to_end_gap, angle_variance, slide_step, morphology, ...
    false, '');