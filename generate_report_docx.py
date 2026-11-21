# -*- coding: utf-8 -*-
"""
Script tao Bao cao Cuoi ky Hoc phan Ky thuat Robot (.docx)
Chuan 100% theo:
  - 1 Huong_dan_bao_cao.docx (A4, Times New Roman 13, gian dong 1.35, can deu)
  - 2 Rubric_danh_gia_bao_cao.docx (C1-C5 muc Xuat sac 9.0-10.0)
  - Huong dan su dung vi du mau, ma nguon mo va trich dan IEEE
"""
import os
import docx
from docx import Document
from docx.shared import Inches, Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

RES_DIR = r'c:\robot\Topic4_RobustMobileRobotControl\results'
OUT_DOCX = r'c:\robot\Topic4_RobustMobileRobotControl\Bao_cao_Cuoi_ky_Ky_thuat_Robot_HuynhMinhThuan_22KTMT1.docx'


def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)


def set_cell_margins(cell, top=80, bottom=80, left=110, right=110):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)


def add_page_number_footer(section):
    footer = section.footer
    p = footer.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run("Trang ")
    run.font.name = "Times New Roman"
    run.font.size = Pt(11)
    fldChar1 = parse_xml(r'<w:fldChar %s w:fldCharType="begin"/>' % nsdecls('w'))
    instrText = parse_xml(r'<w:instrText %s xml:space="preserve"> PAGE </w:instrText>' % nsdecls('w'))
    fldChar2 = parse_xml(r'<w:fldChar %s w:fldCharType="separate"/>' % nsdecls('w'))
    fldChar3 = parse_xml(r'<w:fldChar %s w:fldCharType="end"/>' % nsdecls('w'))
    r_pg = p.add_run()
    r_pg.font.name = "Times New Roman"
    r_pg.font.size = Pt(11)
    r_pg._r.append(fldChar1)
    r_pg._r.append(instrText)
    r_pg._r.append(fldChar2)
    r_pg._r.append(fldChar3)


def add_cover_border(section):
    sectPr = section._sectPr
    pgBorders = parse_xml(
        f'<w:pgBorders {nsdecls("w")} w:offsetFrom="page">'
        f'  <w:top w:val="double" w:sz="12" w:space="24" w:color="1F4E79"/>'
        f'  <w:left w:val="double" w:sz="12" w:space="24" w:color="1F4E79"/>'
        f'  <w:bottom w:val="double" w:sz="12" w:space="24" w:color="1F4E79"/>'
        f'  <w:right w:val="double" w:sz="12" w:space="24" w:color="1F4E79"/>'
        f'</w:pgBorders>'
    )
    sectPr.append(pgBorders)


def style_paragraph(p, align=WD_ALIGN_PARAGRAPH.JUSTIFY, space_before=0, space_after=6, line_spacing=1.35, first_line=0.8):
    p.alignment = align
    pf = p.paragraph_format
    pf.space_before = Pt(space_before)
    pf.space_after = Pt(space_after)
    pf.line_spacing = line_spacing
    if first_line > 0 and align == WD_ALIGN_PARAGRAPH.JUSTIFY:
        pf.first_line_indent = Cm(first_line)


def add_body(doc, text, bold_prefix=None, indent=True):
    p = doc.add_paragraph()
    style_paragraph(p, align=WD_ALIGN_PARAGRAPH.JUSTIFY, space_after=6, line_spacing=1.35, first_line=(0.8 if indent else 0.0))
    if bold_prefix:
        r0 = p.add_run(bold_prefix)
        r0.bold = True
        r0.font.name = 'Times New Roman'
        r0.font.size = Pt(13)
    r = p.add_run(text)
    r.font.name = 'Times New Roman'
    r.font.size = Pt(13)
    return p


def add_bullet(doc, bold_prefix, text):
    p = doc.add_paragraph(style='List Bullet')
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.line_spacing = 1.35
    if bold_prefix:
        r0 = p.add_run(bold_prefix)
        r0.bold = True
        r0.font.name = 'Times New Roman'
        r0.font.size = Pt(13)
    r = p.add_run(text)
    r.font.name = 'Times New Roman'
    r.font.size = Pt(13)
    return p


def add_formula(doc, eq_text, eq_num):
    tbl = doc.add_table(rows=1, cols=2)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False
    tbl.columns[0].width = Cm(14.0)
    tbl.columns[1].width = Cm(2.0)
    c0, c1 = tbl.rows[0].cells[0], tbl.rows[0].cells[1]
    p0 = c0.paragraphs[0]
    p0.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p0.paragraph_format.space_before = Pt(4)
    p0.paragraph_format.space_after = Pt(4)
    r0 = p0.add_run(eq_text)
    r0.font.name = 'Cambria Math'
    r0.font.size = Pt(12)
    r0.italic = True

    p1 = c1.paragraphs[0]
    p1.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p1.paragraph_format.space_before = Pt(4)
    p1.paragraph_format.space_after = Pt(4)
    r1 = p1.add_run(f"({eq_num})")
    r1.font.name = 'Times New Roman'
    r1.font.size = Pt(12)


def add_chapter_heading(doc, title, page_break=True):
    if page_break:
        doc.add_page_break()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(6)
    p.paragraph_format.space_after = Pt(12)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(title.upper())
    r.bold = True
    r.font.name = 'Times New Roman'
    r.font.size = Pt(15)
    r.font.color.rgb = RGBColor(0x1B, 0x36, 0x5D)
    return p


def add_h2(doc, title):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(title)
    r.bold = True
    r.font.name = 'Times New Roman'
    r.font.size = Pt(13.5)
    r.font.color.rgb = RGBColor(0x1F, 0x4E, 0x79)
    return p


def add_h3(doc, title):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_before = Pt(6)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(title)
    r.bold = True
    r.italic = True
    r.font.name = 'Times New Roman'
    r.font.size = Pt(13)
    return p


def add_figure(doc, img_filename, caption, width_inches=6.0):
    img_path = os.path.join(RES_DIR, img_filename)
    p_img = doc.add_paragraph()
    p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_img.paragraph_format.space_before = Pt(8)
    p_img.paragraph_format.space_after = Pt(3)
    p_img.paragraph_format.keep_with_next = True
    run = p_img.add_run()
    run.add_picture(img_path, width=Inches(width_inches))

    p_cap = doc.add_paragraph()
    p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_cap.paragraph_format.space_before = Pt(0)
    p_cap.paragraph_format.space_after = Pt(10)
    r = p_cap.add_run(caption)
    r.italic = True
    r.font.name = 'Times New Roman'
    r.font.size = Pt(11.5)


def add_styled_table(doc, headers, rows, caption, col_widths_cm=None, bold_last_row=False):
    p_cap = doc.add_paragraph()
    p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_cap.paragraph_format.space_before = Pt(8)
    p_cap.paragraph_format.space_after = Pt(4)
    p_cap.paragraph_format.keep_with_next = True
    rc = p_cap.add_run(caption)
    rc.bold = True
    rc.font.name = 'Times New Roman'
    rc.font.size = Pt(12)

    tbl = doc.add_table(rows=len(rows) + 1, cols=len(headers))
    tbl.style = 'Table Grid'
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER

    # Header row
    hdr_cells = tbl.rows[0].cells
    for i, h in enumerate(headers):
        set_cell_background(hdr_cells[i], '1F4E79')
        set_cell_margins(hdr_cells[i], top=90, bottom=90, left=80, right=80)
        hdr_cells[i].vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        p = hdr_cells[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        r = p.add_run(h)
        r.bold = True
        r.font.name = 'Times New Roman'
        r.font.size = Pt(11.5)
        r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)

    # Data rows
    for r_idx, row_data in enumerate(rows):
        row_cells = tbl.rows[r_idx + 1].cells
        bg = 'E9F2FA' if (bold_last_row and r_idx == len(rows) - 1) else ('F7F9FC' if r_idx % 2 == 1 else 'FFFFFF')
        for c_idx, val in enumerate(row_data):
            set_cell_background(row_cells[c_idx], bg)
            set_cell_margins(row_cells[c_idx], top=70, bottom=70, left=80, right=80)
            row_cells[c_idx].vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = row_cells[c_idx].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT if c_idx == 0 else WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = 1.15
            r = p.add_run(str(val))
            r.font.name = 'Times New Roman'
            r.font.size = Pt(11.5)
            if bold_last_row and r_idx == len(rows) - 1:
                r.bold = True

    if col_widths_cm:
        for row in tbl.rows:
            for i, w in enumerate(col_widths_cm):
                row.cells[i].width = Cm(w)

    p_sp = doc.add_paragraph()
    p_sp.paragraph_format.space_before = Pt(0)
    p_sp.paragraph_format.space_after = Pt(4)


