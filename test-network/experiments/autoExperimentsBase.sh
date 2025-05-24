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

SUCCESS_MSG="committed with status (VALID) at localhost:12051"

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
  for ((i=20; i>=1; i--))
  do
    echo -e "\n============================================="
    echo "Starting Experiment for i = $i"
    echo "============================================="

    while true; do
      # Run the deployment script and capture the output
      OUTPUT=$(run_cmd_on_device 0 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/boostrapScripts/autoDeployment && ./autoDeployment.sh" 2>&1)
      sleep 5  # Wait a few seconds before trying again

      # Check if the output contains the desired success message
      if echo "$OUTPUT" | grep -q "$SUCCESS_MSG"; then
        echo "Deployment successful."
        break  # Exit the loop when the deployment is successful
      else
        echo "Deployment not successful. Retrying in 5 seconds..."
        sleep 5  # Wait a few seconds before trying again
      fi
    done

    sleep 5  # Wait a few seconds before trying again

    # 1) Run 'go run . 2^i' on Device 0
    #    Bash doesn't support '^' for exponent, so we use $((2**i)).
    run_cmd_on_device 0 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/experiments/ex1 && export GO111MODULE=on && go mod tidy && nohup go run . $((250*i)) > raft_512_run_latency_50ms_${i}_c${t}.log 2>&1 &"

    # 2) Wait 10 seconds
    echo -e "\n>>> Waiting 10 seconds..."
    sleep 10

    # 3) Run 'go run .' in TPSmeasure folder on Device 2
    run_cmd_on_device 1 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/experiments/TPSmeasure && nohup /usr/local/go/bin/go run . > raft_512_run_tps_50ms_${i}_c${t}.log 2>&1 &"

    # 4) Wait 4 minutes
    echo -e "\n>>> Waiting 4 minutes..."
    sleep 90  # 240 seconds = 4 minutes

  done
done
# -----------------------------------------------------------------------------
# Completion message
# -----------------------------------------------------------------------------
echo ""
echo "==============================================================="
echo " All experiment iterations completed successfully!"
echo "==============================================================="
