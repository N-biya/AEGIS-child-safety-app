#!/usr/bin/env python3
"""
AEGIS Document Formatter
Applies all rules from DOCUMENT_EDITING_RULES.md to AEGIS_with_diagramss.docx
Output: AEGIS_formatted.docx  |  Backup: AEGIS_with_diagramss_BACKUP.docx
"""
import sys, io, re, shutil, copy
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

from docx import Document
from docx.shared import Pt, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

INPUT  = r'e:\FypApp\AEGIS_with_diagramss.docx'
OUTPUT = r'e:\FypApp\AEGIS_formatted.docx'
BACKUP = r'e:\FypApp\AEGIS_with_diagramss_BACKUP.docx'

# ── Document knowledge ────────────────────────────────────────────────────────

# These Heading 3 paragraphs are TOP-LEVEL chapter headings (16 pt, new page)
CHAPTER_HEADINGS = {
    'Introduction',
    'Background Information',
    'Related Work and Literature Review',
    'System Design',
}

# Preliminary-section "Titles" style headings (16 pt, no new page except after cover)
PRELIM_TITLES = {'AUTHORS DECLARATION', 'CERTIFICATE', 'DEDICATION'}

# Figure captions in document order
FIGURE_TITLES = [
    'Use Case Diagram',
    'Architecture Diagram',
    'Entity Relationship Diagram',
    'Activity Diagram',
    'Sequence Diagram',
    'Class Diagram',
]

# Table captions keyed by table index in doc.tables
TABLE_CAPTIONS = {
    1: 'Board of Examiners',
    2: 'Comparison of Existing Child Safety Solutions',
    3: 'Use Case Flow: View Real-Time Vitals',
    4: 'Use Case Flow: Monitor Heart Rate and SpO2',
    5: 'Use Case Flow: Monitor Body Temperature',
    6: 'Use Case Flow: Monitor Stress Level (GSR)',
    7: 'Use Case Flow: View Live Location and History',
}

# All abbreviations with definitions
ABBREV_ALL = {
    'AEGIS': 'Advanced Emergency Guardian and Intelligent Safety',
    'API':   'Application Programming Interface',
    'BLE':   'Bluetooth Low Energy',
    'BPM':   'Beats Per Minute',
    'CSV':   'Comma-Separated Values',
    'ESP32': 'Espressif Systems 32-bit Microcontroller',
    'FIFO':  'First In First Out',
    'GDOP':  'Geometric Dilution of Precision',
    'GPS':   'Global Positioning System',
    'GPRS':  'General Packet Radio Service',
    'GSM':   'Global System for Mobile Communications',
    'GSR':   'Galvanic Skin Response',
    'HAL':   'Hardware Abstraction Layer',
    'HTTP':  'HyperText Transfer Protocol',
    'HTTPS': 'HyperText Transfer Protocol Secure',
    'I2C':   'Inter-Integrated Circuit',
    'IoT':   'Internet of Things',
    'IST':   'Institute of Space Technology',
    'JSON':  'JavaScript Object Notation',
    'JWT':   'JSON Web Token',
    'Li-Po': 'Lithium Polymer',
    'MEMS':  'Micro-Electromechanical Systems',
    'ML':    'Machine Learning',
    'MQTT':  'Message Queuing Telemetry Transport',
    'MVVM':  'Model-View-ViewModel',
    'NMEA':  'National Marine Electronics Association',
    'PKR':   'Pakistan Rupee',
    'PPG':   'Photoplethysmography',
    'REST':  'Representational State Transfer',
    'RMSSD': 'Root Mean Square of Successive Differences',
    'SDNN':  'Standard Deviation of NN Intervals',
    'SMS':   'Short Message Service',
    'SpO2':  'Peripheral Oxygen Saturation',
    'TLS':   'Transport Layer Security',
    'UART':  'Universal Asynchronous Receiver-Transmitter',
    'UI':    'User Interface',
    'URL':   'Uniform Resource Locator',
    'USB':   'Universal Serial Bus',
    'WiFi':  'Wireless Fidelity',
    'XML':   'Extensible Markup Language',
}

