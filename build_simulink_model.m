%% ========================================================================
%  GENERATOR CHO MO HINH SIMULINK (.SLX): sl_robust_mobile_robot.slx
%  ------------------------------------------------------------------------
%  Kịch bản tự động xây dựng mô hình Simulink hoàn chỉnh cho Chủ đề 4:
%  "Điều khiển robot di động trong môi trường có nhiễu và bất định"
%  Tương thích trực tiếp với phong cách Simulink trong sách RVC3 (Chương 3).
% =========================================================================

clear; clc;
modelName = 'sl_robust_mobile_robot';
outputDir = fullfile(pwd, 'results');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Đóng và xóa model cũ nếu đang mở
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
slxPath = fullfile(pwd, [modelName, '.slx']);
if exist(slxPath, 'file')
    delete(slxPath);
end

fprintf(' -> Dang khoi tao mo hinh Simulink [%s.slx]...\n', modelName);
new_system(modelName);
open_system(modelName);

% Cau hinh Solver co dinh buoc (Fixed-step ode4 Runge-Kutta, dt = 0.02s)
% Gan luon StopFcn de moi khi ban bam nut RUN (mau xanh) tren Simulink, do thi ket qua tu dong bat len!
stopCallbackCode = [ ...
    'if exist(''yout'',''var''), ', ...
    'q_s = yout(:,1:3); q_r = yout(:,4:8); err_s = hypot(q_r(:,1)-q_s(:,1), q_r(:,2)-q_s(:,2)); ', ...
    'f_s = findobj(''Type'',''figure'',''Name'',''Ket qua Chay Simulink (Live Run)''); ', ...
    'if isempty(f_s), f_s = figure(''Name'',''Ket qua Chay Simulink (Live Run)'',''NumberTitle'',''off'',''Color'',''w'',''Position'',[180 100 940 420]); else, figure(f_s); clf(f_s); end; ', ...
    'subplot(1,2,1); plot(q_r(:,1),q_r(:,2),''k:'',''LineWidth'',2); hold on; grid on; ', ...
    'plot(q_s(:,1),q_s(:,2),''g-'',''LineWidth'',2); plot(q_s(1,1),q_s(1,2),''ro'',''MarkerFaceColor'',''r''); ', ...
    'axis equal; xlim([-4.2 4.2]); ylim([-2.7 2.7]); xlabel(''X [m]''); ylabel(''Y [m]''); title(''(a) Quy dao XY Robot chay tren Simulink''); legend(''Tham chieu'',''Thuc te (SMC)'',''Xuat phat'',''Location'',''southoutside''); ', ...
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

%% 1. KHỐI PHÁT QUỸ ĐẠO THAM CHIẾU (REFERENCE TRAJECTORY GENERATOR)
add_block('simulink/Sources/Clock', [modelName, '/Clock'], ...
    'Position', [40, 165, 70, 195]);

% Dung Fcn blocks de tao quy dao tham chieu x_ref, y_ref, th_ref, v_ref, w_ref
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/x_ref_fcn'], ...
    'Expr', '3.5*sin(0.19635*u(1))', ...
    'Position', [130, 80, 250, 110]);
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/y_ref_fcn'], ...
    'Expr', '2.2*sin(0.39270*u(1))', ...
    'Position', [130, 130, 250, 160]);
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/th_ref_fcn'], ...
    'Expr', 'atan2(0.86394*cos(0.39270*u(1)), 0.68722*cos(0.19635*u(1)))', ...
    'Position', [130, 180, 250, 210]);
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/v_ref_fcn'], ...
    'Expr', 'sqrt((0.68722*cos(0.19635*u(1)))^2 + (0.86394*cos(0.39270*u(1)))^2)', ...
    'Position', [130, 230, 250, 260]);
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/w_ref_fcn'], ...
    'Expr', '0.35*cos(0.19635*u(1))', ...
    'Position', [130, 280, 250, 310]);

