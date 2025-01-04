#!/bin/bash

PROJECT_NAME=$1
BASE_URL=$API_URL

echo "🚀 Starting API tests..."
echo "⏳ Waiting for API to be ready..."
echo "🔗 Testing API at: $BASE_URL"
sleep 5  # Wait for the API to start

# Function to make HTTP requests with SSL verification disabled
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local token=$4
    
    if [ -n "$data" ]; then
        if [ -n "$token" ]; then
            curl -s -k -X "$method" \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $token" \
                -d "$data" \
                "$BASE_URL$endpoint"
        else
            curl -s -k -X "$method" \
                -H "Content-Type: application/json" \
                -d "$data" \
                "$BASE_URL$endpoint"
        fi
    else
        if [ -n "$token" ]; then
            curl -s -k -X "$method" \
                -H "Authorization: Bearer $token" \
                "$BASE_URL$endpoint"
        else
            curl -s -k -X "$method" "$BASE_URL$endpoint"
        fi
    fi
}

echo "📝 Step 1: Registering a new user..."
register_response=$(make_request "POST" "/api/auth/register" '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "Test123!"
}')
echo "Registration response: $register_response"
echo "✅ Registration completed"

echo -e "\n🔑 Step 2: Logging in with the new user..."
login_response=$(make_request "POST" "/api/auth/login" '{
    "username": "testuser",
    "password": "Test123!"
}')
echo "Login response: $login_response"
echo "✅ Login completed"

# Extract token from login response
token=$(echo $login_response | grep -o '"token":"[^"]*' | cut -d'"' -f4)
echo -e "\n🎟️  Retrieved token: ${token:0:20}..."

echo -e "\n🔒 Step 3: Testing protected endpoint (Get Users)..."
users_response=$(make_request "GET" "/api/user" "" "$token")
echo "Protected endpoint response: $users_response"
echo "✅ Protected endpoint test completed"

echo -e "\n🎉 All tests completed!" 