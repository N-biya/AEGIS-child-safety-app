# Document Editing and Formatting Requirements

## 1. General Formatting Rules

- Use Times New Roman font throughout the entire document.
- Apply the following font sizes:
  - Main Chapter Headings: 16 pt
  - Subheadings: 14 pt
  - Body Paragraphs: 12 pt
- Set paragraph alignment to Justified.
- Set Line Spacing to 1.5 throughout the document.
- Set Line spacing of table of contents to 1.
- Maintain consistent formatting across all chapters and sections.

---

## 2. Page Margin Requirements

Apply the following page margins to the entire document:

- Left Margin: 1.5 inches
- Right Margin: 1 inch
- Top Margin: 1 inch
- Bottom Margin: 1 inch

These margins must remain consistent throughout the document.

---

## 3. Chapter Formatting

- Every new chapter must begin on a new page.
- Ensure proper chapter separation and professional document structure.
- Main chapter titles should use the specified heading style and font size.

---

## 4. Abbreviations Section

### 4.1 Review Existing Abbreviations

- The current abbreviations list contains random entries and may include abbreviations that are not actually used in the document.
- Remove all unused abbreviations.
- Create a new abbreviations list containing only abbreviations that appear in the document.

### 4.2 Abbreviation Usage Rules

For every abbreviation used in the document:

- At its **first occurrence**, write: **Full Form (Abbreviation)**
  - Example: Artificial Intelligence (AI)
- After the first occurrence, use **only the abbreviation** throughout the rest of the document.
  - Example: AI
- Ensure consistency across the entire document.

---

## 5. List of Figures

- Retain or create a List of Figures page.
- Ensure every figure has a proper caption.
- Verify that figure numbering is accurate and sequential.

---

## 6. List of Tables

- Insert a List of Tables page immediately after the List of Figures page.
- Every table in the document must have a properly formatted caption.
- Ensure table numbering is accurate and sequential.
- All table captions must appear automatically in the List of Tables.

---

## 7. Page Numbering Requirements

### 7.1 Preliminary Pages

The following pages belong to the preliminary section:
- Title Page / Cover Page
- Introduction Page (if applicable)
- Abbreviations Page
- List of Figures
- List of Tables

Requirements:
- The first page (Title/Cover Page) must **not** display any page number.
- The Introduction page must **not** display any page number.
- Use **Roman numerals** (i, ii, iii, iv, v, etc.) for preliminary pages starting after the pages that should remain unnumbered.
- Continue Roman numeral numbering through the Abbreviations, List of Figures, and List of Tables pages.

### 7.2 Main Document

- After the List of Tables page, begin the main document section.
- Restart page numbering using **Arabic numerals** (1, 2, 3, 4, etc.).
- Place page numbers at the **bottom center** of each page.
- Maintain numbering consistency throughout the remainder of the document.

---

## 8. Tables and Figures

### Tables

- Every table must have a caption.
- Captions should be descriptive and professionally written.
- Table numbering must be sequential throughout the document.

### Figures

- Every figure must have a caption.
- Captions should clearly describe the figure.
- Figure numbering must be sequential throughout the document.

---

## 8a. Caption Placement (Tables vs. Figures)

- **Table captions go ABOVE the table**, immediately before it, using the `Caption` (or `Table Titles`) paragraph style.
- **Figure captions go BELOW the figure**, immediately after it, centered, using the `Caption` paragraph style.
- Caption text format: `Table X.Y: <Description>` / `Fig X.Y: <Description>`, where X is the chapter number and Y is the sequential number within that chapter (use a `SEQ` field for auto-numbering, not hardcoded numbers).
- Do not mix the two conventions within the same document — every table caption sits above its table, every figure caption sits below its figure, with no exceptions.

---

## 8b. Descriptive Use Case Formatting

Each use case in the "Descriptive Use Cases" section must follow this structure:

1. **Heading**: one heading level below the section heading (e.g. Heading 4 under a Heading 3 "Detailed Use Case Specifications"), titled `Descriptive Use Case: <Use Case Name>`.
2. **Table caption** (style `Caption`, placed above the table): `Table X.Y: <Use Case Name> Use Case`.
3. **Table** — a single 2-column table (style `Normal Table`, single black border on all sides and inside grid lines) with the following rows, in order:
   - `Use Case Name` | `<Name>` — both cells **bold**.
   - `Participating Actor` | `<Actor>`
   - `Goal` | `<Goal>`
   - `Precondition` | `<Precondition>`
   - `Post Condition` | `<Post Condition>`
   - `Basic Flow` — merged across both columns, **bold** (section header row).
   - `User Actions` | `System Response` — sub-header row, **bold**.
   - One row per step of the typical/basic flow, with the user action in the left column and the matching system response in the right column.
   - `Alternative Flow` — merged across both columns, **bold** (section header row).
   - `User Actions` | `System Response` — sub-header row, **bold**.
   - One row per alternative-flow condition/response pair.
- All table text uses Times New Roman, 12pt, matching the rest of the document body.
- Every descriptive use case table caption must be numbered sequentially and appear in the List of Tables.

---

## 9. Writing Style Requirements

- Rewrite content where necessary to sound naturally human-written.
- Avoid robotic, repetitive, or AI-generated wording.
- Improve readability while preserving the original meaning.
- Use academic yet natural language.
- Ensure smooth transitions between paragraphs and sections.
- Reduce the likelihood of AI-content detection by using varied sentence structures and natural phrasing.
- Maintain professionalism and academic integrity throughout the document.

---

## 10. Final Quality Check

Before finalizing the document:

- [ ] Verify all formatting rules have been followed.
- [ ] Verify all abbreviations are correctly listed and used.
- [ ] Verify all figures have captions and appear in the List of Figures.
- [ ] Verify all tables have captions and appear in the List of Tables.
- [ ] Verify page numbering follows the required format.
- [ ] Verify table captions appear above their tables and figure captions appear below their figures.
- [ ] Verify every descriptive use case follows the full template (Use Case Name, Participating Actor, Goal, Precondition, Post Condition, Basic Flow, Alternative Flow).
- [ ] Verify chapter breaks start on new pages.
- [ ] Verify consistency in font, spacing, margins, and alignment.
- [ ] Verify the document reads naturally and professionally.
- [ ] Remove any formatting inconsistencies or unused elements.
- [ ] Deliver a polished, submission-ready document.
