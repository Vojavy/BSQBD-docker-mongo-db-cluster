#!/usr/bin/env python3
import os
import base64
from pymongo import MongoClient
from gridfs import GridFS

def upload_pdf_file(file_path, doc_name, db):
    """
    Загружает PDF-файл в базу данных main.
    Если размер файла <= 16 МБ, сохраняет документ в коллекцию 'pdf'
    (данные кодируются в Base64 в поле 'data').
    Если файл > 16 МБ, используется GridFS (fs.files, fs.chunks).

    :param file_path: Путь к PDF-файлу
    :param doc_name: Имя (title) для документа
    :param db: Экземпляр базы данных (например, client.main)
    :return: Словарь с информацией о способе хранения (method) и _id
    """
    file_size = os.path.getsize(file_path)
    size_limit = 16 * 1024 * 1024  # 16 MB

    if file_size > size_limit:
        print(f"Файл '{doc_name}' ({file_size} байт) больше 16 МБ. Используем GridFS...")
        fs = GridFS(db)  # по умолчанию bucket='fs'
        with open(file_path, "rb") as f:
            file_id = fs.put(f, filename=doc_name, contentType="application/pdf")
        print(f"Файл '{doc_name}' сохранён в GridFS с _id: {file_id}")
        return {"method": "gridfs", "file_id": file_id}
    else:
        print(f"Файл '{doc_name}' ({file_size} байт) ≤ 16 МБ. Сохраняем в коллекцию 'pdf'...")
        with open(file_path, "rb") as f:
            pdf_data = f.read()
        pdf_base64 = base64.b64encode(pdf_data).decode("utf-8")
        doc = {
            "filename": doc_name,
            "contentType": "application/pdf",
            "data": pdf_base64
        }
        result = db.pdf.insert_one(doc)
        print(f"Файл '{doc_name}' сохранён в коллекции 'pdf' с _id: {result.inserted_id}")
        return {"method": "document", "doc_id": result.inserted_id}

def get_pdf_file(identifier, db, method="auto", output_path=None):
    """
    Извлекает PDF-файл из базы main.
    - method="document": ищет _id в коллекции 'pdf'.
    - method="gridfs": ищет _id в GridFS (fs.files, fs.chunks).
    - method="auto": сначала пытается найти в 'pdf', если нет – в GridFS.

    :param identifier: _id документа (для document) или _id файла (для gridfs)
    :param db: Экземпляр базы (client.main)
    :param method: "document", "gridfs" или "auto"
    :param output_path: Если указан, сохраняет PDF в файл и возвращает путь; иначе возвращает данные в виде bytes.
    :return: bytes (данные файла) или путь к файлу (если output_path указан)
    """
    data = None

    if method == "document":
        doc = db.pdf.find_one({"_id": identifier})
        if not doc:
            raise Exception("Документ не найден в коллекции 'pdf'")
        data_b64 = doc["data"]
        data = base64.b64decode(data_b64)
    elif method == "gridfs":
        fs = GridFS(db)
        grid_out = fs.get(identifier)
        data = grid_out.read()
    elif method == "auto":
        doc = db.pdf.find_one({"_id": identifier})
        if doc:
            data_b64 = doc["data"]
            data = base64.b64decode(data_b64)
        else:
            fs = GridFS(db)
            grid_out = fs.get(identifier)
            data = grid_out.read()
    else:
        raise Exception("Неподдерживаемый метод: document/gridfs/auto")

    if output_path:
        with open(output_path, "wb") as f:
            f.write(data)
        return output_path
    return data

def delete_pdf_file(identifier, db, method="auto"):
    """
    Удаляет PDF-файл из базы main.
    
    - method="document": удаляет документ из коллекции 'pdf'
    - method="gridfs": удаляет файл через GridFS
    - method="auto": сначала пытается удалить из 'pdf', если документ не найден, пытается удалить из GridFS

    :param identifier: _id документа (если document) или _id файла (если gridfs)
    :param db: Экземпляр базы (client.main)
    :param method: "document", "gridfs" или "auto"
    """
    if method == "document":
        result = db.pdf.delete_one({"_id": identifier})
        if result.deleted_count:
            print(f"Документ с _id {identifier} успешно удалён из коллекции 'pdf'.")
        else:
            print(f"Документ с _id {identifier} не найден в коллекции 'pdf'.")
    elif method == "gridfs":
        fs = GridFS(db)
        try:
            fs.delete(identifier)
            print(f"Файл с _id {identifier} успешно удалён из GridFS.")
        except Exception as e:
            print(f"Ошибка при удалении файла с _id {identifier} из GridFS: {e}")
    elif method == "auto":
        result = db.pdf.delete_one({"_id": identifier})
        if result.deleted_count:
            print(f"Документ с _id {identifier} успешно удалён из коллекции 'pdf'.")
        else:
            fs = GridFS(db)
            try:
                fs.delete(identifier)
                print(f"Файл с _id {identifier} успешно удалён из GridFS.")
            except Exception as e:
                print(f"Файл с _id {identifier} не найден ни в 'pdf', ни в GridFS.")
    else:
        raise Exception("Неподдерживаемый метод: выберите 'document', 'gridfs' или 'auto'.")

def get_pdf_file_size(identifier, db, method="auto"):
    """
    Возвращает размер PDF-файла в байтах.
    
    - method="document": если файл хранится как документ, декодирует поле 'data' и возвращает длину байтов.
    - method="gridfs": если файл хранится в GridFS, возвращает значение поля 'length'.
    - method="auto": пытается сначала как документ, затем как GridFS.
    
    :param identifier: _id документа (document) или _id файла (gridfs)
    :param db: Экземпляр базы (client.main)
    :param method: "document", "gridfs" или "auto"
    :return: размер файла в байтах
    """
    if method == "document":
        doc = db.pdf.find_one({"_id": identifier})
        if not doc:
            raise Exception("Документ не найден в коллекции 'pdf'")
        data_b64 = doc["data"]
        data = base64.b64decode(data_b64)
        return len(data)
    elif method == "gridfs":
        fs = GridFS(db)
        grid_out = fs.get(identifier)
        return grid_out.length
    elif method == "auto":
        doc = db.pdf.find_one({"_id": identifier})
        if doc:
            data_b64 = doc["data"]
            data = base64.b64decode(data_b64)
            return len(data)
        else:
            fs = GridFS(db)
            grid_out = fs.get(identifier)
            return grid_out.length
    else:
        raise Exception("Неподдерживаемый метод: выберите 'document', 'gridfs' или 'auto'")
