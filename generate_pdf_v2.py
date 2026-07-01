from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm, mm
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, PageBreak, KeepTogether, Flowable
)
from reportlab.lib.colors import HexColor
from reportlab.pdfgen import canvas as pdfcanvas

W, H = A4

# ── Pastel Pink Palette ───────────────────────────────────────────────────────
C_COVER_BG       = HexColor('#3D1C2E')   # deep plum — cover bg
C_COVER_BAND     = HexColor('#7A3050')   # mid rose band
C_COVER_ACCENT   = HexColor('#F4A7B9')   # pastel pink accent line

C_HDR_BG         = HexColor('#C4607A')   # rose — meeting header bar
C_HDR_TEXT       = HexColor('#FFF0F3')   # blush white

C_SUBHDR_ACTION  = HexColor('#F4A7B9')   # pastel rose — action items header
C_SUBHDR_TEXT    = HexColor('#5C1A2E')   # deep plum text

C_ROW1           = HexColor('#FFF5F7')   # very light pink
C_ROW2           = HexColor('#FFE8EF')   # soft blush

C_ACTION1        = HexColor('#FFF0F3')   # blush
C_ACTION2        = HexColor('#FFE4EA')   # deeper blush

C_PROG_HDR       = HexColor('#C9A0DC')   # soft lavender-pink
C_PROG1          = HexColor('#F4E8FF')   # light lavender
C_PROG2          = HexColor('#EDD9F7')   # soft orchid

C_LABEL          = HexColor('#9B3A5A')   # warm rose label
C_BORDER         = HexColor('#F4BACB')   # pink border
C_ACCENT_LINE    = HexColor('#C4607A')   # rose divider
C_PAGE_BG        = HexColor('#FFFBFC')   # near-white warm pink
C_FOOTER         = HexColor('#C4607A')

# ── Styles ────────────────────────────────────────────────────────────────────
sty_hdr_left = ParagraphStyle('HdrL',
    fontName='Helvetica-Bold', fontSize=11.5,
    textColor=C_HDR_TEXT, alignment=TA_LEFT, leftIndent=4)

sty_hdr_right = ParagraphStyle('HdrR',
    fontName='Helvetica-Bold', fontSize=11.5,
    textColor=C_HDR_TEXT, alignment=TA_RIGHT, rightIndent=4)

sty_label = ParagraphStyle('Lbl',
    fontName='Helvetica-Bold', fontSize=8.5,
    textColor=C_LABEL, alignment=TA_LEFT)

sty_value = ParagraphStyle('Val',
    fontName='Helvetica', fontSize=9.5,
    textColor=HexColor('#3D1C2E'), alignment=TA_LEFT)

sty_sec = ParagraphStyle('Sec',
    fontName='Helvetica-Bold', fontSize=10,
    textColor=C_SUBHDR_TEXT, alignment=TA_LEFT)

sty_sec_prog = ParagraphStyle('SecP',
    fontName='Helvetica-Bold', fontSize=10,
    textColor=HexColor('#3D1C2E'), alignment=TA_LEFT)

sty_item = ParagraphStyle('Item',
    fontName='Helvetica', fontSize=10.5,
    textColor=HexColor('#3D1C2E'), leftIndent=8, spaceAfter=2)

sty_bullet = ParagraphStyle('Bul',
    fontName='Helvetica', fontSize=10.5,
    textColor=HexColor('#3D1C2E'), leftIndent=8, spaceAfter=2)

