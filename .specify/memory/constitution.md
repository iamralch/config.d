<!--
Sync Impact Report:
- Version Change: INITIAL → 1.1.0
- Principles Added:
  1. Declarative Configuration Excellence
  2. Host Isolation & Module Purity
  3. Reproducible System State
  4. Pinned Dependencies & Stability
  5. Self-Documenting Configuration
  6. Factory Pattern for System Composition
- Sections Added:
  - Core Principles (5 principles)
  - Configuration Architecture
  - Development & Maintenance
  - Governance
- Templates Status:
  ✅ plan-template.md - reviewed (generic template, no updates needed)
  ✅ spec-template.md - reviewed (generic template, no updates needed)
  ✅ tasks-template.md - reviewed (generic template, no updates needed)
  ✅ checklist-template.md - reviewed (generic template, no updates needed)
  ✅ agent-file-template.md - reviewed (generic template, no updates needed)
- Follow-up TODOs: None
-->

# config.d Constitution

## Core Principles

### I. Declarative Configuration Excellence

All system configuration MUST be declared explicitly in Nix expressions. Imperative modifications outside of declarative Nix code MUST NOT be performed or committed. Every configuration change MUST be version-controlled, auditable, and reproducible from the Git repository alone.

**Rationale**: Declarative configuration ensures reproducibility across machines and time. It eliminates configuration drift, simplifies rollback to known-good states, and forms the philosophical foundation of NixOS and nix-darwin. This principle is non-negotiable.

### II. Host Isolation & Module Purity

Each host configuration MUST be defined in an isolated `.nix` file under `hosts/`. Shared modules (OS-specific, user-specific, or cross-cutting) MUST reside in designated `systems/*/` or `users/*/` directories. Host-specific state MUST NOT leak into shared modules, and shared modules MUST NOT make assumptions about specific hosts.

**Rationale**: Isolation enables independent host evolution without cross-contamination. It prevents configuration entanglement and makes adding, removing, or modifying hosts safe and predictable.

### III. Reproducible System State

All flake inputs MUST be pinned in `flake.lock`. Changes to locked inputs MUST be explicit, tested commits. No implicit system state, dynamic downloads, or external dependencies MUST be introduced during evaluation or build. The same flake.lock MUST guarantee identical system configuration when `darwin-rebuild` or `nixos-rebuild` runs.

**Rationale**: Reproducibility is critical for disaster recovery, collaborative development, and confidence in system behavior. Pinned inputs eliminate surprise breakage and ensure deterministic deployment.

### IV. Pinned Dependencies & Stability

Major version upgrades (NixOS releases, Darwin releases, Nixpkgs channel) MUST be explicit, tested, and documented changes. Unstable packages (e.g., from `nixpkgs-unstable`) MAY be used for specific, cutting-edge tools but MUST be justified and isolated via overlays. Release channels (e.g., `25.05`) MUST be specified in `flake.nix` and remain stable until explicitly bumped.

**Rationale**: Stability over novelty. Pinned versions prevent unintended breakage. Targeted use of unstable packages allows flexibility for fast-moving tools without destabilizing core infrastructure.

### V. Self-Documenting Configuration

Every host configuration MUST include inline comments explaining non-obvious choices. Complex Nix expressions MUST document intent and rationale. User-facing configuration files (`.config/`) SHOULD include header comments linking to upstream documentation or clarifying project-specific behavior.

**Rationale**: Nix syntax is powerful but opaque. Inline documentation reduces cognitive load during maintenance, onboarding, and debugging. Future maintainers (including future-you) should understand why a configuration exists without archaeologial effort.

### VI. Factory Pattern for System Composition

Host configurations MUST be composed exclusively through the `mkSystem` factory function defined in `packages/mksystem.nix`. Direct instantiation of `nixosSystem` or `darwinSystem` outside this factory is PROHIBITED.

**Rationale**: The `mkSystem` factory enforces consistent module composition order, automatically handles platform differences (Darwin vs NixOS), and provides unified access to package sets and inputs. This pattern prevents configuration drift, reduces boilerplate, and ensures that all hosts follow the same structural discipline. Future changes to module composition affect all hosts consistently.

## Configuration Architecture

### Directory Structure

```
config.d/
├── hosts/                    # Host-specific configurations
│   ├── bm-macbook-pro-m1-prv.nix
│   ├── bm-macbook-pro-m1-wrk.nix
│   └── [other-hosts].nix
├── systems/
│   ├── macos/               # macOS-specific modules
│   │   ├── default.nix
│   │   ├── boot.nix
│   │   ├── packages.nix
│   │   ├── programs.nix
│   │   └── homebrew.nix
│   ├── nixos/               # NixOS-specific modules
│   │   ├── default.nix
│   │   ├── boot.nix
│   │   ├── packages.nix
│   │   ├── programs.nix
│   │   └── partitions.nix
│   └── share/               # Shared modules (both OSes)
│       ├── default.nix
│       ├── config.nix
│       ├── packages.nix
│       └── programs.nix
├── users/
│   └── [username]/          # Per-user home-manager configs
│       └── .config/         # Dotfiles managed via Nix or stow
├── packages/                # Custom derivations and builders
│   └── mksystem.nix
├── overlays/                # Package customizations and overrides
│   └── default.nix
├── .specify/                # Project governance and templates
├── flake.nix                # Flake definition and entry point
├── flake.lock               # Pinned dependency manifest (MUST commit)
└── Makefile                 # Build automation (darwin-rebuild, nixos-rebuild)
```

