#!/bin/bash

# Reset Permissions Script for AutoQuill
# This script clears all macOS permissions for the app to test permission prompting

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# App bundle identifier - adjust if needed
BUNDLE_ID="com.divyansh-lalwani.autoquill-ai"
APP_NAME="AutoQuill"

print_status "Resetting permissions for ${APP_NAME}..."

# Kill the app if it's running
print_status "Stopping ${APP_NAME} if running..."
pkill -f "${APP_NAME}" 2>/dev/null || true
sleep 2

# Function to reset a specific permission
reset_permission() {
    local permission_type="$1"
    local permission_name="$2"
    
    print_status "Resetting ${permission_name} permission..."
    
    # Use tccutil to reset the permission
    if tccutil reset "${permission_type}" "${BUNDLE_ID}" 2>/dev/null; then
        print_success "${permission_name} permission reset successfully"
    else
        print_warning "Could not reset ${permission_name} permission (this is normal if it wasn't granted)"
    fi
}

# Reset individual permissions
reset_permission "Microphone" "Microphone"
reset_permission "Accessibility" "Accessibility" 
reset_permission "ScreenCapture" "Screen Recording"

# Clear stored permission data from app's Hive storage
print_status "Clearing stored permission data from app storage..."

# Get the application support directory for the app
APP_SUPPORT_DIR="$HOME/Library/Application Support/com.example.autoquill_ai"
if [ -d "$APP_SUPPORT_DIR" ]; then
    # Remove the settings box that contains stored permission statuses
    if [ -f "$APP_SUPPORT_DIR/settings.hive" ]; then
        print_status "Removing stored permission data..."
        rm -f "$APP_SUPPORT_DIR/settings.hive" 2>/dev/null || true
        print_success "Stored permission data cleared"
    else
        print_status "No stored permission data found"
    fi
else
    print_status "App storage directory not found (app may not have been run yet)"
fi

# Alternative: Clear Flutter app storage
FLUTTER_APP_SUPPORT="$HOME/Library/Application Support/com.divyansh-lalwani.autoquill-ai"
if [ -d "$FLUTTER_APP_SUPPORT" ]; then
    print_status "Clearing Flutter app storage..."
    
    # Look for Hive files that might contain permission data
    find "$FLUTTER_APP_SUPPORT" -name "*.hive" -type f 2>/dev/null | while read -r hive_file; do
        print_status "Removing Hive file: $(basename "$hive_file")"
        rm -f "$hive_file" 2>/dev/null || true
    done
    
    print_success "Flutter app storage cleared"
else
    print_status "Flutter app storage directory not found"
fi

print_status "Reset complete!"
print_warning "Please restart ${APP_NAME} to test permission prompts from a clean state."
print_status "Note: You may need to restart your Mac if accessibility permissions don't reset properly."

echo
print_status "To verify the reset worked:"
echo "  1. Launch ${APP_NAME}"
echo "  2. Go to the Permissions step in onboarding"
echo "  3. All permissions should show 'Not Granted'"
echo "  4. Clicking 'Grant Permission' should show system prompts"

echo
print_status "If problems persist, you can manually reset in System Preferences:"
echo "  System Preferences → Security & Privacy → Privacy → [Permission Type]"
echo "  Remove ${APP_NAME} from the list if it appears"
