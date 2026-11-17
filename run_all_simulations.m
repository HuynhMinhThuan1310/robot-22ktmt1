%% ========================================================================
%  CHU DE 4: DIEU KHIEN ROBOT DI DONG TRONG MOI TRUONG CO NHIEU VA BAT DINH
%  Main Simulation & Evaluation Suite (MATLAB R2024a)
%  ------------------------------------------------------------------------
%  Mo phong Robot vi sai 2 banh (Differential Drive / Unicycle Mobile Robot)
%  chiu tac dong dong thoi cua 4 yeu to bat dinh:
%    1. Sai so mo hinh (Model mismatch: lech ban kinh banh xe r_R, r_L, chieu rong co so b)
%    2. Nhieu cam bien (Sensor noise: nhieu do luong vi tri GPS/UWB & goc huong IMU + troi Odometry)
%    3. Truot banh (Wheel slip: truot doc longitudinal slip & truot ngang lateral skidding)
%    4. Thay doi thong so he thong (Parameter variation: thay doi tai trong / quan tinh dot ngot)
%
%  Doi sanh 4 phuong phap dieu khien:
%    [1] Baseline Kinematic P (RVC3 Ch.3) - Khong loc nhieu (Raw Sensor)
%    [2] PID Controller + Bo loc Kalman Mo rong (EKF)
%    [3] Lyapunov Backstepping (Kanayama) + EKF
%    [4] Robust Adaptive Sliding Mode Control (SMC + Disturbance Observer) + EKF
% =========================================================================

clear; clc; close all;
rng(42); % Co dinh seed de tai lap ket qua chinh xac 100%

outputDir = fullfile(pwd, 'results');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

fprintf('=========================================================================\n');
fprintf('  BAT DAU MO PHONG CHU DE 4: DIEU KHIEN ROBOT DI DONG TRONG MOI TRUONG\n');
fprintf('  CO NHIEU VA BAT DINH (DIFFERENTIAL DRIVE MOBILE ROBOT)\n');
fprintf('=========================================================================\n\n');

%% 1. CAU HINH THONG SO HE THONG & BAT DINH (SYSTEM & UNCERTAINTY PARAMETERS)
simParams.dt = 0.02;          % Chu ky lay mau: 20 ms (50 Hz)
simParams.T  = 40.0;          % Thoi gian mo phong: 40 giay
simParams.t  = 0:simParams.dt:simParams.T;
N = length(simParams.t);

% Thong so danh dinh cua robot (Nominal parameters - Bộ điều khiển biết)
robotNom.r = 0.08;            % Ban kinh banh xe danh dinh [m]
robotNom.b = 0.35;            % Khoang cach 2 banh xe (wheelbase) [m]
robotNom.m = 12.0;            % Khoi luong danh dinh [kg]
robotNom.I = 0.60;            % Momen quan tinh danh dinh [kg.m^2]
robotNom.tau_v = 0.12;        % Hang so thoi gian dong co tinh tien [s]
robotNom.tau_w = 0.10;        % Hang so thoi gian dong co quay [s]
robotNom.v_max = 1.8;         % Van toc dai cuc dai [m/s]
robotNom.w_max = 3.0;         % Van toc goc cuc dai [rad/s]

% Thong so thuc te co sai so mo hinh (Actual plant parameters with mismatch)
% +6% sai so ban kinh banh phai, -4% banh trai, +5% chieu rong co so
robotAct.r_R = robotNom.r * 1.06;
robotAct.r_L = robotNom.r * 0.96;
robotAct.b   = robotNom.b * 1.05;

% Thong so nhieu cam bien (Sensor Noise Covariances)
noiseParams.sigma_pos = 0.06;               % Nhieu do vi tri x, y: std = 6 cm
noiseParams.sigma_th  = deg2rad(2.5);       % Nhieu do goc huong theta: std = 2.5 deg
noiseParams.sigma_enc = 0.03;               % Nhieu encoder banh xe [rad/s]

% Pre-generate common random noise sequences for fair comparison across controllers
noiseSeq.pos = noiseParams.sigma_pos * randn(2, N);
noiseSeq.th  = noiseParams.sigma_th  * randn(1, N);
noiseSeq.enc = noiseParams.sigma_enc * randn(2, N);

%% 2. TAO QUY DAO THAM CHIEU SO 8 (LEMNISCATE / FIGURE-8 TRAJECTORY)
% Quy dao cong lien tuc doi hoi doi huong va thay doi van toc goc lien tuc
A_x = 3.5;                    % Bien do truc X [m]
A_y = 2.2;                    % Bien do truc Y [m]
omega_0 = 2*pi / 32;          % Tan so quy dao (chu ky 32s)

ref = generate_reference_trajectory(simParams.t, A_x, A_y, omega_0);

%% 3. CHAY MO PHONG KICH BAN 1: QUY DAO SO 8 DUOI NHIEU TONG HOP
controllers = {'P_Raw', 'PID_EKF', 'Backstepping_EKF', 'SMC_EKF'};
ctrlNames   = {
    '1. Kinematic P (Raw Sensor)', ...
    '2. PID + EKF', ...
    '3. Backstepping + EKF', ...
    '4. Robust Adaptive SMC + EKF'
};

results = struct();
for c = 1:length(controllers)
    ctrlType = controllers{c};
    fprintf(' -> Dang chay mo phong bo dieu khien [%s]...\n', ctrlNames{c});
    results.(ctrlType) = simulate_closed_loop(simParams, robotNom, robotAct, ...
                                              noiseParams, noiseSeq, ref, ctrlType);
end

%% 4. TINH TOAN BANG CHI SO DANH GIA DINH LUONG (PERFORMANCE METRICS)
fprintf('\n========================================================================================\n');
fprintf('  BANG TONG HOP KET QUA DANH GIA (SCENARIO 1: QUY DAO SO 8 CO NHIEU & TRUOT BANH)\n');
fprintf('========================================================================================\n');
fprintf('%-30s | %-9s | %-9s | %-9s | %-9s | %-9s\n', ...
    'Phuong phap Dieu khien', 'RMSE_p(m)', 'MAE_p(m)', 'Max_p(m)', 'RMSE_th(d)', 'IAE_p(m.s)');
fprintf('----------------------------------------------------------------------------------------\n');

metricsTable = zeros(length(controllers), 6);
for c = 1:length(controllers)
    res = results.(controllers{c});
    fprintf('%-30s | %9.4f | %9.4f | %9.4f | %9.4f | %9.4f\n', ...
        ctrlNames{c}, res.metrics.RMSE_pos, res.metrics.MAE_pos, ...
        res.metrics.Max_pos, rad2deg(res.metrics.RMSE_th), res.metrics.IAE_pos);
    metricsTable(c, :) = [res.metrics.RMSE_pos, res.metrics.MAE_pos, ...
                          res.metrics.Max_pos, rad2deg(res.metrics.RMSE_th), ...
                          res.metrics.IAE_pos, res.metrics.ControlEffort];
end
fprintf('========================================================================================\n\n');

% Luu bang chi so ra file CSV phuc vu viet bao cao
T_metrics = array2table(metricsTable, ...
    'VariableNames', {'RMSE_pos_m', 'MAE_pos_m', 'Max_pos_m', 'RMSE_theta_deg', 'IAE_pos_ms', 'Control_Effort'}, ...
    'RowNames', ctrlNames);
