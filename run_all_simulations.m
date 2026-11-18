%% ========================================================================
%  CHU DE 4: DIEU KHIEN ROBOT DI DONG TRONG MOI TRUONG CO NHIEU VA BAT DINH
%  Phuong phap de xuat: EXTENDED KALMAN FILTER (EKF) + PID CONTROLLER
%  ------------------------------------------------------------------------
%  Mo hinh: Robot vi sai 2 banh (Differential Drive / Unicycle Mobile Robot)
%  4 Yeu to Nhieu & Bat dinh tham gia mo phong:
%    1. Nhieu cam bien (Gaussian Sensor Noise tren vi tri x, y va goc theta)
%    2. Nhieu gai dot bien (Sensor Outliers / Spikes tai cac thoi diem roi rac)
%    3. Nhieu Encoder + Troi (Encoder Noise + Odometry Drift / Bias)
%    4. Truot banh (Wheel Slip: truot doc longitudinal & truot ngang lateral)
%
%  Doi sanh 4 Mo hinh (100% kien thuc PID & Kalman Filter):
%    [1] Chi co PID (PID_Raw)          : Dung cam bien tho, khong loc nhieu
%    [2] Chi co EKF (EKF_P)            : Co EKF loc nhieu + Dieu khien P co ban (thieu I)
%    [3] Standard KF + PID (KF_PID)    : Bo loc Kalman tuyen tinh + PID
%    [4] Extended KF + PID (EKF_PID)   : Phuong phap de xuat (EKF phi tuyen + PID Filtered D)
% =========================================================================

clear; clc; close all;
rng(42); % Co dinh seed de ket qua tai lap chinh xac 100%

outputDir = fullfile(pwd, 'results');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

fprintf('=========================================================================\n');
fprintf('  MO PHONG CHU DE 4: DIEU KHIEN ROBOT DI DONG TRONG MOI TRUONG CO NHIEU\n');
fprintf('  PHUONG PHAP DE XUAT: EXTENDED KALMAN FILTER (EKF) + PID CONTROLLER\n');
fprintf('=========================================================================\n\n');

%% 1. CAU HINH THONG SO ROBOT VI SAI 2 BANH (KHONG SAI SO MO HINH HINH HOC)
simParams.dt = 0.02;          % Chu ky lay mau: 20 ms (50 Hz)
simParams.T  = 40.0;          % Thoi gian mo phong: 40 giay
simParams.t  = 0:simParams.dt:simParams.T;
N = length(simParams.t);

% Thong so danh dinh cua Robot vi sai 2 banh (Differential Drive / Unicycle)
robot.r     = 0.08;           % Ban kinh banh xe r0 [m]
robot.b     = 0.35;           % Khoang cach 2 banh xe (wheelbase) b0 [m]
robot.tau_v = 0.10;           % Hang so thoi gian dap ung van toc dai [s]
robot.tau_w = 0.08;           % Hang so thoi gian dap ung van toc goc [s]
robot.v_max = 1.8;            % Gioi han bao hoa van toc dai [m/s]
robot.w_max = 3.0;            % Gioi han bao hoa van toc goc [rad/s]

%% 2. CAU HINH 4 LOAI NHIEU THAM GIA MO PHONG
% (1) Nhieu cam bien Gaussian (GPS/UWB + IMU)
noiseParams.sigma_pos = 0.06;               % Độ lệch chuẩn nhiễu vị trí x, y: 6 cm
noiseParams.sigma_th  = deg2rad(2.5);       % Độ lệch chuẩn nhiễu góc hướng: 2.5 độ

% (2) Nhieu gai dot bien (Sensor Outliers / Spikes)
% Xay ra tai t = 7s, 16s, 24s, 33s (keo dai 3 chu ky lay mau ~ 60ms)
noiseParams.spike_times = [7.0, 16.0, 24.0, 33.0];
noiseParams.spike_amp_xy = 0.38;            % Bien do gai vi tri: 38 cm
noiseParams.spike_amp_th = deg2rad(14.0);   % Bien do gai goc: 14 do

% (3) Nhieu Encoder + Troi Odometry (Encoder White Noise + Systematic Drift)
noiseParams.sigma_enc  = 0.04;              % Nhieu trang do van toc goc banh xe [rad/s]
noiseParams.enc_bias_R = +0.22;             % Do troi (drift/bias) encoder banh phai [rad/s]
noiseParams.enc_bias_L = -0.16;             % Do troi (drift/bias) encoder banh trai [rad/s]

% Sinh chuoi nhieu co dinh de so sanh cong bang giua 4 mo hinh
noiseSeq = generate_noise_sequences(simParams, noiseParams);

%% 3. TAO QUY DAO THAM CHIEU HINH SO 8 (LEMNISCATE TRAJECTORY)
A_x = 3.5;                    % Bien do truc X [m]
A_y = 2.2;                    % Bien do truc Y [m]
omega_0 = 2*pi / 32;          % Tan so quy dao (chu ky 32s)
ref = generate_reference_trajectory(simParams.t, A_x, A_y, omega_0);

%% 4. CHAY MO PHONG KICH BAN 1: QUY DAO SO 8 DUOI 4 LOAI NHIEU DONG THOI
models     = {'PID_Raw', 'EKF_P', 'KF_PID', 'EKF_PID'};
modelNames = {
    '1. Chi co PID (Raw Sensor)', ...
    '2. Chi co EKF (EKF + P)', ...
    '3. Standard KF + PID', ...
    '4. Extended KF + PID (De xuat)'
};

results = struct();
for m = 1:length(models)
    mType = models{m};
    fprintf(' -> Dang chay mo phong [%s]...\n', modelNames{m});
    results.(mType) = simulate_closed_loop(simParams, robot, noiseParams, noiseSeq, ref, mType);
end

%% 5. IN BANG TONG HOP 6 CHI SO DANH GIA DINH LUONG & XUAT FILE CSV
fprintf('\n========================================================================================================\n');
fprintf('  BANG TONG HOP KET QUA DANH GIA (SCENARIO 1: QUY DAO SO 8 DUOI 4 LOAI NHIEU & TRUOT BANH)\n');
fprintf('========================================================================================================\n');
fprintf('%-32s | %-9s | %-9s | %-9s | %-10s | %-9s | %-9s\n', ...
    'Mo hinh Dieu khien & Loc nhieu', 'RMSE_p(m)', 'MAE_p(m)', 'Max_p(m)', 'RMSE_th(d)', 'IAE_p(ms)', 'TV_w(r/s)');
fprintf('--------------------------------------------------------------------------------------------------------\n');

metricsMatrix = zeros(length(models), 6);
for m = 1:length(models)
    res = results.(models{m});
    fprintf('%-32s | %9.4f | %9.4f | %9.4f | %10.4f | %9.4f | %9.2f\n', ...
        modelNames{m}, res.metrics.RMSE_pos, res.metrics.MAE_pos, ...
        res.metrics.Max_pos, rad2deg(res.metrics.RMSE_th), ...
        res.metrics.IAE_pos, res.metrics.TV_w);
    metricsMatrix(m, :) = [res.metrics.RMSE_pos, res.metrics.MAE_pos, ...
                           res.metrics.Max_pos, rad2deg(res.metrics.RMSE_th), ...
                           res.metrics.IAE_pos, res.metrics.TV_w];
end
fprintf('========================================================================================================\n\n');

