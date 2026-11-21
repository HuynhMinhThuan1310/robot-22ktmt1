# -*- coding: utf-8 -*-
"""
Script ve 3 so do khoi & luu do thuat toan chat luong cao (300 DPI)
phuc vu Bao cao Cuoi ky Hoc phan Ky thuat Robot (Chu de 4: EKF + PID)
"""
import os
import matplotlib.pyplot as plt
import matplotlib.patches as patches

plt.rcParams['font.family'] = 'DejaVu Sans'
plt.rcParams['axes.unicode_minus'] = False

OUT_DIR = r'c:\robot\Topic4_RobustMobileRobotControl\results'
os.makedirs(OUT_DIR, exist_ok=True)


def draw_box(ax, x, y, w, h, text, facecolor='#E8F1FA', edgecolor='#1F4E79',
             fontsize=9.5, fontweight='normal', style='round,pad=0.02', text_color='#111111'):
    box = patches.FancyBboxPatch(
        (x, y), w, h, boxstyle=style,
        facecolor=facecolor, edgecolor=edgecolor, linewidth=1.6, zorder=3
    )
    ax.add_patch(box)
    ax.text(x + w / 2, y + h / 2, text, ha='center', va='center',
            fontsize=fontsize, fontweight=fontweight, color=text_color, zorder=4)


def draw_diamond(ax, cx, cy, w, h, text, facecolor='#FFF2CC', edgecolor='#BF9000', fontsize=9.0):
    pts = [(cx, cy + h/2), (cx + w/2, cy), (cx, cy - h/2), (cx - w/2, cy)]
    poly = patches.Polygon(pts, closed=True, facecolor=facecolor, edgecolor=edgecolor, linewidth=1.6, zorder=3)
    ax.add_patch(poly)
    ax.text(cx, cy, text, ha='center', va='center', fontsize=fontsize, fontweight='bold', color='#111111', zorder=4)


def draw_arrow(ax, x1, y1, x2, y2, label='', lx=None, ly=None, color='#222222', lw=1.5, rad=0.0):
    ax.annotate(
        '', xy=(x2, y2), xytext=(x1, y1),
        arrowprops=dict(arrowstyle='-|>,head_length=0.6,head_width=0.35',
                        color=color, lw=lw, connectionstyle=f'arc3,rad={rad}'),
        zorder=5
    )
    if label:
        tx = lx if lx is not None else (x1 + x2) / 2
        ty = ly if ly is not None else (y1 + y2) / 2 + 0.02
        ax.text(tx, ty, label, ha='center', va='center', fontsize=8.5,
                color=color, fontweight='bold',
                bbox=dict(boxstyle='round,pad=0.15', facecolor='white', edgecolor='none', alpha=0.85), zorder=6)


