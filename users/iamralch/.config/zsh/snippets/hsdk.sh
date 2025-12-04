#!/bin/bash -x

hsdk-env() {
	local HSDK_ENV_ID

	# Get environment data with console URL built by jq
	HSDK_ENV_ID=$(HSDK_DEFAULT_OUTPUT=json hsdk lse |
		jq -r '.[] | "\(.Id)\t\(.Name)\t\(.AWSSsoUrl)/#/console?account_id=\(.AWSAccountId)&role_name=AdministratorAccess"' |
		column -t -s $'\t' |
		fzf --with-nth=1,2 \
			--header='  Environment' \
			--bind 'ctrl-o:become(open {3})' |
		awk '{print $1}')

	if [ -n "$HSDK_ENV_ID" ]; then
		# Default action: set environment
		eval "$(hsdk se "$HSDK_ENV_ID")"
	fi
}
