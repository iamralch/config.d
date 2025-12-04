#!/bin/bash -x

hsdk-env() {
	local HSDK_ENV_ID
	local HSDK_ENV_LIST

	# Get environment data with console URL built by jq
	HSDK_ENV_LIST=$(HSDK_DEFAULT_OUTPUT=json hsdk lse | jq -r '.[] | "\(.Id)\t\(.Name)\t\(.AWSSsoUrl)/#/console?account_id=\(.AWSAccountId)&role_name=AdministratorAccess"' | column -t -s $'\t')
	HSDK_ENV_ID=$(echo "$HSDK_ENV_LIST" | fzf --with-nth=1,2 --accept-nth=1 --header='  Environment' --color=header:cyan --bind 'ctrl-o:become(open {3})')

	if [ -n "$HSDK_ENV_ID" ]; then
		# Default action: set environment
		eval "$(hsdk se "$HSDK_ENV_ID")"
	fi
}
