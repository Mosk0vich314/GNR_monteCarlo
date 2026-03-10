% =========================================================================
% GNR NEMATIC PHYSICS ENGINE - MASTER CONTROLLER
% =========================================================================

% ===========================================================================
% THE SWEEPABLE PARAMETERS CHEAT SHEET
% ===========================================================================
% You can sweep ANY of the parameters below across the X, Y, or Z axes.
% Any parameter you do NOT sweep will automatically use its Default Value.
% You can manually override ANY default value by adding it to the end of your 
% run_gnr_sweep() call as a Name-Value pair (e.g., ..., 'gnr_spacing', 0.5).
% 
% 'angle_variance'       [4.0]  : Local wobble/deviation from the domain's main orientation (deg)
% 'apex_angle'           [30.0] : The shape/sharpness of the electrodes (deg)
% 'avg_domain_size'      [35.0] : Average Voronoi grain size [polydomain only] (nm)
% 'D_tip'                [10.0] : The EBL manufacturing resolution limit (rounded tip diameter) (nm)
% 'end_to_end_gap'       [1.0]  : Spacing between ribbons placed sequentially in the same track (nm)
% 'gnr_spacing'          [1.5]  : Lateral distance between adjacent ribbons (packing density) (nm)
% 'L_gap'                [12.0] : Distance across the empty channel (nm)
% 'L_gnr_mean'           [40.0] : Target average length of the ribbons (nm)
% 'L_gnr_std'            [20.0] : Gamma distribution standard deviation for step-growth lengths (nm)
% 'mean_defect_distance' [40.0] : Average length of pristine segments before a defect (nm)
% 'min_gnr_length'       [25.0] : Absolute physical minimum length for a valid ribbon (nm)
% 'slide_step'           [0.5]  : Resolution of the collision solver (smaller = denser packing, slower) (nm)
% 'target_angle'         [0.0]  : Global alignment (0 = bridging gap) [aligned only] (deg)
% ===========================================================================


clear; clc;

% =========================================================================
% MODULE 1: THE PHYSICS SANDBOX (QUICK VISUAL CHECK)
% =========================================================================
% Highlight this block and press F9 to instantly generate one visual layout
% to verify your physical constraints without running a massive calculation.

% L_gap = 12;
% apex_angle = 30;
% D_tip = 10; % <-- EBL Resolution Limit (creates the rounded tips)
% L_gnr_mean = 40; 
% avg_domain_size = 35;
% target_angle = 0;
% mean_defect_distance = 40;
% L_gnr_std = 20.0;     
% min_gnr_length = 25;  
% gnr_spacing = 1.5;    
% end_to_end_gap = 1.0; 
% angle_variance = 4.0; 
% slide_step = 0.5;     
% morphology = 'polydomain';
% 
% % Set search_perfect to 'false' for an instant visual check
% generate_gnr_schematic(L_gap, apex_angle, D_tip, L_gnr_mean, avg_domain_size, ...
%     target_angle, mean_defect_distance, L_gnr_std, min_gnr_length, ...
%     gnr_spacing, end_to_end_gap, angle_variance, slide_step, morphology, false, '');


% =========================================================================
% MODULE 2: THE UNATTENDED QUEUE (FOR EULER)
% =========================================================================
% Uncomment and run this entire script to process multiple 128-core jobs safely.


fprintf('\n==========================================\n');
fprintf('STARTING BATCH QUEUE\n');
fprintf('==========================================\n');

% --- HARDWARE SETUP ---
num_convergence_trials = 50000;
num_workers = 128;

% --- RUN 1 ---
try
    fprintf('\n---> INITIATING RUN 1: ...\n');
    folder_1 = run_gnr_sweep('L_gnr_mean', 10:7.5:40, ...                            
                             'apex_angle', 10:20:110, ...
                             'L_gap', 5:7.5:35, ...
                             1000, 'aligned', ...
                             'D_tip', 10, ...  % <-- EBL rounded tip limit locked in
                             'angle_variance', 1.0, ...
                             'num_workers', num_workers, ...
                             'gnr_spacing', 0.2, ...
                             'mean_defect_distance', 0, ...
                             'L_gnr_std', 10, ...
                             'min_gnr_length', 5.0); 
                             
    plot_gnr_data(folder_1, true); 
    
    fprintf('---> INITIATING RUN 1: Auto-Convergence...\n');
    auto_convergence(folder_1, num_convergence_trials);
    fprintf('Run 1 Completed Successfully.\n');
