# Điều khiển Robot Di động trong Môi trường có Nhiễu và Bất định (Chủ đề 4)

**Học phần:** Kỹ thuật Robot — Nhóm / Sinh viên: Huỳnh Minh Thuận (`22KTMT1`)  
**Đề tài ứng dụng:** *Nghiên cứu và Thiết kế Hệ thống Điều khiển Bám Quỹ đạo Bền vững cho Robot Tự hành Vận chuyển Hàng hóa (AGV) trong Nhà xưởng Công nghiệp dưới Tác động của Sàn Trơn trượt, Thay đổi Tải trọng và Nhiễu Cảm biến.*

---

## 1. Yêu cầu Phần mềm & Phụ thuộc (Dependencies)

- **Nền tảng:** MATLAB R2024a (tương thích R2021b trở lên)
- **Toolbox sử dụng:** MATLAB & Simulink cơ bản (**không phụ thuộc toolbox trả phí bên thứ 3** — toàn bộ bộ lọc EKF, bộ điều khiển PID/Backstepping/SMC và mô hình động học/động lực học được cài đặt tường minh để dễ kiểm chứng và tái lập).

---

## 2. Phát biểu Bài toán & Mô hình Toán học 4 Yếu tố Bất định

Mô hình đối tượng là **Robot vi sai 2 bánh chủ động (Differential Drive / Unicycle Mobile Robot)** với bán kính bánh danh định $r_0 = 0.08\,\text{m}$, khoảng cách 2 bánh $b_0 = 0.35\,\text{m}$, giới hạn bão hòa $|v| \le 1.8\,\text{m/s}, |\omega| \le 3.0\,\text{rad/s}$.

Trong điều kiện thực tế, hệ thống chịu tác động đồng thời của **4 yếu tố nhiễu và bất định**:

1. **Sai số mô hình hình học (Model Mismatch):**
   - Bán kính bánh phải và bánh trái thực tế lệch so với danh định: $r_R = 1.06\,r_0$, $r_L = 0.96\,r_0$, chiều rộng cơ sở thực tế $b = 1.05\,b_0$.
2. **Nhiễu cảm biến & Trôi Odometry (Sensor Noise & Drift):**
   - Nhiễu đo lường vị trí toàn cục $(x_m, y_m)$ (UWB/Camera) $\sigma_{xy} = 0.06\,\text{m}$, nhiễu góc hướng IMU $\sigma_\theta = 2.5^\circ$, và nhiễu vận tốc góc Encoder bánh xe $\sigma_{\text{enc}} = 0.03\,\text{rad/s}$.
3. **Trượt bánh dọc & trượt ngang (Longitudinal & Lateral Wheel Slip):**
   - Phá vỡ ràng buộc phi holonomic lý tưởng ($\dot{y}\cos\theta - \dot{x}\sin\theta = v_{y,\text{slip}} \neq 0$) khi đi qua vùng sàn trơn trượt tại $t \in [9, 15]\,\text{s}$ và $t \in [25, 31]\,\text{s}$:
     $$\begin{bmatrix} \dot{x} \\ \dot{y} \\ \dot{\theta} \end{bmatrix} = \begin{bmatrix} \cos\theta & 0 \\ \sin\theta & 0 \\ 0 & 1 \end{bmatrix} \begin{bmatrix} v(t) \\ \omega(t) \end{bmatrix} + \begin{bmatrix} -\sin\theta \\ \cos\theta \\ 0 \end{bmatrix} v_{y,\text{slip}}(t)$$
4. **Thay đổi thông số hệ thống đột ngột (Parameter Variations):**
   - Tại $t = 20\,\text{s}$, AGV nhận thêm tải trọng làm tăng hằng số thời gian quán tính $(\tau_v, \tau_\omega)$ thêm $65\% - 75\%$ và giảm $12\%$ hiệu suất cơ cấu chấp hành.

---

## 3. Các Phương pháp Điều khiển Được Đối sánh

