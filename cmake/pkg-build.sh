#!/usr/bin/env bash
# 通用：autotools 上游 → <out>/pkg/prefix（两侧各编一份，互不污染）
set -euo pipefail
SRC=$1
OUT=$2
EXTRA=${EXTRA_CONFIGURE_ARGS:-}
MARCH=${3:-rv64gc}
KERN=${4:-0}
if [ "$KERN" = "1" ]; then
  export CFLAGS="-O2 -march=${MARCH} -DRVV_KERNELS=1"
fi
mkdir -p "$OUT/pkg"
rm -rf "$OUT/pkg/src"
cp -R "$SRC" "$OUT/pkg/src"
cd "$OUT/pkg/src"
if [ ! -f configure ]; then
  if [ -f .bootstrap ]; then sh .bootstrap > "$OUT/pkg/bootstrap.log" 2>&1 || { tail -25 "$OUT/pkg/bootstrap.log"; exit 1; }
  elif [ -f autogen.sh ]; then sh autogen.sh > "$OUT/pkg/bootstrap.log" 2>&1 || { tail -25 "$OUT/pkg/bootstrap.log"; exit 1; }
  elif [ -f configure.ac ] || [ -f configure.in ]; then autoreconf -fi > "$OUT/pkg/bootstrap.log" 2>&1 || { tail -25 "$OUT/pkg/bootstrap.log"; exit 1; }
  fi
fi
./configure --prefix="$OUT/pkg/prefix" --disable-shared --enable-static $EXTRA \
  > "$OUT/pkg/configure.log" 2>&1 || { tail -25 "$OUT/pkg/configure.log"; exit 1; }
make -j"$(nproc)" > "$OUT/pkg/build.log" 2>&1 || { tail -25 "$OUT/pkg/build.log"; exit 1; }
make install > "$OUT/pkg/install.log" 2>&1 || { tail -10 "$OUT/pkg/install.log"; exit 1; }
