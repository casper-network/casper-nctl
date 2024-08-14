#!/usr/bin/env bash
# ----------------------------------------------------------------
# Synopsis.
# ----------------------------------------------------------------

# This test checks if the current gas price is preserved across the upgrades.

# 1. Start network from pre-built stage.
# 2. Execute large amount of deploys to make the price go higher.
# 3. Upgrade all running nodes to v2
# 4. Assert v2 nodes run & the chain advances (new blocks are generated)
# 5. Assert the gas price is preserved.

# ----------------------------------------------------------------
# Imports.
# ----------------------------------------------------------------

source "$NCTL/sh/utils/main.sh"
source "$NCTL/sh/node/svc_$NCTL_DAEMON_TYPE".sh
source "$NCTL/sh/scenarios/common/itst.sh"
source "$NCTL/sh/assets/upgrade.sh"

# ----------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------

function call_config_gen() {
    local OVERRIDE_SCRIPT
    local OVERRIDE_FILE=${1}
    local TOML_FILE=${2}
    local OUTPUT_FILE=${3}

    OVERRIDE_SCRIPT="$NCTL/scripts/config_gen.py"

    "$OVERRIDE_SCRIPT" --override_file "$OVERRIDE_FILE" \
        --toml_file "$TOML_FILE" \
        --output_file "$OUTPUT_FILE" \
        --no_skip
}

# Main entry point.
function _main()
{
    local PROTOCOL_VERSION=${1}
    local INITIAL_PROTOCOL_VERSION
    local ACTIVATION_POINT

    # Step 01: Start network from pre-built stage.
    _step_01
    # Step 02: Await for genesis
    _step_02
    # Step 03: Populate global state -> native + wasm transfers.
    _step_03

    # Step 04: Await era-id += 1.
    _step_04

    INITIAL_PROTOCOL_VERSION=$(get_node_protocol_version 1)
    ACTIVATE_ERA=$(($(get_chain_era)+2))

    log "Will upgrade the chain at era $ACTIVATE_ERA"

    _step_05 "$PROTOCOL_VERSION" "$ACTIVATE_ERA"

    # Step 06: Assert gas price pre and post upgrade
    _step_06

    _step_10
}

# Step 01: Start network from pre-built stage.
function _step_01()
{
    local CHAINSPEC_PATCH
    local PATH_TO_CHAINSPEC
    local NODE_CHAINSPEC_PATH

    log_step_upgrades 1 "Begin upgrade_scenario_15"

    nctl-assets-setup

    for IDX in $(seq 1 5)
    do
        NODE_CHAINSPEC_PATH="$(get_path_to_net)/nodes/node-$IDX/config/2_0_0/chainspec.toml"
        sed -i 's/upper_threshold = 90/upper_threshold = 1/g' "$NODE_CHAINSPEC_PATH"
        sed -i 's/lower_threshold = 50/lower_threshold = 0/g' "$NODE_CHAINSPEC_PATH"
        sed -i 's/max_gas_price = 3/max_gas_price = 10/g' "$NODE_CHAINSPEC_PATH"
        sed -i 's/max_block_size = 10485760/max_block_size = 2048/g' "$NODE_CHAINSPEC_PATH"
        sed -i 's/native_mint_lane = \[ 0, 1024, 1024, 65000000000, 650,\]/native_mint_lane = \[0, 1024, 1024, 65_000_000_000, 100\]/g' "$NODE_CHAINSPEC_PATH"
        sed -i 's/native_auction_lane = \[ 1, 2048, 2048, 362500000000, 145,\]/native_auction_lane = \[1, 2048, 2048, 362_500_000_000, 1\]/g' "$NODE_CHAINSPEC_PATH"
        sed -i 's/wasm_lanes = \[ \[ 2, 1048576, 2048, 1000000000000, 1,\], \[ 3, 344064, 1024, 500000000000, 3,\], \[ 4, 172032, 1024, 50000000000, 7,\], \[ 5, 12288, 512, 1500000000, 15,\],\]/wasm_lanes = \[\[2, 1_048_576, 2048, 1_000_000_000_000, 1\], \[3, 344_064, 1024, 500_000_000_000, 1\], \[4, 172_032, 1024, 50_000_000_000, 1\], \[5, 12_288, 512, 1_500_000_000, 1\]\]/g' "$NODE_CHAINSPEC_PATH"
   done

    log "... Starting 5 validators"
    source "$NCTL/sh/node/start.sh" node=all
}

# Step 02: Await for genesis
function _step_02()
{
    log_step_upgrades 2 "awaiting genesis era completion"

    do_await_genesis_era_to_complete 'false'
}

# Step 03: Populate global state -> native + wasm transfers.
function _step_03()
{
    log_step_upgrades 3 "dispatching deploys to populate global state"

    log "... 300 native transfers"
    source "$NCTL/sh/contracts-transfers/do_dispatch_native.sh" \
        transfers=300 interval=0.0 verbose=false
}

# Step 04: Await era-id += 1.
function _step_04()
{
    log_step_upgrades 4 "awaiting next era"

    nctl-await-n-eras offset='1' sleep_interval='2.0' timeout='180'
}