| STT | Phương pháp | Nguyên lý & Đặc điểm |
| :-: | :--- | :--- |
| **1** | **Kinematic P (Raw Sensor)** | Bộ điều khiển tỷ lệ cơ bản (Baseline theo RVC3 Chương 3), phản hồi trực tiếp từ cảm biến chưa lọc nhiễu. |
| **2** | **PID + EKF** | Kết hợp **Bộ lọc Kalman Mở rộng (EKF)** khử nhiễu đo lường với bộ điều khiển PID có khâu lọc thông thấp cho thành phần đạo hàm (Filtered D) và chống bão hòa tích phân (Anti-windup). |
| **3** | **Lyapunov Backstepping + EKF** | Bộ điều khiển phi tuyến Kanayama trong hệ tọa độ gắn trên thân robot $\{B\}$ đảm bảo ổn định tiệm cận theo hàm Lyapunov. |
| **4** | **Robust Adaptive SMC + EKF** *(Đề xuất)* | Bộ điều khiển **Trượt Thích nghi Bền vững** dùng mặt trượt tích phân, hàm lớp biên trơn $\tanh(s/\phi)$ chống rung (*chattering-free*) và bộ ước lượng bù nhiễu trượt bánh thích nghi $\hat{d}_v, \hat{d}_\omega$. |

---

## 4. Cấu trúc Thư mục & Hướng dẫn Chạy Mô phỏng

```text
Topic4_RobustMobileRobotControl/
├── run_all_simulations.m        # Script chính: chạy 3 kịch bản, in bảng số liệu, vẽ Fig 1-5 & Live 2D Animation (Fig 6)
├── build_simulink_model.m       # Script tự động dựng, kiểm chứng & mở mô hình Simulink (vẽ Fig 7)
├── sl_robust_mobile_robot.slx   # File sơ đồ khối Simulink hoàn chỉnh (có thể mở & bấm Run trực tiếp)
├── results/                     # Thư mục chứa 7 đồ thị 300 DPI (.png) và bảng số liệu (.csv)
└── README.md
```

### Cách chạy trên MATLAB (R2024a):
1. Mở MATLAB và trỏ thư mục hiện tại (**Current Folder**) vào thư mục dự án.
2. Chạy toàn bộ mô phỏng MATLAB & xem hoạt ảnh 2D xe Robot di chuyển:
   ```matlab
   run_all_simulations
   ```
3. Tự động lắp ráp, chạy kiểm chứng và mở sơ đồ khối Simulink:
   ```matlab
   build_simulink_model
   ```
   *(Hoặc nhấp đúp trực tiếp vào `sl_robust_mobile_robot.slx` và bấm nút **Run** màu xanh; đồ thị quỹ đạo, sai số và `Pose_Scope` sẽ tự động mở lên sau khi chạy xong).*

---

## 5. Kết quả Đánh giá Định lượng (Kịch bản 1: Quỹ đạo Hình số 8 dưới Nhiễu & Trượt bánh)

Dữ liệu trích xuất từ [results/simulation_metrics_table.csv](results/simulation_metrics_table.csv) (tính sau giai đoạn quá độ khởi động $t \ge 3.0\,\text{s}$):

| Phương pháp Điều khiển | $\text{RMSE}_p$ [m] | $\text{MAE}_p$ [m] | $\text{Max}\|e_p\|$ [m] | $\text{RMSE}_\theta$ [deg] | $\text{IAE}_p$ [m$\cdot$s] |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **1. Kinematic P (Raw Sensor)** | `0.2065` | `0.1919` | `0.3891` | `4.1343` | `7.0970` |
| **2. PID + EKF** | `0.1167` | `0.0999` | `0.2761` | `4.8335` | `3.6975` |
| **3. Backstepping + EKF** | `0.1102` | `0.0990` | `0.2498` | `4.5039` | `3.6622` |
| **4. Robust Adaptive SMC + EKF** | **`0.0831`** | **`0.0690`** | `0.2912` | `5.5341` | **`2.5502`** |

**Nhận xét chính:**
- Bộ lọc **EKF** giúp giảm sai số đo lường vị trí từ `0.086 m` (cảm biến thô) xuống `0.050 m` và loại bỏ dao động cao tần trên tín hiệu điều khiển $\omega(t)$.
- Bộ điều khiển **Robust Adaptive SMC + EKF** giảm **$59.8\%$** sai số `RMSE` so với bộ điều khiển P cơ bản và giảm **$28.8\%$** so với `PID + EKF`.
- Trong kịch bản bám đường thẳng theo RVC3 Section 3.1.4 có trượt ngang $v_{y,\text{slip}} = -0.12\,\text{m/s}$, bộ điều khiển P bị lệch tĩnh vĩnh viễn ($\sim 0.27\,\text{m}$), trong khi PID và SMC triệt tiêu sai số xác lập về $0$.

