function generate_gnr_schematic(L_gap, apex_angle, D_tip, L_gnr_mean, avg_domain_size, target_angle, mean_defect_distance, L_gnr_std, min_gnr_length, gnr_spacing, end_to_end_gap, angle_variance, slide_step, film_morphology, search_perfect, save_path, title_str)
    
    gamma_theta = (L_gnr_std^2) / L_gnr_mean; 
    gamma_k = (L_gnr_mean^2) / (L_gnr_std^2);
    
    % --- ROUNDED TIP GEOMETRY MATH ---
    R = D_tip / 2; 
    half_angle = apex_angle / 2; 
    xc_L = -L_gap/2 - R; 
    xc_R = L_gap/2 + R; 
    sim_limit = L_gap + D_tip + max(L_gnr_mean, 40); 
    xt_L = xc_L - R*sind(half_angle); 
    xt_R = xc_R + R*sind(half_angle);
    % ---------------------------------

    success_found = false; 
    attempt_total = 0; 
    batch_size = 32; 
    
    if ~search_perfect
        batch_size = 1; 
    end
    
    best_layout = struct();

    while ~success_found && attempt_total < 1000
        batch_GNR_X1 = cell(batch_size, 1); batch_GNR_X2 = cell(batch_size, 1); 
        batch_GNR_Y1 = cell(batch_size, 1); batch_GNR_Y2 = cell(batch_size, 1); 
        batch_DEF_X = cell(batch_size, 1); batch_DEF_Y = cell(batch_size, 1); 
        batch_domains = cell(batch_size, 1); batch_is_p = cell(batch_size, 1); 
        batch_is_b = cell(batch_size, 1); batch_hL = cell(batch_size, 1); 
        batch_hR = cell(batch_size, 1); batch_pristine = zeros(batch_size, 1); 
        batch_bridges = zeros(batch_size, 1);
        
        parfor b = 1:batch_size
            w_GNR_X1=[]; w_GNR_X2=[]; w_GNR_Y1=[]; w_GNR_Y2=[]; 
            w_DEF_X={}; w_DEF_Y={}; w_domains={}; 
            w_GLOBAL_PTS = zeros(200000, 2); w_global_pt_idx = 0;
            
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
                    w_domains{end+1}.vx = vx; w_domains{end}.vy = vy; w_domains{end}.theta = rand() * pi; 
                end
            else
                bound = sim_limit * 2; 
                w_domains{1}.vx = [-bound; bound; bound; -bound]; 
                w_domains{1}.vy = [-bound; -bound; bound; bound]; 
                w_domains{1}.theta = target_angle * (pi/180); 
            end
            
            for d = 1:length(w_domains)
                vx = w_domains{d}.vx; vy = w_domains{d}.vy; 
                theta_base = w_domains{d}.theta; 
                cos_base = cos(theta_base); sin_base = sin(theta_base); 
                cx = mean(vx); cy = mean(vy); 
                diag_len = min(sqrt((max(vx)-min(vx))^2 + (max(vy)-min(vy))^2), sim_limit*3); 
                y_local = (-diag_len : gnr_spacing : diag_len) + (rand() * gnr_spacing);
                
                for k = 1:length(y_local)
                    curr_local_x = -diag_len + rand() * L_gnr_mean; 
                    cand_L = max(gamrnd(gamma_k, gamma_theta), min_gnr_length); 
                    theta_r = theta_base + (randn() * angle_variance) * (pi/180); 
                    s_c = 0; 
                    
                    while curr_local_x < diag_len
                        s_c = s_c + 1; 
                        if s_c > 2000; break; end
                        
                        frag_cx = cx + (curr_local_x + cand_L/2) * cos_base - y_local(k) * sin_base; 
                        frag_cy = cy + (curr_local_x + cand_L/2) * sin_base + y_local(k) * cos_base; 
                        r_x1 = frag_cx - (cand_L/2) * cos(theta_r); r_y1 = frag_cy - (cand_L/2) * sin(theta_r); 
                        r_x2 = frag_cx + (cand_L/2) * cos(theta_r); r_y2 = frag_cy + (cand_L/2) * sin(theta_r); 
                        c_x1=0; c_y1=0; c_x2=0; c_y2=0; clip_len=0; is_valid = false; placed = false; valid_clip = false;
                        
                        if strcmp(film_morphology, 'aligned')
                            c_x1=r_x1; c_y1=r_y1; c_x2=r_x2; c_y2=r_y2; clip_len=cand_L; valid_clip=true; 
                        else
                            in_ends = inpolygon([r_x1, r_x2], [r_y1, r_y2], vx, vy); 
                            if in_ends(1) && in_ends(2)
                                c_x1=r_x1; c_y1=r_y1; c_x2=r_x2; c_y2=r_y2; clip_len=cand_L; valid_clip=true; 
                            else
                                pts = 20; xq = linspace(r_x1, r_x2, pts); yq = linspace(r_y1, r_y2, pts); 
                                in = inpolygon(xq, yq, vx, vy); 
                                if any(in)
                                    idx = find(in); 
                                    c_x1 = xq(idx(1)); c_y1 = yq(idx(1)); c_x2 = xq(idx(end)); c_y2 = yq(idx(end)); 
                                    clip_len = sqrt((c_x2 - c_x1)^2 + (c_y2 - c_y1)^2); valid_clip = true; 
                                end
                            end
                        end
                        
                        if valid_clip && clip_len >= min_gnr_length
                            n_pts = ceil(clip_len / 0.5); 
                            cand_pts_x = linspace(c_x1, c_x2, n_pts)'; cand_pts_y = linspace(c_y1, c_y2, n_pts)'; 
                            is_valid = true;
                            
                            if w_global_pt_idx > 0
                                idx_s = max(1, w_global_pt_idx - 4000); 
                                rec_x = w_GLOBAL_PTS(idx_s:w_global_pt_idx, 1); rec_y = w_GLOBAL_PTS(idx_s:w_global_pt_idx, 2); 
                                min_x = min(cand_pts_x)-1.5; max_x = max(cand_pts_x)+1.5; 
                                min_y = min(cand_pts_y)-1.5; max_y = max(cand_pts_y)+1.5; 
                                valid_m = rec_x > min_x & rec_x < max_x & rec_y > min_y & rec_y < max_y; 
                                if any(valid_m)
                                    obs_x = rec_x(valid_m); obs_y = rec_y(valid_m); 
                                    dx = cand_pts_x - obs_x'; dy = cand_pts_y - obs_y'; 
                                    if any((dx.^2 + dy.^2) < 2.1025, 'all'); is_valid = false; end
                                end
                            end
                            
                            if is_valid
                                w_GNR_X1(end+1)=c_x1; w_GNR_Y1(end+1)=c_y1; w_GNR_X2(end+1)=c_x2; w_GNR_Y2(end+1)=c_y2; 
                                w_GLOBAL_PTS(w_global_pt_idx+1:w_global_pt_idx+n_pts, 1) = cand_pts_x; 
                                w_GLOBAL_PTS(w_global_pt_idx+1:w_global_pt_idx+n_pts, 2) = cand_pts_y; 
                                w_global_pt_idx = w_global_pt_idx + n_pts; 
                                d_x_list = []; d_y_list = []; 
                                
                                if mean_defect_distance > 0
                                    eff_mean = max(0.1, mean_defect_distance - 1.0); 
                                    local_pos = []; curr_d = -eff_mean * log(rand()); 
                                    while curr_d < clip_len
                                        local_pos(end+1) = curr_d; curr_d = curr_d + 1.0 - eff_mean * log(rand()); 
                                    end
                                    if ~isempty(local_pos)
                                        lp = (local_pos') / clip_len; 
                                        d_x_list = c_x1 + lp * (c_x2 - c_x1); d_y_list = c_y1 + lp * (c_y2 - c_y1); 
                                    end
                                end
                                w_DEF_X{end+1} = d_x_list; w_DEF_Y{end+1} = d_y_list; placed = true; 
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
            
            w_bridges=0; w_pristine=0; 
            w_hL=false(length(w_GNR_X1),1); w_hR=false(length(w_GNR_X1),1); 
            w_is_b=false(length(w_GNR_X1),1); w_is_p=false(length(w_GNR_X1),1);
            
            for k = 1:length(w_GNR_X1)
                xx = linspace(w_GNR_X1(k), w_GNR_X2(k), 10); yy = linspace(w_GNR_Y1(k), w_GNR_Y2(k), 10);
                
                % --- SMOOTH TANGENTIAL COLLISION DETECTION ---
                w_hL(k) = any(((xx-xc_L).^2+yy.^2<=R^2 & xx>=xt_L) | (xx<xt_L & abs(yy)<=R*cosd(half_angle)+(xt_L-xx)*tand(half_angle)));
                w_hR(k) = any(((xx-xc_R).^2+yy.^2<=R^2 & xx<=xt_R) | (xx>xt_R & abs(yy)<=R*cosd(half_angle)+(xx-xt_R)*tand(half_angle)));
                
                if w_hL(k) && w_hR(k)
                    w_bridges = w_bridges+1; w_is_b(k)=true; c_defects=0; d_x=w_DEF_X{k}; d_y=w_DEF_Y{k}; 
                    for def=1:length(d_x)
                        def_in_L = ((d_x(def)-xc_L)^2+d_y(def)^2<=R^2 & d_x(def)>=xt_L) | (d_x(def)<xt_L & abs(d_y(def))<=R*cosd(half_angle)+(xt_L-d_x(def))*tand(half_angle));
                        def_in_R = ((d_x(def)-xc_R)^2+d_y(def)^2<=R^2 & d_x(def)<=xt_R) | (d_x(def)>xt_R & abs(d_y(def))<=R*cosd(half_angle)+(d_x(def)-xt_R)*tand(half_angle));
                        if ~def_in_L && ~def_in_R
                            c_defects=c_defects+1; 
                        end
                    end
                    if c_defects==0
                        w_pristine = w_pristine+1; w_is_p(k)=true; 
                    end
                end
            end
            batch_GNR_X1{b}=w_GNR_X1; batch_GNR_X2{b}=w_GNR_X2; batch_GNR_Y1{b}=w_GNR_Y1; batch_GNR_Y2{b}=w_GNR_Y2; 
            batch_DEF_X{b}=w_DEF_X; batch_DEF_Y{b}=w_DEF_Y; batch_domains{b}=w_domains; batch_is_p{b}=w_is_p; 
            batch_is_b{b}=w_is_b; batch_hL{b}=w_hL; batch_hR{b}=w_hR; batch_bridges(b)=w_bridges; batch_pristine(b)=w_pristine;
        end
        
        attempt_total = attempt_total + batch_size;
        
        if ~search_perfect
            best_layout.GNR_X1=batch_GNR_X1{1}; best_layout.GNR_X2=batch_GNR_X2{1}; 
            best_layout.GNR_Y1=batch_GNR_Y1{1}; best_layout.GNR_Y2=batch_GNR_Y2{1}; 
            best_layout.DEF_X=batch_DEF_X{1}; best_layout.DEF_Y=batch_DEF_Y{1}; 
            best_layout.domains=batch_domains{1}; best_layout.is_p=batch_is_p{1}; 
            best_layout.is_b=batch_is_b{1}; best_layout.hL=batch_hL{1}; best_layout.hR=batch_hR{1}; 
            success_found = true; 
        else
            for b = 1:batch_size
                if batch_bridges(b)==1 && batch_pristine(b)==1
                    success_found=true; best_layout.GNR_X1=batch_GNR_X1{b}; best_layout.GNR_X2=batch_GNR_X2{b}; 
                    best_layout.GNR_Y1=batch_GNR_Y1{b}; best_layout.GNR_Y2=batch_GNR_Y2{b}; 
                    best_layout.DEF_X=batch_DEF_X{b}; best_layout.DEF_Y=batch_DEF_Y{b}; 
                    best_layout.domains=batch_domains{b}; best_layout.is_p=batch_is_p{b}; 
                    best_layout.is_b=batch_is_b{b}; best_layout.hL=batch_hL{b}; best_layout.hR=batch_hR{b}; 
                    break; 
                end
            end
        end
    end

    if isfield(best_layout, 'GNR_X1')
        vis_state = 'off'; 
        if ~search_perfect; vis_state = 'on'; end
        
        figure('Visible', vis_state, 'Color', 'w', 'Position', [200, 200, 800, 600]); hold on; axis equal; box on;
        
        if strcmp(film_morphology, 'polydomain')
            for d = 1:length(best_layout.domains)
                patch(best_layout.domains{d}.vx, best_layout.domains{d}.vy, 'w', 'EdgeColor', [0.85 0.85 0.85], 'LineWidth', 1.5, 'FaceColor', 'none', 'ZData', zeros(size(best_layout.domains{d}.vx))-1); 
            end
        end
        
        % --- THE CORRECTED ROUNDED TIP RENDER MATH ---
        t_arc_L = linspace(-pi/2 + half_angle*pi/180, pi/2 - half_angle*pi/180, 50); 
        arc_x_L = xc_L + R*cos(t_arc_L); arc_y_L = R*sin(t_arc_L); 
        far_x_L = -sim_limit*1.5; far_y_L = R*cosd(half_angle) + (xt_L - far_x_L)*tand(half_angle); 
        fill([arc_x_L, far_x_L, far_x_L], [arc_y_L, far_y_L, -far_y_L], [0.8 0.8 0.8], 'EdgeColor', 'k', 'FaceAlpha', 0.9, 'ZData', zeros(1,52)+5);
        
        t_arc_R = linspace(pi/2 + half_angle*pi/180, 3*pi/2 - half_angle*pi/180, 50); 
        arc_x_R = xc_R + R*cos(t_arc_R); arc_y_R = R*sin(t_arc_R); 
        far_x_R = sim_limit*1.5; far_y_R = R*cosd(half_angle) + (far_x_R - xt_R)*tand(half_angle); 
        fill([arc_x_R, far_x_R, far_x_R], [arc_y_R, -far_y_R, far_y_R], [0.8 0.8 0.8], 'EdgeColor', 'k', 'FaceAlpha', 0.9, 'ZData', zeros(1,52)+5);
        % ---------------------------------------------
        
        for k = 1:length(best_layout.GNR_X1)
            if max(best_layout.GNR_X1(k), best_layout.GNR_X2(k)) < -sim_limit*0.8 || min(best_layout.GNR_X1(k), best_layout.GNR_X2(k)) > sim_limit*0.8 || max(best_layout.GNR_Y1(k), best_layout.GNR_Y2(k)) < -sim_limit*0.8 || min(best_layout.GNR_Y1(k), best_layout.GNR_Y2(k)) > sim_limit*0.8
                continue; 
            end
            
            z=2; lw=1.2; col=[0.4 0.4 0.4]; 
            if best_layout.is_p(k)
                z=4; lw=3; col='r'; 
            elseif best_layout.is_b(k)
                z=3; lw=2.5; col=[0.6 0 0.8]; 
            elseif best_layout.hL(k)
                z=3; lw=1.5; col='b'; 
            elseif best_layout.hR(k)
                z=3; lw=1.5; col='g'; 
            end
            
            plot([best_layout.GNR_X1(k), best_layout.GNR_X2(k)], [best_layout.GNR_Y1(k), best_layout.GNR_Y2(k)], 'Color', col, 'LineWidth', lw, 'ZData', [z z]);
            if ~isempty(best_layout.DEF_X{k})
                plot(best_layout.DEF_X{k}, best_layout.DEF_Y{k}, 'X', 'MarkerSize', 6, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', '#FFC000', 'LineWidth', 1, 'ZData', zeros(size(best_layout.DEF_X{k}))+6); 
            end
        end
        
        zoom_x = (L_gap / 2) + (L_gnr_mean * 1.2); zoom_y = (L_gnr_mean * 0.8) + (L_gap/2)*tand(half_angle); 
        xlim([-zoom_x, zoom_x]); ylim([-zoom_y, zoom_y]);
        
        if nargin == 17 && ~isempty(title_str)
            title(title_str, 'FontWeight', 'bold', 'FontSize', 14, 'Interpreter', 'none'); 
        end
        
        if ~isempty(save_path)
            exportgraphics(gcf, save_path, 'Resolution', 300); 
            if search_perfect; close(gcf); end
        end
    else
        fprintf('Failed to find layout.\n'); 
    end
end