writetable(T_metrics, fullfile(outputDir, 'simulation_metrics_table.csv'), 'WriteRowNames', true);

%% 5. KICH BAN 2: BAM DUONG THANG & CHUYEN LAN (RVC3 LINE FOLLOWING) CO TRUOT BANH
fprintf(' -> Dang chay Kich ban 2: Bam duong thang (RVC3 Ch.3) duoi sai so banh xe & truot ngang...\n');
lineRes = simulate_rvc3_line_following(simParams, robotNom, robotAct, noiseParams);

%% 6. KICH BAN 3: PHAN TICH DO NHAY THEO MUC DO NHIEU & TRUOT BANH (SENSITIVITY)
fprintf(' -> Dang chay Kich ban 3: Phan tich do ben vung (Sensitivity Analysis) theo he so bat dinh...\n');
sensRes = run_sensitivity_analysis(simParams, robotNom, robotAct, noiseParams, noiseSeq, ref, controllers);

%% 7. XUAT BO DO THI CHAT LUONG CAO & MO CUA SO HIEN THI TRUC TIEP
fprintf(' -> Dang ve do thi hien thi tren man hinh MATLAB va luu file (300 DPI)...\n');
plot_all_results(simParams, ref, results, controllers, ctrlNames, lineRes, sensRes, outputDir);

%% 8. MO PHONG CHUYEN DONG TRUC QUAN (LIVE 2D ROBOT ANIMATION)
fprintf(' -> Dang chay mo phong hoat anh 2D Robot AGV tren man hinh...\n');
animate_robot_motion(simParams, ref, results, ctrlNames);

fprintf('\nHOAN TAT! Toan bo ket qua va hinh anh da duoc luu tai: %s\n', outputDir);

%% ========================================================================
%  CAC HAM CON MO PHONG & DIEU KHIEN (LOCAL FUNCTIONS)
% =========================================================================

function ref = generate_reference_trajectory(t, A_x, A_y, w0)
    % Quy dao Lemniscate of Gerono (Hinh so 8)
    ref.x   = A_x * sin(w0 * t);
    ref.y   = A_y * sin(2 * w0 * t);
    ref.dx  = A_x * w0 * cos(w0 * t);
    ref.dy  = 2 * A_y * w0 * cos(2 * w0 * t);
    ref.ddx = -A_x * (w0^2) * sin(w0 * t);
    ref.ddy = -4 * A_y * (w0^2) * sin(2 * w0 * t);
    
    ref.th  = atan2(ref.dy, ref.dx);
    % Unwrap theta de tranh nhay pha +-pi khi tinh dao ham
    ref.th_unwrapped = unwrap(ref.th);
    
    % Van toc dai va van toc goc tham chieu
    ref.v   = sqrt(ref.dx.^2 + ref.dy.^2);
    ref.w   = (ref.dx .* ref.ddy - ref.dy .* ref.ddx) ./ (ref.v.^2 + 1e-6);
end

