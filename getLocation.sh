#!/bin/bash

# A script to dynamically scan for WiFi networks and get the Pi's location.

# Your API token
TOKEN="pk.e919848b07050a451cfbaa178af3fb11"
# Your Pi's wireless interface (usually wlan0)
WIFI_INTERFACE="wlan0"

echo "📡 Scanning for nearby Wi-Fi networks on $WIFI_INTERFACE..."
# Use 'sudo iwlist' to scan, then grep/awk to extract BSSIDs.
# We build a comma-separated list of JSON objects.
WIFI_OBJECTS=$(sudo iwlist "$WIFI_INTERFACE" scan | grep "Address:" | awk '{print "    {\"bssid\": \"" $5 "\"}"}' | paste -sd,)

# Check if any WiFi networks were found
if [ -z "$WIFI_OBJECTS" ]; then
    echo "❌ No Wi-Fi networks found. Cannot determine location."
    exit 1
fi

echo "🛰️  Querying Unwired Labs API with found networks..."

# --- Dynamically construct the JSON payload ---
# Note: The "cells" array is empty as a standard Pi cannot scan cell towers.
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
