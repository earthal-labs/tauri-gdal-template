<div align="center">

# Tauri + GDAL Template

  <img src="src/assets/tauri.svg" alt="Tauri" width="120" height="120"> 
  <img src="src/assets/gdal.svg" alt="GDAL" width="120" height="120">
</div>
<br>

A Tauri application template that bundles GDAL (Geospatial Data Abstraction Library) for building self-contained geospatial desktop applications. GDAL supports over 200 raster and vector formats and is the backbone of virtually every GIS application. This template makes it easy to create cross-platform apps that can process satellite imagery, analyze GPS data, and perform geospatial operations without requiring users to install external dependencies.

- **Zero User Dependencies** - Ships with GDAL dynamically linked, no installation required
- **True Cross-Platform** - Build once, run on Windows and Linux  
- **Native Performance** - Rust + GDAL with no language binding overhead
- **Developer-Friendly Setup** - Simple install scripts handle GDAL setup automatically
- **Single Executable** - Distribute as one file with all dependencies included
- **Secure & Sandboxed** - Tauri's security model with full GDAL access

## Support

If you find this template helpful, consider supporting our work!

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow.svg?style=flat-square&logo=buy-me-a-coffee)](https://buymeacoffee.com/earthallabs)

## How It Works

### GDAL Integration
This template uses **dynamic linking** to include GDAL in your Tauri application:

1. **Install GDAL**: Simple install scripts use Pixi to install GDAL on your development machine
2. **Copy Libraries**: GDAL dynamic libraries are copied to `src-tauri/gdal-libs/` for bundling
3. **Build Application**: Tauri bundles these libraries with your executable
4. **Distribute**: End users get a single executable with all GDAL dependencies included

### Why Dynamic Linking?
- **Smaller executables**: Only includes the GDAL libraries your app actually uses
- **Easier development**: No need to compile GDAL from source
- **Better compatibility**: Uses the same GDAL libraries you test with

### Platform-Specific Builds
Since each platform needs its own GDAL dynamic libraries:
- **Windows developers** build Windows executables locally
- **Linux developers** build Linux executables locally  
- **Cross-platform builds** happen automatically via GitHub Actions

### File Structure
```
├── install-gdal.sh           # Linux GDAL installer
├── install-gdal.bat          # Windows GDAL installer
├── src-tauri/
│   ├── gdal-libs/            # Bundled GDAL libraries (gitignored)
│   │   ├── linux/            # Linux libraries
│   │   └── windows/          # Windows libraries
│   ├── build.rs              # GDAL linking configuration
│   └── src/
│       └── lib.rs            # GDAL Rust bindings
└── .github/
    ├── workflows/
    │   ├── build.yml         # CI/CD build workflow
    │   └── release.yml       # Automated release workflow
    └── scripts/
        ├── build.sh          # Linux build script with cross-compilation
        └── create-release.sh # Release helper script
```

## Scripts Overview

### Environment Variables

The install scripts create a `.env` file with:
```bash
GDAL_ROOT=/path/to/gdal
GDAL_HOME=/path/to/gdal
GDAL_LIB_DIR=/path/to/gdal/lib
GDAL_INCLUDE_DIR=/path/to/gdal/include
PKG_CONFIG_PATH=/path/to/gdal/lib/pkgconfig
```
### Install Scripts
- **`install-gdal.sh`**: Linux GDAL installation via Pixi
- **`install-gdal.bat`**: Windows GDAL installation via Pixi

### Build Scripts
- **`.github/scripts/build.sh`**: Linux build script with cross-compilation support
- **Standard Tauri**: `pnpm tauri build` for local development

### CI/CD Workflows
- **`build.yml`**: Automated builds on push/PR
- **`release.yml`**: Automated releases on version tags

### Release Scripts
- **`.github/scripts/create-release.sh`**: Helper script for creating version tags and releases

## Getting Started

### Clone the repository
```bash
git clone https://github.com/earthal-labs/tauri-gdal-template.git
cd tauri-gdal-template
```

### Install GDAL

**Windows:**
```batch
install-gdal.bat
```

**Linux:**
```bash
chmod +x install-gdal.sh
./install-gdal.sh
```

*Note: Both Windows and Linux installers use Pixi for fast, reliable GDAL installation with automatic environment configuration.*

### Run the application
```bash
pnpm install
pnpm tauri dev
```

## Building for Distribution

### Local Build Limitations

**Important**: Due to how we use Pixi and dynamic libraries, local builds are platform-specific:
- **Windows developers** can only build Windows executables
- **Linux developers** can only build Linux executables

This is because each platform requires its own GDAL dynamic libraries, and managing both Windows and Linux libraries locally is complex.

### Local Build
```bash
# Build for current platform
pnpm tauri build

# Check GDAL installation status
./.github/scripts/build.sh --check
```

### Cross-Platform Builds via GitHub Actions

For true cross-platform builds, we rely on GitHub Actions workflows that build on each platform separately:

1. **Create and push a version tag:**
   ```bash
   # Using the helper script (recommended)
   ./.github/scripts/create-release.sh v1.0.0
   
   # Or manually
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **GitHub Actions will automatically:**
   - Build Windows and Linux applications on their respective platforms
   - Create a GitHub release with all artifacts
   - Upload MSI, AppImage, DEB, and RPM packages

3. **Release artifacts include:**
   - **Windows**: MSI installer and portable executable
   - **Linux**: AppImage, DEB, and RPM packages

## Known Issues

### Local Cross-Platform Builds
Currently, local development is limited to building for the current platform only:
- **Windows developers** can only build Windows executables
- **Linux developers** can only build Linux executables

This limitation exists because each platform requires its own GDAL dynamic libraries, and managing both Windows and Linux libraries locally is complex. For true cross-platform builds, use the GitHub Actions workflows.

### Static Linking Exploration
The template currently uses dynamic linking for GDAL integration. Static linking GDAL could potentially:
- Enable true local cross-platform builds
- Reduce executable size in some cases
- Improve deployment simplicity

However, static linking GDAL presents significant challenges:
- Complex compilation requirements
- Platform-specific build configurations
- Potential licensing implications
- Increased build time and complexity

This remains an area for future exploration and improvement.

Made with ❤️ by Earthal Labs
