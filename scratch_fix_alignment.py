# -*- coding: utf-8 -*-
import datetime, shutil, re
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH

SRC = r"E:\FypApp\AEGIS_fixed_BACKUP_20260628_104247_v2.docx"
ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
backup = rf"E:\FypApp\AEGIS_fixed_BACKUP_20260628_104247_v2_PREALIGNFIX_{ts}.docx"
shutil.copy2(SRC, backup)
print("backup:", backup)

doc = Document(SRC)
TITLES = {
    'INTRODUCTION', 'BACKGROUND INFORMATION', 'RELATED WORK AND LITERATURE REVIEW',
    'SYSTEM DESIGN', 'DIAGRAM DESCRIPTIONS', 'IMPLEMENTATION', 'TESTING',
    'CONCLUSION AND FUTURE WORK',
}

fixed = 0
for p in doc.paragraphs:
    t = p.text.strip()
    if re.match(r'^CHAPTER \d+$', t) or t in TITLES:
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        fixed += 1

print("fixed", fixed, "paragraphs")
doc.save(SRC)
print("saved")
