#!/bin/bash
# Script to generate alerts at Penn Station and random nearby locations
# using the /api/debug/test-alert endpoint

echo "Penn Station Area Alerts Generator"
echo "=================================="
echo ""
echo "This script will generate High, Medium, and Low severity alerts"
echo "starting at Penn Station and 6 random locations 50-200 meters away"
echo ""

# Check if wget is available
if ! command -v wget &> /dev/null; then
    echo "Error: wget is required but not installed"
    exit 1
fi

# Penn Station coordinates
PENN_LAT=40.750638
PENN_LON=-73.993452

# Function to calculate new coordinates given distance and bearing
# Parameters:
# $1 - starting latitude in degrees
# $2 - starting longitude in degrees
# $3 - distance in meters
# $4 - bearing in degrees (0=north, 90=east, etc.)
calculate_new_coordinates() {
    local lat1=$1
    local lon1=$2
    local d=$3  # distance in meters
    local brng=$(echo "$4 * 0.0174533" | bc -l)  # bearing in radians
    
    # Earth's radius in meters
    local R=6378137
    
    # Convert latitude and longitude to radians
    local lat1_rad=$(echo "$lat1 * 0.0174533" | bc -l)
    local lon1_rad=$(echo "$lon1 * 0.0174533" | bc -l)
    
    # Calculate new latitude
    local lat2_rad=$(echo "a($lat1_rad) + ($d / $R) * c($brng)" | bc -l)
    
    # Calculate new longitude
    local lon2_rad=$(echo "$lon1_rad + a(s($brng) * s($d / $R) / c($lat2_rad))" | bc -l)
    
    # Convert back to degrees
    local lat2=$(echo "$lat2_rad * 57.2958" | bc -l)
    local lon2=$(echo "$lon2_rad * 57.2958" | bc -l)
    
    echo "$lat2 $lon2"
}

# Function to send alert with location
send_alert() {
    local severity=$1
    local message=$2
    local lat=$3
    local lon=$4
    
    echo "Sending $severity alert: \"$message\" at coordinates ($lat, $lon)..."
    
    wget --quiet --output-document=- --header="Content-Type: application/json" \
      --post-data="{\"severity\":\"$severity\",\"message\":\"$message\",\"location\":[$lat,$lon]}" \
      http://localhost:8080/api/debug/test-alert \
      && echo -e "\n$severity alert sent successfully"
      
    sleep 1
}

# Generate random number between min and max
random_between() {
    local min=$1
    local max=$2
    echo $(( $min + RANDOM % ($max - $min + 1) ))
}

# Send alert at Penn Station
echo "Sending alert at Penn Station..."
send_alert "High" "Cell attack detected at Penn Station" $PENN_LAT $PENN_LON

# Generate 6 random locations around Penn Station
echo ""
echo "Generating 6 random locations around Penn Station..."

# Array of severity levels to cycle through
SEVERITIES=("Medium" "Low" "High" "Medium" "Low" "High")

# Generate and send alerts for 6 random locations
for i in {0..5}; do
    # Random distance between 50-200 meters
    DISTANCE=$(random_between 50 200)
    
    # Random bearing between 0-359 degrees
    BEARING=$(random_between 0 359)
    
    # Calculate new coordinates
    NEW_COORDS=$(calculate_new_coordinates $PENN_LAT $PENN_LON $DISTANCE $BEARING)
    NEW_LAT=$(echo $NEW_COORDS | cut -d' ' -f1)
    NEW_LON=$(echo $NEW_COORDS | cut -d' ' -f2)
    
    # Get severity for this location
    SEVERITY=${SEVERITIES[$i]}
    
    # Create message based on severity and location
    case $SEVERITY in
        "High")
            MESSAGE="Critical cell attack detected ${DISTANCE}m from Penn Station"
            ;;
        "Medium")
            MESSAGE="Suspicious cell activity ${DISTANCE}m from Penn Station"
            ;;
        "Low")
            MESSAGE="Anomalous signal detected ${DISTANCE}m from Penn Station"
            ;;
    esac
    
    # Send alert
    send_alert "$SEVERITY" "$MESSAGE" $NEW_LAT $NEW_LON
done

echo ""
echo "All alerts sent successfully!"
echo "Check your web UI at http://localhost:8080/fs/index.html to see the alerts on the map"
echo "=================================="


