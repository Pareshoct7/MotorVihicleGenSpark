#!/usr/bin/env python3
"""
Word Document and PDF Generator Service for Flutter Motor Vehicle Inspection App

This service:
1. Reads the Word template
2. Fills in inspection data
3. Checks/unchecks checkboxes based on inspection data
4. Saves the filled Word document
5. Converts Word document to PDF for sharing

Usage:
    python word_pdf_generator.py --inspection-json inspection_data.json --output output.pdf
"""

import sys
import json
import argparse
from datetime import datetime
from pathlib import Path
from docx import Document
from docx.shared import RGBColor, Pt
import subprocess
import os


class InspectionWordPDFGenerator:
    """Generates Word documents and PDFs from inspection data"""
    
    # Checkbox mapping for the Word document
    CHECKBOX_UNCHECKED = '□'
    CHECKBOX_CHECKED = '☑'
    
    def __init__(self, template_path):
        """Initialize with Word template path"""
        self.template_path = Path(template_path)
        if not self.template_path.exists():
            raise FileNotFoundError(f"Template not found: {template_path}")
    
    def generate_word_document(self, inspection_data, output_path):
        """
        Generate a filled Word document from inspection data
        
        Args:
            inspection_data (dict): Inspection data from Flutter app
            output_path (str): Path to save the filled Word document
        
        Returns:
            str: Path to the generated Word document
        """
        # Load the template
        doc = Document(self.template_path)
        
        # Fill in inspection details (Table 0)
        self._fill_inspection_details(doc, inspection_data)
        
        # Fill in checklist items (Table 1)
        self._fill_checklist_items(doc, inspection_data)
        
        # Fill in spare keys checkbox (Table 2)
        self._fill_spare_keys(doc, inspection_data)
        
        # Fill in signatures (Table 3)
        self._fill_signatures(doc, inspection_data)
        
        # Save the document
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        doc.save(str(output_path))
        
        print(f"✅ Word document generated: {output_path}")
        return str(output_path)
    
    def _fill_inspection_details(self, doc, data):
        """Fill in the inspection details table (first table)"""
        table = doc.tables[0]
        
        # Row 0: Vehicle Registration No and Store
        table.rows[0].cells[1].text = data.get('vehicleRegistrationNo', '')
        table.rows[0].cells[3].text = data.get('storeName', '')
        
        # Row 1: Odometer Reading and Date
        table.rows[1].cells[1].text = data.get('odometerReading', '')
        
        # Format date
        inspection_date = data.get('inspectionDate', '')
        if inspection_date:
            try:
                # Parse ISO date string
                date_obj = datetime.fromisoformat(inspection_date.replace('Z', '+00:00'))
                formatted_date = date_obj.strftime('%d/%m/%Y')
                table.rows[1].cells[3].text = formatted_date
            except:
                table.rows[1].cells[3].text = inspection_date
        
        # Row 2: Employee Name
        table.rows[2].cells[1].text = data.get('employeeName', '')
    
    def _fill_checklist_items(self, doc, data):
        """Fill in the checklist items table (second table)"""
        table = doc.tables[1]
        
        # Mapping of table rows to inspection fields
        checklist_mapping = [
            # Row 1: Tyres (tread depth) | Both tail lights
            (1, 0, 'tyresTreadDepth', 1, 2, 'tailLights'),
            # Row 2: Wheel nuts | Headlights (low beam)
            (2, 0, 'wheelNuts', 2, 2, 'headlightsLowBeam'),
            # Row 3: Outside section header | Headlights (high beam)
            (3, None, None, 3, 2, 'headlightsHighBeam'),
            # Row 4: Cleanliness | Reverse lights
            (4, 0, 'cleanliness', 4, 2, 'reverseLights'),
            # Row 5: Body damage | Brake lights
            (5, 0, 'bodyDamage', 5, 2, 'brakeLights'),
            # Row 6: Mirrors & Windows | Cab section header
            (6, 0, 'mirrorsWindows', None, None, None),
            # Row 7: Signage | Windscreen & wipers
            (7, 0, 'signage', 7, 2, 'windscreenWipers'),
            # Row 8: Mechanical section header | Horn
            (8, None, None, 8, 2, 'horn'),
            # Row 9: Engine – oil & water | Indicators
            (9, 0, 'engineOilWater', 9, 2, 'indicators'),
            # Row 10: Brakes | Seat belts
            (10, 0, 'brakes', 10, 2, 'seatBelts'),
            # Row 11: Transmission | Cleanliness (cab)
            (11, 0, 'transmission', 11, 2, 'cabCleanliness'),
            # Row 12: Empty | Service log book
            (12, None, None, 12, 2, 'serviceLogBook'),
        ]
        
        for row_idx, left_col, left_field, right_col, right_cell, right_field in checklist_mapping:
            if row_idx < len(table.rows):
                row = table.rows[row_idx]
                
                # Left column checkbox
                if left_col is not None and left_field and left_col < len(row.cells):
                    checked = data.get(left_field, False)
                    row.cells[left_col].text = self.CHECKBOX_CHECKED if checked else self.CHECKBOX_UNCHECKED
                
                # Right column checkbox
                if right_col is not None and right_field and right_cell < len(row.cells):
                    checked = data.get(right_field, False)
                    row.cells[right_cell].text = self.CHECKBOX_CHECKED if checked else self.CHECKBOX_UNCHECKED
    
    def _fill_spare_keys(self, doc, data):
        """Fill in spare keys checkbox (third table)"""
        if len(doc.tables) > 2:
            table = doc.tables[2]
            if len(table.rows) > 0 and len(table.rows[0].cells) > 0:
                checked = data.get('spareKeys', False)
                table.rows[0].cells[0].text = self.CHECKBOX_CHECKED if checked else self.CHECKBOX_UNCHECKED
    
    def _fill_signatures(self, doc, data):
        """Fill in signature section (fourth table)"""
        if len(doc.tables) > 3:
            table = doc.tables[3]
            
            # Employee signature
            if data.get('signature'):
                table.rows[1].cells[0].text = data['signature']
            
            # Date (both signature columns can have the same date)
            inspection_date = data.get('inspectionDate', '')
            if inspection_date:
                try:
                    date_obj = datetime.fromisoformat(inspection_date.replace('Z', '+00:00'))
                    formatted_date = date_obj.strftime('%d/%m/%Y')
                    table.rows[2].cells[0].text = formatted_date
                    table.rows[2].cells[2].text = formatted_date
                except:
                    pass
    
    def convert_to_pdf(self, word_path, pdf_path=None):
        """
        Convert Word document to PDF
        
        Args:
            word_path (str): Path to the Word document
            pdf_path (str): Path to save the PDF (optional, defaults to same name with .pdf)
        
        Returns:
            str: Path to the generated PDF
        """
        word_path = Path(word_path)
        
        if not word_path.exists():
            raise FileNotFoundError(f"Word document not found: {word_path}")
        
        # If no PDF path specified, use same name with .pdf extension
        if pdf_path is None:
            pdf_path = word_path.with_suffix('.pdf')
        else:
            pdf_path = Path(pdf_path)
        
        # Convert Word to PDF
        try:
            # For Linux systems, we'll use LibreOffice instead of docx2pdf
            import subprocess
            
            # Ensure output directory exists
            pdf_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Use LibreOffice to convert
            result = subprocess.run([
                'libreoffice',
                '--headless',
                '--convert-to', 'pdf',
                '--outdir', str(pdf_path.parent),
                str(word_path)
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                # LibreOffice creates PDF with same name in output directory
                generated_pdf = pdf_path.parent / f"{word_path.stem}.pdf"
                
                # Rename if needed
                if generated_pdf != pdf_path:
                    generated_pdf.rename(pdf_path)
                
                print(f"✅ PDF generated: {pdf_path}")
                return str(pdf_path)
            else:
                print(f"❌ LibreOffice conversion failed: {result.stderr}")
                raise Exception(f"PDF conversion failed: {result.stderr}")
                
        except FileNotFoundError:
            print("❌ LibreOffice not found. Please install: apt-get install libreoffice")
            raise
        except subprocess.TimeoutExpired:
            print("❌ PDF conversion timed out")
            raise
        except Exception as e:
            print(f"❌ Error converting to PDF: {e}")
            raise
    
    def generate_word_and_pdf(self, inspection_data, output_base_path):
        """
        Generate both Word document and PDF
        
        Args:
            inspection_data (dict): Inspection data from Flutter app
            output_base_path (str): Base path for output files (without extension)
        
        Returns:
            tuple: (word_path, pdf_path)
        """
        output_base = Path(output_base_path)
        
        # Generate Word document
        word_path = output_base.with_suffix('.docx')
        self.generate_word_document(inspection_data, word_path)
        
        # Convert to PDF
        pdf_path = output_base.with_suffix('.pdf')
        self.convert_to_pdf(word_path, pdf_path)
        
        return str(word_path), str(pdf_path)


def main():
    """Command-line interface for the generator"""
    parser = argparse.ArgumentParser(
        description='Generate Word documents and PDFs from inspection data'
    )
    parser.add_argument(
        '--template',
        required=True,
        help='Path to Word template file (.docx)'
    )
    parser.add_argument(
        '--inspection-json',
        required=True,
        help='Path to JSON file containing inspection data'
    )
    parser.add_argument(
        '--output',
        required=True,
        help='Output file path (without extension, will generate .docx and .pdf)'
    )
    parser.add_argument(
        '--word-only',
        action='store_true',
        help='Generate only Word document, skip PDF conversion'
    )
    
    args = parser.parse_args()
    
    # Load inspection data
    with open(args.inspection_json, 'r') as f:
        inspection_data = json.load(f)
    
    # Initialize generator
    generator = InspectionWordPDFGenerator(args.template)
    
    # Generate documents
    if args.word_only:
        word_path = generator.generate_word_document(
            inspection_data,
            args.output + '.docx'
        )
        print(f"\n✅ Success! Generated Word document: {word_path}")
    else:
        word_path, pdf_path = generator.generate_word_and_pdf(
            inspection_data,
            args.output
        )
        print(f"\n✅ Success!")
        print(f"   Word document: {word_path}")
        print(f"   PDF document: {pdf_path}")


if __name__ == '__main__':
    main()
