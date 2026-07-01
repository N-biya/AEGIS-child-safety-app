from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm, mm
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, PageBreak, KeepTogether
)
from reportlab.platypus.flowables import Flowable
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor

# ── Palette ───────────────────────────────────────────────────────────────────
C_HEADER_BG    = HexColor('#3B2F2F')   # deep warm brown — main header bar
C_HEADER_TEXT  = HexColor('#FFF8F0')   # warm cream text on headers
C_SUBHDR_BG    = HexColor('#C9A98A')   # warm toffee — sub-header bars
C_SUBHDR_TEXT  = HexColor('#2C1A0E')   # dark espresso text
C_ROW_LIGHT    = HexColor('#FFF8F0')   # warm cream — content rows
C_ROW_ALT      = HexColor('#F5ECD7')   # soft apricot — alternating rows
C_ACTION_BG    = HexColor('#FDE8D8')   # peach blush — action items block
C_PROGRESS_BG  = HexColor('#EDE7F6')   # soft lavender — progress block
C_ACCENT_LINE  = HexColor('#C4875A')   # warm terracotta — divider lines
C_PAGE_BG      = HexColor('#FFFCF7')   # near-white warm — page tint
C_COVER_TOP    = HexColor('#3B2F2F')   # cover gradient top
C_COVER_MID    = HexColor('#7B4F3A')   # warm mahogany
C_LABEL        = HexColor('#7B4F3A')   # warm brown for field labels
C_BORDER       = HexColor('#D4B896')   # warm sand border

W, H = A4

# ── Data ──────────────────────────────────────────────────────────────────────
meetings = [
    {
        'form': 11, 'date': '21 April, 2026', 'time': '10:30 AM',
        'action_items': [
            'Get Firebase connected to the Flutter app — Firestore and Auth set up.',
            'Agree on a folder structure and clean up the pubspec dependencies.',
            'Sketch out a rough plan for what we are building across the app, firmware, and ML.',
        ],
        'remarks': [
            'Diagrams refined. Sequence diagram updated with BLE flow.',
            'Use-case diagram aligned with defended concept.',
            'Design documentation complete. Ready for implementation phase.',
        ],
    },
    {
        'form': 12, 'date': '28 April, 2026', 'time': '11:00 AM',
        'action_items': [
            'Set up the bottom nav bar and make sure routing works across all five screens.',
            'Build out basic page layouts for Home, Map, Alerts, Profile, and Settings.',
            'Go over the screens and check they match the Velvet Night design we have been following.',
        ],
        'remarks': [
            'Firebase connected. Firestore and Auth initialised.',
            'Folder structure and dependencies finalised.',
            'Development roadmap drafted and approved.',
        ],
    },
    {
        'form': 13, 'date': '07 May, 2026', 'time': '10:00 AM',
        'action_items': [
            'Get email and password login and signup working with Firebase Auth.',
            'Add field validation and keep the user logged in after closing the app.',
            'Test the full sign-in and sign-out flow on the emulator and a real phone.',
        ],
        'remarks': [
            'Bottom nav bar implemented. Routing working across all screens.',
            'Page layouts built with consistent styling.',
            'Screens match Velvet Night design. Spacing corrected.',
        ],
    },
    {
        'form': 14, 'date': '13 May, 2026', 'time': '11:30 AM',
        'action_items': [
            "Add Google Maps and show the child's live position on the tracking screen.",
            'Set up a Firestore listener so the location updates automatically.',
            'Put a proper marker and small avatar on the map so the child is easy to spot.',
        ],
        'remarks': [
            'Login and signup working with Firebase Auth.',
            'Form validation and session persistence in place.',
            'Tested on emulator and physical device. All passing.',
        ],
    },
    {
        'form': 15, 'date': '20 May, 2026', 'time': '10:30 AM',
        'action_items': [
            'Let the parent draw a safe zone circle on the map and adjust its size.',
            'Save the zone to Firestore so it loads back next time the app opens.',
            'Fire a notification when the child steps outside the safe zone.',
        ],
        'remarks': [
            'Google Maps integrated. Live location displaying correctly.',
            'Firestore listener active. Coordinates updating in real time.',
            'Custom marker and avatar added to tracking screen.',
        ],
    },
    {
        'form': 16, 'date': '26 May, 2026', 'time': '11:00 AM',
        'action_items': [
            'Write firmware to read GPS data from the Neo-6M and send it over BLE.',
            'Broadcast the device ID and coordinates from the ESP32 to the paired phone.',
            'Test it on the real hardware and confirm the Flutter app receives the data correctly.',
        ],
        'remarks': [
            'Safe zone circle implemented. Draggable and resizable.',
            'Zone data saved to Firestore. Loads correctly on relaunch.',
            'Notification triggers on safe zone breach. Tested successfully.',
        ],
    },
    {
        'form': 17, 'date': '03 June, 2026', 'time': '10:30 AM',
        'action_items': [
            'Load the TFLite activity model onto the ESP32 and run it on MPU-6050 sensor data.',
            'Normalise the accelerometer readings before passing them to the model.',
            'Verify the model is picking up idle, walking, running, and fall correctly.',
        ],
        'remarks': [
            'ESP32 reading GPS from Neo-6M. NMEA parsing working.',
            'BLE broadcasting device ID and GPS payload. Verified.',
            'Flutter app receiving and parsing BLE data correctly.',
        ],
    },
    {
        'form': 18, 'date': '09 June, 2026', 'time': '11:00 AM',
        'action_items': [
            'Set up FCM so parents get push alerts when something happens.',
            'Make sure all three alerts fire — safe zone exit, fall detected, and low battery.',
            'Add an alert history screen in the app showing what happened and when.',
        ],
        'remarks': [
            'TFLite model running on ESP32. Inference on MPU-6050 confirmed.',
            'Preprocessing pipeline in place. Readings normalised before inference.',
            'Activity labels and fall detection at acceptable accuracy.',
        ],
    },
    {
        'form': 19, 'date': '16 June, 2026', 'time': '10:00 AM',
        'action_items': [
            'Run a full end-to-end test on the BLE link between the band and the app.',
            'Stress-test the Firestore sync to see how it holds up with live location data.',
            'Write down any bugs we find and plan fixes for the next session.',
        ],
        'remarks': [
            'FCM set up. Push notifications reaching parent device.',
            'All three alert types triggering correctly in tests.',
            'Alert history screen complete. Entries showing with timestamps.',
        ],
    },
    {
        'form': 20, 'date': '18 June, 2026', 'time': '11:30 AM',
        'action_items': [
            'Walk through the whole system — hardware, firmware, and the app — and review everything.',
            'Finalise the demo script and any remaining documentation for FYP submission.',
            'Confirm everything is in order and the project is ready for the final evaluation.',
        ],
        'remarks': [
            'Full BLE pipeline tested. Packet-loss bug found and fixed.',
            'Firestore sync stable under load. Response times acceptable.',
            'All bugs resolved. System ready for final evaluation.',
        ],
    },
]

