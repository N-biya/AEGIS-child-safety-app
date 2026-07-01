# -*- coding: utf-8 -*-
import datetime, shutil, re
from docx import Document
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

SRC = r"E:\FypApp\AEGIS_fixed_BACKUP_20260628_104247_v2.docx"
ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
backup = rf"E:\FypApp\AEGIS_fixed_BACKUP_20260628_104247_v2_PRETITLEPAGES_{ts}.docx"
shutil.copy2(SRC, backup)
print("backup:", backup)

doc = Document(SRC)

def set_page_break_before(paragraph):
    pPr = paragraph._p.get_or_add_pPr()
    if pPr.find(qn('w:pageBreakBefore')) is None:
        pb = OxmlElement('w:pageBreakBefore')
        pPr.insert(0, pb)

# Collect the 8 "CHAPTER N" / TITLE / Heading3 triples up front, before any mutation.
paras = doc.paragraphs
triples = []
for i, p in enumerate(paras):
    t = p.text.strip()
    if re.match(r'^CHAPTER \d+$', t) and p.style.name == "Normal":
        chapter_p = p
        title_p = paras[i + 1]
        heading_p = paras[i + 2]
        triples.append((chapter_p, title_p, heading_p))

print("found", len(triples), "chapter title blocks")
for chapter_p, title_p, heading_p in triples:
    print(" -", chapter_p.text, "/", title_p.text, "->", heading_p.text[:30])

SPACER_COUNT = 16

for chapter_p, title_p, heading_p in triples:
    # spacers BEFORE "CHAPTER N", first spacer carries the page break
    first_spacer = None
    for k in range(SPACER_COUNT):
        sp = chapter_p.insert_paragraph_before("")
        if first_spacer is None:
            first_spacer = sp
    set_page_break_before(first_spacer)

    # spacers AFTER "TITLE" (i.e. immediately before the existing Heading3,
    # which already carries its own pageBreakBefore)
    for k in range(SPACER_COUNT):
        heading_p.insert_paragraph_before("")

doc.save(SRC)
print("saved:", SRC)
