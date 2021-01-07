#!/bin/bash
cd "${PROJECT_DIR}/Example"
if [ -d "Carthage/Build/iOS" ]; then
	echo "Carthage: found dependencies!"
else
	./carthage.sh update --platform iOS
fi