# ── Styles ────────────────────────────────────────────────────────────────────
styles = getSampleStyleSheet()

sty_cover_title = ParagraphStyle('CoverTitle',
    fontName='Helvetica-Bold', fontSize=26, textColor=C_HEADER_TEXT,
    alignment=TA_CENTER, spaceAfter=6)

sty_cover_sub = ParagraphStyle('CoverSub',
    fontName='Helvetica', fontSize=13, textColor=HexColor('#F5DEB3'),
    alignment=TA_CENTER, spaceAfter=4)

sty_cover_meta = ParagraphStyle('CoverMeta',
    fontName='Helvetica', fontSize=10, textColor=HexColor('#D4B896'),
    alignment=TA_CENTER, spaceAfter=3)

sty_form_hdr = ParagraphStyle('FormHdr',
    fontName='Helvetica-Bold', fontSize=11, textColor=C_HEADER_TEXT,
    alignment=TA_LEFT, leftIndent=4)

sty_form_hdr_right = ParagraphStyle('FormHdrR',
    fontName='Helvetica-Bold', fontSize=11, textColor=C_HEADER_TEXT,
    alignment=TA_RIGHT, rightIndent=4)

sty_label = ParagraphStyle('Label',
    fontName='Helvetica-Bold', fontSize=8.5, textColor=C_LABEL, alignment=TA_LEFT)

sty_value = ParagraphStyle('Value',
    fontName='Helvetica', fontSize=9, textColor=HexColor('#2C1A0E'), alignment=TA_LEFT)

sty_section_hdr = ParagraphStyle('SecHdr',
    fontName='Helvetica-Bold', fontSize=9.5, textColor=C_SUBHDR_TEXT, alignment=TA_LEFT)

sty_bullet = ParagraphStyle('Bullet',
    fontName='Helvetica', fontSize=9.5, textColor=HexColor('#2C1A0E'),
    leftIndent=10, firstLineIndent=0, spaceAfter=3, bulletIndent=0)

sty_pg_footer = ParagraphStyle('Footer',
    fontName='Helvetica', fontSize=8, textColor=HexColor('#9E7B5A'), alignment=TA_CENTER)


