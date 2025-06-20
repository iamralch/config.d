OS_TYPE := $(shell uname -s)
OS_HOST := $(host)

define not_supported
	@echo "ERROR: $@ - $(OS_TYPE) is not supported"
endef

.PONY: format
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

.PONY: install
# install the machine
install:
ifeq ($(OS_TYPE),Linux)
	curl -fsSL https://nixos.org/nix/install | bash -s -- --daemon 
else ifeq ($(OS_TYPE),Darwin)
	curl -fsSL https://install.determinate.systems/nix | bash -s -- install --determinate
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
else
	$(call not_supported)
endif

.PONY: update
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
