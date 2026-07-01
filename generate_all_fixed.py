import copy
from docx import Document
from docx.shared import Pt, RGBColor, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
from lxml import etree as ET

# ─────────────────────────────────────────────────────────────────────────────
# DATA
# action_items  → what goes into Meeting Form N itself
# progress      → what goes into "Progress on previous Items" section
#                 (i.e. progress made on the PREVIOUS meeting's action items)
# ─────────────────────────────────────────────────────────────────────────────

meetings = [
    {
        'form': 11, 'date': '21 April, 2026', 'time': '10:30 AM',
        'action_items': [
            'Get Firebase connected to the Flutter app — Firestore and Auth set up.',
            'Agree on a folder structure and clean up the pubspec dependencies.',
            'Sketch out a rough plan for what we are building across the app, firmware, and ML.',
        ],
        # Progress on Form 10's action items (diagrams review)
        'progress': [
            'Diagrams were gone through and updated — the sequence diagram now shows the BLE flow more clearly.',
            'Use-case diagram was adjusted to reflect panel feedback; supervisor confirmed it matches the defended concept.',
            'All design-phase material is wrapped up and ready for submission.',
        ],
    },
    {
        'form': 12, 'date': '28 April, 2026', 'time': '11:00 AM',
        'action_items': [
            'Set up the bottom nav bar and make sure routing works across all five screens.',
            'Build out basic page layouts for Home, Map, Alerts, Profile, and Settings.',
            'Go over the screens and check they match the Velvet Night design we have been following.',
        ],
        # Progress on Form 11's action items (Firebase/setup)
        'progress': [
            'Firebase is connected and both Firestore and Authentication are up and running in the app.',
            'Folder structure is sorted and pubspec.yaml has all the packages we need.',
            'Dev plan is drafted — covers the app, firmware, and ML model work in phases.',
        ],
    },
    {
        'form': 13, 'date': '07 May, 2026', 'time': '10:00 AM',
        'action_items': [
            'Get email and password login and signup working with Firebase Auth.',
            'Add field validation and keep the user logged in after closing the app.',
            'Test the full sign-in and sign-out flow on the emulator and a real phone.',
        ],
        # Progress on Form 12's action items (nav/layouts)
        'progress': [
            'Bottom nav bar is set up and routing between all five screens is working fine.',
            'Page layouts for all five screens are in place with consistent styling throughout.',
            'Went through the designs against Velvet Night tokens — fixed spacing and colours where they were off.',
        ],
    },
    {
        'form': 14, 'date': '13 May, 2026', 'time': '11:30 AM',
        'action_items': [
            'Add Google Maps and show the child\'s live position on the tracking screen.',
            'Set up a Firestore listener so the location updates automatically.',
            'Put a proper marker and small avatar on the map so the child is easy to spot.',
        ],
        # Progress on Form 13's action items (auth)
        'progress': [
            'Email and password login and signup are both working end-to-end with Firebase.',
            'Validation, error messages, and session persistence are all in and working properly.',
            'Ran through login, logout, and signup on the emulator and a real phone — all good.',
        ],
    },
    {
        'form': 15, 'date': '20 May, 2026', 'time': '10:30 AM',
        'action_items': [
            'Let the parent draw a safe zone circle on the map and adjust its size.',
            'Save the zone to Firestore so it loads back next time the app opens.',
            'Fire a notification when the child steps outside the safe zone.',
        ],
        # Progress on Form 14's action items (maps/GPS)
        'progress': [
            'Google Maps is in and showing the live location correctly on the tracking screen.',
            'Firestore listener is running and coordinates are coming through with barely any delay.',
            'Custom marker and avatar are showing up properly on the map.',
        ],
    },
    {
        'form': 16, 'date': '26 May, 2026', 'time': '11:00 AM',
        'action_items': [
            'Write firmware to read GPS data from the Neo-6M and send it over BLE.',
            'Broadcast the device ID and coordinates from the ESP32 to the paired phone.',
            'Test it on the real hardware and confirm the Flutter app receives the data correctly.',
        ],
        # Progress on Form 15's action items (safe zone)
        'progress': [
            'Safe zone circle is draggable and resizable — easy to set up from the map screen.',
            'Zone data is saved to Firestore per user and loads back correctly on app launch.',
            'Notification fired correctly when we moved a test location outside the boundary.',
        ],
    },
    {
        'form': 17, 'date': '03 June, 2026', 'time': '10:30 AM',
        'action_items': [
            'Load the TFLite activity model onto the ESP32 and run it on MPU-6050 sensor data.',
            'Normalise the accelerometer readings before passing them to the model.',
            'Verify the model is picking up idle, walking, running, and fall correctly.',
        ],
        # Progress on Form 16's action items (ESP32 GPS/BLE)
        'progress': [
            'ESP32 is reading GPS data from the Neo-6M fine — NMEA parsing is working as expected.',
            'BLE is broadcasting the device ID and GPS payload — verified with a BLE scanner app.',
            'Tested on real hardware — the Flutter app is receiving and parsing the data correctly.',
        ],
    },
    {
        'form': 18, 'date': '09 June, 2026', 'time': '11:00 AM',
        'action_items': [
            'Set up FCM so parents get push alerts when something happens.',
            'Make sure all three alerts fire — safe zone exit, fall detected, and low battery.',
            'Add an alert history screen in the app showing what happened and when.',
        ],
        # Progress on Form 17's action items (TFLite)
        'progress': [
            'TFLite model is running on the ESP32 and giving output in real time from the sensor.',
            'Preprocessing pipeline is working — readings are normalised before going into the model.',
            'Tested against real movements — activity labels and fall detection are coming out at a reasonable accuracy.',
        ],
    },
    {
        'form': 19, 'date': '16 June, 2026', 'time': '10:00 AM',
        'action_items': [
            'Run a full end-to-end test on the BLE link between the band and the app.',
            'Stress-test the Firestore sync to see how it holds up with live location data.',
            'Write down any bugs we find and plan fixes for the next session.',
        ],
        # Progress on Form 18's action items (FCM/alerts)
        'progress': [
            'FCM is set up and push notifications are reaching the parent\'s device correctly.',
            'All three alert types — safe zone exit, fall, and low battery — are triggering fine in testing.',
            'Alert history screen is done and showing the right entries from Firestore with timestamps.',
        ],
    },
    {
        'form': 20, 'date': '18 June, 2026', 'time': '11:30 AM',
        'action_items': [
            'Walk through the whole system — hardware, firmware, and the app — and review everything.',
            'Finalise the demo script and any remaining documentation for FYP submission.',
            'Confirm everything is in order and the project is ready for the final evaluation.',
        ],
        # Progress on Form 19's action items (integration testing)
        'progress': [
            'Full BLE pipeline tested — found and fixed a packet-loss bug in the handler.',
            'Firestore sync held up under load — updates and alerts are within acceptable response times.',
            'All bugs from testing were fixed; system is stable and ready for the final evaluation.',
        ],
    },
]


