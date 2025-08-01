use gdal::{Dataset, DriverManager};
use serde::{Deserialize, Serialize};
use std::path::Path;
use std::env;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum GdalError {
    #[error("GDAL error: {0}")]
    Gdal(#[from] gdal::errors::GdalError),
    #[error("File not found: {0}")]
    FileNotFound(String),
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DatasetInfo {
    pub size_x: usize,
    pub size_y: usize,
    pub projection: String,
    pub band_count: usize,
    pub driver_name: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GdalInfo {
    pub version: String,
    pub supported_formats: Vec<String>,
    pub platform: String,
}

fn setup_gdal_runtime() {
    // Set up GDAL runtime environment
    if cfg!(target_os = "windows") {
        // On Windows, add the current directory to PATH for DLL loading
        if let Ok(current_dir) = env::current_dir() {
            if let Some(path) = env::var_os("PATH") {
                let mut paths = env::split_paths(&path).collect::<Vec<_>>();
                paths.insert(0, current_dir.clone());
                if let Ok(new_path) = env::join_paths(paths) {
                    env::set_var("PATH", new_path);
                }
            }
        }
    } else {
        // On Linux, set LD_LIBRARY_PATH to include current directory
        if let Ok(current_dir) = env::current_dir() {
            if let Some(lib_path) = env::var_os("LD_LIBRARY_PATH") {
                let mut paths = env::split_paths(&lib_path).collect::<Vec<_>>();
                paths.insert(0, current_dir.clone());
                if let Ok(new_path) = env::join_paths(paths) {
                    env::set_var("LD_LIBRARY_PATH", new_path);
                }
            } else {
                env::set_var("LD_LIBRARY_PATH", current_dir);
            }
        }
    }
}

#[tauri::command]
fn get_gdal_info() -> Result<GdalInfo, String> {
    // Ensure GDAL runtime is set up
    setup_gdal_runtime();
    
    let version = gdal::version_info("RELEASE_NAME");
    
    let driver_count = DriverManager::count();
    let mut formats = Vec::new();
    
    for i in 0..driver_count {
        if let Ok(driver) = DriverManager::get_driver(i) {
            formats.push(driver.short_name());
        }
    }
    
    Ok(GdalInfo {
        version,
        supported_formats: formats,
        platform: std::env::consts::OS.to_string(),
    })
}

#[tauri::command]
fn get_dataset_info(file_path: String) -> Result<DatasetInfo, String> {
    // Ensure GDAL runtime is set up
    setup_gdal_runtime();
    
    let path = Path::new(&file_path);
    if !path.exists() {
        return Err(format!("File not found: {}", file_path));
    }

    let dataset = Dataset::open(path).map_err(|e| e.to_string())?;
    
    let size = dataset.raster_size();
    let projection = dataset.projection();
    let band_count = dataset.raster_count();
    let driver = dataset.driver();
    let driver_name = driver.long_name();

    Ok(DatasetInfo {
        size_x: size.0,
        size_y: size.1,
        projection,
        band_count,
        driver_name,
    })
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    // Set up GDAL runtime environment before starting the app
    setup_gdal_runtime();
    
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            get_gdal_info,
            get_dataset_info
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
