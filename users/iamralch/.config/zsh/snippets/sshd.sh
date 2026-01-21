#!/bin/bash

[ -z "$DEBUG" ] || set -x

# ------------------------------------------------------------------------------
# ssh-tunnel
# ------------------------------------------------------------------------------
# Create a reverse SSH tunnel to expose a local service to the internet.
#
# This function creates a reverse SSH tunnel using the Pinggy.io service,
# which allows you to expose local development servers, APIs, or services
# to the internet for testing, webhooks, or sharing purposes.
#
# The tunnel provides:
#   - HTTPS endpoint with automatic SSL certificate
#   - Random subdomain assignment
#   - Traffic forwarding to your local port
#   - Real-time connection logs
#
# Arguments:
#   $1 - Local port number to expose (required)
#
# Connection Details:
#   - Remote host: a.pinggy.io
#   - SSH port: 443 (works through most firewalls)
#   - Username: qr (Pinggy service account)
#   - Tunnel type: Reverse (-R flag)
#   - Auto-assigned remote port (0)
#
# Security Considerations:
#   - Exposes your local service to the public internet
#   - Use only for development and testing
#   - Consider authentication/authorization for sensitive services
#   - Tunnel session is active until SSH connection is terminated
#
# Example:
#   ssh-tunnel 3000          # Expose local port 3000 (e.g., React dev server)
#   ssh-tunnel 8080          # Expose local port 8080 (e.g., API server)
#
# Usage with Development Servers:
#   # Start your local server
#   npm start                # Usually runs on port 3000
#
#   # In another terminal, create tunnel
#   ssh-tunnel 3000
#
#   # Access via the provided HTTPS URL
#   # Example output: https://abc123.a.pinggy.io
# ------------------------------------------------------------------------------
ssh-tunnel() {
	ssh -p 443 -R0:localhost:"$1" qr@a.pinggy.io
}

# ------------------------------------------------------------------------------
# ssh-docker
# ------------------------------------------------------------------------------
# Connects to a development pod via SSH.
#
# This function constructs the SSH hostname by taking the base name of the
# current working directory and appending ".devpod" to it. It then initiates
# an SSH connection to this constructed hostname.
#
# This is useful for quickly connecting to dynamically named development
# environments (e.g., cloud-based dev environments) that follow a consistent
# naming convention based on the project directory.
#
# Arguments:
#   None. The hostname is derived from the current working directory.
#
# Example:
#   # If current directory is `/Users/iamralch/Projects/my-project`
#   ssh-docker               # Connects to `my-project.devpod`
#
# Usage with dynamically created dev pods:
#   Ensure your SSH config (~/.ssh/config) or DNS settings can resolve
#   hostnames like `your-project-name.devpod` to the correct IP address
#   or SSH gateway.
# ------------------------------------------------------------------------------
ssh-docker() {
	local project_name="${1:-}"

	local project_path
	project_path="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"

	if [[ -z "$project_name" ]]; then
		project_name="$(basename "$project_path")"
	fi

	local project_state
	project_state="$(devpod status --output json --silent "$project_name" | jq -r '.state')"

	case "$project_state" in
	NotFound | Stopped)
		devpod up "$project_path"
		;;
	Running)
		gum log --level info "Container '$project_name' is already running."
		;;
	*)
		gum log --level fatal "Failed to ssh '$project_name' (state: $project_state)"
		return 1
		;;
	esac

	gum log --level info "Connecting to '$project_name'..."
	# We use devpod ssh to connect to the pod
	devpod ssh --workdir /home/vscode/workspace "$project_name"
}
