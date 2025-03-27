#!/usr/bin/env python3
import os
from pymongo import MongoClient
from store_pdf import upload_pdf_file
from dotenv import load_dotenv

load_dotenv()

def main():
    path = os.getenv("FILES_PATH", "./files")
    files_to_upload = [
        (os.path.join(path, "zadání 1W.pdf"), "zadání 1W.pdf"),
        (os.path.join(path, "zadání 2.pdf"), "zadání 2.pdf"),
        (os.path.join(path, "zadání 3 (1).pdf"), "zadání 3.pdf"),
        (os.path.join(path, "RUR_Rossumovi_Universalni_Roboty.pdf"), "RUR.pdf")
    ]

    db_uri = os.getenv("MONGO_URI")
    client = MongoClient(db_uri)
    db = client.get_database("main")

    for file_path, doc_name in files_to_upload:
        if not os.path.exists(file_path):
            print(f"Файл '{file_path}' не найден.")
            continue
        result = upload_pdf_file(file_path, doc_name, db)
        print(f"Загрузка файла '{doc_name}' завершена. Результат: {result}")

if __name__ == "__main__":
    main()
