function out_folder = run_gnr_sweep(param_X_name, param_X_values, param_Y_name, param_Y_values, param_Z_name, param_Z_values, trials_per_pixel, film_morphology, varargin)
    fprintf('[CHECKPOINT 1] run_gnr_sweep.m successfully called!\n');
    
    % --- DEFAULT STATIC PARAMETERS ---
    base_num_workers = 128;
    base_L_gap = 12; 
    base_apex_angle = 30; 
    base_D_tip = 10;
    base_L_gnr_mean = 40; 
    base_L_gnr_std = 20.0; 
    base_avg_domain_size = 35; 
    base_target_angle = 0; 
    base_mean_defect_distance = 40; 
    base_min_gnr_length = 25; 
    base_gnr_spacing = 1.5;          
    base_end_to_end_gap = 1.0; 
    base_angle_variance = 4.0; 
    base_slide_step = 0.5;           

    % --- PARSE OVERRIDES ---
    for i = 1:2:length(varargin)
        p_name = varargin{i}; p_val = varargin{i+1};
        switch p_name
            case 'num_workers', base_num_workers = p_val;
            case 'L_gap', base_L_gap = p_val; 
            case 'apex_angle', base_apex_angle = p_val; 
            case 'D_tip', base_D_tip = p_val; 
            case 'L_gnr_mean', base_L_gnr_mean = p_val; 
            case 'avg_domain_size', base_avg_domain_size = p_val; 
            case 'target_angle', base_target_angle = p_val; 
            case 'mean_defect_distance', base_mean_defect_distance = p_val; 
            case 'L_gnr_std', base_L_gnr_std = p_val; 
            case 'min_gnr_length', base_min_gnr_length = p_val; 
            case 'gnr_spacing', base_gnr_spacing = p_val; 
            case 'end_to_end_gap', base_end_to_end_gap = p_val; 
            case 'angle_variance', base_angle_variance = p_val; 
            case 'slide_step', base_slide_step = p_val;
        end
    end

    % --- SETUP FOLDERS & GRIDS ---
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    if length(param_Z_values) > 1
        out_folder = sprintf('SimRun_%s_%s_vs_%s_vs_%s_%s', upper(film_morphology), param_X_name, param_Y_name, param_Z_name, timestamp);
    else
        out_folder = sprintf('SimRun_%s_%s_vs_%s_%s', upper(film_morphology), param_X_name, param_Y_name, timestamp);
    end
    mkdir(out_folder);
    fprintf('[CHECKPOINT 2] Folder created: %s\n', out_folder);

    [X_grid, Y_grid, Z_grid] = meshgrid(param_X_values, param_Y_values, param_Z_values);
    num_pixels = numel(X_grid); 
    total_trials = num_pixels * trials_per_pixel;
    
    X_flat = repelem(X_grid(:), trials_per_pixel); 
    Y_flat = repelem(Y_grid(:), trials_per_pixel); 
    Z_flat = repelem(Z_grid(:), trials_per_pixel);
    pixel_map = repelem(1:num_pixels, trials_per_pixel)';
    
    out_Np = zeros(total_trials, 1); 
    out_Nd = zeros(total_trials, 1);
    
    fprintf('[CHECKPOINT 3] Memory grids allocated for %d total trials.\n', total_trials);

    % --- CLUSTER CONFIGURATION ---
    desired_workers = base_num_workers; 
    fprintf('[CHECKPOINT 4] Configuring local parcluster for %d workers...\n', desired_workers);
    myCluster = parcluster('local');
    
    job_folder = sprintf('%s/matlab_pool_%s', tempdir, timestamp);
    mkdir(job_folder);
    myCluster.JobStorageLocation = job_folder;
    myCluster.NumWorkers = desired_workers;
    
    poolobj = gcp('nocreate'); 
    if isempty(poolobj) || poolobj.NumWorkers ~= desired_workers
        delete(gcp('nocreate')); 
        fprintf('[CHECKPOINT 5] Requesting parpool now. Waiting for licenses and worker spawn...\n');
        parpool(myCluster, desired_workers); 
    end
    
    fprintf('[CHECKPOINT 6] Parpool successfully connected! Firing up the parfor loop...\n');
    
    q = parallel.pool.DataQueue; 
    updateETA('init', total_trials); 
    afterEach(q, @(~) updateETA('update', total_trials));

    parfor i = 1:total_trials
        % Assign local parameters for the worker
        L_gap = base_L_gap; apex_angle = base_apex_angle; D_tip = base_D_tip; 
        L_gnr_mean = base_L_gnr_mean; avg_domain_size = base_avg_domain_size; 
        target_angle = base_target_angle; mean_defect_distance = base_mean_defect_distance; 
        L_gnr_std = base_L_gnr_std; min_gnr_length = base_min_gnr_length; 
        gnr_spacing = base_gnr_spacing; end_to_end_gap = base_end_to_end_gap; 
        angle_variance = base_angle_variance; slide_step = base_slide_step;
        
        cX = X_flat(i); cY = Y_flat(i); cZ = Z_flat(i);
        
        % Overwrite parameters being swept
        switch param_X_name; case 'L_gap', L_gap=cX; case 'apex_angle', apex_angle=cX; case 'D_tip', D_tip=cX; case 'L_gnr_mean', L_gnr_mean=cX; case 'avg_domain_size', avg_domain_size=cX; case 'target_angle', target_angle=cX; case 'mean_defect_distance', mean_defect_distance=cX; case 'L_gnr_std', L_gnr_std=cX; case 'min_gnr_length', min_gnr_length=cX; case 'gnr_spacing', gnr_spacing=cX; case 'end_to_end_gap', end_to_end_gap=cX; case 'angle_variance', angle_variance=cX; case 'slide_step', slide_step=cX; end
        switch param_Y_name; case 'L_gap', L_gap=cY; case 'apex_angle', apex_angle=cY; case 'D_tip', D_tip=cY; case 'L_gnr_mean', L_gnr_mean=cY; case 'avg_domain_size', avg_domain_size=cY; case 'target_angle', target_angle=cY; case 'mean_defect_distance', mean_defect_distance=cY; case 'L_gnr_std', L_gnr_std=cY; case 'min_gnr_length', min_gnr_length=cY; case 'gnr_spacing', gnr_spacing=cY; case 'end_to_end_gap', end_to_end_gap=cY; case 'angle_variance', angle_variance=cY; case 'slide_step', slide_step=cY; end
        switch param_Z_name; case 'L_gap', L_gap=cZ; case 'apex_angle', apex_angle=cZ; case 'D_tip', D_tip=cZ; case 'L_gnr_mean', L_gnr_mean=cZ; case 'avg_domain_size', avg_domain_size=cZ; case 'target_angle', target_angle=cZ; case 'mean_defect_distance', mean_defect_distance=cZ; case 'L_gnr_std', L_gnr_std=cZ; case 'min_gnr_length', min_gnr_length=cZ; case 'gnr_spacing', gnr_spacing=cZ; case 'end_to_end_gap', end_to_end_gap=cZ; case 'angle_variance', angle_variance=cZ; case 'slide_step', slide_step=cZ; end
        
        % Gamma Distribution Mathematics
        gamma_theta = (L_gnr_std^2) / L_gnr_mean; 
        gamma_k = (L_gnr_mean^2) / (L_gnr_std^2);
        
        % Fillet Geometry Math
        % --- PURE WEDGE GEOMETRY MATH (D_tip is now obsolete) ---
    half_angle = apex_angle / 2; 
    xc_L = -L_gap/2; 
    xc_R = L_gap/2; 
    sim_limit = L_gap + max(L_gnr_mean, 40); 
    % -------------------------------------------------------- 
        xt_L = xc_L - R*sind(half_angle); 
        xt_R = xc_R + R*sind(half_angle);

        GNR_X1 = []; GNR_X2 = []; GNR_Y1 = []; GNR_Y2 = []; 
        DEF_X = {}; DEF_Y = {}; domains = {}; 
        MAX_PTS = 300000; GLOBAL_PTS = zeros(MAX_PTS, 2); global_pt_idx = 0;
        
        % Domain Generation
        if strcmp(film_morphology, 'polydomain')
            area_total = (sim_limit * 4)^2; 
            num_seeds = round(area_total / (avg_domain_size^2)); 
            seed_x = (rand(num_seeds, 1) - 0.5) * sim_limit * 4; 
            seed_y = (rand(num_seeds, 1) - 0.5) * sim_limit * 4; 
            [V, C] = voronoin([seed_x, seed_y]); 
            for v_idx = 1:length(C)
                if any(C{v_idx} == 1); continue; end
                vx = V(C{v_idx}, 1); vy = V(C{v_idx}, 2); 
                if min(vx) > sim_limit || max(vx) < -sim_limit || min(vy) > sim_limit || max(vy) < -sim_limit; continue; end
                domains{end+1}.vx = vx; domains{end}.vy = vy; domains{end}.theta = rand() * pi; 
            end
        else
            bound = sim_limit * 2; 
            domains{1}.vx = [-bound; bound; bound; -bound]; 
            domains{1}.vy = [-bound; -bound; bound; bound]; 
            domains{1}.theta = target_angle * (pi/180); 
        end
        
        % Placement Engine
        for d = 1:length(domains)
            vx = domains{d}.vx; vy = domains{d}.vy; 
            theta_base = domains{d}.theta; 
            cos_base = cos(theta_base); sin_base = sin(theta_base); 
            cx = mean(vx); cy = mean(vy); 
            diag_len = min(sqrt((max(vx)-min(vx))^2 + (max(vy)-min(vy))^2), sim_limit*3); 
            y_local = (-diag_len : gnr_spacing : diag_len) + (rand() * gnr_spacing);
            
            for k = 1:length(y_local)
                curr_local_x = -diag_len + rand() * L_gnr_mean; 
                cand_L = max(gamrnd(gamma_k, gamma_theta), min_gnr_length); 
                theta_r = theta_base + (randn() * angle_variance) * (pi/180); 
                safety_counter = 0; 
                
                while curr_local_x < diag_len
                    safety_counter = safety_counter + 1; 
                    if safety_counter > 2000; break; end 
                    
                    frag_cx = cx + (curr_local_x + cand_L/2) * cos_base - y_local(k) * sin_base; 
                    frag_cy = cy + (curr_local_x + cand_L/2) * sin_base + y_local(k) * cos_base;
                    r_x1 = frag_cx - (cand_L/2) * cos(theta_r); 
                    r_y1 = frag_cy - (cand_L/2) * sin(theta_r); 
                    r_x2 = frag_cx + (cand_L/2) * cos(theta_r); 
                    r_y2 = frag_cy + (cand_L/2) * sin(theta_r); 
                    c_x1 = 0; c_y1 = 0; c_x2 = 0; c_y2 = 0; 
                    clip_len = 0; is_valid = false; placed = false; valid_clip = false;
                    
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
                                idx = find(in); 
                                c_x1 = xq(idx(1)); c_y1 = yq(idx(1)); 
                                c_x2 = xq(idx(end)); c_y2 = yq(idx(end)); 
                                clip_len = sqrt((c_x2 - c_x1)^2 + (c_y2 - c_y1)^2); valid_clip = true; 
                            end
                        end
                    end
                    
                    if valid_clip && clip_len >= min_gnr_length
                        n_pts = ceil(clip_len / 0.5); 
                        cand_pts_x = linspace(c_x1, c_x2, n_pts)'; 
                        cand_pts_y = linspace(c_y1, c_y2, n_pts)'; 
                        is_valid = true;
                        if global_pt_idx > 0
                            idx_start = max(1, global_pt_idx - 4000); 
                            recent_x = GLOBAL_PTS(idx_start:global_pt_idx, 1); 
                            recent_y = GLOBAL_PTS(idx_start:global_pt_idx, 2); 
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
                            GNR_X1(end+1) = c_x1; GNR_Y1(end+1) = c_y1; 
                            GNR_X2(end+1) = c_x2; GNR_Y2(end+1) = c_y2; 
                            GLOBAL_PTS(global_pt_idx+1 : global_pt_idx+n_pts, 1) = cand_pts_x; 
                            GLOBAL_PTS(global_pt_idx+1 : global_pt_idx+n_pts, 2) = cand_pts_y; 
                            global_pt_idx = global_pt_idx + n_pts;
                            
                            d_x_list = []; d_y_list = []; 
                            if mean_defect_distance > 0
                                min_defect_spacing = 1.0; 
                                eff_mean = max(0.1, mean_defect_distance - min_defect_spacing); 
                                local_positions = []; curr_d = -eff_mean * log(rand()); 
                                while curr_d < clip_len
                                    local_positions(end+1) = curr_d; 
                                    curr_d = curr_d + min_defect_spacing - eff_mean * log(rand()); 
                                end
                                if ~isempty(local_positions)
                                    local_pos = (local_positions') / clip_len; 
                                    d_x_list = c_x1 + local_pos * (c_x2 - c_x1); 
                                    d_y_list = c_y1 + local_pos * (c_y2 - c_y1); 
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
        
        % Collision Detection Check
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
        out_Np(i) = b_p; out_Nd(i) = b_d; send(q, 1);
    end
    
    fprintf('\n[CHECKPOINT 7] Simulation complete. Saving Data...\n');
    Y_1_Pristine = zeros(num_pixels, 1); Y_1_Defective = zeros(num_pixels, 1); 
    Y_Multi_Pristine = zeros(num_pixels, 1); Y_Multi_Defective = zeros(num_pixels, 1);
    
    for p = 1:num_pixels
        Np_t = out_Np(pixel_map == p); Nd_t = out_Nd(pixel_map == p); N_tot = Np_t + Nd_t; 
        Y_1_Pristine(p) = sum(Np_t == 1 & Nd_t == 0) / trials_per_pixel * 100; 
        Y_1_Defective(p) = sum(Np_t == 0 & Nd_t == 1) / trials_per_pixel * 100; 
        Y_Multi_Pristine(p) = sum(Np_t > 1 & Nd_t == 0) / trials_per_pixel * 100; 
        Y_Multi_Defective(p) = sum(N_tot > 1 & Nd_t > 0) / trials_per_pixel * 100; 
    end
    
    map_1P = reshape(Y_1_Pristine, size(X_grid)); map_1D = reshape(Y_1_Defective, size(X_grid)); 
    map_MP = reshape(Y_Multi_Pristine, size(X_grid)); map_MD = reshape(Y_Multi_Defective, size(X_grid));
    L_gnr_std = base_L_gnr_std; min_gnr_length = base_min_gnr_length; gnr_spacing = base_gnr_spacing; 
    end_to_end_gap = base_end_to_end_gap; angle_variance = base_angle_variance; slide_step = base_slide_step;
    
    data_filename = fullfile(out_folder, 'SimulationData.mat');
    save(data_filename, 'X_grid', 'Y_grid', 'Z_grid', 'map_1P', 'map_1D', 'map_MP', 'map_MD', 'param_X_name', 'param_X_values', 'param_Y_name', 'param_Y_values', 'param_Z_name', 'param_Z_values', 'base_L_gap', 'base_apex_angle', 'base_D_tip', 'base_L_gnr_mean', 'base_avg_domain_size', 'base_target_angle', 'base_mean_defect_distance', 'L_gnr_std', 'min_gnr_length', 'gnr_spacing', 'end_to_end_gap', 'angle_variance', 'slide_step', 'film_morphology', 'trials_per_pixel');
    try rmdir(job_folder, 's'); catch; end
    fprintf('[CHECKPOINT 8] Saved Successfully to: %s\n', data_filename);
end

function updateETA(action, total_t)
    persistent current_trial start_time msg_len time_history trial_history
    if strcmp(action, 'init')
        current_trial = 0; start_time = tic; msg_len = 0; 
        time_history = zeros(1, 50); trial_history = zeros(1, 50); return; 
    end
    current_trial = current_trial + 1;
    if mod(current_trial, 20) == 0 || current_trial == total_t
        curr_time = toc(start_time); 
        time_history = [time_history(2:end), curr_time]; 
        trial_history = [trial_history(2:end), current_trial]; 
        valid_idx = find(trial_history > 0, 1, 'first');
        if isempty(valid_idx) || trial_history(valid_idx) == current_trial
            rate = curr_time / current_trial; 
        else
            delta_trials = current_trial - trial_history(valid_idx); 
            delta_time = curr_time - time_history(valid_idx); 
            rate = delta_time / delta_trials; 
        end
        eta_sec = rate * (total_t - current_trial);
        if eta_sec > 60; eta_str = sprintf('%d min %02d sec', floor(eta_sec/60), round(mod(eta_sec, 60))); else; eta_str = sprintf('%d sec', round(eta_sec)); end
        fprintf(repmat('\b', 1, msg_len)); 
        msg = sprintf('Heavy Physical Sweep: [ %d / %d ] | Dynamic ETA: %s', current_trial, total_t, eta_str); 
        fprintf('%s', msg); 
        msg_len = length(msg); 
    end
end