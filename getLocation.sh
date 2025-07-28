#!/bin/bash

# A script to get the Raspberry Pi's location via the Unwired Labs API.

# Your API token
TOKEN=""

echo "🛰️  Querying Unwired Labs API for location..."

# --- IMPORTANT ---
# The cell and wifi data below is STATIC.
# For a real-world application, you would need to write code here to
# scan for nearby WiFi APs and cell towers and insert that data dynamically.
# For example, using tools like 'iwlist' for WiFi.
JSON_DATA='{
    "token": "'"$TOKEN"'",
    "radio": "gsm",
    "mcc": 310,
    "mnc": 410,
    "cells": [{
        "lac": 7033,
        "cid": 17811
    }],
    "wifi": [{
        "bssid": "00:17:c5:cd:ca:aa"
    }, {
        "bssid": "d8:97:ba:c2:f0:5a"
    }],
    "address": 1
}'

# Call the API using curl and store the response
# The --silent flag hides the progress meter
API_RESPONSE=$(curl --silent --request POST \
    --url https://us1.unwiredlabs.com/v2/process \
    --header 'Content-Type: application/json' \
    --data "$JSON_DATA")

# Use jq to check if the API call was successful
STATUS=$(echo "$API_RESPONSE" | jq -r '.status')

if [ "$STATUS" == "ok" ]; then
    # Parse the address, latitude, and longitude from the JSON response
    ADDRESS=$(echo "$API_RESPONSE" | jq -r '.address')
    LATITUDE=$(echo "$API_RESPONSE" | jq -r '.lat')
    LONGITUDE=$(echo "$API_RESPONSE" | jq -r '.lon')

    echo "✅ Location Found!"
    echo "📍 Address: $ADDRESS"
    echo "   Coordinates: $LATITUDE, $LONGITUDE"
else
    # If status is not "ok", print the error message from the API
    ERROR_MESSAGE=$(echo "$API_RESPONSE" | jq -r '.message')
    echo "❌ Error: Could not retrieve location."
    echo "   API response: $ERROR_MESSAGE"
fi
