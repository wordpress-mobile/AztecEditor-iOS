#!/bin/bash -eu

PODSPEC_PATH="WordPress-Aztec-iOS.podspec"
SPECS_REPO="git@github.com:wordpress-mobile/cocoapods-specs.git"
SLACK_WEBHOOK=$PODS_SLACK_WEBHOOK

echo "--- :rubygems: Setting up Gems"
# See https://github.com/Automattic/bash-cache-buildkite-plugin/issues/16
gem install bundler:2.3.4

install_gems

echo "--- :cocoapods: Publishing Pod to CocoaPods CDN"
publish_pod $PODSPEC_PATH

echo "--- :cocoapods: Publishing Pod to WP Specs Repo"
publish_private_pod $PODSPEC_PATH $SPECS_REPO "$SPEC_REPO_PUBLIC_DEPLOY_KEY"

echo "--- :slack: Notifying Slack"
slack_notify_pod_published $PODSPEC_PATH $SLACK_WEBHOOK