# ── Full-page cover Flowable ──────────────────────────────────────────────────
class CoverPage(Flowable):
    def __init__(self):
        Flowable.__init__(self)
        self.width  = W
        self.height = H

    def wrap(self, availW, availH):
        return (W, H)

    def draw(self):
        c = self.canv
        c.saveState()

        # Background
        c.setFillColor(C_COVER_BG)
        c.rect(-2*cm, -2*cm, W + 4*cm, H + 4*cm, fill=1, stroke=0)

        # Mid decorative band
        c.setFillColor(C_COVER_BAND)
        c.rect(-2*cm, H*0.3, W + 4*cm, H*0.15, fill=1, stroke=0)

        # Bottom gradient bands
        c.setFillColor(HexColor('#5C2040'))
        c.rect(-2*cm, -2*cm, W + 4*cm, H*0.22, fill=1, stroke=0)

        # Accent lines (pink)
        c.setStrokeColor(C_COVER_ACCENT)
        c.setLineWidth(2)
        c.line(3*cm, H*0.63, W - 3*cm, H*0.63)
        c.setLineWidth(0.5)
        c.line(3*cm, H*0.61, W - 3*cm, H*0.61)

        # ── AEGIS (big title) ──────────────────────────────────────────────
        c.setFont('Helvetica-Bold', 54)
        c.setFillColor(HexColor('#F4A7B9'))
        c.drawCentredString(W/2, H*0.76, 'AEGIS')

        # ── Subtitle ──────────────────────────────────────────────────────
        c.setFont('Helvetica', 16)
        c.setFillColor(HexColor('#F0D0DA'))
        c.drawCentredString(W/2, H*0.70, 'Child Safety Band')

        # ── FYP line ──────────────────────────────────────────────────────
        c.setFont('Helvetica', 12)
        c.setFillColor(HexColor('#D4A0B0'))
        c.drawCentredString(W/2, H*0.65, 'FYP / II  —  Meeting Records')

        # ── Main heading ──────────────────────────────────────────────────
        c.setFont('Helvetica-Bold', 22)
        c.setFillColor(HexColor('#FFF0F3'))
        c.drawCentredString(W/2, H*0.46, 'Meeting Forms  11 – 20')

        # ── Sub-heading ───────────────────────────────────────────────────
        c.setFont('Helvetica', 11)
        c.setFillColor(HexColor('#F4A7B9'))
        c.drawCentredString(W/2, H*0.41, 'with Supervisor Remarks & Progress Notes')

        # ── Info block ────────────────────────────────────────────────────
        c.setFont('Helvetica', 10)
        c.setFillColor(HexColor('#D4A0B0'))
        c.drawCentredString(W/2, H*0.25, 'Supervisor:   Dr. Altaf Hussain')
        c.drawCentredString(W/2, H*0.21, 'Members:   Barira Sarfraz   |   Nabeeha Zahid')
        c.drawCentredString(W/2, H*0.17, 'Reg. No.:   222201044   |   222201009')

        # ── Date range ────────────────────────────────────────────────────
        c.setFont('Helvetica', 9.5)
        c.setFillColor(HexColor('#B07A90'))
        c.drawCentredString(W/2, H*0.11, '21 April 2026  –  18 June 2026')

        # thin rule above date
        c.setStrokeColor(HexColor('#7A3050'))
        c.setLineWidth(0.5)
        c.line(W/2 - 3*cm, H*0.135, W/2 + 3*cm, H*0.135)

        c.restoreState()


# ── Page background + footer ─────────────────────────────────────────────────
def on_page(canv, doc):
    canv.saveState()
    canv.setFillColor(C_PAGE_BG)
    canv.rect(0, 0, W, H, fill=1, stroke=0)
    canv.setStrokeColor(HexColor('#F4BACB'))
    canv.setLineWidth(0.5)
    canv.line(2*cm, 1.4*cm, W - 2*cm, 1.4*cm)
    canv.setFont('Helvetica', 8)
    canv.setFillColor(C_FOOTER)
    canv.drawCentredString(W/2, 0.9*cm, 'AEGIS — Child Safety Band   |   FYP Meeting Records')
    canv.drawRightString(W - 2*cm, 0.9*cm, f'Page {doc.page}')
    canv.restoreState()

def on_first_page(canv, doc):
    # cover page has its own background drawn by CoverPage flowable
    pass


