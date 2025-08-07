#!/usr/bin/env bash
# copyright 2025 by moshix
# This is a BBS for 3270 terminals
# all rights reserved by moshix


# import_calendar.sh - Import calendar events from .ics file into tsu.db
# Usage: ./import_calendar.sh

# Configuration
DB_FILE="tsu.db"

# Check if sqlite3 is installed
if ! command -v sqlite3 &> /dev/null; then
    echo "Error: sqlite3 is not installed. Please install it and try again."
    exit 1
fi

# Check if date command is available
if ! command -v date &> /dev/null; then
    echo "Error: date command is not available. This script requires the date command."
    exit 1
fi

# Function to validate input
validate_username() {
    if [[ -z "$1" ]]; then
        echo "Username cannot be empty."
        return 1
    fi
    return 0
}

# Function to check if user exists in the database
check_user_exists() {
    local username="$1"
    local count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users WHERE username = '$username';")
    
    if [ "$count" -eq 0 ]; then
        echo "User '$username' does not exist in the database."
        return 1
    fi
    
    return 0
}

# Function to get user_id from username
get_user_id() {
    local username="$1"
    local user_id=$(sqlite3 "$DB_FILE" "SELECT user_id FROM users WHERE username = '$username';")
    echo "$user_id"
}

# Function to get user's timezone preference
get_user_timezone() {
    local user_id="$1"
    local timezone=$(sqlite3 "$DB_FILE" "SELECT json_extract(calendar_preferences, '$.time_zone') FROM users WHERE user_id = $user_id;")
    
    # If no timezone preference is set, use UTC as default
    if [ -z "$timezone" ] || [ "$timezone" = "null" ]; then
        echo "UTC"
    else
        # Remove quotes from the extracted JSON value
        echo "$timezone" | tr -d '"'
    fi
}

# Function to check if an event already exists for this user
event_exists() {
    local user_id="$1"
    local title="$2"
    local start_time="$3"
    
    # Escape single quotes in title
    local escaped_title=$(echo "$title" | sed "s/'/''/g")
    
    # Query to check if an event with the same title and start time exists
    local count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM calendar_events 
                                     WHERE user_id = $user_id 
                                     AND title = '$escaped_title' 
                                     AND start_time = '$start_time';")
    
    if [ "$count" -gt 0 ]; then
        return 0  # Event exists
    else
        return 1  # Event doesn't exist
    fi
}

