# Word Document & PDF Generation Feature

## Overview

The Motor Vehicle Inspection App now supports **two methods** for generating inspection reports:

1. **Simple PDF Generation** - Fast, Flutter-native PDF generation (original method)
2. **Word Template PDF Generation** - Uses your Word template for exact layout matching (new method)

This document explains the Word template system and how to use it.

---

## 🎯 Key Features

### **Dual Export System**
- **Simple PDF**: Quick, Flutter-generated PDF with good layout
- **Word Template PDF**: Uses your `.docx` template for **exact** layout matching
- **Word Export**: Generate editable `.docx` files for offline editing

### **Template-Based Generation**
- Uses your actual Word document as the template
- Fills in all inspection data automatically
- Checks/unchecks checkboxes based on inspection results
- Preserves exact formatting, fonts, and layout from your Word template
- Converts to PDF using LibreOffice for universal compatibility

---

## 📋 How It Works

### **System Architecture**

```
Flutter App (Dart)
    ↓
    ├─→ Simple PDF: pdf_service.dart → Native PDF generation
    │
    └─→ Word Template: word_pdf_service.dart
            ↓
        Python Backend (word_pdf_generator.py)
            ↓
            ├─→ 1. Load Word template (.docx)
            ├─→ 2. Fill inspection data into tables
            ├─→ 3. Check/uncheck checkboxes (□ / ☑)
            ├─→ 4. Save filled Word document
            └─→ 5. Convert to PDF (LibreOffice)
```

### **Template Structure**

Your Word template (`inspection_template.docx`) contains:

**Table 0: Inspection Details**
```
┌─────────────────────────────────────────────────────┐
│ Vehicle Registration No: [___] | Store: [___]      │
│ Odometer Reading: [___]        | Date: [___]       │
│ Employee Name: [___]                                │
└─────────────────────────────────────────────────────┘
```

**Table 1: Inspection Checklist** (Two-column layout)
```
┌─────────────────────────────────────────────────────┐
│ OK? | Tyres              | OK? | Electrical          │
│ □   | Tyres (tread depth)| □   | Both tail lights   │
│ □   | Wheel nuts         | □   | Headlights (low)   │
│     | Outside            | □   | Headlights (high)  │
│ □   | Cleanliness        | □   | Reverse lights     │
│ ... | ...                | ... | ...                │
└─────────────────────────────────────────────────────┘
```

**Table 2: Spare Keys**
```
┌─────────────────────────────────────────────────────┐
│ □ | Spare keys available in store                  │
└─────────────────────────────────────────────────────┘
```

**Table 3: Signatures**
```
┌─────────────────────────────────────────────────────┐
│ Employee Signature: [___] | Manager Signature: [___]│
│ Date: [___]               | Date: [___]            │
└─────────────────────────────────────────────────────┘
```

---

## 🚀 Usage Guide

### **In the Flutter App**

#### **From Inspection History Screen:**

1. **Share PDF (Simple)** - Quick PDF generation using Flutter
   ```
   Tap inspection → Share icon → "Share PDF (Simple)"
   ```

2. **Share PDF (Word Template)** - Exact template matching
   ```
   Tap inspection → Share icon → "Share PDF (Word Template)"
   ```

3. **Export Word Document** - Editable Word file
   ```
   Tap inspection → Share icon → "Export Word Document"
   ```

### **From Python Command Line:**

For testing or batch processing:

```bash
cd /home/user/flutter_app

# Generate both Word and PDF
python3 python_services/word_pdf_generator.py \
  --template assets/inspection_template.docx \
  --inspection-json data/inspection.json \
  --output reports/inspection_ABC123

# Generate Word only (skip PDF conversion)
python3 python_services/word_pdf_generator.py \
  --template assets/inspection_template.docx \
  --inspection-json data/inspection.json \
  --output reports/inspection_ABC123 \
  --word-only
```

---

## 🔧 Technical Details

### **Dependencies**

#### **Python:**
- `python-docx` - Word document manipulation
- `LibreOffice` - Word to PDF conversion

#### **Flutter:**
- `path_provider` - Temporary file handling
- `printing` - PDF sharing functionality

### **Data Flow**

1. **Flutter App** creates inspection data JSON:
```json
{
  "vehicleRegistrationNo": "ABC123",
  "storeName": "Auckland Central",
  "odometerReading": "125,456 km",
  "inspectionDate": "2024-11-04T10:30:00Z",
  "employeeName": "John Smith",
  "tyresTreadDepth": true,
  "wheelNuts": true,
  ...
}
```

2. **Python Backend** processes:
   - Loads Word template
   - Fills in table cells with data
   - Replaces `□` (unchecked) with `☑` (checked) for true values
   - Formats dates (ISO → dd/MM/yyyy)
   - Saves Word document

3. **LibreOffice** converts:
   - Reads `.docx` file
   - Generates `.pdf` file
   - Preserves all formatting

4. **Flutter App** handles file:
   - Uses `printing` package to share PDF
   - Or saves Word document to device

---

## 📝 Checkbox Mapping

The Python backend automatically maps inspection fields to checkboxes:

| Field Name | Word Template Location |
|-----------|------------------------|
| `tyresTreadDepth` | Table 1, Row 1, Left Column |
| `wheelNuts` | Table 1, Row 2, Left Column |
| `cleanliness` | Table 1, Row 4, Left Column |
| `bodyDamage` | Table 1, Row 5, Left Column |
| `mirrorsWindows` | Table 1, Row 6, Left Column |
| `signage` | Table 1, Row 7, Left Column |
| `engineOilWater` | Table 1, Row 9, Left Column |
| `brakes` | Table 1, Row 10, Left Column |
| `transmission` | Table 1, Row 11, Left Column |
| `tailLights` | Table 1, Row 1, Right Column |
| `headlightsLowBeam` | Table 1, Row 2, Right Column |
| `headlightsHighBeam` | Table 1, Row 3, Right Column |
| `reverseLights` | Table 1, Row 4, Right Column |
| `brakeLights` | Table 1, Row 5, Right Column |
| `windscreenWipers` | Table 1, Row 7, Right Column |
| `horn` | Table 1, Row 8, Right Column |
| `indicators` | Table 1, Row 9, Right Column |
| `seatBelts` | Table 1, Row 10, Right Column |
| `cabCleanliness` | Table 1, Row 11, Right Column |
| `serviceLogBook` | Table 1, Row 12, Right Column |
| `spareKeys` | Table 2, Row 0 |

---

## ⚠️ Important Notes

### **Template Requirements:**
1. **Must have 4 tables** in the exact order:
   - Table 0: Inspection Details
   - Table 1: Checklist Items
   - Table 2: Spare Keys
   - Table 3: Signatures

2. **Checkbox characters:**
   - Unchecked: `□` (U+25A1 - White Square)
   - Checked: `☑` (U+2611 - Ballot Box with Check)

3. **Date format:**
   - Input: ISO 8601 format (`2024-11-04T10:30:00Z`)
   - Output: dd/MM/yyyy format (`04/11/2024`)

### **Performance:**
- **Simple PDF**: ~1-2 seconds (fast)
- **Word Template PDF**: ~4-6 seconds (slower but exact)
- **Word Export**: ~1-2 seconds

### **File Sizes:**
- Simple PDF: ~30-50 KB
- Word Template PDF: ~100-150 KB (higher quality)
- Word Document: ~90-100 KB

---

## 🛠️ Customization

### **Modifying the Template:**

1. **Open** `assets/inspection_template.docx` in Microsoft Word or LibreOffice
2. **Edit** layout, fonts, colors, or add company logo
3. **Keep** the table structure intact (4 tables)
4. **Save** and the app will use your updated template

### **Adding New Fields:**

1. **Update Word Template:**
   - Add new checkbox row in appropriate table
   - Follow existing format

2. **Update Python Script** (`word_pdf_generator.py`):
   ```python
   # Add to _fill_checklist_items method
   (13, 0, 'newFieldName', None, None, None),
   ```

3. **Update Flutter Service** (`word_pdf_service.dart`):
   ```dart
   'newFieldName': inspection.newFieldName ?? false,
   ```

4. **Update Inspection Model:**
   ```dart
   @HiveField(X) bool? newFieldName;
   ```

---

## 🎨 Comparison: Simple PDF vs Word Template PDF

| Feature | Simple PDF | Word Template PDF |
|---------|-----------|-------------------|
| **Generation Speed** | ⚡ Fast (1-2s) | 🕐 Moderate (4-6s) |
| **Layout Accuracy** | ✓ Good | ✅ Exact Match |
| **Customization** | Code changes needed | Edit Word template |
| **File Size** | 📦 Small (30-50 KB) | 📦 Medium (100-150 KB) |
| **Offline Editing** | ❌ No | ✅ Yes (Word export) |
| **Platform Support** | ✅ All platforms | ⚠️ Requires Python backend |
| **Branding** | ⚠️ Limited | ✅ Full control |

### **When to Use Each:**

**Use Simple PDF when:**
- Speed is critical
- File size matters
- No template customization needed
- Running on mobile devices

**Use Word Template PDF when:**
- Exact layout match required
- Company branding important
- Need editable Word documents
- Running with backend access

---

## 📊 Example Output

### **Generated Word Document:**
- Exact match to your template layout
- All checkboxes properly checked/unchecked
- Dates formatted correctly
- Professional appearance

### **Generated PDF:**
- Converted from Word document
- Preserves all formatting
- Universal compatibility
- High quality output

---

## 🐛 Troubleshooting

### **"LibreOffice not found" error:**
```bash
# Install LibreOffice
sudo apt-get update
sudo apt-get install -y libreoffice-writer libreoffice-core --no-install-recommends
```

### **"Template not found" error:**
- Check `assets/inspection_template.docx` exists
- Verify file permissions
- Ensure template is included in `pubspec.yaml`

### **Checkboxes not displaying correctly:**
- Use correct Unicode characters: `□` (U+25A1) and `☑` (U+2611)
- Check font supports these characters

### **PDF conversion timeout:**
- Increase timeout in Python script
- Check LibreOffice is properly installed
- Verify document complexity isn't too high

---

## 📈 Future Enhancements

- [ ] Add vehicle diagram image support
- [ ] Support for photo attachments
- [ ] Batch Word/PDF generation
- [ ] Cloud storage integration
- [ ] Email sending directly from app
- [ ] Template version management
- [ ] Multi-language template support

---

## 📚 References

- **python-docx Documentation**: https://python-docx.readthedocs.io/
- **LibreOffice Command Line**: https://wiki.documentfoundation.org/Faq/General/CommandLine
- **Flutter Printing Package**: https://pub.dev/packages/printing

---

**Version**: 1.0.0  
**Last Updated**: November 2024  
**Author**: Motor Vehicle Inspection App Development Team