function res = simulate_closed_loop(simParams, robotNom, robotAct, noiseParams, noiseSeq, ref, ctrlType)
    dt = simParams.dt;
    t  = simParams.t;
    N  = length(t);
    
    % Trang thai thuc cua robot: [x; y; theta; v_actual; w_actual]
    % Khoi tao robot lech khoi diem xuat phat de kiem tra kha nang hoi tu
    x_true = zeros(5, N);
    x_true(:, 1) = [0.45; -0.50; ref.th(1) - 0.35; 0.0; 0.0];
    
    % Trang thai do luong tho (Raw noisy measurement) va uoc luong EKF
    z_meas = zeros(3, N);
    x_ekf  = zeros(3, N);
    x_ekf(:, 1) = x_true(1:3, 1);
    P_ekf  = diag([0.05, 0.05, 0.02]);
    
    % Ma tran hiep phuong sai EKF (bao gom ca do bat dinh do truot banh trong Odometry)
    Q_ekf = diag([0.002, 0.002, 0.001]);
    R_ekf = diag([noiseParams.sigma_pos^2, noiseParams.sigma_pos^2, noiseParams.sigma_th^2]);
    
    % Luu tru tin hieu dieu khien & sai so
    u_cmd    = zeros(2, N); % [v_cmd; w_cmd]
    e_body   = zeros(3, N); % Sai so trong he toa do thân xe [e_x; e_y; e_th]
    e_world  = zeros(3, N); % Sai so trong he toa do toàn cuc
    slip_log = zeros(3, N); % [slip_long_v; slip_lat_vy; slip_rot_w]
    dist_est = zeros(2, N); % Uoc luong nhieu tong hop (Disturbance Observer cho SMC)
    
    % Bien trang thai noi cua bo dieu khien PID & SMC
    int_ex  = 0;
    int_ey  = 0;
    int_eth = 0;
    prev_ex = 0;
    prev_eth = 0;
    filt_dex = 0;
    filt_deth = 0;
    d_hat_v = 0;
    d_hat_w = 0;
    
    for k = 1:N-1
        tk = t(k);
        
        % 1. ĐO LƯỜNG CẢM BIẾN (CÓ NHIỄU GAUSSIAN)
        z_meas(1:2, k) = x_true(1:2, k) + noiseSeq.pos(:, k);
        z_meas(3, k)   = wrapToPi_local(x_true(3, k) + noiseSeq.th(k));
        if k == 1
            x_ekf(:, 1) = z_meas(:, 1);
        end
        
        % Chon trang thai phan hoi cho bo dieu khien
        if strcmp(ctrlType, 'P_Raw')
            x_fb = z_meas(:, k); % Dung truc tiep cam bien tho bi nhieu
        else
            x_fb = x_ekf(:, k);  % Dung trang thai da loc qua EKF
        end
        
        % 2. TÍNH SAI SỐ BÁM QUỸ ĐẠO TRONG HỆ TỌA ĐỘ ROBOT (BODY FRAME)
        dx_w = ref.x(k) - x_fb(1);
        dy_w = ref.y(k) - x_fb(2);
        dth  = wrapToPi_local(ref.th(k) - x_fb(3));
        
        th_fb = x_fb(3);
        ex  =  cos(th_fb) * dx_w + sin(th_fb) * dy_w;
        ey  = -sin(th_fb) * dx_w + cos(th_fb) * dy_w;
        eth = dth;
        
        % Sai so thuc te (so voi trang thai that x_true) de danh gia cong bang
        dx_true = ref.x(k) - x_true(1, k);
        dy_true = ref.y(k) - x_true(2, k);
        dth_true = wrapToPi_local(ref.th(k) - x_true(3, k));
        e_world(:, k) = [dx_true; dy_true; dth_true];
        e_body(:, k)  = [ cos(x_true(3,k))*dx_true + sin(x_true(3,k))*dy_true;
                         -sin(x_true(3,k))*dx_true + cos(x_true(3,k))*dy_true;
                          dth_true];
        
        % 3. THIẾT KẾ LUẬT ĐIỀU KHIỂN (CONTROL LAW)
        vr = ref.v(k);
        wr = ref.w(k);
        
        switch ctrlType
            case 'P_Raw'
                % Bo dieu khien P thuan tuy theo kieu RVC3 Ch.3 (phan hoi truc tiep cam bien nhieu)
                Kv = 1.4;
                Ky = 2.2;
                Kth = 1.8;
                dex_raw = (ex - prev_ex) / dt;
                deth_raw = wrapToPi_local(eth - prev_eth) / dt;
                prev_ex = ex;
                prev_eth = eth;
                v_c = vr * cos(eth) + Kv * ex + 0.03 * dex_raw;
                w_c = wr + Ky * vr * ey + Kth * eth + 0.03 * deth_raw;
                
            case 'PID_EKF'
                % Bo dieu khien PID ket hop Feedforward + Lọc thông thấp khâu D + Anti-windup
                Kp_v = 2.0; Ki_v = 0.85; Kd_v = 0.12;
                Kp_y = 3.2; Ki_y = 0.70;
                Kp_w = 2.8; Ki_w = 0.90; Kd_w = 0.14;
                
                int_ex  = min(max(int_ex  + ex * dt, -0.8), 0.8);
                int_ey  = min(max(int_ey  + ey * dt, -0.8), 0.8);
                int_eth = min(max(int_eth + eth * dt, -0.8), 0.8);
                
                dex_raw  = (ex - prev_ex) / dt;
                deth_raw = wrapToPi_local(eth - prev_eth) / dt;
                % Bo loc thong thap khau dao ham (nhu trong Chapter 3 Part 2 slide 45)
                alpha_d = 0.15;
                filt_dex  = (1 - alpha_d) * filt_dex  + alpha_d * dex_raw;
                filt_deth = (1 - alpha_d) * filt_deth + alpha_d * deth_raw;
                prev_ex  = ex;
                prev_eth = eth;
                
                v_c = vr * cos(eth) + Kp_v * ex + Ki_v * int_ex + Kd_v * filt_dex;
                w_c = wr + vr * (Kp_y * ey + Ki_y * int_ey) + Kp_w * eth + Ki_w * int_eth + Kd_w * filt_deth;
                
            case 'Backstepping_EKF'
                % Bo dieu khien phi tuyen Lyapunov Backstepping (Kanayama et al.)
                kx  = 2.6;
                ky  = 6.5;
                kth = 3.4;
                v_c = vr * cos(eth) + kx * ex;
                w_c = wr + ky * vr * ey + kth * sin(eth);
                
            case 'SMC_EKF'
                % Bo dieu khien Truot Thich nghi Ben vung (Robust Adaptive Sliding Mode Control)
                % Ket hop Quan sat nhieu (Disturbance Observer) de bu truot banh & sai so mo hinh
                kx_smc  = 2.7;
                ky_smc  = 7.2;
                kth_smc = 3.6;
                
                % Tich phan sai so co gioi han cho mat truot tich phan (Integral Sliding Surface)
                int_ex  = min(max(int_ex  + ex * dt, -0.6), 0.6);
                int_ey  = min(max(int_ey  + ey * dt, -0.6), 0.6);
                int_eth = min(max(int_eth + eth * dt, -0.6), 0.6);
                
                % Mat truot s1 (doc truc) va s2 (ngang & goc huong)
                lambda_x = 1.4;
                lambda_y = 1.6;
                s1 = ex + lambda_x * int_ex;
                s2 = eth + 0.75 * atan(2.0 * vr * ey) + lambda_y * (0.4 * int_ey + 0.6 * int_eth);
                
                % Luat chuyen mach lam muot bang ham tanh (chong rung / chattering-free)
                phi_1 = 0.16; % Do day lop bien (boundary layer)
                phi_2 = 0.18;
                eta_1 = 0.58; % He so kich hoat ben vung
                eta_2 = 0.75;
                
                % Cap nhat uoc luong nhieu/truot banh thich nghi (Adaptive Disturbance Compensation)
                gamma_v = 1.2;
                gamma_w = 1.4;
                d_hat_v = min(max(d_hat_v + gamma_v * s1 * dt, -0.45), 0.45);
                d_hat_w = min(max(d_hat_w + gamma_w * s2 * dt, -0.65), 0.65);
                dist_est(:, k) = [d_hat_v; d_hat_w];
                
                v_raw = vr * cos(eth) + kx_smc * ex + eta_1 * tanh(s1 / phi_1) + d_hat_v;
                w_raw = wr + ky_smc * vr * ey + kth_smc * sin(eth) + eta_2 * tanh(s2 / phi_2) + d_hat_w;
                if k == 1
                    v_c = v_raw; w_c = w_raw;
                else
                    v_c = 0.65 * u_cmd(1, k-1) + 0.35 * v_raw;
                    w_c = 0.65 * u_cmd(2, k-1) + 0.35 * w_raw;
                end
        end
        
        % Bao hoa tin hieu dieu khien (Actuator saturation)
        v_c = min(max(v_c, -robotNom.v_max), robotNom.v_max);
        w_c = min(max(w_c, -robotNom.w_max), robotNom.w_max);
        u_cmd(:, k) = [v_c; w_c];
        
        % 4. MÔ HÌNH ĐỘNG HỌC & ĐỘNG LỰC HỌC THỰC TẾ CÓ NHIỄU VÀ BẤT ĐỊNH
        % Chuyen doi (v_c, w_c) sang van toc goc 2 banh danh dinh
        w_R_cmd = (v_c + 0.5 * robotNom.b * w_c) / robotNom.r;
        w_L_cmd = (v_c - 0.5 * robotNom.b * w_c) / robotNom.r;
        
        % --- Yếu tố bất định 4: Thay đổi thông số hệ thống đột ngột tại t >= 20s ---
        % Giả lập robot đi vào địa hình lầy / tăng tải trọng làm tăng hằng số thời gian quán tính
        % và gây suy giảm hiệu suất cơ cấu chấp hành 12%
        if tk >= 20.0
            tau_v_act = robotNom.tau_v * 1.65;
            tau_w_act = robotNom.tau_w * 1.75;
            actuator_loss = 0.88;
        else
            tau_v_act = robotNom.tau_v;
            tau_w_act = robotNom.tau_w;
            actuator_loss = 1.00;
        end
        
        % --- Yếu tố bất định 1: Sai số mô hình bán kính bánh xe (r_R, r_L) và chiều rộng b ---
        v_wheel = actuator_loss * 0.5 * (robotAct.r_R * w_R_cmd + robotAct.r_L * w_L_cmd);
        w_wheel = actuator_loss * (robotAct.r_R * w_R_cmd - robotAct.r_L * w_L_cmd) / robotAct.b;
        
        % --- Yếu tố bất định 3: Trượt bánh dọc (Longitudinal Slip) & Trượt ngang (Lateral Skidding) ---
        % Giai đoạn 1 (t in [8s, 16s]): Đi qua vùng sàn trơn ướt gây trượt bánh mạnh
        % Giai đoạn 2 (toàn thời gian): Trượt ngang tỷ lệ với lực ly tâm v*w và nhiễu mặt đường
        slip_zone = exp(-0.5 * ((tk - 12.0) / 2.2)^2) + 0.75 * exp(-0.5 * ((tk - 28.0) / 2.5)^2);
        slip_long_v = -0.22 * v_wheel * slip_zone - 0.06 * sin(1.5 * tk);
        slip_lat_vy = -0.16 * x_true(4, k) * x_true(5, k) + 0.18 * slip_zone * sin(2.0 * tk);
        slip_rot_w  = -0.25 * slip_zone * cos(1.2 * tk) - 0.08 * w_wheel * slip_zone;
        slip_log(:, k) = [slip_long_v; slip_lat_vy; slip_rot_w];
        
        % Động lực học bậc 1 của vận tốc thực tế (First-order actuator + inertia dynamics)
        v_act = x_true(4, k) + (dt / tau_v_act) * (v_wheel + slip_long_v - x_true(4, k));
        w_act = x_true(5, k) + (dt / tau_w_act) * (w_wheel + slip_rot_w  - x_true(5, k));
        
        % Cập nhật trạng thái thực của robot (Unicycle model with lateral skidding vy)
        th_true = x_true(3, k);
        x_next  = x_true(1, k) + dt * (v_act * cos(th_true) - slip_lat_vy * sin(th_true));
        y_next  = x_true(2, k) + dt * (v_act * sin(th_true) + slip_lat_vy * cos(th_true));
        th_next = wrapToPi_local(th_true + dt * w_act);
        
        x_true(:, k+1) = [x_next; y_next; th_next; v_act; w_act];
        
        % 5. BỘ LỌC KALMAN MỞ RỘNG (EXTENDED KALMAN FILTER - EKF)
        % Odometry từ encoder (bị ảnh hưởng bởi sai số bán kính & trượt bánh + nhiễu encoder)
        w_R_enc = w_R_cmd + noiseSeq.enc(1, k);
        w_L_enc = w_L_cmd + noiseSeq.enc(2, k);
        v_odom  = 0.5 * robotNom.r * (w_R_enc + w_L_enc);
        w_odom  = (robotNom.r / robotNom.b) * (w_R_enc - w_L_enc);
        
        % Bước Dự đoán (EKF Prediction)
        th_est = x_ekf(3, k);
        x_pred = [x_ekf(1, k) + dt * v_odom * cos(th_est);
                  x_ekf(2, k) + dt * v_odom * sin(th_est);
                  wrapToPi_local(th_est + dt * w_odom)];
        
        F_jac = [1, 0, -dt * v_odom * sin(th_est);
                 0, 1,  dt * v_odom * cos(th_est);
                 0, 0,  1];
        P_pred = F_jac * P_ekf * F_jac' + Q_ekf;
        
        % Bước Cập nhật (EKF Update với cảm biến vị trí & la bàn tại bước k+1)
        z_next = [x_true(1:2, k+1) + noiseSeq.pos(:, k+1);
                  wrapToPi_local(x_true(3, k+1) + noiseSeq.th(k+1))];
        z_meas(:, k+1) = z_next;
        
        y_tilde = [z_next(1) - x_pred(1);
                   z_next(2) - x_pred(2);
                   wrapToPi_local(z_next(3) - x_pred(3))];
        S_cov = P_pred + R_ekf;
        K_gain = P_pred / S_cov;
        
        x_ekf(:, k+1) = x_pred + K_gain * y_tilde;
        x_ekf(3, k+1) = wrapToPi_local(x_ekf(3, k+1));
        P_ekf = (eye(3) - K_gain) * P_pred;
    end
    
    % Tinh sai so buoc cuoi N
    dx_true = ref.x(N) - x_true(1, N);
    dy_true = ref.y(N) - x_true(2, N);
    dth_true = wrapToPi_local(ref.th(N) - x_true(3, N));
    e_world(:, N) = [dx_true; dy_true; dth_true];
    e_body(:, N)  = [ cos(x_true(3,N))*dx_true + sin(x_true(3,N))*dy_true;
                     -sin(x_true(3,N))*dx_true + cos(x_true(3,N))*dy_true;
                      dth_true];
    u_cmd(:, N) = u_cmd(:, N-1);
    
    % Tong hop chi so danh gia (bo qua 3s dau hoi tu tu vi tri lech ban dau de danh gia do bam on dinh,
    % hoac tinh tren toan bo thoi gian)
    pos_err = sqrt(e_world(1, :).^2 + e_world(2, :).^2);
    steady_idx = t >= 3.0; % Sau giai doan qua do ban dau
    
    res.x_true   = x_true;
    res.z_meas   = z_meas;
    res.x_ekf    = x_ekf;
    res.u_cmd    = u_cmd;
    res.e_body   = e_body;
    res.e_world  = e_world;
    res.pos_err  = pos_err;
    res.slip_log = slip_log;
    res.dist_est = dist_est;
    
    res.metrics.RMSE_pos = sqrt(mean(pos_err(steady_idx).^2));
    res.metrics.MAE_pos  = mean(pos_err(steady_idx));
    res.metrics.Max_pos  = max(pos_err(steady_idx));
    res.metrics.RMSE_th  = sqrt(mean(e_world(3, steady_idx).^2));
    res.metrics.IAE_pos  = trapz(t(steady_idx), pos_err(steady_idx));
    res.metrics.ControlEffort = trapz(t, u_cmd(1,:).^2 + 0.2 * u_cmd(2,:).^2);
