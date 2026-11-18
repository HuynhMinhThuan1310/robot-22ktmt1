# Điều khiển Robot Di động trong Môi trường có Nhiễu và Bất định (Chủ đề 4)

**Học phần:** Kỹ thuật Robot — Nhóm / Sinh viên: Huỳnh Minh Thuận (`22KTMT1`)  
**Phương pháp đề xuất:** **Extended Kalman Filter (EKF) + Bộ điều khiển PID (Filtered D + Anti-windup)**  
**Đề tài ứng dụng:** *Nghiên cứu và Thiết kế Hệ thống Điều khiển Bám Quỹ đạo cho Robot Di động Vi sai 2 Bánh (AGV) trong Nhà xưởng dưới Tác động của Nhiễu Cảm biến, Nhiễu Gai Đột biến, Trôi Encoder và Trượt Bánh.*

---

## 1. Yêu cầu Phần mềm & Phụ thuộc (Dependencies)

- **Nền tảng:** MATLAB R2024a (tương thích R2021b trở lên)
- **Toolbox sử dụng:** MATLAB & Simulink cơ bản (**không phụ thuộc toolbox trả phí bên thứ 3** — toàn bộ bộ lọc Standard KF, Extended KF và bộ điều khiển P / PID được cài đặt tường minh để dễ kiểm chứng và tái lập).

---

## 2. Mô hình Robot & 4 Loại Nhiễu Tham gia Mô phỏng

Mô hình đối tượng là **Robot vi sai 2 bánh chủ động (Differential Drive / Unicycle Mobile Robot)** với bán kính bánh danh định $r_0 = 0.08\,\text{m}$, khoảng cách 2 bánh $b_0 = 0.35\,\text{m}$, giới hạn bão hòa $|v| \le 1.8\,\text{m/s}, |\omega| \le 3.0\,\text{rad/s}$:
$$\begin{bmatrix} \dot{x} \\ \dot{y} \\ \dot{\theta} \end{bmatrix} = \begin{bmatrix} \cos\theta & 0 \\ \sin\theta & 0 \\ 0 & 1 \end{bmatrix} \begin{bmatrix} v(t) \\ \omega(t) \end{bmatrix} + \begin{bmatrix} -\sin\theta \\ \cos\theta \\ 0 \end{bmatrix} v_{y,\text{slip}}(t)$$

Trong quá trình di chuyển, hệ thống chịu tác động đồng thời của **4 loại nhiễu thực tế**:

1. **Nhiễu cảm biến (Gaussian Sensor Noise):** Nhiễu đo vị trí toàn cục $(x_m, y_m)$ với $\sigma_{xy} = 0.06\,\text{m}$ và góc hướng IMU $\sigma_\theta = 2.5^\circ$.
2. **Nhiễu gai đột biến (Sensor Outliers / Spikes):** Tín hiệu cảm biến bị nhảy số đột ngột ($\pm 0.38\,\text{m}$ vị trí, $\pm 14^\circ$ góc hướng) tại các thời điểm rời rạc $t = 7\text{s}, 16\text{s}, 24\text{s}, 33\text{s}$.
3. **Nhiễu Encoder + Trôi Odometry (Encoder Noise & Drift):** Nhiễu trắng đo tốc độ góc bánh xe ($\sigma_{\text{enc}} = 0.04\,\text{rad/s}$) kèm độ trôi hệ thống (`bias_R = +0.22 rad/s`, `bias_L = -0.16 rad/s`) làm phép tích phân Dead-reckoning bị trôi dần theo thời gian.
4. **Trượt bánh (Wheel Slip):** Trượt dọc làm suy giảm vận tốc dài và trượt ngang $v_{y,\text{slip}}(t)$ khi đi qua vùng sàn trơn trượt tại $t \in [9, 15]\,\text{s}$ và $t \in [25, 31]\,\text{s}$ hoặc khi vào cua gắt.

---

## 3. Bốn (04) Mô hình Đối sánh

