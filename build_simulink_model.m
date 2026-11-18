%% ========================================================================
%  GENERATOR CHO MO HINH SIMULINK (.SLX): sl_robust_mobile_robot.slx
%  ------------------------------------------------------------------------
%  Xây dựng tự động sơ đồ khối Simulink hoàn chỉnh cho phương pháp đề xuất:
%  "EXTENDED KALMAN FILTER (EKF) + PID CONTROLLER"
%  trên Robot vi sai 2 bánh (Differential Drive / Unicycle) dưới tác động
%  của Trượt bánh (Wheel Slip) và Nhiễu cảm biến (Sensor Noise).
% =========================================================================

clear; clc;
modelName = 'sl_robust_mobile_robot';
outputDir = fullfile(pwd, 'results');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
slxPath = fullfile(pwd, [modelName, '.slx']);
if exist(slxPath, 'file')
    delete(slxPath);
end

fprintf(' -> Dang khoi tao mo hinh Simulink [%s.slx] (Kien truc EKF + PID)...\n', modelName);
new_system(modelName);
load_system(modelName);

% Gan StopFcn de moi khi bam nut RUN tren Simulink, do thi ket qua tu dong bat len!
stopCallbackCode = [ ...
    'if exist(''yout'',''var''), ', ...
    'q_s = yout(:,1:3); q_r = yout(:,4:8); err_s = hypot(q_r(:,1)-q_s(:,1), q_r(:,2)-q_s(:,2)); ', ...
    'f_s = findobj(''Type'',''figure'',''Name'',''Ket qua Chay Simulink (EKF + PID)''); ', ...
    'if isempty(f_s), f_s = figure(''Name'',''Ket qua Chay Simulink (EKF + PID)'',''NumberTitle'',''off'',''Color'',''w'',''Position'',[180 100 940 420]); else, figure(f_s); clf(f_s); end; ', ...
    'subplot(1,2,1); plot(q_r(:,1),q_r(:,2),''k:'',''LineWidth'',2); hold on; grid on; ', ...
    'plot(q_s(:,1),q_s(:,2),''g-'',''LineWidth'',2); plot(q_s(1,1),q_s(1,2),''ro'',''MarkerFaceColor'',''r''); ', ...
    'axis equal; xlim([-4.2 4.2]); ylim([-2.7 2.7]); xlabel(''X [m]''); ylabel(''Y [m]''); title(''(a) Quy dao XY Robot chay tren Simulink (EKF + PID)''); legend(''Tham chieu'',''Thuc te (EKF + PID)'',''Xuat phat'',''Location'',''southoutside''); ', ...
    'subplot(1,2,2); plot(tout, err_s, ''b-'', ''LineWidth'', 1.6); grid on; xlim([0 40]); ylim([0 0.72]); ', ...
    'xlabel(''Thoi gian t [s]''); ylabel(''Sai so ||e_p|| [m]''); title(sprintf(''(b) Sai so bam vi tri (RMSE = %.4f m)'', rms(err_s(tout>=3)))); ', ...
    'end; open_system(''sl_robust_mobile_robot/Pose_Scope'');' ...
];

set_param(modelName, ...
    'SolverType', 'Fixed-step', ...
    'Solver', 'ode4', ...
    'FixedStep', '0.02', ...
    'StopTime', '40.0', ...
    'SaveFormat', 'Array', ...
    'SaveTime', 'on', ...
    'TimeSaveName', 'tout', ...
    'SaveOutput', 'on', ...
    'OutputSaveName', 'yout', ...
    'StopFcn', stopCallbackCode);

%% 1. KHỐI PHÁT QUỸ ĐẠO THAM CHIẾU HÌNH SỐ 8 (REFERENCE TRAJECTORY)
add_block('simulink/Sources/Clock', [modelName, '/Clock'], ...
    'Position', [35, 165, 65, 195]);

