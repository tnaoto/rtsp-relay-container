#!/bin/bash
set -e

echo "=== FFmpeg RTSP Relay with Environment Configuration ==="

# 環境変数の検証
required_vars=(
    "INPUT_RTSP_HOST"
    "INPUT_RTSP_PORT" 
    "INPUT_RTSP_PATH"
    "OUTPUT_RTSP_HOST"
    "OUTPUT_RTSP_PORT"
    "OUTPUT_RTSP_PATH"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required environment variable $var is not set"
        exit 1
    fi
done

# RTSP URL構築
INPUT_RTSP_URL="rtsp://${INPUT_RTSP_HOST}:${INPUT_RTSP_PORT}/${INPUT_RTSP_PATH}"
OUTPUT_RTSP_URL="rtsp://${OUTPUT_RTSP_HOST}:${OUTPUT_RTSP_PORT}/${OUTPUT_RTSP_PATH}"

# デフォルト値の設定
BUFFER_SIZE="${BUFFER_SIZE:-256M}"
MAX_DELAY="${MAX_DELAY:-60000000}"
THREAD_QUEUE_SIZE="${THREAD_QUEUE_SIZE:-2048}"
INPUT_RTSP_TRANSPORT="${INPUT_RTSP_TRANSPORT:-udp_multicast}"
OUTPUT_RTSP_TRANSPORT="${OUTPUT_RTSP_TRANSPORT:-tcp}"
LOG_LEVEL="${LOG_LEVEL:-warning}"

echo "Configuration:"
echo "  Input RTSP: $INPUT_RTSP_URL"
echo "  Output RTSP: $OUTPUT_RTSP_URL"
echo "  Buffer Size: $BUFFER_SIZE"
echo "  Max Delay: $MAX_DELAY"
echo "  Thread Queue Size: $THREAD_QUEUE_SIZE"

sleep 15

echo "Starting FFmpeg relay..."
exec ffmpeg -hide_banner -loglevel "$LOG_LEVEL" \
    -thread_queue_size "$THREAD_QUEUE_SIZE" \
    -rtsp_transport "$INPUT_RTSP_TRANSPORT" \
    -buffer_size "$BUFFER_SIZE" \
    -max_delay "$MAX_DELAY" \
    -reorder_queue_size "${REORDER_QUEUE_SIZE:-2000}" \
    -fflags +genpts+igndts+flush_packets \
    -avoid_negative_ts make_zero \
    -probesize "${PROBE_SIZE:-64M}" \
    -analyzeduration "${ANALYZE_DURATION:-20M}" \
    -an \
    -i "$INPUT_RTSP_URL" \
    -c copy \
    -copyts \
    -start_at_zero \
    -max_interleave_delta 2000000 \
    -f rtsp \
    -rtsp_transport "$OUTPUT_RTSP_TRANSPORT" \
    "$OUTPUT_RTSP_URL"