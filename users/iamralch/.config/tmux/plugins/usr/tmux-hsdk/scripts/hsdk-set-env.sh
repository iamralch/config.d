#!/bin/bash

hsdk_set_env() {
	HSDK_ENV_NAME="$1"
	HSDK_ENV_ALIAS="$2"

	echo "Setting Environment..."
	echo
	echo "$HSDK_ENV_NAME ($HSDK_ENV_ALIAS)"
	echo

	eval "$(hsdk se "$HSDK_ENV_ALIAS")"
	exec zsh
}

hsdk_set_env "$@"
