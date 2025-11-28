#!/bin/bash -x

aws-lambda-compile() {
	export GOOS=linux
	export GOARCH=amd64
	export GOPATH="$HOME/go/src"

	GIT_BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD | tr '/' '-')
	GIT_REPOSITORY=$(grealpath --relative-to="$GOPATH" "$PWD")

	APP_NAME=$(basename "$PWD")
	APP_FQDN="$APP_NAME-$GIT_BRANCH"
	APP_BUILD="$PWD/build"

	rm -fr "$APP_BUILD"
	# prepare the build directory
	mkdir -p "$APP_BUILD"

	cd "$APP_BUILD" || true

	# compile the binary
	go build -a -v -o bootstrap -ldflags "-X main.Build=$GIT_BRANCH" "$GIT_REPOSITORY/cmd/$APP_NAME"
	# archive the binary
	zip -qj "$APP_FQDN.zip" bootstrap
	# generate the binary sha256
	openssl dgst -binary -sha256 "$APP_FQDN.zip" | base64 | tr -d '\n' >"$APP_FQDN-base64-sha256.sum"
}

aws-lambda-upload() {
	DIR_SOURCE="$PWD/build/"
	DIR_TARGET="s3://hippo-lambda-$HSDK_ENV_ID/"

	aws s3 cp "$DIR_SOURCE" "$DIR_TARGET" --recursive --exclude "*" --include "*.zip" --include "*.sum"
}

hsdk-env() {
	local selected
	selected=$(HSDK_DEFAULT_OUTPUT=json hsdk lse | jq -r '.[] | "\(.Id)\t\(.Name)"' | column -t -s $'\t' | fzf --with-nth=1,2 --header='  Environment' | awk '{print $1}')

	if [ -n "$selected" ]; then
		eval "$(hsdk se "$selected")"
	fi
}
