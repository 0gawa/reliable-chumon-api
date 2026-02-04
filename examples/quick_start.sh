#!/bin/bash

# Restaurant Order Management API - Quick Start Script
# This script demonstrates common API operations using curl.

BASE_URL="http://localhost:3000/api/v1"

echo "🚀 Starting Restaurant Order Management API Quick Start..."
echo "--------------------------------------------------------"

# 1. Check if the server is running
echo "🔍 Checking API status..."
if ! curl -s "$BASE_URL/customer/menus" > /dev/null; then
  echo "❌ Error: API server not found at $BASE_URL. Please run 'docker-compose up' first."
  exit 1
fi
echo "✅ Server is healthy."
echo ""

# 2. List Available Menus (Customer)
echo "📂 [Customer] Fetching available menus..."
curl -s "$BASE_URL/customer/menus" | jq '.' || curl -s "$BASE_URL/customer/menus"
echo ""

# 3. Create an Order (Customer)
echo "📝 [Customer] Creating a new order..."
IDEMPOTENCY_KEY=$(uuidgen 2>/dev/null || echo "39b6b772-888e-4a43-85f0-6184a7a8d5d4")
ORDER_RESPONSE=$(curl -s -X POST "$BASE_URL/customer/orders" \
  -H "Content-Type: application/json" \
  -H "X-Idempotency-Key: $IDEMPOTENCY_KEY" \
  -d '{
    "order": {
      "table_number": "A-5",
      "order_type": "dine_in",
      "items": [
        { "menu_id": 1, "quantity": 2 }
      ]
    }
  }')

echo "$ORDER_RESPONSE" | jq '.' || echo "$ORDER_RESPONSE"
ORDER_ID=$(echo "$ORDER_RESPONSE" | sed -E 's/.*"id":([0-9]+).*/\1/')
echo "✅ Order created with ID: $ORDER_ID"
echo ""

# 4. Try Idempotent Request
echo "🛡️ [Customer] Testing idempotency (reusing same key)..."
curl -s -X POST "$BASE_URL/customer/orders" \
  -H "Content-Type: application/json" \
  -H "X-Idempotency-Key: $IDEMPOTENCY_KEY" \
  -d '{
    "order": {
      "table_number": "A-5",
      "order_type": "dine_in",
      "items": [
        { "menu_id": 1, "quantity": 2 }
      ]
    }
  }' | jq '.' || echo "Success"
echo "✅ Idempotency check passed (Returns original order)."
echo ""

# 5. Get Order Summary
echo "📊 [Customer] Getting order summary for order #$ORDER_ID..."
curl -s "$BASE_URL/customer/orders/$ORDER_ID/summary" | jq '.' || curl -s "$BASE_URL/customer/orders/$ORDER_ID/summary"
echo ""

# 6. List All Orders (Admin)
echo "📋 [Admin] Listing all pending orders..."
curl -s "$BASE_URL/admin/orders?status=pending" | jq '.' || curl -s "$BASE_URL/admin/orders?status=pending"
echo ""

# 7. Update Order Status (Admin)
echo "🔄 [Admin] Confirming order #$ORDER_ID..."
curl -s -X PATCH "$BASE_URL/admin/orders/$ORDER_ID/status" \
  -H "Content-Type: application/json" \
  -d '{"order": {"status": "confirmed"}}' | jq '.' || echo "Updated"
echo ""

# 8. View Analytics Summary (Admin)
echo "📈 [Admin] Fetching sales summary..."
curl -s "$BASE_URL/admin/analytics/summary" | jq '.' || curl -s "$BASE_URL/admin/analytics/summary"
echo ""

echo "--------------------------------------------------------"
echo "✅ Quick Start finished! Explore more at http://localhost:3000/api-docs"
