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
# RTSP transport: prefer explicit environment value. If not provided,
# auto-detect: treat addresses in 224.0.0.0/4 as multicast and use
# udp_multicast; otherwise use tcp (unicast-friendly and more reliable
# across NAT/firewalls).
if [ -n "${INPUT_RTSP_TRANSPORT}" ]; then
    : # use provided value
else
    # get first octet of INPUT_RTSP_HOST (if IPv4 dotted-decimal)
    first_octet=$(echo "${INPUT_RTSP_HOST}" | cut -d. -f1 2>/dev/null || echo "")
    if [[ "$first_octet" =~ ^[0-9]+$ ]] && [ "$first_octet" -ge 224 ] && [ "$first_octet" -le 239 ]; then
        INPUT_RTSP_TRANSPORT="udp_multicast"
    else
        INPUT_RTSP_TRANSPORT="tcp"
    fi
fi
OUTPUT_RTSP_TRANSPORT="${OUTPUT_RTSP_TRANSPORT:-tcp}"
LOG_LEVEL="${LOG_LEVEL:-warning}"
# スナップショット設定 (1 秒に 1 枚をデフォルト)
SNAP_FPS="${SNAP_FPS:-1}"
SNAP_DIR="${SNAP_DIR:-/var/www/snapshots}"

echo "Configuration:"
echo "  Input RTSP: $INPUT_RTSP_URL"
echo "  Output RTSP: $OUTPUT_RTSP_URL"
echo "  Buffer Size: $BUFFER_SIZE"
echo "  Max Delay: $MAX_DELAY"
echo "  Thread Queue Size: $THREAD_QUEUE_SIZE"
echo "  Snapshot dir: $SNAP_DIR (fps=$SNAP_FPS)"

sleep 15

# スナップショット用ディレクトリを作成し、バックグラウンドで簡易スナップショットを生成
mkdir -p "$SNAP_DIR"


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
    "$OUTPUT_RTSP_URL" \
    -vf "fps=$SNAP_FPS" \
    -update 1 -y "$SNAP_DIR/$OUTPUT_RTSP_PATH.jpg"