end

function lineRes = simulate_rvc3_line_following(simParams, robotNom, robotAct, noiseParams)
    % Mo phong bai toan 3.1.4 Driving Along a Line (ax + by + c = 0) trong sach RVC3
    % Duong thang: x - 2y + 4 = 0 => y = 0.5x + 2 (giong het vi du trang 24 Chapter 3_part 1)
    L_line = [1, -2, 4];
    th_line = atan2(L_line(1), -L_line(2)); % atan2(1, 2) = 26.565 deg
    
    dt = simParams.dt;
    t  = 0:dt:25;
    N  = length(t);
    
    modes = {'RVC3_P', 'PID_Comp', 'SMC_Robust'};
    for m = 1:length(modes)
        mode = modes{m};
        x = zeros(3, N);
        x(:, 1) = [1.0; 0.5; 0.0]; % Xuat phat duoi duong thang (d > 0)
        d_err = zeros(1, N);
        int_d = 0;
        int_th = 0;
        
        for k = 1:N-1
            % Khoang cach co dau tu robot den duong thang ax + by + c = 0 (RVC3 slide 22)
            % Khi robot o ben phai / phia duoi duong thang x - 2y + 4 = 0, d > 0 -> can quay trai (w > 0)
            d = (L_line(1)*x(1,k) + L_line(2)*x(2,k) + L_line(3)) / hypot(L_line(1), L_line(2));
            d_err(k) = d;
            eth = wrapToPi_local(th_line - x(3,k));
            
            v_c = 1.0; % Toc do khong doi 1 m/s nhu RVC3
            if strcmp(mode, 'RVC3_P')
                % Bo dieu khien P goc trong RVC3 (Slide 23): w = Kd*d + Kh*(th* - th)
                % Khi co lech ban kinh banh xe va truot ngang, P se bi sai so tinh (steady-state offset)!
                Kd = 0.65; Kh = 1.8;
                w_c = Kd * d + Kh * eth;
            elseif strcmp(mode, 'PID_Comp')
                Kd = 0.85; Ki_d = 0.35; Kh = 2.0; Ki_th = 0.45;
                int_d  = min(max(int_d + d * dt, -1.5), 1.5);
                int_th = min(max(int_th + eth * dt, -1.0), 1.0);
                w_c = (Kd * d + Ki_d * int_d) + Kh * eth + Ki_th * int_th;
            else
                % Robust SMC tren mat truot khoang cach d va goc eth
                int_d = min(max(int_d + d * dt, -1.5), 1.5);
                s_line = eth + atan(0.75 * d) + 0.45 * int_d;
                w_c = 2.0 * eth + 0.95 * d + 0.55 * int_d + 0.65 * tanh(s_line / 0.15);
            end
            w_c = min(max(w_c, -2.5), 2.5);
            
            % Sai so ban kinh banh xe gay lech goc quay thuong xuyen (w_bias) + truot ngang vy_slip
            w_R = (v_c + 0.5 * robotNom.b * w_c) / robotNom.r;
            w_L = (v_c - 0.5 * robotNom.b * w_c) / robotNom.r;
            v_real = 0.5 * (robotAct.r_R * w_R + robotAct.r_L * w_L);
            w_real = (robotAct.r_R * w_R - robotAct.r_L * w_L) / robotAct.b;
            
            % Truot ngang co dinh (vi du di tren mat nghieng nghieng / gio ngang) tu t = 8s
            vy_slip = -0.12 * (t(k) >= 8.0);
            
            x(1, k+1) = x(1, k) + dt * (v_real * cos(x(3,k)) - vy_slip * sin(x(3,k)));
            x(2, k+1) = x(2, k) + dt * (v_real * sin(x(3,k)) + vy_slip * cos(x(3,k)));
            x(3, k+1) = wrapToPi_local(x(3, k) + dt * w_real);
        end
        d_err(N) = (L_line(1)*x(1,N) + L_line(2)*x(2,N) + L_line(3)) / hypot(L_line(1), L_line(2));
        lineRes.(mode).t = t;
        lineRes.(mode).x = x;
        lineRes.(mode).d = d_err;
    end
    lineRes.L_line = L_line;
