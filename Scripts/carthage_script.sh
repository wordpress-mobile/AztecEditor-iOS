#!/bin/bash
cd "${PROJECT_DIR}/Example"
if [ -d "Carthage/Build/iOS" ]; then
echo "`date +%Y-%m-%d:%H:%M:%S` -- found dependencies" >> script_logs.log
else
carthage update
echo "`date +%Y-%m-%d:%H:%M:%S` -- carthage update" >> script_logs.log
fi
