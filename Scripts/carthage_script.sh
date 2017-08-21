#!/bin/bash
cd "${PROJECT_DIR}/Example"
if [ -d "Carthage/Build/iOS" ]; then
	echo "Carthage: found dependencies!"
else
	carthage update
fi