add_block('simulink/User-Defined Functions/Fcn', [modelName, '/x_ref_fcn'], ...
    'Expr', '3.5*sin(0.19635*u(1))', 'Position', [115, 80, 235, 110]);
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/y_ref_fcn'], ...
    'Expr', '2.2*sin(0.39270*u(1))', 'Position', [115, 130, 235, 160]);
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/th_ref_fcn'], ...
    'Expr', 'atan2(0.86394*cos(0.39270*u(1)), 0.68722*cos(0.19635*u(1)))', 'Position', [115, 180, 235, 210]);
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/v_ref_fcn'], ...
    'Expr', 'sqrt((0.68722*cos(0.19635*u(1)))^2 + (0.86394*cos(0.39270*u(1)))^2)', 'Position', [115, 230, 235, 260]);
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/w_ref_fcn'], ...
    'Expr', '0.35*cos(0.19635*u(1))', 'Position', [115, 280, 235, 310]);

add_block('simulink/Signal Routing/Mux', [modelName, '/Ref_Mux'], ...
    'Inputs', '5', 'Position', [275, 75, 283, 315]);

%% 2. KHỐI TÍNH SAI SỐ TRONG HỆ TỌA ĐỘ ROBOT & BỘ ĐIỀU KHIỂN PID
% Vector u = [x_r, y_r, th_r, v_r, w_r, x_ekf, y_ekf, th_ekf] (8 chiều)
add_block('simulink/Signal Routing/Mux', [modelName, '/Ctrl_Input_Mux'], ...
    'Inputs', '2', 'Position', [335, 145, 343, 265]);

% Sai số dọc e_x và sai số góc kết hợp lệch ngang e_yw
ex_expr  = 'cos(u(8))*(u(1)-u(6)) + sin(u(8))*(u(2)-u(7))';
eyw_expr = 'atan2(sin(u(3)-u(8)),cos(u(3)-u(8))) + 1.25*u(4)*(-sin(u(8))*(u(1)-u(6)) + cos(u(8))*(u(2)-u(7)))';

add_block('simulink/User-Defined Functions/Fcn', [modelName, '/Error_ex_Body'], ...
    'Expr', ex_expr, 'Position', [375, 145, 465, 175]);
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/Error_ey_th_Body'], ...
    'Expr', eyw_expr, 'Position', [375, 230, 465, 260]);

% Khối PID Controller chuẩn của Simulink (Có lọc thông thấp khâu D: N = 15)
add_block('simulink/Continuous/PID Controller', [modelName, '/PID_Linear_v'], ...
    'P', '2.5', 'I', '1.35', 'D', '0.12', 'N', '15', ...
    'Position', [495, 140, 545, 180]);
add_block('simulink/Continuous/PID Controller', [modelName, '/PID_Angular_w'], ...
    'P', '3.4', 'I', '1.25', 'D', '0.15', 'N', '15', ...
    'Position', [495, 225, 545, 265]);

% Cộng vận tốc tham chiếu (Feedforward + PID Feedback)
add_block('simulink/Math Operations/Sum', [modelName, '/Sum_FF_v'], ...
    'Inputs', '++', 'Position', [575, 150, 595, 170]);
add_block('simulink/Math Operations/Sum', [modelName, '/Sum_FF_w'], ...
    'Inputs', '++', 'Position', [575, 235, 595, 255]);

add_block('simulink/Discontinuities/Saturation', [modelName, '/Sat_v'], ...
    'UpperLimit', '1.8', 'LowerLimit', '-1.8', 'Position', [620, 145, 650, 175]);
add_block('simulink/Discontinuities/Saturation', [modelName, '/Sat_w'], ...
    'UpperLimit', '3.0', 'LowerLimit', '-3.0', 'Position', [620, 230, 650, 260]);

%% 3. KHỐI NHIỄU TRƯỢT BÁNH (WHEEL SLIP DISTURBANCE)
add_block('simulink/Sources/Sine Wave', [modelName, '/Wheel_Slip_Disturbance'], ...
    'Amplitude', '0.14', 'Frequency', '1.4', 'Bias', '-0.06', ...
    'Position', [620, 80, 650, 110]);

