#!/bin/bash
#
# Nexora Installation Script
# Nexora 瀹夎鑴氭湰
# Usage: curl -sSL ./deploy/install.sh | bash
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="nexora/gateway"
INSTALL_DIR="/opt/Nexora"
SERVICE_NAME="Nexora"
SERVICE_USER="Nexora"
CONFIG_DIR="/etc/nexora"

# Server configuration (will be set by user)
SERVER_HOST="0.0.0.0"
SERVER_PORT="8080"

# Language (default: zh = Chinese)
LANG_CHOICE="zh"

# ============================================================
# Language strings / 璇█瀛楃涓?# ============================================================

# Chinese strings
declare -A MSG_ZH=(
    # General
    ["info"]="淇℃伅"
    ["success"]="鎴愬姛"
    ["warning"]="璀﹀憡"
    ["error"]="閿欒"

    # Language selection
    ["select_lang"]="璇烽€夋嫨璇█ / Select language"
    ["lang_zh"]="涓枃"
    ["lang_en"]="English"
    ["enter_choice"]="璇疯緭鍏ラ€夋嫨 (榛樿: 1)"

    # Installation
    ["install_title"]="Nexora 瀹夎鑴氭湰"
    ["run_as_root"]="璇蜂娇鐢?root 鏉冮檺杩愯 (浣跨敤 sudo)"
    ["detected_platform"]="妫€娴嬪埌骞冲彴"
    ["unsupported_arch"]="涓嶆敮鎸佺殑鏋舵瀯"
    ["unsupported_os"]="涓嶆敮鎸佺殑鎿嶄綔绯荤粺"
    ["missing_deps"]="缂哄皯渚濊禆"
    ["install_deps_first"]="璇峰厛瀹夎浠ヤ笅渚濊禆"
    ["fetching_version"]="姝ｅ湪鑾峰彇鏈€鏂扮増鏈?.."
    ["latest_version"]="鏈€鏂扮増鏈?
    ["failed_get_version"]="鑾峰彇鏈€鏂扮増鏈け璐?
    ["downloading"]="姝ｅ湪涓嬭浇"
    ["download_failed"]="涓嬭浇澶辫触"
    ["verifying_checksum"]="姝ｅ湪鏍￠獙鏂囦欢..."
    ["checksum_verified"]="鏍￠獙閫氳繃"
    ["checksum_failed"]="鏍￠獙澶辫触"
    ["checksum_not_found"]="鏃犳硶楠岃瘉鏍￠獙鍜岋紙checksums.txt 鏈壘鍒帮級"
    ["extracting"]="姝ｅ湪瑙ｅ帇..."
    ["binary_installed"]="浜岃繘鍒舵枃浠跺凡瀹夎鍒?
    ["user_exists"]="鐢ㄦ埛宸插瓨鍦?
    ["creating_user"]="姝ｅ湪鍒涘缓绯荤粺鐢ㄦ埛"
    ["user_created"]="鐢ㄦ埛宸插垱寤?
    ["setting_up_dirs"]="姝ｅ湪璁剧疆鐩綍..."
    ["dirs_configured"]="鐩綍閰嶇疆瀹屾垚"
    ["installing_service"]="姝ｅ湪瀹夎 systemd 鏈嶅姟..."
    ["service_installed"]="systemd 鏈嶅姟宸插畨瑁?
    ["ready_for_setup"]="鍑嗗灏辩华锛屽彲浠ュ惎鍔ㄨ缃悜瀵?

    # Completion
    ["install_complete"]="Nexora 瀹夎瀹屾垚锛?
    ["install_dir"]="瀹夎鐩綍"
    ["next_steps"]="鍚庣画姝ラ"
    ["step1_check_services"]="纭繚 PostgreSQL 鍜?Redis 姝ｅ湪杩愯锛?
    ["step2_start_service"]="鍚姩 Nexora 鏈嶅姟锛?
    ["step3_enable_autostart"]="璁剧疆寮€鏈鸿嚜鍚細"
    ["step4_open_wizard"]="鍦ㄦ祻瑙堝櫒涓墦寮€璁剧疆鍚戝锛?
    ["wizard_guide"]="璁剧疆鍚戝灏嗗紩瀵兼偍瀹屾垚锛?
    ["wizard_db"]="鏁版嵁搴撻厤缃?
    ["wizard_redis"]="Redis 閰嶇疆"
    ["wizard_admin"]="绠＄悊鍛樿处鍙峰垱寤?
    ["useful_commands"]="甯哥敤鍛戒护"
    ["cmd_status"]="鏌ョ湅鐘舵€?
    ["cmd_logs"]="鏌ョ湅鏃ュ織"
    ["cmd_restart"]="閲嶅惎鏈嶅姟"
    ["cmd_stop"]="鍋滄鏈嶅姟"

    # Upgrade
    ["upgrading"]="姝ｅ湪鍗囩骇 Nexora..."
    ["current_version"]="褰撳墠鐗堟湰"
    ["stopping_service"]="姝ｅ湪鍋滄鏈嶅姟..."
    ["backup_created"]="澶囦唤宸插垱寤?
    ["starting_service"]="姝ｅ湪鍚姩鏈嶅姟..."
    ["upgrade_complete"]="鍗囩骇瀹屾垚锛?

    # Version install
    ["installing_version"]="姝ｅ湪瀹夎鎸囧畾鐗堟湰"
    ["version_not_found"]="鎸囧畾鐗堟湰涓嶅瓨鍦?
    ["same_version"]="宸茬粡鏄鐗堟湰锛屾棤闇€鎿嶄綔"
    ["rollback_complete"]="鐗堟湰鍥為€€瀹屾垚锛?
    ["install_version_complete"]="鎸囧畾鐗堟湰瀹夎瀹屾垚锛?
    ["validating_version"]="姝ｅ湪楠岃瘉鐗堟湰..."
    ["available_versions"]="鍙敤鐗堟湰鍒楄〃"
    ["fetching_versions"]="姝ｅ湪鑾峰彇鍙敤鐗堟湰..."
    ["not_installed"]="Nexora 灏氭湭瀹夎锛岃鍏堟墽琛屽叏鏂板畨瑁?
    ["fresh_install_hint"]="鐢ㄦ硶"

    # Uninstall
    ["uninstall_confirm"]="杩欏皢浠庣郴缁熶腑绉婚櫎 Nexora銆?
    ["are_you_sure"]="纭畾瑕佺户缁悧锛?y/N)"
    ["uninstall_cancelled"]="鍗歌浇宸插彇娑?
    ["removing_files"]="姝ｅ湪绉婚櫎鏂囦欢..."
    ["removing_install_dir"]="姝ｅ湪绉婚櫎瀹夎鐩綍..."
    ["removing_user"]="姝ｅ湪绉婚櫎鐢ㄦ埛..."
    ["config_not_removed"]="閰嶇疆鐩綍鏈绉婚櫎"
    ["remove_manually"]="濡備笉鍐嶉渶瑕侊紝璇锋墜鍔ㄥ垹闄?
    ["removing_install_lock"]="姝ｅ湪绉婚櫎瀹夎閿佹枃浠?.."
    ["install_lock_removed"]="瀹夎閿佹枃浠跺凡绉婚櫎锛岄噸鏂板畨瑁呮椂灏嗚繘鍏ヨ缃悜瀵?
    ["purge_prompt"]="鏄惁鍚屾椂鍒犻櫎閰嶇疆鐩綍锛熻繖灏嗘竻闄ゆ墍鏈夐厤缃拰鏁版嵁 [y/N]: "
    ["removing_config_dir"]="姝ｅ湪绉婚櫎閰嶇疆鐩綍..."
    ["uninstall_complete"]="Nexora 宸插嵏杞?

    # Help
    ["usage"]="鐢ㄦ硶"
    ["cmd_none"]="(鏃犲弬鏁?"
    ["cmd_install"]="瀹夎 Nexora"
    ["cmd_upgrade"]="鍗囩骇鍒版渶鏂扮増鏈?
    ["cmd_uninstall"]="鍗歌浇 Nexora"
    ["cmd_install_version"]="瀹夎/鍥為€€鍒版寚瀹氱増鏈?
    ["cmd_list_versions"]="鍒楀嚭鍙敤鐗堟湰"
    ["opt_version"]="鎸囧畾瑕佸畨瑁呯殑鐗堟湰鍙?(渚嬪: v1.0.0)"

    # Server configuration
    ["server_config_title"]="鏈嶅姟鍣ㄩ厤缃?
    ["server_config_desc"]="閰嶇疆 Nexora 鏈嶅姟鐩戝惉鍦板潃"
    ["server_host_prompt"]="鏈嶅姟鍣ㄧ洃鍚湴鍧€"
    ["server_host_hint"]="0.0.0.0 琛ㄧず鐩戝惉鎵€鏈夌綉鍗★紝127.0.0.1 浠呮湰鍦拌闂?
    ["server_port_prompt"]="鏈嶅姟鍣ㄧ鍙?
    ["server_port_hint"]="寤鸿浣跨敤 1024-65535 涔嬮棿鐨勭鍙?
    ["server_config_summary"]="鏈嶅姟鍣ㄩ厤缃?
    ["invalid_port"]="鏃犳晥绔彛鍙凤紝璇疯緭鍏?1-65535 涔嬮棿鐨勬暟瀛?

    # Service management
    ["starting_service"]="姝ｅ湪鍚姩鏈嶅姟..."
    ["service_started"]="鏈嶅姟宸插惎鍔?
    ["service_start_failed"]="鏈嶅姟鍚姩澶辫触锛岃妫€鏌ユ棩蹇?
    ["enabling_autostart"]="姝ｅ湪璁剧疆寮€鏈鸿嚜鍚?.."
    ["autostart_enabled"]="寮€鏈鸿嚜鍚凡鍚敤"
    ["getting_public_ip"]="姝ｅ湪鑾峰彇鍏綉 IP..."
    ["public_ip_failed"]="鏃犳硶鑾峰彇鍏綉 IP锛屼娇鐢ㄦ湰鍦?IP"
)

