#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}========================================="
echo -e "        🚀 Starting Auto Install Node 0g        "
echo -e "=========================================${NC}"
sleep 2

log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local border="-----------------------------------------------------"

    echo -e "${border}"
    case $level in
        "INFO") echo -e "${CYAN}[INFO] ${timestamp} - ${message}${NC}" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS] ${timestamp} - ${message}${NC}" ;;
        "ERROR") echo -e "${RED}[ERROR] ${timestamp} - ${message}${NC}" ;;
        *) echo -e "${YELLOW}[UNKNOWN] ${timestamp} - ${message}${NC}" ;;
    esac
    echo -e "${border}\n"
}

common() {
    local duration=$1
    local message=$2
    local end=$((SECONDS + duration))
    local spinner="⣷⣯⣟⡿⣿⡿⣟⣯⣷"

    echo -n -e "${YELLOW}${message}...${NC} "
    while [ $SECONDS -lt $end ]; do
        printf "\b${spinner:$((SECONDS % ${#spinner})):1}"
        sleep 0.1
    done
    printf "\r${GREEN}✔ Done!${NC} \n"
}

log "INFO" "🔄 Cloning DA-Client repository"
if [ ! -d "0g-da-client" ]; then
    git clone https://github.com/0glabs/0g-da-client.git
else
    log "INFO" "📁 Repository exists. Pulling latest changes."
    cd 0g-da-client && git pull && cd ..
fi

log "INFO" "🐳 Building Docker Image"
cd 0g-da-client
if ! docker image inspect 0g-da-client &> /dev/null; then
    docker build -t 0g-da-client -f combined.Dockerfile .
else
    log "SUCCESS" "✅ Docker image already built."
fi

log "INFO" "🔑 Input Private Key"
read -p "Enter your private key: " PRIVATE_KEY
PRIVATE_KEY=${PRIVATE_KEY#0x}

if [[ ! $PRIVATE_KEY =~ ^[a-fA-F0-9]{64}$ ]]; then
    log "ERROR" "❌ Invalid private key format. Please enter a valid 64-character hex key."
    exit 1
fi

cat <<EOF > envfile.env
COMBINED_SERVER_CHAIN_RPC=https://evmrpc-testnet.0g.ai
COMBINED_SERVER_PRIVATE_KEY=$PRIVATE_KEY
ENTRANCE_CONTRACT_ADDR=0x857C0A28A8634614BB2C96039Cf4a20AFF709Aa9
COMBINED_SERVER_RECEIPT_POLLING_ROUNDS=180
COMBINED_SERVER_RECEIPT_POLLING_INTERVAL=1s
COMBINED_SERVER_TX_GAS_LIMIT=2000000
COMBINED_SERVER_USE_MEMORY_DB=true
COMBINED_SERVER_KV_DB_PATH=/runtime/
COMBINED_SERVER_TimeToExpire=2592000
DISPERSER_SERVER_GRPC_PORT=51001
BATCHER_DASIGNERS_CONTRACT_ADDRESS=0x0000000000000000000000000000000000001000
BATCHER_FINALIZER_INTERVAL=20s
BATCHER_CONFIRMER_NUM=3
BATCHER_MAX_NUM_RETRIES_PER_BLOB=3
BATCHER_FINALIZED_BLOCK_COUNT=50
BATCHER_BATCH_SIZE_LIMIT=500
BATCHER_ENCODING_INTERVAL=3s
BATCHER_ENCODING_REQUEST_QUEUE_SIZE=1
BATCHER_PULL_INTERVAL=10s
BATCHER_SIGNING_INTERVAL=3s
BATCHER_SIGNED_PULL_INTERVAL=20s
BATCHER_EXPIRATION_POLL_INTERVAL=3600
BATCHER_ENCODER_ADDRESS=DA_ENCODER_SERVER
BATCHER_ENCODING_TIMEOUT=300s
BATCHER_SIGNING_TIMEOUT=60s
BATCHER_CHAIN_READ_TIMEOUT=12s
BATCHER_CHAIN_WRITE_TIMEOUT=13s
EOF

log "INFO" "🚀 Starting Node"
docker run -d --env-file envfile.env --name 0g-da-client -v $(pwd)/run:/runtime -p 51001:51001 0g-da-client combined

log "SUCCESS" "🎉 0g-da-client node has been successfully installed and started."
log "SUCCESS" "💡 To view logs, use the following command:"
echo -e "${YELLOW}docker logs -f 0g-da-client${NC}"

log "SUCCESS" "✅ Installation Complete! Happy Node Running! 🎊"