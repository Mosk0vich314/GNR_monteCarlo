function compare_convergence_runs(parent_folders, run_labels, output_filename)
    if length(parent_folders) ~= length(run_labels)
        error('The number of folders must exactly match the number of labels.'); 
    end
    
    % Professional colorblind-friendly palette
    colors = [
        0.000, 0.447, 0.741; 
        0.850, 0.325, 0.098; 
        0.929, 0.694, 0.125; 
        0.494, 0.184, 0.556; 
        0.466, 0.674, 0.188
    ];
    
    figure('Color', 'w', 'Position', [150, 150, 900, 600]); hold on; box on; grid on; 
    legend_entries = cell(length(parent_folders), 1); 
    min_yield = 100; max_yield = 0;
    
    for i = 1:length(parent_folders)
        search_path = fullfile(parent_folders{i}, '00_Optimal_Convergence_*'); 
        found_folders = dir(search_path);
        
        if isempty(found_folders)
            warning('Could not find convergence folder in: %s. Skipping...', parent_folders{i}); 
            continue; 
        end
        
        conv_folder = fullfile(parent_folders{i}, found_folders(1).name); 
        data_file = fullfile(conv_folder, 'Convergence_Data.mat');
        
        if ~exist(data_file, 'file')
            warning('No Convergence_Data.mat inside %s. Skipping...', conv_folder); 
            continue; 
        end
        
        load(data_file, 'cumulative_yield'); 
        total_trials = length(cumulative_yield);
        eval_window = round(total_trials * 0.10); 
        final_yield = cumulative_yield(end); 
        std_dev = std(cumulative_yield(end-eval_window+1:end));
        
        plot(1:total_trials, cumulative_yield, 'LineWidth', 2, 'Color', colors(mod(i-1, size(colors,1))+1, :));
        legend_entries{i} = sprintf('%s (%.1f%% \\pm %.2f%%)', run_labels{i}, final_yield, std_dev);
        
        if final_yield < min_yield; min_yield = final_yield; end
        if final_yield > max_yield; max_yield = final_yield; end
    end
    
    title('Monte Carlo Convergence: Morphologies & Defect Densities', 'FontWeight', 'bold', 'FontSize', 16); 
    xlabel('Number of Simulated Trials', 'FontWeight', 'bold', 'FontSize', 14); 
    ylabel('Cumulative Target Yield (%)', 'FontWeight', 'bold', 'FontSize', 14);
    
    y_padding = max(5, (max_yield - min_yield) * 0.5); 
    ylim([max(0, min_yield - y_padding), min(100, max_yield + y_padding)]);
    
    leg = legend(legend_entries(~cellfun('isempty', legend_entries)), 'Location', 'best'); 
    leg.FontSize = 12;
    
    if nargin < 3 || isempty(output_filename)
        output_filename = 'Publication_Convergence_Comparison.png'; 
    end
    
    exportgraphics(gcf, output_filename, 'Resolution', 300); 
    fprintf('Comparison plot successfully saved as: %s\n', output_filename);
end