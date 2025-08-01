use std::env;
use std::path::Path;
use std::fs;

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    
    // Debug environment variables
    println!("cargo:warning=GDAL_NO_PKG_CONFIG: {:?}", env::var("GDAL_NO_PKG_CONFIG"));
    println!("cargo:warning=GDAL_DYNAMIC: {:?}", env::var("GDAL_DYNAMIC"));
    println!("cargo:warning=GDAL_STATIC: {:?}", env::var("GDAL_STATIC"));
    println!("cargo:warning=GDAL_VERSION: {:?}", env::var("GDAL_VERSION"));
    
    // Cross-platform GDAL detection
    if cfg!(target_os = "windows") {
        configure_windows_gdal();
    } else {
        configure_linux_gdal();
    }
    
    // Copy GDAL libraries to output directory for runtime access
    copy_gdal_libraries();
    
    // Set up Tauri build
    tauri_build::build();
}

fn copy_gdal_libraries() {
    if cfg!(target_os = "windows") {
        // Copy Windows GDAL libraries to src-tauri directory
        let gdal_libs_dir = Path::new("gdal-libs/windows");
        if gdal_libs_dir.exists() {
            if let Ok(entries) = fs::read_dir(gdal_libs_dir) {
                for entry in entries.flatten() {
                    if let Some(extension) = entry.path().extension() {
                        if extension == "dll" {
                            let dest_path = Path::new(".").join(entry.file_name());
                            if let Err(e) = fs::copy(&entry.path(), &dest_path) {
                                println!("cargo:warning=Failed to copy {}: {}", entry.path().display(), e);
                            } else {
                                println!("cargo:warning=Copied {} to {}", entry.path().display(), dest_path.display());
                            }
                        }
                    }
                }
            }
        }
    } else {
        // Copy Linux GDAL libraries to src-tauri directory
        let gdal_libs_dir = Path::new("gdal-libs/linux");
        if gdal_libs_dir.exists() {
            if let Ok(entries) = fs::read_dir(gdal_libs_dir) {
                for entry in entries.flatten() {
                    if let Some(file_name) = entry.file_name().to_str() {
                        if file_name.starts_with("lib") && file_name.contains(".so") {
                            let dest_path = Path::new(".").join(entry.file_name());
                            if let Err(e) = fs::copy(&entry.path(), &dest_path) {
                                println!("cargo:warning=Failed to copy {}: {}", entry.path().display(), e);
                            } else {
                                println!("cargo:warning=Copied {} to {}", entry.path().display(), dest_path.display());
                            }
                        }
                    }
                }
            }
        }
    }
}

fn configure_windows_gdal() {
    // Windows: Look for pixi GDAL installation
    if let Ok(userprofile) = env::var("USERPROFILE") {
        let pixi_gdal_root = format!("{}\\.pixi\\envs\\gdal\\Library", userprofile);
        let pixi_lib_dir = format!("{}\\.pixi\\envs\\gdal\\Library\\lib", userprofile);
        let pixi_include_dir = format!("{}\\.pixi\\envs\\gdal\\Library\\include", userprofile);
        let gdal_lib_file = format!("{}\\.pixi\\envs\\gdal\\Library\\lib\\gdal.lib", userprofile);
        let gdal_i_lib_file = format!("{}\\.pixi\\envs\\gdal\\Library\\lib\\gdal_i.lib", userprofile);
        let gdal_dll_lib_file = format!("{}\\.pixi\\envs\\gdal\\Library\\lib\\gdal.dll.lib", userprofile);
        
        if Path::new(&gdal_lib_file).exists() {
            // Check if gdal_i.lib exists, if not create it from gdal.lib
            if !Path::new(&gdal_i_lib_file).exists() {
                match fs::copy(&gdal_lib_file, &gdal_i_lib_file) {
                    Ok(_) => println!("cargo:warning=Created gdal_i.lib from gdal.lib for compatibility"),
                    Err(e) => println!("cargo:warning=Failed to create gdal_i.lib: {}", e),
                }
            }
            
            // Check if gdal.dll.lib exists, if not create it from gdal.lib
            if !Path::new(&gdal_dll_lib_file).exists() {
                match fs::copy(&gdal_lib_file, &gdal_dll_lib_file) {
                    Ok(_) => println!("cargo:warning=Created gdal.dll.lib from gdal.lib for compatibility"),
                    Err(e) => println!("cargo:warning=Failed to create gdal.dll.lib: {}", e),
                }
            }
            
            configure_gdal_paths(&pixi_gdal_root, &pixi_lib_dir, &pixi_include_dir, &gdal_lib_file);
        } else {
            println!("cargo:warning=GDAL.LIB NOT FOUND AT: {}", gdal_lib_file);
        }
    } else {
        println!("cargo:warning=USERPROFILE environment variable not found");
    }
}

