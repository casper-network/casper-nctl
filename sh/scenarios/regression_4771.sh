#!/usr/bin/env bash

source "$NCTL"/sh/utils/main.sh
source "$NCTL"/sh/views/utils.sh
source "$NCTL"/sh/node/svc_"$NCTL_DAEMON_TYPE".sh
source "$NCTL"/sh/scenarios/common/itst.sh

#######################################
# This test checks if the entry point of an installed contact can successfully be invoked.
#
# It covers against the regression captured in the #4771 ticket.
#######################################
function main() {
    log "------------------------------------------------------------"
    log "Regression 4771 test begins"
    log "------------------------------------------------------------"

    do_await_genesis_era_to_complete
    TX_HASH=$(install_contract)
    log "Install contract transaction hash: $TX_HASH"
    await_n_blocks 2
    ENTITY_CONTRACT=$(get_entity_contract $TX_HASH)
    log "Contract entity: $ENTITY_CONTRACT"
    INVOKE_ENTRY_POINT_RESULT=$(call_entry_point $ENTITY_CONTRACT)
    log "Result of entry point invocation: $INVOKE_ENTRY_POINT_RESULT"

    if [[ "$INVOKE_ENTRY_POINT_RESULT" == *"no such contract at hash"* ]]; then
        log "Test failed: contract not found"
        exit 1
    fi

    MAYBE_ERROR_CODE=$(jq '.code' <(echo $INVOKE_ENTRY_POINT_RESULT | grep -o '{.*}'))
    if [ "$MAYBE_ERROR_CODE" != "null" ]; then
        log "Test failed: endpoint invocation resulted in an error"
        exit 1
    fi

    log "------------------------------------------------------------"
    log "Regression 4771 test finished"
    log "------------------------------------------------------------"
}

function install_contract() {
    local CHAIN_NAME
    local GAS_PAYMENT
    local NODE_ADDRESS
    local PATH_TO_CLIENT
    local PATH_TO_CONTRACT
    local CONTRACT_OWNER_SECRET_KEY
    local CONTRACT_ARG_MESSAGE="Hello Dolly"

    # Set standard deploy parameters.
    CHAIN_NAME=$(get_chain_name)
    GAS_PAYMENT=10000000000000
    NODE_ADDRESS=$(get_node_address_rpc)
    PATH_TO_CLIENT=$(get_path_to_client)

    # Set contract path.
    PATH_TO_CONTRACT="./smart_contracts/gh_4771_regression.wasm"
    if [ ! -f "$PATH_TO_CONTRACT" ]; then
        echo "ERROR: The gh_4771_regression.wasm binary file cannot be found.  Please compile it and move it to the following directory: ./sh/scenarios/smart_contracts/"
        return
    fi

    # Set contract owner secret key.
    CONTRACT_OWNER_SECRET_KEY=$(get_path_to_secret_key "$NCTL_ACCOUNT_TYPE_FAUCET")

    # Dispatch deploy (hits node api).
    TRANSACTION_INSTALL_RESULT=$(
        $PATH_TO_CLIENT put-transaction session \
            --chain-name "$CHAIN_NAME" \
            --node-address "$NODE_ADDRESS" \
            --transaction-path "$PATH_TO_CONTRACT" \
            --session-entry-point call \
            --session-arg "name:string='TEST_GH4771'" \
            --category install-upgrade \
            --payment-amount 150000000000 \
            --gas-price-tolerance 2 \
            --pricing-mode fixed \
            --secret-key "$CONTRACT_OWNER_SECRET_KEY"
        )

    TRANSACTION_HASH=$(echo $TRANSACTION_INSTALL_RESULT | jq '.result.transaction_hash.Version1' | sed -e 's/^"//' -e 's/"$//')
    echo $TRANSACTION_HASH
}

function get_entity_contract() {
    local TX_HASH=${1}
    local PATH_TO_CLIENT
    local NODE_ADDRESS
    local ENTITY_CONTRACT
    local ERROR_MESSAGE

    PATH_TO_CLIENT=$(get_path_to_client)
    NODE_ADDRESS=$(get_node_address_rpc)

    GET_TRANSACTION_RESULT=$(
        $PATH_TO_CLIENT get-transaction \
            --node-address "$NODE_ADDRESS" \
            $TX_HASH
        )

    ERROR_MESSAGE=$(echo $GET_TRANSACTION_RESULT | jq '.result.execution_info.execution_result.Version2.error_message')
    if [ "$ERROR_MESSAGE" != "null" ]; then
        log "Test failed: contract installation error: $ERROR_MESSAGE" >&2
        exit 1
    fi

    ENTITY_CONTRACT=$(echo $GET_TRANSACTION_RESULT | \
        jq '.result.execution_info.execution_result.Version2.effects[] | select(.key | startswith("entity-contract"))' | \
        jq .key | \
        sed -e 's/^"//' -e 's/"$//')
    echo $ENTITY_CONTRACT
}

function call_entry_point() {
    local ENTITY_CONTRACT=${1}

    local CHAIN_NAME
    local PATH_TO_CLIENT
    local NODE_ADDRESS

    PATH_TO_CLIENT=$(get_path_to_client)
    NODE_ADDRESS=$(get_node_address_rpc)
    CHAIN_NAME=$(get_chain_name)

    SECRET_KEY="$(get_path_to_user 1)/secret_key.pem"

    INVOKE_ENDPOINT_RESULT=$(
        $PATH_TO_CLIENT put-transaction invocable-entity \
            --node-address "$NODE_ADDRESS" \
            --chain-name "$CHAIN_NAME" \
            --entity-address "$ENTITY_CONTRACT" \
            --session-entry-point test_entry_point \
            --payment-amount 350000000000 \
            --gas-price-tolerance 100 \
            --pricing-mode fixed \
            --secret-key "$SECRET_KEY"
        )

    echo $INVOKE_ENDPOINT_RESULT
}

# ----------------------------------------------------------------
# ENTRY POINT
# ----------------------------------------------------------------

main