# English strings
declare -A MSG_EN=(
    # General
    ["info"]="INFO"
    ["success"]="SUCCESS"
    ["warning"]="WARNING"
    ["error"]="ERROR"

    # Language selection
    ["select_lang"]="璇烽€夋嫨璇█ / Select language"
    ["lang_zh"]="涓枃"
    ["lang_en"]="English"
    ["enter_choice"]="Enter your choice (default: 1)"

    # Installation
    ["install_title"]="Nexora Installation Script"
    ["run_as_root"]="Please run as root (use sudo)"
    ["detected_platform"]="Detected platform"
    ["unsupported_arch"]="Unsupported architecture"
    ["unsupported_os"]="Unsupported OS"
    ["missing_deps"]="Missing dependencies"
    ["install_deps_first"]="Please install them first"
    ["fetching_version"]="Fetching latest version..."
    ["latest_version"]="Latest version"
    ["failed_get_version"]="Failed to get latest version"
    ["downloading"]="Downloading"
    ["download_failed"]="Download failed"
    ["verifying_checksum"]="Verifying checksum..."
    ["checksum_verified"]="Checksum verified"
    ["checksum_failed"]="Checksum verification failed"
    ["checksum_not_found"]="Could not verify checksum (checksums.txt not found)"
    ["extracting"]="Extracting..."
    ["binary_installed"]="Binary installed to"
    ["user_exists"]="User already exists"
    ["creating_user"]="Creating system user"
    ["user_created"]="User created"
    ["setting_up_dirs"]="Setting up directories..."
    ["dirs_configured"]="Directories configured"
    ["installing_service"]="Installing systemd service..."
    ["service_installed"]="Systemd service installed"
    ["ready_for_setup"]="Ready for Setup Wizard"

    # Completion
    ["install_complete"]="Nexora installation completed!"
    ["install_dir"]="Installation directory"
    ["next_steps"]="NEXT STEPS"
    ["step1_check_services"]="Make sure PostgreSQL and Redis are running:"
    ["step2_start_service"]="Start Nexora service:"
    ["step3_enable_autostart"]="Enable auto-start on boot:"
    ["step4_open_wizard"]="Open the Setup Wizard in your browser:"
    ["wizard_guide"]="The Setup Wizard will guide you through:"
    ["wizard_db"]="Database configuration"
    ["wizard_redis"]="Redis configuration"
    ["wizard_admin"]="Admin account creation"
    ["useful_commands"]="USEFUL COMMANDS"
    ["cmd_status"]="Check status"
    ["cmd_logs"]="View logs"
    ["cmd_restart"]="Restart"
    ["cmd_stop"]="Stop"

    # Upgrade
    ["upgrading"]="Upgrading Nexora..."
    ["current_version"]="Current version"
    ["stopping_service"]="Stopping service..."
    ["backup_created"]="Backup created"
    ["starting_service"]="Starting service..."
    ["upgrade_complete"]="Upgrade completed!"

    # Version install
    ["installing_version"]="Installing specified version"
    ["version_not_found"]="Specified version not found"
    ["same_version"]="Already at this version, no action needed"
    ["rollback_complete"]="Version rollback completed!"
    ["install_version_complete"]="Specified version installed!"
    ["validating_version"]="Validating version..."
    ["available_versions"]="Available versions"
    ["fetching_versions"]="Fetching available versions..."
    ["not_installed"]="Nexora is not installed. Please run a fresh install first"
    ["fresh_install_hint"]="Usage"

    # Uninstall
    ["uninstall_confirm"]="This will remove Nexora from your system."
    ["are_you_sure"]="Are you sure? (y/N)"
    ["uninstall_cancelled"]="Uninstall cancelled"
    ["removing_files"]="Removing files..."
    ["removing_install_dir"]="Removing installation directory..."
    ["removing_user"]="Removing user..."
    ["config_not_removed"]="Config directory was NOT removed."
    ["remove_manually"]="Remove it manually if you no longer need it."
    ["removing_install_lock"]="Removing install lock file..."
    ["install_lock_removed"]="Install lock removed. Setup wizard will appear on next install."
    ["purge_prompt"]="Also remove config directory? This will delete all config and data [y/N]: "
    ["removing_config_dir"]="Removing config directory..."
    ["uninstall_complete"]="Nexora has been uninstalled"

    # Help
    ["usage"]="Usage"
    ["cmd_none"]="(none)"
    ["cmd_install"]="Install Nexora"
    ["cmd_upgrade"]="Upgrade to the latest version"
    ["cmd_uninstall"]="Remove Nexora"
    ["cmd_install_version"]="Install/rollback to a specific version"
    ["cmd_list_versions"]="List available versions"
    ["opt_version"]="Specify version to install (e.g., v1.0.0)"

    # Server configuration
    ["server_config_title"]="Server Configuration"
    ["server_config_desc"]="Configure Nexora server listen address"
    ["server_host_prompt"]="Server listen address"
    ["server_host_hint"]="0.0.0.0 listens on all interfaces, 127.0.0.1 for local only"
    ["server_port_prompt"]="Server port"
    ["server_port_hint"]="Recommended range: 1024-65535"
    ["server_config_summary"]="Server configuration"
    ["invalid_port"]="Invalid port number, please enter a number between 1-65535"

    # Service management
    ["starting_service"]="Starting service..."
    ["service_started"]="Service started"
    ["service_start_failed"]="Service failed to start, please check logs"
    ["enabling_autostart"]="Enabling auto-start on boot..."
    ["autostart_enabled"]="Auto-start enabled"
    ["getting_public_ip"]="Getting public IP..."
    ["public_ip_failed"]="Failed to get public IP, using local IP"
)