catch ME
    warning('Run 1 Failed! Error: %s\nMoving to next run...', ME.message);
end

% --- RUN 2 ---
try
    fprintf('\n---> INITIATING RUN 2: ...\n');
    folder_2 = run_gnr_sweep('L_gnr_mean', 10:7.5:40, ...                            
                             'apex_angle', 10:15:115, ...
                             'L_gap', 2:3:14, ...
                             1000, 'polydomain', ...
                             'D_tip', 10, ...  % <-- EBL rounded tip limit locked in
                             'angle_variance', 2, ...
                             'num_workers', num_workers, ...
                             'gnr_spacing', 1, ...
                             'mean_defect_distance', 5, ...
                             'L_gnr_std', 10, ...
                             'min_gnr_length', 5.0); 
                             
    plot_gnr_data(folder_2, true); 
    
    fprintf('---> INITIATING RUN 2: Auto-Convergence...\n');
    auto_convergence(folder_2, num_convergence_trials);
    fprintf('Run 2 Completed Successfully.\n');
catch ME
    warning('Run 2 Failed! Error: %s\nMoving to next run...', ME.message);
end

% --- RUN 3 ---
try
    fprintf('\n---> INITIATING RUN 3: ...\n');
    folder_3 = run_gnr_sweep('L_gnr_mean', 10:7.5:40, ...                            
                             'apex_angle', 10:20:110, ...
                             'L_gap', 5:7.5:35, ...
                             1000, 'aligned', ...
                             'D_tip', 10, ...  % <-- EBL rounded tip limit locked in
                             'angle_variance', 1.0, ...
                             'num_workers', num_workers, ...
                             'gnr_spacing', 3.8, ...
                             'mean_defect_distance', 0, ...
                             'L_gnr_std', 10, ...
                             'min_gnr_length', 5.0); 
                             
    plot_gnr_data(folder_3, true); 
    
    fprintf('---> INITIATING RUN 3: Auto-Convergence...\n');
    auto_convergence(folder_3, num_convergence_trials);
    fprintf('Run 3 Completed Successfully.\n');
catch ME
    warning('Run 3 Failed! Error: %s\nMoving to next run...', ME.message);
end

% --- RUN 4 ---
try
    fprintf('\n---> INITIATING RUN 4: ...\n');
    folder_4 = run_gnr_sweep('L_gnr_mean', 10:7.5:40, ...                            
                             'apex_angle', 10:15:115, ...
                             'L_gap', 2:3:14, ...
                             1000, 'polydomain', ...
                             'D_tip', 10, ...  % <-- EBL rounded tip limit locked in
                             'angle_variance', 4, ...
                             'num_workers', num_workers, ...
                             'gnr_spacing', 1, ...
                             'mean_defect_distance', 10, ...
                             'L_gnr_std', 10, ...
                             'min_gnr_length', 5.0); 
                             
    plot_gnr_data(folder_4, true); 
    
    fprintf('---> INITIATING RUN 4: Auto-Convergence...\n');
    auto_convergence(folder_4, num_convergence_trials);
    fprintf('Run 4 Completed Successfully.\n');
catch ME
    warning('Run 4 Failed! Error: %s\nMoving to next run...', ME.message);
end

fprintf('\n==========================================\n');
fprintf('BATCH QUEUE COMPLETE. ALL DATA SAVED.\n');
fprintf('==========================================\n');

% =========================================================================
% MODULE 3: RE-PLOT EXISTING DATA
% =========================================================================
% % Paste a folder name here, highlight the line, and press F9 to re-generate plots.
% clear all; clc;
% parentFolder = 'newTipGeometry';
% dataFolder = 'SimRun_POLYDOMAIN_gnr_spacing_vs_apex_angle_vs_L_gap_20260226_103753';
% currentFolder = fullfile(parentFolder, dataFolder);
% plot_gnr_data(currentFolder, true);