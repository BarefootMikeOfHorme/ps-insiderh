// Audit Logging Module
// Provides immutable, tamper-evident audit logging using HDF5

use anyhow::{Result, Context};
use chrono::{DateTime, Utc};
use serde::{Serialize, Deserialize};
use std::path::{Path, PathBuf};
use tracing::{info, debug};
use uuid::Uuid;
use blake3::Hasher;

/// Audit event severity level
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
pub enum AuditLevel {
    Debug,
    Info,
    Warning,
    Error,
    Critical,
}

/// Audit event type
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum AuditEventType {
    ModuleLoaded,
    ModuleExecuted,
    ModuleFailed,
    ConfigurationChanged,
    SecurityEvent,
    DataAccess,
    SystemEvent,
    Custom(String),
}

/// Individual audit event
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuditEvent {
    pub event_id: Uuid,
    pub timestamp: DateTime<Utc>,
    pub level: AuditLevel,
    pub event_type: AuditEventType,
    pub actor: String,
    pub action: String,
    pub target: Option<String>,
    pub metadata: serde_json::Value,
    pub hash: String,
}

impl AuditEvent {
    /// Create a new audit event
    pub fn new(
        level: AuditLevel,
        event_type: AuditEventType,
        actor: String,
        action: String,
    ) -> Self {
        let event_id = Uuid::new_v4();
        let timestamp = Utc::now();

        let mut event = Self {
            event_id,
            timestamp,
            level,
            event_type,
            actor,
            action,
            target: None,
            metadata: serde_json::json!({}),
            hash: String::new(),
        };

        event.hash = event.calculate_hash();
        event
    }

    /// Add target to event
    pub fn with_target(mut self, target: String) -> Self {
        self.target = Some(target);
        self.hash = self.calculate_hash();
        self
    }

    /// Add metadata to event
    pub fn with_metadata(mut self, metadata: serde_json::Value) -> Self {
        self.metadata = metadata;
        self.hash = self.calculate_hash();
        self
    }

    /// Calculate cryptographic hash of event for tamper detection
    fn calculate_hash(&self) -> String {
        let mut hasher = Hasher::new();

        hasher.update(self.event_id.as_bytes());
        hasher.update(self.timestamp.to_rfc3339().as_bytes());
        hasher.update(format!("{:?}", self.level).as_bytes());
        hasher.update(format!("{:?}", self.event_type).as_bytes());
        hasher.update(self.actor.as_bytes());
        hasher.update(self.action.as_bytes());

        if let Some(ref target) = self.target {
            hasher.update(target.as_bytes());
        }

        hasher.update(self.metadata.to_string().as_bytes());

        let hash = hasher.finalize();
        hash.to_hex().to_string()
    }

    /// Verify event integrity
    pub fn verify_integrity(&self) -> bool {
        let calculated_hash = self.calculate_hash();
        calculated_hash == self.hash
    }
}

/// Audit logger that writes to HDF5-based immutable storage
pub struct AuditLogger {
    log_dir: PathBuf,
    buffer: Vec<AuditEvent>,
    buffer_size: usize,
}

impl AuditLogger {
    /// Create a new audit logger
    pub fn new(log_dir: PathBuf) -> Result<Self> {
        std::fs::create_dir_all(&log_dir)
            .context("Failed to create audit log directory")?;

        Ok(Self {
            log_dir,
            buffer: Vec::new(),
            buffer_size: 100, // Flush after 100 events
        })
    }

    /// Log an audit event
    pub fn log(&mut self, event: AuditEvent) -> Result<()> {
        debug!("Audit event [{}]: {} - {}", event.event_id, event.actor, event.action);

        // Verify event integrity before logging
        if !event.verify_integrity() {
            anyhow::bail!("Audit event integrity check failed");
        }

        self.buffer.push(event);

        // Auto-flush if buffer is full
        if self.buffer.len() >= self.buffer_size {
            self.flush()?;
        }

        Ok(())
    }