add_block('simulink/Signal Routing/Mux', [modelName, '/Ref_Mux'], ...
    'Inputs', '5', 'Position', [290, 75, 298, 315]);

%% 2. KHỐI BỘ ĐIỀU KHIỂN BỀN VỮNG (ROBUST SLIDING MODE / BACKSTEPPING CONTROLLER)
% Nhận vector u = [x_r, y_r, th_r, v_r, w_r, x_fb, y_fb, th_fb] (8 chiều)
add_block('simulink/Signal Routing/Mux', [modelName, '/Ctrl_Input_Mux'], ...
    'Inputs', '2', 'Position', [360, 150, 368, 260]);

% Tinh v_cmd va w_cmd bang bieu thuc phi tuyen + thanh phan truot tanh()
v_ctrl_expr = ['u(4)*cos(atan2(sin(u(3)-u(8)),cos(u(3)-u(8)))) + ', ...
               '2.8*(cos(u(8))*(u(1)-u(6)) + sin(u(8))*(u(2)-u(7))) + ', ...
               '0.65*tanh((cos(u(8))*(u(1)-u(6)) + sin(u(8))*(u(2)-u(7)))/0.12)'];

w_ctrl_expr = ['u(5) + 7.5*u(4)*(-sin(u(8))*(u(1)-u(6)) + cos(u(8))*(u(2)-u(7))) + ', ...
               '3.8*sin(atan2(sin(u(3)-u(8)),cos(u(3)-u(8)))) + ', ...
               '0.85*tanh(atan2(sin(u(3)-u(8)),cos(u(3)-u(8)))/0.15)'];

add_block('simulink/User-Defined Functions/Fcn', [modelName, '/Robust_SMC_v'], ...
    'Expr', v_ctrl_expr, 'Position', [410, 155, 550, 195]);
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/Robust_SMC_w'], ...
    'Expr', w_ctrl_expr, 'Position', [410, 220, 550, 260]);

add_block('simulink/Discontinuities/Saturation', [modelName, '/Sat_v'], ...
    'UpperLimit', '1.8', 'LowerLimit', '-1.8', 'Position', [585, 160, 615, 190]);
add_block('simulink/Discontinuities/Saturation', [modelName, '/Sat_w'], ...
    'UpperLimit', '3.0', 'LowerLimit', '-3.0', 'Position', [585, 225, 615, 255]);

%% 3. KHỐI NHIỄU TRƯỢT BÁNH & SAI SỐ MÔ HÌNH (WHEEL SLIP & MODEL UNCERTAINTY)
add_block('simulink/Sources/Sine Wave', [modelName, '/Wheel_Slip_Disturbance'], ...
    'Amplitude', '0.12', 'Frequency', '1.5', 'Position', [580, 90, 610, 120]);

add_block('simulink/Math Operations/Gain', [modelName, '/Wheel_Radius_Mismatch'], ...
    'Gain', '1.04', 'Position', [650, 160, 690, 190]);
add_block('simulink/Math Operations/Gain', [modelName, '/Wheelbase_Mismatch'], ...
    'Gain', '0.96', 'Position', [650, 225, 690, 255]);

add_block('simulink/Math Operations/Sum', [modelName, '/Sum_Slip_v'], ...
    'Inputs', '+-', 'Position', [725, 165, 745, 185]);
add_block('simulink/Math Operations/Sum', [modelName, '/Sum_Slip_w'], ...
    'Inputs', '+-', 'Position', [725, 230, 745, 250]);

%% 4. KHỐI ĐỘNG HỌC ROBOT VI SAI CÓ TRƯỢT NGANG (PERTURBED UNICYCLE PLANT)
add_block('simulink/Signal Routing/Mux', [modelName, '/Plant_Mux'], ...
    'Inputs', '3', 'Position', [790, 155, 798, 295]);

