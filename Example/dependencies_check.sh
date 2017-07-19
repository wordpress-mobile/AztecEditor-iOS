if [ -d "${PROJECT_DIR}/Carthage/Build/iOS" ]; then 
echo \"found dependencies\"
else carthage update
fi
exit