#!/usr/bin/env python3
import os
from pymongo import MongoClient
from bson import ObjectId
from gridfs import GridFS
from dotenv import load_dotenv

load_dotenv()

class Deleter:
    def __init__(self, db):
        self.db = db

    def delete_by_name(self, doc_name):
        result = self.db.pdf.delete_one({"filename": doc_name})
        if result.deleted_count:
            print(f"Файл '{doc_name}' успешно удалён из коллекции 'pdf'.")
            return True
        else:
            print(f"Файл '{doc_name}' не найден в коллекции 'pdf'.")
            return False

    def delete_by_id(self, doc_id, method="document"):
        if method == "document":
            result = self.db.pdf.delete_one({"_id": ObjectId(doc_id)})
            if result.deleted_count:
                print(f"Документ с _id {doc_id} успешно удалён из коллекции 'pdf'.")
                return True
            else:
                print(f"Документ с _id {doc_id} не найден в коллекции 'pdf'.")
                return False
        elif method == "gridfs":
            fs = GridFS(self.db)
            try:
                fs.delete(ObjectId(doc_id))
                print(f"Файл с _id {doc_id} успешно удалён из GridFS.")
                return True
            except Exception as e:
                print(f"Ошибка при удалении файла с _id {doc_id} из GridFS: {e}")
                return False
        else:
            print(f"Неподдерживаемый метод удаления: {method}.")
            return False

def main():
    db_uri = os.getenv("MONGO_URI")
    client = MongoClient(db_uri)
    db = client.get_database("main")

    deleter = Deleter(db)
    files_to_delete = [
        "zadání 1W.pdf",
        "zadání 2.pdf",
        "zadání 3.pdf",
        "RUR.pdf"
    ]

    for name in files_to_delete:
        print(f"Пытаемся удалить файл '{name}' по имени:")
        deleter.delete_by_name(name)

if __name__ == "__main__":
    main()