### Naming Conventions

- **Hosts**: `<descriptive-name>.nix` format (e.g., `bm-macbook-pro-m1-prv.nix` for "Backline MacBook, M1, Private")
- **Modules**: Lowercase with hyphens (e.g., `homebrew.nix`, `boot.nix`, `programs.nix`)
- **Users**: Match POSIX username (e.g., `iamralch/`)
- **Files**: Always `.nix` extension for Nix code; preserve `.toml`, `.json`, etc. for config formats

### Configuration Constraints

- **Home Manager**: Configurations MUST reside under `users/<username>/` with structure aligned to home-manager module paths
- **System Packages**: Declared in `systems/*/packages.nix` (not scattered across hosts)
- **User Dotfiles**: MAY be managed via Nix home-manager OR GNU stow (current project uses stow for `.config/`)
- **Secrets**: MUST NEVER be committed plaintext. Use `sops-nix`, `agenix`, or equivalent encryption
- **Overlays**: Package customizations MUST be isolated in `overlays/` to avoid host-specific breakage

## Development & Maintenance

### Workflow for Configuration Changes

1. **Edit**: Modify relevant `.nix` files or dotfiles in `users/`
2. **Test Locally**: Run `make update host=<hostname>` to invoke `darwin-rebuild` or `nixos-rebuild`
3. **Verify**: Confirm system behavior matches intent; check logs for warnings or errors
4. **Commit**: Create version-controlled commit with clear message (e.g., `feat: add neovim plugins to macOS config`)
5. **Lock Update**: If dependencies changed, commit `flake.lock` updates in a separate commit (e.g., `chore: update flake inputs (2025-11-02)`)

### Adding New Hosts

1. Create `hosts/<new-hostname>.nix` following the structure of existing hosts
2. Update `flake.nix` `outputs` section: add entry to `darwinConfigurations` (macOS) or `nixosConfigurations` (NixOS) by calling the `mkSystem` function
3. Define system architecture (`aarch64-darwin`, `x86_64-linux`, etc.) and primary user
4. Test with `make update host=<new-hostname>`

### The mkSystem Pattern

Host configurations MUST be defined using the `mkSystem` factory function (`packages/mksystem.nix`). This function:

- **Abstracts platform differences**: Automatically handles Darwin vs NixOS module composition
- **Enforces module order**: Applies overlays → shared modules → OS-specific modules → host configuration → user configuration → home-manager
- **Manages package sets**: Provides `pkgs` (stable nixpkgs), `upkgs` (unstable), and `extras` (nix-ai-tools) to all modules
- **Ensures consistency**: Prevents ad-hoc module composition that could introduce configuration drift

**Usage in flake.nix**:

```nix
darwinConfigurations.my-host = mkSystem "my-host" {
  system = "aarch64-darwin";
  user = "username";
};
```

All new hosts MUST follow this pattern. Direct calls to `nixpkgs.lib.nixosSystem` or `nix-darwin.lib.darwinSystem` outside of `mkSystem` are PROHIBITED.

### Updating Dependencies

1. Run `nix flake update` to refresh all inputs OR `nix flake lock --update-input <input>` for targeted updates
2. Test updated configuration on a non-critical host first (if available)
3. Commit `flake.lock` with message format: `chore: update flake inputs (YYYY-MM-DD)`
4. Roll out to remaining hosts only after validation confirms stability

### Rollback Procedure

- **macOS**: `darwin-rebuild --rollback` switches to previous generation
- **NixOS**: Select previous generation from GRUB boot menu OR run `nixos-rebuild --rollback`
- **Home Manager**: Use `home-manager generations` to list and `<path-to-generation>/activate` to restore

## Governance

### Constitution Authority

This constitution governs all changes to the `config.d` repository. When conflicts arise between this document and ad-hoc practices, this document prevails. Complexity additions (e.g., new overlays, custom builders, or host count) MUST be justified against principles of simplicity and maintainability.

### Amendment Process

1. **Propose**: Create issue or pull request documenting the desired change
2. **Justify**: Explain what problem is solved and which principle(s) it upholds or adds
3. **Update**: Modify this constitution with appropriate version bump
4. **Propagate**: Update dependent templates (plan, spec, tasks) if applicable
5. **Approve**: Require approval before merge (self-approval permitted for solo maintainer)
6. **Document**: Add entry to Sync Impact Report and commit

### Versioning Policy

- **MAJOR** (e.g., 1.0.0 → 2.0.0): Removal or redefinition of core principles; backward-incompatible governance changes
- **MINOR** (e.g., 1.0.0 → 1.1.0): Addition of new principles or major sections; expansion of existing guidance
- **PATCH** (e.g., 1.0.0 → 1.0.1): Clarifications, typo fixes, rewording without semantic change

### Compliance Review

All pull requests MUST verify before merge:

- **Declarative Check**: No imperative system modifications introduced; all changes expressible in Nix
- **Isolation Check**: Host-specific changes do not leak into shared modules; shared modules do not assume specific hosts
- **Lock Check**: If dependencies modified, `flake.lock` committed alongside code changes
- **Documentation Check**: Non-obvious configuration choices include inline comments explaining intent
- **Testing Check**: Changes tested on target host(s) before commit

---

**Version**: 1.1.0 | **Ratified**: 2025-11-02 | **Last Amended**: 2025-11-02