# ── XML helpers ───────────────────────────────────────────────────────────────

TNR = 'Times New Roman'

def _sz(pt): return str(int(pt * 2))

def _apply_rfonts(elem, name):
    for x in elem.findall(qn('w:rFonts')): elem.remove(x)
    rf = OxmlElement('w:rFonts')
    rf.set(qn('w:ascii'), name); rf.set(qn('w:hAnsi'), name); rf.set(qn('w:cs'), name)
    elem.insert(0, rf)

def _apply_sz(elem, pt):
    for x in elem.findall(qn('w:sz')): elem.remove(x)
    for x in elem.findall(qn('w:szCs')): elem.remove(x)
    s = OxmlElement('w:sz'); s.set(qn('w:val'), _sz(pt)); elem.append(s)
    sc = OxmlElement('w:szCs'); sc.set(qn('w:val'), _sz(pt)); elem.append(sc)

def _apply_bold(elem, bold):
    for x in elem.findall(qn('w:b')): elem.remove(x)
    b = OxmlElement('w:b')
    if not bold: b.set(qn('w:val'), '0')
    elem.append(b)

def format_run(run, pt, bold=None):
    rPr = run._element.get_or_add_rPr()
    _apply_rfonts(rPr, TNR)
    _apply_sz(rPr, pt)
    if bold is not None: _apply_bold(rPr, bold)

def format_para_mark(para, pt, bold=False):
    pPr = para._element.get_or_add_pPr()
    rPr = pPr.find(qn('w:rPr'))
    if rPr is None:
        rPr = OxmlElement('w:rPr'); pPr.append(rPr)
    _apply_rfonts(rPr, TNR)
    _apply_sz(rPr, pt)
    _apply_bold(rPr, bold)

def set_spacing(para, lines, before=0, after=0):
    pPr = para._element.get_or_add_pPr()
    for x in pPr.findall(qn('w:spacing')): pPr.remove(x)
    sp = OxmlElement('w:spacing')
    sp.set(qn('w:line'), str(int(240 * lines)))
    sp.set(qn('w:lineRule'), 'auto')
    sp.set(qn('w:before'), str(int(before * 20)))
    sp.set(qn('w:after'),  str(int(after  * 20)))
    pPr.append(sp)

def add_page_break_before(para):
    pPr = para._element.get_or_add_pPr()
    for x in pPr.findall(qn('w:pageBreakBefore')): pPr.remove(x)
    pb = OxmlElement('w:pageBreakBefore'); pb.set(qn('w:val'), '1'); pPr.append(pb)

def remove_page_break_before(para):
    pPr = para._element.get_or_add_pPr()
    for x in pPr.findall(qn('w:pageBreakBefore')): pPr.remove(x)

def make_page_num_field_para(doc_obj, num_format='decimal', start=1):
    """Create a centered PAGE field paragraph for footer."""
    p = OxmlElement('w:p')
    pPr = OxmlElement('w:pPr')
    jc = OxmlElement('w:jc'); jc.set(qn('w:val'), 'center')
    pPr.append(jc); p.append(pPr)

    def field_run(text, ftype=None, is_instr=False):
        r = OxmlElement('w:r')
        if ftype:
            fc = OxmlElement('w:fldChar'); fc.set(qn('w:fldCharType'), ftype); r.append(fc)
        elif is_instr:
            it = OxmlElement('w:instrText')
            it.set(qn('xml:space'), 'preserve'); it.text = text; r.append(it)
        else:
            t = OxmlElement('w:t'); t.text = text; r.append(t)
        return r

    p.append(field_run(None, ftype='begin'))
    p.append(field_run(' PAGE ', is_instr=True))
    p.append(field_run(None, ftype='end'))
    return p

def set_section_page_num(section, fmt, start):
    sectPr = section._sectPr
    for x in sectPr.findall(qn('w:pgNumType')): sectPr.remove(x)
    pnt = OxmlElement('w:pgNumType')
    pnt.set(qn('w:fmt'), fmt); pnt.set(qn('w:start'), str(start))
    sectPr.append(pnt)

