#!/usr/bin/env python3
import os
from pymongo import MongoClient
from bson import ObjectId
from gridfs import GridFS

class Deleter:
    def __init__(self, db):
        """
        Инициализирует объект Deleter с экземпляром базы данных.

        :param db: Экземпляр базы данных, например, client.main.
        """
        self.db = db

    def delete_by_name(self, doc_name):
        """
        Удаляет файл из коллекции 'pdf' по имени (значение поля "filename").
        Если файл не найден в коллекции 'pdf', можно добавить здесь логику для поиска в GridFS,
        если имена файлов в GridFS совпадают с doc_name.

        :param doc_name: Имя файла (значение поля "filename").
        :return: True, если удаление прошло успешно, иначе False.
        """
        result = self.db.pdf.delete_one({"filename": doc_name})
        if result.deleted_count:
            print(f"Файл '{doc_name}' успешно удалён из коллекции 'pdf'.")
            return True
        else:
            print(f"Файл '{doc_name}' не найден в коллекции 'pdf'.")
            return False

    def delete_by_id(self, doc_id, method="document"):
        """
        Удаляет файл по _id.
        
        :param doc_id: _id документа (если method=='document') или _id файла в GridFS (если method=='gridfs').
        :param method: "document" для удаления из коллекции 'pdf', "gridfs" для удаления из GridFS.
        :return: True, если удаление прошло успешно, иначе False.
        """
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
    # Подключаемся к MongoDB (измените URI при необходимости)
    client = MongoClient("mongodb://localhost:27017")
    db = client.main

    deleter = Deleter(db)

    # Список имён файлов для удаления (те, которые были загружены)
    files_to_delete = [
        "zadání 1W.pdf",
        "zadání 2.pdf",
        "zadání 3.pdf",
        "RUR.pdf"
    ]

    for name in files_to_delete:
        print(f"Пытаемся удалить файл '{name}' по имени:")
        deleter.delete_by_name(name)

    # Если требуется удаление по _id, можно использовать метод delete_by_id, например:
    # deleter.delete_by_id("67d5b539ff3a959eae6dc7b4", method="document")
    # deleter.delete_by_id("67d5b539ff3a959eae6dc7b7", method="gridfs")

if __name__ == "__main__":
    main()