fn configure_linux_gdal() {
    // Linux: Look for system GDAL installation first (preferred), then pixi, then spack
    if let Ok(home) = env::var("HOME") {
        // First try to find GDAL via system installation
        let gdal_path = find_system_gdal_path();
        
        if let Some(gdal_root) = gdal_path {
            let lib_dir = format!("{}/lib", gdal_root);
            let include_dir = format!("{}/include", gdal_root);
            let gdal_lib_file = format!("{}/lib/libgdal.so", gdal_root);
            
            if Path::new(&gdal_lib_file).exists() {
                configure_gdal_paths(&gdal_root, &lib_dir, &include_dir, &gdal_lib_file);
                return;
            } else {
                println!("cargo:warning=GDAL library not found at: {}", gdal_lib_file);
            }
        }
        
        // Fallback to pixi if system not found
        let gdal_path = find_pixi_gdal_path(&home);
        
        if let Some(gdal_root) = gdal_path {
            let lib_dir = format!("{}/lib", gdal_root);
            let include_dir = format!("{}/include", gdal_root);
            let gdal_lib_file = format!("{}/lib/libgdal.so", gdal_root);
            
            if Path::new(&gdal_lib_file).exists() {
                configure_gdal_paths(&gdal_root, &lib_dir, &include_dir, &gdal_lib_file);
                return;
            } else {
                println!("cargo:warning=GDAL library not found at: {}", gdal_lib_file);
            }
        }
        
        // Fallback to spack if pixi not found
        let gdal_path = find_spack_gdal_path(&home);
        
        if let Some(gdal_root) = gdal_path {
            let lib_dir = format!("{}/lib", gdal_root);
            let include_dir = format!("{}/include", gdal_root);
            let gdal_lib_file = format!("{}/lib/libgdal.so", gdal_root);
            
            if Path::new(&gdal_lib_file).exists() {
                configure_gdal_paths(&gdal_root, &lib_dir, &include_dir, &gdal_lib_file);
            } else {
                println!("cargo:warning=GDAL library not found at: {}", gdal_lib_file);
            }
        } else {
            println!("cargo:warning=GDAL installation not found via system, pixi, or spack");
        }
    } else {
        println!("cargo:warning=HOME environment variable not found");
    }
}

fn find_system_gdal_path() -> Option<String> {
    // Try to find GDAL via pkg-config first
    if let Ok(output) = std::process::Command::new("pkg-config")
        .args(&["--variable=prefix", "gdal"])
        .output() {
        if output.status.success() {
            let path = String::from_utf8_lossy(&output.stdout).trim().to_string();
            if !path.is_empty() && Path::new(&path).exists() {
                return Some(path);
            }
        }
    }
    
    // Fallback: try common system installation paths
    let common_paths = [
        "/usr",
        "/usr/local",
        "/opt/gdal",
    ];
    
    for path in &common_paths {
        let gdal_lib_file = format!("{}/lib/libgdal.so", path);
        if Path::new(&gdal_lib_file).exists() {
            return Some(path.to_string());
        }
    }
    
    None
}