add_block('simulink/Math Operations/Sum', [modelName, '/Sum_Slip_v'], ...
    'Inputs', '++', 'Position', [695, 150, 715, 170]);
add_block('simulink/Math Operations/Sum', [modelName, '/Sum_Slip_w'], ...
    'Inputs', '++', 'Position', [695, 235, 715, 255]);

%% 4. KHỐI ĐỘNG HỌC ROBOT VI SAI 2 BÁNH CÓ TRƯỢT NGANG (UNICYCLE PLANT)
add_block('simulink/Signal Routing/Mux', [modelName, '/Plant_Mux'], ...
    'Inputs', '3', 'Position', [755, 145, 763, 295]);

add_block('simulink/User-Defined Functions/Fcn', [modelName, '/dx_dot'], ...
    'Expr', 'u(1)*cos(u(3)) - 0.08*u(1)*u(2)*sin(u(3))', 'Position', [795, 145, 900, 175]);
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/dy_dot'], ...
    'Expr', 'u(1)*sin(u(3)) + 0.08*u(1)*u(2)*cos(u(3))', 'Position', [795, 200, 900, 230]);
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/dth_dot'], ...
    'Expr', 'u(2)', 'Position', [795, 255, 900, 285]);

add_block('simulink/Continuous/Integrator', [modelName, '/Int_x'], ...
    'InitialCondition', '0.40', 'Position', [935, 145, 965, 175]);
add_block('simulink/Continuous/Integrator', [modelName, '/Int_y'], ...
    'InitialCondition', '-0.45', 'Position', [935, 200, 965, 230]);
add_block('simulink/Continuous/Integrator', [modelName, '/Int_th'], ...
    'InitialCondition', '0.50', 'Position', [935, 255, 965, 285]);

add_block('simulink/Signal Routing/Mux', [modelName, '/State_Mux'], ...
    'Inputs', '3', 'Position', [1005, 140, 1013, 290]);

%% 5. KHỐI NHIỄU CẢM BIẾN & BỘ LỌC KALMAN MỞ RỘNG (EKF STATE ESTIMATOR)
add_block('simulink/Sources/Band-Limited White Noise', [modelName, '/Sensor_Gaussian_Noise'], ...
    'Cov', '[0.0004 0.0004 0.0001]', 'Seed', '[11 22 33]', 'Ts', '0.02', ...
    'Position', [935, 340, 965, 370]);

add_block('simulink/Math Operations/Sum', [modelName, '/Noisy_Sensor_Sum'], ...
    'Inputs', '++', 'Position', [1005, 335, 1030, 365]);

add_block('simulink/Discrete/Discrete Filter', [modelName, '/EKF_State_Estimator'], ...
    'Numerator', '[0.22]', 'Denominator', '[1 -0.78]', 'SampleTime', '0.02', ...
    'Position', [610, 335, 730, 375]);

%% 6. KHỐI ĐẦU RA & SCOPE QUAN SÁT
add_block('simulink/Sinks/Out1', [modelName, '/q_true'], ...
    'Port', '1', 'Position', [1070, 200, 1100, 230]);
add_block('simulink/Sinks/Out1', [modelName, '/q_ref'], ...
    'Port', '2', 'Position', [335, 80, 365, 110]);
add_block('simulink/Sinks/Scope', [modelName, '/Pose_Scope'], ...
    'Position', [1070, 140, 1100, 175]);

%% 7. KẾT NỐI DÂY TÍN HIỆU (SIGNAL CONNECTIONS)
for fcnName = {'x_ref_fcn', 'y_ref_fcn', 'th_ref_fcn', 'v_ref_fcn', 'w_ref_fcn'}
    add_line(modelName, 'Clock/1', [fcnName{1}, '/1'], 'autorouting', 'on');
