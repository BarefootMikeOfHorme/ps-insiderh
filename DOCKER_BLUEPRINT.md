# Docker Environment Blueprint
## OASM + Custom PowerShell + Rust + PyO3 Integration

---

## Executive Summary

Based on the deep research results and component analysis, this blueprint outlines a multi-container Docker environment for building, testing, and running a modular, auditable security orchestration system.

### Component Clarifications

**1. OASM (TypeScript/Node.js)**
- Official platform: Attack Surface Management
- Architecture: Console + Core API + Distributed Workers + PostgreSQL
- **Integration Challenge**: OASM is TypeScript-based, needs API-level integration with Rust

**2. "WPShell" → (deprecated) legacy custom wrapper; use PS-Insider hardened runtime**
- NOT WordPress WP-CLI
- Interpreted as: **Minimal Windows PowerShell core wrapped in Rust**
- Goal: Reduce PowerShell to essential scripting capabilities

**3. "PS2026" → PS-Insider Hardened (PowerShell Insider target/runtime)**
- PowerShell 7.4 LTS (supported until Nov 2026)
- Built on .NET 8.0
- Will use: `mcr.microsoft.com/dotnet/sdk:8.0`

**4. Rust Orchestrator**
- Primary orchestration layer
- Wraps Windows capabilities
- Manages HDF5 templates and CBOR serialization

**5. PyO3 Integration**
- Rust-Python bridge for pattern testing
- Enables Python ML/analysis frameworks

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose Stack                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Rust Core   │  │   PyO3       │  │  PowerShell  │      │
│  │  Orchestrator│◄─┤  Pattern     │  │  Minimal     │      │
│  │  + HDF5      │  │  Testing     │  │  Core        │      │
│  └──────┬───────┘  └──────────────┘  └──────────────┘      │
│         │                                                    │
│         │  ┌──────────────────────────────────┐            │
│         └─►│  OASM Platform (Optional)        │            │
│            │  - Console (React)                │            │
│            │  - Core API (TypeScript)          │            │
│            │  - Workers                        │            │
│            │  - PostgreSQL                     │            │
│            └──────────────────────────────────┘            │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Shared Volumes                                       │   │
│  │  - /workspace (source code)                           │   │
│  │  - /templates (HDF5 immutable templates)              │   │
│  │  - /logs (audit logs)                                 │   │
│  │  - /data (CBOR serialized data)                       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```