OS_TYPE := $(shell uname -s)
OS_HOST := $(host)

define not_supported
	@echo "ERROR: $@ - $(OS_TYPE) is not supported"
endef

.PHONY: format
# format the machine
format:
ifeq ($(OS_TYPE),Linux)
	nix --experimental-features "nix-command flakes" \
		run github:nix-community/disko/latest -- --mode destroy,format,mount ./systems/nixos/partitions.nix
  # generate the configuration
	nixos-generate-config --root /mnt
else
	$(call not_supported)
endif

.PHONY: install
# install the machine
install:
	curl -fsSL https://install.determinate.systems/nix | bash -s -- install --determinate

ifeq ($(OS_TYPE),Darwin)
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
endif

.PHONY: update
# update the machine
update:
ifeq ($(OS_TYPE),Linux)
	nixos-rebuild switch --flake .#$(OS_HOST)
else ifeq ($(OS_TYPE),Darwin)
	darwin-rebuild switch --flake .#$(OS_HOST)
	# nix run nix-darwin/nix-darwin-25.05#darwin-rebuild -- switch --flake .#$(OS_HOST)
else
	$(call not_supported)
endif

