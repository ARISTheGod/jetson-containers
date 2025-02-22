#!/bin/bash

#set -x # Enable debug mode

print_section() {
    local message=$1
    echo -e "\n\033[48;5;130m\033[97m >>> $message \033[0m"
}

log() {
    local level=$1
    local message=$2
    case "$level" in
        INFO)  echo -e "\033[36m[INFO]\033[0m $message" ;;      # Cyan text
        WARN)  echo -e "\033[38;5;205m[WARN]\033[0m $message" ;; # Magenta text
        ERROR) echo -e "\033[1;31m[ERROR]\033[0m $message" ;;   # Red text (bold)
        *)     echo "[LOG]  $message" ;;                        # Default log
    esac
}

parse_args() {
    TEST_FUNCTION=""

    for arg in "$@"; do
        case "$arg" in
            --test=*)
                TEST_FUNCTION="${arg#*=}"
                ;;
            --help)
                print_help
                exit 0
                ;;
            *)
                log ERROR "Unknown parameter: $arg"
                exit 1
                ;;
        esac
    done
}

# Function to get available RAM in MB
get_free_ram() {
    free -m | awk '/^Mem:/ {print $7}'
}

# Function to format numbers with commas
format_number() {
    printf "%'d\n" "$1"
}


# Detect the display manager (GDM, LightDM, etc.)
detect_display_manager() {
    if systemctl list-units --type=service | grep -q 'gdm.service'; then
        echo "gdm"
    elif systemctl list-units --type=service | grep -q 'lightdm.service'; then
        echo "lightdm"
    else
        echo ""
    fi
}

toggle_gui_mode() {

    # Check current GUI status
    current_target=$(systemctl get-default)

    if [[ "$current_target" == "multi-user.target" ]]; then
        gui_status="DISABLED"
        suggested_action="Enable"
        new_target="graphical.target"
    else
        gui_status="ENABLED"
        suggested_action="Disable"
        new_target="multi-user.target"
    fi

    # Display current status
    log INFO "🔎 Current GUI Status: $gui_status"
    log INFO "   Suggested Action: $suggested_action GUI mode"
    log INFO "   (multi-user.target = No GUI, graphical.target = GUI enabled)"
    echo

    # Ask user to switch mode
    read -p "Would you like to $suggested_action the GUI? (y/N): " confirm
    confirm=${confirm,,}  # Convert to lowercase

    if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
        echo "❌ Operation aborted by user."
        return 1
    fi

    # Measure RAM before switching
    ram_before=$(get_free_ram)

    # Apply the GUI mode change
    log INFO "🔄 Switching GUI mode..."
    sudo systemctl set-default "$new_target"

    if [[ "$new_target" == "multi-user.target" ]]; then
        # If disabling GUI, stop the display manager immediately
        display_manager=$(detect_display_manager)

        if [[ -n "$display_manager" ]]; then
            echo "⏳ Stopping $display_manager to free up RAM immediately..."
            sudo systemctl stop "$display_manager"
        fi

        # Kill any remaining GUI sessions
        echo "🔪 Killing remaining GUI processes..."
        sudo pkill -f Xorg
        sudo pkill -f gnome-session
        sudo pkill -f plasmashell
        sudo pkill -f xfwm4
        sudo pkill -f lxsession
    fi

    # Measure RAM after switching
    sleep 5  # Give the system time to release memory
    ram_after=$(get_free_ram)

    # Calculate RAM difference
    ram_diff=$((ram_after - ram_before))

    # Format numbers with commas
    formatted_ram_before=$(format_number "$ram_before")
    formatted_ram_after=$(format_number "$ram_after")
    formatted_ram_diff=$(format_number "${ram_diff#-}")  # Remove negative sign

    # Display results
    log INFO "✅ GUI mode switched to: $new_target"
    log INFO "💾 Available RAM before: ${formatted_ram_before}MB"
    log INFO "💾 Available RAM after:  ${formatted_ram_after}MB"

    if [[ "$ram_diff" -gt 0 ]]; then
        echo "🚀 Freed RAM:  ${formatted_ram_diff}MB (Disabling GUI)"
    elif [[ "$ram_diff" -lt 0 ]]; then
        echo "⬇️  Additional RAM used: ${formatted_ram_diff}MB (Enabling GUI)"
    else
        echo "ℹ️  No significant RAM change detected."
    fi

    log INFO "🔄 To apply changes, reboot your system: sudo reboot"
}

main() {

    parse_args "$@"

    if [[ -n "$TEST_FUNCTION" ]]; then
        # Check if the function exists before calling
        if declare -F "$TEST_FUNCTION" > /dev/null; then
            log WARN "Running test for function: $TEST_FUNCTION"
            "$TEST_FUNCTION"  # Call the function dynamically
            exit 0
        else
            log ERROR "Function '$TEST_FUNCTION' not found."
            exit 1
        fi
    fi

    # Normal execution flow if no --test flag is supplied
    log INFO "Running full setup..."

    toggle_gui_mode

}

# Execute main function
main "$@"