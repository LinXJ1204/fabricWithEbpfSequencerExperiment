#!/bin/bash

# Define device information
declare -A devices
devices=(
  ["192.168.50.224"]="nsd:nsd"
  ["192.168.50.213"]="nsd:nsd"
  ["192.168.50.230"]="udrt:nsd12345"
  ["192.168.50.239"]="nsd1235:nsd12345"
  ["192.168.50.219"]="nsd12345:nsd12345"
)

# Cleanup step
echo "Initializing cleanup on all devices..."
for device in "${!devices[@]}"; do
  IFS=":" read -r username keyword <<< "${devices[$device]}"
  sshpass -p "$keyword" ssh -o StrictHostKeyChecking=no $username@$device "sudo docker rm -f \$(sudo docker ps -a -q) && sudo docker volume rm \$(sudo docker volume ls -q)"
done

# Setup step
declare -A setup_scripts=(
  ["192.168.50.224"]="mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode/orderer.sh"
  ["192.168.50.213"]="mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode/orderer1.sh"
  ["192.168.50.230"]="mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode/orderer2.sh"
  ["192.168.50.239"]="sudo mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode/orderer3.sh"
  ["192.168.50.219"]="sudo mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode/orderer4.sh"
)

echo "Setting up Orderers..."
for device in "${!setup_scripts[@]}"; do
  IFS=":" read -r username keyword <<< "${devices[$device]}"
  sshpass -p "$keyword" ssh -o StrictHostKeyChecking=no $username@$device "bash ${setup_scripts[$device]}"
done

# Peer setup
echo "Setting up peers..."
sshpass -p "nsd" ssh -o StrictHostKeyChecking=no nsd@192.168.50.224 "bash mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode/peer.sh"
sshpass -p "nsd12345" ssh -o StrictHostKeyChecking=no udrt@192.168.50.230 "bash mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode/peer1.sh"
sshpass -p "nsd12345" ssh -o StrictHostKeyChecking=no udrt@192.168.50.230 "bash mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/bringUpNode/peer2.sh"

# Join channels
join_scripts=(
  "mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel/orderer.sh"
  "mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel/orderer1.sh"
  "mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel/orderer2.sh"
  "mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel/orderer3.sh"
  "mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel/orderer4.sh"
)

echo "Joining channels..."
for i in "${!devices[@]}"; do
  IFS=":" read -r username keyword <<< "${devices[$i]}"
  sshpass -p "$keyword" ssh -o StrictHostKeyChecking=no $username@$i "bash ${join_scripts[$i]}"
done

sleep 10

sshpass -p "nsd" ssh -o StrictHostKeyChecking=no nsd@192.168.50.224 "bash mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel/peer.sh"
sshpass -p "nsd12345" ssh -o StrictHostKeyChecking=no udrt@192.168.50.230 "bash mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel/peer1.sh"
sshpass -p "nsd12345" ssh -o StrictHostKeyChecking=no udrt@192.168.50.230 "bash mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/joinChannel/peer2.sh"

# Install and commit chaincode
echo "Installing chaincode..."
sshpass -p "nsd" ssh -o StrictHostKeyChecking=no nsd@192.168.50.224 "bash mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/CCpackage/peerCCInstall.sh"
sshpass -p "nsd12345" ssh -o StrictHostKeyChecking=no udrt@192.168.50.230 "bash mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/CCpackage/peer1CCInstall.sh"
sshpass -p "nsd12345" ssh -o StrictHostKeyChecking=no udrt@192.168.50.230 "bash mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/CCpackage/peer2CCInstall.sh"

sleep 10

echo "Approving chaincode..."
sshpass -p "nsd" ssh -o StrictHostKeyChecking=no nsd@192.168.50.224 "bash mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/CCpackage/approveCC.sh"

sleep 10

echo "Committing chaincode..."
sshpass -p "nsd" ssh -o StrictHostKeyChecking=no nsd@192.168.50.224 "bash mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/CCpackage/commitCC.sh"

echo "Deployment completed!"
