#!/usr/bin/env bash

source "$NCTL"/sh/utils/main.sh

#######################################
# Displays on-chain deploy information.
# Arguments:
#   Deploy hash (optional). If not provided, lists all deploys in the latest block.
#   If no deploys are found, prints a message.
#######################################
function main()
{
    if [ -n "$DEPLOY_HASH" ]; then
        # If a specific deploy hash is provided, show only that deploy
        $(get_path_to_client) get-deploy \
            --node-address "$(get_node_address_rpc)" \
            "$DEPLOY_HASH"
    else
        # No deploy hash provided: list all deploys and transfers
        JSON_OUTPUT=$($(get_path_to_client) list-deploys \
            --node-address "$(get_node_address_rpc)")

        # Combine all hashes
        ALL_HASHES=$(echo "$JSON_OUTPUT" | jq -r '.deploy_hashes + .transfer_hashes | .[]?' )

        if [ -z "$ALL_HASHES" ]; then
            echo "No deploys or transfer hashes found in the current block."
            return
        fi

        # Loop through each hash and display its deploy info
        for HASH in $ALL_HASHES; do
            echo "===== Deploy: $HASH ====="
            $(get_path_to_client) get-deploy \
                --node-address "$(get_node_address_rpc)" \
                "$HASH"
            echo ""
        done
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