# ── Page template with warm background ────────────────────────────────────────
class WarmBackground(Flowable):
    def draw(self):
        pass


def on_page(canv, doc):
    canv.saveState()
    canv.setFillColor(C_PAGE_BG)
    canv.rect(0, 0, W, H, fill=1, stroke=0)
    # subtle bottom rule
    canv.setStrokeColor(C_ACCENT_LINE)
    canv.setLineWidth(0.6)
    canv.line(cm*2, cm*1.2, W - cm*2, cm*1.2)
    # footer text
    canv.setFont('Helvetica', 7.5)
    canv.setFillColor(HexColor('#9E7B5A'))
    canv.drawCentredString(W/2, cm*0.8, 'AEGIS — Child Safety Band   |   FYP Meeting Records')
    canv.drawRightString(W - cm*2, cm*0.8, f'Page {doc.page}')
    canv.restoreState()


def on_cover_page(canv, doc):
    canv.saveState()
    # warm gradient background simulation (two rects)
    canv.setFillColor(HexColor('#3B2F2F'))
    canv.rect(0, 0, W, H, fill=1, stroke=0)
    canv.setFillColor(HexColor('#5C3D2E'))
    canv.rect(0, 0, W, H*0.55, fill=1, stroke=0)
    canv.setFillColor(HexColor('#7B4F3A'))
    canv.rect(0, 0, W, H*0.3, fill=1, stroke=0)
    canv.setFillColor(HexColor('#9B6B52'))
    canv.rect(0, 0, W, H*0.12, fill=1, stroke=0)
    # decorative horizontal lines
    canv.setStrokeColor(HexColor('#C4875A'))
    canv.setLineWidth(1.5)
    canv.line(cm*3, H*0.62, W-cm*3, H*0.62)
    canv.setLineWidth(0.5)
    canv.line(cm*3, H*0.60, W-cm*3, H*0.60)
    canv.restoreState()


