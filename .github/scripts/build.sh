#!/bin/bash

# Simple Build Script for Tauri GDAL
# Builds for the current platform using bundled libraries

set -e

echo "Tauri GDAL Build Script"
echo "======================="
echo

# Function to detect current OS
detect_os() {
    # In GitHub Actions, use the RUNNER_OS environment variable
    if [[ -n "$RUNNER_OS" ]]; then
        case "$RUNNER_OS" in
            Linux)      echo "linux";;
            Windows)    echo "windows";;
            macOS)      echo "macos";;
            *)          echo "unknown";;
        esac
        return
    fi
    
    # Try multiple methods to detect OS
    if [[ -f /proc/version ]] && grep -q "Linux" /proc/version; then
        echo "linux"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    elif [[ -n "$WINDIR" ]] || [[ -n "$windir" ]]; then
        echo "windows"
    elif command -v uname >/dev/null 2>&1; then
        case "$(uname -s)" in
            Linux*)     echo "linux";;
            Darwin*)    echo "macos";;
            CYGWIN*|MINGW*|MSYS*) echo "windows";;
            *)          echo "unknown";;
        esac
    else
        # Fallback: check for common Linux files
        if [[ -f /etc/os-release ]] || [[ -f /etc/redhat-release ]] || [[ -f /etc/debian_version ]]; then
            echo "linux"
        else
            echo "unknown"
        fi
    fi
}

# Function to check and install GTK libraries
check_gtk_libraries() {
    echo "[INFO] Checking GTK libraries..."
    
    # Check if GTK libraries are available via pkg-config
    if pkg-config --exists glib-2.0 && pkg-config --exists gio-2.0 && pkg-config --exists gobject-2.0 && pkg-config --exists gtk+-3.0; then
        echo "[OK] GTK libraries found via pkg-config"
        return 0
    fi
    
    echo "[INFO] GTK libraries not found, installing..."
    
    # Install GTK development packages
    sudo apt update
    sudo apt install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
        libwebkit2gtk-4.1-dev \
        libgtk-3-dev \
        libglib2.0-dev \
        libgirepository1.0-dev \
        libcairo2-dev \
        libpango1.0-dev \
        libatk1.0-dev \
        libgdk-pixbuf2.0-dev \
        libglib2.0-0 \
        libgobject-2.0-0 \
        libgio-2.0-0
    
    # Update library cache
    sudo ldconfig
    
    # Verify installation
    echo "[INFO] Verifying GTK installation..."
    pkg-config --exists glib-2.0 && echo "[OK] glib-2.0 found" || echo "[ERROR] glib-2.0 not found"
    pkg-config --exists gio-2.0 && echo "[OK] gio-2.0 found" || echo "[ERROR] gio-2.0 not found"
    pkg-config --exists gobject-2.0 && echo "[OK] gobject-2.0 found" || echo "[ERROR] gobject-2.0 not found"
    pkg-config --exists gtk+-3.0 && echo "[OK] gtk+-3.0 found" || echo "[ERROR] gtk+-3.0 not found"
    
    # Show pkgconfig files
    echo "[INFO] GTK pkgconfig files:"
    find /usr -name "*.pc" -path "*/pkgconfig/*" | grep -E "(glib|gio|gobject|gtk)" | head -10
    
    # Show pkg-config path
    echo "[INFO] PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
    
    # Test pkg-config
    echo "[INFO] Testing pkg-config:"
    pkg-config --list-all | grep -E "(glib|gio|gobject|gtk)" | head -5
}

