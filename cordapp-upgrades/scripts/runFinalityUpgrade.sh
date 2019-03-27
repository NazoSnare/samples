#!/usr/bin/env bash

current_dir="$(pwd)"

echo "Running in ${current_dir}"

function runCommand() {
    echo "Running $1"
    $1 2>&1 | /dev/null
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
}

# Deploy the nodes
runCommand "./gradlew deployNodes"

# Start the nodes in their initial configuration
runCommand "build/nodes/runnodes"

# Issue obligations between all nodes
runCommand "./gradlew rpc-client:issueBetweenNodes"

# Now upgrade the two nodes not on V2 to V2
runCommand "scripts/upgradeNodes.sh ${current_dir} workflows v2-finality-intermediate PartyA PartyB"

# Show that old transactions can still be processed by settling all obligations, then re-issue obligations between nodes
runCommand "./gradlew rpc-client:settleAllObligations"
runCommand "./gradlew rpc-client:issueBetweenNodes"

# Now upgrade some nodes to V3 and perform the same test as above
runCommand "scripts/upgradeNodes.sh ${current_dir} workflows v3-finality-final PartyB PartyC"

runCommand "./gradlew rpc-client:settleAllObligations"
runCommand "./gradlew rpc-client:issueBetweenNodes"