function analyze_gnr_results(folder_path)
    % Deep Analysis of Raw GNR Nematic Simulation Data
    
    % --- UI FOLDER SELECTION FALLBACK ---
    if nargin < 1
        folder_path = uigetdir('', 'Select a SimRun folder to analyze');
        if isequal(folder_path, 0)
            fprintf('Analysis canceled.\n');
            return;
        end
    end
    % ------------------------------------

    % 1. Load the raw matrices
    data_file = fullfile(folder_path, 'SimulationData.mat');
    if ~exist(data_file, 'file')
        error('Could not find SimulationData.mat in the specified folder.');
    end
    load(data_file);
    
    fprintf('\n======================================================\n');
    fprintf('DEEP ANALYSIS: %s\n', param_X_name);
    fprintf('======================================================\n');

    % --- NEW: GENERATE THE PARAMETER LOG FILE ---
    txt_file = fullfile(folder_path, '00_Simulation_Parameters.txt');
    fid = fopen(txt_file, 'w');
    fprintf(fid, '======================================================\r\n');
    fprintf(fid, '             GNR SIMULATION PARAMETER LOG             \r\n');
    fprintf(fid, '======================================================\r\n\r\n');
    
    fprintf(fid, '--- SWEEP CONFIGURATION ---\r\n');
    fprintf(fid, 'Morphology:       %s\r\n', upper(film_morphology));
    fprintf(fid, 'Trials per Pixel: %d\r\n\r\n', trials_per_pixel);
    
    fprintf(fid, 'X-Axis Sweep:     %s [%g to %g, %d steps]\r\n', param_X_name, min(param_X_values), max(param_X_values), length(param_X_values));
    fprintf(fid, 'Y-Axis Sweep:     %s [%g to %g, %d steps]\r\n', param_Y_name, min(param_Y_values), max(param_Y_values), length(param_Y_values));
    if length(param_Z_values) > 1
        fprintf(fid, 'Z-Axis Sweep:     %s [%g to %g, %d steps]\r\n', param_Z_name, min(param_Z_values), max(param_Z_values), length(param_Z_values));
    else
        fprintf(fid, 'Z-Axis Sweep:     None\r\n');
    end
    
    fprintf(fid, '\r\n--- STATIC / DEFAULT PARAMETERS ---\r\n');
    fprintf(fid, '(Variables swept above override these defaults)\r\n\r\n');
    
    % Macro Device Geometry
    fprintf(fid, 'L_gap:                %g nm\r\n', base_L_gap);
    fprintf(fid, 'apex_angle:           %g deg\r\n', base_apex_angle);
    fprintf(fid, 'D_tip:                %g nm\r\n\r\n', base_D_tip);
    
    % Nanoribbon Statistics (Gamma Distribution)
    fprintf(fid, 'L_gnr_mean:           %g nm (Target Gamma Mean)\r\n', base_L_gnr_mean);
    fprintf(fid, 'L_gnr_std:            %g nm (Target Gamma Std)\r\n', L_gnr_std);
    fprintf(fid, 'min_gnr_length:       %g nm\r\n\r\n', min_gnr_length);
    
    % Film Morphology & Spacing Constraints
    fprintf(fid, 'avg_domain_size:      %g nm\r\n', base_avg_domain_size);
    fprintf(fid, 'target_angle:         %g deg\r\n', base_target_angle);
    fprintf(fid, 'angle_variance:       %g deg\r\n', angle_variance);
    fprintf(fid, 'gnr_spacing:          %g nm\r\n', gnr_spacing);
    fprintf(fid, 'end_to_end_gap:       %g nm\r\n', end_to_end_gap);
    fprintf(fid, 'mean_defect_distance: %g nm\r\n', base_mean_defect_distance);
    fprintf(fid, 'slide_step:           %g nm\r\n', slide_step);
    
    fclose(fid);
    fprintf('-> Saved clean parameter log to: 00_Simulation_Parameters.txt\n\n');
    % --------------------------------------------

    % --- METRIC 1: THE ABSOLUTE PEAK ---
    [max_yield, max_idx] = max(map_1P(:));
    [best_r, best_c, best_z] = ind2sub(size(map_1P), max_idx);
    
    opt_X = param_X_values(best_c);
    opt_Y = param_Y_values(best_r);
    opt_Z = param_Z_values(best_z);
    
    fprintf('1. ABSOLUTE MAXIMUM TARGET YIELD\n');
    fprintf('   Max Yield:      %.1f%%\n', max_yield);
    fprintf('   %s: %g\n', param_X_name, opt_X);
    fprintf('   %s: %g\n', param_Y_name, opt_Y);
    if length(param_Z_values) > 1
        fprintf('   %s: %g\n', param_Z_name, opt_Z);
    end
    fprintf('   (At this peak: %g%% Defective, %g%% Multi-Pristine)\n\n', ...
        map_1D(max_idx), map_MP(max_idx));

    % --- METRIC 2: THE SAFE PROCESS WINDOW ---
    target_min_yield = 60.0;
    max_allowed_defects = 10.0;
    
    safe_zone = (map_1P >= target_min_yield) & ((map_1D + map_MD) <= max_allowed_defects);
    num_safe_configs = sum(safe_zone(:));
    
    fprintf('2. MANUFACTURING PROCESS WINDOW\n');
    fprintf('   Criteria: >%g%% Target Yield, <%g%% Defect/Shorts\n', target_min_yield, max_allowed_defects);
    
    if num_safe_configs > 0
        fprintf('   Found %d safe parameter combinations.\n', num_safe_configs);
        valid_X = X_grid(safe_zone);
        valid_Y = Y_grid(safe_zone);
        fprintf('   Safe %s range: [%g to %g]\n', param_X_name, min(valid_X), max(valid_X));
        fprintf('   Safe %s range: [%g to %g]\n\n', param_Y_name, min(valid_Y), max(valid_Y));
    else
        fprintf('   WARNING: No parameters meet this strict safety criteria.\n\n');
    end

    % --- METRIC 3: 1D SENSITIVITY CROSS-SECTION (DYNAMIC UI) ---
    fprintf('3. SENSITIVITY PROFILE AROUND OPTIMUM\n');
    
    % Determine which variables were actually swept
    is_2d = length(param_Y_values) > 1;
    is_3d = exist('param_Z_values', 'var') && length(param_Z_values) > 1;
    
    % Ask the user which axis to plot
    if is_3d
        choice = questdlg('Which parameter do you want to plot for the sensitivity profile?', ...
            'Select Sensitivity Axis', param_X_name, param_Y_name, param_Z_name, param_X_name);
    elseif is_2d
        choice = questdlg('Which parameter do you want to plot for the sensitivity profile?', ...
            'Select Sensitivity Axis', param_X_name, param_Y_name, param_X_name);
    else
        choice = param_X_name; % Only 1D, so default to X
    end
    
    % Extract the correct 1D slice based on user choice
    figure('Color', 'w', 'Position', [200, 200, 700, 500]);
    hold on; box on; grid on;
    
    switch choice
        case param_X_name
            slice_1P = squeeze(map_1P(best_r, :, best_z));
            slice_MP = squeeze(map_MP(best_r, :, best_z));
            slice_1D = squeeze(map_1D(best_r, :, best_z));
            sweep_vals = param_X_values;
            title_str = sprintf('Sensitivity (Fixed %s=%g', strrep(param_Y_name, '_', ' '), opt_Y);
            if is_3d; title_str = [title_str, sprintf(', %s=%g)', strrep(param_Z_name, '_', ' '), opt_Z)]; else; title_str = [title_str, ')']; end
            
        case param_Y_name
            slice_1P = squeeze(map_1P(:, best_c, best_z));
            slice_MP = squeeze(map_MP(:, best_c, best_z));
            slice_1D = squeeze(map_1D(:, best_c, best_z));
            sweep_vals = param_Y_values;
            title_str = sprintf('Sensitivity (Fixed %s=%g', strrep(param_X_name, '_', ' '), opt_X);
            if is_3d; title_str = [title_str, sprintf(', %s=%g)', strrep(param_Z_name, '_', ' '), opt_Z)]; else; title_str = [title_str, ')']; end
            
        case param_Z_name
            slice_1P = squeeze(map_1P(best_r, best_c, :));
            slice_MP = squeeze(map_MP(best_r, best_c, :));
            slice_1D = squeeze(map_1D(best_r, best_c, :));
            sweep_vals = param_Z_values;
            title_str = sprintf('Sensitivity (Fixed %s=%g, %s=%g)', strrep(param_X_name, '_', ' '), opt_X, strrep(param_Y_name, '_', ' '), opt_Y);
    end
    
    % Plot the selected slice
    plot(sweep_vals, slice_1P, '-o', 'LineWidth', 2.5, 'Color', 'r', 'DisplayName', '1 Pristine (Target)');
    plot(sweep_vals, slice_MP, '--s', 'LineWidth', 1.5, 'Color', [0.6 0 0.8], 'DisplayName', 'Multi-Pristine (Short)');
    plot(sweep_vals, slice_1D, '-.^', 'LineWidth', 1.5, 'Color', 'b', 'DisplayName', 'Defective');
    
    % Mark the exact optimal peak
    plot(choice == param_X_name * opt_X + choice == param_Y_name * opt_Y + choice == param_Z_name * opt_Z, ... % Math trick to get the right opt value
         max_yield, 'k*', 'MarkerSize', 12, 'HandleVisibility', 'off');
    
    xlabel(strrep(choice, '_', ' '), 'FontWeight', 'bold');
    ylabel('Probability (%)', 'FontWeight', 'bold');
    title(title_str);
    legend('Location', 'best');
    
    xl = xlim; dx = diff(xl) * 0.05; xlim([xl(1)-dx, xl(2)+dx]);
    yl = ylim; dy = diff(yl) * 0.05; ylim([yl(1)-dy, yl(2)+dy]);
    
    exportgraphics(gcf, fullfile(folder_path, sprintf('11_Sensitivity_Analysis_%s.png', choice)), 'Resolution', 300);
    fprintf('   Saved sensitivity plot to folder as 11_Sensitivity_Analysis_%s.png\n', choice);
    fprintf('======================================================\n');
end