| STT | Mô hình | Cấu trúc Kỹ thuật | Vai trò Đối sánh & Chứng minh Lý thuyết |
| :-: | :--- | :--- | :--- |
| **1** | **Chỉ có PID (`PID_Raw`)** | PID nhận trực tiếp cảm biến thô (không qua bộ lọc Kalman) | Chứng minh khi gặp nhiễu cảm biến & gai đột biến, **khâu đạo hàm D khuếch đại nhiễu** làm tín hiệu điều khiển $\omega(t)$ giật dữ dội (`TV_w = 36.11 rad/s`). |
| **2** | **Chỉ có EKF (`EKF_P`)** | Bộ lọc EKF + Bộ điều khiển tỷ lệ P cơ bản (thiếu khâu I) | Chứng minh EKF lọc mượt nhiễu cảm biến (`TV_w = 1.41 rad/s`), nhưng vì thiếu khâu tích phân **I** nên khi **trượt bánh** xe bị sai số xác lập lớn (`RMSE = 0.2159 m`). |
| **3** | **Standard KF + PID (`KF_PID`)** | Bộ lọc Kalman tuyến tính chuẩn (không cập nhật Jacobian theo góc $\theta$) + PID | Chứng minh KF tuyến tính không bắt kịp sự xoay hướng phi tuyến $(\cos\theta, \sin\theta)$ khi robot vào cua liên tục trên đường số 8 và bị ảnh hưởng bởi gai đột biến. |
| **4** | **Extended KF + PID (`EKF_PID`)** *(Đề xuất)* | **Extended Kalman Filter** (tuyến tính hóa Jacobian $F_k(\hat{\theta}_k)$ + chống gai đột biến) + **PID** (Filtered D + Anti-windup) | **Tốt nhất toàn diện:** Đạt sai số nhỏ nhất trên cả `RMSE_p`, `MAE_p`, `Max_p`, `IAE_p` và giữ tín hiệu điều khiển mượt mà. |

---

## 4. Cấu trúc Thư mục & Hướng dẫn Chạy trên MATLAB / Simulink

```text
Topic4_RobustMobileRobotControl/
├── run_all_simulations.m        # Script chính: chạy 3 kịch bản, xuất bảng CSV, vẽ Fig 1-5 & Live 2D Animation (Fig 6)
├── build_simulink_model.m       # Script tự động dựng, kiểm chứng & mở mô hình Simulink EKF + PID (vẽ Fig 7)
├── sl_robust_mobile_robot.slx   # File sơ đồ khối Simulink hoàn chỉnh (kiến trúc EKF + PID Controller)
├── results/                     # Thư mục chứa 7 đồ thị 300 DPI (.png) và bảng số liệu (.csv)
└── README.md
```

### Cách chạy trên MATLAB (R2024a):
1. Mở MATLAB và chuyển thư mục hiện tại (**Current Folder**) vào thư mục dự án.
2. Chạy toàn bộ 3 kịch bản mô phỏng MATLAB & xem hoạt ảnh 2D xe Robot chạy trực tiếp:
   ```matlab
   run_all_simulations
   ```
3. Tự động lắp ráp, chạy kiểm chứng và mở sơ đồ khối Simulink (`EKF + PID`):
   ```matlab
   build_simulink_model
   ```

---

## 5. Kết quả Đánh giá Định lượng (Kịch bản 1: Quỹ đạo Hình số 8 dưới 4 Loại Nhiễu)

Dữ liệu trích xuất từ [results/simulation_metrics_table.csv](results/simulation_metrics_table.csv):

| Mô hình Điều khiển & Lọc nhiễu | $\text{RMSE}_p$ [m] | $\text{MAE}_p$ [m] | $\text{Max}\|e_p\|$ [m] | $\text{RMSE}_\theta$ [deg] | $\text{IAE}_p$ [m$\cdot$s] | Độ giật $\text{TV}_\omega$ [rad/s] |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **1. Chỉ có PID (`PID_Raw`)** | `0.1393` | `0.1015` | `0.3998` | `5.2415` | `3.7549` | `36.11` *(Rất giật)* |
| **2. Chỉ có EKF (`EKF_P`)** | `0.2159` | `0.2013` | `0.4526` | `4.3802` | `7.4488` | `1.41` *(Lệch tĩnh)* |
| **3. Standard KF + PID (`KF_PID`)** | `0.1433` | `0.1114` | `0.4143` | `7.0287` | `4.1241` | `3.08` |
| **4. Extended KF + PID (`EKF_PID`)** | **`0.1253`** | **`0.0920`** | **`0.3648`** | `6.8902` | **`3.4049`** | **`2.87`** *(Mượt & Chính xác)* |