# =========================================================================
# HINH A: SO DO KIEN TRUC TONG THE HE THONG DIEU KHIEN EKF + PID
# =========================================================================
def make_system_architecture():
    fig, ax = plt.subplots(figsize=(12, 6.2), dpi=300)
    ax.set_xlim(0, 12)
    ax.set_ylim(0, 6.2)
    ax.axis('off')

    ax.text(6.0, 5.9, 'SƠ ĐỒ KIẾN TRÚC TỔNG THỂ HỆ THỐNG ĐIỀU KHIỂN ROBOT DI ĐỘNG (EKF + PID)',
            ha='center', va='center', fontsize=12.5, fontweight='bold', color='#1B365D')

    # Hàng trên (Forward Path)
    draw_box(ax, 0.3, 3.6, 1.9, 1.15,
             'Quỹ đạo tham chiếu\n(Reference Generator)\n$x_r, y_r, \\theta_r, v_r, \\omega_r$',
             facecolor='#E2EFDA', edgecolor='#385723', fontweight='bold')

    draw_box(ax, 2.75, 3.6, 1.95, 1.15,
             'Chuyển đổi Hệ tọa độ\nThân xe {B}\n$e_x, e_y, e_\\theta$',
             facecolor='#DDEBF7', edgecolor='#1F4E79', fontweight='bold')

    draw_box(ax, 5.20, 3.6, 2.45, 1.15,
             'Bộ điều khiển PID\n(Feedforward + P + I\n+ Filtered D + Anti-windup)',
             facecolor='#D9E1F2', edgecolor='#203764', fontsize=8.8, fontweight='bold')

    draw_box(ax, 8.35, 3.6, 2.75, 1.15,
             'Mô hình Robot Vi sai 2 Bánh\n(Differential Drive / Unicycle)\n+ Quán tính động cơ ($\\tau_v, \\tau_\\omega$)',
             facecolor='#FCE4D6', edgecolor='#C55A11', fontweight='bold')

    # Nhiễu trượt bánh (phía trên Robot)
    draw_box(ax, 8.55, 5.05, 2.35, 0.55,
             'Nhiễu (4): Trượt bánh dọc & ngang\n$d_v(t), d_\\omega(t), v_{y,slip}(t)$',
             facecolor='#F8CBAD', edgecolor='#C00000', fontsize=8.5, fontweight='bold', text_color='#800000')
    draw_arrow(ax, 9.72, 5.05, 9.72, 4.77, color='#C00000', lw=1.6)

    # Mũi tên hàng trên
    draw_arrow(ax, 2.22, 4.18, 2.73, 4.18)
    draw_arrow(ax, 4.72, 4.18, 5.23, 4.18, '$e_B$', lx=4.98, ly=4.42)
    draw_arrow(ax, 7.62, 4.18, 8.33, 4.18, '$v_{cmd}, \\omega_{cmd}$', lx=7.98, ly=4.45)

    # Đầu ra trạng thái thật
    ax.plot([11.12, 11.65], [4.18, 4.18], color='#222222', lw=1.6)
    ax.text(11.45, 4.48, '$q_{true}$\n$[x,y,\\theta]^T$', ha='center', va='center', fontsize=8.8, fontweight='bold')

    # Hàng dưới (Feedback Path: Cảm biến + Encoder + EKF)
    draw_box(ax, 8.35, 1.55, 2.75, 1.05,
             'Cảm biến Vị trí & Góc (UWB/IMU)\n+ Nhiễu (1) Gaussian\n+ Nhiễu (2) Gai đột biến (Outliers)',
             facecolor='#FFF2CC', edgecolor='#BF9000', fontsize=8.8, fontweight='bold')

    draw_box(ax, 5.25, 0.35, 2.45, 0.90,
             'Encoder 2 Bánh xe (Odometry)\n+ Nhiễu (3) Encoder & Trôi (Drift)',
             facecolor='#FFF2CC', edgecolor='#BF9000', fontsize=8.8, fontweight='bold')

    draw_box(ax, 3.05, 1.50, 3.55, 1.15,
             'Bộ lọc Kalman Mở rộng (EKF)\n• Dự đoán phi tuyến + Jacobian $F_k(\\hat{\\theta}_k)$\n• Chống gai đột biến 3$\\sigma$ (Innovation Gating)',
             facecolor='#E2EFDA', edgecolor='#2E75B6', fontsize=9.0, fontweight='bold')

    # Kết nối vòng hồi tiếp
    # q_true đi xuống cảm biến
    ax.plot([11.45, 11.45], [4.18, 2.08], color='#222222', lw=1.5)
    draw_arrow(ax, 11.45, 2.08, 11.12, 2.08)

    # Từ cảm biến vào EKF
    draw_arrow(ax, 8.33, 2.08, 6.62, 2.08, '$z_k$ (nhiễu)', lx=7.48, ly=2.30, color='#B45F06')

    # Từ lệnh u_cmd đi xuống Encoder Odometry rồi vào EKF
    ax.plot([7.98, 7.98], [4.18, 0.80], color='#555555', lw=1.3, ls='--')
    draw_arrow(ax, 7.98, 0.80, 7.72, 0.80, color='#555555', lw=1.3)
    ax.plot([5.23, 4.82], [0.80, 0.80], color='#555555', lw=1.3)
    draw_arrow(ax, 4.82, 0.80, 4.82, 1.48, '$v_{odom}, \\omega_{odom}$', lx=4.05, ly=1.05, color='#555555', lw=1.3)

    # Từ EKF vòng ngược lên khối Sai số {B}
    ax.plot([3.03, 1.95], [2.08, 2.08], color='#1F4E79', lw=1.8)
    ax.plot([1.95, 1.95], [2.08, 3.15], color='#1F4E79', lw=1.8)
    ax.plot([1.95, 3.72], [3.15, 3.15], color='#1F4E79', lw=1.8)
    draw_arrow(ax, 3.72, 3.15, 3.72, 3.58, '$\\hat{q}_{EKF} = [\\hat{x}, \\hat{y}, \\hat{\\theta}]^T$',
               lx=2.85, ly=2.88, color='#1F4E79', lw=1.8)

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, 'diagram_1_system_architecture.png'), dpi=300, bbox_inches='tight', facecolor='white')
    plt.close(fig)


