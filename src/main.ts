import { invoke } from "@tauri-apps/api/core";
import { open } from "@tauri-apps/plugin-dialog";

// Type definitions for GDAL responses
interface GdalInfo {
  version: string;
  supported_formats: string[];
  platform: string;
}

interface DatasetInfo {
  size_x: number;
  size_y: number;
  projection: string;
  band_count: number;
  driver_name: string;
}

// GDAL functionality
async function testGdal() {
  try {
    const gdalInfo: GdalInfo = await invoke('get_gdal_info');
    
    // Update the UI with GDAL information
    const gdalInfoEl = document.getElementById('gdal-info');
    if (gdalInfoEl) {
      gdalInfoEl.innerHTML = `
        <div class="gdal-status">
          <h3>GDAL Information</h3>
          <div class="gdal-details">
            <span class="gdal-item"><strong>Version:</strong> ${gdalInfo.version}</span>
            <span class="gdal-item"><strong>Platform:</strong> ${gdalInfo.platform}</span>
            <span class="gdal-item"><strong>Formats:</strong> ${gdalInfo.supported_formats.length}</span>
            <details class="formats-toggle">
              <summary>View All</summary>
              <pre class="formats-list">${gdalInfo.supported_formats.join('\n')}</pre>
            </details>
          </div>
        </div>
      `;
    }
  } catch (error) {
    console.error('GDAL Error:', error);
    const gdalInfoEl = document.getElementById('gdal-info');
    if (gdalInfoEl) {
      gdalInfoEl.innerHTML = `<p style="color: red;">GDAL Error: ${error}</p>`;
    }
  }
}

async function analyzeDataset(filePath: string) {
  try {
    const datasetInfo: DatasetInfo = await invoke('get_dataset_info', { filePath });
    
    const fileName = filePath.split(/[\\/]/).pop() || filePath;
    
    // Truncate projection string if it's too long
    const projection = datasetInfo.projection || 'No projection information';
    const truncatedProjection = projection.length > 30 
      ? projection.substring(0, 30) + '...' 
      : projection;
    
    const alertMessage = `Dataset Information:

    File: ${fileName}

    Bands: ${datasetInfo.band_count}

    Driver: ${datasetInfo.driver_name}

    Dimensions: ${datasetInfo.size_x} × ${datasetInfo.size_y} pixels
    
    Projection: ${truncatedProjection}
    `;

    alert(alertMessage);
  } catch (error) {
    console.error('Dataset Analysis Error:', error);
    alert(`Error analyzing dataset: ${error}`);
  }
}

async function openFileDialog() {
  try {
    const filePath = await open({
      multiple: false,
      filters: [
        {
          name: 'Raster Files',
          extensions: ['tif', 'tiff', 'jp2', 'png', 'jpg', 'jpeg', 'bmp', 'gif', 'img', 'hdf', 'nc']
        },
        {
          name: 'All Files',
          extensions: ['*']
        }
      ]
    });
    
    if (filePath) {
      await analyzeDataset(filePath);
    }
  } catch (error) {
    console.error('File dialog error:', error);
    // Fallback to prompt if dialog fails
    const filePath = prompt("File dialog failed. Enter the full path to a raster file:");
    if (filePath && filePath.trim()) {
      await analyzeDataset(filePath.trim());
    }
  }
}

function setupAnalyzeButton() {
  const analyzeBtn = document.getElementById('analyze-btn') as HTMLButtonElement;
  
  if (analyzeBtn) {
    analyzeBtn.disabled = false;
    analyzeBtn.addEventListener('click', openFileDialog);
  }
}

window.addEventListener("DOMContentLoaded", () => {
  // Auto-test GDAL integration on startup
  testGdal();
  
  // Setup analyze button
  setupAnalyzeButton();
});