% u(1) = v_real, u(2) = w_real, u(3) = theta
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/dx_dot'], ...
    'Expr', 'u(1)*cos(u(3)) - 0.08*u(1)*u(2)*sin(u(3))', ...
    'Position', [830, 150, 940, 180]);
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/dy_dot'], ...
    'Expr', 'u(1)*sin(u(3)) + 0.08*u(1)*u(2)*cos(u(3))', ...
    'Position', [830, 205, 940, 235]);
add_block('simulink/User-Defined Functions/Fcn', [modelName, '/dth_dot'], ...
    'Expr', 'u(2)', ...
    'Position', [830, 260, 940, 290]);

add_block('simulink/Continuous/Integrator', [modelName, '/Int_x'], ...
    'InitialCondition', '0.45', 'Position', [975, 150, 1005, 180]);
add_block('simulink/Continuous/Integrator', [modelName, '/Int_y'], ...
    'InitialCondition', '-0.50', 'Position', [975, 205, 1005, 235]);
add_block('simulink/Continuous/Integrator', [modelName, '/Int_th'], ...
    'InitialCondition', '0.50', 'Position', [975, 260, 1005, 290]);

add_block('simulink/Signal Routing/Mux', [modelName, '/State_Mux'], ...
    'Inputs', '3', 'Position', [1050, 145, 1058, 295]);

%% 5. KHỐI NHIỄU CẢM BIẾN & BỘ LỌC THÔNG THẤP / EKF XẤP XỈ (SENSOR NOISE & FILTER)
add_block('simulink/Sources/Band-Limited White Noise', [modelName, '/Sensor_Noise'], ...
    'Cov', '[0.0004 0.0004 0.0001]', 'Seed', '[11 22 33]', 'Ts', '0.02', ...
    'Position', [975, 345, 1005, 375]);

add_block('simulink/Math Operations/Sum', [modelName, '/Noisy_Sensor_Sum'], ...
    'Inputs', '++', 'Position', [1050, 340, 1075, 370]);

add_block('simulink/Discrete/Discrete Filter', [modelName, '/Kalman_LowPass_Filter'], ...
    'Numerator', '[0.25]', 'Denominator', '[1 -0.75]', 'SampleTime', '0.02', ...
    'Position', [650, 340, 760, 380]);

%% 6. KHỐI ĐẦU RA & QUAN SÁT (OUTPUTS & SCOPES)
add_block('simulink/Sinks/Out1', [modelName, '/q_true'], ...
    'Port', '1', 'Position', [1120, 205, 1150, 235]);
add_block('simulink/Sinks/Out1', [modelName, '/q_ref'], ...
    'Port', '2', 'Position', [360, 80, 390, 110]);
add_block('simulink/Sinks/Scope', [modelName, '/Pose_Scope'], ...
    'Position', [1120, 140, 1150, 175]);

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

add_line(modelName, 'Ctrl_Input_Mux/1', 'Robust_SMC_v/1', 'autorouting', 'on');
add_line(modelName, 'Ctrl_Input_Mux/1', 'Robust_SMC_w/1', 'autorouting', 'on');
add_line(modelName, 'Robust_SMC_v/1', 'Sat_v/1', 'autorouting', 'on');
add_line(modelName, 'Robust_SMC_w/1', 'Sat_w/1', 'autorouting', 'on');

add_line(modelName, 'Sat_v/1', 'Wheel_Radius_Mismatch/1', 'autorouting', 'on');
add_line(modelName, 'Sat_w/1', 'Wheelbase_Mismatch/1', 'autorouting', 'on');

add_line(modelName, 'Wheel_Radius_Mismatch/1', 'Sum_Slip_v/1', 'autorouting', 'on');
add_line(modelName, 'Wheel_Slip_Disturbance/1', 'Sum_Slip_v/2', 'autorouting', 'on');
add_line(modelName, 'Wheelbase_Mismatch/1', 'Sum_Slip_w/1', 'autorouting', 'on');
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
add_line(modelName, 'Sensor_Noise/1', 'Noisy_Sensor_Sum/2', 'autorouting', 'on');
add_line(modelName, 'Noisy_Sensor_Sum/1', 'Kalman_LowPass_Filter/1', 'autorouting', 'on');
add_line(modelName, 'Kalman_LowPass_Filter/1', 'Ctrl_Input_Mux/2', 'autorouting', 'on');

