import os
import pandas as pd
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

mongo_uri = os.getenv('MONGO_URI')
client = MongoClient(mongo_uri)
db = client['main']
collection = db['stock_prices']

df = pd.read_csv('../files/data-sets/Mastercard_stock_history.csv')

# Rename column to match MongoDB schema
df.rename(columns={'Stock Splits': 'Stock_Splits'}, inplace=True)

# Convert date to datetime format
df['Date'] = pd.to_datetime(df['Date'], errors='coerce')

# Ensure numerical fields have the correct types
numeric_fields = ['Open', 'High', 'Low', 'Close', 'Dividends', 'Stock_Splits']
df[numeric_fields] = df[numeric_fields].astype(float)

df['Volume'] = df['Volume'].astype(int)

# Replace NaN with None
df = df.where(pd.notnull(df), None)

# Insert data into MongoDB
collection.insert_many(df.to_dict(orient='records'))

print("✅ Mastercard Stock History dataset uploaded successfully.")
