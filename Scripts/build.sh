XCODE_WORKSPACE=Aztec.xcworkspace
XCODE_PROJECT=Aztec.xcodeproj
XCODE_SCHEME=AztecExample
XCODE_SDK=iphonesimulator

xcodebuild build test \
	-workspace "$XCODE_WORKSPACE" \
	-scheme "$XCODE_SCHEME" \
	-sdk "$XCODE_SDK" \
    -destination "name=iPhone SE" \
	-configuration Debug | xcpretty -c && exit ${PIPESTATUS[0]}

exit ${PIPESTATUS[0]}