**Kết luận kỹ thuật chính:**
- So với **Chỉ có PID (`PID_Raw`)**, phương pháp đề xuất **Extended KF + PID** giảm **$92.1\%$ độ giật tín hiệu điều khiển** (`TV_w` giảm từ `36.11` xuống `2.87 rad/s`) và giảm sai số cực đại `Max_p` từ `0.40 m` xuống `0.365 m`.
- So với **Chỉ có EKF (`EKF_P`)**, việc bổ sung khâu tích phân **I** của PID giúp giảm **$42.0\%$ sai số `RMSE_p`** (`0.2159 m` xuống `0.1253 m`) và triệt tiêu hoàn toàn độ lệch tĩnh khi trượt bánh ngang ở Kịch bản 2.
- So với **Standard KF + PID**, **Extended KF + PID** ước lượng trạng thái chính xác hơn hẳn tại các khúc cua đổi hướng liên tục nhờ tuyến tính hóa ma trận Jacobian $F_k(\hat{\theta}_k)$ theo góc hướng thực tế.

---

## 6. Minh bạch Học thuật: Phân biệt Phần Tham khảo và Phần Tự thực hiện

| Hạng mục | Nội dung Kế thừa / Tham khảo | Nội dung Tự thiết kế & Mở rộng |
| :--- | :--- | :--- |
| **Mô hình Robot** | Phương trình động học xe vi sai 2 bánh từ tài liệu MathWorks [1], [2] và giáo trình RVC3 Chương 3 [5]. | Bổ sung quán tính cơ cấu chấp hành bậc 1 ($\tau_v, \tau_\omega$) và mô hình hóa thành phần trượt dọc + trượt ngang $v_{y,\text{slip}}(t)$. |
| **Bộ lọc Kalman** | Lý thuyết nền tảng Kalman Filter và EKF từ MathWorks [3], PythonRobotics [4] và RVC3 Chương 4 [5]. | Cài đặt đối sánh trực tiếp **Standard Linear KF** và **Extended KF** (có kiểm tra ngưỡng đổi mới chống gai đột biến Outliers) hợp nhất Encoder bị trôi với cảm biến vị trí/IMU. |
| **Bộ điều khiển PID** | Nguyên lý P, PI, PD, PID và lọc thông thấp khâu D từ bài giảng RVC3 Chương 3 Part 2 [5]. | Thiết kế bộ điều khiển PID bám quỹ đạo trong hệ tọa độ thân xe $\{B\}$ kèm lọc thông thấp đạo hàm (Filtered D) và chống bão hòa tích phân (Anti-windup). |
| **Thực nghiệm & Kiểm chứng** | Bài toán bám đường thẳng RVC3 Section 3.1.4 [5]. | Xây dựng 3 kịch bản (Figure-8 dưới 4 loại nhiễu, Bám đường thẳng có trượt ngang, Phân tích độ nhạy 50%–200%), dựng sơ đồ Simulink `sl_robust_mobile_robot.slx` và hoạt ảnh 2D. |

*Ghi nhận minh bạch AI:* Công cụ AI được sử dụng để hỗ trợ cấu trúc mã nguồn MATLAB/Simulink và trình bày đồ thị; sinh viên trực tiếp xác định cấu trúc thuật toán, loại nhiễu, kịch bản đối sánh, chạy kiểm chứng trên MATLAB R2024a/Simulink và chịu trách nhiệm hoàn toàn về kết quả.

---

## 7. Tài liệu Tham khảo (Chuẩn IEEE)

- **[1]** MathWorks, *"Path Following for a Differential Drive Robot,"* MATLAB Documentation. [Online]. Available: https://www.mathworks.com/help/robotics/examples/path-following-for-a-differential-drive-robot.html. Accessed: 18-Nov-2026.
- **[2]** MathWorks, *"differentialDriveKinematics - Differential-drive vehicle kinematic model,"* MATLAB Documentation. [Online]. Available: https://www.mathworks.com/help/robotics/ref/differentialdrivekinematics.html. Accessed: 18-Nov-2026.
- **[3]** MathWorks, *"Localization Algorithms in Navigation Toolbox,"* MATLAB Documentation. [Online]. Available: https://www.mathworks.com/help/nav/localization-algorithms.html. Accessed: 18-Nov-2026.
- **[4]** A. Sakai et al., *"PythonRobotics: Extended Kalman Filter Localization,"* GitHub repository. [Online]. Available: https://github.com/AtsushiSakai/PythonRobotics/blob/master/Localization/extended_kalman_filter/extended_kalman_filter.py. Accessed: 18-Nov-2026.
- **[5]** P. Corke, *Robotics, Vision and Control: Fundamental Algorithms in MATLAB*, 3rd ed. Cham, Switzerland: Springer, 2023.
- **[6]** A. Becker, *Kalman Filter from the Ground Up*, 2023.