# ── Helper: build one meeting block ──────────────────────────────────────────
def build_meeting_block(m):
    elements = []
    col_w = W - 4*cm   # usable width

    # ── Top header bar ────────────────────────────────────────────────────
    hdr_data = [[
        Paragraph(f'Meeting Form No.  {m["form"]}', sty_form_hdr),
        Paragraph(f'Date:  {m["date"]}   &nbsp;&nbsp;   Time:  {m["time"]}', sty_form_hdr_right),
    ]]
    hdr_table = Table(hdr_data, colWidths=[col_w*0.45, col_w*0.55])
    hdr_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), C_HEADER_BG),
        ('TOPPADDING',    (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LEFTPADDING',   (0,0), (0,0),   10),
        ('RIGHTPADDING',  (-1,-1), (-1,-1), 10),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('ROUNDEDCORNERS', [4, 4, 0, 0]),
    ]))

    # ── Info row (project / supervisor / members) ─────────────────────────
    info_data = [
        [Paragraph('Project Title', sty_label),
         Paragraph('AEGIS — Child Safety Band', sty_value),
         Paragraph('Supervisor', sty_label),
         Paragraph('Dr. Altaf Hussain', sty_value)],
        [Paragraph('Members', sty_label),
         Paragraph('Barira Sarfraz &nbsp; | &nbsp; Nabeeha Zahid', sty_value),
         Paragraph('Reg. No.', sty_label),
         Paragraph('222201044 &nbsp; | &nbsp; 222201009', sty_value)],
    ]
    info_table = Table(info_data, colWidths=[col_w*0.13, col_w*0.37, col_w*0.13, col_w*0.37])
    info_style = TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), C_ROW_LIGHT),
        ('BACKGROUND', (0,1), (-1,1), C_ROW_ALT),
        ('TOPPADDING',    (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING',   (0,0), (-1,-1), 8),
        ('RIGHTPADDING',  (0,0), (-1,-1), 6),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('GRID', (0,0), (-1,-1), 0.4, C_BORDER),
    ])
    info_table.setStyle(info_style)

    # ── Action Items section ──────────────────────────────────────────────
    ai_hdr = Table([[Paragraph('  Action Items', sty_section_hdr)]],
                   colWidths=[col_w])
    ai_hdr.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), C_SUBHDR_BG),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
        ('GRID', (0,0), (-1,-1), 0.4, C_BORDER),
    ]))

    ai_rows = []
    for i, item in enumerate(m['action_items']):
        bg = C_ACTION_BG if i % 2 == 0 else HexColor('#FCEEE3')
        ai_rows.append([Paragraph(f'  {i+1}.  {item}', sty_bullet)])

    ai_body = Table(ai_rows, colWidths=[col_w])
    ai_body_style = [
        ('TOPPADDING',    (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING',   (0,0), (-1,-1), 12),
        ('GRID', (0,0), (-1,-1), 0.3, C_BORDER),
    ]
    for i in range(len(ai_rows)):
        bg = C_ACTION_BG if i % 2 == 0 else HexColor('#FCEEE3')
        ai_body_style.append(('BACKGROUND', (0,i), (0,i), bg))
    ai_body.setStyle(TableStyle(ai_body_style))

    # ── Progress on previous Items section ────────────────────────────────
    prog_hdr = Table([[Paragraph(
        f'  Progress on Previous Items  '
        f'<font color="#5C3D2E" size="8">(Supervisor Remarks — based on Form {m["form"]-1} action items)</font>',
        sty_section_hdr)]],
        colWidths=[col_w])
    prog_hdr.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), HexColor('#B39DDB')),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
        ('GRID', (0,0), (-1,-1), 0.4, HexColor('#9575CD')),
    ]))

    prog_rows = []
    for i, remark in enumerate(m['remarks']):
        bg = C_PROGRESS_BG if i % 2 == 0 else HexColor('#E8DAEF')
        prog_rows.append([Paragraph(f'  •  {remark}', sty_bullet)])

    prog_body = Table(prog_rows, colWidths=[col_w])
    prog_body_style = [
        ('TOPPADDING',    (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING',   (0,0), (-1,-1), 14),
        ('GRID', (0,0), (-1,-1), 0.3, HexColor('#9575CD')),
        ('ROUNDEDCORNERS', [0, 0, 4, 4]),
    ]
    for i in range(len(prog_rows)):
        bg = C_PROGRESS_BG if i % 2 == 0 else HexColor('#E8DAEF')
        prog_body_style.append(('BACKGROUND', (0,i), (0,i), bg))
    prog_body.setStyle(TableStyle(prog_body_style))

    block = KeepTogether([
        hdr_table,
        info_table,
        ai_hdr,
        ai_body,
        prog_hdr,
        prog_body,
        Spacer(1, 14),
    ])
    return block


# ── Build document ────────────────────────────────────────────────────────────
out_path = 'forms/AEGIS Meeting Forms 11-20.pdf'

doc = SimpleDocTemplate(
    out_path,
    pagesize=A4,
    leftMargin=2*cm, rightMargin=2*cm,
    topMargin=2.2*cm, bottomMargin=2.2*cm,
    title='AEGIS Meeting Forms 11–20',
    author='AEGIS Team',
)

story = []

# ── Cover page ────────────────────────────────────────────────────────────────
story.append(Spacer(1, H * 0.18))
story.append(Paragraph('AEGIS', sty_cover_title))
story.append(Paragraph('Child Safety Band', sty_cover_sub))
story.append(Spacer(1, 10))
story.append(Paragraph('FYP / II  —  Meeting Records', sty_cover_sub))
story.append(Spacer(1, 6))
story.append(HRFlowable(width='70%', thickness=1, color=C_ACCENT_LINE, hAlign='CENTER'))
story.append(Spacer(1, 12))
story.append(Paragraph('Meeting Forms 11 – 20', sty_cover_title))
story.append(Spacer(1, 8))
story.append(Paragraph('with Supervisor Remarks &amp; Progress Notes', sty_cover_sub))
story.append(Spacer(1, 30))
story.append(Paragraph('Supervisor:  Dr. Altaf Hussain', sty_cover_meta))
story.append(Paragraph('Members:  Barira Sarfraz  &nbsp;|&nbsp;  Nabeeha Zahid', sty_cover_meta))
story.append(Paragraph('Reg. No.:  222201044  &nbsp;|&nbsp;  222201009', sty_cover_meta))
story.append(Spacer(1, 16))
story.append(HRFlowable(width='40%', thickness=0.5, color=C_ACCENT_LINE, hAlign='CENTER'))
story.append(Spacer(1, 10))
story.append(Paragraph('21 April 2026 – 18 June 2026', sty_cover_meta))
story.append(PageBreak())

# ── Meeting blocks ────────────────────────────────────────────────────────────
for m in meetings:
    story.append(build_meeting_block(m))

# ── Build with two page templates ─────────────────────────────────────────────
# We use onFirstPage for cover and onLaterPages for rest
doc.build(story, onFirstPage=on_cover_page, onLaterPages=on_page)

print(f'PDF saved: {out_path}')