def build_report():
    doc = Document()

    # =====================================================================
    # CAU HINH TRANG A4 & LE THEO QUY CACH BAO CAO CHUNG
    # =====================================================================
    sec0 = doc.sections[0]
    sec0.page_width = Cm(21.0)
    sec0.page_height = Cm(29.7)
    sec0.top_margin = Cm(2.5)
    sec0.bottom_margin = Cm(2.5)
    sec0.left_margin = Cm(3.0)
    sec0.right_margin = Cm(2.0)
    add_cover_border(sec0)

    # Set default Normal style
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Times New Roman'
    normal_style.font.size = Pt(13)

    # =====================================================================
    # TRANG BÌA (COVER PAGE)
    # =====================================================================
    def cover_line(text, size=14, bold=False, italic=False, color=None, before=0, after=4):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(before)
        p.paragraph_format.space_after = Pt(after)
        r = p.add_run(text)
        r.font.name = 'Times New Roman'
        r.font.size = Pt(size)
        r.bold = bold
        r.italic = italic
        if color:
            r.font.color.rgb = color
        return p

    cover_line("ĐẠI HỌC ĐÀ NẴNG", size=14, bold=True, before=6, after=2)
    cover_line("TRƯỜNG ĐẠI HỌC BÁCH KHOA", size=14, bold=True, after=2)
    cover_line("KHOA ĐIỆN TỬ – TRÍ TUỆ NHÂN TẠO", size=13.5, bold=True, color=RGBColor(0x1F, 0x4E, 0x79), after=36)

    cover_line("BÁO CÁO CUỐI KỲ", size=22, bold=True, color=RGBColor(0x1B, 0x36, 0x5D), before=24, after=8)
    cover_line("HỌC PHẦN: KỸ THUẬT ROBOT", size=15, bold=True, after=30)

    cover_line("ĐỀ TÀI (CHỦ ĐỀ 4):", size=13.5, bold=True, after=8)
    cover_line(
        "ĐIỀU KHIỂN ROBOT DI ĐỘNG TRONG MÔI TRƯỜNG CÓ NHIỄU VÀ BẤT ĐỊNH\n"
        "ỨNG DỤNG BỘ LỌC KALMAN MỞ RỘNG (EKF) KẾT HỢP PID CHO ROBOT AGV VI SAI 2 BÁNH",
        size=15.5, bold=True, color=RGBColor(0x1F, 0x4E, 0x79), after=48
    )

    # Bang thong tin sinh vien & GVHD
    tbl_info = doc.add_table(rows=4, cols=2)
    tbl_info.alignment = WD_TABLE_ALIGNMENT.CENTER
    info_data = [
        ("Giảng viên hướng dẫn:", "TS. Phan Trần Đăng Khoa"),
        ("Sinh viên thực hiện:", "Huỳnh Minh Thuận"),
        ("Mã số sinh viên:", "106220236"),
        ("Lớp sinh hoạt:", "22KTMT1"),
    ]
    for idx, (k, v) in enumerate(info_data):
        c0, c1 = tbl_info.rows[idx].cells[0], tbl_info.rows[idx].cells[1]
        c0.width = Cm(6.5)
        c1.width = Cm(8.0)
        p0 = c0.paragraphs[0]
        p0.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p0.paragraph_format.space_after = Pt(6)
        r0 = p0.add_run(k)
        r0.bold = True
        r0.font.name = 'Times New Roman'
        r0.font.size = Pt(13)

        p1 = c1.paragraphs[0]
        p1.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p1.paragraph_format.space_after = Pt(6)
        r1 = p1.add_run(v)
        r1.font.name = 'Times New Roman'
        r1.font.size = Pt(13)

    cover_line("Đà Nẵng, tháng 11 năm 2026", size=13, italic=True, before=95, after=0)

    # Chuyen sang section moi khong co khung vien bia, co danh so trang
    sec1 = doc.add_section(docx.enum.section.WD_SECTION.NEW_PAGE)
    sec1.page_width = Cm(21.0)
    sec1.page_height = Cm(29.7)
    sec1.top_margin = Cm(2.5)
    sec1.bottom_margin = Cm(2.5)
    sec1.left_margin = Cm(3.0)
    sec1.right_margin = Cm(2.0)
    sec1.footer.is_linked_to_previous = False
    add_page_number_footer(sec1)

    # =====================================================================
    # MỤC LỤC, DANH MỤC HÌNH VẼ, BẢNG BIỂU & TỪ VIẾT TẮT
    # =====================================================================
    add_chapter_heading(doc, "MỤC LỤC", page_break=False)
    toc_items = [
        ("DANH MỤC HÌNH VẼ, BẢNG BIỂU VÀ TỪ VIẾT TẮT", True),
        ("CHƯƠNG 1. GIỚI THIỆU", True),
        ("    1.1. Bối cảnh và bài toán ứng dụng cụ thể", False),
        ("    1.2. Mục tiêu nghiên cứu", False),
        ("    1.3. Phạm vi thực hiện", False),
        ("    1.4. Cấu trúc báo cáo", False),
        ("CHƯƠNG 2. CƠ SỞ LÝ THUYẾT", True),
        ("    2.1. Tổng quan bài toán điều khiển robot di động trong môi trường nhiễu", False),
        ("    2.2. Mô hình động học Robot vi sai 2 bánh và 4 loại nhiễu thực tế", False),
        ("    2.3. Lý thuyết Bộ lọc Kalman tuyến tính (KF) và Kalman Mở rộng (EKF)", False),
        ("    2.4. Lý thuyết Bộ điều khiển PID (Filtered D và Anti-windup)", False),
        ("    2.5. Phân tích ưu – nhược điểm và lý do kết hợp EKF + PID", False),
        ("CHƯƠNG 3. NỘI DUNG NGHIÊN CỨU VÀ THIẾT KẾ HỆ THỐNG", True),
        ("    3.1. Phát biểu bài toán, giả thiết, ràng buộc và 6 tiêu chí đánh giá", False),
        ("    3.2. Phương pháp tiếp cận và Kiến trúc hệ thống tổng thể", False),
        ("    3.3. Thiết kế thuật toán EKF tích hợp chống gai đột biến (3σ Gating)", False),
        ("    3.4. Thiết kế Bộ điều khiển PID trong hệ tọa độ thân xe {B}", False),
        ("    3.5. Công cụ, thiết lập thông số mô phỏng và Minh bạch nguồn thực hiện", False),
        ("CHƯƠNG 4. KẾT QUẢ MÔ PHỎNG VÀ THẢO LUẬN", True),
        ("    4.1. Kịch bản 1: Bám quỹ đạo hình số 8 dưới 4 loại nhiễu đồng thời", False),
        ("    4.2. Kịch bản 2: Bám đường thẳng (RVC3) khi có trượt bánh ngang", False),
        ("    4.3. Kịch bản 3: Phân tích độ nhạy theo cường độ nhiễu (50% – 200%)", False),
        ("    4.4. Kiểm chứng trực tiếp trên mô hình Simulink", False),
        ("    4.5. Đánh giá ưu – nhược điểm và các hạn chế còn tồn tại", False),
        ("CHƯƠNG 5. KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN", True),
        ("    5.1. Kết luận", False),
        ("    5.2. Hướng phát triển", False),
        ("TÀI LIỆU THAM KHẢO", True),
        ("PHỤ LỤC: MÃ NGUỒN, HƯỚNG DẪN CHẠY VÀ MINH BẠCH AI", True),
    ]
    for item, is_bold in toc_items:
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(1)
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.line_spacing = 1.25
        r = p.add_run(item)
        r.font.name = 'Times New Roman'
        r.font.size = Pt(12.5)
        r.bold = is_bold

    doc.add_page_break()
    add_chapter_heading(doc, "DANH MỤC HÌNH VẼ, BẢNG BIỂU VÀ TỪ VIẾT TẮT", page_break=False)

    add_h2(doc, "1. Danh mục Hình vẽ")
    figs_list = [
        "Hình 3.1. Sơ đồ kiến trúc tổng thể hệ thống điều khiển kín EKF + PID cho Robot di động.",
        "Hình 3.2. Lưu đồ thuật toán Bộ lọc Kalman Mở rộng (EKF) tích hợp khâu chống nhiễu gai 3σ.",
        "Hình 3.3. Sơ đồ cấu trúc Bộ điều khiển PID bám quỹ đạo (Filtered D + Anti-windup).",
        "Hình 4.1. Quỹ đạo 2D hình số 8 của 4 mô hình và phóng to khúc cua có trượt bánh.",
        "Hình 4.2. Đáp ứng sai số bám vị trí Euclid, sai số ngang và sai số góc hướng theo thời gian.",
        "Hình 4.3. Tín hiệu điều khiển, hiệu quả lọc nhiễu KF vs. EKF và độ trôi Odometry.",
        "Hình 4.4. Kịch bản 2 – Bám đường thẳng x - 2y + 4 = 0 (RVC3) khi có trượt bánh ngang.",
        "Hình 4.5. Biểu đồ cột so sánh RMSE/MAE/Max Error và Phân tích độ nhạy (50% – 200%).",
        "Hình 4.6. Sơ đồ khối Simulink hoàn chỉnh (sl_robust_mobile_robot.slx) với khối Robot Model.",
        "Hình 4.7. Kết quả kiểm chứng quỹ đạo XY và sai số bám trực tiếp trên Simulink."
    ]
    for f in figs_list:
        add_body(doc, f, indent=False)

    add_h2(doc, "2. Danh mục Bảng biểu")
    tabs_list = [
        "Bảng 2.1. So sánh đặc điểm 4 mô hình lọc nhiễu và điều khiển được khảo sát.",
        "Bảng 3.1. Thông số vật lý Robot vi sai 2 bánh và cấu hình 4 loại nhiễu mô phỏng.",
        "Bảng 3.2. Bộ tham số tinh chỉnh cho các bộ điều khiển P, PID và bộ lọc KF / EKF.",
        "Bảng 3.3. Phân biệt minh bạch phần kế thừa tham khảo và phần tự thiết kế, mở rộng.",
        "Bảng 4.1. Bảng tổng hợp 6 chỉ số đánh giá định lượng ở Kịch bản 1 (Quỹ đạo hình số 8).",
        "Bảng 4.2. So sánh sai số RMSE_p [m] của 4 mô hình khi tăng cường độ nhiễu từ 50% đến 200%."
    ]
    for tb in tabs_list:
        add_body(doc, tb, indent=False)

    add_h2(doc, "3. Danh mục Từ viết tắt")
    abbr_rows = [
        ("AGV", "Automated Guided Vehicle (Xe tự hành vận chuyển hàng hóa)"),
        ("EKF", "Extended Kalman Filter (Bộ lọc Kalman mở rộng)"),
        ("IAE", "Integral of Absolute Error (Tích phân sai số tuyệt đối)"),
        ("IMU", "Inertial Measurement Unit (Cụm cảm biến quán tính)"),
        ("KF", "Kalman Filter (Bộ lọc Kalman tuyến tính chuẩn)"),
        ("MAE", "Mean Absolute Error (Sai số tuyệt đối trung bình)"),
        ("PID", "Proportional – Integral – Derivative (Tỷ lệ – Tích phân – Đạo hàm)"),
        ("RMSE", "Root Mean Square Error (Sai số toàn phương trung bình căn)"),
        ("RVC3", "Robotics, Vision and Control, 3rd Edition (Giáo trình Peter Corke)"),
        ("TV", "Total Variation (Độ biến thiên tổng / Độ giật tín hiệu điều khiển)"),
        ("UWB", "Ultra-Wideband (Công nghệ định vị siêu băng rộng trong nhà)")
    ]
    add_styled_table(doc, ["Từ viết tắt", "Giải thích đầy đủ"], abbr_rows,
                     "Danh mục các thuật ngữ viết tắt sử dụng trong báo cáo", col_widths_cm=[3.5, 12.5])

    # =====================================================================
    # CHƯƠNG 1. GIỚI THIỆU
    # =====================================================================
    add_chapter_heading(doc, "CHƯƠNG 1. GIỚI THIỆU")

    add_h2(doc, "1.1. Bối cảnh và bài toán ứng dụng cụ thể")
    add_body(doc,
        "Trong xu thế tự động hóa sản xuất và kho vận thông minh (Smart Factory & Smart Logistics), robot di động tự hành "
        "vận chuyển hàng hóa (AGV – Automated Guided Vehicle) sử dụng cấu trúc vi sai 2 bánh chủ động (Differential Drive) "
        "được triển khai rộng rãi nhờ kết cấu cơ khí gọn nhẹ, bán kính quay vòng nhỏ và khả năng cơ động cao trong các lối đi hẹp. "
        "Nhiệm vụ cốt lõi của AGV là di chuyển bám sát quỹ đạo đặt trước giữa các trạm gia công và khu vực lưu kho với độ chính xác cao, "
        "đảm bảo an toàn cho con người và hàng hóa."
    )
    add_body(doc,
        "Tuy nhiên, khác với các bài toán điều khiển động học lý tưởng trong phòng thí nghiệm, môi trường nhà xưởng công nghiệp thực tế "
        "chứa đựng nhiều nguồn nhiễu và yếu tố bất định tác động đồng thời lên hệ thống: (1) cảm biến định vị trong nhà (như UWB, LiDAR, "
        "camera trần kết hợp IMU) luôn tồn tại nhiễu đo lường ngẫu nhiên dạng Gaussian; (2) hiện tượng phản xạ đa đường (multipath) hoặc che khuất "
        "tạm thời gây ra các xung nhiễu gai đột biến (Outliers); (3) cảm biến Encoder gắn trên hai bánh xe chịu nhiễu xung và độ trôi tích lũy "
        "(Odometry drift); và (4) bề mặt sàn nhà xưởng tại một số phân khu dính dầu mỡ, bụi mịn hoặc ẩm ướt gây ra hiện tượng trượt bánh dọc và "
        "trượt ngang (Wheel slip), phá vỡ giả thiết lăn không trượt lý tưởng."
    )
    add_body(doc,
        "Nếu sử dụng các bộ điều khiển cổ điển lấy trực tiếp tín hiệu cảm biến thô (chưa lọc nhiễu), thành phần đạo hàm sẽ khuếch đại mạnh "
        "nhiễu cao tần và gai đột biến, gây rung giật cơ cấu chấp hành, mòn động cơ và mất ổn định quỹ đạo. Ngược lại, nếu chỉ tập trung lọc nhiễu "
        "bằng Kalman Filter mà sử dụng bộ điều khiển tỷ lệ (P) đơn giản, robot sẽ xuất hiện sai số xác lập (steady-state offset) không thể tự triệt tiêu "
        "khi gặp trượt bánh kéo dài. Do đó, việc nghiên cứu, thiết kế và kiểm chứng một kiến trúc kết hợp chặt chẽ giữa ước lượng trạng thái phi tuyến "
        "(Extended Kalman Filter – EKF) và điều khiển bám quỹ đạo (PID có lọc thông thấp khâu đạo hàm và chống bão hòa tích phân) là yêu cầu cấp thiết "
        "và mang ý nghĩa thực tiễn rõ rệt."
    )

    add_h2(doc, "1.2. Mục tiêu nghiên cứu")
    add_body(doc, "Mục tiêu chung của đề tài là nghiên cứu, thiết kế và kiểm chứng bằng mô phỏng trên MATLAB/Simulink giải pháp điều khiển bám quỹ đạo "
                  "cho robot di động vi sai 2 bánh giúp duy trì độ chính xác chuyển động trong môi trường có nhiễu cảm biến, gai đột biến, trôi Encoder và trượt bánh.",
             bold_prefix="Mục tiêu chung: ")
    add_body(doc, "Để đảm bảo tính định lượng và khả năng kiểm chứng, đề tài đặt ra các mục tiêu cụ thể sau:", bold_prefix="Mục tiêu cụ thể: ")
    add_bullet(doc, "Mô hình hóa hệ thống: ", "Xây dựng mô hình động học robot vi sai 2 bánh (Differential Drive / Unicycle) mở rộng có xét quán tính động cơ và 4 nguồn nhiễu thực tế (Gaussian, Outliers, Encoder drift, Wheel slip).")
    add_bullet(doc, "Thiết kế giải pháp đề xuất (EKF + PID): ", "Cài đặt bộ lọc Kalman mở rộng (EKF) tích hợp kiểm tra ngưỡng đổi mới 3σ chống gai đột biến, kết hợp bộ điều khiển PID trong hệ tọa độ thân xe {B} có lọc thông thấp khâu D và Anti-windup.")
    add_bullet(doc, "Mục tiêu định lượng kiểm chứng được: ", "Giảm ít nhất 35% sai số RMSE vị trí so với mô hình Chỉ có EKF (EKF + P); giảm trên 85% độ giật tín hiệu điều khiển TV_ω so với mô hình Chỉ có PID (không lọc); vượt trội hơn Standard KF + PID trên quỹ đạo cong; và triệt tiêu hoàn toàn sai số xác lập (e_ss -> 0) khi bám đường thẳng có trượt ngang.")
    add_bullet(doc, "Kiểm chứng đa nền tảng: ", "Xây dựng đầy đủ bộ mã nguồn MATLAB Script (chạy 3 kịch bản + hoạt ảnh 2D) và sơ đồ khối Simulink (.slx) hoạt động độc lập, dễ tái lập.")

    add_h2(doc, "1.3. Phạm vi thực hiện")
    add_bullet(doc, "Không gian hoạt động: ", "Chuyển động phẳng 2D trong mặt phẳng (x, y) của sàn nhà xưởng, trạng thái robot gồm 3 biến [x, y, θ]^T.")
    add_bullet(doc, "Giới hạn mô hình: ", "Tập trung vào 4 loại nhiễu cốt lõi (nhiễu cảm biến Gaussian, nhiễu gai đột biến, nhiễu Encoder + trôi, và trượt bánh dọc/ngang); bỏ qua sai số hình học chế tạo bánh xe (giả thiết r_R = r_L = r_0, b = b_0) và chưa xét bài toán tránh vật cản động.")
    add_bullet(doc, "Hình thức kiểm chứng: ", "Mô hình hóa toán học và mô phỏng kiểm chứng định lượng trên MATLAB R2024a và Simulink.")

    add_h2(doc, "1.4. Cấu trúc báo cáo")
    add_body(doc, "Ngoài phần mở đầu, tài liệu tham khảo và phụ lục, nội dung chính của báo cáo được tổ chức thành 5 chương: "
                  "Chương 1 trình bày bối cảnh ứng dụng, mục tiêu và phạm vi; "
                  "Chương 2 hệ thống hóa cơ sở lý thuyết về động học xe vi sai, 4 loại nhiễu, Kalman Filter (KF/EKF) và bộ điều khiển PID; "
                  "Chương 3 trình bày chi tiết thiết kế thuật toán, sơ đồ khối, lưu đồ và thiết lập thông số mô phỏng; "
                  "Chương 4 phân tích kết quả thực nghiệm qua 3 kịch bản MATLAB và kiểm chứng Simulink; "
                  "Chương 5 tổng kết kết quả đạt được và đề xuất hướng phát triển tiếp theo.")

    # =====================================================================
    # CHƯƠNG 2. CƠ SỞ LÝ THUYẾT
    # =====================================================================
    add_chapter_heading(doc, "CHƯƠNG 2. CƠ SỞ LÝ THUYẾT")

    add_h2(doc, "2.1. Tổng quan bài toán điều khiển robot di động trong môi trường nhiễu")
    add_body(doc,
        "Điều khiển bám quỹ đạo (Trajectory Tracking) cho robot di động có bánh xe (Wheeled Mobile Robot – WMR) là bài toán tổng hợp "
        "tín hiệu vận tốc dài v(t) và vận tốc góc ω(t) sao cho cấu hình thực tế q(t) = [x(t), y(t), θ(t)]^T hội tụ về quỹ đạo tham chiếu "
        "phụ thuộc thời gian q_r(t) = [x_r(t), y_r(t), θ_r(t)]^T. Theo giáo trình Robotics, Vision and Control (RVC3) của Peter Corke [5] "
        "và tài liệu chuẩn của MathWorks [1], [2], các phương pháp điều khiển cơ bản như điều khiển tỷ lệ (Proportional) hay Pure Pursuit "
        "hoạt động hiệu quả trong điều kiện lý tưởng khi trạng thái đo lường chính xác và bánh xe lăn không trượt."
    )
    add_body(doc,
        "Tuy nhiên, khi đưa vào môi trường công nghiệp thực tế, hai thách thức lớn xuất hiện đồng thời: (i) trạng thái đo lường bị ô nhiễm "
        "bởi nhiễu cảm biến và các điểm ngoại lai (Outliers), và (ii) nhiễu quá trình dạng trượt bánh làm sai lệch quan hệ giữa vận tốc lệnh "
        "và vận tốc dịch chuyển thực tế. Để giải quyết trọn vẹn bài toán này, hệ thống cần tách bạch rõ hai lớp chức năng: Lớp ước lượng trạng thái "
        "(State Estimation) dùng Bộ lọc Kalman để làm sạch số đo và hợp nhất cảm biến [3], [4], [6], và Lớp điều khiển vòng kín (Feedback Control) "
        "dùng Bộ điều khiển PID có khâu tích phân và lọc nhiễu đạo hàm [5] để bù sai lệch động học và triệt tiêu sai số xác lập."
    )

    add_h2(doc, "2.2. Mô hình động học Robot vi sai 2 bánh và 4 loại nhiễu thực tế")
    add_h3(doc, "2.2.1. Phương trình động học lý tưởng và mở rộng khi có trượt bánh")
    add_body(doc,
        "Xét robot vi sai 2 bánh chủ động có bán kính bánh xe r_0 và khoảng cách giữa hai tâm bánh (wheelbase) là b_0. "
        "Gọi ω_R và ω_L lần lượt là vận tốc góc của bánh phải và bánh trái. Quan hệ động học thuận giữa vận tốc hai bánh và vận tốc "
        "tịnh tiến v, vận tốc quay ω của thân xe được xác định bởi [2], [5]:"
    )
    add_formula(doc, "v_wheel = (r_0 / 2) · (ω_R + ω_L),      ω_wheel = (r_0 / b_0) · (ω_R - ω_L)", "2.1")
    add_body(doc,
        "Trong điều kiện lăn không trượt lý tưởng, robot tuân theo ràng buộc phi holonomic (non-holonomic constraint): "
        "ẏ·cos(θ) - ẋ·sin(θ) = 0, nghĩa là vận tốc theo phương ngang trục bánh xe bằng không. Tuy nhiên, khi đi qua vùng sàn trơn trượt "
        "hoặc vào cua chịu lực ly tâm, bánh xe phát sinh vận tốc trượt dọc d_v(t), trượt quay d_ω(t) và vận tốc trượt ngang v_(y,slip)(t) ≠ 0. "
        "Kết hợp với quán tính bậc 1 của cụm động cơ (hằng số thời gian τ_v, τ_ω), mô hình động học – động lực học thực tế của robot trở thành:"
    )
    add_formula(doc, "τ_v · v̇ + v = v_wheel + d_v(t),      τ_ω · ω̇ + ω = ω_wheel + d_ω(t)", "2.2")
    add_formula(doc, "ẋ = v·cos(θ) - v_(y,slip)·sin(θ),   ẏ = v·sin(θ) + v_(y,slip)·cos(θ),   θ̇ = ω", "2.3")

    add_h3(doc, "2.2.2. Mô hình hóa 4 loại nhiễu tham gia trong đề tài")
    add_bullet(doc, "Nhiễu cảm biến Gaussian (Sensor Noise): ", "Phép đo vị trí (x_m, y_m) từ hệ thống UWB/Camera và góc hướng θ_m từ IMU chịu nhiễu trắng phân bố chuẩn ν_k ~ N(0, R) với ma trận hiệp phương sai R = diag(σ_xy^2, σ_xy^2, σ_θ^2).")
    add_bullet(doc, "Nhiễu gai đột biến (Sensor Outliers / Spikes): ", "Tại các thời điểm rời rạc do phản xạ tín hiệu hoặc che khuất, phép đo bị cộng thêm xung biên độ lớn Δz_spike (lên tới ±0.38 m và ±14°), vượt xa dải 3σ thông thường.")
    add_bullet(doc, "Nhiễu Encoder và Trôi Odometry (Encoder Drift): ", "Tốc độ đo từ hai Encoder bị cộng thêm nhiễu trắng và độ lệch hệ thống (bias_R, bias_L): ω_(R,enc) = ω_(R,cmd) + n_R + b_R. Khi tích phân theo thời gian (Dead-reckoning), sai số vị trí sẽ tích lũy tăng dần không giới hạn nếu không có cảm biến ngoài hiệu chỉnh.")
    add_bullet(doc, "Trượt bánh (Wheel Slip): ", "Gồm trượt dọc d_v(t) làm hao hụt lực đẩy khi qua vùng sàn trơn và trượt ngang v_(y,slip)(t) tỷ lệ với lực ly tâm v·ω hoặc độ nghiêng mặt sàn.")

    add_h2(doc, "2.3. Lý thuyết Bộ lọc Kalman tuyến tính (KF) và Kalman Mở rộng (EKF)")
    add_body(doc,
        "Bộ lọc Kalman (Kalman Filter) là bộ ước lượng trạng thái tối ưu theo nghĩa cực tiểu hóa phương sai sai số ước lượng cho hệ thống động "
        "chịu nhiễu Gaussian [6]. Quy trình lọc đệ quy gồm hai pha: Dự đoán (Prediction) dựa trên mô hình chuyển động (Odometry) và Cập nhật (Update) "
        "dựa trên phép đo cảm biến ngoài z_k."
    )
    add_body(doc,
        "Đối với Standard Kalman Filter (KF tuyến tính), mô hình chuyển trạng thái bắt buộc có dạng tuyến tính x_k = A·x_(k-1) + B·u_k. "
        "Khi áp dụng cho robot di động 2D với ma trận đầu vào B cố định quanh góc hướng danh định θ_0, dự đoán vị trí sẽ không theo kịp sự "
        "thay đổi phi tuyến của cos(θ_k) và sin(θ_k) khi robot xoay vòng trên quỹ đạo cong, dẫn đến sai số dự đoán và trễ pha lớn."
    )
    add_body(doc,
        "Để khắc phục nhược điểm này, Bộ lọc Kalman Mở rộng (Extended Kalman Filter – EKF) [3], [4], [5] sử dụng trực tiếp hàm động học phi tuyến "
        "f(x_(k-1), u_k) ở bước dự đoán trạng thái, đồng thời tuyến tính hóa cục bộ quanh trạng thái ước lượng tức thời x̂_(k-1) bằng Ma trận Jacobian F_k:"
    )
    add_formula(doc, "x̂_(k|k-1) = f(x̂_(k-1), u_k),      P_(k|k-1) = F_k · P_(k-1) · F_k^T + Q", "2.4")
    add_formula(doc, "K_k = P_(k|k-1) · (P_(k|k-1) + R)^(-1),   x̂_k = x̂_(k|k-1) + K_k · (z_k - x̂_(k|k-1))", "2.5")
    add_body(doc,
        "Trong đó, ma trận Jacobian F_k = ∂f/∂x cập nhật liên tục hai phần tử phi tuyến F_13 = -Δt·v_odom·sin(θ̂_(k-1)) và "
        "F_23 = Δt·v_odom·cos(θ̂_(k-1)) tại mỗi chu kỳ lấy mẫu, giúp EKF truyền bá chính xác bất định của góc hướng sang bất định tọa độ (x, y)."
    )

    add_h2(doc, "2.4. Lý thuyết Bộ điều khiển PID (Filtered D và Anti-windup)")
    add_body(doc,
        "Bộ điều khiển PID (Proportional – Integral – Derivative) là cấu trúc điều khiển phản hồi kinh điển và phổ biến nhất trong công nghiệp [5]:"
    )
    add_formula(doc, "u(t) = K_p · e(t) + K_i · ∫e(τ)dτ + K_d · (de(t)/dt)", "2.6")
    add_bullet(doc, "Khâu Tỷ lệ (P): ", "Tạo tác động điều khiển tỷ lệ trực tiếp với sai số hiện tại. Tuy nhiên, nếu chỉ dùng khâu P, khi có nhiễu thường trực (như trượt bánh), hệ thống bắt buộc phải duy trì một sai số xác lập e_ss ≠ 0 để tạo ra tín hiệu bù cân bằng với nhiễu.")
    add_bullet(doc, "Khâu Tích phân (I) kết hợp Anti-windup: ", "Cộng dồn sai số quá khứ để tăng dần tín hiệu điều khiển cho tới khi sai số xác lập bị triệt tiêu hoàn toàn về 0. Để tránh hiện tượng bão hòa tích phân (Integral windup) gây vọt lố lớn khi vận tốc bị kẹp bão hòa, thành phần tích phân cần được giới hạn trong vùng [-I_max, I_max].")
    add_bullet(doc, "Khâu Đạo hàm (D) kết hợp Bộ lọc thông thấp (Filtered D): ", "Dự đoán xu hướng biến thiên sai số để tạo lực giảm chấn (damping), giảm dao động và vọt lố. Tuy nhiên, như đã chỉ ra trong bài giảng Chapter 3 Part 2 [5], đạo hàm thuần túy khuếch đại rất mạnh nhiễu đo lường cao tần. Do đó, cần tích hợp bộ lọc thông thấp bậc 1 cho khâu D: U_D(s) = (K_d·s) / (1 + T_f·s) · E(s).")

    add_h2(doc, "2.5. Phân tích ưu – nhược điểm và lý do kết hợp EKF + PID")
    t21_headers = ["Mô hình", "Cấu trúc", "Ưu điểm chính", "Nhược điểm / Hạn chế"]
    t21_rows = [
        ("1. Chỉ có PID\n(PID_Raw)", "PID nhận trực tiếp cảm biến thô", "Đơn giản, khâu I có khả năng bù trượt bánh.", "Khâu D khuếch đại nhiễu Gaussian & gai đột biến gây rung giật mạnh động cơ (TV_ω rất cao)."),
        ("2. Chỉ có EKF\n(EKF + P)", "EKF lọc nhiễu + Điều khiển P cơ bản", "Lọc sạch nhiễu cảm biến, tín hiệu lái rất mượt.", "Thiếu khâu tích phân I nên bị sai số tĩnh (steady-state error) lớn khi xảy ra trượt bánh."),
        ("3. Standard KF\n+ PID", "Kalman tuyến tính cố định + PID", "Lọc được nhiễu Gaussian trên đoạn đường thẳng, có khâu I bù trượt.", "Không cập nhật Jacobian theo góc quay θ nên bị lệch pha khi vào cua gắt và nhạy với gai đột biến."),
        ("4. Extended KF\n+ PID (Đề xuất)", "EKF (Jacobian + 3σ Gating) + PID (Filtered D + Anti-windup)", "Lọc sạch 4 loại nhiễu, chống gai đột biến, bám sát đường cong gắt và triệt tiêu sai số trượt bánh.", "Cần thiết lập hợp lý ma trận hiệp phương sai Q, R và tinh chỉnh bộ hệ số PID.")
    ]
    add_styled_table(doc, t21_headers, t21_rows,
                     "Bảng 2.1. So sánh đặc điểm 4 mô hình lọc nhiễu và điều khiển được khảo sát",
                     col_widths_cm=[3.0, 3.5, 4.7, 4.8], bold_last_row=True)

    # =====================================================================
    # CHƯƠNG 3. NỘI DUNG NGHIÊN CỨU VÀ THIẾT KẾ HỆ THỐNG
    # =====================================================================
    add_chapter_heading(doc, "CHƯƠNG 3. NỘI DUNG NGHIÊN CỨU VÀ THIẾT KẾ HỆ THỐNG")

    add_h2(doc, "3.1. Phát biểu bài toán, giả thiết, ràng buộc và 6 tiêu chí đánh giá")
    add_body(doc,
        "Cho robot AGV vi sai 2 bánh chuyển động trên mặt phẳng 2D theo phương trình (2.2)–(2.3), chịu tác động đồng thời của 4 loại nhiễu "
        "đã mô tả ở Mục 2.2.2. Bài toán đặt ra là thiết kế hệ thống ước lượng và điều khiển vòng kín sao cho robot xuất phát từ vị trí ban đầu "
        "bị đặt lệch q(0) = [0.40, -0.45, θ_r(0) - 0.30]^T nhanh chóng hội tụ và bám sát quỹ đạo tham chiếu q_r(t) thỏa mãn ràng buộc vật lý "
        "bão hòa cơ cấu chấp hành |v_cmd| ≤ 1.8 m/s và |ω_cmd| ≤ 3.0 rad/s."
    )
    add_body(doc, "Để đánh giá khách quan hiệu năng của 4 mô hình, đề tài sử dụng 6 tiêu chí định lượng chuẩn mực sau giai đoạn quá độ khởi động (t ≥ 3.0 s):", bold_prefix="Các tiêu chí đánh giá định lượng: ")
    add_bullet(doc, "RMSE_p [m] (Root Mean Square Error): ", "Sai số toàn phương trung bình căn của khoảng cách Euclid ||e_p(k)|| = √((x_r - x)^2 + (y_r - y)^2). Đây là chỉ số chính, phạt nặng các độ lệch lớn.")
    add_bullet(doc, "MAE_p [m] (Mean Absolute Error): ", "Sai số khoảng cách trung bình cộng trên toàn bộ thời gian bám ổn định.")
    add_bullet(doc, "Max_p [m] (Maximum Tracking Error): ", "Độ lệch cực đại tại thời điểm xấu nhất (qua vùng trơn hoặc dính gai nhiễu), phản ánh mức độ an toàn hành lang di chuyển.")
    add_bullet(doc, "RMSE_θ [độ]: ", "Sai số toàn phương trung bình của góc hướng đầu xe e_θ = θ_r ⊖ θ.")
    add_bullet(doc, "IAE_p [m·s] (Integral of Absolute Error): ", "Tích phân sai số vị trí theo thời gian ∫||e_p(t)||dt, đánh giá tổng sai số tích lũy và tốc độ hồi phục.")
    add_bullet(doc, "TV_ω [rad/s] (Total Variation của lệnh quay ω): ", "Độ biến thiên tổng trung bình mỗi giây TV_ω = (1/ΔT)·Σ|ω_cmd(k) - ω_cmd(k-1)|, đo trực tiếp độ giật cục và mức độ hại động cơ của tín hiệu điều khiển.")

    add_h2(doc, "3.2. Phương pháp tiếp cận và Kiến trúc hệ thống tổng thể")
    add_body(doc,
        "Hệ thống đề xuất được thiết kế theo kiến trúc điều khiển kín hai lớp gồm: (1) Lớp ước lượng trạng thái sử dụng Bộ lọc Kalman Mở rộng (EKF) "
        "tích hợp khâu kiểm tra ngưỡng đổi mới 3σ nhằm hợp nhất tốc độ Encoder bị trôi với cảm biến vị trí/IMU chứa nhiễu Gaussian và gai đột biến; "
        "(2) Lớp điều khiển bám quỹ đạo sử dụng phép biến đổi sai số về hệ tọa độ gắn trên thân robot {B} kết hợp bộ điều khiển PID có bù tiến "
        "(Feedforward), lọc thông thấp khâu D và chống bão hòa tích phân Anti-windup. Kiến trúc tổng thể được trình bày trên Hình 3.1."
    )
    add_figure(doc, "diagram_1_system_architecture.png",
               "Hình 3.1. Sơ đồ kiến trúc tổng thể hệ thống điều khiển kín EKF + PID cho Robot di động.", width_inches=6.2)

    add_h2(doc, "3.3. Thiết kế thuật toán EKF tích hợp chống gai đột biến (3σ Gating)")
    add_body(doc,
        "Tại mỗi chu kỳ lấy mẫu Δt = 0.02 s (tần số 50 Hz), thuật toán EKF thực hiện chu trình Dự đoán – Kiểm tra gai đột biến – Cập nhật "
        "như mô tả trong lưu đồ Hình 3.2:"
    )
    add_bullet(doc, "Bước 1 – Dự đoán phi tuyến: ", "Từ tín hiệu Encoder hai bánh (ω_(R,enc), ω_(L,enc)), tính vận tốc Odometry (v_odom, ω_odom) theo (2.1) và dự đoán trạng thái x̂_(k|k-1) theo góc hướng ước lượng hiện tại θ̂_(k-1). Tính ma trận Jacobian F_k và hiệp phương sai dự đoán P_(k|k-1) = F_k·P_(k-1)·F_k^T + Q.")
    add_bullet(doc, "Bước 2 – Kiểm tra ngưỡng đổi mới chống gai đột biến (Innovation Gating): ", "Tính vector đổi mới ỹ_k = z_k - x̂_(k|k-1). Nếu khoảng cách vị trí ||ỹ_(k,xy)|| > 3σ_xy (vượt ngưỡng tin cậy 99.7% của phân bố Gaussian), bộ lọc nhận diện phép đo đang dính gai đột biến (Outlier) và tự động tăng mạnh ma trận hiệp phương sai đo lường R_adapt = 25·R để giảm trọng số của phép đo lỗi, ngăn không cho gai nhiễu kéo lệch trạng thái ước lượng.")
    add_bullet(doc, "Bước 3 – Cập nhật Kalman: ", "Tính độ lợi Kalman K_k = P_(k|k-1)·(P_(k|k-1) + R_adapt)^(-1), cập nhật trạng thái x̂_k = x̂_(k|k-1) + K_k·ỹ_k (chuẩn hóa góc về [-π, π)) và cập nhật ma trận hiệp phương sai P_k = (I - K_k)·P_(k|k-1).")

    add_figure(doc, "diagram_2_ekf_flowchart.png",
               "Hình 3.2. Lưu đồ thuật toán Bộ lọc Kalman Mở rộng (EKF) tích hợp khâu chống nhiễu gai 3σ.", width_inches=5.3)

    add_h2(doc, "3.4. Thiết kế Bộ điều khiển PID trong hệ tọa độ thân xe {B}")
    add_body(doc,
        "Từ trạng thái ước lượng sạch nhiễu q̂_EKF = [x̂, ŷ, θ̂]^T và trạng thái tham chiếu q_r = [x_r, y_r, θ_r]^T, sai số vị trí và hướng "
        "được chiếu từ hệ tọa độ toàn cục {0} sang hệ tọa độ gắn trên thân robot {B} thông qua ma trận quay R^T(θ̂):"
    )
    add_formula(doc, "e_x = (x_r - x̂)·cos(θ̂) + (y_r - ŷ)·sin(θ̂),   e_y = -(x_r - x̂)·sin(θ̂) + (y_r - ŷ)·cos(θ̂),   e_θ = θ_r ⊖ θ̂", "3.1")
    add_body(doc,
        "Trong hệ tọa độ thân xe, e_x là sai số dọc trục (quyết định việc tăng/giảm tốc độ dài v), còn e_y (sai số lệch ngang – cross-track error) "
        "và e_θ (sai số góc hướng) quyết định việc bẻ lái vận tốc góc ω. Luật điều khiển PID kết hợp bù tiến (Feedforward) được tổng hợp như sau:"
    )
    add_formula(doc, "v_cmd = v_r·cos(e_θ) + K_(p,v)·e_x + K_(i,v)·I_x + K_(d,v)·d_(f,x)", "3.2")
    add_formula(doc, "ω_cmd = ω_r + v_r·(K_(p,y)·e_y + K_(i,y)·I_y + K_(d,y)·d_(f,y)) + K_(p,ω)·e_θ + K_(i,ω)·I_θ + K_(d,ω)·d_(f,θ)", "3.3")
    add_body(doc,
        "Trong đó, thành phần tích phân I_j(k) = sat(I_j(k-1) + e_j(k)·Δt, ±1.2) tích hợp Anti-windup giúp bù dứt điểm sai số tĩnh do trượt bánh "
        "mà không gây vọt lố; thành phần đạo hàm được lọc thông thấp bậc 1 dạng rời rạc d_(f,j)(k) = (1 - α_d)·d_(f,j)(k-1) + α_d·(e_j(k) - e_j(k-1))/Δt "
        "với α_d = 0.22 giúp triệt tiêu phần nhiễu dư ở tần số cao. Cấu trúc khối của bộ điều khiển PID được minh họa tại Hình 3.3."
    )
    add_figure(doc, "diagram_3_pid_control_loop.png",
               "Hình 3.3. Sơ đồ cấu trúc Bộ điều khiển PID bám quỹ đạo (Filtered D + Anti-windup).", width_inches=6.2)

    add_h2(doc, "3.5. Công cụ, thiết lập thông số mô phỏng và Minh bạch nguồn thực hiện")
    add_body(doc,
        "Toàn bộ hệ thống mô phỏng được xây dựng và chạy kiểm chứng trên nền tảng MATLAB R2024a và Simulink với bộ giải bước cố định "
        "(Fixed-step Δt = 0.02 s, thời gian mô phỏng T = 40 s), không phụ thuộc vào toolbox trả phí bên thứ 3 để đảm bảo khả năng tái lập cao. "
        "Thông số vật lý, cấu hình 4 loại nhiễu và bộ tham số điều khiển được tổng hợp trong Bảng 3.1 và Bảng 3.2."
    )

    t31_headers = ["Nhóm thông số", "Ký hiệu / Đại lượng", "Giá trị thiết lập", "Ý nghĩa vật lý"]
    t31_rows = [
        ("Robot vi sai", "r_0 / b_0", "0.08 m / 0.35 m", "Bán kính bánh xe / khoảng cách 2 bánh"),
        ("Động cơ", "τ_v / τ_ω", "0.10 s / 0.08 s", "Hằng số thời gian quán tính động cơ"),
        ("Bão hòa", "v_max / ω_max", "1.8 m/s / 3.0 rad/s", "Giới hạn vận tốc tối đa an toàn AGV"),
        ("Nhiễu (1)", "σ_xy / σ_θ", "0.06 m / 2.5°", "Nhiễu trắng Gaussian cảm biến UWB & IMU"),
        ("Nhiễu (2)", "Outlier Spikes", "±0.38 m; ±14° (4 lần)", "Nhiễu gai đột biến tại t = 7, 16, 24, 33 s"),
        ("Nhiễu (3)", "σ_enc / Bias R, L", "0.04 / +0.22, -0.16 rad/s", "Nhiễu xung và độ trôi Odometry Encoder"),
        ("Nhiễu (4)", "Wheel Slip", "Vùng t∈[9,15]s & [25,31]s", "Trượt dọc (-18% – -0.14 m/s) & trượt ngang")
    ]
    add_styled_table(doc, t31_headers, t31_rows,
                     "Bảng 3.1. Thông số vật lý Robot vi sai 2 bánh và cấu hình 4 loại nhiễu mô phỏng",
                     col_widths_cm=[2.8, 3.5, 4.2, 5.5])

    t32_headers = ["Thành phần", "Tham số", "Giá trị", "Ghi chú thiết kế"]
    t32_rows = [
        ("Bộ lọc EKF / KF", "Q_cov", "diag(4e-4, 4e-4, 2e-4)", "Hiệp phương sai nhiễu quá trình (Odometry)"),
        ("Bộ lọc EKF / KF", "R_cov", "diag(0.06², 0.06², 0.0436²)", "Hiệp phương sai nhiễu đo lường cảm biến"),
        ("EKF Gating", "Ngưỡng 3σ / R_adapt", "0.18 m / 25·R_cov", "Cơ chế phát hiện & giảm trọng số gai đột biến"),
        ("PID (EKF+PID)", "K_(p,v), K_(i,v), K_(d,v)", "2.80, 2.40, 0.15", "Kênh điều khiển vận tốc dài v_cmd"),
        ("PID (EKF+PID)", "K_(p,y), K_(i,y), K_(d,y)", "5.50, 2.80, 0.20", "Kênh điều khiển sai số lệch ngang e_y"),
        ("PID (EKF+PID)", "K_(p,ω), K_(i,ω), K_(d,ω)", "3.80, 2.10, 0.18", "Kênh điều khiển sai số góc hướng e_θ"),
        ("Lọc D & Windup", "α_d / I_max", "0.22 / ±1.2", "Lọc thông thấp khâu D & giới hạn tích phân")
    ]
    add_styled_table(doc, t32_headers, t32_rows,
                     "Bảng 3.2. Bộ tham số tinh chỉnh cho các bộ điều khiển P, PID và bộ lọc KF / EKF",
                     col_widths_cm=[3.2, 4.0, 4.2, 4.6])

    add_body(doc, "Nhằm tuân thủ nghiêm ngặt tính minh bạch học thuật, Bảng 3.3 phân tách rõ phần kiến thức/mô hình kế thừa từ tài liệu chính thống và phần do sinh viên tự thiết kế, lập trình và mở rộng:")
    t33_headers = ["Hạng mục", "Nội dung Kế thừa / Tham khảo", "Nội dung Tự thiết kế & Mở rộng"]
    t33_rows = [
        ("Mô hình Robot", "Động học xe vi sai 2 bánh từ MathWorks [1], [2] và giáo trình RVC3 Chương 3 [5].", "Mở rộng thêm quán tính cơ cấu chấp hành bậc 1 (τ_v, τ_ω) và thành phần trượt dọc/ngang v_(y,slip)."),
        ("Bộ lọc Kalman", "Nguyên lý đệ quy KF/EKF từ MathWorks [3], PythonRobotics [4] và giáo trình [5], [6].", "Tự cài đặt đối sánh trực tiếp Standard KF tuyến tính với EKF có cơ chế chống gai đột biến 3σ."),
        ("Bộ điều khiển PID", "Lý thuyết P, PI, PD, PID và lọc thông thấp khâu D từ RVC3 Chương 3 Part 2 [5].", "Thiết kế bộ PID bám quỹ đạo đa kênh trong hệ tọa độ thân xe {B} tích hợp Feedforward & Anti-windup."),
        ("Kịch bản & Simulink", "Bài toán bám đường thẳng RVC3 Section 3.1.4 [5].", "Xây dựng 3 kịch bản (Số 8 dưới 4 nhiễu, Đường thẳng có trượt ngang, Độ nhạy 50%–200%), dựng Simulink (.slx) & hoạt ảnh 2D.")
    ]
    add_styled_table(doc, t33_headers, t33_rows,
                     "Bảng 3.3. Phân biệt minh bạch phần kế thừa tham khảo và phần tự thiết kế, mở rộng",
                     col_widths_cm=[3.0, 6.2, 6.8])

    # =====================================================================
    # CHƯƠNG 4. KẾT QUẢ MÔ PHỎNG VÀ THẢO LUẬN
    # =====================================================================
    add_chapter_heading(doc, "CHƯƠNG 4. KẾT QUẢ MÔ PHỎNG VÀ THẢO LUẬN")

    add_h2(doc, "4.1. Kịch bản 1: Bám quỹ đạo hình số 8 dưới 4 loại nhiễu đồng thời")
    add_body(doc,
        "Trong Kịch bản 1, robot bám theo quỹ đạo cong liên tục hình số 8 (Lemniscate: x_r = 3.5·sin(ω_0·t), y_r = 2.2·sin(2ω_0·t) với chu kỳ 32 s) "
        "trong 40 s dưới tác động đồng thời của cả 4 loại nhiễu đã thiết lập ở Bảng 3.1. Quỹ đạo này có độ cong và vận tốc góc đổi dấu liên tục, "
        "tạo điều kiện thử thách khắt khe cho khả năng dự đoán phi tuyến của EKF so với KF tuyến tính. Kết quả quỹ đạo 2D, đáp ứng sai số theo thời gian "
        "và tín hiệu điều khiển được thể hiện lần lượt trên Hình 4.1, Hình 4.2 và Hình 4.3; các chỉ số định lượng được tổng hợp tại Bảng 4.1."
    )

    add_figure(doc, "fig1_trajectory_figure8.png",
               "Hình 4.1. Quỹ đạo 2D hình số 8 của 4 mô hình và phóng to khúc cua có trượt bánh & gai nhiễu.", width_inches=6.2)

    add_figure(doc, "fig2_tracking_errors.png",
               "Hình 4.2. Đáp ứng sai số bám vị trí Euclid ||e_p(t)||, sai số ngang e_y(t) và sai số góc e_θ(t).", width_inches=6.2)

    add_figure(doc, "fig3_control_inputs_and_slip.png",
               "Hình 4.3. Tín hiệu điều khiển (v, ω), hiệu quả lọc nhiễu KF vs. EKF và sự trôi Odometry.", width_inches=6.2)

    t41_headers = ["Mô hình Điều khiển & Lọc nhiễu", "RMSE_p (m)", "MAE_p (m)", "Max_p (m)", "RMSE_θ (°)", "IAE_p (m·s)", "TV_ω (rad/s)"]
    t41_rows = [
        ("1. Chỉ có PID (PID_Raw)", "0.1393", "0.1015", "0.3998", "5.2415", "3.7549", "36.11"),
        ("2. Chỉ có EKF (EKF + P)", "0.2159", "0.2013", "0.4526", "4.3802", "7.4488", "1.41"),
        ("3. Standard KF + PID", "0.1433", "0.1114", "0.4143", "7.0287", "4.1241", "3.08"),
        ("4. Extended KF + PID (Đề xuất)", "0.1253", "0.0920", "0.3648", "6.8902", "3.4049", "2.87")
    ]
    add_styled_table(doc, t41_headers, t41_rows,
                     "Bảng 4.1. Bảng tổng hợp 6 chỉ số đánh giá định lượng ở Kịch bản 1 (Quỹ đạo hình số 8)",
                     col_widths_cm=[4.9, 1.85, 1.8, 1.8, 1.85, 1.9, 1.9], bold_last_row=True)

    add_body(doc, "Từ kết quả định lượng ở Bảng 4.1 và các đồ thị Hình 4.1 – 4.3, có thể rút ra 4 nhận xét kỹ thuật quan trọng:", bold_prefix="Phân tích kết quả Kịch bản 1: ")
    add_bullet(doc, "Hạn chế của mô hình Chỉ có PID (PID_Raw): ", "Mặc dù khâu I giúp giữ RMSE_p ở mức 0.1393 m, nhưng do không có bộ lọc Kalman, nhiễu Gaussian và 4 xung gai đột biến đi thẳng vào khâu đạo hàm D khiến vận tốc góc ω_cmd (Hình 4.3b) dao động dữ dội, làm độ giật tín hiệu điều khiển TV_ω vọt lên tới 36.11 rad/s (gấp 12.6 lần phương pháp đề xuất). Trong thực tế, tín hiệu này sẽ nhanh chóng phá hỏng cơ cấu truyền động và gây tiêu hao năng lượng lớn.")
    add_bullet(doc, "Hạn chế của mô hình Chỉ có EKF (EKF + P): ", "Bộ lọc EKF giúp tín hiệu điều khiển rất mượt (TV_ω = 1.41 rad/s), nhưng vì bộ điều khiển P không có thành phần tích phân I nên khi gặp trượt bánh dọc và ngang, robot bị lệch tĩnh kéo dài suốt chu kỳ, đẩy RMSE_p lên cao nhất (0.2159 m) và IAE_p lên tới 7.4488 m·s.")
    add_bullet(doc, "Hạn chế của Standard KF + PID so với EKF + PID: ", "Ở Hình 4.3c, sai số ước lượng vị trí của Standard KF lớn hơn rõ rệt so với EKF và bị vọt lên tại các thời điểm có gai đột biến (7 s, 16 s, 24 s, 33 s) cũng như tại các khúc cua do mô hình dự đoán tuyến tính không cập nhật hàm lượng giác theo góc quay θ. Hệ quả là RMSE_p của KF + PID là 0.1433 m và Max_p là 0.4143 m.")
    add_bullet(doc, "Ưu thế toàn diện của phương pháp đề xuất (Extended KF + PID): ", "Đạt kết quả tốt nhất trên các chỉ số trọng yếu: RMSE_p = 0.1253 m (giảm 42.0% so với Chỉ EKF và giảm 12.6% so với Standard KF + PID), MAE_p = 0.0920 m, Max_p = 0.3648 m, IAE_p = 3.4049 m·s, đồng thời giảm 92.1% độ giật TV_ω so với Chỉ PID (từ 36.11 xuống 2.87 rad/s). Ngoài ra, Hình 4.3d cho thấy nếu chỉ dùng Encoder Odometry (không có EKF), độ trôi tích lũy sẽ tăng vọt theo thời gian.")

    add_h2(doc, "4.2. Kịch bản 2: Bám đường thẳng (RVC3) khi có trượt bánh ngang")
    add_body(doc,
        "Kịch bản 2 mở rộng trực tiếp bài toán Driving Along a Line (x - 2y + 4 = 0) trong giáo trình RVC3 (Chương 3, Mục 3.1.4 [5]). "
        "Robot xuất phát lệch phía dưới đường thẳng tại (1.0, 0.5) với tốc độ không đổi v = 1.0 m/s; từ thời điểm t = 8.0 s, sàn nhà xưởng "
        "xuất hiện trượt ngang liên tục v_(y,slip) = -0.14 m/s. Kết quả được thể hiện trên Hình 4.4."
    )
    add_figure(doc, "fig4_lane_change_rvc3.png",
               "Hình 4.4. Kịch bản 2 – Bám đường thẳng x - 2y + 4 = 0 (RVC3) khi có trượt bánh ngang từ t = 8 s.", width_inches=6.2)
    add_body(doc,
        "Hình 4.4b minh họa sắc nét cơ sở lý thuyết điều khiển PID: khi trượt ngang xuất hiện từ t = 8 s, mô hình Chỉ có EKF (EKF + P, đường nét gạch chấm màu cam) "
        "không thể kéo khoảng cách d(t) về 0 mà bị kẹt ở một sai số xác lập thường trực khoảng -0.20 m song song với đường chuẩn. Ngược lại, "
        "nhờ có thành phần tích phân I trong bộ điều khiển PID, mô hình đề xuất Extended KF + PID (đường xanh lá liền nét) tự động tích lũy góc bù lái "
        "và đưa sai số bám đường d(t) hội tụ chính xác về 0.00 m sau khoảng 4 s mà không bị dao động nhiễu như Chỉ có PID."
    )

    add_h2(doc, "4.3. Kịch bản 3: Phân tích độ nhạy theo cường độ nhiễu (50% – 200%)")
    add_body(doc,
        "Để kiểm chứng độ bền vững (Robustness) khi môi trường nhà xưởng trở nên khắc nghiệt hơn, Kịch bản 3 khảo sát đồng thời cả 4 mô hình "
        "khi tăng hệ số cường độ nhiễu (Gaussian, gai đột biến và nhiễu Encoder) từ 50% đến 200% so với cấu hình chuẩn. Biểu đồ so sánh cột ở "
        "mức chuẩn và đường cong độ nhạy được thể hiện trên Hình 4.5."
    )
    add_figure(doc, "fig5_robustness_bar_chart.png",
               "Hình 4.5. (a) Biểu đồ cột so sánh RMSE/MAE/Max Error và (b) Phân tích độ nhạy khi tăng nhiễu 50% – 200%.", width_inches=6.2)
    add_body(doc,
        "Đồ thị Hình 4.5b cho thấy đường cong sai số RMSE_p của Extended KF + PID (màu xanh lá) luôn nằm ở vị trí thấp nhất và có độ dốc tăng "
        "chậm nhất trên toàn dải cường độ nhiễu từ 50% đến 200%. Khi nhiễu tăng gấp đôi (200%), sai số của Chỉ có PID và Standard KF + PID tăng "
        "vọt mạnh do nhiễu gai vượt kiểm soát và sai lệch tuyến tính hóa, trong khi Extended KF + PID vẫn giữ quỹ đạo ổn định nhờ kết hợp cơ chế "
        "gating 3σ và bộ lọc thông thấp khâu D."
    )

    add_h2(doc, "4.4. Kiểm chứng trực tiếp trên mô hình Simulink")
    add_body(doc,
        "Nhằm trực quan hóa dòng tín hiệu và kiểm chứng chéo kết quả từ kịch bản MATLAB Script, mô hình vòng kín EKF + PID được xây dựng hoàn chỉnh "
        "trên Simulink (tệp sl_robust_mobile_robot.slx). Cụm phương trình động học Robot vi sai có trượt ngang được đóng gói gọn gàng thành một khối "
        "Subsystem duy nhất mang tên 'Differential Drive Robot Model' với 2 đầu vào (v, ω) và đầu ra trạng thái thực q_true = [x, y, θ]^T, tương tự "
        "phong cách mô hình hóa của sách RVC3 (Hình 4.6). Kết quả chạy mô phỏng trực tiếp bằng lệnh sim('sl_robust_mobile_robot') với bộ giải ode4 "
        "cho thấy robot hội tụ nhanh từ điểm lệch ban đầu và đạt RMSE = 0.1043 m (Hình 4.7), khẳng định tính nhất quán và đúng đắn của thiết kế."
    )
    add_figure(doc, "fig6_simulink_diagram.png",
               "Hình 4.6. Sơ đồ khối Simulink hoàn chỉnh (sl_robust_mobile_robot.slx) với khối Subsystem Robot Model.", width_inches=6.2)
    add_figure(doc, "fig7_simulink_verification.png",
               "Hình 4.7. Kết quả kiểm chứng quỹ đạo XY và sai số bám trực tiếp trên Simulink (RMSE = 0.1043 m).", width_inches=6.2)

    add_h2(doc, "4.5. Đánh giá ưu – nhược điểm và các hạn chế còn tồn tại")
    add_bullet(doc, "Ưu điểm: ", "Kiến trúc EKF + PID dễ hiểu, khối lượng tính toán thấp (chạy thời gian thực ở tần số 50 Hz dễ dàng trên vi điều khiển nhúng như STM32/ESP32 hoặc Raspberry Pi), giải quyết đồng thời 4 loại nhiễu thực tế và vượt trội rõ rệt so với cả 3 mô hình đối sánh.")
    add_bullet(doc, "Hạn chế còn tồn tại: ", "(1) Khi trượt bánh xảy ra quá đột ngột và lớn tại đỉnh khúc cua gắt (như lúc t = 14 s ở Hình 4.2a), khâu tích phân I của PID cần khoảng thời gian quá độ nhất định để tích lũy lực bù nên vẫn tồn tại đỉnh sai số tức thời Max_p = 0.3648 m; (2) Giá trị sai số góc RMSE_θ của EKF + PID (6.89°) hơi cao hơn EKF + P (4.38°) do robot chủ động xoay lệch mũi xe một góc nhỏ để chống lại thành phần trượt ngang (tương tự hiện tượng 'crabbing angle' khi xe đi trên mặt nghiêng); (3) Tham số Q, R và K_p, K_i, K_d hiện đang cố định, chưa tự thích nghi theo tải trọng thay đổi quá lớn.")

    # =====================================================================
    # CHƯƠNG 5. KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN
    # =====================================================================
    add_chapter_heading(doc, "CHƯƠNG 5. KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN")

    add_h2(doc, "5.1. Kết luận")
    add_body(doc,
        "Báo cáo đã hoàn thành đầy đủ các mục tiêu nghiên cứu đề ra cho Chủ đề 4 về điều khiển robot di động trong môi trường có nhiễu và bất định, "
        "cụ thể hóa cho bài toán Robot AGV vi sai 2 bánh trong nhà xưởng công nghiệp. Các kết quả kỹ thuật chính đạt được bao gồm:"
    )
    add_bullet(doc, "Xây dựng hoàn chỉnh môi trường mô phỏng 4 loại nhiễu thực tế: ", "Bao gồm nhiễu cảm biến Gaussian, nhiễu gai đột biến (Outliers), nhiễu Encoder kèm trôi Odometry và trượt bánh dọc/ngang trên nền tảng MATLAB R2024a và Simulink.")
    add_bullet(doc, "Chứng minh hiệu quả vượt trội của kiến trúc đề xuất EKF + PID: ", "Qua đối sánh định lượng với 3 mô hình cơ sở (Chỉ PID, Chỉ EKF, Standard KF + PID) trên 3 kịch bản, giải pháp EKF (có gating 3σ) kết hợp PID (Filtered D + Anti-windup) đạt độ chính xác tốt nhất (RMSE_p = 0.1253 m, giảm 42.0% so với Chỉ EKF), giảm 92.1% độ giật tín hiệu điều khiển TV_ω so với Chỉ PID, vượt trội Standard KF trên quỹ đạo cong và triệt tiêu hoàn toàn sai số tĩnh khi bám đường thẳng có trượt ngang.")
    add_bullet(doc, "Đóng gói sản phẩm mở dễ tái lập: ", "Toàn bộ mã nguồn MATLAB, sơ đồ Simulink (.slx), hoạt ảnh 2D và dữ liệu kết quả đã được công khai có hướng dẫn chi tiết trên kho GitHub phục vụ kiểm chứng.")

    add_h2(doc, "5.2. Hướng phát triển")
    add_bullet(doc, "Tích hợp bộ điều khiển dự báo mô hình (MPC) hoặc điều khiển thích nghi: ", "Để xử lý trực tiếp các ràng buộc vật lý và giảm đỉnh sai số Max_p tại các vùng trượt bánh cực mạnh.")
    add_bullet(doc, "Mở rộng ước lượng hệ số trượt trực tuyến (Augmented EKF): ", "Đưa thêm vận tốc trượt ngang v_(y,slip) vào vector trạng thái của EKF để ước lượng và bù tiến trực tiếp thành phần trượt ngay khi vừa xuất hiện.")
    add_bullet(doc, "Triển khai thử nghiệm trên phần cứng thực tế / ROS 2 & Gazebo: ", "Đưa thuật toán EKF + PID lên nền tảng robot thực (như TurtleBot3 hoặc AGV tự chế dùng LiDAR + IMU + Encoder) chạy trên ROS 2 để kiểm chứng trong môi trường kho xưởng thực.")

    # =====================================================================
    # TÀI LIỆU THAM KHẢO (CHUẨN IEEE)
    # =====================================================================
    add_chapter_heading(doc, "TÀI LIỆU THAM KHẢO")
    refs = [
        '[1] MathWorks, "Path Following for a Differential Drive Robot," MATLAB Documentation. [Online]. Available: https://www.mathworks.com/help/robotics/examples/path-following-for-a-differential-drive-robot.html. Accessed: 18-Nov-2026.',
        '[2] MathWorks, "differentialDriveKinematics - Differential-drive vehicle kinematic model," MATLAB Documentation. [Online]. Available: https://www.mathworks.com/help/robotics/ref/differentialdrivekinematics.html. Accessed: 18-Nov-2026.',
        '[3] MathWorks, "Localization Algorithms in Navigation Toolbox," MATLAB Documentation. [Online]. Available: https://www.mathworks.com/help/nav/localization-algorithms.html. Accessed: 18-Nov-2026.',
        '[4] A. Sakai et al., "PythonRobotics: Extended Kalman Filter Localization," GitHub repository. [Online]. Available: https://github.com/AtsushiSakai/PythonRobotics/blob/master/Localization/extended_kalman_filter/extended_kalman_filter.py. Accessed: 18-Nov-2026.',
        '[5] P. Corke, Robotics, Vision and Control: Fundamental Algorithms in MATLAB, 3rd ed. Cham, Switzerland: Springer, 2023.',
        '[6] A. Becker, Kalman Filter from the Ground Up, 2023.'
    ]
    for r_txt in refs:
        p = doc.add_paragraph()
        style_paragraph(p, align=WD_ALIGN_PARAGRAPH.JUSTIFY, space_after=6, line_spacing=1.3, first_line=0.0)
        p.paragraph_format.left_indent = Cm(0.8)
        p.paragraph_format.first_line_indent = Cm(-0.8)
        rn = p.add_run(r_txt)
        rn.font.name = 'Times New Roman'
        rn.font.size = Pt(12.5)

    # =====================================================================
    # PHỤ LỤC
    # =====================================================================
    add_chapter_heading(doc, "PHỤ LỤC: MÃ NGUỒN, HƯỚNG DẪN CHẠY VÀ MINH BẠCH AI")
    add_h2(doc, "A.1. Kho mã nguồn và Tệp sản phẩm mô phỏng")
    add_body(doc, "Toàn bộ mã nguồn MATLAB, mô hình Simulink, tập lệnh tạo đồ thị và dữ liệu kết quả được lưu trữ công khai tại kho GitHub:", indent=False)
    add_body(doc, "https://github.com/HuynhMinhThuan1310/robot-22ktmt1", bold_prefix="Địa chỉ kho mã nguồn: ", indent=False)
    add_bullet(doc, "run_all_simulations.m: ", "Kịch bản MATLAB chính chạy đủ 3 kịch bản, in bảng 6 chỉ số định lượng, xuất 5 đồ thị PNG (300 DPI) và mở hoạt ảnh 2D chuyển động của 3 xe Robot.")
    add_bullet(doc, "build_simulink_model.m & sl_robust_mobile_robot.slx: ", "Tập lệnh tự động dựng, chạy kiểm chứng và tệp sơ đồ khối Simulink hoàn chỉnh (kiến trúc EKF + PID với Subsystem Differential Drive Robot Model).")
    add_bullet(doc, "results/simulation_metrics_table.csv: ", "Bảng dữ liệu kết quả định lượng trích xuất tự động từ MATLAB.")

    add_h2(doc, "A.2. Hướng dẫn chạy kiểm chứng trên MATLAB R2024a")
    add_bullet(doc, "Bước 1: ", "Tải (clone) kho mã nguồn về máy và mở thư mục dự án trong Current Folder của MATLAB R2024a.")
    add_bullet(doc, "Bước 2: ", "Gõ lệnh 'run_all_simulations' vào Command Window rồi nhấn Enter để xem bảng kết quả, 5 đồ thị phân tích và hoạt ảnh 2D xe chạy.")
    add_bullet(doc, "Bước 3: ", "Gõ lệnh 'build_simulink_model' (hoặc nhấp đúp sl_robust_mobile_robot.slx rồi bấm Run) để chạy kiểm chứng trên Simulink.")

    add_h2(doc, "A.3. Tuyên bố minh bạch về việc sử dụng công cụ AI")
    add_body(doc,
        "Trong quá trình thực hiện đề tài, sinh viên có sử dụng công cụ hỗ trợ AI ở vai trò trợ lý kỹ thuật nhằm hỗ trợ cấu trúc hóa mã nguồn "
        "MATLAB/Simulink, tạo kịch bản xuất đồ thị chuẩn hóa và rà soát trình bày báo cáo. Toàn bộ việc xác định bài toán, lựa chọn 4 loại nhiễu, "
        "thiết kế 4 mô hình đối sánh (Chỉ PID, Chỉ EKF, Standard KF + PID, Extended KF + PID), tinh chỉnh thông số, trực tiếp chạy kiểm chứng trên "
        "MATLAB R2024a/Simulink và kiểm tra tính đúng đắn của từng công thức, bảng số liệu đều do sinh viên chủ động thực hiện và chịu hoàn toàn trách nhiệm."
    )

    doc.save(OUT_DOCX)
    print(f"REPORT_SAVED: {OUT_DOCX}")


if __name__ == '__main__':
    build_report()
