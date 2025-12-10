#!/bin/bash -x

# ==============================================================================
# AWS Resource Selection Utilities
# ==============================================================================
# Shell functions for interactively selecting AWS resources using fuzzy
# finding (fzf) with visual feedback via gum spinner.
#
# Dependencies:
#   - aws: AWS CLI v2
#   - fzf: Fuzzy finder for terminal
#   - gum: A tool for glamorous shell scripts (provides spinner)
#
# Authentication:
#   Requires valid AWS credentials configured via:
#   - AWS CLI configuration (~/.aws/credentials)
#   - Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
#   - IAM roles (when running on EC2/ECS)
#   - AWS SSO
#
# Usage:
#   Source this file in your shell configuration:
#   source ~/.config/zsh/snippets/aws.sh
# ==============================================================================

# ------------------------------------------------------------------------------
# aws-s3-bucket-fzf
# ------------------------------------------------------------------------------
# Interactively select an S3 bucket from the current AWS account.
#
# This function retrieves all S3 buckets accessible to the current AWS
# credentials and presents them in an interactive fuzzy finder with a
# custom prompt showing the s3:// protocol prefix.
#
# Output:
#   The selected bucket name (stdout)
#   Empty string if no selection made
#
# Required Permissions:
#   - s3:ListAllMyBuckets
#
# Example:
#   bucket=$(aws-s3-bucket-fzf)
#   aws s3 ls "s3://$bucket"
# ------------------------------------------------------------------------------
aws-s3-bucket-fzf() {
	local bucket_list

	# Query AWS for all S3 buckets with spinner feedback
	# - JMESPath query extracts bucket names only
	# - tr converts tab-separated output to newline-separated list
	bucket_list=$(gum spin -- aws s3api list-buckets --query 'Buckets[*].Name' --output text | tr '\t' '\n')

	# Display buckets in fzf with s3:// prefix in prompt for context
	echo "$bucket_list" | fzf --ansi \
		--header="  S3 Bucket" \
		--color=header:yellow --prompt=" s3://  "
}

# ------------------------------------------------------------------------------
# aws-logs-group-fzf
# ------------------------------------------------------------------------------
# Interactively select a CloudWatch Logs log group.
#
# This function retrieves all CloudWatch log groups in the current region
# and presents them in an interactive fuzzy finder.
#
# Output:
#   The selected log group name (stdout)
#   Empty string if no selection made
#
# Required Permissions:
#   - logs:DescribeLogGroups
#
# Example:
#   log_group=$(aws-logs-group-fzf)
#   aws logs tail "$log_group" --follow
# ------------------------------------------------------------------------------
aws-logs-group-fzf() {
	local log_group_list

	# Query AWS for all CloudWatch log groups with spinner feedback
	# - JMESPath query extracts log group names only
	# - tr converts tab-separated output to newline-separated list
	log_group_list=$(gum spin --title "Loading AWS Log Groups..." -- aws logs describe-log-groups --query 'logGroups[*].logGroupName' --output text | tr '\t' '\n')

	# Display log groups in fzf
	echo "$log_group_list" | fzf --ansi \
		--header="  CloudWatch Log Group" \
		--color=header:yellow
}

# ------------------------------------------------------------------------------
# aws-logs-stream-fzf
# ------------------------------------------------------------------------------
# Interactively select a CloudWatch Logs log stream from a specific log group.
#
# This function retrieves log streams for a given log group, ordered by most
# recent activity first, and presents them in an interactive fuzzy finder.
#
# Arguments:
#   $1 - Log group name (required)
#
# Output:
#   The selected log stream name (stdout)
#   Empty string if no selection made
#
# Return Codes:
#   0 - Success
#   1 - Error (missing log group parameter)
#
# Required Permissions:
#   - logs:DescribeLogStreams
#
# Example:
#   log_group=$(aws-logs-group-fzf)
#   log_stream=$(aws-logs-stream-fzf "$log_group")
#   aws logs get-log-events --log-group-name "$log_group" --log-stream-name "$log_stream"
# ------------------------------------------------------------------------------
aws-logs-stream-fzf() {
	local log_group="${1}"
	local log_stream_list

	# Validate required parameter
	if [ -z "$log_group" ]; then
		gum log --level=error "Log group name required as first argument"
		return 1
	fi

	# Query AWS for log streams in the specified log group
	# - Ordered by LastEventTime descending (most recent first)
	# - JMESPath query extracts log stream names only
	# - tr converts tab-separated output to newline-separated list
	log_stream_list=$(gum spin --title "Loading AWS Log Streams..." -- aws logs describe-log-streams --log-group-name "$log_group" --order-by LastEventTime --descending --query 'logStreams[*].logStreamName' --output text --max-items 100 | tr '\t' '\n')

	# Display log streams in fzf with log group name in prompt for context
	echo "$log_stream_list" | fzf --ansi \
		--header="  CloudWatch Log Stream" \
		--color=header:yellow --prompt=" $log_group   "
}
