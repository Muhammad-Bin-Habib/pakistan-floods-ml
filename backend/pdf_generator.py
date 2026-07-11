import os
import datetime
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, KeepTogether
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch

# Theme color configuration matching NDMA application guidelines
CLR_NAVY = colors.HexColor('#0F172A')       # Prussian Navy Primary
CLR_GREEN = colors.HexColor('#16A34A')      # Forest Green Accent
CLR_TEXT = colors.HexColor('#334155')       # Slate Text color
CLR_BG = colors.HexColor('#F8FAFC')         # Light background shade
CLR_BORDER = colors.HexColor('#E2E8F0')     # Border shade

def generate_projection_pdf(region, officer_name, batch_id, model_r2, df_projections, dest_path):
    """
    Renders a professional PDF report containing the ML future calamity projections
    complete with tables, NDMA headers, and a matplotlib trend visualization.
    """
    # 1. Generate the Calamity Risk Projections Line Chart
    chart_path = os.path.join(os.path.dirname(dest_path), f'temp_trend_{region}.png')
    
    plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')
    fig, ax = plt.subplots(figsize=(6.5, 3.0), dpi=300)
    
    years = df_projections['Year'].tolist()
    min_aff = df_projections['Est_Affected_Min'].tolist()
    max_aff = df_projections['Est_Affected_Max'].tolist()
    fatality = df_projections['Proj_Fatalities'].tolist()
    
    # Dual-axis chart: Left axis for Est Affected range, Right axis for fatalities
    ax.fill_between(years, min_aff, max_aff, color='#16A34A', alpha=0.15, label='Est. Affected Population Range')
    line1 = ax.plot(years, min_aff, color='#15803D', linestyle='--', linewidth=1.5, label='Min Est. Affected')
    line2 = ax.plot(years, max_aff, color='#16A34A', linestyle='-', linewidth=1.8, label='Max Est. Affected')
    ax.set_ylabel('Projected Affected Population', color='#16A34A', fontsize=9, fontweight='bold')
    ax.tick_params(axis='y', labelcolor='#16A34A', labelsize=8)
    
    ax2 = ax.twinx()
    line3 = ax2.plot(years, fatality, color='#C53030', marker='o', markersize=4, linewidth=1.8, label='Proj. Fatalities')
    ax2.set_ylabel('Projected Calamity Fatalities', color='#C53030', fontsize=9, fontweight='bold')
    ax2.tick_params(axis='y', labelcolor='#C53030', labelsize=8)
    ax2.grid(False) # Prevent overlapping gridlines
    
    # Unified legends
    lines = line1 + line2 + line3
    labels = [l.get_label() for l in lines]
    ax.legend(lines, labels, loc='upper left', fontsize=8, frameon=True, facecolor='white', edgecolor='#E2E8F0')
    
    ax.set_xlabel('Projected Year (Incremental Simulation)', fontsize=9)
    ax.set_title(f'Risk Trend Simulation Model: {region.upper()} Forecast (2023-2030)', fontsize=10, fontweight='bold', color='#0F172A', pad=10)
    
    plt.tight_layout()
    plt.savefig(chart_path, format='png', bbox_inches='tight')
    plt.close()

    # 2. Setup ReportLab PDF flow documents
    doc = SimpleDocTemplate(
        dest_path,
        pagesize=letter,
        leftMargin=0.5 * inch,
        rightMargin=0.5 * inch,
        topMargin=0.5 * inch,
        bottomMargin=0.5 * inch
    )
    
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=18,
        leading=22,
        textColor=CLR_NAVY,
        spaceAfter=4
    )
    
    subtitle_style = ParagraphStyle(
        'DocSubTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=14,
        textColor=CLR_GREEN,
        spaceAfter=15
    )
    
    h2_style = ParagraphStyle(
        'SectionHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=CLR_NAVY,
        spaceBefore=12,
        spaceAfter=8,
        keepWithNext=True
    )
    
    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=13,
        textColor=CLR_TEXT
    )

    tbl_header_style = ParagraphStyle(
        'TblHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10,
        textColor=colors.white,
        alignment=1 # Centered
    )

    tbl_cell_style = ParagraphStyle(
        'TblCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=11,
        textColor=CLR_TEXT,
        alignment=1 # Centered
    )

    story = []
    
    # Header NDMA bar decoration
    header_data = [[
        Paragraph('NATIONAL DISASTER MANAGEMENT AUTHORITY (NDMA) EOC SYSTEM', ParagraphStyle('HBar', fontName='Helvetica-Bold', fontSize=9, leading=11, textColor=colors.white)),
        Paragraph(f"GEN TIME: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M')}", ParagraphStyle('HTime', fontName='Helvetica', fontSize=8, leading=10, textColor=colors.white, alignment=2))
    ]]
    header_table = Table(header_data, colWidths=[5.0 * inch, 2.5 * inch])
    header_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), CLR_NAVY),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
        ('RIGHTPADDING', (0,0), (-1,-1), 10),
    ]))
    story.append(header_table)
    story.append(Spacer(1, 10))
    
    # Document main title
    story.append(Paragraph('CALAMITY RISK & RELIEF PROJECTIONS REPORT', title_style))
    story.append(Paragraph(f'REGIONAL RISK FORECAST FOR TERRITORY OF: {region.upper()}', subtitle_style))
    
    # Metadata parameters table
    meta_data = [
        [
            Paragraph('<b>EOC Analyst:</b>', body_style), Paragraph(officer_name, body_style),
            Paragraph('<b>System Model Accuracy (R²):</b>', body_style), Paragraph(f"{model_r2 * 100:.2f}%", body_style)
        ],
        [
            Paragraph('<b>Officer Batch ID:</b>', body_style), Paragraph(batch_id, body_style),
            Paragraph('<b>Simulation Engine:</b>', body_style), Paragraph('Linear Regression & Scaling', body_style)
        ]
    ]
    meta_table = Table(meta_data, colWidths=[1.8 * inch, 1.95 * inch, 2.05 * inch, 1.7 * inch])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), CLR_BG),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('ROWBACKGROUNDS', (0,0), (-1,-1), [CLR_BG]),
        ('BOX', (0,0), (-1,-1), 1, CLR_BORDER),
        ('INNERGRID', (0,0), (-1,-1), 0.5, CLR_BORDER),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 12))
    
    # 1. Calamity forecast charts
    story.append(Paragraph('I. SIMULATION FORWARD PROJECTIONS GRAPH (EOC DATA MODEL)', h2_style))
    story.append(Image(chart_path, width=7.0 * inch, height=3.2 * inch))
    story.append(Spacer(1, 12))
    
    # 2. Detailed calamity metrics table
    story.append(Paragraph('II. SIMULATION DATA SUMMARY TABLE', h2_style))
    
    # Table headers setup
    table_headers = [
        Paragraph('<b>Yr</b>', tbl_header_style), 
        Paragraph('<b>Deaths</b>', tbl_header_style), 
        Paragraph('<b>Injured</b>', tbl_header_style), 
        Paragraph('<b>Houses Dmg</b>', tbl_header_style),
        Paragraph('<b>Est. Affected (Range)</b>', tbl_header_style),
        Paragraph('<b>Tents Req.</b>', tbl_header_style),
        Paragraph('<b>Water (Ltrs)</b>', tbl_header_style),
        Paragraph('<b>Med. Kits</b>', tbl_header_style)
    ]
    
    table_rows = [table_headers]
    
    # Load and format prediction data rows
    for index, row in df_projections.iterrows():
        table_rows.append([
            Paragraph(str(int(row['Year'])), tbl_cell_style),
            Paragraph(f"{int(row['Proj_Fatalities']):,}", tbl_cell_style),
            Paragraph(f"{int(row['Proj_Injured']):,}", tbl_cell_style),
            Paragraph(f"{int(row['Proj_Houses_Damaged']):,}", tbl_cell_style),
            Paragraph(f"{int(row['Est_Affected_Min']):,} - {int(row['Est_Affected_Max']):,}", tbl_cell_style),
            Paragraph(f"{int(row['Tents_Req_Min']):,} - {int(row['Tents_Req_Max']):,}", tbl_cell_style),
            Paragraph(f"{int(row['Water_Liters_Min']):,} - {int(row['Water_Liters_Max']):,}", tbl_cell_style),
            Paragraph(f"{int(row['MedicalComps_Req_Min']):,} - {int(row['MedicalComps_Req_Max']):,}", tbl_cell_style)
        ])
        
    projections_table = Table(table_rows, colWidths=[
        0.55 * inch, 0.75 * inch, 0.75 * inch, 0.9 * inch, 1.65 * inch, 1.1 * inch, 1.2 * inch, 0.6 * inch
    ])
    
    projections_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), CLR_NAVY),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, CLR_BORDER),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, CLR_BG])
    ]))
    story.append(projections_table)
    
    # 3. Footer disclaimer
    story.append(Spacer(1, 15))
    story.append(Paragraph('<i>Notice: This calculation is generated purely for crisis modeling. Discrepancies between prediction outputs and real-life outcomes should be verified with ground-level SITREPs.</i>', ParagraphStyle('Notes', fontName='Helvetica-Oblique', fontSize=7, leading=10, textColor=CLR_TEXT)))

    # Build PDF
    doc.build(story)
    
    # Clean up the chart image
    if os.path.exists(chart_path):
        try:
            os.remove(chart_path)
        except:
            pass
            
    return dest_path