---

## 6. Minh bạch Học thuật: Phân biệt Phần Tham khảo và Phần Tự thực hiện

| Hạng mục | Nội dung Kế thừa / Tham khảo | Nội dung Tự thiết kế & Mở rộng |
| :--- | :--- | :--- |
| **Mô hình Robot** | Phương trình động học xe vi sai lý tưởng từ tài liệu MathWorks [1], [2] và giáo trình RVC3 [5]. | Mở rộng sang mô hình động lực học có hằng số thời gian cơ cấu chấp hành $\tau_v, \tau_\omega$, lệch bán kính $(r_R, r_L, b)$, trượt ngang $v_{y,\text{slip}}$ và đổi tải trọng đột ngột. |
| **Ước lượng Trạng thái** | Nguyên lý thuật toán Extended Kalman Filter (EKF) từ MathWorks [3], PythonRobotics [4] và RVC3 Chương 4 [5]. | Tự cài đặt hàm EKF rời rạc trên MATLAB hợp nhất Odometry bị trôi (do sai số bánh xe) với cảm biến vị trí/IMU nhiễu Gaussian. |
| **Thuật toán Điều khiển** | Bộ điều khiển P (RVC3 Ch.3 [5]) và Backstepping của Kanayama [6]. | Thiết kế bộ điều khiển **PID + Filtered D + Anti-windup** và **Robust Adaptive SMC + Disturbance Observer** chống rung bằng hàm $\tanh(s/\phi)$. |
| **Kịch bản & Kiểm chứng** | Ý tưởng bài toán bám đường thẳng RVC3 Section 3.1.4 [5]. | Xây dựng 3 kịch bản thử nghiệm (Figure-8, Line Following có trượt ngang, Sensitivity Analysis 50%–200%), tự dựng mô hình Simulink `.slx` và hoạt ảnh 2D. |

*Ghi nhận minh bạch AI:* Công cụ AI được sử dụng để hỗ trợ cấu trúc mã nguồn MATLAB/Simulink và tối ưu hóa trực quan hóa đồ thị; sinh viên trực tiếp nghiên cứu mô hình toán học, hiệu chỉnh thông số, chạy kiểm chứng thực nghiệm trên MATLAB R2024a/Simulink và chịu hoàn toàn trách nhiệm về kết quả.

---

## 7. Tài liệu Tham khảo (Chuẩn IEEE)

- **[1]** MathWorks, *"Path Following for a Differential Drive Robot,"* MATLAB Documentation. [Online]. Available: https://www.mathworks.com/help/robotics/examples/path-following-for-a-differential-drive-robot.html. Accessed: 17-Nov-2026.
- **[2]** MathWorks, *"differentialDriveKinematics - Differential-drive vehicle kinematic model,"* MATLAB Documentation. [Online]. Available: https://www.mathworks.com/help/robotics/ref/differentialdrivekinematics.html. Accessed: 17-Nov-2026.
- **[3]** MathWorks, *"Localization Algorithms in Navigation Toolbox,"* MATLAB Documentation. [Online]. Available: https://www.mathworks.com/help/nav/localization-algorithms.html. Accessed: 17-Nov-2026.
- **[4]** A. Sakai et al., *"PythonRobotics: Extended Kalman Filter Localization,"* GitHub repository. [Online]. Available: https://github.com/AtsushiSakai/PythonRobotics/blob/master/Localization/extended_kalman_filter/extended_kalman_filter.py. Accessed: 17-Nov-2026.
- **[5]** P. Corke, *Robotics, Vision and Control: Fundamental Algorithms in MATLAB*, 3rd ed. Cham, Switzerland: Springer, 2023.
- **[6]** Y. Kanayama, Y. Kimura, F. Miyazaki, and T. Noguchi, *"A stable tracking control method for an autonomous mobile robot,"* in *Proc. IEEE Int. Conf. Robot. Autom. (ICRA)*, Cincinnati, OH, USA, 1990, pp. 384–389.
