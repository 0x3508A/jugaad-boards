#!/usr/bin/env bash
# Direct build script for 'jugaad_samd_ard' build

set -e
set +x
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BUILD_NAME='jugaad_samd_ard'
PACKAGE_TEMPLATE='jugaad_samd_ard.txt'
PACKAGE_INDEX=0
PACKAGE_NAME='package_jugaad-boards_index.json'
PACKAGE_FILE="${SCRIPT_DIR}/../${PACKAGE_NAME}"
MIXIN_DIR="mixin"
# Internal Vars
FORCE_CLEANUP=0

# Set Dummy Tag name
if [[ ! -v TAG_NAME ]]; then 
	TAG_NAME="$(date +"%Y%m%d.%H.%M")"
fi
BUILD="${BUILD_NAME}-${TAG_NAME}"
ARCIVE_NAME_FILE="${BUILD}/extras/ARCHIVE.txt"
BUILD_VERSION_FILE="${BUILD}/BUILD-VERSION.txt"
PACKAGE_STAGING="package_${BUILD_NAME}_index.json"

# Print all variables
echo
echo " -- Environment Variables"
echo
echo "    PWD                 =${PWD}"
echo "    SCRIPT_DIR          =${SCRIPT_DIR}"
echo "    BUILD               =${BUILD}"
echo "    PACKAGE_INDEX       =${PACKAGE_INDEX}"
echo "    PACKAGE_NAME        =${MIXIN_DIR}"
echo "    PACKAGE_TEMPLATE    =${PACKAGE_TEMPLATE}"
echo "    TAG_NAME            =${TAG_NAME}"
echo "    MIXIN_DIR           =${MIXIN_DIR}"
echo

# Get the Arduino SAMD Core
echo
echo " -- Get the Arduino SAMD Core"
echo
if [ $FORCE_CLEANUP -eq 1 ];then
	echo
	echo "   --- Perform Cleanup of old Directory"
	echo
	rm -rf ArduinoCore-samd
fi
if [ ! -e ArduinoCore-samd ]; then
	echo
	echo "   --- Get the SAMD repository First"
	echo
	git clone --depth 1 https://github.com/arduino/ArduinoCore-samd.git
	pushd ArduinoCore-samd
	echo
	echo "   --- Get SAMD repository Tags"
	echo
	git fetch --tags
	CORE_VERSION="$(git describe --tags "$(git rev-list --tags --max-count=1)")"
	echo
	echo "   --- Setup SAMD repository to CORE_VERSION=${CORE_VERSION}"
	echo
	git switch -c "$CORE_VERSION"
	echo "$CORE_VERSION" > CORE_VERSION.txt
	echo
	echo "   --- Return back to starting Directory"
	echo
	popd
fi

# Get API Directory
echo
echo " -- Get the Arduino API Core"
echo
if [ $FORCE_CLEANUP -eq 1 ];then
	echo
	echo "   --- Perform Cleanup of old Directory"
	echo
	rm -rf ArduinoCore-samd/cores/arduino/api
fi
if [ ! -e "ArduinoCore-samd/cores/arduino/api" ]; then
	echo
	echo "   --- Get the API repository First"
	echo
	git clone --depth 1 https://github.com/arduino/ArduinoCore-API.git
	pushd ArduinoCore-API
	echo
	echo "   --- Get ArduinoCore-API repository Tags"
	echo
	git fetch --tags
	API_VERSION="$(git describe --tags "$(git rev-list --tags --max-count=1)")"
	echo
	echo "   --- Setup API repository to API_VERSION=${API_VERSION}"
	echo
	git switch -c "$API_VERSION"
	echo "$API_VERSION" > ../ArduinoCore-samd/API_VERSION.txt
	echo
	echo "   --- Copy API directory to correct location"
	echo
	mv api "../ArduinoCore-samd/cores/arduino/"
	echo
	echo "   --- Return back to starting Directory"
	echo
	popd
	echo
	echo "   --- Cleanup API Repository Directory"
	echo
	rm -rf ArduinoCore-API
