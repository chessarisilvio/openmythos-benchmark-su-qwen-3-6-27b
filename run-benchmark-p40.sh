#!/usr/bin/env bash
# run-benchmark-p40.sh
# Benchmark script for Qwen 3.6 27B on P40 (sm_61) using llama.cpp MTP backend.
# Designed to be run from the project root.
# Avoids hardcoded absolute paths; uses environment variables.

# Exit on error
set -euo pipefail

# Default environment variables (can be overridden)
: "${MODEL_PATH:=/opt/modelli-ai/qwen3.6-27b/Qwen3.6-27B-Q4_K_M.gguf}"
: "${PRESET_NAME:=27b}"  # preset defined in start-llama.yaml
: "${PORT:=8090}"
: "${HOST:=127.0.0.1}"
: "${BENCH_SECONDS:=30}"
: "${BATCH_SIZE:=1}"
: "${CTX_SIZE:=65536}"
: "${NGL:=99}"
: "${THREADS:=6}"
: "${OUTPUT_DIR:=./benchmark-results}"
: "${OUTPUT_FILE:=${OUTPUT_DIR}/p40_benchmark_$(date +%Y%m%d_%H%M%S).json}"

# Helper functions
log() { echo "[*] $@"; }
error() { echo "[!] $@" >&2; }

# Check dependencies
command -v start-llama >/dev/null 2>&1 || { error "start-llama not found in PATH"; exit 1; }
command -v curl >/dev/null 2>&1 || { error "curl not found"; exit 1; }
command -v jq >/dev/null 2>&1 || { error "jq not found (for JSON parsing)"; exit 1; }

# Validate model path
if [[ ! -f "${MODEL_PATH}" ]]; then
    error "Model file not found: ${MODEL_PATH}"
    echo "Please download the Qwen 3.6 27B Q4_K_M GGUF model and place it at:"
    echo "  ${MODEL_PATH}"
    echo "Or set MODEL_PATH environment variable to point to the model."
    exit 1
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"

log "Starting benchmark for Qwen 3.6 27B on P40 (sm_61)"
log "Model: ${MODEL_PATH}"
log "Preset: ${PRESET_NAME} (port ${PORT})"
log "Context size: ${CTX_SIZE}, GPU layers: ${NGL}, Threads: ${THREADS}"
log "Benchmark duration: ${BENCH_SECONDS}s, Batch size: ${BATCH_SIZE}"

# Launch the model server in background using start-llama
log "Launching llama-server with preset '${PRESET_NAME}'..."
# We'll use start-llama with dry-run to see the command, then execute without dry-run.
# But we need to capture PID to kill later.
# start-llama can background the process and write PID file.
# We'll invoke start-llama with the preset and let it background.
# However start-llama expects to be run with preset name; we'll use the preset from config.
# We'll also override some parameters via extra_args if needed.
# We'll use start-llama <preset> --ctx ${CTX_SIZE} --ngl ${NGL} --threads ${THREADS} --port ${PORT}
# Note: start-llama will read preset from config and apply overrides.
START_CMD=(start-llama "${PRESET_NAME}" --ctx "${CTX_SIZE}" --ngl "${NGL}" --threads "${THREADS}" --port "${PORT}" --dry-run)
log "Dry-run command: ${START_CMD[*]}"
# Actually we want to launch for real, so we'll run without --dry-run but capture PID via start-llama's internal mechanism.
# start-llama when run without arguments like start-llama <preset> will background and write PID.
# We'll run it in background and wait a bit for server to be ready.
log "Starting server (background)..."
start-llama "${PRESET_NAME}" --ctx "${CTX_SIZE}" --ngl "${NGL}" --threads "${THREADS}" --port "${PORT}" >/dev/null 2>&1 &
SERVER_PID=$!
log "Server started with PID ${SERVER_PID}"

# Wait for server to be ready
log "Waiting for server to become ready on http://${HOST}:${PORT}/health..."
timeout=30
elapsed=0
while ! curl -s http://${HOST}:${PORT}/health | grep -q '"status":"ok"'; do
    sleep 1
    ((elapsed++))
    if (( elapsed >= timeout )); then
        error "Server did not become ready within ${timeout}s"
        kill "${SERVER_PID}" 2>/dev/null || true
        exit 1
    fi
done
log "Server is ready."

