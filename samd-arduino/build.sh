#!/usr/bin/env bash
# Direct build script for 'jugaad_samd_ard' build

set -e
set +x
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export BUILD='jugaad_samd_ard'
export PACKAGE_TEMPLATE='jugaad_samd_ard.txt'
export PACKAGE_INDEX=0
export PACKAGE_NAME="${SCRIPT_DIR}/../package_jugaad-boards_index.json"
export MIXIN_DIR="${SCRIPT_DIR}/mixin"
# Internal Vars
FORCE_CLEANUP=1

# Set Dummy Tag name
if [[ ! -v TAG_NAME ]]; then 
	TAG_NAME="$(date +"%Y%m%d.%H.%M")"
fi

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