# Step 05: Upgrade network from stage.
function _step_05()
{
    local PROTOCOL_VERSION=${1}
    local ACTIVATION_POINT=${2}
    local NODE_CHAINSPEC_PATH

    log_step_upgrades 3 "upgrading 1 thru 5"

    log "... setting upgrade assets"

    for i in $(seq 1 5); do
        if [ "$i" -le '5' ]; then
            log "... staging upgrade on validator node-$i"
        else
            log "... staging upgrade on non-validator node-$i"
        fi
        _upgrade_node "$PROTOCOL_VERSION" "$ACTIVATION_POINT" "$i"

        NODE_CHAINSPEC_PATH="$(get_path_to_net)/nodes/node-$i/config/2_1_0/chainspec.toml"
        sed -i 's/upper_threshold = 90/upper_threshold = 1/g' "$NODE_CHAINSPEC_PATH"
        sed -i 's/lower_threshold = 50/lower_threshold = 0/g' "$NODE_CHAINSPEC_PATH"
        sed -i 's/max_gas_price = 3/max_gas_price = 10/g' "$NODE_CHAINSPEC_PATH"
        sed -i 's/max_block_size = 10485760/max_block_size = 2048/g' "$NODE_CHAINSPEC_PATH"
        sed -i 's/native_mint_lane = \[ 0, 1024, 1024, 65000000000, 650,\]/native_mint_lane = \[0, 1024, 1024, 65_000_000_000, 100\]/g' "$NODE_CHAINSPEC_PATH"
        sed -i 's/native_auction_lane = \[ 1, 2048, 2048, 362500000000, 145,\]/native_auction_lane = \[1, 2048, 2048, 362_500_000_000, 1\]/g' "$NODE_CHAINSPEC_PATH"
        sed -i 's/wasm_lanes = \[ \[ 2, 1048576, 2048, 1000000000000, 1,\], \[ 3, 344064, 1024, 500000000000, 3,\], \[ 4, 172032, 1024, 50000000000, 7,\], \[ 5, 12288, 512, 1500000000, 15,\],\]/wasm_lanes = \[\[2, 1_048_576, 2048, 1_000_000_000_000, 1\], \[3, 344_064, 1024, 500_000_000_000, 1\], \[4, 172_032, 1024, 50_000_000_000, 1\], \[5, 12_288, 512, 1_500_000_000, 1\]\]/g' "$NODE_CHAINSPEC_PATH"
    done

    log "... awaiting 2 eras + 1 block"
    nctl-await-n-eras offset='2' sleep_interval='5.0' timeout='180' node_id='2'
    await_n_blocks '1' 'true' '2'
}

# Step 06: Assert chain is progressing at all nodes.
function _step_06()
{
    local PATH_NODE_LOGS
    local UPGRADE_POINT
    local ERA_BEFORE_UPGRADE
    local ERA_AFTER_UPGRADE
    local GAS_PRICE_BEFORE_UPGRADE
    local GAS_PRICE_AFTER_UPGRADE

    log_step_upgrades 6 "asserting gas price"

    for IDX in $(seq 1 5)
    do
        PATH_NODE_LOGS=$(get_path_to_node_logs "$NODE_ID")
        UPGRADE_POINT=$(cat $PATH_NODE_LOGS/stdout.log | grep -n "node starting up\",\"protocol_version\"\:\"2\.1\.0" | cut -d: -f1)
        ERA_BEFORE_UPGRADE=$(head -$UPGRADE_POINT $PATH_NODE_LOGS/stdout.log | grep "New era gas price" | tail -1 | jq ".fields.message" | grep -o '[0-9]\+' | tail -1)
        GAS_PRICE_BEFORE_UPGRADE=$(head -$UPGRADE_POINT $PATH_NODE_LOGS/stdout.log | grep "New era gas price" | tail -1 | jq ".fields.message" | grep -o '[0-9]\+' | head -1)
        ERA_AFTER_UPGRADE=$(tail -n +$UPGRADE_POINT $PATH_NODE_LOGS/stdout.log | grep "New era gas price" | head -1 | jq ".fields.message" | grep -o '[0-9]\+' | tail -1)
        GAS_PRICE_AFTER_UPGRADE=$(tail -n +$UPGRADE_POINT $PATH_NODE_LOGS/stdout.log | grep "New era gas price" | head -1 | jq ".fields.message" | grep -o '[0-9]\+' | head -1)

        # We expect era to increase by 1 and gas price to remain the same.
        if [ "$ERA_BEFORE_UPGRADE" -eq "$((ERA_AFTER_UPGRADE - 1))" ] && [ "$GAS_PRICE_BEFORE_UPGRADE" -eq "$GAS_PRICE_AFTER_UPGRADE" ]; then
            log "... gas price preserved on node-$IDX"
        else
            log "... gas price not preserved on node-$IDX"
            exit 1
        fi
    done
}

# Step 10: Terminate.
function _step_10()
{
    log_step_upgrades 10 "test successful - tidying up"

    source "$NCTL/sh/assets/teardown.sh"

    log_break
}

# ----------------------------------------------------------------
# ENTRY POINT
# ----------------------------------------------------------------

unset INITIAL_PROTOCOL_VERSION
unset PROTOCOL_VERSION

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)
    case "$KEY" in
        version) PROTOCOL_VERSION=${VALUE} ;;
        *)
    esac
done

# Must be higher than the current protocol version.
PROTOCOL_VERSION=${PROTOCOL_VERSION:-"2_1_0"}

_main "$PROTOCOL_VERSION"
