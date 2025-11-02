<!--
Sync Impact Report:
- Version Change: INITIAL → 1.0.0
- Principles Added:
  1. Declarative Configuration
  2. Host Isolation & Modularity
  3. Reproducible Builds
  4. Version Pinning
  5. Documentation-as-Code
- Sections Added:
  - Core Principles (5 principles)
  - Configuration Standards
  - Development Workflow
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

### I. Declarative Configuration

All system state MUST be declared explicitly in Nix expressions. Imperative modifications outside of the Nix configuration MUST be avoided. Each configuration change MUST be version-controlled and auditable.

**Rationale**: Declarative configuration ensures reproducibility, simplifies rollback, and eliminates configuration drift across hosts. This is the foundational principle of NixOS/nix-darwin and must be strictly enforced.

### II. Host Isolation & Modularity

Each host configuration MUST be isolated in `hosts/` with a dedicated `.nix` file. Shared functionality MUST reside in reusable modules under `systems/share/`, `systems/macos/`, or `systems/nixos/`. Host-specific configurations MUST NOT leak into shared modules.

**Rationale**: Isolation enables independent host evolution while modules promote DRY principles. This prevents cross-host contamination and makes configuration maintenance predictable at scale.

### III. Reproducible Builds

All inputs MUST be pinned via `flake.lock`. Changes to dependencies MUST be explicit commits. No implicit system state or external downloads MUST occur during evaluation or build. The same flake inputs MUST produce identical system configurations.

**Rationale**: Reproducibility is critical for disaster recovery, testing, and collaboration. Pinned inputs guarantee that `darwin-rebuild` or `nixos-rebuild` produces consistent results regardless of when or where it runs.

### IV. Version Pinning

Major version upgrades (NixOS releases, Darwin releases, nixpkgs) MUST be explicit, tested, and documented. `nixpkgs-unstable` MAY be used for specific packages via overlays but MUST NOT be the default. Release channels (e.g., `25.05`) MUST be specified in `flake.nix`.

**Rationale**: Stability over novelty. Pinning major versions prevents surprise breakage. Unstable packages are permitted for cutting-edge tools but must be justified and isolated.

### V. Documentation-as-Code

Every host MUST have inline comments explaining non-obvious configuration choices. Complex Nix expressions MUST include rationale comments. User-facing configuration files (e.g., `.config/`) SHOULD include header comments linking to upstream documentation.

**Rationale**: Nix syntax is powerful but opaque. Inline documentation reduces cognitive load during maintenance and onboarding. Future-you (or collaborators) should understand why a configuration exists without forensic archaeology.

## Configuration Standards

### File Organization

- **Hosts**: `hosts/<hostname>.nix` — host-specific hardware, users, hostname, networking
- **Systems**: `systems/nixos/`, `systems/macos/`, `systems/share/` — OS-specific and shared modules
- **Users**: `users/<username>/` — home-manager configurations, dotfiles
- **Packages**: `packages/` — custom derivations, system builders (e.g., `mksystem.nix`)
- **Overlays**: `overlays/` — package customizations and overrides

### Naming Conventions

- Host files MUST follow pattern: `<descriptive-name>.nix` (e.g., `bm-macbook-pro-m1-prv.nix`)
- Module files MUST use lowercase with hyphens: `boot.nix`, `homebrew.nix`, `programs.nix`
- User directories MUST match POSIX usernames

### Configuration Constraints

- Home Manager configs MUST reside under `users/<username>/`
- System-level packages MUST be declared in `systems/*/packages.nix`
- User dotfiles MAY be managed via Nix home-manager OR GNU stow (currently: stow for `.config/`)
- Secrets MUST NOT be committed plaintext (use `sops-nix`, `agenix`, or equivalent)

## Development Workflow

### Making Changes

1. **Edit**: Modify relevant `.nix` files or user configs
2. **Test Locally**: Run `make update host=<hostname>` (invokes `darwin-rebuild` or `nixos-rebuild`)
3. **Verify**: Check that system behaves as expected
4. **Commit**: Version control the change with descriptive commit message
5. **Update Lock**: If dependencies changed, commit `flake.lock` updates separately

### Adding New Hosts

1. Create `hosts/<new-hostname>.nix` based on existing host template
2. Add configuration to `flake.nix` `outputs` section (darwinConfigurations or nixosConfigurations)
3. Define system architecture and primary user
4. Import appropriate system modules (`systems/macos/` or `systems/nixos/`)
5. Test with `make update host=<new-hostname>`

### Updating Dependencies

1. Run `nix flake update` to refresh all inputs OR `nix flake lock --update-input <input>` for targeted updates
2. Test the updated system on a non-critical host first
3. Commit `flake.lock` with message: `chore: update flake inputs (YYYY-MM-DD)`
4. Roll out to remaining hosts after validation

### Rollback Procedure

- **macOS**: `darwin-rebuild --rollback`
- **NixOS**: Select previous generation from boot menu OR `nixos-rebuild --rollback`
- **Home Manager**: `home-manager generations` → `<path-to-generation>/activate`

## Governance

### Constitution Authority

This constitution governs all changes to the `config.d` repository. When conflicts arise between this document and ad-hoc practices, this document prevails. Complexity additions (e.g., additional overlays, custom builders) MUST be justified against the principle of simplicity.

### Amendment Process

1. Propose amendment via issue or pull request
2. Document rationale (what problem does it solve? what principle does it uphold or add?)
3. Update this constitution with version bump
4. Propagate changes to dependent templates (plan, spec, tasks) if applicable
5. Require approval before merge (self-approval permitted for solo maintainer)

### Versioning Policy

- **MAJOR**: Removal or redefinition of core principles; backward-incompatible governance changes
- **MINOR**: Addition of new principles or sections; expansion of existing guidance
- **PATCH**: Clarifications, typo fixes, rewording without semantic change

### Compliance Review

All pull requests MUST verify:
- Host isolation maintained (no shared state leakage)
- Inputs remain pinned (`flake.lock` committed)
- Documentation updated for non-obvious changes
- No imperative system modifications introduced

**Version**: 1.0.0 | **Ratified**: 2025-11-02 | **Last Amended**: 2025-11-02
