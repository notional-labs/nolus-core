#!/bin/bash
set -euxo pipefail

# Add new DEX.
# Extending the existing Hermes settings and creating a connection between Nolus and the new DEX.

SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPTS_DIR"/internal/verify.sh
source "$SCRIPTS_DIR"/internal/add-dex-support.sh

NOLUS_NET="http://localhost:26612/"
NOLUS_HOME_DIR="$HOME/.nolus"
ACCOUNT_KEY_TO_FEED_HERMES_ADDRESS="reserve"
NOLUS_CHAIN_ID=$(grep -oP 'chain-id = "\K[^"]+' "$NOLUS_HOME_DIR"/config/client.toml)

HERMES_CONFIG_DIR_PATH="$HOME/.hermes"
HERMES_BINARY_DIR_PATH="$HOME/hermes"
CHAIN_ID=""
CHAIN_IP_ADDR_RPC=""
CHAIN_IP_ADDR_GRPC=""
CHAIN_ACCOUNT_PREFIX=""
CHAIN_PRICE_DENOM=""
CHAIN_TRUSTING_PERIOD=""


while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in

  -h | --help)
    printf \
    "Usage: %s
    [--nolus-home-dir <nolus_home_dir>]
    [--account-key-to-feed-hermes-address <account_key_to_feed_hermes_address>]
    [--hermes-config-dir-path <config.toml_and_hermes.seed_dir_path>]
    [--hermes-binary-dir-path <hermes_binary_dir_path>]
    [--dex-chain-id <new_dex_chain_id>]
    [--dex-ip-addr-rpc-host <new_dex_chain_ip_addr_rpc_fully_host>]
    [--dex-ip-addr-grpc-host <new_dex_chain_ip_addr_grpc_fully_host>]
    [--dex-account-prefix <new_dex_account_prefix>]
    [--dex-price-denom <new_dex_price_denom>]
    [--dex-trusting-period-secs <new_dex_trusting_period_in_seconds>]" \
    "$0"
    exit 0
    ;;

  --nolus-home-dir)
    NOLUS_HOME_DIR="$2"
    shift
    shift
    ;;

  --account-key-to-feed-hermes-address)
    ACCOUNT_KEY_TO_FEED_HERMES_ADDRESS="$2"
    shift
    shift
    ;;

  --hermes-config-dir-path)
    HERMES_CONFIG_DIR_PATH="$2"
    shift
    shift
    ;;

  --hermes-binary-dir-path)
    HERMES_BINARY_DIR_PATH="$2"
    shift
    shift
    ;;

  --dex-chain-id)
    CHAIN_ID="$2"
    shift
    shift
    ;;

  --dex-ip-addr-rpc-host)
    CHAIN_IP_ADDR_RPC="$2"
    shift
    shift
    ;;

  --dex-ip-addr-grpc-host)
    CHAIN_IP_ADDR_GRPC="$2"
    shift
    shift
    ;;

  --dex-account-prefix)
    CHAIN_ACCOUNT_PREFIX="$2"
    shift
    shift
    ;;

  --dex-price-denom)
    CHAIN_PRICE_DENOM="$2"
    shift
    shift
    ;;

  --dex-trusting-period-secs)
    CHAIN_TRUSTING_PERIOD="$2"
    shift
    shift
    ;;

  *)
    echo >&2 "The provided option '$key' is not recognized"
    exit 1
    ;;

  esac
done

verify_mandatory "$CHAIN_ID" "new DEX chain_id"
verify_mandatory "$CHAIN_IP_ADDR_RPC" "new DEX RPC addr - fully host part"
verify_mandatory "$CHAIN_IP_ADDR_GRPC" "new DEX gRPC addr - fully host part"
verify_mandatory "$CHAIN_ACCOUNT_PREFIX" "new DEX account prefix"
verify_mandatory "$CHAIN_PRICE_DENOM" "new DEX price  denom"
verify_mandatory "$CHAIN_TRUSTING_PERIOD" "new DEX trusting period"

# Extend the existing Hermes configuration
add_new_chain_hermes "$HERMES_CONFIG_DIR_PATH" "$CHAIN_ID" "$CHAIN_IP_ADDR_RPC" "$CHAIN_IP_ADDR_GRPC" \
    "$CHAIN_ACCOUNT_PREFIX" "$CHAIN_PRICE_DENOM" "$CHAIN_TRUSTING_PERIOD"

# Link the Hermes account to the DEX
dex_account_setup "$HERMES_BINARY_DIR_PATH" "$CHAIN_ID" "$HERMES_CONFIG_DIR_PATH"/hermes.seed

NOLUS_HERMES_ADDRESS=$(get_hermes_address "$HERMES_BINARY_DIR_PATH" "$NOLUS_CHAIN_ID")

# Open a connection
open_connection "$NOLUS_NET" "$NOLUS_HOME_DIR" "$ACCOUNT_KEY_TO_FEED_HERMES_ADDRESS" "$HERMES_BINARY_DIR_PATH" \
    "$NOLUS_HERMES_ADDRESS" "$NOLUS_CHAIN_ID" "$CHAIN_ID"