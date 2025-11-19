#!/usr/bin/env bash

source "$NCTL"/sh/utils/main.sh

#######################################
# Displays on-chain deploy information.
# Arguments:
#   Deploy hash 
#   If no deploys are found or no deploy hash provided, prints a message.
#######################################
function main()
{
    if [ -n "$DEPLOY_HASH" ]; then
        # If a specific deploy hash is provided, show only that deploy
        $(get_path_to_client) get-deploy \
            --node-address "$(get_node_address_rpc)" \
            "$DEPLOY_HASH"
    else
        # No deploy hash provided:
        echo "no deploy hash provided, please provide a deploy hash to get the deploy information"
    fi
}

# ----------------------------------------------------------------
# ENTRY POINT
# ----------------------------------------------------------------

DEPLOY_HASH=""

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)
    case "$KEY" in
        deploy) DEPLOY_HASH=${VALUE} ;;
        *)
            # Ignore other arguments
            ;;
    esac
done

main "$DEPLOY_HASH"

