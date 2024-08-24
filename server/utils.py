import magic
from docx import Document
import fitz

def get_file_type(file_path):
    file_type = magic.from_file(file_path, mime=True)
    return file_type

def read_docx(file_path):
    doc = Document(file_path)
    full_text = []
    for paragraph in doc.paragraphs:
        full_text.append(paragraph.text)
    return '\n'.join(full_text)

def read_text_or_code(file_path):
    with open(file_path, "r") as file:
        content = file.read()
        return content
    
def read_pdf(pdf_path):
    doc = fitz.open(pdf_path)
    text = ""
    for page in doc:
        text += page.get_text()
    return text
