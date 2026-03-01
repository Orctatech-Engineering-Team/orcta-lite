#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REQUESTS_DIR="$PROJECT_ROOT/requests"
BASE_FILE="$REQUESTS_DIR/_base.http"

# Default base URL
BASE_URL="http://localhost:3000"

# Usage
usage() {
    echo -e "${BLUE}Usage:${NC} pnpm http <file> [request-name]"
    echo ""
    echo "Arguments:"
    echo "  file          .http file name (without extension) or 'list'"
    echo "  request-name  Optional: run specific request by name (comment above request)"
    echo ""
    echo "Examples:"
    echo "  pnpm http list              # List all .http files"
    echo "  pnpm http health            # Run all requests in health.http"
    echo "  pnpm http health ping       # Run only 'Ping' request"
    echo "  pnpm http posts create      # Run 'Create' request from posts.http"
    echo ""
    echo "Variables:"
    echo "  Set in requests/_base.http or inline with @name = value"
    exit 1
}

# Load variables from base file
declare -A VARS

load_base_vars() {
    if [[ -f "$BASE_FILE" ]]; then
        while IFS= read -r line; do
            if [[ $line =~ ^@([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
                VARS["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
            fi
        done < "$BASE_FILE"
    fi

    # Set default base if not defined
    if [[ -z "${VARS[base]:-}" ]]; then
        VARS[base]="$BASE_URL"
    fi
}

# Replace variables in string
replace_vars() {
    local str="$1"
    for key in "${!VARS[@]}"; do
        str="${str//\{\{$key\}\}/${VARS[$key]}}"
        str="${str//\$$key/${VARS[$key]}}"
    done
    echo "$str"
}

# List available .http files
list_files() {
    echo -e "${BLUE}Available request files:${NC}"
    echo ""
    for f in "$REQUESTS_DIR"/*.http; do
        [[ -f "$f" ]] || continue
        local name=$(basename "$f" .http)
        [[ "$name" == "_base" ]] && continue

        # Count requests in file
        local count=$(grep -c "^###" "$f" 2>/dev/null || echo "0")
        echo -e "  ${GREEN}$name${NC} ($count requests)"

        # List request names
        grep "^###" "$f" | while read -r line; do
            local req_name="${line### }"
            echo -e "    - $req_name"
        done
    done
}

# Parse and execute requests from .http file
run_requests() {
    local file="$1"
    local target_request="${2:-}"
    local file_path="$REQUESTS_DIR/$file.http"

    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}Error:${NC} File not found: $file_path"
        exit 1
    fi

    load_base_vars

    # Also load variables from the target file
    while IFS= read -r line; do
        if [[ $line =~ ^@([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
            VARS["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
        fi
    done < "$file_path"

    local current_name=""
    local method=""
    local url=""
    local headers=()
    local body=""
    local in_body=false
    local request_count=0
    local executed=false

    execute_request() {
        if [[ -z "$method" || -z "$url" ]]; then
            return
        fi

        # Check if we should run this request
        if [[ -n "$target_request" ]]; then
            local name_lower=$(echo "$current_name" | tr '[:upper:]' '[:lower:]')
            local target_lower=$(echo "$target_request" | tr '[:upper:]' '[:lower:]')
            if [[ "$name_lower" != *"$target_lower"* ]]; then
                return
            fi
        fi

        ((request_count++))
        executed=true

        # Replace variables
        url=$(replace_vars "$url")
        body=$(replace_vars "$body")

        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}$current_name${NC}"
        echo -e "${GREEN}$method${NC} $url"
        echo ""

        # Build curl command
        local curl_cmd=(curl -s -w "\n%{http_code}" -X "$method" "$url")

        for header in "${headers[@]}"; do
            header=$(replace_vars "$header")
            curl_cmd+=(-H "$header")
        done

        if [[ -n "$body" ]]; then
            curl_cmd+=(-d "$body")
        fi

        # Execute
        local response
        response=$("${curl_cmd[@]}" 2>&1) || true

        # Split response and status code
        local status_code="${response##*$'\n'}"
        local body_response="${response%$'\n'*}"

        # Color status code
        local status_color="$GREEN"
        if [[ "$status_code" =~ ^4 ]]; then
            status_color="$YELLOW"
        elif [[ "$status_code" =~ ^5 ]]; then
            status_color="$RED"
        fi

        echo -e "${status_color}HTTP $status_code${NC}"
        echo ""

        # Pretty print JSON if possible
        if command -v jq &> /dev/null && [[ -n "$body_response" ]]; then
            echo "$body_response" | jq . 2>/dev/null || echo "$body_response"
        else
            echo "$body_response"
        fi

        echo ""
    }

    # Parse file
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Request separator - execute previous and reset
        if [[ $line =~ ^### ]]; then
            execute_request
            current_name="${line### }"
            method=""
            url=""
            headers=()
            body=""
            in_body=false
            continue
        fi

        # Skip empty lines and comments (but not in body)
        if [[ ! $in_body ]]; then
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            [[ "$line" =~ ^@ ]] && continue  # Skip variable definitions
        fi

        # Parse method and URL
        if [[ -z "$method" && $line =~ ^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)[[:space:]]+(.+)$ ]]; then
            method="${BASH_REMATCH[1]}"
            url="${BASH_REMATCH[2]}"
            continue
        fi

        # Parse headers
        if [[ -z "$body" && ! $in_body && $line =~ ^([A-Za-z-]+):[[:space:]]*(.+)$ ]]; then
            headers+=("${BASH_REMATCH[1]}: ${BASH_REMATCH[2]}")
            continue
        fi

        # Body starts after empty line or directly with { or [
        if [[ $line =~ ^\{|\[|\" || -z "$line" && -n "$method" ]]; then
            in_body=true
        fi

        if [[ $in_body && -n "$line" ]]; then
            body+="$line"
        fi

    done < "$file_path"

    # Execute last request
    execute_request

    if [[ "$executed" == false && -n "$target_request" ]]; then
        echo -e "${YELLOW}No request matching '$target_request' found in $file.http${NC}"
        exit 1
    fi

    if [[ $request_count -eq 0 ]]; then
        echo -e "${YELLOW}No requests found in $file.http${NC}"
    fi
}

# Main
if [[ $# -lt 1 ]]; then
    usage
fi

case "$1" in
    list|ls)
        list_files
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        run_requests "$1" "${2:-}"
        ;;
esac
