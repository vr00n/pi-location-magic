#!/bin/bash

# A script to get the Raspberry Pi's location via the Unwired Labs API without jq.

# Your API token
TOKEN="pk.e919848b07050a451cfbaa178af3fb11"

echo "🛰️  Querying Unwired Labs API for location..."

# --- IMPORTANT ---
# The cell and wifi data below is STATIC.
# For a real-world application, you would need to write code here to
# scan for nearby WiFi APs and cell towers and insert that data dynamically.
JSON_DATA='{
    "token": "'"$TOKEN"'",
    "radio": "gsm",
    "mcc": 310,
    "mnc": 410,
    "cells": [{"lac": 7033, "cid": 17811}],
    "wifi": [{"bssid": "00:17:c5:cd:ca:aa"}, {"bssid": "d8:97:ba:c2:f0:5a"}],
    "address": 1
}'

# Call the API using curl and store the response
API_RESPONSE=$(curl --silent --request POST \
    --url https://us1.unwiredlabs.com/v2/process \
    --header 'Content-Type: application/json' \
    --data "$JSON_DATA")

# --- Parsing without jq ---
# Isolate the line with "status", then use cut to get the 4th field using a quote " as the delimiter.
STATUS=$(echo "$API_RESPONSE" | grep -o '"status":"[^"]*"' | cut -d '"' -f 4)

if [ "$STATUS" == "ok" ]; then
    # Parse the address, latitude, and longitude from the JSON response
    ADDRESS=$(echo "$API_RESPONSE" | grep -o '"address":"[^"]*"' | cut -d '"' -f 4)
    
    # For numbers, which aren't in quotes, we isolate the key-value pair and then cut by the colon :
    LATITUDE=$(echo "$API_RESPONSE" | grep -o '"lat":[0-9.-]*' | cut -d ':' -f 2)
    LONGITUDE=$(echo "$API_RESPONSE" | grep -o '"lon":[0-9.-]*' | cut -d ':' -f 2)

    echo "✅ Location Found!"
    echo "📍 Address: $ADDRESS"
    echo "   Coordinates: $LATITUDE, $LONGITUDE"
else
    # If status is not "ok", parse and print the error message
    ERROR_MESSAGE=$(echo "$API_RESPONSE" | grep -o '"message":"[^"]*"' | cut -d '"' -f 4)
    echo "❌ Error: Could not retrieve location."
    echo "   API response: $ERROR_MESSAGE"
fi
