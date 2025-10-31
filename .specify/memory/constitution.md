<!--
Sync Impact Report:
- Version change: 0.0.0 → 1.0.0
- List of modified principles:
    - [PRINCIPLE_1_NAME] → I. Declarative First
    - [PRINCIPLE_2_NAME] → II. Modularity and Reusability
    - [PRINCIPLE_3_NAME] → III. Host-Specific Configurations
    - [PRINCIPLE_4_NAME] → IV. Secrets Management
    - [PRINCIPLE_5_NAME] → V. Minimalism and Focus
- Added sections:
    - Development Workflow
    - Code Style and Structure
- Removed sections: None
- Templates requiring updates:
    - ✅ .specify/templates/plan-template.md
- Follow-up TODOs: None
-->
# config.d Constitution

## Core Principles

### I. Declarative First
All system and user configuration MUST be managed declaratively using Nix. This ensures reproducibility and simplifies system management.

### II. Modularity and Reusability
Configurations SHOULD be broken down into logical, reusable modules (e.g., by service, application, or feature). This promotes maintainability and scalability.

### III. Host-Specific Configurations
Each host MUST have a dedicated configuration file in the `hosts/` directory. This allows for tailored configurations while maximizing shared modules.

### IV. Secrets Management
No secrets are to be stored directly in the Nix store. Secrets MUST be managed externally and provisioned securely at runtime.

### V. Minimalism and Focus
Each configuration file or module SHOULD have a single, well-defined purpose. Avoid monolithic configuration files.

## Development Workflow

Updates to the configuration are managed through the `Makefile`. To apply changes to a target host, run `make update host=<TARGET_HOST>`. This command ensures that the configuration is built and activated correctly.

## Code Style and Structure

All Nix code SHOULD be formatted using `nixpkgs-fmt`. Before committing changes, run `nix flake check` to ensure that the configuration is valid and free of errors.

## Governance

All pull requests and reviews must verify compliance with this constitution. Any deviation from these principles must be justified and documented.

**Version**: 1.0.0 | **Ratified**: 2025-10-31 | **Last Amended**: 2025-10-31