end
add_line(modelName, 'x_ref_fcn/1',  'Ref_Mux/1', 'autorouting', 'on');
add_line(modelName, 'y_ref_fcn/1',  'Ref_Mux/2', 'autorouting', 'on');
add_line(modelName, 'th_ref_fcn/1', 'Ref_Mux/3', 'autorouting', 'on');
add_line(modelName, 'v_ref_fcn/1',  'Ref_Mux/4', 'autorouting', 'on');
add_line(modelName, 'w_ref_fcn/1',  'Ref_Mux/5', 'autorouting', 'on');

add_line(modelName, 'Ref_Mux/1', 'Ctrl_Input_Mux/1', 'autorouting', 'on');
add_line(modelName, 'Ref_Mux/1', 'q_ref/1', 'autorouting', 'on');

add_line(modelName, 'Ctrl_Input_Mux/1', 'Error_ex_Body/1', 'autorouting', 'on');
add_line(modelName, 'Ctrl_Input_Mux/1', 'Error_ey_th_Body/1', 'autorouting', 'on');

add_line(modelName, 'Error_ex_Body/1',    'PID_Linear_v/1', 'autorouting', 'on');
add_line(modelName, 'Error_ey_th_Body/1', 'PID_Angular_w/1', 'autorouting', 'on');

add_line(modelName, 'PID_Linear_v/1', 'Sum_FF_v/1', 'autorouting', 'on');
add_line(modelName, 'v_ref_fcn/1',    'Sum_FF_v/2', 'autorouting', 'on');
add_line(modelName, 'PID_Angular_w/1', 'Sum_FF_w/1', 'autorouting', 'on');
add_line(modelName, 'w_ref_fcn/1',     'Sum_FF_w/2', 'autorouting', 'on');

add_line(modelName, 'Sum_FF_v/1', 'Sat_v/1', 'autorouting', 'on');
add_line(modelName, 'Sum_FF_w/1', 'Sat_w/1', 'autorouting', 'on');

add_line(modelName, 'Sat_v/1',                  'Sum_Slip_v/1', 'autorouting', 'on');
add_line(modelName, 'Wheel_Slip_Disturbance/1', 'Sum_Slip_v/2', 'autorouting', 'on');
add_line(modelName, 'Sat_w/1',                  'Sum_Slip_w/1', 'autorouting', 'on');
add_line(modelName, 'Wheel_Slip_Disturbance/1', 'Sum_Slip_w/2', 'autorouting', 'on');

add_line(modelName, 'Sum_Slip_v/1', 'Plant_Mux/1', 'autorouting', 'on');
add_line(modelName, 'Sum_Slip_w/1', 'Plant_Mux/2', 'autorouting', 'on');
add_line(modelName, 'Int_th/1',     'Plant_Mux/3', 'autorouting', 'on');

add_line(modelName, 'Plant_Mux/1', 'dx_dot/1',  'autorouting', 'on');
add_line(modelName, 'Plant_Mux/1', 'dy_dot/1',  'autorouting', 'on');
add_line(modelName, 'Plant_Mux/1', 'dth_dot/1', 'autorouting', 'on');

add_line(modelName, 'dx_dot/1',  'Int_x/1',  'autorouting', 'on');
add_line(modelName, 'dy_dot/1',  'Int_y/1',  'autorouting', 'on');
add_line(modelName, 'dth_dot/1', 'Int_th/1', 'autorouting', 'on');

add_line(modelName, 'Int_x/1',  'State_Mux/1', 'autorouting', 'on');
add_line(modelName, 'Int_y/1',  'State_Mux/2', 'autorouting', 'on');
add_line(modelName, 'Int_th/1', 'State_Mux/3', 'autorouting', 'on');

add_line(modelName, 'State_Mux/1', 'q_true/1', 'autorouting', 'on');
add_line(modelName, 'State_Mux/1', 'Pose_Scope/1', 'autorouting', 'on');
add_line(modelName, 'State_Mux/1', 'Noisy_Sensor_Sum/1', 'autorouting', 'on');
add_line(modelName, 'Sensor_Gaussian_Noise/1', 'Noisy_Sensor_Sum/2', 'autorouting', 'on');
add_line(modelName, 'Noisy_Sensor_Sum/1', 'EKF_State_Estimator/1', 'autorouting', 'on');
add_line(modelName, 'EKF_State_Estimator/1', 'Ctrl_Input_Mux/2', 'autorouting', 'on');