% Lưu file Simulink .slx và chạy thử nghiệm
save_system(modelName, slxPath);
fprintf(' -> Da luu mo hinh Simulink thanh cong: %s\n', slxPath);

% Xuất hình ảnh sơ đồ khối Simulink phục vụ báo cáo
try
    print(['-s', modelName], '-dpng', '-r300', fullfile(outputDir, 'fig6_simulink_diagram.png'));
    fprintf(' -> Da xuat anh so do khoi Simulink: fig6_simulink_diagram.png\n');
catch ME
    fprintf(' [!] Luu y khi xuat anh Simulink: %s\n', ME.message);
end

% Chạy mô phỏng Simulink kiểm chứng
fprintf(' -> Dang chay kiem chung sim("%s")...\n', modelName);
simOut = sim(modelName);
q_sim  = simOut.yout(:, 1:3);
q_ref  = simOut.yout(:, 4:8);
t_sim  = simOut.tout;
err_sim = hypot(q_ref(:,1) - q_sim(:,1), q_ref(:,2) - q_sim(:,2));
fprintf(' -> Kiem chung Simulink thanh cong! Sai so RMSE tren Simulink = %.4f m\n', rms(err_sim(t_sim >= 3.0)));

% Vẽ đồ thị kết quả xuất từ Simulink
figSim = figure('Name', 'Fig 7: Ket qua kiem chung truc tiep tren Simulink', 'NumberTitle', 'off', ...
                'Color', 'w', 'Position', [160, 120, 950, 420], 'Visible', 'on');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
hold on; grid on; box on;
plot(q_ref(:,1), q_ref(:,2), 'k:', 'LineWidth', 2.0, 'DisplayName', 'Quy dao tham chieu (Simulink)');
plot(q_sim(:,1), q_sim(:,2), 'g-', 'LineWidth', 2.0, 'DisplayName', 'Quy dao thuc te (Robust SMC - Simulink)');
plot(q_sim(1,1), q_sim(1,2), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'DisplayName', 'Vi tri xuat phat lech');
xlabel('Toa do X [m]', 'FontWeight', 'bold');
ylabel('Toa do Y [m]', 'FontWeight', 'bold');
title('(a) Quy dao XY chay truc tiep tren Simulink', 'FontWeight', 'bold');
legend('Location', 'southoutside');
axis equal; xlim([-4.2, 4.2]); ylim([-2.7, 2.7]);

nexttile;
hold on; grid on; box on;
plot(t_sim, err_sim, 'b-', 'LineWidth', 1.8, 'DisplayName', '||e_p(t)|| tren Simulink');
yline(rms(err_sim(t_sim >= 3.0)), 'r--', sprintf('RMSE (t >= 3s) = %.4f m', rms(err_sim(t_sim >= 3.0))), ...
    'LineWidth', 1.5, 'LabelHorizontalAlignment', 'right', 'HandleVisibility', 'off');
xlabel('Thoi gian t [s]', 'FontWeight', 'bold');
ylabel('Sai so khoang cach Euclid ||e_p|| [m]', 'FontWeight', 'bold');
title('(b) Dap ung sai so bam vi tri tren Simulink', 'FontWeight', 'bold');
legend('Location', 'northeast');

exportgraphics(figSim, fullfile(outputDir, 'fig7_simulink_verification.png'), 'Resolution', 300);
fprintf(' -> Da xuat do thi kiem chung Simulink: fig7_simulink_verification.png\n');

save_system(modelName, slxPath);
open_system(modelName);
set_param(modelName, 'ZoomFactor', 'FitSystem');
open_system([modelName, '/Pose_Scope']);
save_system(modelName, slxPath);
fprintf(' -> Mo hinh Simulink [%s.slx] dang duoc mo tren man hinh de ban tuong tac!\n', modelName);