# =========================================================================
# HINH B: LUU DO THUAT TOAN BO LOC KALMAN MO RONG (EKF) CHONG GAI DOT BIEN
# =========================================================================
def make_ekf_flowchart():
    fig, ax = plt.subplots(figsize=(9.5, 10.5), dpi=300)
    ax.set_xlim(0, 9.5)
    ax.set_ylim(0, 10.5)
    ax.axis('off')

    ax.text(4.75, 10.15, 'LƯU ĐỒ THUẬT TOÁN BỘ LỌC KALMAN MỞ RỘNG (EKF)\nTÍCH HỢP CHỐNG NHIỄU GAI ĐỘT BIẾN (INNOVATION GATING)',
            ha='center', va='center', fontsize=11.5, fontweight='bold', color='#1B365D')

    # 1. Start / Init
    draw_box(ax, 2.55, 8.95, 4.4, 0.72,
             'Bắt đầu / Khởi tạo trạng thái ban đầu\n$\\hat{x}_0 = z_0, \\quad P_0 = \\mathrm{diag}(0.04, 0.04, 0.02), \\quad Q, R$',
             facecolor='#E2EFDA', edgecolor='#385723', style='round,pad=0.04', fontweight='bold')

    # 2. Read Encoder & Predict State
    draw_box(ax, 1.85, 7.45, 5.8, 1.05,
             'BƯỚC 1: DỰ ĐOÁN PHI TUYẾN (PREDICTION)\nĐọc tốc độ Encoder: $v_{odom}, \\omega_{odom}$\n'
             '$\\hat{x}_{k|k-1} = \\hat{x}_{k-1} + \\Delta t\\, v_{odom}\\cos(\\hat{\\theta}_{k-1}),\\; '
             '\\hat{y}_{k|k-1} = \\hat{y}_{k-1} + \\Delta t\\, v_{odom}\\sin(\\hat{\\theta}_{k-1})$',
             facecolor='#DDEBF7', edgecolor='#1F4E79', fontsize=8.8)

    # 3. Jacobian & Covariance Prediction
    draw_box(ax, 1.85, 6.05, 5.8, 0.95,
             'Tính Ma trận Jacobian tức thời $F_k = \\partial f / \\partial x |_{\\hat{\\theta}_{k-1}}$:\n'
             '$F_{13} = -\\Delta t\\,v_{odom}\\sin\\hat{\\theta},\\; F_{23} = \\Delta t\\,v_{odom}\\cos\\hat{\\theta}$\n'
             'Dự đoán Hiệp phương sai: $P_{k|k-1} = F_k P_{k-1} F_k^T + Q$',
             facecolor='#DDEBF7', edgecolor='#1F4E79', fontsize=8.8)

    # 4. Read Sensor & Innovation
    draw_box(ax, 2.35, 4.85, 4.8, 0.75,
             'Đọc cảm biến vị trí & IMU: $z_k = [x_m, y_m, \\theta_m]^T$\nTính sai lệch đổi mới (Innovation): $\\tilde{y}_k = z_k - \\hat{x}_{k|k-1}$',
             facecolor='#FFF2CC', edgecolor='#BF9000', fontsize=9.0)

    # 5. Decision Diamond: Outlier check
    draw_diamond(ax, 4.75, 3.65, 3.6, 1.15,
                 'Kiểm tra Gai đột biến?\n$\\|\\tilde{y}_{k,xy}\\| > 3\\sigma_{xy}$',
                 facecolor='#FCE4D6', edgecolor='#C55A11', fontsize=8.8)

    # Left branch (NO - Normal)
    draw_box(ax, 0.35, 2.25, 3.1, 0.75,
             'Phép đo bình thường:\n$R_{adapt} = R$',
             facecolor='#E2EFDA', edgecolor='#385723', fontsize=9.0, fontweight='bold')

    # Right branch (YES - Outlier detected)
    draw_box(ax, 6.05, 2.25, 3.1, 0.75,
             'Phát hiện Gai đột biến (Outlier):\nTăng phạt $R_{adapt} = 25\\,R$',
             facecolor='#F8CBAD', edgecolor='#C00000', fontsize=8.8, fontweight='bold', text_color='#800000')

    # 6. Update step
    draw_box(ax, 1.85, 0.75, 5.8, 1.05,
             'BƯỚC 2: CẬP NHẬT TRẠNG THÁI (UPDATE)\n'
             'Độ lợi Kalman: $K_k = P_{k|k-1}(P_{k|k-1} + R_{adapt})^{-1}$\n'
             'Cập nhật: $\\hat{x}_k = \\hat{x}_{k|k-1} + K_k \\tilde{y}_k, \\quad P_k = (I - K_k) P_{k|k-1}$',
             facecolor='#D9E1F2', edgecolor='#203764', fontsize=9.0, fontweight='bold')

    # Arrows
    draw_arrow(ax, 4.75, 8.93, 4.75, 8.53)
    draw_arrow(ax, 4.75, 7.43, 4.75, 7.03)
    draw_arrow(ax, 4.75, 6.03, 4.75, 5.63)
    draw_arrow(ax, 4.75, 4.83, 4.75, 4.25)

    # Diamond -> Left (Sai / Bình thường)
    ax.plot([2.95, 1.90], [3.65, 3.65], color='#385723', lw=1.5)
    draw_arrow(ax, 1.90, 3.65, 1.90, 3.03, 'Sai (Bình thường)', lx=1.75, ly=3.85, color='#385723')

    # Diamond -> Right (Đúng / Gai đột biến)
    ax.plot([6.55, 7.60], [3.65, 3.65], color='#C00000', lw=1.5)
    draw_arrow(ax, 7.60, 3.65, 7.60, 3.03, 'Đúng (Outlier!)', lx=7.75, ly=3.85, color='#C00000')

    # Merge to Update
    ax.plot([1.90, 1.90], [2.23, 1.98], color='#222222', lw=1.5)
    ax.plot([7.60, 7.60], [2.23, 1.98], color='#222222', lw=1.5)
    ax.plot([1.90, 7.60], [1.98, 1.98], color='#222222', lw=1.5)
    draw_arrow(ax, 4.75, 1.98, 4.75, 1.82)

    # Loop back k -> k+1
    ax.plot([1.83, 0.15], [1.28, 1.28], color='#1F4E79', lw=1.5, ls='--')
    ax.plot([0.15, 0.15], [1.28, 7.98], color='#1F4E79', lw=1.5, ls='--')
    draw_arrow(ax, 0.15, 7.98, 1.83, 7.98, 'Bước kế tiếp\n$k \\leftarrow k+1$', lx=0.88, ly=5.20, color='#1F4E79')

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, 'diagram_2_ekf_flowchart.png'), dpi=300, bbox_inches='tight', facecolor='white')
    plt.close(fig)


