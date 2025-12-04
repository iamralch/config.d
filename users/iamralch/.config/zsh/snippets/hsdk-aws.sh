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

aws-logs() {
	# Get all log groups and select one with fzf
	local AWS_LOG_GROUP_LIST
	local AWS_LOG_GROUP_NAME

	AWS_LOG_GROUP_LIST=$(gum spin -- aws logs describe-log-groups --query 'logGroups[*].logGroupName' --output text | tr '\t' '\n')
	AWS_LOG_GROUP_NAME=$(echo "$AWS_LOG_GROUP_LIST" | fzf --header="  CloudWatch Log Group" --color=header:yellow)

	if [ "$1" = "tail" ]; then
		aws logs tail "$AWS_LOG_GROUP_NAME" "${@:2}"
		exit $?
	fi

	local AWS_LOG_STREAM_NAME
	local AWS_LOG_STREAM_LIST

	if [ -n "$AWS_LOG_GROUP_NAME" ]; then
		AWS_LOG_STREAM_LIST=$(gum spin -- aws logs describe-log-streams --log-group-name "$AWS_LOG_GROUP_NAME" --order-by LastEventTime --descending --query 'logStreams[*].logStreamName' --output text | tr '\t' '\n')
		AWS_LOG_STREAM_NAME=$(echo "$AWS_LOG_STREAM_LIST" | fzf --header="  CloudWatch Log Stream" --color=header:yellow --prompt=" $AWS_LOG_GROUP_NAME   ")
	fi

	if [ "$1" = "get-log-events" ]; then
		aws logs get-log-events --log-group-name "$AWS_LOG_GROUP_NAME" --log-stream-name "$AWS_LOG_STREAM_NAME" "${@:2}"
		exit $?
	fi
}