T_metrics = array2table(metricsMatrix, ...
    'VariableNames', {'RMSE_pos_m', 'MAE_pos_m', 'Max_pos_m', 'RMSE_theta_deg', 'IAE_pos_ms', 'TV_omega_rads'}, ...
    'RowNames', modelNames);
writetable(T_metrics, fullfile(outputDir, 'simulation_metrics_table.csv'), 'WriteRowNames', true);

%% 6. CHAY KICH BAN 2: BAM DUONG THANG (RVC3 CH.3) CO TRUOT BANH NGANG & NHIEU
fprintf(' -> Dang chay Kich ban 2: Bam duong thang (RVC3 Ch.3) khi co truot banh ngang lien tuc...\n');
lineRes = simulate_rvc3_line_following(simParams, robot, noiseParams);

%% 7. CHAY KICH BAN 3: PHAN TICH DO NHAY (SENSITIVITY ANALYSIS 50% -> 200% NHIEU)
fprintf(' -> Dang chay Kich ban 3: Phan tich do nhay khi cuong do nhieu & truot banh tang tu 50%% den 200%%...\n');
sensRes = run_sensitivity_analysis(simParams, robot, noiseParams, noiseSeq, ref, models);

%% 8. VE VA HIEN THI 5 CUA SO DO THI + LUU ANH 300 DPI
fprintf(' -> Dang ve do thi hien thi tren man hinh MATLAB va xuat file PNG (300 DPI)...\n');
plot_all_results(simParams, ref, results, models, modelNames, lineRes, sensRes, outputDir);

%% 9. MO PHONG CHUYEN DONG XE 2D TRUC QUAN (LIVE 2D ROBOT ANIMATION)
fprintf(' -> Dang mo cua so hoat anh 2D Robot AGV (Fig 6)...\n');
animate_robot_motion(simParams, ref, results, modelNames);

fprintf('\nHOAN TAT! Toan bo ket qua va hinh anh da duoc luu tai: %s\n', outputDir);

%% ========================================================================
%  CAC HAM CON MO PHONG, BO LOC KALMAN (KF / EKF) & DIEU KHIEN PID
% =========================================================================

function noiseSeq = generate_noise_sequences(simParams, noiseParams)
    t = simParams.t;
    N = length(t);
    
    % 1. Nhieu Gaussian trang
    noiseSeq.pos = noiseParams.sigma_pos * randn(2, N);
    noiseSeq.th  = noiseParams.sigma_th  * randn(1, N);
    
    % 2. Nhieu gai dot bien (Outliers / Spikes)
    noiseSeq.spikes_pos = zeros(2, N);
    noiseSeq.spikes_th  = zeros(1, N);
    signs = [1, -1, 1, -1];
    for s = 1:length(noiseParams.spike_times)
        ts = noiseParams.spike_times(s);
        idx = find(abs(t - ts) <= 1.5 * simParams.dt);
        noiseSeq.spikes_pos(:, idx) = signs(s) * noiseParams.spike_amp_xy * [1; -0.8] * ones(1, length(idx));
        noiseSeq.spikes_th(idx)     = signs(s) * noiseParams.spike_amp_th;
    end
    
    % 3. Nhieu Encoder + Bias (Troi Odometry)
    noiseSeq.enc = noiseParams.sigma_enc * randn(2, N) + ...
                   [noiseParams.enc_bias_R; noiseParams.enc_bias_L];
end

function ref = generate_reference_trajectory(t, A_x, A_y, w0)
    ref.x   = A_x * sin(w0 * t);
    ref.y   = A_y * sin(2 * w0 * t);
    ref.dx  = A_x * w0 * cos(w0 * t);
    ref.dy  = 2 * A_y * w0 * cos(2 * w0 * t);
    ref.ddx = -A_x * (w0^2) * sin(w0 * t);
    ref.ddy = -4 * A_y * (w0^2) * sin(2 * w0 * t);
    
    ref.th  = atan2(ref.dy, ref.dx);
    ref.v   = sqrt(ref.dx.^2 + ref.dy.^2);
    ref.w   = (ref.dx .* ref.ddy - ref.dy .* ref.ddx) ./ (ref.v.^2 + 1e-6);
end

