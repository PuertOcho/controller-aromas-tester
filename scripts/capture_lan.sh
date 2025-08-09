#!/usr/bin/env bash
set -euo pipefail
IFACE=${1:-"$(ip route | awk '/default/ {print $5; exit}')"}
OUT_DIR=${2:-"../captures"}
mkdir -p "$OUT_DIR"
TS=$(date +"%Y%m%d_%H%M%S")
FILE="$OUT_DIR/lan_${IFACE}_${TS}.pcapng"
echo "[tshark] capturando en interfaz $IFACE -> $FILE (Ctrl+C para parar)"
# Captura tráfico relevante local (mDNS/SSDP/UDP/TCP)
tshark -i "$IFACE" -w "$FILE" -f "udp port 5353 or udp port 1900 or tcp or udp" --color
