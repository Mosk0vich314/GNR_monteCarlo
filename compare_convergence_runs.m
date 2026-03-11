function compare_convergence_runs()
    % =========================================================================
    % MULTI-CONVERGENCE OVERLAY TOOL (UI CHECKLIST VERSION)
    % =========================================================================
    clear; clc; close all;

    parent_dir = uigetdir('', 'Select the Parent Folder containing your Convergence runs');
    if isequal(parent_dir, 0); return; end

    % Find all folders starting with "Convergence_" or "00_Optimal_Convergence"
    items = dir(parent_dir);
    folder_names = {};
    for i = 1:length(items)
        if items(i).isdir && (contains(items(i).name, 'Convergence_') || contains(items(i).name, '00_Optimal'))
            folder_names{end+1} = items(i).name;
        end
    end

    if isempty(folder_names)
        fprintf('No Convergence folders found in this directory.\n'); return;
    end

    [selection_idx, ok] = listdlg('PromptString', 'Select Convergence runs to compare:', ...
                                  'SelectionMode', 'multiple', ...
                                  'ListString', folder_names, ...
                                  'Name', 'Overlay Convergence Plots', ...
                                  'ListSize', [600, 300]);
    if ~ok; return; end

    % Setup the Overlay Figure
    figure('Color', 'w', 'Position', [100, 100, 1000, 600]); 
    hold on; box on; grid on;
    colors = lines(length(selection_idx)); % distinct colors for each line
    
    max_trials = 0;
    
    fprintf('\nExtracting and Overlaying Data...\n');
    for i = 1:length(selection_idx)
        folder = folder_names{selection_idx(i)};
        data_file = fullfile(parent_dir, folder, 'Convergence_Data.mat');
        
        if ~exist(data_file, 'file')
            warning('Skipping %s: No Convergence_Data.mat found.', folder); continue;
        end
        
        S = load(data_file, 'cumulative_yield');
        yield_curve = S.cumulative_yield;
        trials = length(yield_curve);
        if trials > max_trials; max_trials = trials; end
        
        % Clean up the folder name for the legend
        leg_name = strrep(folder, 'Convergence_', ''); leg_name = strrep(leg_name, '_', ' ');
        
        plot(1:trials, yield_curve, 'LineWidth', 2, 'Color', colors(i,:), 'DisplayName', leg_name);
        % Plot the final value dot
        scatter(trials, yield_curve(end), 50, colors(i,:), 'filled', 'HandleVisibility', 'off');
    end

    title('Convergence Stability Comparison', 'FontWeight', 'bold', 'FontSize', 14);
    xlabel('Number of Simulated Trials', 'FontWeight', 'bold');
    ylabel('Cumulative Probability (%)', 'FontWeight', 'bold');
    xlim([0, max_trials * 1.05]);
    legend('Location', 'best', 'Interpreter', 'none');
    
    exportgraphics(gcf, fullfile(parent_dir, 'Overlay_Convergence_Comparison.png'), 'Resolution', 300);
    fprintf('Comparison plot saved as Overlay_Convergence_Comparison.png in the parent directory!\n');
end