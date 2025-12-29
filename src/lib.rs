// OASM Orchestrator Library
// Modular security orchestration with HDF5, CBOR, and PyO3

pub mod orchestrator;
pub mod hdf5_manager;
pub mod cbor_handler;
pub mod powershell;
pub mod audit;

use anyhow::Result;
use tracing::{info, debug};

/// Initialize the OASM orchestrator system
pub fn init() -> Result<()> {
    // Set up tracing subscriber
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::from_default_env()
                .add_directive(tracing::Level::DEBUG.into())
        )
        .with_target(false)
        .with_thread_ids(true)
        .with_file(true)
        .with_line_number(true)
        .init();

    info!("OASM Orchestrator initialized");
    debug!("Debug logging enabled");

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_init() {
        assert!(init().is_ok());
    }
}