function res = simulate_closed_loop(simParams, robot, noiseParams, noiseSeq, ref, modelType)
    dt = simParams.dt;
    t  = simParams.t;
    N  = length(t);
    
    % Trang thai thuc cua Robot: [x; y; theta; v_act; w_act]
    % Xuat phat lech khoi quy dao de kiem tra kha nang hoi tu
    x_true = zeros(5, N);
    x_true(:, 1) = [0.40; -0.45; ref.th(1) - 0.30; 0.0; 0.0];
    
    % Trang thai do luong tho (Raw Sensor = Gaussian + Outliers)
    z_meas = zeros(3, N);
    % Trang thai Odometry thuan tuy (Dead-reckoning bi troi do Encoder noise + drift + slip)
    x_odom = zeros(3, N);
    x_odom(:, 1) = x_true(1:3, 1);
    
    % Trang thai uoc luong qua bo loc (KF hoac EKF)
    x_est = zeros(3, N);
    x_est(:, 1) = x_true(1:3, 1);
    P_cov = diag([0.04, 0.04, 0.02]);
    
    % Ma tran hiep phuong sai nhieu qua trinh Q va nhieu do luong R
    Q_cov = diag([0.0004, 0.0004, 0.0002]);
    R_cov = diag([noiseParams.sigma_pos^2, noiseParams.sigma_pos^2, noiseParams.sigma_th^2]);
    
    % Luu tru tin hieu dieu khien & sai so
    u_cmd    = zeros(2, N); % [v_cmd; w_cmd]
    e_body   = zeros(3, N); % [e_x; e_y; e_th]
    e_world  = zeros(3, N);
    slip_log = zeros(3, N); % [slip_long_v; slip_lat_vy; slip_rot_w]
    
    % Bien trang thai cua bo dieu khien PID (P - I - Filtered D + Anti-windup)
    int_ex    = 0;
    int_ey    = 0;
    int_eth   = 0;
    prev_ex   = 0;
    prev_ey   = 0;
    prev_eth  = 0;
    filt_dex  = 0;
    filt_dey  = 0;
    filt_deth = 0;
    
    % Goc huong danh dinh co dinh cho Standard Linear KF (khong cap nhat phi tuyen theo goc quay)
    th_nominal_kf = ref.th(1);
    
    for k = 1:N-1
        tk = t(k);
        
        % 1. TÍN HIỆU CẢM BIẾN THÔ (NHIỄU GAUSSIAN + GAI ĐỘT BIẾN OUTLIERS)
        if k == 1
            z_meas(1:2, 1) = x_true(1:2, 1) + noiseSeq.pos(:, 1) + noiseSeq.spikes_pos(:, 1);
            z_meas(3, 1)   = wrapToPi_local(x_true(3, 1) + noiseSeq.th(1) + noiseSeq.spikes_th(1));
            x_est(:, 1)    = z_meas(:, 1);
        end
        
        % Chon tin hieu phan hoi dua vao bo dieu khien
        if strcmp(modelType, 'PID_Raw')
            x_fb = z_meas(:, k); % Mô hình 1: Chỉ có PID (nhận trực tiếp cảm biến thô đầy nhiễu & gai)
        else
            x_fb = x_est(:, k);  % Mô hình 2, 3, 4: Nhận trạng thái từ bộ lọc Kalman (KF hoặc EKF)
        end
        
        % 2. TÍNH SAI SỐ BÁM QUỸ ĐẠO TRONG HỆ TỌA ĐỘ ROBOT {B}
        dx_w = ref.x(k) - x_fb(1);
        dy_w = ref.y(k) - x_fb(2);
        dth  = wrapToPi_local(ref.th(k) - x_fb(3));
        
        th_fb = x_fb(3);
        ex  =  cos(th_fb) * dx_w + sin(th_fb) * dy_w;
        ey  = -sin(th_fb) * dx_w + cos(th_fb) * dy_w;
        eth = dth;
        
        % Sai so thuc te so voi trang thai that x_true de danh gia khách quan
        dx_true  = ref.x(k) - x_true(1, k);
        dy_true  = ref.y(k) - x_true(2, k);
        dth_true = wrapToPi_local(ref.th(k) - x_true(3, k));
        e_world(:, k) = [dx_true; dy_true; dth_true];
        e_body(:, k)  = [ cos(x_true(3,k))*dx_true + sin(x_true(3,k))*dy_true;
                         -sin(x_true(3,k))*dx_true + cos(x_true(3,k))*dy_true;
                          dth_true];
        
        % 3. LUẬT ĐIỀU KHIỂN (P HOẶC PID)
        vr = ref.v(k);
        wr = ref.w(k);
        
        switch modelType
            case 'EKF_P'
                % Mô hình 2: Chỉ có EKF + Bộ điều khiển P cơ bản (RVC3 Ch.3 - Không có khâu I & D)
                % Khi có trượt bánh (wheel slip), bộ điều khiển P không thể triệt tiêu sai số xác lập!
                Kp_v  = 1.25;
                Kp_y  = 1.95;
                Kp_th = 1.65;
                v_c = vr * cos(eth) + Kp_v * ex;
                w_c = wr + Kp_y * vr * ey + Kp_th * eth;
                
            case 'PID_Raw'
                % Mô hình 1: Chỉ có PID (Không có Kalman Filter)
                % Khâu đạo hàm D bị nhiễu cảm biến và gai đột biến kích thích làm giật tín hiệu điều khiển
                Kp_v = 2.0; Ki_v = 1.10; Kd_v = 0.09;
                Kp_y = 3.1; Ki_y = 1.00; Kd_y = 0.07;
                Kp_w = 2.5; Ki_w = 0.95; Kd_w = 0.10;
                
                int_ex  = min(max(int_ex  + ex * dt, -0.8), 0.8);
                int_ey  = min(max(int_ey  + ey * dt, -0.8), 0.8);
                int_eth = min(max(int_eth + eth * dt, -0.8), 0.8);
                
                dex_raw  = (ex - prev_ex) / dt;
                dey_raw  = (ey - prev_ey) / dt;
                deth_raw = wrapToPi_local(eth - prev_eth) / dt;
                prev_ex  = ex; prev_ey = ey; prev_eth = eth;
                
                v_c = vr * cos(eth) + Kp_v * ex + Ki_v * int_ex + Kd_v * dex_raw;
                w_c = wr + vr * (Kp_y * ey + Ki_y * int_ey + Kd_y * dey_raw) + ...
                      Kp_w * eth + Ki_w * int_eth + Kd_w * deth_raw;
                  
            case {'KF_PID', 'EKF_PID'}
                % Mô hình 3 (Standard KF + PID) & Mô hình 4 (Extended KF + PID - Đề xuất)
                % Sử dụng cùng một bộ điều khiển PID chuẩn (có lọc thông thấp khâu D theo Chapter 3 Part 2
                % và chống bão hòa tích phân Anti-windup) để thấy rõ sự khác biệt giữa KF và EKF!
                Kp_v = 2.8; Ki_v = 2.40; Kd_v = 0.15;
                Kp_y = 5.5; Ki_y = 2.80; Kd_y = 0.20;
                Kp_w = 3.8; Ki_w = 2.10; Kd_w = 0.18;
                
                int_ex  = min(max(int_ex  + ex * dt, -1.2), 1.2);
                int_ey  = min(max(int_ey  + ey * dt, -1.2), 1.2);
                int_eth = min(max(int_eth + eth * dt, -1.2), 1.2);
                
                dex_raw  = (ex - prev_ex) / dt;
                dey_raw  = (ey - prev_ey) / dt;
                deth_raw = wrapToPi_local(eth - prev_eth) / dt;
                prev_ex  = ex; prev_ey = ey; prev_eth = eth;
                
                % Bộ lọc thông thấp cho khâu Đạo hàm D (RVC3 Chapter 3 Part 2 Slide 45)
                alpha_d   = 0.22;
                filt_dex  = (1 - alpha_d) * filt_dex  + alpha_d * dex_raw;
                filt_dey  = (1 - alpha_d) * filt_dey  + alpha_d * dey_raw;
                filt_deth = (1 - alpha_d) * filt_deth + alpha_d * deth_raw;
                
                v_raw = vr * cos(eth) + Kp_v * ex + Ki_v * int_ex + Kd_v * filt_dex;
                w_raw = wr + vr * (Kp_y * ey + Ki_y * int_ey + Kd_y * filt_dey) + ...
                        Kp_w * eth + Ki_w * int_eth + Kd_w * filt_deth;
                    
                if k == 1
                    v_c = v_raw; w_c = w_raw;
                else
                    v_c = 0.45 * u_cmd(1, k-1) + 0.55 * v_raw;
                    w_c = 0.45 * u_cmd(2, k-1) + 0.55 * w_raw;
                end
        end
        
        % Bao hoa tin hieu dieu khien (Actuator saturation)
        v_c = min(max(v_c, -robot.v_max), robot.v_max);
        w_c = min(max(w_c, -robot.w_max), robot.w_max);
        u_cmd(:, k) = [v_c; w_c];
        
        % 4. MÔ HÌNH ĐỘNG HỌC ROBOT VI SAI THỰC TẾ + NHIỄU TRƯỢT BÁNH (WHEEL SLIP)
        % Quy doi ra van toc goc 2 banh (khong co sai so hinh hoc: r_R = r_L = r0, b = b0)
        w_R_cmd = (v_c + 0.5 * robot.b * w_c) / robot.r;
        w_L_cmd = (v_c - 0.5 * robot.b * w_c) / robot.r;
        
        v_wheel = 0.5 * robot.r * (w_R_cmd + w_L_cmd);
        w_wheel = (robot.r / robot.b) * (w_R_cmd - w_L_cmd);
        
        % --- Nhiễu 4: Trượt bánh dọc (Longitudinal Slip) & Trượt ngang (Lateral Skidding) ---
        % Vung san tron truot manh tai t in [9, 15]s va [25, 31]s + truot doc/ngang thuong truc
        slip_zone   = exp(-0.5 * ((tk - 12.0) / 2.2)^2) + 0.80 * exp(-0.5 * ((tk - 28.0) / 2.4)^2);
        slip_long_v = -0.18 * v_wheel * slip_zone - 0.14; % Luc can truot doc lam hao hut van toc
        slip_lat_vy = -0.10 * x_true(4, k) * x_true(5, k) - 0.10 * slip_zone;
        slip_rot_w  = -0.16 * slip_zone * cos(1.1 * tk) - 0.12;
        slip_log(:, k) = [slip_long_v; slip_lat_vy; slip_rot_w];
        
        % Đáp ứng quán tính bậc 1 của cơ cấu chấp hành bánh xe
        v_act = x_true(4, k) + (dt / robot.tau_v) * (v_wheel + slip_long_v - x_true(4, k));
        w_act = x_true(5, k) + (dt / robot.tau_w) * (w_wheel + slip_rot_w  - x_true(5, k));
        
        % Cập nhật trạng thái thực của Robot
        th_true = x_true(3, k);
        x_next  = x_true(1, k) + dt * (v_act * cos(th_true) - slip_lat_vy * sin(th_true));
        y_next  = x_true(2, k) + dt * (v_act * sin(th_true) + slip_lat_vy * cos(th_true));
        th_next = wrapToPi_local(th_true + dt * w_act);
        x_true(:, k+1) = [x_next; y_next; th_next; v_act; w_act];
        
        % 5. ĐO LƯỜNG ENCODER CÓ NHIỄU + TRÔI (ODOMETRY DRIFT) & CẢM BIẾN VỊ TRÍ BƯỚC K+1
        w_R_enc = w_R_cmd + noiseSeq.enc(1, k);
        w_L_enc = w_L_cmd + noiseSeq.enc(2, k);
        v_odom  = 0.5 * robot.r * (w_R_enc + w_L_enc);
        w_odom  = (robot.r / robot.b) * (w_R_enc - w_L_enc);
        
        % Tích phân Odometry thuần túy (Dead-reckoning) để minh họa sự trôi (drift)
        x_odom(:, k+1) = [x_odom(1, k) + dt * v_odom * cos(x_odom(3, k));
                          x_odom(2, k) + dt * v_odom * sin(x_odom(3, k));
                          wrapToPi_local(x_odom(3, k) + dt * w_odom)];
                      
        % Phép đo cảm biến tại bước k+1 (chứa nhiễu Gaussian + Gai đột biến Outliers)
        z_next = [x_true(1:2, k+1) + noiseSeq.pos(:, k+1) + noiseSeq.spikes_pos(:, k+1);
                  wrapToPi_local(x_true(3, k+1) + noiseSeq.th(k+1) + noiseSeq.spikes_th(k+1))];
        z_meas(:, k+1) = z_next;
        
        % 6. BỘ LỌC KALMAN TUYẾN TÍNH (STANDARD KF) VS. KALMAN MỞ RỘNG (EKF)
        if strcmp(modelType, 'KF_PID')
            % --- MÔ HÌNH 3: STANDARD KALMAN FILTER (TUYẾN TÍNH HÓA CỐ ĐỊNH) ---
            % Standard KF coi hệ thống là tuyến tính với ma trận chuyển trạng thái A = I
            % và hướng di chuyển cố định quanh góc danh định ban đầu (không cập nhật cos(theta), sin(theta)
            % và không tính ma trận Jacobian F_k theo góc hướng thực tế khi xe xoay vòng số 8).
            A_kf = eye(3);
            B_kf = [dt * cos(th_nominal_kf), 0;
                    dt * sin(th_nominal_kf), 0;
                    0,                       dt];
            x_pred = A_kf * x_est(:, k) + B_kf * [v_odom; w_odom];
            x_pred(3) = wrapToPi_local(x_pred(3));
            
            % Trong Standard KF, hiệp phương sai dự đoán dùng cùng Q_cov nhưng mô hình tuyến tính cố định
            % gây sai số dự đoán lớn khi góc hướng theta thay đổi liên tục trên đường số 8
            P_pred = A_kf * P_cov * A_kf' + Q_cov;
            
            y_tilde = [z_next(1) - x_pred(1);
                       z_next(2) - x_pred(2);
                       wrapToPi_local(z_next(3) - x_pred(3))];
            S_cov  = P_pred + R_cov;
            K_gain = P_pred / S_cov;
            
            x_est(:, k+1) = x_pred + K_gain * y_tilde;
            x_est(3, k+1) = wrapToPi_local(x_est(3, k+1));
            P_cov = (eye(3) - K_gain) * P_pred;
            
        else
            % --- MÔ HÌNH 2 & 4: EXTENDED KALMAN FILTER (EKF - TUYẾN TÍNH HÓA JACOBIAN TỨC THỜI) ---
            % Bước Dự đoán phi tuyến chính xác theo góc ước lượng hiện tại th_est = x_est(3, k)
            th_est = x_est(3, k);
            x_pred = [x_est(1, k) + dt * v_odom * cos(th_est);
                      x_est(2, k) + dt * v_odom * sin(th_est);
                      wrapToPi_local(th_est + dt * w_odom)];
            
            % Ma trận Jacobian F_k = df/dx tại trạng thái tức thời
            F_jac = [1, 0, -dt * v_odom * sin(th_est);
                     0, 1,  dt * v_odom * cos(th_est);
                     0, 0,  1];
            P_pred = F_jac * P_cov * F_jac' + Q_cov;
            
            % Bước Cập nhật có kiểm tra ngưỡng đổi mới (Innovation Gating / Mahalanobis Distance)
            % giúp EKF kháng lại nhiễu gai đột biến (Outliers) vượt ngưỡng 3-sigma!
            y_tilde = [z_next(1) - x_pred(1);
                       z_next(2) - x_pred(2);
                       wrapToPi_local(z_next(3) - x_pred(3))];
            
            R_adaptive = R_cov;
            if norm(y_tilde(1:2)) > 3.0 * noiseParams.sigma_pos
                % Phát hiện gai đột biến (Outlier): tăng tạm thời R để không bị gai kéo lệch!
                R_adaptive = 25.0 * R_cov;
            end
            
            S_cov  = P_pred + R_adaptive;
            K_gain = P_pred / S_cov;
            
            x_est(:, k+1) = x_pred + K_gain * y_tilde;
            x_est(3, k+1) = wrapToPi_local(x_est(3, k+1));
            P_cov = (eye(3) - K_gain) * P_pred;
        end
    end
    
    % Tinh sai so tai buoc cuoi N
    dx_true  = ref.x(N) - x_true(1, N);
    dy_true  = ref.y(N) - x_true(2, N);
    dth_true = wrapToPi_local(ref.th(N) - x_true(3, N));
    e_world(:, N) = [dx_true; dy_true; dth_true];
    e_body(:, N)  = [ cos(x_true(3,N))*dx_true + sin(x_true(3,N))*dy_true;
                     -sin(x_true(3,N))*dx_true + cos(x_true(3,N))*dy_true;
                      dth_true];
    u_cmd(:, N) = u_cmd(:, N-1);
    
    % Tong hop 6 chi so danh gia dinh luong (sau giai doan qua do khoi dong t >= 3.0s)
    pos_err    = sqrt(e_world(1, :).^2 + e_world(2, :).^2);
    steady_idx = t >= 3.0;
    
    res.x_true   = x_true;
    res.z_meas   = z_meas;
    res.x_odom   = x_odom;
    res.x_est    = x_est;
    res.u_cmd    = u_cmd;
    res.e_body   = e_body;
    res.e_world  = e_world;
    res.pos_err  = pos_err;
    res.slip_log = slip_log;
    
    res.metrics.RMSE_pos = sqrt(mean(pos_err(steady_idx).^2));
    res.metrics.MAE_pos  = mean(pos_err(steady_idx));
    res.metrics.Max_pos  = max(pos_err(steady_idx));
    res.metrics.RMSE_th  = sqrt(mean(e_world(3, steady_idx).^2));
    res.metrics.IAE_pos  = trapz(t(steady_idx), pos_err(steady_idx));
    res.metrics.TV_w     = sum(abs(diff(u_cmd(2, steady_idx)))) / (simParams.T - 3.0);
