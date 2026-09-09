#!/bin/bash
###
# Bitwuzla: Satisfiability Modulo Theories (SMT) solver.
#
# Copyright (C) 2026 by the authors listed in the AUTHORS file at
# https://github.com/bitwuzla/bitwuzla/blob/main/AUTHORS
#
# This file is part of Bitwuzla under the MIT license. See COPYING for more
# information at https://github.com/bitwuzla/bitwuzla/blob/main/COPYING
##

# Set up Murxla (https://github.com/murxla/murxla) and fuzz the current code.
#
# Everything lives in build-murxla/: a shared debug build of Bitwuzla installed
# into build-murxla/install and a Murxla checkout built against it. Both are
# only set up if not present, the Bitwuzla library is reinstalled on every run
# so that Murxla always fuzzes the current code.
#
# Usage: contrib/run-murxla.sh [<murxla options>]
#
# Without options Murxla runs in continuous mode with a 5s time limit per test
# run and delta debugs the traces it finds. Error traces are written to the
# current working directory.

set -e -o pipefail

MURXLA_REPO="https://github.com/murxla/murxla.git"

BITWUZLA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$BITWUZLA_DIR/build-murxla}"
INSTALL_DIR="$BUILD_DIR/install"
MURXLA_DIR="$BUILD_DIR/murxla"
MURXLA_BINARY="$MURXLA_DIR/build/bin/murxla"

# Debug build so that assertions and model/unsat core checks are enabled.
if [ ! -f "$BUILD_DIR/build.ninja" ]; then
  echo "-- configuring Bitwuzla in $BUILD_DIR"
  (
    cd "$BITWUZLA_DIR"
    python3 configure.py debug --shared --no-testing \
      --prefix "$INSTALL_DIR" -b "$BUILD_DIR"
  )
  # Keep debug symbols in the installed library, they are stripped by default.
  meson configure "$BUILD_DIR" -Dstrip=false
fi

# Rebuilds first, --only-changed skips copying the (large) unchanged libraries.
echo "-- installing Bitwuzla into $INSTALL_DIR"
meson install -C "$BUILD_DIR" --only-changed

if [ ! -d "$MURXLA_DIR" ]; then
  echo "-- cloning Murxla into $MURXLA_DIR"
  git clone "$MURXLA_REPO" "$MURXLA_DIR"
fi

# Murxla picks up Bitwuzla via install/lib/pkgconfig/bitwuzla.pc and links
# libbitwuzla.so by absolute path, hence it does not have to be rebuilt when
# Bitwuzla changes.
if [ ! -f "$MURXLA_BINARY" ]; then
  echo "-- building Murxla in $MURXLA_DIR/build"
  cmake -S "$MURXLA_DIR" -B "$MURXLA_DIR/build" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="$INSTALL_DIR" \
    -DENABLE_BOOLECTOR=OFF \
    -DENABLE_CVC5=OFF \
    -DENABLE_YICES=OFF
  cmake --build "$MURXLA_DIR/build" -j "$(nproc)"
fi

args=("$@")
if [ ${#args[@]} -eq 0 ]; then
  args=(-t 5 -d)
fi
# Traces already encode the solver, --bitwuzla must not be given on replay.
case " ${args[*]} " in
  *" -u "* | *" --untrace "*) ;;
  *) args=(--bitwuzla "${args[@]}") ;;
esac

echo "-- $MURXLA_BINARY ${args[*]}"
exec "$MURXLA_BINARY" "${args[@]}"