# Function to convert a timestamp from a specific timezone to UTC
# Usage: convert_to_utc "20230729T143000" "America/New_York"
convert_to_utc() {
    local timestamp="$1"
    local timezone="$2"
    
    # Extract date parts
    local year="${timestamp:0:4}"
    local month="${timestamp:4:2}"
    local day="${timestamp:6:2}"
    
    # Extract time parts (default to 00:00:00 if not provided)
    local hour="00"
    local minute="00"
    local second="00"
    
    if [[ ${#timestamp} -ge 11 && ${timestamp:9:2} =~ [0-9]{2} ]]; then
        hour="${timestamp:9:2}"
    fi
    
    if [[ ${#timestamp} -ge 13 && ${timestamp:11:2} =~ [0-9]{2} ]]; then
        minute="${timestamp:11:2}"
    fi
    
    if [[ ${#timestamp} -ge 15 && ${timestamp:13:2} =~ [0-9]{2} ]]; then
        second="${timestamp:13:2}"
    fi
    
    # Create timestamp in the format expected by 'date' command
    local formatted_timestamp="${year}-${month}-${day} ${hour}:${minute}:${second}"
    
    # Use date command to convert to UTC
    if [[ "$timezone" != "UTC" && -n "$timezone" ]]; then
        export TZ="$timezone"
        local utc_time=$(date -u -d "$formatted_timestamp" "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
        
        # If the date command fails (e.g., due to unsupported options or format), try alternative approaches
        if [ $? -ne 0 ]; then
            # For macOS, try a different date format
            utc_time=$(date -u -j -f "%Y-%m-%d %H:%M:%S" "$formatted_timestamp" "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
            
            # If that fails too, fall back to creating an RFC3339 timestamp without conversion
            if [ $? -ne 0 ]; then
                echo "${year}-${month}-${day}T${hour}:${minute}:${second}Z"
                echo "Warning: Could not convert time from $timezone to UTC. Using provided time as UTC." >&2
                return
            fi
        fi
        
        echo "$utc_time"
    else
        # If timezone is UTC or empty, just format the timestamp in RFC3339 format
        echo "${year}-${month}-${day}T${hour}:${minute}:${second}Z"
    fi
}

# Function to parse ICS file and insert events into the database
parse_ics_and_insert() {
    local ics_file="$1"
    local user_id="$2"
    local user_timezone="$3"  # User's preferred timezone (fallback)
    
    # Check if file exists
    if [ ! -f "$ics_file" ]; then
        echo "Error: ICS file '$ics_file' not found."
        return 1
    fi

    echo "Parsing ICS file and inserting events for user ID $user_id..."
    
    # Temporary file for SQL commands
    local temp_sql=$(mktemp)
    
    # Start transaction
    echo "BEGIN TRANSACTION;" > "$temp_sql"
    
    # Variables to store event data
    local in_event=false
    local title=""
    local description=""
    local start_time=""
    local end_time=""
    local event_timezone=""
    local duration=60  # Default duration in minutes
    local event_count=0
    local skipped_count=0
    local timezone_count=0
    
    # Read ICS file line by line
    while IFS= read -r line || [ -n "$line" ]; do
        # Remove carriage return if present
        line=$(echo "$line" | tr -d '\r')
        
        # Check for event start/end
        if [ "$line" = "BEGIN:VEVENT" ]; then
            in_event=true
            title=""
            description=""
            start_time=""
            end_time=""
            event_timezone=""
            duration=60  # Reset to default
        elif [ "$line" = "END:VEVENT" ] && [ "$in_event" = true ]; then
            in_event=false
            
            if [ -n "$start_time" ] && [ -n "$title" ]; then
                # Determine which timezone to use
                local tz_to_use="$user_timezone"
                if [ -n "$event_timezone" ]; then
                    tz_to_use="$event_timezone"
                    timezone_count=$((timezone_count + 1))
                fi
                
                # Convert event time to UTC
                local utc_time=$(convert_to_utc "$start_time" "$tz_to_use")
                
                # Check if this event already exists in the database
                if event_exists "$user_id" "$title" "$utc_time"; then
                    skipped_count=$((skipped_count + 1))
                    continue
                fi
                
                # Prepare SQL statement
                # Escape single quotes in title and description
                title=$(echo "$title" | sed "s/'/''/g")
                description=$(echo "$description" | sed "s/'/''/g")
                
                echo "INSERT INTO calendar_events (user_id, title, description, start_time, duration) VALUES ($user_id, '$title', '$description', '$utc_time', $duration);" >> "$temp_sql"
                
                event_count=$((event_count + 1))
            fi
        fi
        
        # Parse event data
        if [ "$in_event" = true ]; then
            # Extract event properties
            if [[ "$line" =~ ^SUMMARY:(.*) ]]; then
                title="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^DESCRIPTION:(.*) ]]; then
                description="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^DTSTART\;TZID=([^:]*):([0-9T]*) ]]; then
                # Format with explicit timezone
                event_timezone="${BASH_REMATCH[1]}"
                start_time="${BASH_REMATCH[2]}"
            elif [[ "$line" =~ ^DTSTART:([0-9TZ]*) ]]; then
                # Format without timezone (implicit UTC)
                start_time="${BASH_REMATCH[1]}"
                # If Z suffix is present, it's explicitly UTC
                if [[ "$start_time" == *Z ]]; then
                    event_timezone="UTC"
                    # Remove Z suffix for our parser
                    start_time="${start_time%Z}"
                fi
            elif [[ "$line" =~ ^DURATION:PT([0-9]*)M ]]; then
                duration="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^DTEND\;TZID=([^:]*):([0-9T]*) ]]; then
                # End time with timezone
                end_time="${BASH_REMATCH[2]}"
                # We'll use the timezone from DTSTART if available
            elif [[ "$line" =~ ^DTEND:([0-9TZ]*) ]]; then
                # End time without timezone
                end_time="${BASH_REMATCH[1]}"
                # Remove Z suffix if present
                if [[ "$end_time" == *Z ]]; then
                    end_time="${end_time%Z}"
                fi
            fi
            
            # Handle multi-line properties (continuation lines start with a space)
            if [[ "$line" =~ ^[[:space:]] ]] && [ -n "$description" ]; then
                # This is a continuation of the previous line (probably description)
                description="$description $(echo "$line" | sed 's/^ //')"
            fi
            
            # Calculate duration from end time if available and DURATION isn't specified
            if [ -n "$end_time" ] && [ -n "$start_time" ] && [[ ! "$line" =~ ^DURATION ]]; then
                # This is a simplified duration calculation that works for same-day events
                # For more complex duration calculations, we would need a more sophisticated approach
                
                # Extract time parts
                local start_hour="00"
                local start_min="00"
                local end_hour="00"
                local end_min="00"
                
                # Extract hours and minutes if available
                if [[ ${#start_time} -ge 11 && ${start_time:9:2} =~ [0-9]{2} ]]; then
                    start_hour=${start_time:9:2}
                fi
                
                if [[ ${#start_time} -ge 13 && ${start_time:11:2} =~ [0-9]{2} ]]; then
                    start_min=${start_time:11:2}
                fi
                
                if [[ ${#end_time} -ge 11 && ${end_time:9:2} =~ [0-9]{2} ]]; then
                    end_hour=${end_time:9:2}
                fi
                
                if [[ ${#end_time} -ge 13 && ${end_time:11:2} =~ [0-9]{2} ]]; then
                    end_min=${end_time:11:2}
                fi
                
                local start_mins=$((10#$start_hour * 60 + 10#$start_min))
                local end_mins=$((10#$end_hour * 60 + 10#$end_min))
                
                # If end time is earlier than start time, assume it's next day
                if [ $end_mins -lt $start_mins ]; then
                    end_mins=$((end_mins + 24 * 60))
                fi
                
                duration=$((end_mins - start_mins))
                
                # Use default if calculation fails
                if [ $duration -le 0 ]; then
                    duration=60
                fi
            fi
        fi
    done < "$ics_file"
    
    # Commit transaction
    echo "COMMIT;" >> "$temp_sql"
    
    # Execute SQL commands
    sqlite3 "$DB_FILE" < "$temp_sql"
    local exit_code=$?
    
    # Remove temporary file
    rm -f "$temp_sql"
    
    if [ $exit_code -eq 0 ]; then
        echo "Successfully imported $event_count events."
        echo "Skipped $skipped_count duplicate events."
        echo "Used event-specific timezone for $timezone_count events."
        return 0
    else
        echo "Error occurred while importing events."
        return 1
    fi
}

# Function to ask if user wants to delete existing events
ask_delete_existing() {
    local user_id="$1"
    
    # Count existing events
    local count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM calendar_events WHERE user_id = $user_id;")
    
    if [ "$count" -gt 0 ]; then
        echo "User already has $count existing calendar events."
        read -p "Do you want to delete all existing events before importing? (y/n): " choice
        
        case "$choice" in
            y|Y )
                echo "Deleting existing events..."
                sqlite3 "$DB_FILE" "DELETE FROM calendar_events WHERE user_id = $user_id;"
                echo "Deleted $count events."
                return 0
                ;;
            * )
                echo "Keeping existing events. Will only import new events."
                return 1
                ;;
        esac
    fi
    
    return 1  # No events to delete
}

# Function to fix existing malformed entries in the database
fix_existing_malformed_entries() {
    local user_id="$1"
    
    # Count malformed entries
    local count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM calendar_events WHERE user_id = $user_id AND start_time LIKE '%::%';")
    
    if [ "$count" -gt 0 ]; then
        echo "Found $count existing entries with malformed timestamps."
        read -p "Do you want to fix these entries? (y/n): " choice
        
        case "$choice" in
            y|Y )
                echo "Fixing malformed timestamps..."
                sqlite3 "$DB_FILE" "UPDATE calendar_events SET start_time = REPLACE(start_time, 'T::Z', 'T00:00:00Z') WHERE user_id = $user_id AND start_time LIKE '%::%';"
                echo "Fixed $count entries."
                return 0
                ;;
            * )
                echo "Skipping repair of malformed entries."
                return 1
                ;;
        esac
    fi
    
    return 1  # No malformed entries
}

# Main script

echo "=== Forum3270 Calendar Import Tool ==="
echo "This script imports events from an .ics file into a user's calendar."
echo "Events will be converted to UTC and stored with respect to their original time zones."

# Ask for username
while true; do
    read -p "Enter username: " username
    
    if validate_username "$username"; then
        if check_user_exists "$username"; then
            break
        fi
    fi
    
    echo "Please try again."
done

# Get user ID
user_id=$(get_user_id "$username")
echo "Found user ID: $user_id"

# Get user's timezone preference
timezone=$(get_user_timezone "$user_id")
echo "User timezone preference: $timezone"

# Fix any existing malformed entries
fix_existing_malformed_entries "$user_id"

# Ask if user wants to delete existing events
ask_delete_existing "$user_id"

# Ask for ICS file
while true; do
    read -p "Enter path to .ics calendar file: " ics_file
    
    if [ -f "$ics_file" ]; then
        break
    else
        echo "File not found. Please enter a valid path."
    fi
done

# Parse ICS file and insert events
parse_ics_and_insert "$ics_file" "$user_id" "$timezone"

exit 0 