# =========================================================================
# HINH C: SO DO KHOI BO DIEU KHIEN PID TRONG HE TOA DO THAN XE {B}
# =========================================================================
def make_pid_flowchart():
    fig, ax = plt.subplots(figsize=(11.5, 5.2), dpi=300)
    ax.set_xlim(0, 11.5)
    ax.set_ylim(0, 5.2)
    ax.axis('off')

    ax.text(5.75, 4.9, 'SƠ ĐỒ CẤU TRÚC BỘ ĐIỀU KHIỂN PID BÁM QUỸ ĐẠO (FILTERED D + ANTI-WINDUP)',
            ha='center', va='center', fontsize=12.0, fontweight='bold', color='#1B365D')

    # Input
    draw_box(ax, 0.25, 1.95, 2.25, 1.30,
             'Sai số trong hệ {B}\n(từ $\\hat{q}_{EKF}$ và $q_{ref}$):\n$e_x, \\; e_y, \\; e_\\theta$',
             facecolor='#E2EFDA', edgecolor='#385723', fontweight='bold')

    # 3 nhánh P, I, D
    draw_box(ax, 3.25, 3.45, 3.15, 0.90,
             'Khâu Tỷ lệ (P)\n$u_P = K_p \\cdot e(k)$\n(Tạo lực kéo nhanh về quỹ đạo)',
             facecolor='#DDEBF7', edgecolor='#1F4E79', fontsize=9.0, fontweight='bold')

    draw_box(ax, 3.25, 2.15, 3.15, 0.95,
             'Khâu Tích phân (I) + Anti-windup\n$I(k) = \\mathrm{sat}(I(k-1) + e(k)\\Delta t)$\n(Triệt tiêu sai số tĩnh do trượt bánh)',
             facecolor='#FFF2CC', edgecolor='#BF9000', fontsize=8.8, fontweight='bold')

    draw_box(ax, 3.25, 0.80, 3.15, 0.95,
             'Khâu Đạo hàm (D) + Lọc thông thấp\n$d_f(k) = (1-\\alpha)d_f(k-1) + \\alpha\\frac{\\Delta e}{\\Delta t}$\n(Giảm vọt lố, không khuếch đại nhiễu)',
             facecolor='#FCE4D6', edgecolor='#C55A11', fontsize=8.8, fontweight='bold')

    # Nút cộng tổng
    circle = patches.Circle((7.45, 2.60), 0.30, facecolor='#F2F2F2', edgecolor='#222222', lw=1.6, zorder=3)
    ax.add_patch(circle)
    ax.text(7.45, 2.60, '$\\Sigma$', ha='center', va='center', fontsize=14, fontweight='bold', zorder=4)

    # Feedforward
    draw_box(ax, 6.60, 3.85, 1.70, 0.65,
             'Bù tiến (Feedforward)\n$v_r\\cos e_\\theta, \\; \\omega_r$',
             facecolor='#EDEDED', edgecolor='#595959', fontsize=8.5, fontweight='bold')
    draw_arrow(ax, 7.45, 3.83, 7.45, 2.92)

    # Saturation + Smoothing
    draw_box(ax, 8.20, 2.05, 1.80, 1.10,
             'Bão hòa vận tốc\n$|v| \\leq 1.8\\,\\mathrm{m/s}$\n$|\\omega| \\leq 3.0\\,\\mathrm{rad/s}$',
             facecolor='#D9E1F2', edgecolor='#203764', fontsize=8.8, fontweight='bold')

    # Output
    draw_box(ax, 10.30, 2.15, 1.00, 0.90,
             'Lệnh lái\n$v_{cmd}$\n$\\omega_{cmd}$',
             facecolor='#E2EFDA', edgecolor='#385723', fontsize=9.2, fontweight='bold')

    # Connections
    ax.plot([2.52, 2.85], [2.60, 2.60], color='#222222', lw=1.5)
    ax.plot([2.85, 2.85], [1.28, 3.90], color='#222222', lw=1.5)
    draw_arrow(ax, 2.85, 3.90, 3.23, 3.90)
    draw_arrow(ax, 2.85, 2.60, 3.23, 2.60)
    draw_arrow(ax, 2.85, 1.28, 3.23, 1.28)

    ax.plot([6.42, 6.60], [3.65, 3.65], color='#222222', lw=1.4)
    draw_arrow(ax, 6.60, 3.65, 7.22, 2.84)
    draw_arrow(ax, 6.42, 2.60, 7.13, 2.60)
    ax.plot([6.42, 6.60], [1.28, 1.28], color='#222222', lw=1.4)
    draw_arrow(ax, 6.60, 1.28, 7.22, 2.36)

    draw_arrow(ax, 7.77, 2.60, 8.18, 2.60)
    draw_arrow(ax, 10.02, 2.60, 10.28, 2.60)

    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, 'diagram_3_pid_control_loop.png'), dpi=300, bbox_inches='tight', facecolor='white')
    plt.close(fig)


if __name__ == '__main__':
    make_system_architecture()
    make_ekf_flowchart()
    make_pid_flowchart()
    print('Generated 3 diagrams successfully!')
