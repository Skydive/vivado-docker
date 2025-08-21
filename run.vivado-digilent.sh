#!/usr/bin/env bash
# Copyright 2023 Google. All rights reserved.
#
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# A script that runs the graphical vivado tool from within the built container.

set -euo pipefail
set -x

INTERACTIVE=""
if sh -c ": >/dev/tty" >/dev/null 2>/dev/null; then
	# Only add these if running on actual terminal.
	INTERACTIVE="--interactive --tty"
fi

VIVADO_VERSION="2025.1"

readonly VIVADO_PATH="/opt/Xilinx/${VIVADO_VERSION}/Vivado"

: "${DISPLAY:=:0}"

XAUTH_DOCKER="${PWD}/.docker.xauth"
touch "${XAUTH_DOCKER}"
chmod 600 "${XAUTH_DOCKER}"

# Extract your X11 cookie and write to a file the container can read
xauth nlist "${DISPLAY}" | sed -e 's/^..../ffff/' | xauth -f "${XAUTH_DOCKER}" nmerge -

# Useful with some Java apps on tiling WMs
export _JAVA_AWT_WM_NONREPARENTING=1

docker run \
  ${INTERACTIVE} \
  -u $(id -u):$(id -g) \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  -v "${PWD}:/work:rw" \
  -v "${XAUTH_DOCKER}:/tmp/.docker.xauth:ro" \
  -e DISPLAY="${DISPLAY}" \
  -e XAUTHORITY="/tmp/.docker.xauth" \
  -e HOME="/work" \
  -e JAVA_TOOL_OPTIONS="-Dswing.defaultlaf=javax.swing.plaf.metal.MetalLookAndFeel" \
  -e GDK_BACKEND=x11 \
  -e SWT_GTK3=0 \
  -v /dev/dri:/dev/dri \
  -v /run/opengl-driver:/run/opengl-driver:ro \
  -v /run/opengl-driver-32:/run/opengl-driver-32:ro \
  --net=host \
  --device /dev/dri \
  --device /dev/bus/usb/003/010 \
  xilinx-vivado:${VIVADO_VERSION}-digilent \
  /bin/bash -c \
    "env \
      _JAVA_AWT_WM_NONREPARENTING=1 AWT_TOOLKIT=MToolkit \
      _JAVA_OPTIONS='-Dsun.java2d.opengl=true' \
      LD_LIBRARY_PATH=${VIVADO_PATH}/lib/lnx64.o \
      ${VIVADO_PATH}/bin/setEnvAndRunCmd.sh vivado \
    "

