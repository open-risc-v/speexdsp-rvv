#!/usr/bin/env bash
# speexdsp 真实包用例：回声消除 + 预处理全流程（整数 FIR / 自适应滤波 / VAD）。
set -euo pipefail
: "${STAGE:=run}" "${SIDE:=A}" "${BIN:=build/native}" "${DATA:=build/ab-data}" "${OUT:=build/ab-data/out}"
mkdir -p "$DATA" "$OUT"
case "$STAGE" in
  gen) : > "$DATA/speexdsp.ready" ;;
  run)
    H=""
    for c in "$BIN/speexdsp_harness" "$BIN/tools/speexdsp_harness"; do
      [ -x "$c" ] && H="$c" && break
    done
    if [ -z "$H" ]; then echo "缺少 speexdsp_harness（该侧未构建）" >&2; exit 1; fi
    ${RUNNER:-} "$H" "$OUT/echo.pcm"
    ;;
esac
