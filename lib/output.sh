#!/usr/bin/env bash
#
# output.sh - Unified output styling for claw
# Provides consistent colors, formatting, and visual elements
#

# ============================================================================
# Color Definitions
# ============================================================================

# Check if terminal supports colors
if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
    # Primary colors
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    GRAY='\033[0;90m'

    # Bold variants
    BOLD='\033[1m'
    DIM='\033[2m'

    # Background colors
    BG_RED='\033[41m'
    BG_GREEN='\033[42m'
    BG_YELLOW='\033[43m'
    BG_BLUE='\033[44m'

    # Reset
    NC='\033[0m'
else
    # No colors for non-interactive terminals
    RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE='' GRAY=''
    BOLD='' DIM=''
    BG_RED='' BG_GREEN='' BG_YELLOW='' BG_BLUE=''
    NC=''
fi

# ============================================================================
# Status Icons
# ============================================================================

ICON_SUCCESS="✓"
ICON_ERROR="✗"
ICON_WARNING="⚠"
ICON_INFO="ℹ"
ICON_PENDING="○"
ICON_RUNNING="●"
ICON_ARROW="→"
ICON_CHECK="✓"
ICON_CROSS="✗"
ICON_STAR="★"
ICON_CLAW="🦞"

# Spinner frames for animations
SPINNER_FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

# ============================================================================
# Box Drawing Characters
# ============================================================================

BOX_TL="┌"  # Top-left
BOX_TR="┐"  # Top-right
BOX_BL="└"  # Bottom-left
BOX_BR="┘"  # Bottom-right
BOX_H="─"   # Horizontal
BOX_V="│"   # Vertical

# Double-line variants for headers
BOX2_TL="╔"
BOX2_TR="╗"
BOX2_BL="╚"
BOX2_BR="╝"
BOX2_H="═"
BOX2_V="║"

# ============================================================================
# Output Functions
# ============================================================================

# Print a success message
# Usage: print_success "message"
print_success() {
    echo -e "${GREEN}${ICON_SUCCESS}${NC} $1"
}

# Print an error message
# Usage: print_error "message"
print_error() {
    echo -e "${RED}${ICON_ERROR}${NC} $1" >&2
}

# Print a warning message
# Usage: print_warning "message"
print_warning() {
    echo -e "${YELLOW}${ICON_WARNING}${NC} $1"
}

# Print an info message
# Usage: print_info "message"
print_info() {
    echo -e "${BLUE}${ICON_INFO}${NC} $1"
}

# Print a step in a process
# Usage: print_step "Step description"
print_step() {
    echo -e "${CYAN}${ICON_ARROW}${NC} $1"
}

# Print dimmed/muted text
# Usage: print_dim "message"
print_dim() {
    echo -e "${GRAY}$1${NC}"
}

# Print bold text
# Usage: print_bold "message"
print_bold() {
    echo -e "${BOLD}$1${NC}"
}

# ============================================================================
# Section Headers
# ============================================================================

