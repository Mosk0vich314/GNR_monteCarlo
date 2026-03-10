% =========================================================================
% THE MONOLITH RESCUE SCRIPT (ZERO DEPENDENCIES)
% =========================================================================
clear; clc;

num_trials = 50000;
desired_workers = 128;

fprintf('\n==========================================\n');
fprintf('STARTING MONOLITHIC RESCUE OPERATION\n');
fprintf('==========================================\n');

% --- 1. START THE POOL ONCE ---
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
myCluster = parcluster('local');
job_folder = sprintf('%s/matlab_pool_monolith_%s', tempdir, timestamp);
if ~exist(job_folder, 'dir'); mkdir(job_folder); end
myCluster.JobStorageLocation = job_folder;

poolobj = gcp('nocreate');
if isempty(poolobj) || poolobj.NumWorkers ~= desired_workers
    delete(gcp('nocreate'));
    fprintf('Booting %d workers...\n', desired_workers);
    parpool(myCluster, desired_workers);
else
    fprintf('Workers already alive.\n');
end

% --- 2. LOOP OVER FOLDERS ---
folders = dir('SimRun_*');

for f_idx = 1:length(folders)
    if ~folders(f_idx).isdir; continue; end
    data_folder = folders(f_idx).name;

    % Skip if already done
    conv_folder_name = sprintf('00_Optimal_Convergence_%dk', round(num_trials/1000));
    conv_folder = fullfile(data_folder, conv_folder_name);
    if exist(fullfile(conv_folder, 'Convergence_Data.mat'), 'file')
        fprintf('Skipping %s (Already rescued)\n', data_folder);
        continue;
    end

    fprintf('\n---> Rescuing: %s\n', data_folder);

    % --- 3. READ DATA SAFELY ---
    data_file = fullfile(data_folder, 'SimulationData.mat');
    if ~exist(data_file, 'file'); continue; end

    % Load into a struct to prevent workspace corruption
    S = load(data_file);

    [~, max_idx] = max(S.map_1P(:));
    [best_r, best_c, best_z] = ind2sub(size(S.map_1P), max_idx);

    opt_X = S.param_X_values(best_c);
    opt_Y = S.param_Y_values(best_r);
    if length(S.param_Z_values) > 1; opt_Z = S.param_Z_values(best_z); else; opt_Z = S.param_Z_values(1); end

    L_gap = S.base_L_gap; apex_angle = S.base_apex_angle; D_tip = S.base_D_tip;
    L_gnr_mean = S.base_L_gnr_mean; avg_domain_size = S.base_avg_domain_size;
    target_angle = S.base_target_angle; mean_defect_distance = S.base_mean_defect_distance;
    L_gnr_std = S.L_gnr_std; min_gnr_length = S.min_gnr_length;
    gnr_spacing = S.gnr_spacing; end_to_end_gap = S.end_to_end_gap;
    angle_variance = S.angle_variance; slide_step = S.slide_step;
    film_morphology = S.film_morphology;

    switch S.param_X_name; case 'L_gap', L_gap=opt_X; case 'apex_angle', apex_angle=opt_X; case 'D_tip', D_tip=opt_X; case 'L_gnr_mean', L_gnr_mean=opt_X; case 'avg_domain_size', avg_domain_size=opt_X; case 'target_angle', target_angle=opt_X; case 'mean_defect_distance', mean_defect_distance=opt_X; case 'L_gnr_std', L_gnr_std=opt_X; case 'min_gnr_length', min_gnr_length=opt_X; case 'gnr_spacing', gnr_spacing=opt_X; case 'end_to_end_gap', end_to_end_gap=opt_X; case 'angle_variance', angle_variance=opt_X; case 'slide_step', slide_step=opt_X; end
    switch S.param_Y_name; case 'L_gap', L_gap=opt_Y; case 'apex_angle', apex_angle=opt_Y; case 'D_tip', D_tip=opt_Y; case 'L_gnr_mean', L_gnr_mean=opt_Y; case 'avg_domain_size', avg_domain_size=opt_Y; case 'target_angle', target_angle=opt_Y; case 'mean_defect_distance', mean_defect_distance=opt_Y; case 'L_gnr_std', L_gnr_std=opt_Y; case 'min_gnr_length', min_gnr_length=opt_Y; case 'gnr_spacing', gnr_spacing=opt_Y; case 'end_to_end_gap', end_to_end_gap=opt_Y; case 'angle_variance', angle_variance=opt_Y; case 'slide_step', slide_step=opt_Y; end
    switch S.param_Z_name; case 'L_gap', L_gap=opt_Z; case 'apex_angle', apex_angle=opt_Z; case 'D_tip', D_tip=opt_Z; case 'L_gnr_mean', L_gnr_mean=opt_Z; case 'avg_domain_size', avg_domain_size=opt_Z; case 'target_angle', target_angle=opt_Z; case 'mean_defect_distance', mean_defect_distance=opt_Z; case 'L_gnr_std', L_gnr_std=opt_Z; case 'min_gnr_length', min_gnr_length=opt_Z; case 'gnr_spacing', gnr_spacing=opt_Z; case 'end_to_end_gap', end_to_end_gap=opt_Z; case 'angle_variance', angle_variance=opt_Z; case 'slide_step', slide_step=opt_Z; end

    if ~exist(conv_folder, 'dir'); mkdir(conv_folder); end

    gamma_theta = (L_gnr_std^2) / L_gnr_mean;
    gamma_k = (L_gnr_mean^2) / (L_gnr_std^2);

    R = D_tip / 2; half_angle = apex_angle / 2; xc_L = -L_gap/2 - R; xc_R = L_gap/2 + R;
    sim_limit = L_gap + D_tip + max(L_gnr_mean, 40);
    xt_L = xc_L - R*sind(half_angle); xt_R = xc_R + R*sind(half_angle);

    out_Np = zeros(num_trials, 1); out_Nd = zeros(num_trials, 1);

    fprintf('Running %d %s physics collisions...\n', num_trials, film_morphology);

    % --- 4. THE PARFOR LOOP (NO EXTERNAL DEPENDENCIES) ---
    parfor i = 1:num_trials
        GNR_X1 = []; GNR_X2 = []; GNR_Y1 = []; GNR_Y2 = [];
        DEF_X = {}; DEF_Y = {}; domains = {};
        MAX_PTS = 300000; GLOBAL_PTS = zeros(MAX_PTS, 2); global_pt_idx = 0;

        if strcmp(film_morphology, 'polydomain')
            area_total = (sim_limit * 4)^2; num_seeds = round(area_total / (avg_domain_size^2));
            seed_x = (rand(num_seeds, 1) - 0.5) * sim_limit * 4; seed_y = (rand(num_seeds, 1) - 0.5) * sim_limit * 4;
            [V, C] = voronoin([seed_x, seed_y]);
            for v_idx = 1:length(C)
                if any(C{v_idx} == 1); continue; end
                vx = V(C{v_idx}, 1); vy = V(C{v_idx}, 2);
                if min(vx) > sim_limit || max(vx) < -sim_limit || min(vy) > sim_limit || max(vy) < -sim_limit; continue; end
                domains{end+1}.vx = vx; domains{end}.vy = vy; domains{end}.theta = rand() * pi;
            end
        else
            bound = sim_limit * 2; domains{1}.vx = [-bound; bound; bound; -bound];
            domains{1}.vy = [-bound; -bound; bound; bound]; domains{1}.theta = target_angle * (pi/180);
        end

        for d = 1:length(domains)
            vx = domains{d}.vx; vy = domains{d}.vy; theta_base = domains{d}.theta; cos_base = cos(theta_base); sin_base = sin(theta_base);
            cx = mean(vx); cy = mean(vy); diag_len = min(sqrt((max(vx)-min(vx))^2 + (max(vy)-min(vy))^2), sim_limit*3);
            y_local = (-diag_len : gnr_spacing : diag_len) + (rand() * gnr_spacing);
            for k = 1:length(y_local)
                curr_local_x = -diag_len + rand() * L_gnr_mean;
                cand_L = max(gamrnd(gamma_k, gamma_theta), min_gnr_length);
                theta_r = theta_base + (randn() * angle_variance) * (pi/180); safety_counter = 0;
                while curr_local_x < diag_len
                    safety_counter = safety_counter + 1; if safety_counter > 2000; break; end
                    frag_cx = cx + (curr_local_x + cand_L/2) * cos_base - y_local(k) * sin_base;
                    frag_cy = cy + (curr_local_x + cand_L/2) * sin_base + y_local(k) * cos_base;
                    r_x1 = frag_cx - (cand_L/2) * cos(theta_r); r_y1 = frag_cy - (cand_L/2) * sin(theta_r);
                    r_x2 = frag_cx + (cand_L/2) * cos(theta_r); r_y2 = frag_cy + (cand_L/2) * sin(theta_r);
                    c_x1 = 0; c_y1 = 0; c_x2 = 0; c_y2 = 0; clip_len = 0; is_valid = false; placed = false; valid_clip = false;

                    if strcmp(film_morphology, 'aligned')
                        c_x1=r_x1; c_y1=r_y1; c_x2=r_x2; c_y2=r_y2; clip_len=cand_L; valid_clip=true;
                    else
                        in_ends = inpolygon([r_x1, r_x2], [r_y1, r_y2], vx, vy);
                        if in_ends(1) && in_ends(2)
                            c_x1 = r_x1; c_y1 = r_y1; c_x2 = r_x2; c_y2 = r_y2; clip_len = cand_L; valid_clip = true;
                        else
                            pts = 20; xq = linspace(r_x1, r_x2, pts); yq = linspace(r_y1, r_y2, pts);
                            in = inpolygon(xq, yq, vx, vy);
                            if any(in)
                                idx = find(in); c_x1 = xq(idx(1)); c_y1 = yq(idx(1)); c_x2 = xq(idx(end)); c_y2 = yq(idx(end));
                                clip_len = sqrt((c_x2 - c_x1)^2 + (c_y2 - c_y1)^2); valid_clip = true;
                            end
                        end
                    end

                    if valid_clip && clip_len >= min_gnr_length
                        n_pts = ceil(clip_len / 0.5); cand_pts_x = linspace(c_x1, c_x2, n_pts)'; cand_pts_y = linspace(c_y1, c_y2, n_pts)'; is_valid = true;
                        if global_pt_idx > 0
                            idx_start = max(1, global_pt_idx - 4000);
                            recent_x = GLOBAL_PTS(idx_start:global_pt_idx, 1); recent_y = GLOBAL_PTS(idx_start:global_pt_idx, 2);
                            min_x = min(cand_pts_x) - 1.5; max_x = max(cand_pts_x) + 1.5;
                            min_y = min(cand_pts_y) - 1.5; max_y = max(cand_pts_y) + 1.5;
                            valid_mask = recent_x > min_x & recent_x < max_x & recent_y > min_y & recent_y < max_y;
                            if any(valid_mask)
                                obs_x = recent_x(valid_mask); obs_y = recent_y(valid_mask);
                                dx = cand_pts_x - obs_x'; dy = cand_pts_y - obs_y';
                                if any((dx.^2 + dy.^2) < 2.1025, 'all'); is_valid = false; end
                            end
                        end
                        if is_valid
                            GNR_X1(end+1) = c_x1; GNR_Y1(end+1) = c_y1; GNR_X2(end+1) = c_x2; GNR_Y2(end+1) = c_y2;
                            GLOBAL_PTS(global_pt_idx+1 : global_pt_idx+n_pts, 1) = cand_pts_x;
                            GLOBAL_PTS(global_pt_idx+1 : global_pt_idx+n_pts, 2) = cand_pts_y;
                            global_pt_idx = global_pt_idx + n_pts;

                            d_x_list = []; d_y_list = [];
                            if mean_defect_distance > 0
                                min_defect_spacing = 1.0; eff_mean = max(0.1, mean_defect_distance - min_defect_spacing);
                                local_positions = []; curr_d = -eff_mean * log(rand());
                                while curr_d < clip_len
                                    local_positions(end+1) = curr_d; curr_d = curr_d + min_defect_spacing - eff_mean * log(rand());
                                end
                                if ~isempty(local_positions)
                                    local_pos = (local_positions') / clip_len;
                                    d_x_list = c_x1 + local_pos * (c_x2 - c_x1); d_y_list = c_y1 + local_pos * (c_y2 - c_y1);
                                end
                            end
                            DEF_X{end+1} = d_x_list; DEF_Y{end+1} = d_y_list; placed = true;
                        end
                    end
                    if placed
                        curr_local_x = curr_local_x + cand_L + end_to_end_gap;
                        cand_L = max(gamrnd(gamma_k, gamma_theta), min_gnr_length);
                        theta_r = theta_base + (randn() * angle_variance) * (pi/180);
                    else
                        curr_local_x = curr_local_x + slide_step;
                    end
                end
            end
        end

        b_p = 0; b_d = 0;
        for k = 1:length(GNR_X1)
            xx = linspace(GNR_X1(k), GNR_X2(k), 10); yy = linspace(GNR_Y1(k), GNR_Y2(k), 10);
            hit_L = any(((xx-xc_L).^2+yy.^2<=R^2 & xx>=xt_L) | (xx<xt_L & abs(yy)<=R*cosd(half_angle)+(xt_L-xx)*tand(half_angle)));
            hit_R = any(((xx-xc_R).^2+yy.^2<=R^2 & xx<=xt_R) | (xx>xt_R & abs(yy)<=R*cosd(half_angle)+(xx-xt_R)*tand(half_angle)));
            if hit_L && hit_R
                channel_defects = 0; d_x = DEF_X{k}; d_y = DEF_Y{k};
                for def = 1:length(d_x)
                    def_in_L = ((d_x(def)-xc_L)^2+d_y(def)^2<=R^2 & d_x(def)>=xt_L) | (d_x(def)<xt_L & abs(d_y(def))<=R*cosd(half_angle)+(xt_L-d_x(def))*tand(half_angle));
                    def_in_R = ((d_x(def)-xc_R)^2+d_y(def)^2<=R^2 & d_x(def)<=xt_R) | (d_x(def)>xt_R & abs(d_y(def))<=R*cosd(half_angle)+(d_x(def)-xt_R)*tand(half_angle));
                    if ~def_in_L && ~def_in_R; channel_defects = channel_defects + 1; end
                end
                if channel_defects == 0; b_p = b_p + 1; else; b_d = b_d + 1; end
            end
        end
        out_Np(i) = b_p; out_Nd(i) = b_d;
    end

    fprintf('Data collected. Saving files...\n');

    is_target = (out_Np == 1) & (out_Nd == 0);
    cumulative_yield = cumsum(is_target) ./ (1:num_trials)' * 100;
    eval_window = round(num_trials * 0.10);
    std_dev = std(cumulative_yield(end-eval_window+1:end));

    txt_path = fullfile(conv_folder, '00_Manuscript_Data.txt');
    fid = fopen(txt_path, 'w');
    fprintf(fid, '--- OPTIMAL CONVERGENCE DATA ---\nTotal Trials: %d\nFinal Yield: %.2f%%\nStatistical Error (last %d trials): ±%.4f%%\n', num_trials, cumulative_yield(end), eval_window, std_dev);
    fclose(fid);

    figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 800, 500]);
    hold on; box on; grid on;
    plot(1:num_trials, cumulative_yield, 'LineWidth', 1.5, 'Color', [0 0.4470 0.7410]);
    yline(cumulative_yield(end), '--r', 'LineWidth', 2, 'Label', sprintf('Final Yield: %.1f%% \\pm %.2f%%', cumulative_yield(end), std_dev));
    title('Automated Convergence Analysis', 'FontWeight', 'bold');
    xlabel('Number of Simulated Trials', 'FontWeight', 'bold');
    ylabel('Cumulative Probability (%)', 'FontWeight', 'bold');
    ylim([max(0, cumulative_yield(end)-5), min(100, cumulative_yield(end)+5)]);
    exportgraphics(gcf, fullfile(conv_folder, '01_Convergence_Plot.png'), 'Resolution', 300);

    save(fullfile(conv_folder, 'Convergence_Data.mat'), 'out_Np', 'out_Nd', 'cumulative_yield');
    fprintf('Saved perfectly.\n');

end

try rmdir(job_folder, 's'); catch; end
fprintf('\n==========================================\n');
fprintf('MASS RESCUE COMPLETE.\n');
fprintf('==========================================\n');