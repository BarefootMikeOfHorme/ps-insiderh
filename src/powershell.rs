// PowerShell Wrapper Module
// Provides safe execution of PowerShell scripts with audit logging

use anyhow::{Result, Context};
use std::process::{Command, Stdio};
use std::path::Path;
use tracing::{info, debug, warn, error};
use chrono::Utc;
use uuid::Uuid;

/// PowerShell execution configuration
#[derive(Debug, Clone)]
pub struct PowerShellConfig {
    /// PowerShell executable path (default: "pwsh" for PowerShell 7.x)
    pub executable: String,
    /// Working directory for script execution
    pub working_dir: Option<String>,
    /// Execution timeout in seconds
    pub timeout_seconds: u64,
    /// Whether to capture stdout
    pub capture_output: bool,
    /// Whether to capture stderr
    pub capture_stderr: bool,
}

impl Default for PowerShellConfig {
    fn default() -> Self {
        Self {
            executable: "pwsh".to_string(),
            working_dir: None,
            timeout_seconds: 300, // 5 minutes
            capture_output: true,
            capture_stderr: true,
        }
    }
}

/// PowerShell execution result
#[derive(Debug)]
pub struct PowerShellResult {
    pub execution_id: Uuid,
    pub success: bool,
    pub exit_code: i32,
    pub stdout: String,
    pub stderr: String,
    pub execution_time_ms: u64,
    pub timestamp: chrono::DateTime<Utc>,
}

/// PowerShell wrapper for safe script execution
pub struct PowerShellWrapper {
    config: PowerShellConfig,
}

impl PowerShellWrapper {
    pub fn new(config: PowerShellConfig) -> Self {
        Self { config }
    }

    /// Execute a PowerShell script from string
    pub fn execute_script(&self, script: &str) -> Result<PowerShellResult> {
        let execution_id = Uuid::new_v4();
        let start_time = std::time::Instant::now();

        info!("Executing PowerShell script [{}]", execution_id);
        debug!("Script content: {}", script);

        let mut command = Command::new(&self.config.executable);

        // Set execution policy and other safety flags
        command
            .arg("-NoProfile")
            .arg("-NonInteractive")
            .arg("-ExecutionPolicy")
            .arg("Bypass")
            .arg("-Command")
            .arg(script);

        // Set working directory if specified
        if let Some(ref working_dir) = self.config.working_dir {
            command.current_dir(working_dir);
        }

        // Configure stdio
        if self.config.capture_output {
            command.stdout(Stdio::piped());
        }
        if self.config.capture_stderr {
            command.stderr(Stdio::piped());
        }

        // Execute the command
        let output = command.output()
            .context("Failed to execute PowerShell command")?;

        let execution_time_ms = start_time.elapsed().as_millis() as u64;

        let stdout = if self.config.capture_output {
            String::from_utf8_lossy(&output.stdout).to_string()
        } else {
            String::new()
        };

        let stderr = if self.config.capture_stderr {
            String::from_utf8_lossy(&output.stderr).to_string()
        } else {
            String::new()
        };

        let exit_code = output.status.code().unwrap_or(-1);
        let success = output.status.success();

        if !success {
            warn!("PowerShell script failed with exit code: {}", exit_code);
            debug!("stderr: {}", stderr);
        }

        info!("PowerShell execution completed [{}] in {}ms", execution_id, execution_time_ms);

        Ok(PowerShellResult {
            execution_id,
            success,
            exit_code,
            stdout,
            stderr,
            execution_time_ms,
            timestamp: Utc::now(),
        })
    }

    /// Execute a PowerShell script from file
    pub fn execute_script_file(&self, script_path: &Path) -> Result<PowerShellResult> {
        let execution_id = Uuid::new_v4();

        info!("Executing PowerShell script file [{}]: {:?}", execution_id, script_path);

        if !script_path.exists() {
            anyhow::bail!("Script file not found: {:?}", script_path);
        }

        let script_path_str = script_path.to_str()
            .context("Invalid script path")?;

        // Use -File parameter for script files
        let start_time = std::time::Instant::now();

        let mut command = Command::new(&self.config.executable);

        command
            .arg("-NoProfile")
            .arg("-NonInteractive")
            .arg("-ExecutionPolicy")
            .arg("Bypass")
            .arg("-File")
            .arg(script_path_str);

        if let Some(ref working_dir) = self.config.working_dir {
            command.current_dir(working_dir);
        }

        if self.config.capture_output {
            command.stdout(Stdio::piped());
        }
        if self.config.capture_stderr {
            command.stderr(Stdio::piped());
        }

        let output = command.output()
            .context("Failed to execute PowerShell script file")?;

        let execution_time_ms = start_time.elapsed().as_millis() as u64;

        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        let exit_code = output.status.code().unwrap_or(-1);
        let success = output.status.success();

        if !success {
            warn!("PowerShell script file failed with exit code: {}", exit_code);
        }

        info!("PowerShell file execution completed [{}] in {}ms", execution_id, execution_time_ms);

        Ok(PowerShellResult {
            execution_id,
            success,
            exit_code,
            stdout,
            stderr,
            execution_time_ms,
            timestamp: Utc::now(),
        })
    }

    /// Execute a simple PowerShell command
    pub fn execute_command(&self, command: &str) -> Result<PowerShellResult> {
        self.execute_script(command)
    }

    /// Check if PowerShell is available
    pub fn check_availability(&self) -> bool {
        let output = Command::new(&self.config.executable)
            .arg("-Command")
            .arg("Write-Output 'PowerShell Available'")
            .output();

        match output {
            Ok(out) => out.status.success(),
            Err(e) => {
                error!("PowerShell not available: {}", e);
                false
            }
        }
    }

    /// Get PowerShell version
    pub fn get_version(&self) -> Result<String> {
        let result = self.execute_script("$PSVersionTable.PSVersion.ToString()")?;

        if result.success {
            Ok(result.stdout.trim().to_string())
        } else {
            anyhow::bail!("Failed to get PowerShell version: {}", result.stderr)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_powershell_availability() {
        let config = PowerShellConfig::default();
        let wrapper = PowerShellWrapper::new(config);

        // This test will only pass if PowerShell is installed
        if wrapper.check_availability() {
            println!("PowerShell is available");
        } else {
            println!("PowerShell is not available (test skipped)");
        }
    }

    #[test]
    fn test_simple_command() {
        let config = PowerShellConfig::default();
        let wrapper = PowerShellWrapper::new(config);

        if !wrapper.check_availability() {
            println!("PowerShell not available, skipping test");
            return;
        }

        let result = wrapper.execute_command("Write-Output 'Hello from PowerShell'").unwrap();

        assert!(result.success);
        assert!(result.stdout.contains("Hello from PowerShell"));
    }

    #[test]
    fn test_failed_command() {
        let config = PowerShellConfig::default();
        let wrapper = PowerShellWrapper::new(config);

        if !wrapper.check_availability() {
            println!("PowerShell not available, skipping test");
            return;
        }

        let result = wrapper.execute_command("throw 'Test error'").unwrap();

        assert!(!result.success);
        assert_ne!(result.exit_code, 0);
    }
}