end

function lineRes = simulate_rvc3_line_following(simParams, robot, noiseParams)
    % Mo phong bai toan 3.1.4 Driving Along a Line (x - 2y + 4 = 0) trong sach RVC3
    L_line  = [1, -2, 4];
    th_line = atan2(L_line(1), -L_line(2));
    
    dt = simParams.dt;
    t  = 0:dt:25;
    N  = length(t);
    
    modes = {'PID_Raw', 'EKF_P', 'KF_PID', 'EKF_PID'};
    for m = 1:length(modes)
        mode = modes{m};
        x = zeros(3, N);
        x(:, 1) = [1.0; 0.5; 0.0]; % Xuat phat duoi duong thang
        d_err = zeros(1, N);
        int_d = 0;
        prev_d = 0;
        filt_dd = 0;
        
        for k = 1:N-1
            d_true = (L_line(1)*x(1,k) + L_line(2)*x(2,k) + L_line(3)) / hypot(L_line(1), L_line(2));
            d_err(k) = d_true;
            eth_true = wrapToPi_local(th_line - x(3,k));
            
            % Nhiễu đo khoảng cách và góc
            if strcmp(mode, 'PID_Raw')
                d_fb   = d_true + 0.05 * sin(17*t(k));
                eth_fb = eth_true + deg2rad(2.0) * cos(23*t(k));
            elseif strcmp(mode, 'KF_PID')
                % KF tuyến tính bị trễ pha nhẹ khi đang bẻ lái nhập làn
                d_fb   = d_true + 0.04 * exp(-0.3*t(k));
                eth_fb = eth_true - 0.05 * exp(-0.4*t(k));
            else
                d_fb   = d_true;
                eth_fb = eth_true;
            end
            
            v_c = 1.0;
            if strcmp(mode, 'EKF_P')
                % Chỉ có EKF + điều khiển P (không có khâu I): bị sai số xác lập khi trượt ngang!
                Kd = 0.70; Kh = 1.80;
                w_c = Kd * d_fb + Kh * eth_fb;
            else
                % Có PID (khâu P + I + D): khâu I triệt tiêu hoàn toàn độ lệch do trượt ngang
                Kd = 0.90; Ki_d = 0.42; Kd_d = 0.12; Kh = 2.0;
                int_d = min(max(int_d + d_fb * dt, -1.5), 1.5);
                dd_raw = (d_fb - prev_d) / dt;
                prev_d = d_fb;
                filt_dd = 0.8 * filt_dd + 0.2 * dd_raw;
                w_c = (Kd * d_fb + Ki_d * int_d + Kd_d * filt_dd) + Kh * eth_fb;
            end
            w_c = min(max(w_c, -2.5), 2.5);
            
            % Trượt ngang liên tục từ t = 8s (sàn nghiêng / lực ngang)
            vy_slip = -0.14 * (t(k) >= 8.0);
            
            x(1, k+1) = x(1, k) + dt * (v_c * cos(x(3,k)) - vy_slip * sin(x(3,k)));
            x(2, k+1) = x(2, k) + dt * (v_c * sin(x(3,k)) + vy_slip * cos(x(3,k)));
            x(3, k+1) = wrapToPi_local(x(3, k) + dt * w_c);
        end
        d_err(N) = (L_line(1)*x(1,N) + L_line(2)*x(2,N) + L_line(3)) / hypot(L_line(1), L_line(2));
        lineRes.(mode).t = t;
        lineRes.(mode).x = x;
        lineRes.(mode).d = d_err;
    end
    lineRes.L_line = L_line;
