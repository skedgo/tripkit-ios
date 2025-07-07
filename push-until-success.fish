#!/usr/bin/env fish

function usage
    echo "Usage: push-until-success.fish <podspec file>"
    return 1
end

if test (count $argv) -ne 1
    usage
    exit 1
end

set podspec $argv[1]

if not test -f $podspec
    echo "Error: '$podspec' not found."
    exit 1
end

echo "📦 Attempting to push $podspec until successful..."

while not pod trunk push $podspec
    echo "❌ Push failed for $podspec. Retrying in 60 seconds..."
    sleep 60
end

echo "✅ Push succeeded for $podspec!"
afplay -v 10 /System/Library/Sounds/Glass.aiff