def clear_footer_page_num(section):
    """Remove page number display from footer (for cover page)."""
    sectPr = section._sectPr
    # titlePg suppresses first-page footer when enabled with a blank first footer
    tp = sectPr.find(qn('w:titlePg'))
    if tp is None:
        tp = OxmlElement('w:titlePg'); sectPr.append(tp)

def make_simple_para(text, style_val, pt, bold=False, align='left', spacing=1.5):
    """Create a new w:p element with given text and font."""
    p = OxmlElement('w:p')
    pPr = OxmlElement('w:pPr')
    ps = OxmlElement('w:pStyle'); ps.set(qn('w:val'), style_val); pPr.append(ps)
    jc_map = {'left': 'left', 'center': 'center', 'justify': 'both'}
    jc = OxmlElement('w:jc'); jc.set(qn('w:val'), jc_map.get(align, 'left')); pPr.append(jc)
    sp = OxmlElement('w:spacing')
    sp.set(qn('w:line'), str(int(240 * spacing))); sp.set(qn('w:lineRule'), 'auto')
    sp.set(qn('w:before'), '0'); sp.set(qn('w:after'), '0'); pPr.append(sp)
    # Para mark rPr
    rPr_pmark = OxmlElement('w:rPr')
    rf = OxmlElement('w:rFonts'); rf.set(qn('w:ascii'), TNR); rf.set(qn('w:hAnsi'), TNR); rf.set(qn('w:cs'), TNR)
    rPr_pmark.append(rf)
    s = OxmlElement('w:sz'); s.set(qn('w:val'), _sz(pt)); rPr_pmark.append(s)
    sc = OxmlElement('w:szCs'); sc.set(qn('w:val'), _sz(pt)); rPr_pmark.append(sc)
    if bold: b = OxmlElement('w:b'); rPr_pmark.append(b)
    pPr.append(rPr_pmark)
    p.append(pPr)
    # Run
    r = OxmlElement('w:r')
    rPr = OxmlElement('w:rPr')
    rf2 = OxmlElement('w:rFonts'); rf2.set(qn('w:ascii'), TNR); rf2.set(qn('w:hAnsi'), TNR); rf2.set(qn('w:cs'), TNR)
    rPr.append(rf2)
    s2 = OxmlElement('w:sz'); s2.set(qn('w:val'), _sz(pt)); rPr.append(s2)
    sc2 = OxmlElement('w:szCs'); sc2.set(qn('w:val'), _sz(pt)); rPr.append(sc2)
    if bold: b2 = OxmlElement('w:b'); rPr.append(b2)
    r.append(rPr)
    t = OxmlElement('w:t'); t.set(qn('xml:space'), 'preserve'); t.text = text; r.append(t)
    p.append(r)
    return p

# ── Abbreviation scan ─────────────────────────────────────────────────────────

def find_used_abbreviations(doc):
    """Scan body text (excluding abbrev section itself) for each abbreviation."""
    body_parts = []
    skip = False
    for para in doc.paragraphs:
        t = para.text
        if 'List of Abbreviations' in t and para.style.name.startswith('Heading'):
            skip = True; continue
        if skip and para.style.name.startswith('Heading') and 'Abbreviations' not in t:
            skip = False
        if not skip:
            body_parts.append(t)
    body = '\n'.join(body_parts)

    used = {'AEGIS': ABBREV_ALL['AEGIS']}  # always include AEGIS
    for abbr, full in ABBREV_ALL.items():
        if abbr == 'AEGIS': continue
        pattern = r'\b' + re.escape(abbr) + r'\b'
        if re.search(pattern, body, re.IGNORECASE if len(abbr) > 4 else 0):
            used[abbr] = full
    return dict(sorted(used.items()))

# ── Table caption helpers ─────────────────────────────────────────────────────

def find_body_children(doc):
    """Return list of (type, element) for all top-level body children."""
    body = doc.element.body
    result = []
    for child in body:
        tag = child.tag.split('}')[-1] if '}' in child.tag else child.tag
        result.append((tag, child))
    return result

