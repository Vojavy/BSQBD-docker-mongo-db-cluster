#!/usr/bin/env python3
import os
from pymongo import MongoClient
from store_pdf import upload_pdf_file

def main():
    path='files/pdf'
    # Список файлов для загрузки: (путь, имя документа)
    files_to_upload = [
        (path+"/zadání 1W.pdf", "zadání 1W.pdf"),
        (path+"/zadání 2.pdf", "zadání 2.pdf"),
        (path+"/zadání 3 (1).pdf", "zadání 3.pdf"),
        (path+"/RUR_Rossumovi_Universalni_Roboty.pdf", "RUR.pdf")
    ]

    # Подключаемся к MongoDB (можно поменять URI)
    client = MongoClient("mongodb://localhost:27017")
    db = client.main  # база 'main'

    for file_path, doc_name in files_to_upload:
        if not os.path.exists(file_path):
            print(f"Файл '{file_path}' не найден.")
            continue
        result = upload_pdf_file(file_path, doc_name, db)
        print(f"Загрузка файла '{doc_name}' завершена. Результат: {result}")

if __name__ == "__main__":
    main()