def generate_dataset_summary_pdf(officer_name, batch_id, df_historical, dest_path):
    """
    Renders a professional summary report of the historical disaster database
    including metrics, a visual bar chart comparing regions, and statistics tables.
    """
    # 1. Generate the historical regional summary chart
    chart_path = os.path.join(os.path.dirname(dest_path), 'temp_hist_chart.png')
    
    # Aggregate data by Region
    agg = df_historical.groupby('Region').agg({
        'Total_deaths': 'sum',
        'Total_injured': 'sum',
        'Houses_damaged': 'sum',
        'Livestock_damaged': 'sum',
        'Year': 'count'
    }).rename(columns={'Year': 'record_count'}).reset_index()

    plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')
    fig, ax = plt.subplots(figsize=(6.5, 3.0), dpi=300)
    
    # Bar width and offset
    x = np.arange(len(agg['Region']))
    width = 0.35
    
    bars1 = ax.bar(x - width/2, agg['Total_deaths'], width, label='Fatalities', color='#C53030')
    bars2 = ax.bar(x + width/2, agg['Houses_damaged'] / 100, width, label='Houses Damaged (x100)', color='#0F172A')
    
    # Set tick labels and legend
    ax.set_xticks(x)
    ax.set_xticklabels(agg['Region'].str.upper(), fontsize=8)
    ax.set_ylabel('Aggregated Incidents Metric count', fontsize=9, fontweight='bold', color='#0F172A')
    ax.set_title('Historical Database Aggregates: Calamity Breakdown by Province/Region', fontsize=10, fontweight='bold', color='#0F172A', pad=10)
    ax.legend(fontsize=8, loc='upper right', frameon=True)
    
    plt.tight_layout()
    plt.savefig(chart_path, format='png', bbox_inches='tight')
    plt.close()

    # 2. Setup ReportLab PDF Flow Document
    doc = SimpleDocTemplate(
        dest_path,
        pagesize=letter,
        leftMargin=0.5 * inch,
        rightMargin=0.5 * inch,
        topMargin=0.5 * inch,
        bottomMargin=0.5 * inch
    )
    
    styles = getSampleStyleSheet()
    
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=18,
        leading=22,
        textColor=CLR_NAVY,
        spaceAfter=4
    )
    
    subtitle_style = ParagraphStyle(
        'DocSubTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=14,
        textColor=CLR_GREEN,
        spaceAfter=15
    )
    
    h2_style = ParagraphStyle(
        'SectionHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=CLR_NAVY,
        spaceBefore=12,
        spaceAfter=8,
        keepWithNext=True
    )
    
    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=13,
        textColor=CLR_TEXT
    )

    tbl_header_style = ParagraphStyle(
        'TblHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10,
        textColor=colors.white,
        alignment=1
    )

    tbl_cell_style = ParagraphStyle(
        'TblCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=11,
        textColor=CLR_TEXT,
        alignment=1
    )

    story = []
    
    # Header bar
    header_data = [[
        Paragraph('NATIONAL DISASTER MANAGEMENT AUTHORITY (NDMA) EOC SYSTEM', ParagraphStyle('HBar', fontName='Helvetica-Bold', fontSize=9, leading=11, textColor=colors.white)),
        Paragraph(f"GEN TIME: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M')}", ParagraphStyle('HTime', fontName='Helvetica', fontSize=8, leading=10, textColor=colors.white, alignment=2))
    ]]
    header_table = Table(header_data, colWidths=[5.0 * inch, 2.5 * inch])
    header_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), CLR_NAVY),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
        ('RIGHTPADDING', (0,0), (-1,-1), 10),
    ]))
    story.append(header_table)
    story.append(Spacer(1, 10))
    
    # Title
    story.append(Paragraph('HISTORICAL FLOOD DATA & TELEMETRY SUMMARY', title_style))
    story.append(Paragraph('SYSTEM TELEMETRY DATABASE CONSOLIDATED SITUATION REPORT', subtitle_style))
    
    # Metadata table
    total_records = len(df_historical)
    min_year = int(df_historical['Year'].min()) if not df_historical.empty else 0
    max_year = int(df_historical['Year'].max()) if not df_historical.empty else 0
    
    meta_data = [
        [
            Paragraph('<b>Requesting Officer:</b>', body_style), Paragraph(officer_name, body_style),
            Paragraph('<b>Historical Span:</b>', body_style), Paragraph(f"{min_year} - {max_year}", body_style)
        ],
        [
            Paragraph('<b>Officer Batch ID:</b>', body_style), Paragraph(batch_id, body_style),
            Paragraph('<b>Consolidated Records:</b>', body_style), Paragraph(f"{total_records} Years / SITREPs", body_style)
        ]
    ]
    meta_table = Table(meta_data, colWidths=[1.8 * inch, 1.95 * inch, 2.05 * inch, 1.7 * inch])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), CLR_BG),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('ROWBACKGROUNDS', (0,0), (-1,-1), [CLR_BG]),
        ('BOX', (0,0), (-1,-1), 1, CLR_BORDER),
        ('INNERGRID', (0,0), (-1,-1), 0.5, CLR_BORDER),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 12))
    
    # 1. Historical comparison chart
    story.append(Paragraph('I. HISTORICAL SYSTEM CALAMITY INCIDENTS GRAPH', h2_style))
    story.append(Image(chart_path, width=7.0 * inch, height=3.2 * inch))
    story.append(Spacer(1, 12))
    
    # 2. Aggregated breakdown by region
    story.append(Paragraph('II. SUMMARY BREAKDOWN BY GEOGRAPHICAL PROVINCE/REGION', h2_style))
    
    table_headers = [
        Paragraph('<b>Region</b>', tbl_header_style), 
        Paragraph('<b>Reports Count</b>', tbl_header_style),
        Paragraph('<b>Total Deaths</b>', tbl_header_style), 
        Paragraph('<b>Total Injured</b>', tbl_header_style), 
        Paragraph('<b>Houses Damaged</b>', tbl_header_style),
        Paragraph('<b>Livestock Lost</b>', tbl_header_style)
    ]
    
    table_rows = [table_headers]
    for idx, row in agg.iterrows():
        table_rows.append([
            Paragraph(str(row['Region']).upper(), tbl_cell_style),
            Paragraph(f"{int(row['record_count']):,}", tbl_cell_style),
            Paragraph(f"{int(row['Total_deaths']):,}", tbl_cell_style),
            Paragraph(f"{int(row['Total_injured']):,}", tbl_cell_style),
            Paragraph(f"{int(row['Houses_damaged']):,}", tbl_cell_style),
            Paragraph(f"{int(row['Livestock_damaged']):,}", tbl_cell_style)
        ])
        
    agg_table = Table(table_rows, colWidths=[1.5 * inch, 1.1 * inch, 1.2 * inch, 1.2 * inch, 1.3 * inch, 1.2 * inch])
    agg_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), CLR_NAVY),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.5, CLR_BORDER),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, CLR_BG])
    ]))
    story.append(agg_table)
    
    story.append(Spacer(1, 15))
    story.append(Paragraph('<i>System Data Provenance Warning: Generated directly from central analytics repository. All data points reflect official recorded metrics for national disaster reporting.</i>', ParagraphStyle('Notes', fontName='Helvetica-Oblique', fontSize=7, leading=10, textColor=CLR_TEXT)))

    doc.build(story)
    
    if os.path.exists(chart_path):
        try:
            os.remove(chart_path)
        except:
            pass
            
    return dest_path