def insert_para_after_element(doc, ref_elem, new_para_elem):
    """Insert new_para_elem immediately after ref_elem in the document body."""
    body = doc.element.body
    children = list(body)
    idx = children.index(ref_elem)
    body.insert(idx + 1, new_para_elem)

# ── Main formatter ────────────────────────────────────────────────────────────

def main():
    shutil.copy2(INPUT, BACKUP)
    print(f'[OK] Backup: {BACKUP}')

    doc = Document(INPUT)

    # ── 1. Page margins ──────────────────────────────────────────────────────
    for sec in doc.sections:
        sec.left_margin   = Inches(1.5)
        sec.right_margin  = Inches(1.0)
        sec.top_margin    = Inches(1.0)
        sec.bottom_margin = Inches(1.0)
    print('[OK] Margins set')

    # ── 2. Find used abbreviations ───────────────────────────────────────────
    used_abbrevs = find_used_abbreviations(doc)
    print(f'[OK] Used abbreviations ({len(used_abbrevs)}): {", ".join(used_abbrevs.keys())}')

    # ── 3. Format all paragraphs ─────────────────────────────────────────────
    fig_num = 0
    toc_section = False   # are we in TOC/List-of-Figures section

    for i, para in enumerate(doc.paragraphs):
        sname = para.style.name
        text  = para.text.strip()

        # Track TOC section for 1.0 spacing
        if text in ('List of Figures', 'List of Tables', 'List of Abbreviations') and sname.startswith('Heading'):
            toc_section = True
        elif toc_section and sname.startswith('Heading') and text not in ('List of Figures', 'List of Tables', 'List of Abbreviations'):
            toc_section = False

        # Classify
        is_chapter = (
            (sname == 'Heading 3' and text in CHAPTER_HEADINGS) or
            sname == 'Heading 1' or
            (sname == 'Titles' and text in PRELIM_TITLES)
        )
        is_subheading  = sname in ('Heading 2', 'Heading 3') and not is_chapter
        is_toc_entry   = sname == 'table of figures' or toc_section
        is_caption     = sname == 'Caption'
        is_cover       = i <= 16

        # Font size & alignment
        if is_chapter:
            pt = 16; bold = True;  align = WD_ALIGN_PARAGRAPH.CENTER
        elif is_subheading:
            pt = 14; bold = True;  align = WD_ALIGN_PARAGRAPH.LEFT
        elif is_caption:
            pt = 12; bold = True;  align = WD_ALIGN_PARAGRAPH.CENTER
        elif is_toc_entry:
            pt = 12; bold = False; align = WD_ALIGN_PARAGRAPH.LEFT
        elif is_cover:
            pt = 12; bold = False; align = WD_ALIGN_PARAGRAPH.CENTER
        else:
            pt = 12; bold = False; align = WD_ALIGN_PARAGRAPH.JUSTIFY

        # Apply alignment
        para.alignment = align

        # Apply font to all runs
        for run in para.runs:
            format_run(run, pt, bold=bold if (is_chapter or is_subheading or is_caption) else False)

        # Apply paragraph mark formatting
        format_para_mark(para, pt, bold=(is_chapter or is_subheading or is_caption))

        # Line spacing
        if is_toc_entry:
            set_spacing(para, 1.0)
        elif is_chapter:
            set_spacing(para, 1.5, before=12, after=6)
        elif is_subheading:
            set_spacing(para, 1.5, before=6, after=3)
        else:
            set_spacing(para, 1.5)

        # Page break before each chapter
        if is_chapter and i > 0:
            add_page_break_before(para)
        elif not is_chapter:
            remove_page_break_before(para)

        # Fix figure captions (static numbering)
        if is_caption and 'Figure' in text:
            fig_num += 1
            title = FIGURE_TITLES[fig_num - 1] if fig_num <= len(FIGURE_TITLES) else f'Figure {fig_num}'
            new_text = f'Figure {fig_num}: {title}'
            # Clear all content and rebuild
            for run in para.runs:
                run.text = ''
            # Remove any field code elements inside the paragraph
            p_elem = para._element
            for child in list(p_elem):
                tag = child.tag.split('}')[-1] if '}' in child.tag else child.tag
                if tag == 'r':
                    p_elem.remove(child)
            # Add single clean run
            r_elem = OxmlElement('w:r')
            rPr = OxmlElement('w:rPr')
            rf = OxmlElement('w:rFonts'); rf.set(qn('w:ascii'), TNR); rf.set(qn('w:hAnsi'), TNR); rf.set(qn('w:cs'), TNR)
            rPr.append(rf)
            sz = OxmlElement('w:sz'); sz.set(qn('w:val'), '24'); rPr.append(sz)
            szc = OxmlElement('w:szCs'); szc.set(qn('w:val'), '24'); rPr.append(szc)
            b_elem = OxmlElement('w:b'); rPr.append(b_elem)
            r_elem.append(rPr)
            t_elem = OxmlElement('w:t'); t_elem.set(qn('xml:space'), 'preserve'); t_elem.text = new_text
            r_elem.append(t_elem)
            p_elem.append(r_elem)

    print(f'[OK] Paragraphs formatted ({fig_num} figure captions fixed)')

    # ── 4. Fix abbreviations section ─────────────────────────────────────────
    # Find start and end of abbrev section
    abbrev_start_idx = None
    abbrev_end_idx   = None
    for i, para in enumerate(doc.paragraphs):
        if para.text.strip() == 'List of Abbreviations' and para.style.name.startswith('Heading'):
            abbrev_start_idx = i
        elif abbrev_start_idx is not None and para.style.name.startswith('Heading') and i > abbrev_start_idx:
            abbrev_end_idx = i
            break

    if abbrev_start_idx is not None and abbrev_end_idx is not None:
        # Paragraphs to replace
        old_abbrev_paras = doc.paragraphs[abbrev_start_idx + 1 : abbrev_end_idx]

        # Reuse existing paragraphs if enough, else we'll add/remove
        # Strategy: clear texts and rewrite; add/remove as needed
        sorted_abbrevs = sorted(used_abbrevs.items())

        # If we have more existing paragraphs than needed, clear extras
        for j, para in enumerate(old_abbrev_paras):
            if j < len(sorted_abbrevs):
                abbr, full = sorted_abbrevs[j]
                new_text = f'{abbr}\t{full}'
                for run in para.runs:
                    run.text = ''
                p_elem = para._element
                for child in list(p_elem):
                    tag = child.tag.split('}')[-1] if '}' in child.tag else child.tag
                    if tag == 'r':
                        p_elem.remove(child)
                r = OxmlElement('w:r')
                rPr = OxmlElement('w:rPr')
                rf = OxmlElement('w:rFonts'); rf.set(qn('w:ascii'), TNR); rf.set(qn('w:hAnsi'), TNR); rf.set(qn('w:cs'), TNR)
                rPr.append(rf)
                sz_ = OxmlElement('w:sz'); sz_.set(qn('w:val'), '24'); rPr.append(sz_)
                szc_ = OxmlElement('w:szCs'); szc_.set(qn('w:val'), '24'); rPr.append(szc_)
                r.append(rPr)
                t_ = OxmlElement('w:t'); t_.set(qn('xml:space'), 'preserve'); t_.text = new_text
                r.append(t_)
                p_elem.append(r)
                para.alignment = WD_ALIGN_PARAGRAPH.LEFT
                set_spacing(para, 1.5)
                format_para_mark(para, 12)
            else:
                # Remove surplus abbreviation paragraphs
                para._element.getparent().remove(para._element)

        # If we need MORE paragraphs than existed, insert them
        if len(sorted_abbrevs) > len(old_abbrev_paras):
            # Insert additional ones before the end heading
            end_para_elem = doc.paragraphs[abbrev_start_idx + 1 + min(len(old_abbrev_paras), len(sorted_abbrevs))]._element
            body = doc.element.body
            for j in range(len(old_abbrev_paras), len(sorted_abbrevs)):
                abbr, full = sorted_abbrevs[j]
                new_p = make_simple_para(f'{abbr}\t{full}', 'Normal', 12, bold=False, align='left', spacing=1.5)
                body.insert(list(body).index(end_para_elem), new_p)

        print(f'[OK] Abbreviations section rebuilt ({len(sorted_abbrevs)} entries)')
    else:
        print('[WARN] Could not find abbreviations section boundaries')

    # ── 4b. Remove empty Caption placeholder paragraphs from original doc ───
    to_remove = [p for p in doc.paragraphs if p.style.name == 'Caption' and not p.text.strip()]
    for p in to_remove:
        p._element.getparent().remove(p._element)
    print(f'[OK] Removed {len(to_remove)} empty Caption placeholder paragraphs')

    # ── 5. Update List of Figures entries ────────────────────────────────────
    fig_entry_num = 0
    for para in doc.paragraphs:
        if para.style.name == 'table of figures':
            fig_entry_num += 1
            if fig_entry_num <= len(FIGURE_TITLES):
                title = FIGURE_TITLES[fig_entry_num - 1]
                new_text = f'Figure {fig_entry_num}\t{title}'
                p_elem = para._element
                pPr = p_elem.find(qn('w:pPr'))
                # Remove ALL content children (runs, hyperlinks, bookmarks, etc.)
                for child in list(p_elem):
                    tag = child.tag.split('}')[-1] if '}' in child.tag else child.tag
                    if tag != 'pPr':
                        p_elem.remove(child)
                r = OxmlElement('w:r')
                rPr = OxmlElement('w:rPr')
                rf = OxmlElement('w:rFonts'); rf.set(qn('w:ascii'), TNR); rf.set(qn('w:hAnsi'), TNR); rf.set(qn('w:cs'), TNR)
                rPr.append(rf)
                r.append(rPr)
                t_ = OxmlElement('w:t'); t_.set(qn('xml:space'), 'preserve'); t_.text = new_text
                r.append(t_)
                p_elem.append(r)
                set_spacing(para, 1.0)
                para.alignment = WD_ALIGN_PARAGRAPH.LEFT
    print(f'[OK] List of Figures updated ({fig_entry_num} entries)')

    # ── 6. Add table captions + build List of Tables ─────────────────────────
    # Find body children to locate tables
    body = doc.element.body
    body_children = list(body)
    table_count = 0
    table_caption_data = []  # list of (table_num, caption_text)

    i = 0
    while i < len(body_children):
        child = body_children[i]
        tag = child.tag.split('}')[-1] if '}' in child.tag else child.tag
        if tag == 'tbl':
            table_count += 1
            if table_count in TABLE_CAPTIONS:
                cap_text = f'Table {table_count}: {TABLE_CAPTIONS[table_count]}'
                # Check if next sibling is already a caption
                next_elem = body_children[i + 1] if i + 1 < len(body_children) else None
                already_has_caption = False
                if next_elem is not None:
                    nt = next_elem.tag.split('}')[-1] if '}' in next_elem.tag else next_elem.tag
                    if nt == 'p':
                        # Check if it's a Caption-style paragraph
                        pPr = next_elem.find(qn('w:pPr'))
                        if pPr is not None:
                            pStyle = pPr.find(qn('w:pStyle'))
                            if pStyle is not None and 'Caption' in pStyle.get(qn('w:val'), ''):
                                already_has_caption = True

                if not already_has_caption:
                    cap_p = make_simple_para(cap_text, 'Caption', 12, bold=True, align='center', spacing=1.5)
                    idx_in_body = list(body).index(child)
                    body.insert(idx_in_body + 1, cap_p)
                    body_children = list(body)  # refresh after insert

                table_caption_data.append((table_count, TABLE_CAPTIONS[table_count]))
        i += 1

    print(f'[OK] Table captions added (significant tables: {len(table_caption_data)})')

    # ── 7. Insert "List of Tables" heading+entries after List of Figures ──────
    # Find the List of Figures heading paragraph
    lof_heading_elem = None
    for para in doc.paragraphs:
        if para.text.strip() == 'List of Figures' and para.style.name.startswith('Heading'):
            lof_heading_elem = para._element
            break

    # Find the element that comes after all LOF entries (the next heading)
    if lof_heading_elem is not None:
        body_ch = list(body)
        lof_idx = body_ch.index(lof_heading_elem)
        insert_after_idx = lof_idx
        # Skip past all 'table of figures' style paragraphs
        for j in range(lof_idx + 1, len(body_ch)):
            elem = body_ch[j]
            etag = elem.tag.split('}')[-1] if '}' in elem.tag else elem.tag
            if etag == 'p':
                pPr = elem.find(qn('w:pPr'))
                if pPr is not None:
                    pStyle = pPr.find(qn('w:pStyle'))
                    style_val = pStyle.get(qn('w:val'), '') if pStyle is not None else ''
                    if 'table of figures' not in style_val.lower() and 'tableoffigures' not in style_val.lower():
                        insert_after_idx = j - 1
                        break
            insert_after_idx = j

        # Build List of Tables section elements in reverse order so we can insert after lof_idx
        lot_elements = []

        # Heading
        h_elem = make_simple_para('List of Tables', 'Heading2', 14, bold=True, align='left', spacing=1.5)
        lot_elements.append(h_elem)

        # Table of tables entries
        for tnum, tcap in table_caption_data:
            entry_text = f'Table {tnum}\t{tcap}'
            e_elem = make_simple_para(entry_text, 'Normal', 12, bold=False, align='left', spacing=1.0)
            lot_elements.append(e_elem)

        # Insert all after the last LOF entry
        ref_elem = body_ch[insert_after_idx]
        insert_pos = list(body).index(ref_elem) + 1
        for el in reversed(lot_elements):
            body.insert(insert_pos, el)

        print(f'[OK] List of Tables inserted ({len(table_caption_data)} entries)')

    # ── 8. Format tables ──────────────────────────────────────────────────────
    for table in doc.tables:
        for row in table.rows:
            for cell in row.cells:
                for para in cell.paragraphs:
                    para.alignment = WD_ALIGN_PARAGRAPH.LEFT
                    set_spacing(para, 1.0)
                    format_para_mark(para, 12)
                    for run in para.runs:
                        format_run(run, 12)
    print('[OK] Tables formatted')

    # ── 9. Page numbering ────────────────────────────────────────────────────
    # Set main section to Arabic numbering starting at 1
    if doc.sections:
        main_sec = doc.sections[-1]
        set_section_page_num(main_sec, 'decimal', 1)

        # Add bottom-center page number to footer
        footer = main_sec.footer
        # Clear existing footer content
        for para in footer.paragraphs:
            p_elem = para._element
            for child in list(p_elem):
                ctag = child.tag.split('}')[-1] if '}' in child.tag else child.tag
                if ctag in ('r', 'hyperlink'):
                    p_elem.remove(child)

        if footer.paragraphs:
            fp = footer.paragraphs[0]
            fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
            format_para_mark(fp, 12)
            # Add PAGE field
            r1 = OxmlElement('w:r')
            fc1 = OxmlElement('w:fldChar'); fc1.set(qn('w:fldCharType'), 'begin')
            r1.append(fc1); fp._element.append(r1)

            r2 = OxmlElement('w:r')
            it = OxmlElement('w:instrText'); it.set(qn('xml:space'), 'preserve'); it.text = ' PAGE '
            r2.append(it); fp._element.append(r2)

            r3 = OxmlElement('w:r')
            fc3 = OxmlElement('w:fldChar'); fc3.set(qn('w:fldCharType'), 'end')
            r3.append(fc3); fp._element.append(r3)

    print('[OK] Page numbering set (Arabic, bottom center)')

    # ── 10. Save ─────────────────────────────────────────────────────────────
    doc.save(OUTPUT)
    print(f'\n[DONE] Formatted document saved: {OUTPUT}')
    print(f'       Original unchanged:        {INPUT}')
    print(f'       Backup copy:               {BACKUP}')

if __name__ == '__main__':
    main()
