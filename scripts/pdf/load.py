#!/usr/bin/env python3
import os
from pymongo import MongoClient
from bson import ObjectId
from gridfs import GridFS
from store_pdf import get_pdf_file

class Loader:
    def __init__(self, db):
        self.db = db

    def load_by_name(self, doc_name, output_dir):
        """
        Ищет PDF-файл по имени (filename) и сохраняет в папку output_dir.
        Если файл хранится в коллекции 'pdf', извлекается как document.
        Если файл хранится в GridFS, извлекается через gridfs.
        """
        os.makedirs(output_dir, exist_ok=True)

        # 1) Проверяем коллекцию 'pdf'
        doc = self.db.pdf.find_one({"filename": doc_name})
        if doc:
            doc_id = doc["_id"]
            out_path = os.path.join(output_dir, doc_name)
            print(f"Найден документ '{doc_name}' в коллекции 'pdf' (_id={doc_id}). Сохраняем в '{out_path}'...")
            get_pdf_file(doc_id, self.db, method="document", output_path=out_path)
            print(f"Файл '{doc_name}' сохранён в '{out_path}'.")
            return

        # 2) Проверяем GridFS (fs.files) по filename
        fs = GridFS(self.db)
        file_info = self.db.fs.files.find_one({"filename": doc_name})
        if file_info:
            file_id = file_info["_id"]
            out_path = os.path.join(output_dir, doc_name)
            print(f"Найден файл '{doc_name}' в GridFS (_id={file_id}). Сохраняем в '{out_path}'...")
            get_pdf_file(file_id, self.db, method="gridfs", output_path=out_path)
            print(f"Файл '{doc_name}' сохранён в '{out_path}'.")
            return

        print(f"Файл '{doc_name}' не найден ни в 'pdf', ни в GridFS.")

def main():
    # Получаем путь к текущему скрипту (load.py)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Определяем папку для сохранения, расположенную рядом со скриптом
    output_dir = os.path.join(script_dir, "installed")

    client = MongoClient("mongodb://localhost:27017")
    db = client.main

    loader = Loader(db)
    files_to_load = [
        "zadání 1W.pdf",
        "zadání 2.pdf",
        "zadání 3.pdf"
    ]

    for name in files_to_load:
        loader.load_by_name(name, output_dir=output_dir)

if __name__ == "__main__":
    main()
