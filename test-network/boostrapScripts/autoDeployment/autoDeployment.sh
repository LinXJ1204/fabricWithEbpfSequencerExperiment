#!/usr/bin/env bash

###############################################################################
# Auto-Deployment Script for Multi-Device Hyperledger Fabric Setup
#
# This script performs:
#   1. Docker cleanup (containers + volumes) on all devices
#   2. Sequential execution of the setup scripts on the correct devices
#
# Prerequisites:
#   1. sshpass installed on local machine
#   2. Password-based SSH access to remote devices
#
# Usage:
#   ./auto_deploy.sh
###############################################################################

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Each entry:  DeviceIndex => "IPAddress Username Password"
declare -A DEVICES
DEVICES["0"]="192.168.50.224 nsd nsd" #P_0
DEVICES["1"]="192.168.50.213 nsd nsd" #P_1, P_2
DEVICES["2"]="192.168.50.230 udrt nsd12345" #O_1
DEVICES["5"]="192.168.50.184 nsd02 nsd12345" #seq
DEVICES["3"]="192.168.50.239 nsd1235 nsd12345" #O_0
DEVICES["4"]="192.168.50.219 nsd12345 nsd12345" #O_2
DEVICES["6"]="192.168.50.182 nsd12345 nsd12345" #O_3


# Helper function to run a command over SSH on a specific device
run_cmd_on_device() {
  local device_index=$1
  local cmd=$2

  # Extract connection info
  IFS=' ' read -r ip user pass <<< "${DEVICES[$device_index]}"

  # Execute command via sshpass, ignoring known-hosts prompt
  echo -e "\n>>> [Device $device_index: $ip] Running command: $cmd"
  sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" "$cmd"
}

# -----------------------------------------------------------------------------
# 1. Initialize (Docker Cleanup)
#    Run on all devices:
#      sudo docker rm -f $(sudo docker ps -a -q)
#      sudo docker volume rm $(sudo docker volume ls -q)
# -----------------------------------------------------------------------------

echo "====================="
echo " Step 1: Initialize "
echo "====================="
for i in "${!DEVICES[@]}"; do
  IFS=' ' read -r ip user pass <<< "${DEVICES[$i]}"
  echo -e "\n>>> [Device $i: $ip] Initializing Docker Cleanup..."
  sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" \
    "echo '$pass' | docker rm -f \$(docker ps -a -q) && \
     echo '$pass' | docker volume rm \$(docker volume ls -q)"
done

# -----------------------------------------------------------------------------
# 2. Setup
#
# Order of scripts to run (all paths relative to mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts):
#
#   1. bringUpNode/orderer.sh in Device0
#   2. bringUpNode/orderer1.sh in Device1
#   3. bringUpNode/orderer2.sh in Device2
#   4. sudo bringUpNode/orderer3.sh in Device3
#   5. sudo bringUpNode/orderer4.sh in Device4
#   6. bringUpNode/peer.sh in Device0
#   7. bringUpNode/peer1.sh in Device2
#   8. bringUpNode/peer2.sh in Device2
#   9. joinChannel/orderer.sh in Device0
#   10. joinChannel/orderer1.sh in Device1
#   11. joinChannel/orderer2.sh in Device2
#   12. joinChannel/orderer3.sh in Device3
#   13. joinChannel/orderer4.sh in Device4
#   14. Wait 10 seconds
#   15. joinChannel/peer.sh in Device0
#   16. joinChannel/peer1.sh in Device2
#   17. joinChannel/peer2.sh in Device2
#   18. CCpackage/peerCCInstall.sh in Device0
#   19. CCpackage/peer1CCInstall.sh in Device2
#   20. CCpackage/peer2CCInstall.sh in Device2
#   21. Wait 10 seconds
#   22. CCpackage/approveCC.sh in Device0
#   23. Wait 10 seconds
#   24. CCpackage/commitCC.sh in Device0
#   25. Wait 10 seconds
#
# -----------------------------------------------------------------------------

echo ""
echo "=================="
echo " Step 2: Setup   "
echo "=================="

# 1) bringUpNode/orderer.sh on Device0
run_cmd_on_device 3 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode && ./orderer.sh"

