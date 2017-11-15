if [ ! $TRAVIS ]; then
	TRAVIS_XCODE_WORKSPACE=Aztec.xcworkspace
	TRAVIS_XCODE_PROJECT=Aztec.xcodeproj
	TRAVIS_XCODE_SCHEME=AztecExample
    TRAVIS_XCODE_SDK=iphonesimulator
fi

xcrun simctl erase all && xcodebuild build test \
	-workspace "$TRAVIS_XCODE_WORKSPACE" \
	-scheme "$TRAVIS_XCODE_SCHEME" \
	-sdk "$TRAVIS_XCODE_SDK" \
    -destination "name=iPhone SE" \
	-configuration Debug | xcpretty -c && exit ${PIPESTATUS[0]}




	