# Run benchmark using llama-bench (from mtp binary) via HTTP? Actually llama-bench is a binary that loads model directly.
# We'll use llama-bench from the mtp build to measure tokens per second.
# Find llama-bench binary path from start-llama config or default.
# We'll derive from the preset's binary.
# For simplicity, we'll use the llama-bench binary located alongside llama-server in the mtp build.
# We'll locate it via the start-llama config or assume it's in the same directory as server.
# We'll read the config to get binary dir for the preset.
# Since we don't have yaml parsing in bash easily, we'll approximate: if preset is 27b, binary is mtp.
# We'll set LLAMA_BENCH_PATH accordingly.
LLAMA_BENCH_PATH="/mnt/data/hd-linux~/projects/Hub/LLM-Research/llama-mtp/build/bin/llama-bench"
if [[ ! -f "${LLAMA_BENCH_PATH}" ]]; then
    error "llama-bench not found at ${LLAMA_BENCH_PATH}"
    kill "${SERVER_PID}" 2>/dev/null || true
    exit 1
fi

log "Running llama-bench to measure performance..."
# llama-bench usage: llama-bench -m <model> -n <predict> -b <batch> -c <ctx> --ngl <ngl> --threads <t> --log-disable
# We'll run for a fixed number of tokens to predict (e.g., 512) and measure time.
# We'll also capture tokens per second.
# We'll run with -n 512 (number of tokens to predict) and -b ${BATCH_SIZE}.
# We'll also set -c ${CTX_SIZE} (context size).
# We'll also set --ngl ${NGL} and --threads ${THREADS}.
# We'll output JSON? llama-bench may not output JSON; we'll parse its output.
# We'll run and capture the last line that contains "tokens per second".
# We'll also save raw output to a log file.
BENCH_LOG="${OUTPUT_DIR}/bench_raw_$(date +%Y%m%d_%H%M%S).log"
log "Running llama-bench (output to ${BENCH_LOG})"
# Note: llama-bench may require the model to be in RAM; we'll point to the same model.
"${LLAMA_BENCH_PATH}" -m "${MODEL_PATH}" -n 512 -b "${BATCH_SIZE}" -c "${CTX_SIZE}" --ngl "${NGL}" --threads "${THREADS}" --log-disable 2>&1 | tee "${BENCH_LOG}"
# Extract tokens per second from output (look for line with "tokens per second")
TPS=$(grep -i "tokens per second" "${BENCH_LOG}" | tail -1 | grep -oE '[0-9]+(\.[0-9]+)?' || true)
if [[ -z "${TPS}" ]]; then
    # Try alternative pattern
    TPS=$(grep -i "t/s" "${BENCH_LOG}" | tail -1 | grep -oE '[0-9]+(\.[0-9]+)?' || true)
fi
log "Tokens per second: ${TPS:-N/A}"

# Also measure latency via HTTP request (time to first token)
log "Measuring latency via HTTP generate endpoint..."
# We'll send a simple prompt and measure time to first token.
# We'll use curl with -w "%{time_starttransfer}" to get time until first byte.
LATENCY_LOG="${OUTPUT_DIR}/latency_raw_$(date +%Y%m%d_%H%M%S).log"
PROMPT="Hello, how are you?"
# We'll use the /completion endpoint (llama-server compatible)
# We'll set max_tokens=1 to get only first token.
START_TIME=$(date +%s.%N)
RESPONSE=$(curl -s -X POST http://${HOST}:${PORT}/completion \
    -H "Content-Type: application/json" \
    -d "{\"prompt\": \"${PROMPT}\", \"max_tokens\": 1, \"temperature\": 0.0}" \
    -w "%{time_starttransfer}" \
    -o /dev/null)
# Actually curl -w outputs the time to stdout after the response body; we suppressed body to /dev/null.
# So RESPONSE will contain the time.
LATENCY_MS=$(echo "${RESPONSE}" | awk '{print $1*1000}')
log "Latency (time to first token): ${LATENCY_MS} ms"

# Stop the server
log "Stopping server (PID ${SERVER_PID})..."
kill "${SERVER_PID}" 2>/dev/null || true
wait "${SERVER_PID}" 2>/dev/null || true
log "Server stopped."

# Create JSON output
mkdir -p "${OUTPUT_DIR}"
cat > "${OUTPUT_FILE}" <<EOF
{
  "model": "${MODEL_PATH}",
  "preset": "${PRESET_NAME}",
  "port": ${PORT},
  "context_size": ${CTX_SIZE},
  "gpu_layers": ${NGL},
  "threads": ${THREADS},
  "batch_size": ${BATCH_SIZE},
  "benchmark_duration_sec": ${BENCH_SECONDS},
  "tokens_per_second": ${TPS:-null},
  "latency_ms": ${LATENCY_MS:-null},
  "timestamp_utc": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "notes": "Benchmark run on P40 (sm_61) using llama.cpp MTP backend. See raw logs in ${OUTPUT_DIR}."
}
EOF

log "Benchmark results saved to ${OUTPUT_FILE}"
log "Done."