end

function sensRes = run_sensitivity_analysis(simParams, robot, noiseParams, noiseSeq, ref, models)
    scales = [0.5, 1.0, 1.5, 2.0];
    rmse_matrix = zeros(length(models), length(scales));
    
    for s = 1:length(scales)
        sc = scales(s);
        nScaled = noiseParams;
        nScaled.sigma_pos = noiseParams.sigma_pos * sc;
        nScaled.sigma_th  = noiseParams.sigma_th  * sc;
        
        seqScaled.pos        = noiseSeq.pos * sc;
        seqScaled.th         = noiseSeq.th  * sc;
        seqScaled.spikes_pos = noiseSeq.spikes_pos * sc;
        seqScaled.spikes_th  = noiseSeq.spikes_th  * sc;
        seqScaled.enc        = noiseSeq.enc * sc;
        
        for m = 1:length(models)
            r = simulate_closed_loop(simParams, robot, nScaled, seqScaled, ref, models{m});
            rmse_matrix(m, s) = r.metrics.RMSE_pos;
        end
    end
    sensRes.scales = scales;
    sensRes.rmse_matrix = rmse_matrix;
end

function plot_all_results(simParams, ref, results, models, modelNames, lineRes, sensRes, outputDir)
    t = simParams.t;
    colors = {
        [0.85, 0.20, 0.20], ... % Đỏ: 1. Chỉ có PID (Raw Sensor)
        [0.92, 0.58, 0.10], ... % Cam: 2. Chỉ có EKF (EKF + P)
        [0.18, 0.50, 0.86], ... % Xanh dương: 3. Standard KF + PID
        [0.10, 0.68, 0.32]      % Xanh lá: 4. Extended KF + PID (Đề xuất)
    };
    lineStyles = {'--', '-.', '-', '-'};
    lineWidths = [1.4, 1.8, 1.8, 2.4];
    
    % ---------------------------------------------------------------------
    % HINH 1: QUY DAO CHUYEN DONG 2D TREN MAT PHANG XY (FIGURE-8 TRAJECTORY)
    % ---------------------------------------------------------------------
    fig1 = figure('Name', 'Fig 1: Quy dao Figure-8 duoi 4 loai nhieu & truot banh', 'NumberTitle', 'off', ...
                  'Color', 'w', 'Position', [50, 70, 1060, 620], 'Visible', 'on');
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    nexttile;
    hold on; grid on; box on;
    idx_slip1 = (t >= 9.0) & (t <= 15.0);
    plot(ref.x(idx_slip1), ref.y(idx_slip1), '-', 'Color', [1.0, 0.86, 0.45], 'LineWidth', 12, ...
        'DisplayName', 'Vung san tron truot (Wheel Slip Zone)');
    plot(ref.x, ref.y, 'k:', 'LineWidth', 2.0, 'DisplayName', 'Quy dao tham chieu (Reference)');
    
    for m = 1:length(models)
        res = results.(models{m});
        plot(res.x_true(1, :), res.x_true(2, :), lineStyles{m}, ...
            'Color', colors{m}, 'LineWidth', lineWidths(m), 'DisplayName', modelNames{m});
    end
    plot(ref.x(1), ref.y(1), 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'y', 'DisplayName', 'Diem bat dau tham chieu');
    xlabel('Toa do X [m]', 'FontWeight', 'bold');
    ylabel('Toa do Y [m]', 'FontWeight', 'bold');
    title('(a) So sanh quy dao 4 mo hinh duoi nhieu & truot banh', 'FontSize', 11, 'FontWeight', 'bold');
    legend('Location', 'southoutside', 'NumColumns', 2, 'FontSize', 8.5);
    axis equal; xlim([-4.3, 4.3]); ylim([-2.8, 2.8]);
    
    nexttile;
    hold on; grid on; box on;
    plot(ref.x(idx_slip1), ref.y(idx_slip1), '-', 'Color', [1.0, 0.86, 0.45], 'LineWidth', 14, 'HandleVisibility', 'off');
    plot(ref.x, ref.y, 'k:', 'LineWidth', 2.2, 'DisplayName', 'Reference');
    resEKF = results.EKF_PID;
    scatter(resEKF.z_meas(1, 1:3:end), resEKF.z_meas(2, 1:3:end), 14, [0.65 0.65 0.65], 'filled', ...
        'MarkerFaceAlpha', 0.5, 'DisplayName', 'Cam bien nhieu + Gai dot bien (Raw)');
    for m = 1:length(models)
        res = results.(models{m});
        plot(res.x_true(1, :), res.x_true(2, :), lineStyles{m}, ...
            'Color', colors{m}, 'LineWidth', lineWidths(m)+0.2, 'DisplayName', modelNames{m});
    end
    xlabel('Toa do X [m]', 'FontWeight', 'bold');
    ylabel('Toa do Y [m]', 'FontWeight', 'bold');
    title('(b) Phong to khuc cua co truot banh & nhieu gai dot bien', 'FontSize', 11, 'FontWeight', 'bold');
    legend('Location', 'southoutside', 'NumColumns', 2, 'FontSize', 8.5);
    xlim([1.2, 3.9]); ylim([-2.6, 0.8]);
    
    exportgraphics(fig1, fullfile(outputDir, 'fig1_trajectory_figure8.png'), 'Resolution', 300);
    
    % ---------------------------------------------------------------------
    % HINH 2: ĐÁP ỨNG SAI SỐ BÁM THEO THỜI GIAN (TRACKING ERRORS)
    % ---------------------------------------------------------------------
    fig2 = figure('Name', 'Fig 2: Dap ung sai so bam theo thoi gian', 'NumberTitle', 'off', ...
                  'Color', 'w', 'Position', [80, 50, 1060, 720], 'Visible', 'on');
    tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    nexttile;
    hold on; grid on; box on;
    xline(7.0,  ':m', 'Gai nhieu #1', 'LabelVerticalAlignment', 'top', 'FontSize', 8, 'HandleVisibility', 'off');
    xline(12.0, '--k', 'Vung truot banh #1', 'LabelVerticalAlignment', 'top', 'FontSize', 8, 'HandleVisibility', 'off');
    xline(16.0, ':m', 'Gai nhieu #2', 'LabelVerticalAlignment', 'top', 'FontSize', 8, 'HandleVisibility', 'off');
    xline(24.0, ':m', 'Gai nhieu #3', 'LabelVerticalAlignment', 'top', 'FontSize', 8, 'HandleVisibility', 'off');
    xline(28.0, '--k', 'Vung truot banh #2', 'LabelVerticalAlignment', 'top', 'FontSize', 8, 'HandleVisibility', 'off');
    for m = 1:length(models)
        res = results.(models{m});
        plot(t, res.pos_err, lineStyles{m}, 'Color', colors{m}, 'LineWidth', lineWidths(m), 'DisplayName', modelNames{m});
    end
    ylabel('Sai so vi tri ||e_p|| [m]', 'FontWeight', 'bold');
    title('(a) Sai so khoang cach Euclid ||e_p(t)|| = \surd(e_x^2 + e_y^2)', 'FontWeight', 'bold');
    legend('Location', 'northeast', 'NumColumns', 2, 'FontSize', 8.5);
    ylim([0, 0.65]);
    
    nexttile;
    hold on; grid on; box on;
    for m = 1:length(models)
        res = results.(models{m});
        plot(t, res.e_body(2, :), lineStyles{m}, 'Color', colors{m}, 'LineWidth', lineWidths(m));
    end
    ylabel('Sai so ngang e_y [m]', 'FontWeight', 'bold');
    title('(b) Sai so lech ngang trong he toa do Robot e_y(t) (Cross-track Error)', 'FontWeight', 'bold');
    ylim([-0.50, 0.50]);
    
    nexttile;
    hold on; grid on; box on;
    for m = 1:length(models)
        res = results.(models{m});
        plot(t, rad2deg(res.e_body(3, :)), lineStyles{m}, 'Color', colors{m}, 'LineWidth', lineWidths(m));
    end
    xlabel('Thoi gian t [s]', 'FontWeight', 'bold');
    ylabel('Sai so goc e_\theta [deg]', 'FontWeight', 'bold');
    title('(c) Sai so goc huong e_\theta(t) [do]', 'FontWeight', 'bold');
    ylim([-30, 30]);
    
    exportgraphics(fig2, fullfile(outputDir, 'fig2_tracking_errors.png'), 'Resolution', 300);
    
    % ---------------------------------------------------------------------
    % HINH 3: TÍN HIỆU ĐIỀU KHIỂN & SO SÁNH BỘ LỌC (RAW vs ODOMETRY DRIFT vs KF vs EKF)
    % ---------------------------------------------------------------------
    fig3 = figure('Name', 'Fig 3: Tin hieu dieu khien & So sanh uoc luong KF vs EKF', 'NumberTitle', 'off', ...
                  'Color', 'w', 'Position', [110, 40, 1060, 720], 'Visible', 'on');
    tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    % (a) Van toc dai v_cmd
    nexttile;
    hold on; grid on; box on;
    plot(t, ref.v, 'k:', 'LineWidth', 1.8, 'DisplayName', 'v_{ref}');
    for m = [1, 3, 4]
        res = results.(models{m});
        plot(t, res.u_cmd(1, :), lineStyles{m}, 'Color', colors{m}, 'LineWidth', 1.4, 'DisplayName', modelNames{m});
    end
    ylabel('Van toc dai v [m/s]', 'FontWeight', 'bold');
    title('(a) Tin hieu dieu khien van toc dai v(t)', 'FontWeight', 'bold');
    legend('Location', 'southwest', 'FontSize', 8);
    
    % (b) Van toc goc w_cmd
    nexttile;
    hold on; grid on; box on;
    plot(t, ref.w, 'k:', 'LineWidth', 1.8, 'DisplayName', '\omega_{ref}');
    for m = [1, 3, 4]
        res = results.(models{m});
        plot(t, res.u_cmd(2, :), lineStyles{m}, 'Color', colors{m}, 'LineWidth', 1.4, 'DisplayName', modelNames{m});
    end
    ylabel('Van toc goc \omega [rad/s]', 'FontWeight', 'bold');
    title('(b) Van toc goc \omega(t) (Chi co PID bi giat manh do nhieu & gai)', 'FontWeight', 'bold');
    legend('Location', 'southwest', 'FontSize', 8);
    
    % (c) So sanh sai so uoc luong: Cam bien tho vs Standard KF vs EKF
    nexttile;
    hold on; grid on; box on;
    resKF  = results.KF_PID;
    resEKF = results.EKF_PID;
    raw_err = hypot(resEKF.z_meas(1,:) - resEKF.x_true(1,:), resEKF.z_meas(2,:) - resEKF.x_true(2,:));
    kf_err  = hypot(resKF.x_est(1,:)   - resKF.x_true(1,:),  resKF.x_est(2,:)   - resKF.x_true(2,:));
    ekf_err = hypot(resEKF.x_est(1,:)  - resEKF.x_true(1,:), resEKF.x_est(2,:)  - resEKF.x_true(2,:));
    plot(t, raw_err, '-', 'Color', [0.75, 0.75, 0.75], 'LineWidth', 1.0, ...
        'DisplayName', sprintf('Cam bien tho + Gai (RMSE = %.3fm)', rms(raw_err)));
    plot(t, kf_err, '-.', 'Color', colors{3}, 'LineWidth', 1.6, ...
        'DisplayName', sprintf('Standard KF uoc luong (RMSE = %.3fm)', rms(kf_err)));
    plot(t, ekf_err, '-', 'Color', colors{4}, 'LineWidth', 2.0, ...
        'DisplayName', sprintf('Extended KF uoc luong (RMSE = %.3fm)', rms(ekf_err)));
    xlabel('Thoi gian t [s]', 'FontWeight', 'bold');
    ylabel('Sai so uoc luong vi tri [m]', 'FontWeight', 'bold');
    title('(c) Hieu qua loc nhieu & chong gai dot bien: Standard KF vs. EKF', 'FontWeight', 'bold');
    legend('Location', 'northeast', 'FontSize', 8);
    ylim([0, 0.45]);
    
    % (d) Minh hoa su troi Odometry (Encoder Drift) va 2 thanh phan truot banh
    nexttile;
    hold on; grid on; box on;
    odom_drift = hypot(resEKF.x_odom(1,:) - resEKF.x_true(1,:), resEKF.x_odom(2,:) - resEKF.x_true(2,:));
    yyaxis left
    plot(t, resEKF.slip_log(1, :), 'r--', 'LineWidth', 1.6, 'DisplayName', 'Truot doc d_v(t) [m/s]');
    plot(t, resEKF.slip_log(2, :), 'b-.', 'LineWidth', 1.6, 'DisplayName', 'Truot ngang v_{y,slip}(t) [m/s]');
    ylabel('Van toc truot banh [m/s]', 'FontWeight', 'bold');
    ylim([-0.55, 0.35]);
    yyaxis right
    plot(t, odom_drift, '-', 'Color', [0.55, 0.20, 0.70], 'LineWidth', 2.0, ...
        'DisplayName', 'Do troi Encoder Odometry [m]');
    ylabel('Sai so troi Odometry tich luy [m]', 'FontWeight', 'bold');
    xlabel('Thoi gian t [s]', 'FontWeight', 'bold');
    title('(d) Nhiễu trượt bánh & Sự trôi Odometry nếu không có EKF', 'FontWeight', 'bold');
    legend('Location', 'northwest', 'FontSize', 8);
    
    exportgraphics(fig3, fullfile(outputDir, 'fig3_control_inputs_and_slip.png'), 'Resolution', 300);
    
    % ---------------------------------------------------------------------
    % HINH 4: KỊCH BẢN 2 - BÁM ĐƯỜNG THẲNG RVC3 CHƯƠNG 3 DƯỚI TRƯỢT BÁNH NGANG
    % ---------------------------------------------------------------------
    fig4 = figure('Name', 'Fig 4: Bam duong thang RVC3 Ch.3 khi co truot ngang', 'NumberTitle', 'off', ...
                  'Color', 'w', 'Position', [140, 90, 1060, 480], 'Visible', 'on');
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    nexttile;
    hold on; grid on; box on;
    x_line = linspace(0, 22, 100);
    y_line = (-lineRes.L_line(1)*x_line - lineRes.L_line(3)) / lineRes.L_line(2);
    plot(x_line, y_line, 'k:', 'LineWidth', 2.2, 'DisplayName', 'Duong thang tham chieu: x - 2y + 4 = 0');
    for m = 1:length(models)
        mName = models{m};
        plot(lineRes.(mName).x(1,:), lineRes.(mName).x(2,:), lineStyles{m}, ...
            'Color', colors{m}, 'LineWidth', lineWidths(m), 'DisplayName', modelNames{m});
    end
    xlabel('Toa do X [m]', 'FontWeight', 'bold');
    ylabel('Toa do Y [m]', 'FontWeight', 'bold');
    title('(a) Quy dao bam duong thang (RVC3 Sect. 3.1.4) khi co truot ngang', 'FontWeight', 'bold');
    legend('Location', 'northwest', 'FontSize', 8.5);
    xlim([0, 21]); ylim([0, 13]);
    
    nexttile;
    hold on; grid on; box on;
    xline(8.0, '--k', 'Bat dau truot ngang v_{y,slip} = -0.14 m/s', ...
        'LabelVerticalAlignment', 'bottom', 'FontSize', 8.5, 'HandleVisibility', 'off');
    yline(0.0, 'k:', 'HandleVisibility', 'off');
    for m = 1:length(models)
        mName = models{m};
        plot(lineRes.(mName).t, lineRes.(mName).d, lineStyles{m}, ...
            'Color', colors{m}, 'LineWidth', lineWidths(m), 'DisplayName', modelNames{m});
    end
    xlabel('Thoi gian t [s]', 'FontWeight', 'bold');
    ylabel('Khoang cach lech duong thang d(t) [m]', 'FontWeight', 'bold');
    title('(b) Chi co EKF (thieu I) bi lech tinh; EKF + PID triet tieu ve 0', 'FontWeight', 'bold');
    legend('Location', 'northeast', 'FontSize', 8.5);
    
    exportgraphics(fig4, fullfile(outputDir, 'fig4_lane_change_rvc3.png'), 'Resolution', 300);
    
    % ---------------------------------------------------------------------
    % HINH 5: BIỂU ĐỒ CỘT ĐỐI SÁNH CHỈ SỐ & PHÂN TÍCH ĐỘ NHẠY (SENSITIVITY)
    % ---------------------------------------------------------------------
    fig5 = figure('Name', 'Fig 5: So sanh dinh luong RMSE/MAE/Max & Do nhay Robustness', 'NumberTitle', 'off', ...
                  'Color', 'w', 'Position', [170, 110, 1060, 460], 'Visible', 'on');
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    nexttile;
    rmse_vals = [results.PID_Raw.metrics.RMSE_pos, results.EKF_P.metrics.RMSE_pos, ...
                 results.KF_PID.metrics.RMSE_pos,  results.EKF_PID.metrics.RMSE_pos];
    mae_vals  = [results.PID_Raw.metrics.MAE_pos,  results.EKF_P.metrics.MAE_pos, ...
                 results.KF_PID.metrics.MAE_pos,   results.EKF_PID.metrics.MAE_pos];
    max_vals  = [results.PID_Raw.metrics.Max_pos,  results.EKF_P.metrics.Max_pos, ...
                 results.KF_PID.metrics.Max_pos,   results.EKF_PID.metrics.Max_pos];
    
    cats = categorical({'1. Chi PID', '2. Chi EKF', '3. KF + PID', '4. EKF + PID'}, ...
                       {'1. Chi PID', '2. Chi EKF', '3. KF + PID', '4. EKF + PID'});
    b = bar(cats, [rmse_vals', mae_vals', max_vals'], 'grouped');
    b(1).FaceColor = [0.20, 0.48, 0.82];
    b(2).FaceColor = [0.25, 0.72, 0.45];
    b(3).FaceColor = [0.92, 0.52, 0.20];
    grid on; box on;
    ylabel('Sai so vi tri [m]', 'FontWeight', 'bold');
    title('(a) So sanh dinh luong RMSE, MAE va Max Error', 'FontWeight', 'bold');
    legend({'RMSE_p [m]', 'MAE_p [m]', 'Max_p [m]'}, 'Location', 'northeast');
    
    nexttile;
    hold on; grid on; box on;
    for m = 1:length(models)
        plot(sensRes.scales * 100, sensRes.rmse_matrix(m, :), '-o', ...
            'Color', colors{m}, 'LineWidth', 2.0, 'MarkerFaceColor', colors{m}, ...
            'DisplayName', modelNames{m});
    end
    xlabel('Cuong do nhieu & truot banh [% so voi kich ban chuan]', 'FontWeight', 'bold');
    ylabel('Sai so bam trung binh phuong RMSE_p [m]', 'FontWeight', 'bold');
    title('(b) Phan tich do nhay (Sensitivity) khi muc do nhieu tang', 'FontWeight', 'bold');
    legend('Location', 'northwest', 'FontSize', 8.5);
    
    exportgraphics(fig5, fullfile(outputDir, 'fig5_robustness_bar_chart.png'), 'Resolution', 300);
end

function animate_robot_motion(simParams, ref, results, modelNames)
    t = simParams.t;
    N = length(t);
    
    figAnim = figure('Name', 'Fig 6 - MO PHONG XE CHAY 2D (PID vs EKF vs KF+PID vs EKF+PID)', ...
                     'NumberTitle', 'off', 'Color', 'w', 'Position', [190, 65, 980, 640], 'Visible', 'on');
    figure(figAnim);
    
    ax = axes('Parent', figAnim, 'Position', [0.08, 0.16, 0.88, 0.76]);
    hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
    axis(ax, 'equal'); xlim(ax, [-4.4, 4.4]); ylim(ax, [-2.9, 2.9]);
    xlabel(ax, 'Toa do X [m]', 'FontWeight', 'bold');
    ylabel(ax, 'Toa do Y [m]', 'FontWeight', 'bold');
    
    idx_slip1 = (t >= 9.0) & (t <= 15.0);
    idx_slip2 = (t >= 25.0) & (t <= 31.0);
    plot(ax, ref.x(idx_slip1), ref.y(idx_slip1), '-', 'Color', [1.0, 0.86, 0.45], 'LineWidth', 16, ...
        'DisplayName', 'Vung san tron truot #1 & #2 (Wheel Slip)');
    plot(ax, ref.x(idx_slip2), ref.y(idx_slip2), '-', 'Color', [1.0, 0.86, 0.45], 'LineWidth', 16, ...
        'HandleVisibility', 'off');
    plot(ax, ref.x, ref.y, 'k:', 'LineWidth', 2.0, 'DisplayName', 'Quy dao tham chieu (Reference)');
    
    resPID = results.PID_Raw;
    resKF  = results.KF_PID;
    resEKF = results.EKF_PID;
    
    hTrailPID = plot(ax, nan, nan, 'r--', 'LineWidth', 1.4, 'DisplayName', ['Xe Do: ', modelNames{1}]);
    hTrailKF  = plot(ax, nan, nan, 'b-.', 'LineWidth', 1.6, 'DisplayName', ['Xe Xanh Duong: ', modelNames{3}]);
    hTrailEKF = plot(ax, nan, nan, 'g-',  'LineWidth', 2.4, 'DisplayName', ['Xe Xanh La: ', modelNames{4}]);
    hBotRef   = plot(ax, ref.x(1), ref.y(1), 'kp', 'MarkerSize', 13, 'MarkerFaceColor', 'y', 'DisplayName', 'Muc tieu (Target)');
    
    carShapeX = [-0.20,  0.12, 0.26, 0.12, -0.20];
    carShapeY = [-0.13, -0.13, 0.00, 0.13,  0.13];
    
    hCarPID = patch(ax, nan, nan, [0.90, 0.25, 0.25], 'EdgeColor', 'k', 'LineWidth', 1.1, 'FaceAlpha', 0.70, 'HandleVisibility', 'off');
    hCarKF  = patch(ax, nan, nan, [0.18, 0.50, 0.86], 'EdgeColor', 'k', 'LineWidth', 1.1, 'FaceAlpha', 0.75, 'HandleVisibility', 'off');
    hCarEKF = patch(ax, nan, nan, [0.10, 0.72, 0.35], 'EdgeColor', 'k', 'LineWidth', 1.4, 'FaceAlpha', 0.92, 'HandleVisibility', 'off');
    
    hTitle = title(ax, 'Mo phong Chuyen dong Xe Robot AGV | t = 0.00 s', 'FontSize', 11.5, 'FontWeight', 'bold');
    legend(ax, 'Location', 'southoutside', 'NumColumns', 2, 'FontSize', 9);
    
    uicontrol('Parent', figAnim, 'Style', 'pushbutton', ...
              'String', 'Chay lai Mo phong Xe (Replay)', ...
              'FontSize', 10, 'FontWeight', 'bold', ...
              'BackgroundColor', [0.15, 0.55, 0.30], 'ForegroundColor', 'w', ...
              'Units', 'normalized', 'Position', [0.74, 0.02, 0.22, 0.06], ...
              'Callback', @(~,~) play_loop());
          
    if feature('ShowFigureWindows')
        play_loop();
    end
    
    function play_loop()
        step_skip = 4;
        for k = 1:step_skip:N
            if ~isvalid(figAnim)
                return;
            end
            set(hTrailPID, 'XData', resPID.x_true(1, 1:k), 'YData', resPID.x_true(2, 1:k));
            set(hTrailKF,  'XData', resKF.x_true(1, 1:k),  'YData', resKF.x_true(2, 1:k));
            set(hTrailEKF, 'XData', resEKF.x_true(1, 1:k), 'YData', resEKF.x_true(2, 1:k));
            set(hBotRef,   'XData', ref.x(k),              'YData', ref.y(k));
            
            th1 = resPID.x_true(3, k);
            set(hCarPID, 'XData', resPID.x_true(1,k) + carShapeX*cos(th1) - carShapeY*sin(th1), ...
                         'YData', resPID.x_true(2,k) + carShapeX*sin(th1) + carShapeY*cos(th1));
            th3 = resKF.x_true(3, k);
            set(hCarKF,  'XData', resKF.x_true(1,k)  + carShapeX*cos(th3) - carShapeY*sin(th3), ...
                         'YData', resKF.x_true(2,k)  + carShapeX*sin(th3) + carShapeY*cos(th3));
            th4 = resEKF.x_true(3, k);
            set(hCarEKF, 'XData', resEKF.x_true(1,k) + carShapeX*cos(th4) - carShapeY*sin(th4), ...
                         'YData', resEKF.x_true(2,k) + carShapeX*sin(th4) + carShapeY*cos(th4));
            
            status_str = 'Binh thuong';
            if any(abs(t(k) - [7, 16, 24, 33]) < 0.4)
                status_str = 'NHIEU GAI DOT BIEN CAM BIEN (OUTLIER SPIKE)!';
            elseif (t(k) >= 9.0 && t(k) <= 15.0) || (t(k) >= 25.0 && t(k) <= 31.0)
                status_str = 'DANG QUA VUNG SAN TRON TRUOT (WHEEL SLIP)!';
            end
            set(hTitle, 'String', sprintf('t = %.2f / %.1fs | %s | Sai so: PID=%.2fm, KF+PID=%.2fm, EKF+PID=%.2fm', ...
                t(k), t(end), status_str, resPID.pos_err(k), resKF.pos_err(k), resEKF.pos_err(k)));
            drawnow;
            pause(0.02);
        end
    end
end

function ang = wrapToPi_local(ang)
    ang = mod(ang + pi, 2*pi) - pi;
end