fi

# Add Mixin
echo
echo " -- Prepare to Mixin"
echo
echo
echo "   --- Create the new ${BUILD} directory"
echo
mkdir "${BUILD}"
echo
echo "   --- Copy the SAMD Core"
echo
cp -arT ArduinoCore-samd "${BUILD}/"
echo
echo "   --- Cleanup Variants and Bootloaders"
echo
rm -rf "${BUILD}/variants/"
rm -rf "${BUILD}/bootloaders/"
rm -rf "${BUILD}/LICENSE"
echo
echo "   --- Copy the Mixin directory"
echo
cp -arT mixin "${BUILD}/"
echo
echo "   --- Recipi is ready to prepare"
echo
ARCHIVE="${BUILD}.tar.bz2"
echo "$ARCHIVE" > "${ARCIVE_NAME_FILE}"
echo "${TAG_NAME}" > "${BUILD_VERSION_FILE}"

# Create the Archive
echo
echo " -- Create the Archive ${ARCHIVE}"
echo
echo
echo "   --- Tar the archive"
echo
tar --exclude=extras/** --exclude=.git* --exclude=.idea \
	-cjf "${ARCHIVE}" "${BUILD}"
echo
echo "   --- Cleanup the Build"
echo
rm -rf "${BUILD}"
echo
echo "   --- Prepare the Sum and Size of the Archive"
echo
CHKSUM=$(sha256sum "${ARCHIVE}" | awk '{ print $1 }')
SIZE=$(wc -c "${ARCHIVE}" | awk '{ print $1 }')
echo
echo "   --- Checksum for ${ARCHIVE} = ${CHKSUM}"
echo "   --- Size for ${ARCHIVE}     = ${SIZE} bytes"
echo

# Create the Temporary Package Template
echo
echo " -- Create the Temporary Package Template"
echo
echo
echo "   --- prepare 'input.json' using ${PACKAGE_TEMPLATE}"
echo
sed "s/%%VERSION%%/${TAG_NAME}/" "${PACKAGE_TEMPLATE}"|
sed "s/%%FILENAME%%/${ARCHIVE}/" |
sed "s/%%CHECKSUM%%/${CHKSUM}/" |
sed "s/%%RELEASE%%/${TAG_NAME}/" |
sed "s/%%SIZE%%/${SIZE}/" > input.json
echo
echo "   --- Create the actual ${PACKAGE_NAME}"
echo
jq -r --argjson inf "$(jq '.packages[0].platforms[0]' input.json)" \
	'.packages[0].platforms += [$inf]' \
	"${PACKAGE_FILE}" | tee "${PACKAGE_NAME}"
# echo
# echo "   --- Create the Staging ${PACKAGE_STAGING}"
# echo
# if [ "$OS" == "Windows_NT" ];then
# NEW_URL="file://$(realpath "${PWD}/../artifacts" | sed 's/^\/\(.\)/\/\1:/' | cut -c 2-)/${ARCHIVE}"
# else
# NEW_URL="file:///${PWD}/../artifacts/${ARCHIVE}"
# fi
# echo
# echo "   --- New URL (Staging) = ${NEW_URL}"
# echo
# echo
# echo "   --- Staging File output"
# echo
# jq --argjson inp "\"${NEW_URL}\"" \
# 	'.packages[0].platforms[0].url = $inp' \
# 	input.json | tee "${PACKAGE_STAGING}"
echo
echo "   --- Clean-up the pre-cursor"
echo
rm input.json

# Prepare Artifact
echo
echo " -- Prepare Artifacts"
echo
if [ ! -e "../artifacts" ]; then
	mkdir ../artifacts
fi
echo
echo "   --- Move things to Artifacts folder"
echo
mv ./*.tar.bz2 ../artifacts/
mv ./*.json ../artifacts/
# End
echo
echo
#echo "Press Enter to exit...."
#read