    /// Flush buffered events to persistent storage
    pub fn flush(&mut self) -> Result<()> {
        if self.buffer.is_empty() {
            return Ok(());
        }

        info!("Flushing {} audit events to storage", self.buffer.len());

        // Create log file with timestamp
        let timestamp = Utc::now().format("%Y%m%d_%H%M%S");
        let log_file = self.log_dir.join(format!("audit_{}.cbor", timestamp));

        // Serialize events to CBOR
        crate::cbor_handler::CBORHandler::serialize_to_file(&self.buffer, &log_file)
            .context("Failed to write audit events to storage")?;

        info!("Audit events written to: {:?}", log_file);

        self.buffer.clear();

        Ok(())
    }

    /// Create a module load event
    pub fn log_module_load(&mut self, module_id: &str, actor: &str) -> Result<()> {
        let event = AuditEvent::new(
            AuditLevel::Info,
            AuditEventType::ModuleLoaded,
            actor.to_string(),
            "load_module".to_string(),
        )
        .with_target(module_id.to_string())
        .with_metadata(serde_json::json!({
            "module_id": module_id,
        }));

        self.log(event)
    }

    /// Create a module execution event
    pub fn log_module_execution(
        &mut self,
        module_id: &str,
        actor: &str,
        success: bool,
        execution_time_ms: u64,
    ) -> Result<()> {
        let level = if success { AuditLevel::Info } else { AuditLevel::Error };
        let event_type = if success {
            AuditEventType::ModuleExecuted
        } else {
            AuditEventType::ModuleFailed
        };

        let event = AuditEvent::new(
            level,
            event_type,
            actor.to_string(),
            "execute_module".to_string(),
        )
        .with_target(module_id.to_string())
        .with_metadata(serde_json::json!({
            "module_id": module_id,
            "success": success,
            "execution_time_ms": execution_time_ms,
        }));

        self.log(event)
    }

    /// Create a security event
    pub fn log_security_event(&mut self, actor: &str, action: &str, details: serde_json::Value) -> Result<()> {
        let event = AuditEvent::new(
            AuditLevel::Warning,
            AuditEventType::SecurityEvent,
            actor.to_string(),
            action.to_string(),
        )
        .with_metadata(details);

        self.log(event)
    }

    /// Read audit events from a log file
    pub fn read_log_file(path: &Path) -> Result<Vec<AuditEvent>> {
        crate::cbor_handler::CBORHandler::deserialize_from_file(path)
            .context("Failed to read audit log file")
    }

    /// Verify integrity of all events in a log file
    pub fn verify_log_file(path: &Path) -> Result<bool> {
        let events: Vec<AuditEvent> = Self::read_log_file(path)?;

        for event in events {
            if !event.verify_integrity() {
                return Ok(false);
            }
        }

        Ok(true)
    }
}

impl Drop for AuditLogger {
    fn drop(&mut self) {
        // Ensure buffered events are flushed on drop
        if let Err(e) = self.flush() {
            eprintln!("Failed to flush audit events on drop: {}", e);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn test_event_integrity() {
        let event = AuditEvent::new(
            AuditLevel::Info,
            AuditEventType::ModuleLoaded,
            "system".to_string(),
            "load_template".to_string(),
        );

        assert!(event.verify_integrity());

        // Tamper with event
        let mut tampered = event.clone();
        tampered.actor = "attacker".to_string();

        assert!(!tampered.verify_integrity());
    }

    #[test]
    fn test_audit_logger() {
        let dir = tempdir().unwrap();
        let mut logger = AuditLogger::new(dir.path().to_path_buf()).unwrap();

        logger.log_module_load("test-module", "system").unwrap();
        logger.log_module_execution("test-module", "system", true, 150).unwrap();

        logger.flush().unwrap();

        // Verify log files were created
        let entries: Vec<_> = std::fs::read_dir(dir.path()).unwrap().collect();
        assert!(entries.len() > 0);
    }

    #[test]
    fn test_log_file_verification() {
        let dir = tempdir().unwrap();
        let mut logger = AuditLogger::new(dir.path().to_path_buf()).unwrap();

        logger.log_module_load("test", "system").unwrap();
        logger.flush().unwrap();

        // Find the log file
        let log_file = std::fs::read_dir(dir.path())
            .unwrap()
            .next()
            .unwrap()
            .unwrap()
            .path();

        assert!(AuditLogger::verify_log_file(&log_file).unwrap());
    }
}
