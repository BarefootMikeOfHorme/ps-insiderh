// HDF5 Template Manager
// Handles loading/saving module templates using HDF5 format

use anyhow::{Result, Context};
use hdf5::{File, Group};
use std::path::PathBuf;
use tracing::{info, debug};
use crate::orchestrator::ModuleTemplate;

/// Manages HDF5 template storage and retrieval
pub struct HDF5Manager {
    template_dir: PathBuf,
}

impl HDF5Manager {
    pub fn new(template_dir: PathBuf) -> Self {
        Self { template_dir }
    }

    /// Load a module template from HDF5 file
    pub fn load_template(&self, name: &str) -> Result<ModuleTemplate> {
        let template_path = self.template_dir.join(format!("{}.h5", name));

        info!("Loading HDF5 template from: {:?}", template_path);

        if !template_path.exists() {
            anyhow::bail!("Template file not found: {:?}", template_path);
        }

        let file = File::open(&template_path)
            .context("Failed to open HDF5 template file")?;

        // Read metadata group
        let metadata_group = file.group("metadata")
            .context("Failed to read metadata group")?;

        let id = Self::read_string_attr(&metadata_group, "id")?;
        let version = Self::read_string_attr(&metadata_group, "version")?;
        let binary_path_str = Self::read_string_attr(&metadata_group, "binary_path")?;

        // Read extended metadata as JSON
        let metadata_json = Self::read_string_attr(&metadata_group, "extended_metadata")
            .unwrap_or_else(|_| "{}".to_string());
        let metadata: serde_json::Value = serde_json::from_str(&metadata_json)
            .context("Failed to parse extended metadata JSON")?;

        debug!("Loaded template: id={}, version={}", id, version);

        Ok(ModuleTemplate {
            id,
            version,
            binary_path: PathBuf::from(binary_path_str),
            metadata,
        })
    }

    /// Save a module template to HDF5 file
    pub fn save_template(&self, template: &ModuleTemplate) -> Result<()> {
        let template_path = self.template_dir.join(format!("{}.h5", template.id));

        info!("Saving HDF5 template to: {:?}", template_path);

        // Create parent directory if it doesn't exist
        if let Some(parent) = template_path.parent() {
            std::fs::create_dir_all(parent)
                .context("Failed to create template directory")?;
        }

        let file = File::create(&template_path)
            .context("Failed to create HDF5 template file")?;

        // Create metadata group
        let metadata_group = file.create_group("metadata")
            .context("Failed to create metadata group")?;

        Self::write_string_attr(&metadata_group, "id", &template.id)?;
        Self::write_string_attr(&metadata_group, "version", &template.version)?;
        Self::write_string_attr(&metadata_group, "binary_path",
            template.binary_path.to_str().unwrap_or(""))?;

        // Serialize extended metadata as JSON
        let metadata_json = serde_json::to_string(&template.metadata)
            .context("Failed to serialize extended metadata")?;
        Self::write_string_attr(&metadata_group, "extended_metadata", &metadata_json)?;

        // Create data group for future binary data storage
        file.create_group("data")
            .context("Failed to create data group")?;

        info!("Template saved successfully: {}", template.id);

        Ok(())
    }

    /// List all available templates
    pub fn list_templates(&self) -> Result<Vec<String>> {
        let mut templates = Vec::new();

        if !self.template_dir.exists() {
            return Ok(templates);
        }

        for entry in std::fs::read_dir(&self.template_dir)
            .context("Failed to read template directory")?
        {
            let entry = entry.context("Failed to read directory entry")?;
            let path = entry.path();

            if path.extension().and_then(|s| s.to_str()) == Some("h5") {
                if let Some(stem) = path.file_stem().and_then(|s| s.to_str()) {
                    templates.push(stem.to_string());
                }
            }
        }

        debug!("Found {} templates", templates.len());
        Ok(templates)
    }

    /// Helper: Read string attribute from HDF5 group
    fn read_string_attr(group: &Group, name: &str) -> Result<String> {
        let attr = group.attr(name)
            .with_context(|| format!("Failed to read attribute: {}", name))?;

        let value: hdf5::types::VarLenUnicode = attr.read_scalar()
            .with_context(|| format!("Failed to read scalar value for: {}", name))?;

        Ok(value.to_string())
    }

    /// Helper: Write string attribute to HDF5 group
    fn write_string_attr(group: &Group, name: &str, value: &str) -> Result<()> {
        let string_value = unsafe { hdf5::types::VarLenUnicode::from_str_unchecked(value) };

        group.new_attr_builder()
            .with_data(&string_value)
            .create(name)
            .with_context(|| format!("Failed to create attribute: {}", name))?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn test_save_and_load_template() {
        let dir = tempdir().unwrap();
        let manager = HDF5Manager::new(dir.path().to_path_buf());

        let template = ModuleTemplate {
            id: "test-module".to_string(),
            version: "1.0.0".to_string(),
            binary_path: PathBuf::from("/opt/modules/test"),
            metadata: serde_json::json!({
                "description": "Test module",
                "author": "OASM Team"
            }),
        };

        manager.save_template(&template).unwrap();
        let loaded = manager.load_template("test-module").unwrap();

        assert_eq!(loaded.id, template.id);
        assert_eq!(loaded.version, template.version);
        assert_eq!(loaded.binary_path, template.binary_path);
    }

    #[test]
    fn test_list_templates() {
        let dir = tempdir().unwrap();
        let manager = HDF5Manager::new(dir.path().to_path_buf());

        assert_eq!(manager.list_templates().unwrap().len(), 0);

        let template = ModuleTemplate {
            id: "module1".to_string(),
            version: "1.0.0".to_string(),
            binary_path: PathBuf::from("/opt/modules/module1"),
            metadata: serde_json::json!({}),
        };

        manager.save_template(&template).unwrap();
        assert_eq!(manager.list_templates().unwrap().len(), 1);
    }
}
