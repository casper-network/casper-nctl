#!/usr/bin/env bash

source "$NCTL"/sh/utils/main.sh

#######################################
# Submits an auction withdrawal.
# Arguments:
#   Validator ordinal identifier.
#   Withdrawal amount.
#   Flag indicating whether to emit log messages.
#######################################
function main()
{
    local BIDDER_ID=${1}
    local AMOUNT=${2}
    local QUIET=${3:-"FALSE"}
    local CHAIN_NAME
    local GAS_PAYMENT
    local NODE_ADDRESS
    local PATH_TO_CLIENT
    local BIDDER_SECRET_KEY
    local BIDDER_ACCOUNT_KEY
    local TRANSACTION_RESULT
    
    log "default amount , $AMOUNT"
    
    log "getting chain name"
    CHAIN_NAME=$(get_chain_name)
    log "getting gas payment"
    GAS_PAYMENT=${GAS_PAYMENT:-$NCTL_DEFAULT_GAS_PAYMENT}
    log "getting node address"
    NODE_ADDRESS=$(get_node_address_rpc)
    log "getting path to client"
    PATH_TO_CLIENT=$(get_path_to_client)

    log "getting secret key"
    BIDDER_SECRET_KEY=$(get_path_to_secret_key "$NCTL_ACCOUNT_TYPE_NODE" "$BIDDER_ID")
    log "getting account key"
    BIDDER_ACCOUNT_KEY=$(get_account_key "$NCTL_ACCOUNT_TYPE_NODE" "$BIDDER_ID" | tr '[:upper:]' '[:lower:]')

    if [ "$QUIET" != "TRUE" ]; then
        log "dispatching transaction"
        log "... chain = $CHAIN_NAME"
        log "... dispatch node = $NODE_ADDRESS"
        log "... bidder id = $BIDDER_ID"
        log "... bidder account key = $BIDDER_ACCOUNT_KEY"
        log "... bidder secret key = $BIDDER_SECRET_KEY"
        log "... withdrawal amount = $AMOUNT"
    fi

    log "... sending transaction"
    TRANSACTION_RESULT=$($PATH_TO_CLIENT put-transaction withdraw-bid \
                                 --chain-name "$CHAIN_NAME" \
                                 --node-address "$NODE_ADDRESS" \
                                 --payment-amount "$GAS_PAYMENT" \
                                 --ttl "5min" \
                                 --secret-key "$BIDDER_SECRET_KEY" \
                                 --gas-price-tolerance 1 \
                                 --standard-payment true \
                                 --public-key "$BIDDER_ACCOUNT_KEY" \
                                 --transaction-amount "$AMOUNT" )
    if [ -z "$TRANSACTION_RESULT" ]; then
        log "failed to get transaction result"
        log "... node address: $NODE_ADDRESS"
        exit 1
    else
        echo "$TRANSACTION_RESULT"
    fi

    log "... getting transaction hash"
    TRANSACTION_HASH=$(echo $TRANSACTION_RESULT | jq -r '.result.transaction_hash.Version1')

    if [ "$QUIET" != "TRUE" ]; then
        log "transation dispatched:"
        log "... transaction hash = $TRANSACTION_HASH"
    fi
}

# ----------------------------------------------------------------
# ENTRY POINT
# ----------------------------------------------------------------

unset AMOUNT
unset NODE_ID

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)
    case "$KEY" in
        amount) AMOUNT=${VALUE} ;;
        node) NODE_ID=${VALUE} ;;
        *)
    esac
done

main "${NODE_ID:-1}" \
     "${AMOUNT:-$(get_node_default_bid_withdraw_amount "${NODE_ID:-1}")}"