# Get message based on current language
msg() {
    local key="$1"
    if [ "$LANG_CHOICE" = "en" ]; then
        echo "${MSG_EN[$key]}"
    else
        echo "${MSG_ZH[$key]}"
    fi
}

# Print functions
print_info() {
    echo -e "${BLUE}[$(msg 'info')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(msg 'success')]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(msg 'warning')]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(msg 'error')]${NC} $1"
}

# Check if running interactively (can access terminal)
# When piped (curl | bash), stdin is not a terminal, but /dev/tty may still be available
is_interactive() {
    # Check if /dev/tty is available (works even when piped)
    [ -e /dev/tty ] && [ -r /dev/tty ] && [ -w /dev/tty ]
}

# Select language
select_language() {
    # If not interactive (piped), use default language
    if ! is_interactive; then
        LANG_CHOICE="zh"
        return
    fi

    echo ""
    echo -e "${CYAN}=============================================="
    echo "  $(msg 'select_lang')"
    echo "==============================================${NC}"
    echo ""
    echo "  1) $(msg 'lang_zh') (榛樿/default)"
    echo "  2) $(msg 'lang_en')"
    echo ""

    read -p "$(msg 'enter_choice'): " lang_input < /dev/tty

    case "$lang_input" in
        2|en|EN|english|English)
            LANG_CHOICE="en"
            ;;
        *)
            LANG_CHOICE="zh"
            ;;
    esac

    echo ""
}

