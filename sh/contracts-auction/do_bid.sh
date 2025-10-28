#!/usr/bin/env bash

source "$NCTL"/sh/utils/main.sh

#######################################
# Submits an auction bid.
# Arguments:
#   Bidder ordinal identifier.
#   Bid amount.
#   Delegation rate.
#   Flag indicating whether to emit log messages.
#######################################
function main()
{
    local BIDDER_ID=${1}
    local BID_AMOUNT=${2}
    local BID_DELEGATION_RATE=${3}
    local QUIET=${4:-"FALSE"}

    local CHAIN_NAME
    local GAS_PAYMENT
    local NODE_ADDRESS
    local PATH_TO_CLIENT
    local BIDDER_ACCOUNT_KEY
    local BIDDER_SECRET_KEY

    CHAIN_NAME=$(get_chain_name)
    GAS_PAYMENT=${GAS_PAYMENT:-$NCTL_DEFAULT_GAS_PAYMENT}
    NODE_ADDRESS=$(get_node_address_rpc)
    PATH_TO_CLIENT=$(get_path_to_client)

    BIDDER_ACCOUNT_KEY=$(get_account_key "$NCTL_ACCOUNT_TYPE_NODE" "$BIDDER_ID" | tr '[:upper:]' '[:lower:]')
    BIDDER_SECRET_KEY=$(get_path_to_secret_key "$NCTL_ACCOUNT_TYPE_NODE" "$BIDDER_ID")

    if [ "$QUIET" != "TRUE" ]; then
        log "dispatching transaction"
        log "... chain = $CHAIN_NAME"
        log "... dispatch node = $NODE_ADDRESS"
        log "... contract = $PATH_TO_CONTRACT"
        log "... bidder id = $BIDDER_ID"
        log "... bidder secret key = $BIDDER_SECRET_KEY"
        log "... bid amount = $BID_AMOUNT"
        log "... bid delegation rate = $BID_DELEGATION_RATE"
    fi

    TRANSACTION_HASH=$(
        $PATH_TO_CLIENT put-transaction add-bid \
            --chain-name "$CHAIN_NAME" \
            --node-address "$NODE_ADDRESS" \
            --payment-amount "$GAS_PAYMENT" \
            --ttl "5min" \
            --secret-key "$BIDDER_SECRET_KEY" \
            --public-key "$BIDDER_ACCOUNT_KEY" \
            --transaction-amount "$BID_AMOUNT" \
            --delegation-rate "$BID_DELEGATION_RATE" \
            --gas-price-tolerance 1 \
            --standard-payment true \
            | jq '.result.transaction_hash.Version1' \
            | sed -e 's/^"//' -e 's/"$//'
        )
        
        
    if [ "$QUIET" != "TRUE" ]; then
        log "transaction dispatched:"
        log "... transaction hash = $TRANSACTION_HASH"
    fi
}

# ----------------------------------------------------------------
# ENTRY POINT
# ----------------------------------------------------------------

unset AMOUNT
unset NODE_ID
unset DELEGATION_RATE
unset QUIET

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)
    case "$KEY" in
        amount) AMOUNT=${VALUE} ;;
        node) NODE_ID=${VALUE} ;;
        rate) DELEGATION_RATE=${VALUE} ;;
        quiet) QUIET=${VALUE} ;;
        *)
    esac
done

main "${NODE_ID:-6}" \
     "${AMOUNT:-$(get_node_staking_weight "${NODE_ID:-6}")}" \
     "${DELEGATION_RATE:-6}" \
     ${QUIET:-"FALSE"}
