# Word Template PDF Generation - Setup Guide

## Overview

This guide explains how to set up and use the Word template-based PDF generation feature for the Motor Vehicle Inspection App.

## System Requirements

### Desktop Platforms (Required for Word PDF Generation)
- **macOS, Linux, or Windows**
- **Python 3.7+**
- **LibreOffice** (for Word to PDF conversion)

### Mobile Platforms (Limited Support)
- **Android/iOS**: Word template PDF generation is **not available** on mobile devices
- Only the Simple PDF generation works on mobile
- Consider using a backend server for Word PDF generation on mobile

## Installation

### macOS

```bash
# Install Python package
pip3 install python-docx

# Install LibreOffice
brew install libreoffice
```

### Linux (Ubuntu/Debian)

```bash
# Install Python package
pip3 install python-docx

# Install LibreOffice
sudo apt-get update
sudo apt-get install -y libreoffice-writer libreoffice-core --no-install-recommends
```

### Windows

```powershell
# Install Python package
pip install python-docx

# Download and install LibreOffice from:
# https://www.libreoffice.org/download/download/
```

## Verification

After installation, verify everything is set up correctly:

```bash
# Check Python
python3 --version

# Check python-docx
pip3 list | grep python-docx

# Check LibreOffice (macOS/Linux)
soffice --version
# OR
libreoffice --version
```

## How It Works

### Architecture

```
Flutter App
    ↓
    Extracts template from assets to temp directory
    ↓
    Calls Python script with inspection JSON data
    ↓
Python Script (word_pdf_generator.py)
    ├─→ Loads Word template
    ├─→ Fills in inspection data
    ├─→ Checks/unchecks checkboxes
    ├─→ Saves Word document
    └─→ Converts to PDF using LibreOffice
    ↓
Flutter App shares/displays PDF
```

### File Locations

- **Template**: `assets/inspection_template.docx` (bundled in Flutter assets)
- **Python Script**: `python_services/word_pdf_generator.py`
- **Flutter Service**: `lib/services/word_pdf_service.dart`

## Usage

### From Flutter App

1. Open **Inspection History**
2. Tap the **Share icon** (📤) on any inspection
3. Choose your export format:
   - **Share PDF (Simple)** - Quick Flutter-native PDF (works on all platforms)
   - **Share PDF (Word Template)** - Exact template match (desktop only)
   - **Export Word Document** - Editable .docx file (desktop only)

### Command Line Testing

For debugging or batch processing:

```bash
cd /Users/pareshpatil/StudioProjects/MotorVihicleGenSpark-1

# Generate Word document only
python3 python_services/word_pdf_generator.py \
  --template assets/inspection_template.docx \
  --inspection-json test_data.json \
  --output output/inspection \
  --word-only

# Generate both Word and PDF
python3 python_services/word_pdf_generator.py \
  --template assets/inspection_template.docx \
  --inspection-json test_data.json \
  --output output/inspection
```

## Template Customization

To customize the Word template:

1. Open `assets/inspection_template.docx` in Microsoft Word or LibreOffice
2. Modify layout, fonts, colors, add company logo, etc.
3. **Important**: Keep the table structure:
   - Table 0: Inspection Details
   - Table 1: Checklist Items
   - Table 2: Spare Keys
   - Table 3: Signatures
4. Save the template
5. Hot reload or rebuild the Flutter app

## Troubleshooting

### Error: "Failed to load template from assets"

**Solution**: Ensure `inspection_template.docx` is listed in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/inspection_template.docx
```

### Error: "LibreOffice not found"

**Solution**: 
- macOS: `brew install libreoffice`
- Linux: `sudo apt-get install libreoffice`
- Windows: Download from https://www.libreoffice.org/

### Error: "No module named 'docx'"

**Solution**: Install python-docx:
```bash
pip3 install python-docx
```

### PDF conversion timeout

**Solution**: 
- Check LibreOffice is properly installed
- Increase timeout in `word_pdf_generator.py` line 237 (currently 30 seconds)
- Simplify the Word template if it's too complex

### Feature doesn't work on Android

**Expected Behavior**: This is a known limitation. Word PDF generation requires Python and LibreOffice, which are not available on Android/iOS. Use the "Simple PDF" option on mobile devices instead.

## Performance

- **Simple PDF**: ~1-2 seconds (all platforms)
- **Word Template PDF**: ~4-8 seconds (desktop only)
  - 1-2s: Word document generation
  - 3-6s: PDF conversion by LibreOffice
- **Word Export**: ~1-2 seconds (desktop only)

## Security Notes

- All processing happens locally on the device
- No data is sent to external servers
- Template and temporary files are stored in system temp directory
- Temporary files are cleaned up after generation

## Platform Support Matrix

| Feature | macOS | Linux | Windows | Android | iOS |
|---------|-------|-------|---------|---------|-----|
| Simple PDF | ✅ | ✅ | ✅ | ✅ | ✅ |
| Word Template PDF | ✅ | ✅ | ✅ | ❌ | ❌ |
| Word Export | ✅ | ✅ | ✅ | ❌ | ❌ |

## Dependencies Summary

### Python Packages
- `python-docx==1.2.0` - Word document manipulation

### System Dependencies
- LibreOffice (any recent version)
- Python 3.7+

### Flutter Packages (already in pubspec.yaml)
- `path_provider: ^2.1.4` - Temp directory access
- `printing: 5.13.3` - PDF sharing

## Next Steps

1. ✅ Dependencies installed
2. ✅ Template path fixed
3. ✅ Cross-platform LibreOffice support
4. 🔄 Test the feature (see Verification section in implementation plan)
5. 📝 Create sample inspection and generate PDFs