# Validate port number
validate_port() {
    local port="$1"
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
        return 0
    fi
    return 1
}

# Configure server settings
configure_server() {
    # If not interactive (piped), use default settings
    if ! is_interactive; then
        print_info "$(msg 'server_config_summary'): ${SERVER_HOST}:${SERVER_PORT} (default)"
        return
    fi

    echo ""
    echo -e "${CYAN}=============================================="
    echo "  $(msg 'server_config_title')"
    echo "==============================================${NC}"
    echo ""
    echo -e "${BLUE}$(msg 'server_config_desc')${NC}"
    echo ""

    # Server host
    echo -e "${YELLOW}$(msg 'server_host_hint')${NC}"
    read -p "$(msg 'server_host_prompt') [${SERVER_HOST}]: " input_host < /dev/tty
    if [ -n "$input_host" ]; then
        SERVER_HOST="$input_host"
    fi

    echo ""

    # Server port
    echo -e "${YELLOW}$(msg 'server_port_hint')${NC}"
    while true; do
        read -p "$(msg 'server_port_prompt') [${SERVER_PORT}]: " input_port < /dev/tty
        if [ -z "$input_port" ]; then
            # Use default
            break
        elif validate_port "$input_port"; then
            SERVER_PORT="$input_port"
            break
        else
            print_error "$(msg 'invalid_port')"
        fi
    done

    echo ""
    print_info "$(msg 'server_config_summary'): ${SERVER_HOST}:${SERVER_PORT}"
    echo ""
}

# Check if running as root
check_root() {
    # Use 'id -u' instead of $EUID for better compatibility
    # $EUID may not work reliably when script is piped to bash
    if [ "$(id -u)" -ne 0 ]; then
        print_error "$(msg 'run_as_root')"
        exit 1
    fi
}

# Detect OS and architecture
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        *)
            print_error "$(msg 'unsupported_arch'): $ARCH"
            exit 1
            ;;
    esac

    case "$OS" in
        linux)
            OS="linux"
            ;;
        darwin)
            OS="darwin"
            ;;
        *)
            print_error "$(msg 'unsupported_os'): $OS"
            exit 1
            ;;
    esac

    print_info "$(msg 'detected_platform'): ${OS}_${ARCH}"
}

# Check dependencies
check_dependencies() {
    local missing=()

    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi

    if ! command -v tar &> /dev/null; then
        missing+=("tar")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        print_error "$(msg 'missing_deps'): ${missing[*]}"
        print_info "$(msg 'install_deps_first')"
        exit 1
    fi
}