# ─────────────────────────────────────────────────────────────────────────────
# PART 1 — Regenerate Meeting Forms 11-20 with natural action items
# ─────────────────────────────────────────────────────────────────────────────

def add_bullet_paragraph(tc, text, template_para):
    new_p = copy.deepcopy(template_para._element)
    for r in new_p.findall(qn('w:r')):
        new_p.remove(r)
    for ins in new_p.findall(qn('w:ins')):
        new_p.remove(ins)
    r_elem = copy.deepcopy(template_para.runs[0]._element)
    for t in r_elem.findall(qn('w:t')):
        r_elem.remove(t)
    t_elem = ET.SubElement(r_elem, qn('w:t'))
    t_elem.text = text
    t_elem.set('{http://www.w3.org/XML/1998/namespace}space', 'preserve')
    new_p.append(r_elem)
    tc.append(new_p)


print('Regenerating Meeting Forms 11-20...')
for entry in meetings:
    doc = Document('forms/Meeting Form 10.docx')
    table = doc.tables[0]

    # Meeting Number
    cell = table.rows[6].cells[1]
    for p in cell.paragraphs:
        for run in p.runs:
            run.text = ''
    if cell.paragraphs[0].runs:
        cell.paragraphs[0].runs[0].text = str(entry['form'])
    else:
        cell.paragraphs[0].add_run(str(entry['form']))

    # Date
    cell_date = table.rows[6].cells[3]
    for p in cell_date.paragraphs:
        for run in p.runs:
            run.text = ''
    if cell_date.paragraphs[0].runs:
        cell_date.paragraphs[0].runs[0].text = entry['date']
    else:
        cell_date.paragraphs[0].add_run(entry['date'])

    # Time
    cell_time = table.rows[6].cells[6]
    for p in cell_time.paragraphs:
        for run in p.runs:
            run.text = ''
    if cell_time.paragraphs[0].runs:
        cell_time.paragraphs[0].runs[0].text = entry['time']
    else:
        cell_time.paragraphs[0].add_run(entry['time'])

    # Action Items
    action_cell = table.rows[9].cells[0]
    template_para = action_cell.paragraphs[0]
    tc = action_cell._tc
    for p in tc.findall(qn('w:p')):
        tc.remove(p)
    for item_text in entry['action_items']:
        add_bullet_paragraph(tc, item_text, template_para)
    end_p = copy.deepcopy(template_para._element)
    for child in list(end_p):
        if child.tag != qn('w:pPr'):
            end_p.remove(child)
    pPr = end_p.find(qn('w:pPr'))
    if pPr is not None:
        numPr = pPr.find(qn('w:numPr'))
        if numPr is not None:
            pPr.remove(numPr)
        pStyle = pPr.find(qn('w:pStyle'))
        if pStyle is not None:
            pStyle.set(qn('w:val'), 'NoSpacing')
    tc.append(end_p)

    filename = f'forms/Meeting Form {entry["form"]}.docx'
    doc.save(filename)
    print(f'  Saved: {filename}')


# ─────────────────────────────────────────────────────────────────────────────
# PART 2 — Regenerate Progress Notes document
# ─────────────────────────────────────────────────────────────────────────────

