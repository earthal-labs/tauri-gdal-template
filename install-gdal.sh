#!/bin/bash

# Install GDAL via Pixi for Linux
# This script installs GDAL and copies libraries to be bundled with the Tauri application

set -e

echo "Installing GDAL via Pixi for Linux"
echo "==================================="
echo

# Check if Pixi is installed
if ! command -v pixi &> /dev/null; then
    echo "Error: Pixi is not installed"
    echo "Please install Pixi first:"
    echo "  curl -fsSL https://pixi.sh/install.sh | bash"
    exit 1
fi

# Check if GDAL is already installed
if command -v gdalinfo &> /dev/null; then
    echo "GDAL is already installed"
    gdalinfo --version
else
    echo "Installing GDAL via Pixi..."
    pixi global install gdal=3.10.3
    echo "GDAL installation completed"
fi

# Get Pixi environment paths
PIXI_GLOBAL_ROOT="$HOME/.pixi/envs/gdal"
PIXI_GLOBAL_BIN="$HOME/.pixi/envs/gdal/bin"

# Create bundled library directories
echo "Setting up bundled library directories..."

# Create Linux libraries directory for bundling
mkdir -p src-tauri/gdal-libs/linux

# Copy Linux GDAL libraries for bundling
echo "Copying Linux GDAL libraries for bundling..."

# Copy main GDAL library
if [[ -f "$PIXI_GLOBAL_ROOT/lib/libgdal.so" ]]; then
    cp "$PIXI_GLOBAL_ROOT/lib/libgdal.so" src-tauri/gdal-libs/linux/
    echo "Copied libgdal.so"
else
    echo "Warning: libgdal.so not found at $PIXI_GLOBAL_ROOT/lib/libgdal.so"
fi

# Copy all GDAL-related shared libraries
if [[ -d "$PIXI_GLOBAL_ROOT/lib" ]]; then
    cp "$PIXI_GLOBAL_ROOT/lib/"*.so* src-tauri/gdal-libs/linux/ 2>/dev/null || echo "Warning: No .so files found"
    echo "Copied all shared libraries"
fi

# Copy include files
if [[ -d "$PIXI_GLOBAL_ROOT/include" ]]; then
    cp -r "$PIXI_GLOBAL_ROOT/include" src-tauri/gdal-libs/linux/
    echo "Copied include files"
fi

# Copy share files (GDAL data, PROJ data)
if [[ -d "$PIXI_GLOBAL_ROOT/share" ]]; then
    cp -r "$PIXI_GLOBAL_ROOT/share" src-tauri/gdal-libs/linux/
    echo "Copied share files"
fi

# Create .env file for the project
echo "Creating .env file for project..."
cat > .env << EOF
# GDAL Environment Variables for Tauri
GDAL_ROOT=$PIXI_GLOBAL_ROOT
GDAL_HOME=$PIXI_GLOBAL_ROOT
GDAL_LIB_DIR=$PIXI_GLOBAL_ROOT/lib
GDAL_INCLUDE_DIR=$PIXI_GLOBAL_ROOT/include
GDAL_BIN_DIR=$PIXI_GLOBAL_BIN
GDAL_VERSION=3.10.3
GDAL_DYNAMIC=1
GDAL_STATIC=0
PATH=$HOME/.pixi/bin:$PIXI_GLOBAL_BIN:\$PATH
PKG_CONFIG_PATH=$PIXI_GLOBAL_ROOT/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig
LD_LIBRARY_PATH=$PIXI_GLOBAL_ROOT/lib
LIBRARY_PATH=$PIXI_GLOBAL_ROOT/lib

EOF

echo "Created .env file for project"

# Source the environment variables for verification
echo "Loading environment variables..."
export PATH="$HOME/.pixi/bin:$PIXI_GLOBAL_BIN:$PATH"
export PKG_CONFIG_PATH="$PIXI_GLOBAL_ROOT/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"
export LD_LIBRARY_PATH="$PIXI_GLOBAL_ROOT/lib"
export LIBRARY_PATH="$PIXI_GLOBAL_ROOT/lib"

# Verify installation
echo
echo "Verifying installation..."
# Check if gdalinfo is available in PATH or in Pixi environment
if command -v gdalinfo &> /dev/null; then
    echo "GDAL is available in PATH:"
    gdalinfo --version
elif [[ -f "$PIXI_GLOBAL_BIN/gdalinfo" ]]; then
    echo "GDAL is available in Pixi environment:"
    "$PIXI_GLOBAL_BIN/gdalinfo" --version
else
    echo "Error: GDAL installation verification failed"
    echo "Current PATH: $PATH"
    exit 1
fi

echo
echo "Linux GDAL libraries copied to src-tauri/gdal-libs/linux/"
echo "Found GDAL libraries and dependencies for bundling"

echo
echo "GDAL installation complete for Linux!"
echo "Libraries are now bundled with your Tauri application"
echo "Next steps:"
echo "  1. Build for Linux: pnpm tauri build"
echo "  2. The bundled libraries will be included in your app" 