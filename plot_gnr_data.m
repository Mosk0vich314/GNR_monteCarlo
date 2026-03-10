function plot_gnr_data(data_folder, generate_schematic)
    if nargin < 2
        generate_schematic = false; 
    end
    
    load(fullfile(data_folder, 'SimulationData.mat'));
    
    % --- LEGACY DATA FALLBACK ---
    if ~exist('param_X_values', 'var'); param_X_values = unique(X_grid)'; end
    if ~exist('param_Y_values', 'var'); param_Y_values = unique(Y_grid)'; end
    if exist('Z_grid', 'var') && ~exist('param_Z_values', 'var')
        param_Z_values = unique(Z_grid)'; 
    elseif ~exist('param_Z_values', 'var')
        param_Z_values = 1; param_Z_name = 'None'; Z_grid = ones(size(X_grid)); 
    end
    if ~exist('film_morphology', 'var'); film_morphology = 'polydomain'; end
    if ~exist('base_L_gap', 'var'); base_L_gap = 12; end
    if ~exist('base_apex_angle', 'var'); base_apex_angle = 30; end
    if ~exist('base_D_tip', 'var'); base_D_tip = 10; end
    if ~exist('base_L_gnr_mean', 'var'); base_L_gnr_mean = 40; end
    if ~exist('base_avg_domain_size', 'var'); base_avg_domain_size = 35; end
    if ~exist('base_target_angle', 'var'); base_target_angle = 0; end
    if ~exist('base_mean_defect_distance', 'var'); base_mean_defect_distance = 40; end
    if ~exist('L_gnr_std', 'var'); L_gnr_std = 20.0; end
    if ~exist('min_gnr_length', 'var'); min_gnr_length = 25; end
    if ~exist('gnr_spacing', 'var'); gnr_spacing = 1.5; end
    if ~exist('end_to_end_gap', 'var'); end_to_end_gap = 1.0; end
    if ~exist('angle_variance', 'var'); angle_variance = 4.0; end
    if ~exist('slide_step', 'var'); slide_step = 0.5; end
    % ----------------------------
    
    is_3D_sweep = length(param_Z_values) > 1; 
    is_1D_sweep = (length(param_X_values) == 1 || length(param_Y_values) == 1) && ~is_3D_sweep;
    
    label_map = containers.Map(...
        {'L_gap', 'apex_angle', 'D_tip', 'L_gnr_mean', 'avg_domain_size', 'target_angle', 'mean_defect_distance', 'L_gnr_std', 'min_gnr_length', 'gnr_spacing', 'end_to_end_gap', 'angle_variance', 'slide_step'}, ...
        {'Gap (nm)', 'Tip Angle (deg)', 'Tip Diam (nm)', 'GNR L (nm)', 'Domain Size (nm)', 'Align Angle (deg)', 'Defect Dist (nm)', 'Length Std Dev (nm)', 'Min Length (nm)', 'GNR Spacing (nm)', 'End-to-End Gap (nm)', 'Angle Variance (deg)', 'Slide Step (nm)'});
    
    mid_c = round(length(param_X_values)/2); x_mid = param_X_values(mid_c); 
    mid_r = round(length(param_Y_values)/2); y_mid = param_Y_values(mid_r); 
    mid_z = round(length(param_Z_values)/2); z_mid = param_Z_values(mid_z);

    if is_3D_sweep
        fprintf('Silently Plotting 3D Data...\n');
        num_slices = 3; 
        x_idx = unique(round(linspace(2, max(2, length(param_X_values)-1), num_slices))); 
        y_idx = unique(round(linspace(2, max(2, length(param_Y_values)-1), num_slices))); 
        z_idx = unique(round(linspace(2, max(2, length(param_Z_values)-1), num_slices))); 
        
        x_slices = param_X_values(x_idx); 
        y_slices = param_Y_values(y_idx); 
        z_slices = param_Z_values(z_idx);
        
        maps = {map_1P, map_1D, map_MP, map_MD}; 
        titles = {'1 Pristine GNR (Target)', '1 Defective GNR', '>1 Pristine GNRs (Short Circuit)', 'Multi-Bridge w/ Defects'}; 
        files = {'01_3D_1P.png', '02_3D_1D.png', '03_3D_MP.png', '04_3D_MD.png'};
        
        for m = 1:4
            current_map = maps{m}; 
            figure('Visible', 'off', 'Color', 'w', 'Position', [50, 50, 1400, 1000]); 
            sgtitle(titles{m}, 'FontSize', 18, 'FontWeight', 'bold');
            
            subplot(2, 3, 1); hold on; box on; 
            contourf(param_X_values, param_Y_values, current_map(:,:,mid_z), 100, 'LineColor', 'none'); 
            colormap('parula'); colorbar; 
            xlabel(label_map(param_X_name), 'FontWeight', 'bold'); ylabel(label_map(param_Y_name), 'FontWeight', 'bold'); 
            title(sprintf('%s = %g', label_map(param_Z_name), z_mid));
            
            subplot(2, 3, 2); hold on; box on; 
            contourf(param_X_values, param_Z_values, squeeze(current_map(mid_r, :, :))', 100, 'LineColor', 'none'); 
            colormap('parula'); colorbar; 
            xlabel(label_map(param_X_name), 'FontWeight', 'bold'); ylabel(label_map(param_Z_name), 'FontWeight', 'bold'); 
            title(sprintf('%s = %g', label_map(param_Y_name), y_mid));
            
            subplot(2, 3, 3); hold on; box on; 
            contourf(param_Y_values, param_Z_values, squeeze(current_map(:, mid_c, :))', 100, 'LineColor', 'none'); 
            colormap('parula'); colorbar; 
            xlabel(label_map(param_Y_name), 'FontWeight', 'bold'); ylabel(label_map(param_Z_name), 'FontWeight', 'bold'); 
            title(sprintf('%s = %g', label_map(param_X_name), x_mid));
            
            subplot(2, 3, [4, 5, 6]); hold on; box on; grid on; 
            h = slice(X_grid, Y_grid, Z_grid, current_map, x_slices, y_slices, z_slices); 
            set(h, 'EdgeColor', 'none', 'FaceColor', 'interp', 'FaceAlpha', 0.60); 
            axis tight; pbaspect([2 1.5 1.5]); view(-37.5, 30); camproj('orthographic'); 
            
            xl = xlim; dx = diff(xl) * 0.05; xlim([xl(1)-dx, xl(2)+dx]); 
            yl = ylim; dy = diff(yl) * 0.05; ylim([yl(1)-dy, yl(2)+dy]); 
            zl = zlim; dz = diff(zl) * 0.05; zlim([zl(1)-dz, zl(2)+dz]); 
            
            colormap('parula'); c = colorbar; c.Label.String = 'Probability (%)'; c.Label.FontWeight = 'bold'; 
            xlabel(label_map(param_X_name), 'FontWeight', 'bold'); ylabel(label_map(param_Y_name), 'FontWeight', 'bold'); zlabel(label_map(param_Z_name), 'FontWeight', 'bold'); 
            exportgraphics(gcf, fullfile(data_folder, files{m}), 'Resolution', 300); close(gcf); 
        end
    elseif is_1D_sweep
        sweep_vals = param_X_values; sweep_name = param_X_name; 
        if length(param_Y_values) > 1; sweep_vals = param_Y_values; sweep_name = param_Y_name; end
        
        figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 800, 600]); hold on; box on; 
        plot(sweep_vals, squeeze(map_1P), '-or', 'LineWidth', 2); 
        title('Target Yield: 1 Pristine GNR'); xlabel(label_map(sweep_name), 'FontWeight', 'bold'); ylabel('Yield (%)', 'FontWeight', 'bold'); 
        exportgraphics(gcf, fullfile(data_folder, '01_1D_Pristine.png'), 'Resolution', 300); close(gcf);
    else
        figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 900, 650]); 
        contourf(X_grid(:,:,1), Y_grid(:,:,1), map_1P(:,:,1), 100, 'LineColor', 'none'); 
        colormap('parula'); colorbar; 
        title('Target Yield: 1 Pristine GNR'); xlabel(label_map(param_X_name), 'FontWeight', 'bold'); ylabel(label_map(param_Y_name), 'FontWeight', 'bold'); 
        exportgraphics(gcf, fullfile(data_folder, '01_2D_Pristine.png'), 'Resolution', 300); close(gcf);
    end
    
    if generate_schematic
        fprintf('Calling external standalone generator to find optimal layout...\n');
        [~, max_idx] = max(map_1P(:)); 
        [best_r, best_c, best_z] = ind2sub(size(map_1P), max_idx); 
        opt_X = param_X_values(best_c); opt_Y = param_Y_values(best_r); opt_Z = param_Z_values(best_z);
        
        txt_path = fullfile(data_folder, '12_Optimal_Settings.txt'); 
        fid = fopen(txt_path, 'w'); 
        fprintf(fid, '=== OPTIMAL MANUFACTURING SETTINGS ===\nPeak Target Yield (1 Pristine GNR): %.1f%%\n\n--- Sweet Spot Parameters ---\n%s: %g\n%s: %g\n', map_1P(max_idx), label_map(param_X_name), opt_X, label_map(param_Y_name), opt_Y); 
        if is_3D_sweep; fprintf(fid, '%s: %g\n', label_map(param_Z_name), opt_Z); end
        fprintf(fid, '\n--- Failure Risks at this Peak ---\nDefective Bridges: %.1f%%\nShort Circuits (Multi-Pristine): %.1f%%\n', map_1D(max_idx), map_MP(max_idx)); 
        fclose(fid);
        
        L_gap = base_L_gap; apex_angle = base_apex_angle; D_tip = base_D_tip; 
        L_gnr_mean = base_L_gnr_mean; avg_domain_size = base_avg_domain_size; 
        target_angle = base_target_angle; mean_defect_distance = base_mean_defect_distance;
        
        switch param_X_name; case 'L_gap', L_gap=opt_X; case 'apex_angle', apex_angle=opt_X; case 'D_tip', D_tip=opt_X; case 'L_gnr_mean', L_gnr_mean=opt_X; case 'avg_domain_size', avg_domain_size=opt_X; case 'target_angle', target_angle=opt_X; case 'mean_defect_distance', mean_defect_distance=opt_X; case 'L_gnr_std', L_gnr_std=opt_X; case 'min_gnr_length', min_gnr_length=opt_X; case 'gnr_spacing', gnr_spacing=opt_X; case 'end_to_end_gap', end_to_end_gap=opt_X; case 'angle_variance', angle_variance=opt_X; case 'slide_step', slide_step=opt_X; end
        switch param_Y_name; case 'L_gap', L_gap=opt_Y; case 'apex_angle', apex_angle=opt_Y; case 'D_tip', D_tip=opt_Y; case 'L_gnr_mean', L_gnr_mean=opt_Y; case 'avg_domain_size', avg_domain_size=opt_Y; case 'target_angle', target_angle=opt_Y; case 'mean_defect_distance', mean_defect_distance=opt_Y; case 'L_gnr_std', L_gnr_std=opt_Y; case 'min_gnr_length', min_gnr_length=opt_Y; case 'gnr_spacing', gnr_spacing=opt_Y; case 'end_to_end_gap', end_to_end_gap=opt_Y; case 'angle_variance', angle_variance=opt_Y; case 'slide_step', slide_step=opt_Y; end
        switch param_Z_name; case 'L_gap', L_gap=opt_Z; case 'apex_angle', apex_angle=opt_Z; case 'D_tip', D_tip=opt_Z; case 'L_gnr_mean', L_gnr_mean=opt_Z; case 'avg_domain_size', avg_domain_size=opt_Z; case 'target_angle', target_angle=opt_Z; case 'mean_defect_distance', mean_defect_distance=opt_Z; case 'L_gnr_std', L_gnr_std=opt_Z; case 'min_gnr_length', min_gnr_length=opt_Z; case 'gnr_spacing', gnr_spacing=opt_Z; case 'end_to_end_gap', end_to_end_gap=opt_Z; case 'angle_variance', angle_variance=opt_Z; case 'slide_step', slide_step=opt_Z; end
        
        if is_3D_sweep
            title_str = sprintf('Optimal Layout | Yield: %.1f%% | %s: %g, %s: %g, %s: %g', map_1P(max_idx), label_map(param_X_name), opt_X, label_map(param_Y_name), opt_Y, label_map(param_Z_name), opt_Z); 
        else
            title_str = sprintf('Optimal Layout | Target Yield: %.1f%% | %s: %g, %s: %g', map_1P(max_idx), label_map(param_X_name), opt_X, label_map(param_Y_name), opt_Y); 
        end
        
        save_path = fullfile(data_folder, '10_Schematic_BestScenario.png');
        generate_gnr_schematic(L_gap, apex_angle, D_tip, L_gnr_mean, avg_domain_size, target_angle, mean_defect_distance, L_gnr_std, min_gnr_length, gnr_spacing, end_to_end_gap, angle_variance, slide_step, film_morphology, true, save_path, title_str);
    end
    fprintf('Plots successfully saved in %s\n', data_folder);
end