#!/bin/bash -x

replace() {
	rg -l "$1" | xargs sd "$1" "$2"
}

go-build() {
	export GOOS=linux
	export GOARCH=amd64
	export GOPROJECTS="$HOME/Projects"

	GIT_BRANCH=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD | tr '/' '-')
	GIT_REPOSITORY=$(grealpath --relative-to="$GOPROJECTS" "$PWD")

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