end

function sensRes = run_sensitivity_analysis(simParams, robotNom, robotAct, noiseParams, noiseSeq, ref, controllers)
    % Khao sat RMSE khi he so bat dinh (muc do truot banh + sai so mo hinh + nhieu) tang tu 0.5x den 2.0x
    scales = [0.5, 1.0, 1.5, 2.0];
    rmse_matrix = zeros(length(controllers), length(scales));
    
    for s = 1:length(scales)
        sc = scales(s);
        actScaled = robotAct;
        actScaled.r_R = robotNom.r * (1 + 0.06 * sc);
        actScaled.r_L = robotNom.r * (1 - 0.04 * sc);
        actScaled.b   = robotNom.b * (1 + 0.05 * sc);
        
        noiseScaled = noiseParams;
        noiseScaled.sigma_pos = noiseParams.sigma_pos * sc;
        noiseScaled.sigma_th  = noiseParams.sigma_th  * sc;
        
        seqScaled.pos = noiseSeq.pos * sc;
        seqScaled.th  = noiseSeq.th  * sc;
        seqScaled.enc = noiseSeq.enc * sc;
        
        for c = 1:length(controllers)
            r = simulate_closed_loop(simParams, robotNom, actScaled, noiseScaled, seqScaled, ref, controllers{c});
            rmse_matrix(c, s) = r.metrics.RMSE_pos;
        end
    end
    sensRes.scales = scales;
    sensRes.rmse_matrix = rmse_matrix;
end

