function sweep_info(data_folder)
    % =========================================================================
    % QUICK SWEEP INSPECTOR
    % =========================================================================
    
    % If no folder is provided, pop up a UI to select one
    if nargin < 1
        data_folder = uigetdir('', 'Select a SimRun folder to inspect');
        if isequal(data_folder, 0)
            fprintf('Operation canceled.\n');
            return;
        end
    end
    
    data_file = fullfile(data_folder, 'SimulationData.mat');
    if ~exist(data_file, 'file')
        error('Could not find SimulationData.mat in the specified folder.');
    end
    
    % Load only the variable names and sweep values to save RAM and time
    S = load(data_file, 'param_X_name', 'param_Y_name', 'param_Z_name', ...
                        'param_X_values', 'param_Y_values', 'param_Z_values', ...
                        'X_grid', 'Y_grid', 'Z_grid');
                        
    % Legacy fallback for older runs
    if ~isfield(S, 'param_X_values'); S.param_X_values = unique(S.X_grid)'; end
    if ~isfield(S, 'param_Y_values'); S.param_Y_values = unique(S.Y_grid)'; end
    if isfield(S, 'Z_grid') && ~isfield(S, 'param_Z_values'); S.param_Z_values = unique(S.Z_grid)'; end
    
    label_map = containers.Map(...
        {'L_gap', 'apex_angle', 'D_tip', 'L_gnr_mean', 'avg_domain_size', 'target_angle', 'mean_defect_distance', 'L_gnr_std', 'min_gnr_length', 'gnr_spacing', 'end_to_end_gap', 'angle_variance', 'slide_step'}, ...
        {'Gap (nm)', 'Tip Angle (deg)', 'Tip Diam (nm)', 'GNR L (nm)', 'Domain Size (nm)', 'Align Angle (deg)', 'Defect Dist (nm)', 'Length Std Dev (nm)', 'Min Length (nm)', 'GNR Spacing (nm)', 'End-to-End Gap (nm)', 'Angle Variance (deg)', 'Slide Step (nm)'});

    [~, folder_name, ~] = fileparts(data_folder);
    fprintf('\n==========================================\n');
    fprintf('SWEEP INSPECTOR: %s\n', folder_name);
    fprintf('==========================================\n');
    
    fprintf('X-Axis | %s:\n', label_map(S.param_X_name));
    fprintf('  Available Slices: %s\n\n', mat2str(S.param_X_values));
    
    if length(S.param_Y_values) > 1
        fprintf('Y-Axis | %s:\n', label_map(S.param_Y_name));
        fprintf('  Available Slices: %s\n\n', mat2str(S.param_Y_values));
    end
    
    if isfield(S, 'param_Z_values') && length(S.param_Z_values) > 1
        fprintf('Z-Axis | %s:\n', label_map(S.param_Z_name));
        fprintf('  Available Slices: %s\n\n', mat2str(S.param_Z_values));
    end
    
    fprintf('Copy-Paste Plotting Template:\n');
    fprintf('plot_gnr_data(''%s'', false, ''slice_x'', %g, ''slice_y'', %g);\n', folder_name, S.param_X_values(1), S.param_Y_values(1));
    fprintf('==========================================\n\n');
end