def set_cell_bg(cell, hex_color):
    tc = cell._tc
    tcPr = tc.find(qn('w:tcPr'))
    if tcPr is None:
        tcPr = OxmlElement('w:tcPr')
        tc.insert(0, tcPr)
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear')
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'), hex_color)
    tcPr.append(shd)


def set_cell_vAlign(cell, align='center'):
    tc = cell._tc
    tcPr = tc.find(qn('w:tcPr'))
    if tcPr is None:
        tcPr = OxmlElement('w:tcPr')
        tc.insert(0, tcPr)
    vAlign = OxmlElement('w:vAlign')
    vAlign.set(qn('w:val'), align)
    tcPr.append(vAlign)


print('\nGenerating Progress Notes document...')
doc = Document()
section = doc.sections[0]
section.top_margin = Cm(1.8)
section.bottom_margin = Cm(1.8)
section.left_margin = Cm(2.2)
section.right_margin = Cm(2.2)

# Title
title_p = doc.add_paragraph()
title_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = title_p.add_run('AEGIS — Child Safety Band')
r.bold = True
r.font.size = Pt(13)

sub_p = doc.add_paragraph()
sub_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r2 = sub_p.add_run('Progress on Previous Items  |  Meeting Forms 11 – 20')
r2.bold = True
r2.font.size = Pt(11)

sub_p2 = doc.add_paragraph()
sub_p2.alignment = WD_ALIGN_PARAGRAPH.CENTER
r3 = sub_p2.add_run('(To be reviewed and signed by Dr. Altaf Hussain)')
r3.italic = True
r3.font.size = Pt(9.5)
r3.font.color.rgb = RGBColor(0x55, 0x55, 0x55)

doc.add_paragraph()

for idx, entry in enumerate(meetings):
    form_no   = entry['form']
    prev_form = form_no - 1
    date      = entry['date']
    progress  = entry['progress']

    # One table per meeting — 5 rows
    # Row 0: meeting header (dark navy)
    # Row 1: "Progress on previous Items (if any)" label (mid-blue, bold)
    # Row 2-4: three progress bullet points
    # Row 5: supervisor comments + signature

    tbl = doc.add_table(rows=6, cols=2)
    tbl.style = 'Table Grid'
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER

    # ── Row 0: header ─────────────────────────────────────────────────────
    hdr = tbl.rows[0]
    # merge cols for left side
    c0 = hdr.cells[0]
    c1 = hdr.cells[1]
    set_cell_bg(c0, '1F3864')
    set_cell_bg(c1, '1F3864')

    p0 = c0.paragraphs[0]
    r = p0.add_run(f'Meeting Form No.  {form_no}')
    r.bold = True; r.font.size = Pt(10); r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)

    p1 = c1.paragraphs[0]
    p1.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    r = p1.add_run(f'Date:  {date}')
    r.bold = True; r.font.size = Pt(10); r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)

    # ── Row 1: section label ──────────────────────────────────────────────
    label_cell = tbl.rows[1].cells[0]
    set_cell_bg(label_cell, 'D6E4F7')
    set_cell_bg(tbl.rows[1].cells[1], 'D6E4F7')
    lp = label_cell.paragraphs[0]
    r = lp.add_run(f'Progress on previous Items (if any)   [Based on action items from Meeting Form {prev_form}]')
    r.bold = True
    r.font.size = Pt(9.5)

    # ── Rows 2-4: progress bullet points ──────────────────────────────────
    for i, note in enumerate(progress):
        row = tbl.rows[2 + i]
        # merge both cols visually by setting same background and spanning text
        c_left  = row.cells[0]
        c_right = row.cells[1]
        set_cell_bg(c_right, 'FFFFFF')
        bp = c_left.paragraphs[0]
        bp.paragraph_format.left_indent = Pt(8)
        r = bp.add_run(f'{i+1}.  {note}')
        r.font.size = Pt(9.5)
        # clear right cell
        c_right.paragraphs[0].clear()

    # ── Row 5: supervisor comments + signature ─────────────────────────────
    sig_row = tbl.rows[5]
    sc0 = sig_row.cells[0]
    sc1 = sig_row.cells[1]

    sp0 = sc0.paragraphs[0]
    r = sp0.add_run("Supervisor's Comments:")
    r.bold = True; r.font.size = Pt(9)
    sc0.add_paragraph()   # blank line for writing

    sp1 = sc1.paragraphs[0]
    sp1.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    r = sp1.add_run("Supervisor's Signature:")
    r.bold = True; r.font.size = Pt(9)
    sc1.add_paragraph()
    sig_line = sc1.add_paragraph()
    sig_line.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    r = sig_line.add_run('_______________________________')
    r.font.size = Pt(9)

    # Set column widths
    tbl.columns[0].width = Cm(10)
    tbl.columns[1].width = Cm(7)

    # spacer between entries
    spacer = doc.add_paragraph()
    spacer.paragraph_format.space_after = Pt(6)

out = 'forms/Progress Notes (Forms 11-20)_new.docx'
doc.save(out)
print(f'  Saved: {out}')
print('\nAll done!')
