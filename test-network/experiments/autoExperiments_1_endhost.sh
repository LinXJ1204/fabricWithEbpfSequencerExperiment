#!/usr/bin/env bash

###############################################################################
# Experiment Loop Script
# 
# For i in [0..12]:
#   1. Run: cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/experiments/ex1 && go run . 2^i (on Device 0)
#   2. Wait 10 seconds
#   3. Run: cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/experiments/TPSmeasure && go run . (on Device 2)
#   4. Wait 4 minutes
###############################################################################

# -----------------------------------------------------------------------------
# Configuration: define devices (index => "IP Username Password")
# -----------------------------------------------------------------------------
declare -A DEVICES
DEVICES["0"]="192.168.50.224 nsd nsd" #P_0
DEVICES["1"]="192.168.50.213 nsd nsd" #P_1
DEVICES["1"]="192.168.50.213 nsd nsd" #P_2
DEVICES["2"]="192.168.50.230 udrt nsd12345" #O_1
DEVICES["5"]="192.168.50.184 nsd02 nsd12345" #seq
DEVICES["3"]="192.168.50.239 nsd1235 nsd12345" #O_0
DEVICES["4"]="192.168.50.219 nsd12345 nsd12345" #O_2
DEVICES["6"]="192.168.50.182 nsd12345 nsd12345" #O_3

declare -A tc_progarms
tc_progarms["1"]="tc_LRU_1node"
tc_progarms["2"]="tc_LRU_2nodes"
tc_progarms["3"]="tc_LRU_3nodes"
tc_progarms["4"]="tc"
tc_progarms["5"]="tc_LRU_5nodes"

# -----------------------------------------------------------------------------
# Helper function to run a command via SSH on a specific device
# -----------------------------------------------------------------------------
run_cmd_on_device() {
  local device_index=$1
  local cmd=$2

  # Extract connection info from DEVICES array
  IFS=' ' read -r ip user pass <<< "${DEVICES[$device_index]}"

  echo -e "\n>>> [Device $device_index: $ip] Running command: $cmd"
  # -o StrictHostKeyChecking=no disables host key verification
  sshpass -p "$pass" ssh -n -f -o StrictHostKeyChecking=no  "$user@$ip" "$cmd"
}

# -----------------------------------------------------------------------------
# Main experiment loop
# -----------------------------------------------------------------------------
for ((t=1; t<=5; t++))
do
  echo -e "\n============================================="
  echo "Starting Experiment for node count = $t"
  echo "============================================="
  run_cmd_on_device 2 "cd mmainPlan/fabricWithEbpfSequencer/sequencer && export GO111MODULE=on && go mod tidy && nohup go run . $t > t.log 2>&1 &"

  for ((i=6; i<=12; i++))
  do
  echo -e "\n============================================="
  echo "Starting Experiment for node = $i"
  echo "============================================="

  run_cmd_on_device 2 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/experiments/ex2/server && export GO111MODULE=on && go mod tidy && nohup go run . > eBPF_sequencer_latency_${t}_node_$((2**i))_size.log 2>&1 &"
  run_cmd_on_device 2 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/experiments/ex2/client && export GO111MODULE=on && go mod tidy && nohup go run . 3000 $((2**i)) > text.log 2>&1 &"

  echo -e "\n>>> Waiting 5 minutes..."
  sleep 300

  done

  sleep 60

  echo "Done iteration $t."
  IFS=' ' read -r ip user pass <<< "${DEVICES[5]}"
    sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" \
      "nohup echo '$pass' | sudo -S reboot 2>&1 &"

  sleep 150

done

# -----------------------------------------------------------------------------
# Completion message
# -----------------------------------------------------------------------------
echo ""
echo "==============================================================="
echo " All experiment iterations completed successfully!"
echo "==============================================================="
