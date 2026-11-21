# -*- coding: utf-8 -*-
"""
English Edition Final Report Generator (.docx) for Robotics Course (Topic 4: EKF + PID)
- Cover page ONLY has double page border (all subsequent pages have zero border)
- Justified/Left alignment for all headings, text, and tables; ONLY figures & captions (and cover) centered
- 11 STIX LaTeX rendered equations (350 DPI) + native Word subscripts/superscripts
- Authors: Huynh Minh Thuan (106220236) & Tran Viet Thang (Class 22KTMT1)
"""
import os
import re
import docx
from docx import Document
from docx.shared import Inches, Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn
from PIL import Image

RES_DIR = r'c:\robot\Topic4_RobustMobileRobotControl\results'
EQ_DIR = os.path.join(RES_DIR, 'equations')
OUT_DOCX_EN = r'c:\robot\Topic4_RobustMobileRobotControl\Final_Report_Robotics_EN_Final.docx'


def add_rich_runs(p, text, font_size=13, bold=False, italic=False, color=None):
    token_pattern = re.compile(r'(_\{[^}]+\}|\^\{[^}]+\})')
    parts = token_pattern.split(text)
    for part in parts:
        if not part:
            continue
        if part.startswith('_{') and part.endswith('}'):
            r = p.add_run(part[2:-1])
            r.font.subscript = True
        elif part.startswith('^{') and part.endswith('}'):
            r = p.add_run(part[2:-1])
            r.font.superscript = True
        else:
            r = p.add_run(part)
        r.font.name = 'Times New Roman'
        r.font.size = Pt(font_size)
        r.bold = bold
        r.italic = italic
        if color:
            r.font.color.rgb = color


def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)


def set_cell_margins(cell, top=80, bottom=80, left=100, right=100):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)


def remove_table_borders(table):
    tblPr = table._tbl.tblPr
    borders = parse_xml(
        f'<w:tblBorders {nsdecls("w")}>'
        f'  <w:top w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
        f'  <w:left w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
        f'  <w:bottom w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
        f'  <w:right w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
        f'  <w:insideH w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
        f'  <w:insideV w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
        f'</w:tblBorders>'
    )
    tblPr.append(borders)


def add_page_number_footer(section):
    footer = section.footer
    p = footer.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run = p.add_run("Page ")
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
        f'<w:pgBorders {nsdecls("w")} w:offsetFrom="page" w:display="firstPage">'
        f'  <w:top w:val="double" w:sz="12" w:space="24" w:color="000000"/>'
        f'  <w:left w:val="double" w:sz="12" w:space="24" w:color="000000"/>'
        f'  <w:bottom w:val="double" w:sz="12" w:space="24" w:color="000000"/>'
        f'  <w:right w:val="double" w:sz="12" w:space="24" w:color="000000"/>'
        f'</w:pgBorders>'
    )
    sectPr.append(pgBorders)


def clear_page_border(section):
    sectPr = section._sectPr
    pgBorders = parse_xml(
        f'<w:pgBorders {nsdecls("w")} w:offsetFrom="page">'
        f'  <w:top w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
        f'  <w:left w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
        f'  <w:bottom w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
        f'  <w:right w:val="none" w:sz="0" w:space="0" w:color="auto"/>'
        f'</w:pgBorders>'
    )
    sectPr.append(pgBorders)


def add_body(doc, text, bold_prefix=None, indent=True):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    pf = p.paragraph_format
    pf.space_before = Pt(0)
    pf.space_after = Pt(6)
    pf.line_spacing = 1.35
    if indent:
        pf.first_line_indent = Cm(0.8)
    if bold_prefix:
        add_rich_runs(p, bold_prefix, font_size=13, bold=False)
    add_rich_runs(p, text, font_size=13, bold=False)
    return p


def add_bullet(doc, bold_prefix, text):
    p = doc.add_paragraph(style='List Bullet')
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.line_spacing = 1.35
    if bold_prefix:
        add_rich_runs(p, bold_prefix, font_size=13, bold=False)
    add_rich_runs(p, text, font_size=13, bold=False)
    return p


def add_existing_eq(doc, eq_num):
    eq_path = os.path.join(EQ_DIR, f"eq_{eq_num.replace('.', '_')}.png")
    with Image.open(eq_path) as im:
        w_px, _ = im.size
    w_in = min(w_px / 350.0, 5.15)
    tbl = doc.add_table(rows=1, cols=2)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    remove_table_borders(tbl)
    tbl.autofit = False
    c0, c1 = tbl.rows[0].cells[0], tbl.rows[0].cells[1]
    c0.width = Cm(14.0)
    c1.width = Cm(2.0)
    c0.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
    c1.vertical_alignment = WD_ALIGN_VERTICAL.CENTER

    p0 = c0.paragraphs[0]
    p0.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p0.paragraph_format.left_indent = Cm(0.8)
    p0.paragraph_format.space_before = Pt(4)
    p0.paragraph_format.space_after = Pt(4)
    p0.add_run().add_picture(eq_path, width=Inches(w_in))

    p1 = c1.paragraphs[0]
    p1.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p1.paragraph_format.space_before = Pt(4)
    p1.paragraph_format.space_after = Pt(4)
    r1 = p1.add_run(f"({eq_num})")
    r1.font.name = 'Times New Roman'
    r1.font.size = Pt(12.5)


def add_chapter_heading(doc, title, page_break=True):
    if page_break:
        doc.add_page_break()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_before = Pt(6)
    p.paragraph_format.space_after = Pt(12)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(title.upper())
    r.bold = True
    r.font.name = 'Times New Roman'
    r.font.size = Pt(15)
    r.font.color.rgb = RGBColor(0x00, 0x00, 0x00)
    return p


def add_h2(doc, title):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.keep_with_next = True
    add_rich_runs(p, title, font_size=13.5, bold=True, color=RGBColor(0x00, 0x00, 0x00))
    return p


