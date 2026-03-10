function extract_2d_slice(data_folder, freeze_axis, target_val)
    data_file = fullfile(data_folder, 'SimulationData.mat');
    
    if ~exist(data_file, 'file')
        error('Could not find SimulationData.mat in %s', data_folder); 
    end
    
    load(data_file); 
    
    if length(param_Z_values) == 1
        error('This data is already 2D or 1D. There is no 3D volume to slice!'); 
    end
    
    format_label = @(name) strrep(name, '_', ' ');

    switch upper(freeze_axis)
        case 'X'
            [~, idx] = min(abs(param_X_values - target_val)); 
            actual_val = param_X_values(idx); 
            frozen_name = param_X_name; 
            x_plot_vals = param_Z_values; x_name = param_Z_name; 
            y_plot_vals = param_Y_values; y_name = param_Y_name; 
            slice_1P = squeeze(map_1P(:, idx, :));
            
        case 'Y'
            [~, idx] = min(abs(param_Y_values - target_val)); 
            actual_val = param_Y_values(idx); 
            frozen_name = param_Y_name; 
            x_plot_vals = param_X_values; x_name = param_X_name; 
            y_plot_vals = param_Z_values; y_name = param_Z_name; 
            slice_1P = squeeze(map_1P(idx, :, :))'; 
            
        case 'Z'
            [~, idx] = min(abs(param_Z_values - target_val)); 
            actual_val = param_Z_values(idx); 
            frozen_name = param_Z_name; 
            x_plot_vals = param_X_values; x_name = param_X_name; 
            y_plot_vals = param_Y_values; y_name = param_Y_name; 
            slice_1P = squeeze(map_1P(:, :, idx));
            
        otherwise
            error('freeze_axis must be X, Y, or Z');
    end

    figure('Color', 'w', 'Position', [200, 200, 800, 600]); hold on; box on;
    contourf(x_plot_vals, y_plot_vals, slice_1P, 100, 'LineColor', 'none'); 
    colormap('parula'); c = colorbar; 
    c.Label.String = 'Target Yield: 1 Pristine GNR (%)'; c.Label.FontWeight = 'bold';
    
    title(sprintf('Cross-Section at %s = %g', format_label(frozen_name), actual_val), 'FontWeight', 'bold', 'FontSize', 14); 
    xlabel(format_label(x_name), 'FontWeight', 'bold', 'FontSize', 12); 
    ylabel(format_label(y_name), 'FontWeight', 'bold', 'FontSize', 12); axis tight;
    
    save_name = sprintf('2D_Slice_Fixed_%s_at_%g.png', upper(freeze_axis), actual_val); 
    save_path = fullfile(data_folder, save_name); 
    exportgraphics(gcf, save_path, 'Resolution', 300); 
    fprintf('Saved 2D slice plot to: %s\n', save_name);
end