# ── Build one meeting block (fills a full page) ───────────────────────────────
def build_meeting_block(m):
    col_w = W - 4*cm

    # ── Header bar ────────────────────────────────────────────────────────
    hdr = Table([[
        Paragraph(f'Meeting Form No.  {m["form"]}', sty_hdr_left),
        Paragraph(f'Date:  {m["date"]}   &nbsp;&nbsp;   Time:  {m["time"]}', sty_hdr_right),
    ]], colWidths=[col_w*0.44, col_w*0.56])
    hdr.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), C_HDR_BG),
        ('TOPPADDING',    (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ('LEFTPADDING',   (0,0), (0,0),   12),
        ('RIGHTPADDING',  (1,0), (1,0),   12),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('LINEBELOW', (0,0), (-1,-1), 2, C_COVER_ACCENT),
    ]))

    # ── Info rows ─────────────────────────────────────────────────────────
    info = Table([
        [Paragraph('Project Title', sty_label),
         Paragraph('AEGIS — Child Safety Band', sty_value),
         Paragraph('Supervisor', sty_label),
         Paragraph('Dr. Altaf Hussain', sty_value)],
        [Paragraph('Members', sty_label),
         Paragraph('Barira Sarfraz  &nbsp;|&nbsp;  Nabeeha Zahid', sty_value),
         Paragraph('Reg. No.', sty_label),
         Paragraph('222201044  &nbsp;|&nbsp;  222201009', sty_value)],
    ], colWidths=[col_w*0.14, col_w*0.36, col_w*0.14, col_w*0.36])
    info.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), C_ROW1),
        ('BACKGROUND', (0,1), (-1,1), C_ROW2),
        ('TOPPADDING',    (0,0), (-1,-1), 7),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
        ('LEFTPADDING',   (0,0), (-1,-1), 10),
        ('GRID', (0,0), (-1,-1), 0.5, C_BORDER),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))

    # ── Action Items ──────────────────────────────────────────────────────
    ai_hdr = Table([[Paragraph('  Action Items', sty_sec)]],
                   colWidths=[col_w])
    ai_hdr.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), C_SUBHDR_ACTION),
        ('TOPPADDING', (0,0), (-1,-1), 7),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('GRID', (0,0), (-1,-1), 0.5, C_BORDER),
    ]))

    ai_rows = [[Paragraph(f'  {i+1}.  {txt}', sty_item)]
               for i, txt in enumerate(m['action_items'])]
    ai_body = Table(ai_rows, colWidths=[col_w])
    ai_style = [
        ('TOPPADDING',    (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LEFTPADDING',   (0,0), (-1,-1), 14),
        ('GRID', (0,0), (-1,-1), 0.4, C_BORDER),
    ]
    for i in range(len(ai_rows)):
        ai_style.append(('BACKGROUND', (0,i), (0,i), C_ACTION1 if i%2==0 else C_ACTION2))
    ai_body.setStyle(TableStyle(ai_style))

    # ── Progress / Supervisor Remarks ─────────────────────────────────────
    prev = m['form'] - 1
    prog_hdr = Table([[Paragraph(
        f'  Progress on Previous Items'
        f'<font color="#7A3050" size="8.5">  (Supervisor Remarks — based on Form {prev} action items)</font>',
        sty_sec_prog)]],
        colWidths=[col_w])
    prog_hdr.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), C_PROG_HDR),
        ('TOPPADDING', (0,0), (-1,-1), 7),
        ('BOTTOMPADDING', (0,0), (-1,-1), 7),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('GRID', (0,0), (-1,-1), 0.5, HexColor('#BF8FD0')),
    ]))

    prog_rows = [[Paragraph(f'  •  {r}', sty_bullet)]
                 for r in m['remarks']]
    prog_body = Table(prog_rows, colWidths=[col_w])
    prog_style = [
        ('TOPPADDING',    (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LEFTPADDING',   (0,0), (-1,-1), 16),
        ('GRID', (0,0), (-1,-1), 0.4, HexColor('#BF8FD0')),
    ]
    for i in range(len(prog_rows)):
        prog_style.append(('BACKGROUND', (0,i), (0,i), C_PROG1 if i%2==0 else C_PROG2))
    prog_body.setStyle(TableStyle(prog_style))

    return [
        Spacer(1, 0.3*cm),
        hdr,
        Spacer(1, 0.15*cm),
        info,
        Spacer(1, 0.4*cm),
        ai_hdr,
        ai_body,
        Spacer(1, 0.4*cm),
        prog_hdr,
        prog_body,
        PageBreak(),
    ]


# ── Data ─────────────────────────────────────────────────────────────────────
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

# ── Assemble ──────────────────────────────────────────────────────────────────
out = 'forms/AEGIS Meeting Forms 11-20.pdf'

doc = SimpleDocTemplate(
    out,
    pagesize=A4,
    leftMargin=2*cm, rightMargin=2*cm,
    topMargin=2*cm, bottomMargin=2*cm,
    title='AEGIS Meeting Forms 11–20',
    author='AEGIS Team',
)

def on_first_page(canv, doc):
    # Draw cover entirely on the canvas — no story elements on page 1
    canv.saveState()
    # Background
    canv.setFillColor(C_COVER_BG)
    canv.rect(0, 0, W, H, fill=1, stroke=0)
    # Mid band
    canv.setFillColor(HexColor('#5C2040'))
    canv.rect(0, H*0.30, W, H*0.16, fill=1, stroke=0)
    # Bottom band
    canv.setFillColor(HexColor('#4A1830'))
    canv.rect(0, 0, W, H*0.22, fill=1, stroke=0)
    # Accent lines
    canv.setStrokeColor(C_COVER_ACCENT)
    canv.setLineWidth(2)
    canv.line(3*cm, H*0.635, W - 3*cm, H*0.635)
    canv.setLineWidth(0.5)
    canv.line(3*cm, H*0.615, W - 3*cm, H*0.615)
    # AEGIS title
    canv.setFont('Helvetica-Bold', 58)
    canv.setFillColor(HexColor('#F4A7B9'))
    canv.drawCentredString(W/2, H*0.76, 'AEGIS')
    # Child Safety Band
    canv.setFont('Helvetica', 17)
    canv.setFillColor(HexColor('#F0D0DA'))
    canv.drawCentredString(W/2, H*0.70, 'Child Safety Band')
    # FYP line
    canv.setFont('Helvetica', 12)
    canv.setFillColor(HexColor('#D4A0B0'))
    canv.drawCentredString(W/2, H*0.655, 'FYP / II  —  Meeting Records')
    # Main heading
    canv.setFont('Helvetica-Bold', 24)
    canv.setFillColor(HexColor('#FFF0F3'))
    canv.drawCentredString(W/2, H*0.46, 'Meeting Forms  11 – 20')
    # Sub-heading
    canv.setFont('Helvetica', 11.5)
    canv.setFillColor(HexColor('#F4A7B9'))
    canv.drawCentredString(W/2, H*0.41, 'with Supervisor Remarks & Progress Notes')
    # Info
    canv.setFont('Helvetica', 10.5)
    canv.setFillColor(HexColor('#D4A0B0'))
    canv.drawCentredString(W/2, H*0.255, 'Supervisor:   Dr. Altaf Hussain')
    canv.drawCentredString(W/2, H*0.215, 'Members:   Barira Sarfraz   |   Nabeeha Zahid')
    canv.drawCentredString(W/2, H*0.175, 'Reg. No.:   222201044   |   222201009')
    # Date rule
    canv.setStrokeColor(HexColor('#7A3050'))
    canv.setLineWidth(0.5)
    canv.line(W/2 - 3.5*cm, H*0.135, W/2 + 3.5*cm, H*0.135)
    canv.setFont('Helvetica', 9.5)
    canv.setFillColor(HexColor('#A06880'))
    canv.drawCentredString(W/2, H*0.105, '21 April 2026  –  18 June 2026')
    canv.restoreStyle() if hasattr(canv, 'restoreStyle') else None
    canv.restoreState()


story = []
# Page 1 = cover (drawn by onFirstPage); story starts with a PageBreak to push to page 2
story.append(PageBreak())

# One form per page
for m in meetings:
    story.extend(build_meeting_block(m))

doc.build(story, onFirstPage=on_first_page, onLaterPages=on_page)
print(f'Saved: {out}')
