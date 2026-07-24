#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
PROJECT_DIR=${SCRIPT_DIR:h}
CONFIGURATION=${CONFIGURATION:-release}
APP_PATH=${1:-"${PROJECT_DIR}/.build/mote.app"}

cd "${PROJECT_DIR}"

export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}

swift build -c "${CONFIGURATION}" --product mote
BIN_DIR=$(swift build -c "${CONFIGURATION}" --show-bin-path)

if [[ -e "${APP_PATH}" ]]; then
    rm -rf "${APP_PATH}"
fi

mkdir -p "${APP_PATH}/Contents/MacOS"
mkdir -p "${APP_PATH}/Contents/Resources"

cp "${BIN_DIR}/mote" "${APP_PATH}/Contents/MacOS/mote"
cp "${PROJECT_DIR}/Resources/Info.plist" "${APP_PATH}/Contents/Info.plist"
cp "${PROJECT_DIR}/Resources/MenuBarIcon.png" "${APP_PATH}/Contents/Resources/MenuBarIcon.png"
cp "${PROJECT_DIR}/Resources/AppIcon.png" "${APP_PATH}/Contents/Resources/AppIcon.png"
cp "${PROJECT_DIR}/Resources/smallseasons.ics" "${APP_PATH}/Contents/Resources/smallseasons.ics"

xattr -cr "${APP_PATH}"
codesign \
    --force \
    --sign - \
    --timestamp=none \
    --requirements '=designated => identifier "com.duncangough.mote"' \
    "${APP_PATH}"
xattr -cr "${APP_PATH}"

echo "${APP_PATH}"