fn find_pixi_gdal_path(home: &str) -> Option<String> {
    // Try to find GDAL in pixi environments
    let pixi_envs_dir = format!("{}/.pixi/envs", home);
    if Path::new(&pixi_envs_dir).exists() {
        // Look for GDAL in pixi environments
        if let Ok(entries) = std::fs::read_dir(&pixi_envs_dir) {
            for entry in entries.flatten() {
                let gdalinfo_path = entry.path().join("bin").join("gdalinfo");
                if gdalinfo_path.exists() {
                    // Return the environment root directory
                    return Some(entry.path().to_string_lossy().to_string());
                }
            }
        }
    }
    
    // Fallback: try common pixi installation paths
    let common_paths = [
        format!("{}/.pixi/envs/*/bin/gdalinfo", home),
    ];
    
    for pattern in &common_paths {
        if let Ok(entries) = glob::glob(pattern) {
            for entry in entries.flatten() {
                if entry.exists() {
                    // Extract the environment root from the bin path
                    if let Some(parent) = entry.parent() {
                        if let Some(env_root) = parent.parent() {
                            return Some(env_root.to_string_lossy().to_string());
                        }
                    }
                }
            }
        }
    }
    
    None
}

fn find_spack_gdal_path(home: &str) -> Option<String> {
    // Try to find GDAL via spack location command
    let spack_root = format!("{}/spack", home);
    if Path::new(&spack_root).exists() {
        // Try to get GDAL path from spack
        if let Ok(output) = std::process::Command::new("spack")
            .args(&["location", "-i", "gdal"])
            .output() {
            if output.status.success() {
                let path = String::from_utf8_lossy(&output.stdout).trim().to_string();
                if !path.is_empty() && Path::new(&path).exists() {
                    return Some(path);
                }
            }
        }
    }
    
    // Fallback: try common spack installation paths
    let common_paths = [
        format!("{}/spack/opt/spack/linux-*/gcc-*/gdal-3.10.3-*", home),
        format!("{}/spack/opt/spack/linux-*/gcc-*/gdal-*", home),
    ];
    
    for pattern in &common_paths {
        if let Ok(entries) = glob::glob(pattern) {
            for entry in entries.flatten() {
                if entry.is_dir() {
                    return Some(entry.to_string_lossy().to_string());
                }
            }
        }
    }
    
    None
}

fn configure_gdal_paths(gdal_root: &str, lib_dir: &str, include_dir: &str, gdal_lib_file: &str) {
    // Set GDAL environment variables
    env::set_var("GDAL_ROOT", gdal_root);
    env::set_var("GDAL_HOME", gdal_root);
    env::set_var("GDAL_LIB_DIR", lib_dir);
    env::set_var("GDAL_INCLUDE_DIR", include_dir);
    
    // Force environment variables for rustc
    println!("cargo:rustc-env=GDAL_ROOT={}", gdal_root);
    println!("cargo:rustc-env=GDAL_HOME={}", gdal_root);
    println!("cargo:rustc-env=GDAL_LIB_DIR={}", lib_dir);
    println!("cargo:rustc-env=GDAL_INCLUDE_DIR={}", include_dir);
    
    // Link the GDAL library
    println!("cargo:rustc-link-search=native={}", lib_dir);
    
    // Use dynamic linking on Windows, static on Linux
    if cfg!(target_os = "windows") {
        // On Windows, use gdal_i.lib for dynamic linking
        println!("cargo:rustc-link-lib=dylib=gdal_i");
    } else {
        println!("cargo:rustc-link-lib=gdal");
    }
    
    println!("cargo:rustc-link-arg={}", gdal_lib_file);
    
    // For Pixi installations, ensure proper library search paths
    if gdal_root.contains("pixi") {
        // Add the pixi environment's lib directory to the library search path
        println!("cargo:rustc-link-search=native={}", lib_dir);
    }
}

