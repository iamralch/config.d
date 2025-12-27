.PHONY: format
# format the machine (Linux only)
format:
	@if [ "$$(uname -s)" = "Linux" ]; then \
		nix --experimental-features "nix-command flakes" \
			run github:nix-community/disko/latest -- --mode destroy,format,mount ./systems/nixos/partitions.nix && \
		nixos-generate-config --root /mnt; \
	else \
		echo "ERROR: format is only supported on Linux"; \
		exit 1; \
	fi

.PHONY: install
# install nix and homebrew (Darwin only)
install:
	@if [ "$$(uname -s)" == "Darwin" ]; then \
		curl -fsSL https://install.determinate.systems/nix | bash -s -- install --determinate && \
		curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash \
	else \
		echo "ERROR: install is only supported on Darwin"; \
		exit 1; \
	fi

.PHONY: update
# update the machine: make update host=<hostname>
update:
	@if [ -z "$(host)" ]; then \
		echo "ERROR: host is required. Usage: make update host=<hostname>"; \
		exit 1; \
	fi
	@if [ "$$(uname -s)" = "Linux" ]; then \
		nixos-rebuild switch --flake .#$(host) --impure; \
	elif [ "$$(uname -s)" = "Darwin" ]; then \
		darwin-rebuild switch --flake .#$(host) --impure; \
	else \
		echo "ERROR: update is not supported on $$(uname -s)"; \
		exit 1; \
	fi