# Function to check if GDAL is installed via Pixi
check_gdal_installation() {
    echo "[INFO] Checking GDAL installation..."
    
    # Check if gdalinfo is available in PATH
    if command -v gdalinfo &> /dev/null; then
        echo "[OK] GDAL is available in PATH"
        gdalinfo --version 2>/dev/null || echo "[WARNING] GDAL version check failed"
        return 0
    fi
    
    # Check if gdalinfo is available in Pixi environment
    local pixi_gdal_bin="$HOME/.pixi/envs/gdal/bin"
    if [[ -f "$pixi_gdal_bin/gdalinfo" ]]; then
        echo "[OK] GDAL is available in Pixi environment"
        "$pixi_gdal_bin/gdalinfo" --version 2>/dev/null || echo "[WARNING] GDAL version check failed"
        return 0
    fi
    
    # Check if .env file exists and load environment variables
    if [[ -f .env ]]; then
        echo "[INFO] Loading environment variables from .env file..."
        export $(cat .env | grep -v '^#' | xargs)
        
        # Check again after loading environment variables
        if command -v gdalinfo &> /dev/null; then
            echo "[OK] GDAL is available after loading .env"
            gdalinfo --version 2>/dev/null || echo "[WARNING] GDAL version check failed"
            return 0
        fi
    fi
    
    echo "[ERROR] GDAL not found"
    echo "[INFO] Please install GDAL via Pixi:"
    echo "  pixi global install gdal=3.10.3"
    return 1
}

# Function to check bundled libraries
check_bundled_libraries() {
    local current_os=$(detect_os)
    
    echo "[INFO] Checking bundled libraries for $current_os..."
    
    case "$current_os" in
        "linux")
            if [[ -f "src-tauri/gdal-libs/linux/libgdal.so" ]]; then
                echo "[OK] Linux GDAL libraries found"
                return 0
            else
                echo "[ERROR] Linux GDAL libraries not found"
                echo "[INFO] Please run: ./install-gdal.sh"
                return 1
            fi
            ;;
        "windows")
            if [[ -f "src-tauri/gdal-libs/windows/gdal.dll" ]]; then
                echo "[OK] Windows GDAL libraries found"
                return 0
            else
                echo "[ERROR] Windows GDAL libraries not found"
                echo "[INFO] Please run: install-gdal.bat"
                return 1
            fi
            ;;
        *)
            echo "[ERROR] Unsupported platform: $current_os"
            return 1
            ;;
    esac
}

# Function to build for current platform
build_current_platform() {
    local current_os=$(detect_os)
    
    echo "Building for current platform: $current_os"
    
    # Check GDAL installation
    if ! check_gdal_installation; then
        echo "Error: GDAL installation required"
        exit 1
    fi
    
    # Check and install GTK libraries (Linux only)
    if [[ "$current_os" == "linux" ]]; then
        check_gtk_libraries
    fi
    
    # Check bundled libraries
    if ! check_bundled_libraries; then
        echo "Error: Bundled libraries required"
        exit 1
    fi
    
    # Build using Tauri's native support
    echo "Running Tauri build for $current_os..."
    
    # Ensure Rust toolchain is properly set up
    export PATH="$HOME/.cargo/bin:$PATH"
    
    if ! command -v cargo &> /dev/null; then
        echo "Error: Cargo not found. Rust toolchain not properly installed."
        exit 1
    fi
    
    # Check if we're in the right directory
    if [[ ! -f "src-tauri/Cargo.toml" ]]; then
        echo "Error: src-tauri/Cargo.toml not found. Are we in the right directory?"
        exit 1
    fi
    
    # Clean AppImage build cache to avoid corrupted artifacts
    rm -rf src-tauri/target/release/bundle/appimage* 2>/dev/null || true
    
    # Run the build
    pnpm tauri build
    
    echo
    echo "Build completed for $current_os!"
    echo "Built applications can be found in:"
    echo "  - src-tauri/target/release/bundle/"
    echo
    echo "Platform-specific bundles:"
    case "$current_os" in
        "linux")
            echo "  - Linux: AppImage, DEB, RPM packages"
            ;;
        "windows")
            echo "  - Windows: MSI, NSIS installers"
            ;;
        "macos")
            echo "  - macOS: DMG packages"
            ;;
    esac
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --check        Check GDAL installation and bundled libraries"
    echo
    echo "Examples:"
    echo "  $0                    # Build for current platform"
    echo "  $0 --check           # Check installation"
}

# Main execution
main() {
    local check_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            --check)
                check_only=true
                shift
                ;;
            *)
                echo "[ERROR] Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check installation only
    if [[ "$check_only" == true ]]; then
        check_gdal_installation
        check_bundled_libraries
        exit $?
    fi
    
    # Build for current platform
    build_current_platform
}

# Run main function
main "$@" 