# Get latest release version
get_latest_version() {
    print_info "$(msg 'fetching_version')"
    LATEST_VERSION=$(curl -s --connect-timeout 10 --max-time 30 "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -z "$LATEST_VERSION" ]; then
        print_error "$(msg 'failed_get_version')"
        print_info "Please check your network connection or try again later."
        exit 1
    fi

    print_info "$(msg 'latest_version'): $LATEST_VERSION"
}

# List available versions
list_versions() {
    print_info "$(msg 'fetching_versions')"

    local versions
    versions=$(curl -s --connect-timeout 10 --max-time 30 "https://api.github.com/repos/${GITHUB_REPO}/releases" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | head -20)

    if [ -z "$versions" ]; then
        print_error "$(msg 'failed_get_version')"
        print_info "Please check your network connection or try again later."
        exit 1
    fi

    echo ""
    echo "$(msg 'available_versions'):"
    echo "----------------------------------------"
    echo "$versions" | while read -r version; do
        echo "  $version"
    done
    echo "----------------------------------------"
    echo ""
}

# Validate if a version exists
validate_version() {
    local version="$1"

    # Check for empty version
    if [ -z "$version" ]; then
        print_error "$(msg 'opt_version')" >&2
        exit 1
    fi

    # Ensure version starts with 'v'
    if [[ ! "$version" =~ ^v ]]; then
        version="v$version"
    fi

    print_info "$(msg 'validating_version') $version" >&2

    # Check if the release exists
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 30 "https://api.github.com/repos/${GITHUB_REPO}/releases/tags/${version}" 2>/dev/null)

    # Check for network errors (empty or non-numeric response)
    if [ -z "$http_code" ] || ! [[ "$http_code" =~ ^[0-9]+$ ]]; then
        print_error "Network error: Failed to connect to GitHub API" >&2
        exit 1
    fi

    if [ "$http_code" != "200" ]; then
        print_error "$(msg 'version_not_found'): $version" >&2
        echo "" >&2
        list_versions >&2
        exit 1
    fi

    # Return the normalized version (to stdout)
    echo "$version"
}

# Get current installed version
get_current_version() {
    if [ -f "$INSTALL_DIR/Nexora" ]; then
        # Use grep -E for better compatibility (works on macOS and Linux)
        "$INSTALL_DIR/Nexora" --version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown"
    else
        echo "not_installed"
    fi
}

