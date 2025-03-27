#!/bin/bash
set -e

echo "📌 Initializing collections and validation schemas..."

MONGO_CMD="mongosh --quiet --port 27017 -u \"$MONGO_INITDB_ROOT_USERNAME\" -p \"$MONGO_INITDB_ROOT_PASSWORD\" --authenticationDatabase admin"

# Function to check if a collection exists
collection_exists() {
  $MONGO_CMD --eval "db.getSiblingDB('main').getCollectionNames().includes('$1')"
}

# Initialize netflix collection
if [ "$(collection_exists 'netflix')" == "false" ]; then
  echo "Creating collection netflix with validation schema..."
  $MONGO_CMD <<EOF
db = db.getSiblingDB('main');
db.createCollection("netflix", {
  validator: {
    \$jsonSchema: {
      bsonType: "object",
      required: [
        "type", "title", "director", "cast", "country",
        "date_added", "release_year", "rating", "duration",
        "listed_in", "description"
      ],
      properties: {
        type: { enum: ["TV Show", "Movie"] },
        title: { bsonType: "string" },
        director: { bsonType: "string" },
        cast: { bsonType: "string" },
        country: { bsonType: "string" },
        date_added: { bsonType: "date" },
        release_year: { bsonType: "int" },
        rating: { bsonType: "string" },
        duration: { bsonType: "string" },
        listed_in: { bsonType: "string" },
        description: { bsonType: "string" }
      }
    }
  }
});
EOF
  echo "✅ Collection netflix created."
else
  echo "✅ Collection netflix already exists."
fi

echo "🚦 Creating Indian Traffic Violations collection with validation schema..."

mongosh --port 27017 -u "$MONGO_INITDB_ROOT_USERNAME" \
  -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin <<EOF
use main;

if (!db.getCollectionNames().includes("Indian_Traffic_Violations")) {
  db.createCollection("Indian_Traffic_Violations", {
    validator: {
      \$jsonSchema: {
        bsonType: "object",
        required: ["Violation_ID", "Violation_Type", "Fine_Amount", "Location", "Date", "Vehicle_Type", "Driver_Age", "Driver_Gender", "Penalty_Points"],
        properties: {
          Violation_ID: { bsonType: "string", description: "Must be a string and is required." },
          Violation_Type: { bsonType: "string", description: "Type of violation, required." },
          Fine_Amount: { bsonType: "number", description: "Amount of fine, required." },
          Location: { bsonType: "string", description: "Location of violation, required." },
          Date: { bsonType: "date", description: "Date of violation, required." },
          Time: { bsonType: ["string", "null"], description: "Time of violation." },
          Vehicle_Type: { bsonType: "string", description: "Vehicle type, required." },
          Vehicle_Color: { bsonType: ["string", "null"], description: "Vehicle color." },
          Vehicle_Model_Year: { bsonType: ["int", "null"], description: "Vehicle model year." },
          Registration_State: { bsonType: ["string", "null"], description: "State of vehicle registration." },
          Driver_Age: { bsonType: "int", description: "Age of driver, required." },
          Driver_Gender: { enum: ["Male", "Female", "Other"], description: "Gender of driver, required." },
          License_Type: { bsonType: ["string", "null"], description: "Type of driving license." },
          Penalty_Points: { bsonType: "int", description: "Penalty points, required." },
          Weather_Condition: { bsonType: ["string", "null"], description: "Weather condition." },
          Road_Condition: { bsonType: ["string", "null"], description: "Road condition." },
          Officer_ID: { bsonType: ["string", "null"], description: "ID of the issuing officer." },
          Issuing_Agency: { bsonType: ["string", "null"], description: "Issuing agency." },
          License_Validity: { bsonType: ["bool", "null"], description: "License validity status." },
          Number_of_Passengers: { bsonType: ["int", "null"], description: "Number of passengers." },
          Helmet_Worn: { bsonType: ["bool", "null"], description: "Helmet worn status." },
          Seatbelt_Worn: { bsonType: ["bool", "null"], description: "Seatbelt worn status." },
          Traffic_Light_Status: { bsonType: ["string", "null"], description: "Traffic light status." },
          Speed_Limit: { bsonType: ["int", "null"], description: "Speed limit." },
          Recorded_Speed: { bsonType: ["int", "null"], description: "Recorded speed." },
          Alcohol_Level: { bsonType: ["double", "null"], description: "Alcohol level." },
          Breathalyzer_Result: { bsonType: ["bool", "null"], description: "Breathalyzer test result." },
          Towed: { bsonType: ["bool", "null"], description: "Vehicle towed status." },
          Fine_Paid: { bsonType: ["bool", "null"], description: "Fine payment status." },
          Payment_Method: { bsonType: ["string", "null"], description: "Payment method." },
          Court_Appearance_Required: { bsonType: ["bool", "null"], description: "Court appearance required." },
          Previous_Violations: { bsonType: ["int", "null"], description: "Number of previous violations." },
          Comments: { bsonType: ["string", "null"], description: "Additional comments." }
        }
      }
    }
  });
  print("✅ Indian_Traffic_Violations collection created with validation schema.");
} else {
  print("⚠️ Indian_Traffic_Violations collection already exists. Skipping creation.");
}
EOF

echo "📈 Creating stock_prices collection with validation schema..."

mongosh --port 27017 -u "$MONGO_INITDB_ROOT_USERNAME" \
  -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin <<EOF
use main;

if (!db.getCollectionNames().includes("stock_prices")) {
  db.createCollection("stock_prices", {
    validator: {
      \$jsonSchema: {
        bsonType: "object",
        required: ["Date", "Open", "High", "Low", "Close", "Volume", "Dividends", "Stock_Splits"],
        properties: {
          Date: { bsonType: "date", description: "Trading date, required." },
          Open: { bsonType: "double", description: "Opening price, required." },
          High: { bsonType: "double", description: "Highest price, required." },
          Low: { bsonType: "double", description: "Lowest price, required." },
          Close: { bsonType: "double", description: "Closing price, required." },
          Volume: { bsonType: "int", description: "Trading volume, required." },
          Dividends: { bsonType: "double", description: "Dividends paid, required." },
          Stock_Splits: { bsonType: "double", description: "Stock splits ratio, required." }
        }
      }
    }
  });
  print("✅ stock_prices collection created with validation schema.");
} else {
  print("⚠️ stock_prices collection already exists. Skipping creation.");
}
EOF

echo "🎉 All collections and schemas are ready."