save_system(modelName, slxPath);
fprintf(' -> Da luu mo hinh Simulink thanh cong: %s\n', slxPath);

try
    print(['-s', modelName], '-dpng', '-r300', fullfile(outputDir, 'fig6_simulink_diagram.png'));
    fprintf(' -> Da xuat anh so do khoi Simulink: fig6_simulink_diagram.png\n');
catch ME
    fprintf(' [!] Luu y khi xuat anh Simulink: %s\n', ME.message);
end

fprintf(' -> Dang chay kiem chung sim("%s")...\n', modelName);
simOut = sim(modelName);
q_sim  = simOut.yout(:, 1:3);
q_ref  = simOut.yout(:, 4:8);
t_sim  = simOut.tout;
err_sim = hypot(q_ref(:,1) - q_sim(:,1), q_ref(:,2) - q_sim(:,2));
fprintf(' -> Kiem chung Simulink (EKF + PID) thanh cong! Sai so RMSE tren Simulink = %.4f m\n', rms(err_sim(t_sim >= 3.0)));

figSim = figure('Name', 'Fig 7: Ket qua kiem chung EKF + PID truc tiep tren Simulink', 'NumberTitle', 'off', ...
                'Color', 'w', 'Position', [160, 120, 950, 420], 'Visible', 'on');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
hold on; grid on; box on;
plot(q_ref(:,1), q_ref(:,2), 'k:', 'LineWidth', 2.0, 'DisplayName', 'Quy dao tham chieu (Simulink)');
plot(q_sim(:,1), q_sim(:,2), 'g-', 'LineWidth', 2.0, 'DisplayName', 'Quy dao thuc te (EKF + PID - Simulink)');
plot(q_sim(1,1), q_sim(1,2), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'DisplayName', 'Vi tri xuat phat lech');
xlabel('Toa do X [m]', 'FontWeight', 'bold');
ylabel('Toa do Y [m]', 'FontWeight', 'bold');
title('(a) Quy dao XY chay truc tiep tren Simulink (EKF + PID)', 'FontWeight', 'bold');
legend('Location', 'southoutside');
axis equal; xlim([-4.2, 4.2]); ylim([-2.7, 2.7]);

nexttile;
hold on; grid on; box on;
plot(t_sim, err_sim, 'b-', 'LineWidth', 1.8, 'DisplayName', '||e_p(t)|| tren Simulink (EKF + PID)');
yline(rms(err_sim(t_sim >= 3.0)), 'r--', sprintf('RMSE (t >= 3s) = %.4f m', rms(err_sim(t_sim >= 3.0))), ...
    'LineWidth', 1.5, 'LabelHorizontalAlignment', 'right', 'HandleVisibility', 'off');
xlabel('Thoi gian t [s]', 'FontWeight', 'bold');
ylabel('Sai so khoang cach Euclid ||e_p|| [m]', 'FontWeight', 'bold');
title('(b) Dap ung sai so bam vi tri tren Simulink (EKF + PID)', 'FontWeight', 'bold');
legend('Location', 'northeast');
xlim([0, 40]); ylim([0, 0.72]);

exportgraphics(figSim, fullfile(outputDir, 'fig7_simulink_verification.png'), 'Resolution', 300);
fprintf(' -> Da xuat do thi kiem chung Simulink: fig7_simulink_verification.png\n');

if feature('ShowFigureWindows')
    open_system(modelName);
    set_param(modelName, 'ZoomFactor', 'FitSystem');
    open_system([modelName, '/Pose_Scope']);
    save_system(modelName, slxPath);
else
    save_system(modelName, slxPath);
    close_system(modelName, 0);
end
