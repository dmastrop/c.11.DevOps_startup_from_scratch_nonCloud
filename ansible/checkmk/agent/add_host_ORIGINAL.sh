#!/usr/bin/env bash

script_dir=$(dirname "$(readlink -f "$0")")
. "${script_dir}"/.env

# Collect information of current host
host=$(hostname -f)
default_interface=$(ip r | awk '/default/ {print $5}' | head -n1)
ip_address=$(ip a show dev "${default_interface}" | awk '$1 == "inet" { sub("/.*", "", $2); print $2}')

# checkmk_api_url and automation_secret variables
checkmk_api_url="${checkmk_api_url}"
automation_secret="${automation_secret}"

# Add host
curl \
	--request POST \
	--header "Authorization: Bearer automation ${automation_secret}" \
	--header "Accept: application/json" \
	--header "Content-Type: application/json" \
	--data '{
        "attributes": {
            "ipaddress": "'"${ip_address}"'"
        },
        "folder": "/",
        "host_name": "'"${host}"'"
    }' \
	"${checkmk_api_url}"/domain-types/host_config/collections/all

# Scan for services
# added mode tabula_rasa which should help with some issues
curl \
	--request POST \
	--header "Authorization: Bearer automation ${automation_secret}" \
	--header "Accept: application/json" \
	--header "Content-Type: application/json" \
	--data '{
        "host_name": "'"${host}"'",
        "mode": "tabula_rasa"
    }' \
	"${checkmk_api_url}"/domain-types/service_discovery_run/actions/start/invoke

# Activate changes
# the If-Match as indicated or put in Etag for the value as indicated here:
# https://docs.checkmk.com/latest/en/rest_api.html#restapi_show_a_host
curl \
	--request POST \
	--header "Authorization: Bearer automation ${automation_secret}" \
	--header "Accept: application/json" \
	--header "Content-Type: application/json" \
	--header "If-Match: "*"" \
	--data '{
        "force_foreign_changes": false,
        "redirect": false,
        "sites": [
            "cmk"
        ]
    }' \
	"${checkmk_api_url}"/domain-types/activation_run/actions/activate-changes/invoke
