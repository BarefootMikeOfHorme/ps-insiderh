// CBOR Data Handler
// Handles serialization/deserialization of runtime data using CBOR format

use anyhow::{Result, Context};
use serde::{Serialize, Deserialize};
use std::path::Path;
use std::fs::File;
use std::io::{Read, Write};
use tracing::{info, debug};

/// CBOR data handler for efficient binary serialization
pub struct CBORHandler;

impl CBORHandler {
    /// Serialize data to CBOR format and write to file
    pub fn serialize_to_file<T: Serialize>(data: &T, path: &Path) -> Result<()> {
        info!("Serializing data to CBOR file: {:?}", path);

        // Create parent directory if needed
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)
                .context("Failed to create parent directory")?;
        }

        let mut file = File::create(path)
            .context("Failed to create CBOR file")?;

        let cbor_data = serde_cbor::to_vec(data)
            .context("Failed to serialize data to CBOR")?;

        file.write_all(&cbor_data)
            .context("Failed to write CBOR data to file")?;

        debug!("Serialized {} bytes to {:?}", cbor_data.len(), path);

        Ok(())
    }

    /// Deserialize data from CBOR file
    pub fn deserialize_from_file<T: for<'de> Deserialize<'de>>(path: &Path) -> Result<T> {
        info!("Deserializing data from CBOR file: {:?}", path);

        let mut file = File::open(path)
            .context("Failed to open CBOR file")?;

        let mut cbor_data = Vec::new();
        file.read_to_end(&mut cbor_data)
            .context("Failed to read CBOR file")?;

        let data: T = serde_cbor::from_slice(&cbor_data)
            .context("Failed to deserialize CBOR data")?;

        debug!("Deserialized {} bytes from {:?}", cbor_data.len(), path);

        Ok(data)
    }

    /// Serialize data to CBOR bytes
    pub fn serialize<T: Serialize>(data: &T) -> Result<Vec<u8>> {
        serde_cbor::to_vec(data)
            .context("Failed to serialize data to CBOR")
    }

    /// Deserialize data from CBOR bytes
    pub fn deserialize<T: for<'de> Deserialize<'de>>(cbor_data: &[u8]) -> Result<T> {
        serde_cbor::from_slice(cbor_data)
            .context("Failed to deserialize CBOR data")
    }

    /// Serialize data using ciborium (alternative CBOR implementation)
    /// Provides more compact encoding for certain data structures
    pub fn serialize_compact<T: Serialize>(data: &T) -> Result<Vec<u8>> {
        let mut buffer = Vec::new();
        ciborium::ser::into_writer(data, &mut buffer)
            .context("Failed to serialize data with ciborium")?;
        Ok(buffer)
    }

    /// Deserialize data using ciborium
    pub fn deserialize_compact<T: for<'de> Deserialize<'de>>(cbor_data: &[u8]) -> Result<T> {
        ciborium::de::from_reader(cbor_data)
            .context("Failed to deserialize data with ciborium")
    }
}

/// Module execution result with CBOR serialization
#[derive(Debug, Serialize, Deserialize)]
pub struct ExecutionResult {
    pub module_id: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub success: bool,
    pub output: String,
    pub error: Option<String>,
    pub execution_time_ms: u64,
    pub metadata: serde_json::Value,
}

impl ExecutionResult {
    pub fn new_success(module_id: String, output: String, execution_time_ms: u64) -> Self {
        Self {
            module_id,
            timestamp: chrono::Utc::now(),
            success: true,
            output,
            error: None,
            execution_time_ms,
            metadata: serde_json::json!({}),
        }
    }

    pub fn new_failure(module_id: String, error: String, execution_time_ms: u64) -> Self {
        Self {
            module_id,
            timestamp: chrono::Utc::now(),
            success: false,
            output: String::new(),
            error: Some(error),
            execution_time_ms,
            metadata: serde_json::json!({}),
        }
    }

    /// Save execution result to CBOR file
    pub fn save(&self, path: &Path) -> Result<()> {
        CBORHandler::serialize_to_file(self, path)
    }

    /// Load execution result from CBOR file
    pub fn load(path: &Path) -> Result<Self> {
        CBORHandler::deserialize_from_file(path)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn test_serialize_deserialize_bytes() {
        let original = ExecutionResult::new_success(
            "test-module".to_string(),
            "Test output".to_string(),
            150
        );

        let cbor_data = CBORHandler::serialize(&original).unwrap();
        let deserialized: ExecutionResult = CBORHandler::deserialize(&cbor_data).unwrap();

        assert_eq!(deserialized.module_id, original.module_id);
        assert_eq!(deserialized.success, original.success);
        assert_eq!(deserialized.output, original.output);
    }

    #[test]
    fn test_serialize_deserialize_file() {
        let dir = tempdir().unwrap();
        let file_path = dir.path().join("result.cbor");

        let original = ExecutionResult::new_failure(
            "failed-module".to_string(),
            "Test error".to_string(),
            75
        );

        original.save(&file_path).unwrap();
        let loaded = ExecutionResult::load(&file_path).unwrap();

        assert_eq!(loaded.module_id, original.module_id);
        assert_eq!(loaded.success, false);
        assert_eq!(loaded.error, original.error);
    }

    #[test]
    fn test_compact_serialization() {
        let original = ExecutionResult::new_success(
            "test".to_string(),
            "output".to_string(),
            100
        );

        let standard = CBORHandler::serialize(&original).unwrap();
        let compact = CBORHandler::serialize_compact(&original).unwrap();

        // Both should be valid
        let _: ExecutionResult = CBORHandler::deserialize(&standard).unwrap();
        let _: ExecutionResult = CBORHandler::deserialize_compact(&compact).unwrap();

        debug!("Standard: {} bytes, Compact: {} bytes", standard.len(), compact.len());
    }
}