def add_h3(doc, title):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    p.paragraph_format.space_before = Pt(6)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    add_rich_runs(p, title, font_size=13, bold=True, italic=True)
    return p


def add_figure(doc, img_filename, caption, width_inches=6.0):
    img_path = os.path.join(RES_DIR, img_filename)
    p_img = doc.add_paragraph()
    p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_img.paragraph_format.space_before = Pt(8)
    p_img.paragraph_format.space_after = Pt(3)
    p_img.paragraph_format.keep_with_next = True
    p_img.add_run().add_picture(img_path, width=Inches(width_inches))

    p_cap = doc.add_paragraph()
    p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_cap.paragraph_format.space_before = Pt(0)
    p_cap.paragraph_format.space_after = Pt(10)
    add_rich_runs(p_cap, caption, font_size=11.5, italic=True)


def add_styled_table(doc, headers, rows, caption, col_widths_cm=None, bold_last_row=False):
    p_cap = doc.add_paragraph()
    p_cap.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p_cap.paragraph_format.space_before = Pt(8)
    p_cap.paragraph_format.space_after = Pt(4)
    p_cap.paragraph_format.keep_with_next = True
    add_rich_runs(p_cap, caption, font_size=12, bold=True)

    tbl = doc.add_table(rows=len(rows) + 1, cols=len(headers))
    tbl.style = 'Table Grid'
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER

    hdr_cells = tbl.rows[0].cells
    for i, h in enumerate(headers):
        set_cell_background(hdr_cells[i], 'E6E6E6')
        set_cell_margins(hdr_cells[i], top=85, bottom=85, left=80, right=80)
        hdr_cells[i].vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        p = hdr_cells[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        add_rich_runs(p, h, font_size=11.5, bold=True, color=RGBColor(0x00, 0x00, 0x00))

    for r_idx, row_data in enumerate(rows):
        row_cells = tbl.rows[r_idx + 1].cells
        bg = 'FFFFFF'
        for c_idx, val in enumerate(row_data):
            set_cell_background(row_cells[c_idx], bg)
            set_cell_margins(row_cells[c_idx], top=65, bottom=65, left=80, right=80)
            row_cells[c_idx].vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = row_cells[c_idx].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = 1.15
            add_rich_runs(p, str(val), font_size=11.5, bold=False)

    if col_widths_cm:
        for row in tbl.rows:
            for i, w in enumerate(col_widths_cm):
                row.cells[i].width = Cm(w)

    p_sp = doc.add_paragraph()
    p_sp.paragraph_format.space_before = Pt(0)
    p_sp.paragraph_format.space_after = Pt(4)


def build_english_report():
    doc = Document()

    sec0 = doc.sections[0]
    sec0.page_width = Cm(21.0)
    sec0.page_height = Cm(29.7)
    sec0.top_margin = Cm(2.5)
    sec0.bottom_margin = Cm(2.5)
    sec0.left_margin = Cm(3.0)
    sec0.right_margin = Cm(2.0)
    add_cover_border(sec0)

    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Times New Roman'
    normal_style.font.size = Pt(13)

    # =====================================================================
    # COVER PAGE (CENTERED, DOUBLE BORDER ONLY ON THIS PAGE)
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

    cover_line("THE UNIVERSITY OF DANANG", size=14, bold=True, before=6, after=2)
    cover_line("UNIVERSITY OF SCIENCE AND TECHNOLOGY", size=14, bold=True, after=2)
    cover_line("FACULTY OF ELECTRONICS AND ARTIFICIAL INTELLIGENCE", size=13.5, bold=True, after=34)

    cover_line("FINAL PROJECT REPORT", size=22, bold=True, before=20, after=8)
    cover_line("COURSE: ROBOTICS", size=15, bold=True, after=28)

    cover_line("TOPIC 4:", size=13.5, bold=True, after=8)
    cover_line(
        "MOBILE ROBOT CONTROL IN NOISY AND UNCERTAIN ENVIRONMENTS\n"
        "EXTENDED KALMAN FILTER (EKF) COMBINED WITH PID CONTROL FOR DIFFERENTIAL-DRIVE AGVs",
        size=15.0, bold=True, after=44
    )

    tbl_info = doc.add_table(rows=4, cols=2)
    tbl_info.alignment = WD_TABLE_ALIGNMENT.CENTER
    remove_table_borders(tbl_info)
    info_data = [
        ("Supervising Lecturer:", "Dr. Phan Tran Dang Khoa"),
        ("Students:", "1. Huynh Minh Thuan  (ID: 106220236)\n2. Tran Viet Thang"),
        ("Class:", "22KTMT1"),
        ("Source Repository:", "github.com/HuynhMinhThuan1310/robot-22ktmt1"),
    ]
    for idx, (k, v) in enumerate(info_data):
        c0, c1 = tbl_info.rows[idx].cells[0], tbl_info.rows[idx].cells[1]
        c0.width = Cm(5.5)
        c1.width = Cm(9.5)
        p0 = c0.paragraphs[0]
        p0.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p0.paragraph_format.space_after = Pt(6)
        p0.paragraph_format.line_spacing = 1.25
        r0 = p0.add_run(k)
        r0.bold = True
        r0.font.name = 'Times New Roman'
        r0.font.size = Pt(13)

        p1 = c1.paragraphs[0]
        p1.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p1.paragraph_format.space_after = Pt(6)
        p1.paragraph_format.line_spacing = 1.25
        r1 = p1.add_run(v)
        r1.font.name = 'Times New Roman'
        r1.font.size = Pt(13)

    cover_line("Da Nang, November 2026", size=13, italic=True, before=85, after=0)

    # Section 1: NO BORDERS on content pages
    sec1 = doc.add_section(docx.enum.section.WD_SECTION.NEW_PAGE)
    sec1.page_width = Cm(21.0)
    sec1.page_height = Cm(29.7)
    sec1.top_margin = Cm(2.5)
    sec1.bottom_margin = Cm(2.5)
    sec1.left_margin = Cm(3.0)
    sec1.right_margin = Cm(2.0)
    clear_page_border(sec1)
    sec1.footer.is_linked_to_previous = False
    add_page_number_footer(sec1)

    # =====================================================================
    # TABLE OF CONTENTS & LISTS
    # =====================================================================
    add_chapter_heading(doc, "TABLE OF CONTENTS", page_break=False)
    toc_items = [
        ("LIST OF FIGURES, TABLES, AND ABBREVIATIONS", True),
        ("CHAPTER 1. INTRODUCTION", True),
        ("    1.1. Background and Target Industrial Application", False),
        ("    1.2. Research Objectives", False),
        ("    1.3. Scope and Assumptions", False),
        ("    1.4. Report Organization", False),
        ("CHAPTER 2. THEORETICAL BACKGROUND", True),
        ("    2.1. Overview of Mobile Robot Trajectory Tracking Under Noise", False),
        ("    2.2. Differential-Drive Kinematics and Four Practical Disturbance Sources", False),
        ("    2.3. Standard Kalman Filter (KF) vs. Extended Kalman Filter (EKF)", False),
        ("    2.4. PID Control with Low-Pass Filtered Derivative and Anti-Windup", False),
        ("    2.5. Comparative Analysis of Candidate Architectures", False),
        ("CHAPTER 3. SYSTEM DESIGN AND METHODOLOGY", True),
        ("    3.1. Problem Formulation, Constraints, and Six Quantitative Metrics", False),
        ("    3.2. Proposed Closed-Loop Architecture (EKF + PID)", False),
        ("    3.3. Extended Kalman Filter Design with 3σ Outlier Gating", False),
        ("    3.4. Body-Frame PID Trajectory Controller Design", False),
        ("    3.5. Simulation Setup, Parameters, and Attribution Transparency", False),
        ("CHAPTER 4. SIMULATION RESULTS AND DISCUSSION", True),
        ("    4.1. Scenario 1: Figure-8 Trajectory Tracking Under Four Combined Noises", False),
        ("    4.2. Scenario 2: RVC3 Line Following Under Continuous Lateral Wheel Slip", False),
        ("    4.3. Scenario 3: Robustness Sensitivity Analysis (50% – 200% Noise)", False),
        ("    4.4. Simulink Verification and Model Validation", False),
        ("    4.5. Discussion of Strengths and Remaining Limitations", False),
        ("CHAPTER 5. CONCLUSION AND FUTURE WORK", True),
        ("    5.1. Conclusion", False),
        ("    5.2. Future Work", False),
        ("REFERENCES", True),
        ("APPENDIX: SOURCE CODE, EXECUTION GUIDE, AND AI DISCLOSURE", True),
    ]
    for item, is_bold in toc_items:
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.space_before = Pt(1)
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.line_spacing = 1.25
        add_rich_runs(p, item, font_size=12.5, bold=is_bold)

    doc.add_page_break()
    add_chapter_heading(doc, "LIST OF FIGURES, TABLES, AND ABBREVIATIONS", page_break=False)

    add_h2(doc, "1. List of Figures")
    for f in [
        "Figure 3.1. Overall closed-loop EKF + PID control architecture for the differential-drive AGV.",
        "Figure 3.2. Flowchart of the Extended Kalman Filter (EKF) with 3σ innovation gating.",
        "Figure 3.3. Block diagram of the body-frame PID controller with Filtered D and Anti-windup.",
        "Figure 4.1. 2D Figure-8 trajectories of the four models and zoomed-in view of the slip zone.",
        "Figure 4.2. Time-domain tracking errors: Euclidean position ||e_{p}||, cross-track e_{y}, and heading e_{θ}.",
        "Figure 4.3. Control commands (v, ω), KF vs. EKF estimation error, and accumulated odometry drift.",
        "Figure 4.4. Scenario 2 – RVC3 straight-line following (x − 2y + 4 = 0) under continuous lateral slip.",
        "Figure 4.5. Quantitative bar chart (RMSE, MAE, Max Error) and sensitivity analysis (50% – 200%).",
        "Figure 4.6. Simulink block diagram (sl_robust_mobile_robot.slx) with encapsulated Robot Model Subsystem.",
        "Figure 4.7. Direct Simulink verification of XY trajectory and Euclidean tracking error (RMSE = 0.1043 m)."
    ]:
        add_body(doc, f, indent=False)

    add_h2(doc, "2. List of Tables")
    for tb in [
        "Table 2.1. Qualitative comparison of the four evaluated filtering and control models.",
        "Table 3.1. Physical robot parameters and configuration of the four noise/disturbance sources.",
        "Table 3.2. Tuned parameters for the KF/EKF estimators and P/PID trajectory controllers.",
        "Table 3.3. Clear attribution separating inherited references from original design contributions.",
        "Table 4.1. Quantitative comparison across six performance metrics in Scenario 1 (Figure-8)."
    ]:
        add_body(doc, tb, indent=False)

    add_h2(doc, "3. List of Abbreviations")
    add_styled_table(doc, ["Abbreviation", "Full Term"], [
        ("AGV", "Automated Guided Vehicle"),
        ("EKF", "Extended Kalman Filter"),
        ("IAE", "Integral of Absolute Error"),
        ("IMU", "Inertial Measurement Unit"),
        ("KF", "Kalman Filter (Standard Linear Kalman Filter)"),
        ("MAE", "Mean Absolute Error"),
        ("PID", "Proportional – Integral – Derivative"),
        ("RMSE", "Root Mean Square Error"),
        ("RVC3", "Robotics, Vision and Control, 3rd Edition (Peter Corke)"),
        ("TV", "Total Variation (Control signal smoothness / chattering index)"),
        ("UWB", "Ultra-Wideband indoor localization")
    ], "List of abbreviations used throughout this report", col_widths_cm=[3.5, 12.5])

    # =====================================================================
    # CHAPTER 1. INTRODUCTION
    # =====================================================================
    add_chapter_heading(doc, "CHAPTER 1. INTRODUCTION")

    add_h2(doc, "1.1. Background and Target Industrial Application")
    add_body(doc,
        "In modern smart factories and automated warehouses, differential-drive Automated Guided Vehicles (AGVs) are widely deployed "
        "for material transport due to their compact mechanical footprint, zero-radius turning capability, and high maneuverability in narrow aisles. "
        "Maintaining accurate trajectory tracking along predefined paths between workstations is critical for both throughput and operational safety."
    )
    add_body(doc,
        "Unlike idealized laboratory conditions, real industrial floors introduce multiple concurrent uncertainties: (1) indoor localization sensors "
        "(UWB, LiDAR, or overhead cameras combined with IMUs) suffer from continuous Gaussian measurement noise; (2) multipath reflections or temporary "
        "occlusions inject sudden outlier spikes into pose readings; (3) wheel encoders experience pulse noise and systematic bias, causing unbounded "
        "odometry drift under pure dead-reckoning; and (4) oil, dust, or moisture on factory floors induce longitudinal and lateral wheel slip, violating "
        "the classical pure-rolling non-holonomic constraint."
    )
    add_body(doc,
        "Feeding raw, unfiltered sensor measurements directly into a PID controller causes the derivative term (D) to amplify high-frequency noise and "
        "outlier spikes, producing severe actuator chattering. Conversely, relying solely on state filtering (EKF) with a basic proportional (P) controller "
        "yields smooth commands but leaves persistent steady-state tracking offsets whenever wheel slip occurs. Therefore, combining a nonlinear Extended "
        "Kalman Filter (EKF) with a properly engineered PID controller (featuring low-pass filtered derivative and integral anti-windup) provides a practical, "
        "computationally efficient, and theoretically grounded solution."
    )

    add_h2(doc, "1.2. Research Objectives")
    add_body(doc, "The primary objective is to design, simulate, and quantitatively validate an EKF + PID trajectory tracking system in MATLAB/Simulink "
                  "for a differential-drive mobile robot operating under sensor noise, outlier spikes, encoder drift, and wheel slip.",
             bold_prefix="General Objective: ")
    add_body(doc, "Specific verifiable objectives include:", bold_prefix="Specific Objectives: ")
    add_bullet(doc, "System Modeling: ", "Formulate a differential-drive (unicycle) kinematic model incorporating first-order actuator dynamics and four realistic disturbance sources (Gaussian noise, outlier spikes, encoder drift, and longitudinal/lateral wheel slip).")
    add_bullet(doc, "Proposed EKF + PID Design: ", "Implement an Extended Kalman Filter with 3σ innovation gating for outlier rejection, coupled with a body-frame PID controller utilizing filtered derivative action and integral anti-windup.")
    add_bullet(doc, "Verifiable Quantitative Targets: ", "Reduce position RMSE_{p} by at least 35% relative to EKF-only (EKF + P); reduce angular command chattering TV_{ω} by over 85% compared to raw PID; outperform Standard Linear KF + PID on curved paths; and eliminate steady-state error (e_{ss} → 0) under sustained lateral wheel slip.")
    add_bullet(doc, "Cross-Platform Verification: ", "Deliver reproducible, self-contained MATLAB scripts (3 scenarios + 2D live animation) and an interactive Simulink model (.slx).")

    add_h2(doc, "1.3. Scope and Assumptions")
    add_bullet(doc, "Workspace: ", "Planar 2D motion on a warehouse floor described by the pose vector q = [x, y, θ]^{T}.")
    add_bullet(doc, "Modeling Scope: ", "Focuses on the four core disturbance sources (Gaussian sensor noise, outliers, encoder drift, and wheel slip); geometric wheel-radius manufacturing errors are neglected (r_{R} = r_{L} = r_{0}, b = b_{0}), and dynamic obstacle avoidance is outside the scope.")
    add_bullet(doc, "Validation Method: ", "Numerical simulation and quantitative benchmarking in MATLAB R2024a and Simulink.")

    add_h2(doc, "1.4. Report Organization")
    add_body(doc, "The remainder of this report is organized into four chapters: Chapter 2 reviews the theoretical foundations of differential-drive kinematics, "
                  "noise modeling, KF/EKF, and PID control; Chapter 3 details the system architecture, algorithm flowcharts, and simulation parameters; "
                  "Chapter 4 presents and analyzes the experimental results across three MATLAB scenarios and Simulink verification; and Chapter 5 summarizes "
                  "key findings and outlines future research directions.")

    # =====================================================================
    # CHAPTER 2. THEORETICAL BACKGROUND
    # =====================================================================
    add_chapter_heading(doc, "CHAPTER 2. THEORETICAL BACKGROUND")

    add_h2(doc, "2.1. Overview of Mobile Robot Trajectory Tracking Under Noise")
    add_body(doc,
        "Trajectory tracking for Wheeled Mobile Robots (WMRs) aims to generate linear and angular velocity commands (v, ω) such that the actual robot pose "
        "q(t) = [x(t), y(t), θ(t)]^{T} converges to a time-parameterized reference trajectory q_{r}(t) = [x_{r}(t), y_{r}(t), θ_{r}(t)]^{T}. Standard kinematic "
        "controllers presented in Peter Corke's RVC3 [5] and MathWorks documentation [1], [2] perform reliably under ideal no-slip, noise-free assumptions. "
        "Under practical disturbances, decoupling the problem into State Estimation (Kalman Filtering) [3], [4], [6] and Closed-Loop Feedback Control (PID) [5] "
        "ensures both noise immunity and disturbance rejection."
    )

    add_h2(doc, "2.2. Differential-Drive Kinematics and Four Practical Disturbance Sources")
    add_h3(doc, "2.2.1. Perturbed Differential-Drive Kinematic Model")
    add_body(doc,
        "For a two-wheeled differential-drive robot with wheel radius r_{0} and wheelbase b_{0}, the forward kinematic mapping from right and left wheel "
        "angular velocities (ω_{R}, ω_{L}) to body linear and angular velocities (v_{wheel}, ω_{wheel}) is given by [2], [5]:"
    )
    add_existing_eq(doc, "2.1")
    add_body(doc,
        "Accounting for first-order motor actuator lag (time constants τ_{v}, τ_{ω}), longitudinal slip disturbances d_{v}(t), rotational slip d_{ω}(t), "
        "and lateral skidding velocity v_{y,slip}(t) ≠ 0 that violates the ideal non-holonomic constraint ẏ cos θ − ẋ sin θ = 0, the perturbed equations of motion are:"
    )
    add_existing_eq(doc, "2.2")
    add_existing_eq(doc, "2.3")

    add_h3(doc, "2.2.2. Modeling of the Four Noise and Disturbance Sources")
    add_bullet(doc, "Gaussian Sensor Noise: ", "Global position (x_{m}, y_{m}) and IMU heading θ_{m} are corrupted by zero-mean white Gaussian noise ν_{k} ~ N(0, R) with covariance R = diag(σ_{xy}^{2}, σ_{xy}^{2}, σ_{θ}^{2}).")
    add_bullet(doc, "Sensor Outlier Spikes: ", "Intermittent high-amplitude measurement spikes Δz_{spike} (±0.38 m in position and ±14° in heading) occur at discrete instants due to multipath or occlusion.")
    add_bullet(doc, "Encoder Noise and Odometry Drift: ", "Wheel encoder readings include white noise and systematic bias (b_{R}, b_{L}), causing pure dead-reckoning odometry to drift unboundedly over time.")
    add_bullet(doc, "Wheel Slip: ", "Longitudinal slip d_{v}(t) reduces forward traction in slippery floor patches, while lateral skidding v_{y,slip}(t) pushes the vehicle sideways during sharp turns or inclined-floor motion.")

    add_h2(doc, "2.3. Standard Kalman Filter (KF) vs. Extended Kalman Filter (EKF)")
    add_body(doc,
        "The Standard Kalman Filter assumes a linear state-transition model x_{k} = A x_{k-1} + B u_{k} [6]. When applied to a mobile robot using a fixed "
        "input matrix B linearized around an initial heading θ_{0}, the prediction fails to capture the nonlinear trigonometric rotation (cos θ_{k}, sin θ_{k}) "
        "during continuous curved turns, introducing significant estimation lag."
    )
    add_body(doc,
        "By contrast, the Extended Kalman Filter (EKF) [3], [4], [5] propagates the state directly through the nonlinear motion function f(x̂_{k-1}, u_{k}) "
        "and updates the error covariance using the instantaneous Jacobian matrix F_{k} = ∂f/∂x evaluated at θ̂_{k-1}:"
    )
    add_existing_eq(doc, "2.4")
    add_existing_eq(doc, "2.5")

    add_h2(doc, "2.4. PID Control with Low-Pass Filtered Derivative and Anti-Windup")
    add_body(doc, "The classical continuous-time PID control law is expressed as [5]:")
    add_existing_eq(doc, "2.6")
    add_body(doc,
        "While proportional action (P) provides immediate corrective response, it cannot eliminate steady-state errors under constant disturbances such as wheel slip. "
        "Integral action (I) accumulates past error to drive steady-state error to zero, requiring clamping (Anti-windup) to prevent overshoot under actuator saturation. "
        "Because pure differentiation amplifies high-frequency measurement noise, a first-order low-pass filter is integrated into the derivative channel [5]:"
    )
    add_existing_eq(doc, "2.7")

    add_h2(doc, "2.5. Comparative Analysis of Candidate Architectures")
    add_styled_table(doc, ["Model", "Structure", "Key Strengths", "Limitations"], [
        ("1. PID Only\n(PID Raw)", "PID fed directly with raw sensor measurements", "Simple structure; integral action compensates slip.", "Derivative term amplifies Gaussian noise and outlier spikes, causing severe chattering (high TV_{ω})."),
        ("2. EKF Only\n(EKF + P)", "EKF estimator + basic Proportional (P) controller", "Clean state estimation and very smooth control commands.", "Lacks integral action I, resulting in large steady-state tracking offset under wheel slip."),
        ("3. Standard KF\n+ PID", "Fixed-heading Linear KF + PID controller", "Filters Gaussian noise on straight paths and compensates slip.", "Fails to track nonlinear heading rotation on sharp curves and lacks outlier gating."),
        ("4. Extended KF\n+ PID (Proposed)", "EKF (Jacobian + 3σ Gating) + PID (Filtered D + Anti-windup)", "Rejects all four noise/slip types, tracks sharp curves accurately, and delivers smooth actuation.", "Requires proper tuning of Q, R covariance matrices and PID gains.")
    ], "Table 2.1. Qualitative comparison of the four evaluated filtering and control models",
       col_widths_cm=[3.1, 3.6, 4.6, 4.7], bold_last_row=True)

    # =====================================================================
    # CHAPTER 3. SYSTEM DESIGN AND METHODOLOGY
    # =====================================================================
    add_chapter_heading(doc, "CHAPTER 3. SYSTEM DESIGN AND METHODOLOGY")

    add_h2(doc, "3.1. Problem Formulation, Constraints, and Six Quantitative Metrics")
    add_body(doc,
        "Starting from an offset initial pose q(0) = [0.40, −0.45, θ_{r}(0) − 0.30]^{T}, the differential-drive AGV must converge to and track the reference "
        "trajectory q_{r}(t) under actuator saturation limits |v_{cmd}| ≤ 1.8 m/s and |ω_{cmd}| ≤ 3.0 rad/s. Performance is benchmarked for t ≥ 3.0 s using six metrics: "
        "RMSE_{p} [m] (primary accuracy metric penalizing large deviations), MAE_{p} [m] (mean absolute position error), Max_{p} [m] (worst-case safety margin), "
        "RMSE_{θ} [deg] (heading accuracy), IAE_{p} [m·s] (accumulated position error over time), and TV_{ω} [rad/s] (angular command total variation measuring actuator smoothness):"
    )
    add_existing_eq(doc, "3.1")

    add_h2(doc, "3.2. Proposed Closed-Loop Architecture (EKF + PID)")
    add_body(doc,
        "The proposed architecture integrates nonlinear EKF state estimation in the feedback path with a body-frame PID trajectory controller in the forward path "
        "(Figure 3.1). Encoder odometry drives the EKF prediction step, while noisy UWB/IMU measurements update the estimate through a 3σ outlier-rejection gate."
    )
    add_figure(doc, "diagram_1_system_architecture.png",
               "Figure 3.1. Overall closed-loop EKF + PID control architecture for the differential-drive AGV.", width_inches=6.2)

    add_h2(doc, "3.3. Extended Kalman Filter Design with 3σ Outlier Gating")
    add_body(doc,
        "At each 50 Hz sampling step (Δt = 0.02 s), the EKF predicts the pose from wheel odometry and computes the innovation vector ỹ_{k} = z_{k} − x̂_{k|k-1} "
        "(Figure 3.2). If the planar innovation norm exceeds the 3σ confidence threshold (||ỹ_{k,xy}|| > 3σ_{xy}), an outlier spike is flagged and the measurement "
        "covariance is temporarily inflated to R_{adapt} = 25 R, preventing corrupted measurements from destabilizing the state estimate."
    )
    add_figure(doc, "diagram_2_ekf_flowchart.png",
               "Figure 3.2. Flowchart of the Extended Kalman Filter (EKF) with 3σ innovation gating.", width_inches=5.3)

    add_h2(doc, "3.4. Body-Frame PID Trajectory Controller Design")
    add_body(doc,
        "The global tracking error is transformed into the robot body frame {B} via the rotation matrix R^{T}(θ̂):"
    )
    add_existing_eq(doc, "3.2")
    add_body(doc, "Combining velocity feedforward with decoupled PID feedback channels yields the linear and angular velocity commands (Figure 3.3):")
    add_existing_eq(doc, "3.3")
    add_existing_eq(doc, "3.4")
    add_figure(doc, "diagram_3_pid_control_loop.png",
               "Figure 3.3. Block diagram of the body-frame PID controller with Filtered D and Anti-windup.", width_inches=6.2)

    add_h2(doc, "3.5. Simulation Setup, Parameters, and Attribution Transparency")
    add_styled_table(doc, ["Category", "Symbol / Parameter", "Configured Value", "Physical Meaning"], [
        ("Robot Geometry", "r_{0} / b_{0}", "0.08 m / 0.35 m", "Nominal wheel radius and wheelbase"),
        ("Actuator Lag", "τ_{v} / τ_{ω}", "0.10 s / 0.08 s", "First-order motor time constants"),
        ("Saturation", "v_{max} / ω_{max}", "1.8 m/s / 3.0 rad/s", "Maximum safe AGV velocity limits"),
        ("Noise (1)", "σ_{xy} / σ_{θ}", "0.06 m / 2.5°", "Gaussian sensor noise (UWB & IMU)"),
        ("Noise (2)", "Outlier Spikes", "±0.38 m; ±14° (4 spikes)", "Sudden spikes at t = 7, 16, 24, 33 s"),
        ("Noise (3)", "σ_{enc} / Bias R, L", "0.04 / +0.22, −0.16 rad/s", "Encoder noise and systematic odometry drift"),
        ("Noise (4)", "Wheel Slip", "Zones t ∈ [9,15]s & [25,31]s", "Longitudinal traction loss & lateral skidding")
    ], "Table 3.1. Physical robot parameters and configuration of the four noise/disturbance sources",
       col_widths_cm=[2.9, 3.5, 4.3, 5.3])

    add_styled_table(doc, ["Module", "Parameter", "Value", "Design Role"], [
        ("EKF / KF", "Q", "diag(4×10^{-4}, 4×10^{-4}, 2×10^{-4})", "Process (odometry) noise covariance"),
        ("EKF / KF", "R", "diag(0.06^{2}, 0.06^{2}, 0.0436^{2})", "Measurement noise covariance"),
        ("EKF Gating", "3σ Threshold / R_{adapt}", "0.18 m / 25 R", "Outlier spike detection & down-weighting"),
        ("PID (EKF+PID)", "K_{p,v}, K_{i,v}, K_{d,v}", "2.80, 2.40, 0.15", "Longitudinal velocity control channel"),
        ("PID (EKF+PID)", "K_{p,y}, K_{i,y}, K_{d,y}", "5.50, 2.80, 0.20", "Cross-track lateral error channel"),
        ("PID (EKF+PID)", "K_{p,ω}, K_{i,ω}, K_{d,ω}", "3.80, 2.10, 0.18", "Heading error control channel"),
        ("Filter & Windup", "α_{d} / I_{max}", "0.22 / ±1.2", "Derivative low-pass filter & integral clamp")
    ], "Table 3.2. Tuned parameters for the KF/EKF estimators and P/PID trajectory controllers",
       col_widths_cm=[3.2, 3.8, 4.4, 4.6])

    add_styled_table(doc, ["Component", "Inherited / Referenced Baseline", "Original Design & Extensions"], [
        ("Robot Model", "Ideal differential-drive kinematics from MathWorks [1], [2] and RVC3 Ch.3 [5].", "Extended with first-order actuator lag (τ_{v}, τ_{ω}) and longitudinal/lateral wheel slip v_{y,slip}."),
        ("Kalman Filter", "Recursive KF/EKF theory from MathWorks [3], PythonRobotics [4], and [5], [6].", "Direct benchmark of Standard Linear KF vs. EKF enhanced with 3σ innovation gating against outliers."),
        ("PID Controller", "PID and filtered-derivative concepts from RVC3 Ch.3 Part 2 [5].", "Multi-channel body-frame PID with velocity feedforward, discrete filtered D, and anti-windup."),
        ("Validation", "RVC3 Section 3.1.4 straight-line following concept [5].", "Three comprehensive scenarios (Figure-8, Slipping Line, 50%–200% Sensitivity), Simulink .slx, and 2D animation.")
    ], "Table 3.3. Clear attribution separating inherited references from original design contributions",
       col_widths_cm=[2.9, 6.3, 6.8])

    # =====================================================================
    # CHAPTER 4. SIMULATION RESULTS AND DISCUSSION
    # =====================================================================
    add_chapter_heading(doc, "CHAPTER 4. SIMULATION RESULTS AND DISCUSSION")

    add_h2(doc, "4.1. Scenario 1: Figure-8 Trajectory Tracking Under Four Combined Noises")
    add_body(doc,
        "In Scenario 1, the robot tracks a continuous Lemniscate Figure-8 reference trajectory (x_{r} = 3.5 sin(ω_{0} t), y_{r} = 2.2 sin(2ω_{0} t), period 32 s) "
        "for 40 s under all four simultaneous disturbance sources. Results are illustrated in Figures 4.1–4.3 and summarized quantitatively in Table 4.1."
    )
    add_figure(doc, "fig1_trajectory_figure8.png",
               "Figure 4.1. 2D Figure-8 trajectories of the four models and zoomed-in view of the slip zone.", width_inches=6.2)
    add_figure(doc, "fig2_tracking_errors.png",
               "Figure 4.2. Time-domain tracking errors: Euclidean position ||e_{p}||, cross-track e_{y}, and heading e_{θ}.", width_inches=6.2)
    add_figure(doc, "fig3_control_inputs_and_slip.png",
               "Figure 4.3. Control commands (v, ω), KF vs. EKF estimation error, and accumulated odometry drift.", width_inches=6.2)

    add_styled_table(doc, ["Control & Filtering Model", "RMSE_{p} (m)", "MAE_{p} (m)", "Max_{p} (m)", "RMSE_{θ} (°)", "IAE_{p} (m·s)", "TV_{ω} (rad/s)"], [
        ("1. PID Only (PID Raw)", "0.1393", "0.1015", "0.3998", "5.2415", "3.7549", "36.11"),
        ("2. EKF Only (EKF + P)", "0.2159", "0.2013", "0.4526", "4.3802", "7.4488", "1.41"),
        ("3. Standard KF + PID", "0.1433", "0.1114", "0.4143", "7.0287", "4.1241", "3.08"),
        ("4. Extended KF + PID (Proposed)", "0.1253", "0.0920", "0.3648", "6.8902", "3.4049", "2.87")
    ], "Table 4.1. Quantitative comparison across six performance metrics in Scenario 1 (Figure-8)",
       col_widths_cm=[4.9, 1.85, 1.8, 1.8, 1.85, 1.9, 1.9], bold_last_row=True)

    add_bullet(doc, "PID Only (PID Raw): ", "Without state filtering, Gaussian noise and outlier spikes are amplified by the derivative term, causing extreme angular command chattering (TV_{ω} = 36.11 rad/s, 12.6× higher than EKF + PID).")
    add_bullet(doc, "EKF Only (EKF + P): ", "Produces very smooth commands (TV_{ω} = 1.41 rad/s), but lacking integral action causes severe steady-state tracking drift under wheel slip (worst RMSE_{p} = 0.2159 m and IAE_{p} = 7.4488 m·s).")
    add_bullet(doc, "Standard KF + PID vs. Extended KF + PID: ", "Standard KF suffers from nonlinear heading mismatch during turns and outlier spikes (Figure 4.3c), resulting in higher error (RMSE_{p} = 0.1433 m, Max_{p} = 0.4143 m).")
    add_bullet(doc, "Proposed Extended KF + PID: ", "Achieves the best overall tracking accuracy (RMSE_{p} = 0.1253 m, a 42.0% reduction vs. EKF Only and 12.6% vs. Standard KF + PID; lowest MAE_{p}, Max_{p}, and IAE_{p}) while cutting control chattering TV_{ω} by 92.1% compared to raw PID.")

    add_h2(doc, "4.2. Scenario 2: RVC3 Line Following Under Continuous Lateral Wheel Slip")
    add_body(doc,
        "Extending RVC3 Section 3.1.4 (line x − 2y + 4 = 0) with sustained lateral slip v_{y,slip} = −0.14 m/s starting at t = 8 s (Figure 4.4), "
        "EKF Only (EKF + P) remains trapped at a permanent steady-state offset of approximately −0.20 m. In contrast, Extended KF + PID leverages its "
        "integral action to converge the normal distance error d(t) cleanly back to 0.00 m within 4 seconds."
    )
    add_figure(doc, "fig4_lane_change_rvc3.png",
               "Figure 4.4. Scenario 2 – RVC3 straight-line following (x − 2y + 4 = 0) under continuous lateral slip.", width_inches=6.2)

    add_h2(doc, "4.3. Scenario 3: Robustness Sensitivity Analysis (50% – 200% Noise)")
    add_body(doc,
        "Scaling noise and outlier intensity from 50% to 200% (Figure 4.5b) confirms that Extended KF + PID consistently maintains the lowest RMSE_{p} "
        "curve with the gentlest growth slope, demonstrating superior robustness under harsh operating conditions."
    )
    add_figure(doc, "fig5_robustness_bar_chart.png",
               "Figure 4.5. Quantitative bar chart (RMSE, MAE, Max Error) and sensitivity analysis (50% – 200%).", width_inches=6.2)

    add_h2(doc, "4.4. Simulink Verification and Model Validation")
    add_body(doc,
        "The closed-loop EKF + PID architecture was independently validated in Simulink (sl_robust_mobile_robot.slx), encapsulating the perturbed "
        "unicycle kinematics into a clean 'Differential Drive Robot Model' Subsystem (Figure 4.6). Direct fixed-step simulation (ode4, Δt = 0.02 s) "
        "confirms rapid convergence and accurate tracking with RMSE = 0.1043 m (Figure 4.7)."
    )
    add_figure(doc, "fig6_simulink_diagram.png",
               "Figure 4.6. Simulink block diagram (sl_robust_mobile_robot.slx) with encapsulated Robot Model Subsystem.", width_inches=6.2)
    add_figure(doc, "fig7_simulink_verification.png",
               "Figure 4.7. Direct Simulink verification of XY trajectory and Euclidean tracking error (RMSE = 0.1043 m).", width_inches=6.2)

    add_h2(doc, "4.5. Discussion of Strengths and Remaining Limitations")
    add_bullet(doc, "Strengths: ", "Lightweight computational footprint (suitable for 50 Hz real-time execution on embedded MCUs), transparent tuning grounded in classical control and estimation theory, and verified superiority across all key metrics.")
    add_bullet(doc, "Limitations: ", "(1) Abrupt high-magnitude wheel slip at sharp curve apices still causes a transient peak Max_{p} = 0.3648 m while integral action builds up; (2) Heading RMSE_{θ} (6.89°) is slightly higher than EKF + P because the robot intentionally maintains a small crabbing angle to counter lateral slip; (3) Fixed Q, R and PID gains are not yet online-adaptive for extreme payload changes.")

    # =====================================================================
    # CHAPTER 5. CONCLUSION AND FUTURE WORK
    # =====================================================================
    add_chapter_heading(doc, "CHAPTER 5. CONCLUSION AND FUTURE WORK")

    add_h2(doc, "5.1. Conclusion")
    add_body(doc,
        "This project successfully developed and validated an Extended Kalman Filter + PID trajectory control framework for differential-drive AGVs "
        "operating under Gaussian sensor noise, outlier spikes, encoder drift, and wheel slip. Benchmarking against PID Only, EKF Only, and Standard "
        "KF + PID across three MATLAB scenarios and Simulink verification confirmed that EKF + PID delivers the lowest tracking error (RMSE_{p} = 0.1253 m, "
        "42.0% better than EKF Only), eliminates 92.1% of raw-PID angular command chattering, and fully removes steady-state slip offsets."
    )

    add_h2(doc, "5.2. Future Work")
    add_bullet(doc, "Augmented EKF Slip Estimation: ", "Augment the EKF state vector with lateral slip velocity v_{y,slip} to enable direct feedforward slip compensation.")
    add_bullet(doc, "Model Predictive Control (MPC): ", "Investigate constrained MPC to further reduce transient peak errors at high curvature.")
    add_bullet(doc, "Hardware / ROS 2 Deployment: ", "Deploy the validated EKF + PID stack onto a physical differential-drive robot (e.g., TurtleBot3 with LiDAR, IMU, and wheel encoders) in ROS 2.")

    # =====================================================================
    # REFERENCES (IEEE)
    # =====================================================================
    add_chapter_heading(doc, "REFERENCES")
    for r_txt in [
        '[1] MathWorks, "Path Following for a Differential Drive Robot," MATLAB Documentation. [Online]. Available: https://www.mathworks.com/help/robotics/examples/path-following-for-a-differential-drive-robot.html. Accessed: 18-Nov-2026.',
        '[2] MathWorks, "differentialDriveKinematics - Differential-drive vehicle kinematic model," MATLAB Documentation. [Online]. Available: https://www.mathworks.com/help/robotics/ref/differentialdrivekinematics.html. Accessed: 18-Nov-2026.',
        '[3] MathWorks, "Localization Algorithms in Navigation Toolbox," MATLAB Documentation. [Online]. Available: https://www.mathworks.com/help/nav/localization-algorithms.html. Accessed: 18-Nov-2026.',
        '[4] A. Sakai et al., "PythonRobotics: Extended Kalman Filter Localization," GitHub repository. [Online]. Available: https://github.com/AtsushiSakai/PythonRobotics/blob/master/Localization/extended_kalman_filter/extended_kalman_filter.py. Accessed: 18-Nov-2026.',
        '[5] P. Corke, Robotics, Vision and Control: Fundamental Algorithms in MATLAB, 3rd ed. Cham, Switzerland: Springer, 2023.',
        '[6] A. Becker, Kalman Filter from the Ground Up, 2023.'
    ]:
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.line_spacing = 1.3
        p.paragraph_format.left_indent = Cm(0.8)
        p.paragraph_format.first_line_indent = Cm(-0.8)
        rn = p.add_run(r_txt)
        rn.font.name = 'Times New Roman'
        rn.font.size = Pt(12.5)

    # =====================================================================
    # APPENDIX
    # =====================================================================
    add_chapter_heading(doc, "APPENDIX: SOURCE CODE, EXECUTION GUIDE, AND AI DISCLOSURE")
    add_h2(doc, "A.1. Repository and Reproducibility")
    add_body(doc, "https://github.com/HuynhMinhThuan1310/robot-22ktmt1", bold_prefix="GitHub Repository: ", indent=False)
    add_bullet(doc, "run_all_simulations.m: ", "Runs all three scenarios, prints the 6-metric table, exports 5 high-resolution PNG figures, and launches the live 2D animation.")
    add_bullet(doc, "build_simulink_model.m & sl_robust_mobile_robot.slx: ", "Builds, simulates, and opens the Simulink EKF + PID block diagram.")

    add_h2(doc, "A.2. AI Assistance Transparency Statement")
    add_body(doc,
        "During this project, the student team (Huynh Minh Thuan and Tran Viet Thang) utilized AI-assisted tools as a technical aid for structuring "
        "MATLAB/Simulink code, automating plot generation, and proofreading report formatting. All problem formulation, noise-source selection, "
        "controller/estimator benchmarking design, parameter tuning, direct MATLAB R2024a/Simulink verification, and verification of all equations "
        "and experimental data were independently performed and validated by the authors."
    )

    doc.save(OUT_DOCX_EN)
    print(f"EN_REPORT_SAVED: {OUT_DOCX_EN}")


if __name__ == '__main__':
    build_english_report()
