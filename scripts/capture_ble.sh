#!/usr/bin/env bash
set -euo pipefail
OUT_DIR=${1:-"../captures"}
mkdir -p "$OUT_DIR"
TS=$(date +"%Y%m%d_%H%M%S")
FILE="$OUT_DIR/btmon_${TS}.log"
echo "[btmon] escribiendo en $FILE"
# Requiere permisos de usuario para btmon (no root)
btmon | tee "$FILE"
