import os
import pandas as pd
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

mongo_uri = os.getenv('MONGO_URI')
client = MongoClient(mongo_uri)
db = client['main']
collection = db['netflix']

df = pd.read_csv('../files/data-sets/Netflix_films.csv')

# Убираем ненужные колонки (например, 'index', 'show_id', если они не в схеме)
df = df[['type', 'title', 'director', 'cast', 'country', 'date_added',
         'release_year', 'rating', 'duration', 'listed_in', 'description']]

# Конвертация дат
df['date_added'] = pd.to_datetime(df['date_added'], errors='coerce')
df['release_year'] = pd.to_numeric(df['release_year'], errors='coerce').astype('Int64')

# Заполняем пустые значения в полях типа строка (например, cast)
str_fields = ['cast', 'director', 'country', 'rating', 'duration', 'listed_in', 'description']
df[str_fields] = df[str_fields].fillna("Unknown")

# Замена NaN на None
df = df.where(pd.notnull(df), None)

# Вставка в MongoDB
collection.insert_many(df.to_dict(orient='records'))

print("✅ Netflix films dataset uploaded successfully.")