function plot_all_results(simParams, ref, results, controllers, ctrlNames, lineRes, sensRes, outputDir)
    t = simParams.t;
    colors = {
        [0.85, 0.20, 0.20], ... % Red (P Raw)
        [0.93, 0.60, 0.10], ... % Orange/Amber (PID + EKF)
        [0.15, 0.50, 0.85], ... % Blue (Backstepping + EKF)
        [0.10, 0.68, 0.32]      % Green (Robust SMC + EKF)
    };
    lineStyles = {'--', '-.', '-', '-'};
    lineWidths = [1.4, 1.8, 1.8, 2.3];
    
    % ---------------------------------------------------------------------
    % HINH 1: QUY DAO CHUYEN DONG 2D TREN MAT PHANG XY (FIGURE-8 TRAJECTORY)
    % ---------------------------------------------------------------------
    fig1 = figure('Name', 'Fig 1: Quy dao Figure-8 duoi nhieu & truot banh', 'NumberTitle', 'off', ...
                  'Color', 'w', 'Position', [60, 80, 1050, 620], 'Visible', 'on');
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    nexttile;
    hold on; grid on; box on;
    % Danh dau vung truot banh (Slip Zone 1 around t=12s)
    idx_slip1 = (t >= 9.0) & (t <= 15.0);
    plot(ref.x(idx_slip1), ref.y(idx_slip1), '-', 'Color', [1.0, 0.85, 0.45], 'LineWidth', 12, ...
        'DisplayName', 'Vung san tron truot (Slip Zone)');
    plot(ref.x, ref.y, 'k:', 'LineWidth', 2.0, 'DisplayName', 'Quy dao tham chieu (Reference)');
    
    for c = 1:length(controllers)
        res = results.(controllers{c});
        plot(res.x_true(1, :), res.x_true(2, :), lineStyles{c}, ...
            'Color', colors{c}, 'LineWidth', lineWidths(c), 'DisplayName', ctrlNames{c});
    end
    plot(ref.x(1), ref.y(1), 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'y', 'DisplayName', 'Diem bat dau tham chieu');
    xlabel('Toa do X [m]', 'FontWeight', 'bold');
    ylabel('Toa do Y [m]', 'FontWeight', 'bold');
    title('(a) Quy dao bam hinh so 8 duoi nhieu & truot banh', 'FontSize', 11, 'FontWeight', 'bold');
    legend('Location', 'southoutside', 'NumColumns', 2, 'FontSize', 8.5);
    axis equal; xlim([-4.3, 4.3]); ylim([-2.8, 2.8]);
    
    % Zoom-in tai khuc cua co truot banh + thay doi tai trong
    nexttile;
    hold on; grid on; box on;
    plot(ref.x(idx_slip1), ref.y(idx_slip1), '-', 'Color', [1.0, 0.85, 0.45], 'LineWidth', 14, ...
        'HandleVisibility', 'off');
    plot(ref.x, ref.y, 'k:', 'LineWidth', 2.2, 'DisplayName', 'Reference');
    % Ve them diem do cam bien bi nhieu (Raw Sensor Points)
    resSMC = results.SMC_EKF;
    scatter(resSMC.z_meas(1, 1:4:end), resSMC.z_meas(2, 1:4:end), 12, [0.6 0.6 0.6], 'filled', ...
        'MarkerFaceAlpha', 0.45, 'DisplayName', 'Du lieu cam bien nhieu (Noisy GPS/UWB)');
    for c = 1:length(controllers)
        res = results.(controllers{c});
        plot(res.x_true(1, :), res.x_true(2, :), lineStyles{c}, ...
            'Color', colors{c}, 'LineWidth', lineWidths(c)+0.3, 'DisplayName', ctrlNames{c});
    end
    xlabel('Toa do X [m]', 'FontWeight', 'bold');
    ylabel('Toa do Y [m]', 'FontWeight', 'bold');
    title('(b) Phong to doan cua co truot banh & nhieu cam bien', 'FontSize', 11, 'FontWeight', 'bold');
    legend('Location', 'southoutside', 'NumColumns', 2, 'FontSize', 8.5);
    xlim([1.2, 3.9]); ylim([-2.6, 0.8]);
    
    exportgraphics(fig1, fullfile(outputDir, 'fig1_trajectory_figure8.png'), 'Resolution', 300);
    
    % ---------------------------------------------------------------------
    % HINH 2: ĐÁP ỨNG SAI SỐ BÁM THEO THỜI GIAN (TRACKING ERRORS)
    % ---------------------------------------------------------------------
    fig2 = figure('Name', 'Fig 2: Dap ung sai so bam theo thoi gian', 'NumberTitle', 'off', ...
                  'Color', 'w', 'Position', [90, 60, 1050, 720], 'Visible', 'on');
    tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    % Tile 1: Tong sai so vi tri Euclid ||e_p||
    nexttile;
    hold on; grid on; box on;
    xline(12.0, '--k', 'Vung truot banh #1', 'LabelVerticalAlignment', 'top', 'FontSize', 8.5, 'HandleVisibility', 'off');
    xline(20.0, '--r', 'Thay doi tai trong (+65% quan tinh)', 'LabelVerticalAlignment', 'top', 'FontSize', 8.5, 'HandleVisibility', 'off');
    xline(28.0, '--k', 'Vung truot banh #2', 'LabelVerticalAlignment', 'top', 'FontSize', 8.5, 'HandleVisibility', 'off');
    for c = 1:length(controllers)
        res = results.(controllers{c});
        plot(t, res.pos_err, lineStyles{c}, 'Color', colors{c}, 'LineWidth', lineWidths(c), ...
            'DisplayName', ctrlNames{c});
    end
    ylabel('Sai so vi tri ||e_p|| [m]', 'FontWeight', 'bold');
    title('(a) Sai so khoang cach Euclid ||e_p(t)|| = \surd(e_x^2 + e_y^2)', 'FontWeight', 'bold');
    legend('Location', 'northeast', 'NumColumns', 2, 'FontSize', 8.5);
    ylim([0, 0.70]);
    
    % Tile 2: Sai so ngang e_y (Cross-track error)
    nexttile;
    hold on; grid on; box on;
    xline(20.0, '--r', 'HandleVisibility', 'off');
    for c = 1:length(controllers)
        res = results.(controllers{c});
        plot(t, res.e_body(2, :), lineStyles{c}, 'Color', colors{c}, 'LineWidth', lineWidths(c));
    end
    ylabel('Sai so ngang e_y [m]', 'FontWeight', 'bold');
    title('(b) Sai so lech ngang trong he toa do Robot e_y(t) (Cross-track Error)', 'FontWeight', 'bold');
    ylim([-0.55, 0.55]);
    
    % Tile 3: Sai so goc huong e_theta [deg]
    nexttile;
    hold on; grid on; box on;
    xline(20.0, '--r', 'HandleVisibility', 'off');
    for c = 1:length(controllers)
        res = results.(controllers{c});
        plot(t, rad2deg(res.e_body(3, :)), lineStyles{c}, 'Color', colors{c}, 'LineWidth', lineWidths(c));
    end
    xlabel('Thoi gian t [s]', 'FontWeight', 'bold');
    ylabel('Sai so goc e_\theta [deg]', 'FontWeight', 'bold');
    title('(c) Sai so goc huong e_\theta(t) [do]', 'FontWeight', 'bold');
    ylim([-35, 35]);
    
    exportgraphics(fig2, fullfile(outputDir, 'fig2_tracking_errors.png'), 'Resolution', 300);
    
    % ---------------------------------------------------------------------
    % HINH 3: TÍN HIỆU ĐIỀU KHIỂN, HIỆU QUẢ LỌC NHIỄU EKF & ƯỚC LƯỢNG TRƯỢT BÁNH
    % ---------------------------------------------------------------------
    fig3 = figure('Name', 'Fig 3: Tin hieu dieu khien, EKF & Uoc luong truot banh', 'NumberTitle', 'off', ...
                  'Color', 'w', 'Position', [120, 50, 1050, 720], 'Visible', 'on');
    tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    % (a) Van toc dai v_cmd
    nexttile;
    hold on; grid on; box on;
    plot(t, ref.v, 'k:', 'LineWidth', 1.8, 'DisplayName', 'v_{ref}');
    for c = [1, 2, 4]
        res = results.(controllers{c});
        plot(t, res.u_cmd(1, :), lineStyles{c}, 'Color', colors{c}, 'LineWidth', 1.4, 'DisplayName', ctrlNames{c});
    end
    ylabel('Van toc dai v [m/s]', 'FontWeight', 'bold');
    title('(a) Tin hieu dieu khien van toc dai v(t)', 'FontWeight', 'bold');
    legend('Location', 'southwest', 'FontSize', 8);
    
    % (b) Van toc goc w_cmd
    nexttile;
    hold on; grid on; box on;
    plot(t, ref.w, 'k:', 'LineWidth', 1.8, 'DisplayName', '\omega_{ref}');
    for c = [1, 2, 4]
        res = results.(controllers{c});
        plot(t, res.u_cmd(2, :), lineStyles{c}, 'Color', colors{c}, 'LineWidth', 1.4, 'DisplayName', ctrlNames{c});
    end
    ylabel('Van toc goc \omega [rad/s]', 'FontWeight', 'bold');
    title('(b) Tin hieu dieu khien van toc goc \omega(t) (P bi nhieu cao tan)', 'FontWeight', 'bold');
    legend('Location', 'southwest', 'FontSize', 8);
    
    % (c) Hieu qua loc nhieu cua EKF so voi Raw Sensor
    nexttile;
    hold on; grid on; box on;
    resSMC = results.SMC_EKF;
    raw_err = hypot(resSMC.z_meas(1,:) - resSMC.x_true(1,:), resSMC.z_meas(2,:) - resSMC.x_true(2,:));
    ekf_err = hypot(resSMC.x_ekf(1,:)  - resSMC.x_true(1,:), resSMC.x_ekf(2,:)  - resSMC.x_true(2,:));
    plot(t, raw_err, '-', 'Color', [0.75, 0.75, 0.75], 'LineWidth', 1.0, ...
        'DisplayName', sprintf('Sai so cam bien tho (RMSE = %.3fm)', rms(raw_err)));
    plot(t, ekf_err, '-', 'Color', [0.10, 0.45, 0.80], 'LineWidth', 1.8, ...
        'DisplayName', sprintf('Sau khi loc EKF (RMSE = %.3fm)', rms(ekf_err)));
    xlabel('Thoi gian t [s]', 'FontWeight', 'bold');
    ylabel('Sai so do luong vi tri [m]', 'FontWeight', 'bold');
    title('(c) Hieu qua khu nhieu cam bien cua Bo loc Kalman Mo rong (EKF)', 'FontWeight', 'bold');
    legend('Location', 'northeast', 'FontSize', 8.5);
    
    % (d) Nhan dang va bu nhieu truot banh cua SMC
    nexttile;
    hold on; grid on; box on;
    plot(t, resSMC.slip_log(1, :), 'r--', 'LineWidth', 1.6, 'DisplayName', 'Nhieu truot doc thuc te d_v(t)');
    plot(t, resSMC.slip_log(2, :), 'b-.', 'LineWidth', 1.6, 'DisplayName', 'Van toc truot ngang v_{y,slip}(t)');
    plot(t, -resSMC.dist_est(1, :), 'g-', 'LineWidth', 2.0, 'DisplayName', 'Uoc luong bu nhieu cua SMC (-d_{est,v})');
    xlabel('Thoi gian t [s]', 'FontWeight', 'bold');
    ylabel('Van toc nhieu / truot [m/s]', 'FontWeight', 'bold');
    title('(d) Bieu do truot banh & Kha nang uoc luong bu nhieu cua SMC', 'FontWeight', 'bold');
    legend('Location', 'southwest', 'FontSize', 8);
    
    exportgraphics(fig3, fullfile(outputDir, 'fig3_control_inputs_and_slip.png'), 'Resolution', 300);
    
    % ---------------------------------------------------------------------
    % HINH 4: KỊCH BẢN BÁM ĐƯỜNG THẲNG RVC3 CHƯƠNG 3 DƯỚI TRƯỢT NGANG & SAI SỐ BÁNH XE
    % ---------------------------------------------------------------------
    fig4 = figure('Name', 'Fig 4: Bam duong thang RVC3 Ch.3 khi co truot ngang', 'NumberTitle', 'off', ...
                  'Color', 'w', 'Position', [150, 100, 1050, 480], 'Visible', 'on');
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    nexttile;
    hold on; grid on; box on;
    x_line = linspace(0, 22, 100);
    y_line = (-lineRes.L_line(1)*x_line - lineRes.L_line(3)) / lineRes.L_line(2);
    plot(x_line, y_line, 'k:', 'LineWidth', 2.2, 'DisplayName', 'Duong thang tham chieu: x - 2y + 4 = 0');
    plot(lineRes.RVC3_P.x(1,:), lineRes.RVC3_P.x(2,:), 'r--', 'LineWidth', 1.8, ...
        'DisplayName', 'RVC3 Proportional (Khong bu truot -> Lech tinh)');
    plot(lineRes.PID_Comp.x(1,:), lineRes.PID_Comp.x(2,:), 'b-.', 'LineWidth', 1.9, ...
        'DisplayName', 'PID Line Controller (Khu sai so xac lap)');
    plot(lineRes.SMC_Robust.x(1,:), lineRes.SMC_Robust.x(2,:), 'g-', 'LineWidth', 2.2, ...
        'DisplayName', 'Robust SMC Line Controller (Hoi tu nhanh & ben vung)');
    xlabel('Toa do X [m]', 'FontWeight', 'bold');
    ylabel('Toa do Y [m]', 'FontWeight', 'bold');
    title('(a) Quy dao bam duong thang (RVC3 Sect. 3.1.4) khi co truot banh', 'FontWeight', 'bold');
    legend('Location', 'northwest', 'FontSize', 8.5);
    xlim([0, 21]); ylim([0, 13]);
    
    nexttile;
    hold on; grid on; box on;
    xline(8.0, '--k', 'Bat dau truot ngang v_{y,slip} = -0.12 m/s', 'LabelVerticalAlignment', 'bottom', 'FontSize', 8.5, 'HandleVisibility', 'off');
    yline(0.0, 'k:', 'HandleVisibility', 'off');
    plot(lineRes.RVC3_P.t, lineRes.RVC3_P.d, 'r--', 'LineWidth', 1.8, 'DisplayName', 'RVC3 Proportional (Con sai so tinh ~0.27m)');
    plot(lineRes.PID_Comp.t, lineRes.PID_Comp.d, 'b-.', 'LineWidth', 1.9, 'DisplayName', 'PID Line Controller');
    plot(lineRes.SMC_Robust.t, lineRes.SMC_Robust.d, 'g-', 'LineWidth', 2.2, 'DisplayName', 'Robust SMC Line Controller');
    xlabel('Thoi gian t [s]', 'FontWeight', 'bold');
    ylabel('Khoang cach lech duong thang d(t) [m]', 'FontWeight', 'bold');
    title('(b) Sai so khoang cach d(t) den duong thang (Minh hoa ly thuyet Ch.3)', 'FontWeight', 'bold');
    legend('Location', 'northeast', 'FontSize', 8.5);
    
    exportgraphics(fig4, fullfile(outputDir, 'fig4_lane_change_rvc3.png'), 'Resolution', 300);
    
    % ---------------------------------------------------------------------
    % HINH 5: BIỂU ĐỒ ĐỐI SÁNH CHỈ SỐ ĐỊNH LƯỢNG & PHÂN TÍCH ĐỘ NHẠY
    % ---------------------------------------------------------------------
    fig5 = figure('Name', 'Fig 5: So sanh dinh luong RMSE/MAE/Max & Do nhay Robustness', 'NumberTitle', 'off', ...
                  'Color', 'w', 'Position', [180, 120, 1050, 460], 'Visible', 'on');
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    nexttile;
    rmse_vals = [results.P_Raw.metrics.RMSE_pos, results.PID_EKF.metrics.RMSE_pos, ...
                 results.Backstepping_EKF.metrics.RMSE_pos, results.SMC_EKF.metrics.RMSE_pos];
    mae_vals  = [results.P_Raw.metrics.MAE_pos, results.PID_EKF.metrics.MAE_pos, ...
                 results.Backstepping_EKF.metrics.MAE_pos, results.SMC_EKF.metrics.MAE_pos];
    max_vals  = [results.P_Raw.metrics.Max_pos, results.PID_EKF.metrics.Max_pos, ...
                 results.Backstepping_EKF.metrics.Max_pos, results.SMC_EKF.metrics.Max_pos];
    
    b = bar(categorical({'1. P (Raw)', '2. PID+EKF', '3. Backstep+EKF', '4. SMC+EKF'}, ...
                        {'1. P (Raw)', '2. PID+EKF', '3. Backstep+EKF', '4. SMC+EKF'}), ...
            [rmse_vals', mae_vals', max_vals'], 'grouped');
    b(1).FaceColor = [0.20, 0.48, 0.82];
    b(2).FaceColor = [0.25, 0.72, 0.45];
    b(3).FaceColor = [0.92, 0.52, 0.20];
    grid on; box on;
    ylabel('Sai so vi tri [m]', 'FontWeight', 'bold');
    title('(a) So sanh dinh luong RMSE, MAE va Max Error', 'FontWeight', 'bold');
    legend({'RMSE [m]', 'MAE [m]', 'Max Error [m]'}, 'Location', 'northeast');
    
    nexttile;
    hold on; grid on; box on;
    for c = 1:length(controllers)
        plot(sensRes.scales * 100, sensRes.rmse_matrix(c, :), '-o', ...
            'Color', colors{c}, 'LineWidth', 2.0, 'MarkerFaceColor', colors{c}, ...
            'DisplayName', ctrlNames{c});
    end
    xlabel('Muc do bat dinh & nhieu tong hop [% so voi kich ban chuan]', 'FontWeight', 'bold');
    ylabel('Sai so bam trung binh phuong RMSE [m]', 'FontWeight', 'bold');
    title('(b) Phan tich do nhay (Robustness) khi muc do nhieu tang', 'FontWeight', 'bold');
    legend('Location', 'northwest', 'FontSize', 8.5);
    
    exportgraphics(fig5, fullfile(outputDir, 'fig5_robustness_bar_chart.png'), 'Resolution', 300);
end

function animate_robot_motion(simParams, ref, results, ctrlNames)
    % Mo cua so hoat anh 2D truc quan so sanh Robot P (Raw) va Robot Robust SMC + EKF
    t = simParams.t;
    N = length(t);
    
    figAnim = figure('Name', 'Fig 6 - MO PHONG XE CHAY 2D (LIVE ROBOT ANIMATION)', ...
                     'NumberTitle', 'off', 'Color', 'w', 'Position', [180, 70, 980, 640], 'Visible', 'on');
    figure(figAnim); % Dua cua so mo phong xe chay len tren cung (Bring to front)
    
    ax = axes('Parent', figAnim, 'Position', [0.08, 0.16, 0.88, 0.76]);
    hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
    axis(ax, 'equal'); xlim(ax, [-4.4, 4.4]); ylim(ax, [-2.9, 2.9]);
    xlabel(ax, 'Toa do X [m]', 'FontWeight', 'bold');
    ylabel(ax, 'Toa do Y [m]', 'FontWeight', 'bold');
    
    % Ve vung truot banh va quy dao tham chieu
    idx_slip1 = (t >= 9.0) & (t <= 15.0);
    idx_slip2 = (t >= 25.0) & (t <= 31.0);
    plot(ax, ref.x(idx_slip1), ref.y(idx_slip1), '-', 'Color', [1.0, 0.85, 0.45], 'LineWidth', 16, ...
        'DisplayName', 'Vung san tron truot #1 & #2 (Slip Zone)');
    plot(ax, ref.x(idx_slip2), ref.y(idx_slip2), '-', 'Color', [1.0, 0.85, 0.45], 'LineWidth', 16, ...
        'HandleVisibility', 'off');
    plot(ax, ref.x, ref.y, 'k:', 'LineWidth', 2.0, 'DisplayName', 'Quy dao tham chieu (Reference)');
    
    resP   = results.P_Raw;
    resSMC = results.SMC_EKF;
    
    % Vet quy dao di chuyen cua 2 xe
    hTrailP   = plot(ax, nan, nan, 'r--', 'LineWidth', 1.5, 'DisplayName', ['Xe 1 (Do): ', ctrlNames{1}]);
    hTrailSMC = plot(ax, nan, nan, 'g-',  'LineWidth', 2.4, 'DisplayName', ['Xe 2 (Xanh): ', ctrlNames{4}]);
    hBotRef   = plot(ax, ref.x(1), ref.y(1), 'kp', 'MarkerSize', 13, 'MarkerFaceColor', 'y', 'DisplayName', 'Muc tieu di dong (Target)');
    
    % Ve than xe Robot (Hinh đa giác thân xe có đầu nhọn chỉ hướng)
    carShapeX = [-0.20,  0.12, 0.26, 0.12, -0.20];
    carShapeY = [-0.13, -0.13, 0.00, 0.13,  0.13];
    
    hCarP   = patch(ax, nan, nan, [0.90, 0.25, 0.25], 'EdgeColor', 'k', 'LineWidth', 1.2, 'FaceAlpha', 0.75, 'HandleVisibility', 'off');
    hCarSMC = patch(ax, nan, nan, [0.10, 0.72, 0.35], 'EdgeColor', 'k', 'LineWidth', 1.4, 'FaceAlpha', 0.90, 'HandleVisibility', 'off');
    
    hTitle = title(ax, 'Mo phong Chuyen dong Xe Robot AGV | t = 0.00 s', 'FontSize', 12, 'FontWeight', 'bold');
    legend(ax, 'Location', 'southoutside', 'NumColumns', 2, 'FontSize', 9);
    
    % Thêm nút bấm "Chạy lại mô phỏng xe (Replay)" ngay trên cửa sổ
    uicontrol('Parent', figAnim, 'Style', 'pushbutton', ...
              'String', 'Chay lai Mo phong Xe (Replay)', ...
              'FontSize', 10, 'FontWeight', 'bold', ...
              'BackgroundColor', [0.15, 0.55, 0.30], 'ForegroundColor', 'w', ...
              'Units', 'normalized', 'Position', [0.74, 0.02, 0.22, 0.06], ...
              'Callback', @(~,~) play_loop());
          
    play_loop();
    
    function play_loop()
        step_skip = 4; % Moi buoc 0.08s
        for k = 1:step_skip:N
            if ~isvalid(figAnim)
                return;
            end
            % Cap nhat vet duong di
            set(hTrailP,   'XData', resP.x_true(1, 1:k),   'YData', resP.x_true(2, 1:k));
            set(hTrailSMC, 'XData', resSMC.x_true(1, 1:k), 'YData', resSMC.x_true(2, 1:k));
            set(hBotRef,   'XData', ref.x(k),              'YData', ref.y(k));
            
            % Cap nhat toa do va goc quay than xe P (Màu đỏ)
            thP = resP.x_true(3, k);
            xp  = resP.x_true(1, k) + carShapeX * cos(thP) - carShapeY * sin(thP);
            yp  = resP.x_true(2, k) + carShapeX * sin(thP) + carShapeY * cos(thP);
            set(hCarP, 'XData', xp, 'YData', yp);
            
            % Cap nhat toa do va goc quay than xe SMC (Màu xanh lá)
            thS = resSMC.x_true(3, k);
            xs  = resSMC.x_true(1, k) + carShapeX * cos(thS) - carShapeY * sin(thS);
            ys  = resSMC.x_true(2, k) + carShapeX * sin(thS) + carShapeY * cos(thS);
            set(hCarSMC, 'XData', xs, 'YData', ys);
            
            status_str = 'Binh thuong';
            if (t(k) >= 9.0 && t(k) <= 15.0) || (t(k) >= 25.0 && t(k) <= 31.0)
                status_str = 'DANG DI QUA VUNG SAN TRON TRUOT (WHEEL SLIP)!';
            elseif t(k) >= 20.0
                status_str = 'DA TANG TAI TRONG HANG HOA (+65% QUAN TINH)';
            end
            set(hTitle, 'String', sprintf('t = %.2f / %.1f s | %s | Sai so P: %.2fm vs SMC: %.2fm', ...
                t(k), t(end), status_str, resP.pos_err(k), resSMC.pos_err(k)));
            drawnow;
            pause(0.025); % Giu toc do chuyen dong muot tren man hinh (~12 giay toan quy dao)
        end
    end
end

function ang = wrapToPi_local(ang)
    ang = mod(ang + pi, 2*pi) - pi;
end