# Print a section header with box
# Usage: print_header "Title"
print_header() {
    local title="$1"
    local width="${2:-70}"
    local padding=$(( (width - ${#title} - 2) / 2 ))
    local pad_str=""
    for ((i=0; i<padding; i++)); do pad_str+=" "; done

    echo -e "${WHITE}${BOX2_TL}$(printf '%0.s═' $(seq 1 $width))${BOX2_TR}${NC}"
    echo -e "${WHITE}${BOX2_V}${pad_str}${ICON_CLAW} ${title}${pad_str}${BOX2_V}${NC}"
    echo -e "${WHITE}${BOX2_BL}$(printf '%0.s═' $(seq 1 $width))${BOX2_BR}${NC}"
}

# Print a section title (simpler)
# Usage: print_section "Title" [color]
print_section() {
    local title="$1"
    local color="${2:-$CYAN}"
    echo -e "${color}${BOX_TL}${BOX_H} ${title} $(printf '%0.s─' $(seq 1 $((60 - ${#title}))))${BOX_TR}${NC}"
}

# Print section footer
# Usage: print_section_end [color]
print_section_end() {
    local color="${1:-$CYAN}"
    echo -e "${color}${BOX_BL}$(printf '%0.s─' $(seq 1 68))${BOX_BR}${NC}"
}

# ============================================================================
# Progress Indicators
# ============================================================================

# Print a progress bar
# Usage: print_progress current total [width]
print_progress() {
    local current="$1"
    local total="$2"
    local width="${3:-30}"

    if [[ $total -eq 0 ]]; then
        echo "[$(printf '%0.s░' $(seq 1 $width))] 0%"
        return
    fi

    local percent=$(( (current * 100) / total ))
    local filled=$(( (current * width) / total ))
    local empty=$(( width - filled ))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    echo -e "[${GREEN}${bar}${NC}] ${percent}%"
}

# Show a spinner (call in a loop)
# Usage: show_spinner
_spinner_idx=0
show_spinner() {
    local frame="${SPINNER_FRAMES[$_spinner_idx]}"
    _spinner_idx=$(( (_spinner_idx + 1) % ${#SPINNER_FRAMES[@]} ))
    printf "\r${CYAN}%s${NC} " "$frame"
}

# Clear spinner
clear_spinner() {
    printf "\r   \r"
}

# ============================================================================
# Tables
# ============================================================================

# Print a simple key-value pair
# Usage: print_kv "Key" "Value"
print_kv() {
    local key="$1"
    local value="$2"
    printf "${WHITE}%-15s${NC} %s\n" "$key:" "$value"
}

# Print a table row
# Usage: print_row "col1" "col2" "col3" ...
print_row() {
    local format="${TABLE_FORMAT:-%-20s %-20s %-20s}"
    printf "${format}\n" "$@"
}

# Print a table header
# Usage: print_table_header "col1" "col2" "col3" ...
print_table_header() {
    local format="${TABLE_FORMAT:-%-20s %-20s %-20s}"
    printf "${BOLD}${format}${NC}\n" "$@"
    echo -e "${GRAY}$(printf '%0.s─' $(seq 1 60))${NC}"
}

# ============================================================================
# Status Badges
# ============================================================================

# Print a status badge
# Usage: print_badge "text" "color"
print_badge() {
    local text="$1"
    local color="${2:-$BLUE}"
    echo -e "${color}[${text}]${NC}"
}

# Print status with appropriate color
# Usage: print_status "status"
print_status() {
    local status="$1"
    case "$status" in
        success|completed|pass|ok)
            echo -e "${GREEN}${ICON_SUCCESS} ${status}${NC}"
            ;;
        error|failed|fail)
            echo -e "${RED}${ICON_ERROR} ${status}${NC}"
            ;;
        warning|warn)
            echo -e "${YELLOW}${ICON_WARNING} ${status}${NC}"
            ;;
        pending|waiting)
            echo -e "${GRAY}${ICON_PENDING} ${status}${NC}"
            ;;
        running|in_progress)
            echo -e "${BLUE}${ICON_RUNNING} ${status}${NC}"
            ;;
        *)
            echo -e "${status}"
            ;;
    esac
}

# ============================================================================
# Utility Functions
# ============================================================================

# Truncate string to max length
# Usage: truncate "string" [max_length]
truncate_str() {
    local str="$1"
    local max="${2:-60}"
    if [[ ${#str} -gt $max ]]; then
        echo "${str:0:$((max-3))}..."
    else
        echo "$str"
    fi
}

# Pad string to width
# Usage: pad_str "string" width [char]
pad_str() {
    local str="$1"
    local width="$2"
    local char="${3:- }"
    printf "%-${width}s" "$str"
}

# Center string
# Usage: center_str "string" width
center_str() {
    local str="$1"
    local width="$2"
    local pad=$(( (width - ${#str}) / 2 ))
    printf "%*s%s%*s" $pad "" "$str" $pad ""
}
