import os
import pandas as pd
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

mongo_uri = os.getenv('MONGO_URI')
client = MongoClient(mongo_uri)
db = client['main']
collection = db['Indian_Traffic_Violations']

df = pd.read_csv('../files/data-sets/Indian_Traffic_Violations.csv')

# Конвертация даты в формат MongoDB
df['Date'] = pd.to_datetime(df['Date'], errors='coerce')

# Конвертация строковых полей в булевы типы
bool_fields = ['License_Validity', 'Seatbelt_Worn', 'Breathalyzer_Result', 'Towed', 'Fine_Paid', 'Court_Appearance_Required', 'Helmet_Worn']
for field in bool_fields:
    df[field] = df[field].map({'Yes': True, 'No': False, 'Valid': True, 'Invalid': False, 'Positive': True, 'Negative': False})

# Замена NaN на None
df = df.where(pd.notnull(df), None)

# Импорт данных в MongoDB
collection.insert_many(df.to_dict(orient='records'))

print("✅ Indian Traffic Violations dataset uploaded successfully.")