# 2) bringUpNode/orderer1.sh on Device1
run_cmd_on_device 2 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode && ./orderer1.sh"

# 3) bringUpNode/orderer2.sh on Device2
run_cmd_on_device 4 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode && ./orderer2.sh"

# 4) sudo bringUpNode/orderer3.sh on Device3
run_cmd_on_device 6 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode && ./orderer3.sh"

# 5) sudo bringUpNode/orderer4.sh on Device4
#run_cmd_on_device 4 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode && ./orderer4.sh"

# 6) bringUpNode/peer.sh in Device0
run_cmd_on_device 0 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode && ./peer.sh"

# 7) bringUpNode/peer1.sh in Device2
run_cmd_on_device 1 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode && ./peer1.sh"

# 8) bringUpNode/peer2.sh in Device2
run_cmd_on_device 1 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode && ./peer2.sh"

echo -e "\n>>> Waiting 5 seconds..."
sleep 5

# 9) joinChannel/orderer.sh in Device0
run_cmd_on_device 3 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel && export PATH=../../../../bin:$PATH && ./orderer.sh"
sleep 1
# 10) joinChannel/orderer1.sh in Device1
run_cmd_on_device 2 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel && export PATH=../../../bin:$PATH && ./orderer1.sh"
sleep 1
# 11) joinChannel/orderer2.sh in Device2
run_cmd_on_device 4 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel && export PATH=../../../../bin:$PATH && ./orderer2.sh"
sleep 1
# 12) joinChannel/orderer3.sh in Device3
run_cmd_on_device 6 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel && export PATH=../../../../bin:$PATH && ./orderer3.sh"
sleep 1
# 13) joinChannel/orderer4.sh in Device4
#run_cmd_on_device 4 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel && export PATH=../../../../bin:$PATH && ./orderer4.sh"

# 14) Wait 10 seconds
echo -e "\n>>> Waiting 5 seconds..."
sleep 5

# 15) joinChannel/peer.sh in Device0
run_cmd_on_device 0 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel && export PATH=../../../bin:$PATH && ./peer.sh"
sleep 1
# 16) joinChannel/peer1.sh in Device2
run_cmd_on_device 1 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel && export PATH=../../../../bin:$PATH && ./peer1.sh"
sleep 1
# 17) joinChannel/peer2.sh in Device2
run_cmd_on_device 1 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel && export PATH=../../../../bin:$PATH && ./peer2.sh"

echo -e "\n>>> Waiting 5 seconds..."
sleep 5

# 18) CCpackage/peerCCInstall.sh in Device0
run_cmd_on_device 0 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/CCpackage && export PATH=../../../bin:$PATH && ./peerCCInstall.sh"

# 19) CCpackage/peer1CCInstall.sh in Device2
run_cmd_on_device 1 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/CCpackage && export PATH=../../../../bin:$PATH && ./peer1CCInstall.sh"

# 20) CCpackage/peer2CCInstall.sh in Device2
run_cmd_on_device 1 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/CCpackage && export PATH=../../../../bin:$PATH && ./peer2CCInstall.sh"

# 21) Wait 10 seconds
echo -e "\n>>> Waiting 10 seconds..."
sleep 3

# 22) CCpackage/approveCC.sh in Device0
run_cmd_on_device 0 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/CCpackage && export PATH=../../../bin:$PATH && ./approveCC.sh"

# 23) Wait 10 seconds
echo -e "\n>>> Waiting 10 seconds..."
sleep 3

# 24) CCpackage/commitCC.sh in Device0
run_cmd_on_device 0 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/CCpackage && export PATH=../../../bin:$PATH && ./commitCC.sh"

# 25) Wait 10 seconds
echo -e "\n>>> Waiting 10 seconds..."
sleep 5

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo ""
echo "===================================================="
echo " Deployment steps completed successfully!"
echo "===================================================="

run_cmd_on_device 0 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/experiments/initLedger && export GO111MODULE=on && go mod tidy && go run ."

echo ""
echo "===================================================="
echo " Chaincode initialization steps completed successfully!"
echo "===================================================="