# Download and extract
download_and_extract() {
    local version_num=${LATEST_VERSION#v}
    local archive_name="Nexora_${version_num}_${OS}_${ARCH}.tar.gz"
    local download_url="https://github.com/${GITHUB_REPO}/releases/download/${LATEST_VERSION}/${archive_name}"
    local checksum_url="https://github.com/${GITHUB_REPO}/releases/download/${LATEST_VERSION}/checksums.txt"

    print_info "$(msg 'downloading') ${archive_name}..."

    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    # Download archive
    if ! curl -sL "$download_url" -o "$TEMP_DIR/$archive_name"; then
        print_error "$(msg 'download_failed')"
        exit 1
    fi

    # Download and verify checksum
    print_info "$(msg 'verifying_checksum')"
    if curl -sL "$checksum_url" -o "$TEMP_DIR/checksums.txt" 2>/dev/null; then
        local expected_checksum=$(grep "$archive_name" "$TEMP_DIR/checksums.txt" | awk '{print $1}')
        local actual_checksum=$(sha256sum "$TEMP_DIR/$archive_name" | awk '{print $1}')

        if [ "$expected_checksum" != "$actual_checksum" ]; then
            print_error "$(msg 'checksum_failed')"
            print_error "Expected: $expected_checksum"
            print_error "Actual: $actual_checksum"
            exit 1
        fi
        print_success "$(msg 'checksum_verified')"
    else
        print_warning "$(msg 'checksum_not_found')"
    fi

    # Extract
    print_info "$(msg 'extracting')"
    tar -xzf "$TEMP_DIR/$archive_name" -C "$TEMP_DIR"

    # Create install directory
    mkdir -p "$INSTALL_DIR"

    # Copy binary
    cp "$TEMP_DIR/Nexora" "$INSTALL_DIR/Nexora"
    chmod +x "$INSTALL_DIR/Nexora"

    # Copy deploy files if they exist in the archive
    if [ -d "$TEMP_DIR/deploy" ]; then
        cp -r "$TEMP_DIR/deploy/"* "$INSTALL_DIR/" 2>/dev/null || true
    fi

    print_success "$(msg 'binary_installed') $INSTALL_DIR/Nexora"
}

# Create system user
create_user() {
    if id "$SERVICE_USER" &>/dev/null; then
        print_info "$(msg 'user_exists'): $SERVICE_USER"
        # Fix: Ensure existing user has /bin/sh shell for sudo to work
        # Previous versions used /bin/false which prevents sudo execution
        local current_shell
        current_shell=$(getent passwd "$SERVICE_USER" 2>/dev/null | cut -d: -f7)
        if [ "$current_shell" = "/bin/false" ] || [ "$current_shell" = "/sbin/nologin" ]; then
            print_info "Fixing user shell for sudo compatibility..."
            if usermod -s /bin/sh "$SERVICE_USER" 2>/dev/null; then
                print_success "User shell updated to /bin/sh"
            else
                print_warning "Failed to update user shell. Service restart may not work automatically."
                print_warning "Manual fix: sudo usermod -s /bin/sh $SERVICE_USER"
            fi
        fi
    else
        print_info "$(msg 'creating_user') $SERVICE_USER..."
        # Use /bin/sh instead of /bin/false to allow sudo execution
        # The user still cannot login interactively (no password set)
        useradd -r -s /bin/sh -d "$INSTALL_DIR" "$SERVICE_USER"
        print_success "$(msg 'user_created')"
    fi
}

# Setup directories and permissions
setup_directories() {
    print_info "$(msg 'setting_up_dirs')"

    # Create directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/data"
    mkdir -p "$CONFIG_DIR"

    # Set ownership
    chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"
    chown -R "$SERVICE_USER:$SERVICE_USER" "$CONFIG_DIR"

    print_success "$(msg 'dirs_configured')"
}

# Install systemd service
install_service() {
    print_info "$(msg 'installing_service')"

    # Create service file with configured host and port
    cat > /etc/systemd/system/Nexora.service << EOF
[Unit]
Description=Nexora - AI API Gateway Platform
Documentation=https://nexora.example/docs
After=network.target postgresql.service redis.service
Wants=postgresql.service redis.service

[Service]
Type=simple
User=Nexora
Group=Nexora
WorkingDirectory=/opt/Nexora
ExecStart=/opt/Nexora/Nexora
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=Nexora

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
ReadWritePaths=/opt/Nexora

# Environment - Server configuration
Environment=GIN_MODE=release
Environment=SERVER_HOST=${SERVER_HOST}
Environment=SERVER_PORT=${SERVER_PORT}

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd
    systemctl daemon-reload

    print_success "$(msg 'service_installed')"
}

# Prepare for setup wizard (no config file needed - setup wizard will create it)
prepare_for_setup() {
    print_success "$(msg 'ready_for_setup')"
}

# Get public IP address
get_public_ip() {
    print_info "$(msg 'getting_public_ip')"

    # Try to get public IP from ipinfo.io
    local response
    response=$(curl -s --connect-timeout 5 --max-time 10 "https://ipinfo.io/json" 2>/dev/null)

    if [ -n "$response" ]; then
        # Extract IP from JSON response using grep and sed (no jq dependency)
        PUBLIC_IP=$(echo "$response" | grep -o '"ip": *"[^"]*"' | sed 's/"ip": *"\([^"]*\)"/\1/')
        if [ -n "$PUBLIC_IP" ]; then
            print_success "Public IP: $PUBLIC_IP"
            return 0
        fi
    fi

    # Fallback to local IP
    print_warning "$(msg 'public_ip_failed')"
    PUBLIC_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR_SERVER_IP")
    return 1
}

# Start service
start_service() {
    print_info "$(msg 'starting_service')"

    if systemctl start Nexora; then
        print_success "$(msg 'service_started')"
        return 0
    else
        print_error "$(msg 'service_start_failed')"
        print_info "sudo journalctl -u Nexora -n 50"
        return 1
    fi
}

# Enable service auto-start
enable_autostart() {
    print_info "$(msg 'enabling_autostart')"

    if systemctl enable Nexora 2>/dev/null; then
        print_success "$(msg 'autostart_enabled')"
        return 0
    else
        print_warning "Failed to enable auto-start"
        return 1
    fi
}

# Print completion message
print_completion() {
    # Use PUBLIC_IP which was set by get_public_ip()
    # Determine display address
    local display_host="${PUBLIC_IP:-YOUR_SERVER_IP}"
    if [ "$SERVER_HOST" = "127.0.0.1" ]; then
        display_host="127.0.0.1"
    fi

    echo ""
    echo "=============================================="
    print_success "$(msg 'install_complete')"
    echo "=============================================="
    echo ""
    echo "$(msg 'install_dir'): $INSTALL_DIR"
    echo "$(msg 'server_config_summary'): ${SERVER_HOST}:${SERVER_PORT}"
    echo ""
    echo "=============================================="
    echo "  $(msg 'step4_open_wizard')"
    echo "=============================================="
    echo ""
    print_info "     http://${display_host}:${SERVER_PORT}"
    echo ""
    echo "     $(msg 'wizard_guide')"
    echo "     - $(msg 'wizard_db')"
    echo "     - $(msg 'wizard_redis')"
    echo "     - $(msg 'wizard_admin')"
    echo ""
    echo "=============================================="
    echo "  $(msg 'useful_commands')"
    echo "=============================================="
    echo ""
    echo "  $(msg 'cmd_status'):   sudo systemctl status Nexora"
    echo "  $(msg 'cmd_logs'):     sudo journalctl -u Nexora -f"
    echo "  $(msg 'cmd_restart'):  sudo systemctl restart nexora"
    echo "  $(msg 'cmd_stop'):     sudo systemctl stop Nexora"
    echo ""
    echo "=============================================="
}

# Upgrade function
upgrade() {
    # Check if Nexora is installed
    if [ ! -f "$INSTALL_DIR/Nexora" ]; then
        print_error "$(msg 'not_installed')"
        print_info "$(msg 'fresh_install_hint'): $0 install"
        exit 1
    fi

    print_info "$(msg 'upgrading')"

    # Get current version
    CURRENT_VERSION=$("$INSTALL_DIR/Nexora" --version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    print_info "$(msg 'current_version'): $CURRENT_VERSION"

    # Stop service
    if systemctl is-active --quiet Nexora; then
        print_info "$(msg 'stopping_service')"
        systemctl stop Nexora
    fi

    # Backup current binary
    cp "$INSTALL_DIR/Nexora" "$INSTALL_DIR/Nexora.backup"
    print_info "$(msg 'backup_created'): $INSTALL_DIR/Nexora.backup"

    # Download and install new version
    get_latest_version
    download_and_extract

    # Set permissions
    chown "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR/Nexora"

    # Start service
    print_info "$(msg 'starting_service')"
    systemctl start Nexora

    print_success "$(msg 'upgrade_complete')"
}

# Install specific version (for upgrade or rollback)
# Requires: Nexora must already be installed
install_version() {
    local target_version="$1"

    # Check if Nexora is installed
    if [ ! -f "$INSTALL_DIR/Nexora" ]; then
        print_error "$(msg 'not_installed')"
        print_info "$(msg 'fresh_install_hint'): $0 install -v $target_version"
        exit 1
    fi

    # Validate and normalize version
    target_version=$(validate_version "$target_version")

    print_info "$(msg 'installing_version'): $target_version"

    # Get current version
    local current_version
    current_version=$(get_current_version)
    print_info "$(msg 'current_version'): $current_version"

    # Check if same version
    if [ "$current_version" = "$target_version" ] || [ "$current_version" = "${target_version#v}" ]; then
        print_warning "$(msg 'same_version')"
        exit 0
    fi

    # Stop service if running
    if systemctl is-active --quiet Nexora; then
        print_info "$(msg 'stopping_service')"
        systemctl stop Nexora
    fi

    # Backup current binary (for potential recovery)
    if [ -f "$INSTALL_DIR/Nexora" ]; then
        local backup_name
        if [ "$current_version" != "unknown" ] && [ "$current_version" != "not_installed" ]; then
            backup_name="Nexora.backup.${current_version}"
        else
            backup_name="Nexora.backup.$(date +%Y%m%d%H%M%S)"
        fi
        cp "$INSTALL_DIR/Nexora" "$INSTALL_DIR/$backup_name"
        print_info "$(msg 'backup_created'): $INSTALL_DIR/$backup_name"
    fi

    # Set LATEST_VERSION to the target version for download_and_extract
    LATEST_VERSION="$target_version"

    # Download and install
    download_and_extract

    # Set permissions
    chown "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR/Nexora"

    # Start service
    print_info "$(msg 'starting_service')"
    if systemctl start Nexora; then
        print_success "$(msg 'service_started')"
    else
        print_error "$(msg 'service_start_failed')"
        print_info "sudo journalctl -u Nexora -n 50"
    fi

    # Print completion message
    local new_version
    new_version=$(get_current_version)
    echo ""
    echo "=============================================="
    print_success "$(msg 'install_version_complete')"
    echo "=============================================="
    echo ""
    echo "  $(msg 'current_version'): $new_version"
    echo ""
}

# Uninstall function
uninstall() {
    print_warning "$(msg 'uninstall_confirm')"

    # If not interactive (piped), require -y flag or skip confirmation
    if ! is_interactive; then
        if [ "${FORCE_YES:-}" != "true" ]; then
            print_error "Non-interactive mode detected. Use 'curl ... | bash -s -- uninstall -y' to confirm."
            exit 1
        fi
    else
        read -p "$(msg 'are_you_sure') " -n 1 -r < /dev/tty
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "$(msg 'uninstall_cancelled')"
            exit 0
        fi
    fi

    print_info "$(msg 'stopping_service')"
    systemctl stop Nexora 2>/dev/null || true
    systemctl disable Nexora 2>/dev/null || true

    print_info "$(msg 'removing_files')"
    rm -f /etc/systemd/system/Nexora.service
    systemctl daemon-reload

    print_info "$(msg 'removing_install_dir')"
    rm -rf "$INSTALL_DIR"

    print_info "$(msg 'removing_user')"
    userdel "$SERVICE_USER" 2>/dev/null || true

    # Remove install lock file (.installed) to allow fresh setup on reinstall
    print_info "$(msg 'removing_install_lock')"
    rm -f "$CONFIG_DIR/.installed" 2>/dev/null || true
    rm -f "$INSTALL_DIR/.installed" 2>/dev/null || true
    print_success "$(msg 'install_lock_removed')"

    # Ask about config directory removal (interactive mode only)
    local remove_config=false
    if [ "${PURGE:-}" = "true" ]; then
        remove_config=true
    elif is_interactive; then
        read -p "$(msg 'purge_prompt')" -n 1 -r < /dev/tty
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            remove_config=true
        fi
    fi

    if [ "$remove_config" = true ]; then
        print_info "$(msg 'removing_config_dir')"
        rm -rf "$CONFIG_DIR"
    else
        print_warning "$(msg 'config_not_removed'): $CONFIG_DIR"
        print_warning "$(msg 'remove_manually')"
    fi

    print_success "$(msg 'uninstall_complete')"
}

# Main
main() {
    # Parse flags first
    local target_version=""
    local positional_args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--yes)
                FORCE_YES="true"
                shift
                ;;
            --purge)
                PURGE="true"
                shift
                ;;
            -v|--version)
                if [ -n "${2:-}" ] && [[ ! "$2" =~ ^- ]]; then
                    target_version="$2"
                    shift 2
                else
                    echo "Error: --version requires a version argument"
                    exit 1
                fi
                ;;
            --version=*)
                target_version="${1#*=}"
                if [ -z "$target_version" ]; then
                    echo "Error: --version requires a version argument"
                    exit 1
                fi
                shift
                ;;
            *)
                positional_args+=("$1")
                shift
                ;;
        esac
    done

    # Restore positional arguments
    set -- "${positional_args[@]}"

    # Select language first
    select_language

    echo ""
    echo "=============================================="
    echo "       $(msg 'install_title')"
    echo "=============================================="
    echo ""

    # Parse commands
    case "${1:-}" in
        upgrade|update)
            check_root
            detect_platform
            check_dependencies
            if [ -n "$target_version" ]; then
                # Upgrade to specific version
                install_version "$target_version"
            else
                # Upgrade to latest
                upgrade
            fi
            exit 0
            ;;
        install)
            # Install with optional version
            check_root
            detect_platform
            check_dependencies
            if [ -n "$target_version" ]; then
                # Install specific version (fresh install or rollback)
                if [ -f "$INSTALL_DIR/Nexora" ]; then
                    # Already installed, treat as version change
                    install_version "$target_version"
                else
                    # Fresh install with specific version
                    configure_server
                    LATEST_VERSION=$(validate_version "$target_version")
                    download_and_extract
                    create_user
                    setup_directories
                    install_service
                    prepare_for_setup
                    get_public_ip
                    start_service
                    enable_autostart
                    print_completion
                fi
            else
                # Fresh install with latest version
                configure_server
                get_latest_version
                download_and_extract
                create_user
                setup_directories
                install_service
                prepare_for_setup
                get_public_ip
                start_service
                enable_autostart
                print_completion
            fi
            exit 0
            ;;
        rollback)
            # Rollback to a specific version (alias for install with version)
            if [ -z "$target_version" ] && [ -n "${2:-}" ]; then
                target_version="$2"
            fi
            if [ -z "$target_version" ]; then
                print_error "$(msg 'opt_version')"
                echo ""
                echo "Usage: $0 rollback -v <version>"
                echo "       $0 rollback <version>"
                echo ""
                list_versions
                exit 1
            fi
            check_root
            detect_platform
            check_dependencies
            install_version "$target_version"
            exit 0
            ;;
        list-versions|versions)
            list_versions
            exit 0
            ;;
        uninstall|remove)
            check_root
            uninstall
            exit 0
            ;;
        --help|-h)
            echo "$(msg 'usage'): $0 [command] [options]"
            echo ""
            echo "Commands:"
            echo "  $(msg 'cmd_none')            $(msg 'cmd_install')"
            echo "  install              $(msg 'cmd_install')"
            echo "  upgrade              $(msg 'cmd_upgrade')"
            echo "  rollback <version>   $(msg 'cmd_install_version')"
            echo "  list-versions        $(msg 'cmd_list_versions')"
            echo "  uninstall            $(msg 'cmd_uninstall')"
            echo ""
            echo "Options:"
            echo "  -v, --version <ver>  $(msg 'opt_version')"
            echo "  -y, --yes            Skip confirmation prompts (for uninstall)"
            echo ""
            echo "Examples:"
            echo "  $0                        # Install latest version"
            echo "  $0 install -v v0.1.0      # Install specific version"
            echo "  $0 upgrade                # Upgrade to latest"
            echo "  $0 upgrade -v v0.2.0      # Upgrade to specific version"
            echo "  $0 rollback v0.1.0        # Rollback to v0.1.0"
            echo "  $0 list-versions          # List available versions"
            echo ""
            exit 0
            ;;
    esac

    # Default: Fresh install with latest version
    check_root
    detect_platform
    check_dependencies

    if [ -n "$target_version" ]; then
        # Install specific version
        if [ -f "$INSTALL_DIR/Nexora" ]; then
            install_version "$target_version"
        else
            configure_server
            LATEST_VERSION=$(validate_version "$target_version")
            download_and_extract
            create_user
            setup_directories
            install_service
            prepare_for_setup
            get_public_ip
            start_service
            enable_autostart
            print_completion
        fi
    else
        # Install latest version
        configure_server
        get_latest_version
        download_and_extract
        create_user
        setup_directories
        install_service
        prepare_for_setup
        get_public_ip
        start_service
        enable_autostart
        print_completion
    fi
}

main "$@"
