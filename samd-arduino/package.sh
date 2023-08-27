#!/usr/bin/env bash

# Copyright (c) 2023 Abhijit Bose - All Rights Reserved
# This work is licensed under the 
# Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
#
# To view a copy of this license, 
# visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or 
# send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
#
# SPDX: CC-BY-NC-ND-4.0
#
# You should have received a copy of the Creative Commons
# Attribution-NonCommercial-NoDerivatives 4.0 International License
# along with this Package; if not, write to the Creative Commons, PO Box 1866, 
# Mountain View, CA 94042, USA.

# Set the evironment variable TESTING='true'
# To enable Upload to 0x0.st service.

set -e
set +x
# Initial Var
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BUILD_NAME='0x3508-JugaadSamdArd'
TEMPLATE='samd-arduino.json'
PACKAGE_NAME='package_0x3508a_index.json'
INTERJSON="${TEMPLATE}.temp.json"
VERSION="$(<"${SCRIPT_DIR}"/version.txt)"
BUILD="${BUILD_NAME}-${VERSION}"
ARCHIVE_NAME="${BUILD}.tar.bz2"
ARCHIVE_PATH="https://github.com/0x3508A/jugaad-boards/raw/main/"
# Indicate Change due to Testing now Enableded
if [ "$TESTING" == "true" ];then
ARCHIVE_PATH="https://github.com/0x3508A/jugaad-boards/raw/testing/samd-arduino/"
fi
ARCHIVE_URL="${ARCHIVE_PATH}${ARCHIVE_NAME}"
# Internal Vars
FORCE_CLEANUP='true'

# Actual Build Output Tags
PACKAGE_FILE="${SCRIPT_DIR}/../${PACKAGE_NAME}"
TEMPLATE_FILE="${SCRIPT_DIR}/${TEMPLATE}"
INTERJSON_FILE="${SCRIPT_DIR}/${INTERJSON}"
OUTPUT_FILE="${SCRIPT_DIR}/${PACKAGE_NAME}"
MIXIN_DIR="${SCRIPT_DIR}/mixin"
BUILD_DIR="${SCRIPT_DIR}/${BUILD}"
ARCHIVE_FILE="${SCRIPT_DIR}/${ARCHIVE_NAME}"

# Functions
printenv() {
	echo " -- Environment Variables"
	echo
	echo "    PWD            = ${PWD}"
	echo "    SCRIPT_DIR     = ${SCRIPT_DIR}"
	echo "    BUILD          = ${BUILD}"
	echo "    PACKAGE_FILE   = ${PACKAGE_FILE}"
	echo "    TEMPLATE_FILE  = ${TEMPLATE_FILE}"
	echo "    INTERJSON_FILE = ${INTERJSON_FILE}"
	echo "    OUTPUT_FILE    = ${OUTPUT_FILE}"
	echo "    MIXIN_DIR      = ${MIXIN_DIR}"
	echo "    BUILD_DIR      = ${BUILD_DIR}"
	echo "    ARCHIVE_FILE   = ${ARCHIVE_FILE}"
	echo "    ARCHIVE_URL    = ${ARCHIVE_URL}"
	echo "    TESTING        = ${TESTING}"
	echo "    FORCE_CLEANUP  = ${FORCE_CLEANUP}"
	echo
}
endofline() {
	popd
	echo
	echo " Done! "
	echo
}
errorend() {
	popd
	echo
	echo " Terminated due to ERROR: "
	echo "$1"
	echo
	exit "$2"
}
getsamdcore() {
	# Cleanup
	if [ -e "${BUILD_DIR}" ]; then
		rm -rf "${BUILD_DIR}"
	fi
	echo
	git clone --depth 1 https://github.com/arduino/ArduinoCore-samd.git "${BUILD_DIR}"
	echo
	pushd "${BUILD_DIR}"
	echo
	git fetch --tags
	echo
	CORE_VERSION="$(git describe --tags "$(git rev-list --tags --max-count=1)")"
	git switch -c "$CORE_VERSION"
	echo	
	echo " -- CORE_VERSION = ${CORE_VERSION}"
	echo "${CORE_VERSION}" >> "CORE_VERSION.txt"	
	echo
	rm -rf .git .github LICENSE variants bootloaders drivers post_install.bat
	cp "${SCRIPT_DIR}/../LICENSE.txt" .
	echo "${BUILD}" > "BUILD_VERSION.txt"
	popd
	echo
}
addapicore() {
	echo
	git clone --depth 1 https://github.com/arduino/ArduinoCore-API.git "${BUILD_DIR}/extras/ArduinoCore-API"
	echo
	pushd "${BUILD_DIR}/extras/ArduinoCore-API"
	echo
	git fetch --tags
	echo
	API_VERSION="$(git describe --tags "$(git rev-list --tags --max-count=1)")"
	git switch -c "$API_VERSION"
	echo
	echo " -- API_VERSION = ${API_VERSION}"
	echo "${API_VERSION}" >> "${BUILD_DIR}/API_VERSION.txt"	
	echo
	mv api ../../cores/arduino/
	echo
	popd
	echo
	rm -rf "${BUILD_DIR}/extras/ArduinoCore-API"	
}
domixing() {
	echo
	cp -arT mixin "${BUILD_DIR}/"
	echo
}
createArchive() {
	if [ -e "${ARCHIVE_NAME}" ]; then
		rm -rf "${ARCHIVE_NAME}"
	fi
	tar --exclude=extras/** --exclude=.git* --exclude=.idea \
		-cjf "${ARCHIVE_NAME}" "${BUILD}"
	echo
	echo " -- ARCHIVE = ${ARCHIVE_FILE}"
	echo
}
createinterjson() {
	if [ -e "${INTERJSON_FILE}" ]; then
		rm -rf "${INTERJSON_FILE}"
	fi
	echo
	CHKSUM=$(sha256sum "${ARCHIVE_FILE}" | awk '{ print $1 }')
	SIZE=$(wc -c "${ARCHIVE_FILE}" | awk '{ print $1 }')
	echo "   --- Checksum for ${ARCHIVE_NAME} = ${CHKSUM}"
	echo "   --- Size for ${ARCHIVE_NAME}     = ${SIZE} bytes"
	echo "   --- Archive URL = ${ARCHIVE_URL}"
	echo
	sed "s/%%VERSION%%/${VERSION}/" <"${TEMPLATE_FILE}"| \
	sed "s/%%FILENAME%%/${ARCHIVE_NAME}/" | \
	sed "s,%%URLRESOURCE%%,${ARCHIVE_URL}," | \
	sed "s/%%CHECKSUM%%/${CHKSUM}/" | \
	sed "s/%%SIZE%%/${SIZE}/" > "${INTERJSON_FILE}" && \
	echo && \
	echo "  --- Created Intermidiate JSON File : ${INTERJSON_FILE}"
	echo
}
createpackagejson() {
	if [ -e "${OUTPUT_FILE}" ]; then
		rm -rf "${OUTPUT_FILE}"
	fi
	echo
	jq -r --argjson inf "$(jq '.' "${INTERJSON_FILE}")" \
	'.packages[0].platforms += [$inf]' \
	"${PACKAGE_FILE}" > "${OUTPUT_FILE}" && \
	echo "  --- Created package JSON File : ${OUTPUT_FILE}"
	echo
}




# Begin Processing
echo
pushd "${SCRIPT_DIR}"
echo
printenv
getsamdcore
addapicore
domixing
createArchive
createinterjson
createpackagejson
endofline

