#!/bin/bash

# A script to dynamically scan for WiFi networks and get the Pi's location,
# now with logging to show which networks were found.

# Your API token
TOKEN="pk.e919848b07050a451cfbaa178af3fb11"
# Your Pi's wireless interface (usually wlan0)
WIFI_INTERFACE="wlan0"

echo "📡 Scanning for nearby Wi-Fi networks on $WIFI_INTERFACE..."

# Scan and read the BSSIDs into a bash array for easy processing
mapfile -t BSSID_LIST < <(sudo iwlist "$WIFI_INTERFACE" scan | grep "Address:" | awk '{print $5}')

# Check if any WiFi networks were found
if [ ${#BSSID_LIST[@]} -eq 0 ]; then
    echo "❌ No Wi-Fi networks found. Cannot determine location."
    exit 1
fi

# --- NEW: Log the found networks ---
echo "✅ Found ${#BSSID_LIST[@]} network(s):"
printf "  %s\n" "${BSSID_LIST[@]}"

# Now, build the JSON objects from our list of BSSIDs
WIFI_OBJECTS=""
for BSSID in "${BSSID_LIST[@]}"; do
    WIFI_OBJECTS+="{\"bssid\": \"$BSSID\"},"
done
# Remove the final trailing comma to create valid JSON
WIFI_OBJECTS=${WIFI_OBJECTS%,}


echo "🛰️  Querying Unwired Labs API with found networks..."

# Dynamically construct the JSON payload
JSON_DATA='{
    "token": "'"$TOKEN"'",
    "wifi": ['"$WIFI_OBJECTS"'],
    "address": 1
}'

# Call the API using curl and store the response
API_RESPONSE=$(curl --silent --request POST \
    --url https://us1.unwiredlabs.com/v2/process \
    --header 'Content-Type: application/json' \
    --data "$JSON_DATA")

# --- Parsing without jq ---
STATUS=$(echo "$API_RESPONSE" | grep -o '"status":"[^"]*"' | cut -d '"' -f 4)

if [ "$STATUS" == "ok" ]; then
    ADDRESS=$(echo "$API_RESPONSE" | grep -o '"address":"[^"]*"' | cut -d '"' -f 4)
    LATITUDE=$(echo "$API_RESPONSE" | grep -o '"lat":[0-9.-]*' | cut -d ':' -f 2)
    LONGITUDE=$(echo "$API_RESPONSE" | grep -o '"lon":[0-9.-]*' | cut -d ':' -f 2)

    echo "✅ Location Found!"
    echo "📍 Address: $ADDRESS"
    echo "   Coordinates: $LATITUDE, $LONGITUDE"
else
    ERROR_MESSAGE=$(echo "$API_RESPONSE" | grep -o '"message":"[^"]*"' | cut -d '"' -f 4)
    echo "❌ Error: Could not retrieve location."
    echo "   API response: $ERROR_MESSAGE"
fi
