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

declare -A tc_bufferSize
tc_bufferSize["1"]="1000"
tc_bufferSize["2"]="2000"
tc_bufferSize["3"]="3000"
tc_bufferSize["4"]="4000"
tc_bufferSize["5"]="5000"
tc_bufferSize["6"]="10000"
tc_bufferSize["7"]="15000"
tc_bufferSize["8"]="20000"
tc_bufferSize["9"]="25000"
tc_bufferSize["10"]="30000"
tc_bufferSize["11"]="35000"
tc_bufferSize["12"]="40000"
tc_bufferSize["13"]="45000"
tc_bufferSize["14"]="50000"
tc_bufferSize["15"]="100000"
tc_bufferSize["16"]="200000"
tc_bufferSize["17"]="300000"
tc_bufferSize["18"]="400000"
tc_bufferSize["19"]="500000"
tc_bufferSize["20"]="1000000"

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
for ((s=2; s<=5; s++))
do
  for ((t=10; t<=20; t++))
  do
    echo -e "\n============================================="
    echo "Starting Experiment for node count = $t"
    echo "============================================="

    for ((i=6; i<=14; i++))
    do

    program=${tc_progarms[4]}
    tcBufferSize=${tc_bufferSize[$i]}
    IFS=' ' read -r ip user pass <<< "${DEVICES[5]}"
      sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" \
        "echo '$pass' | sudo -S tc qdisc add dev enp109s0 root handle 1: pfifo limit '$tcBufferSize' && \
        cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/ebpfExec/exp && \
        nohup echo '$pass' | sudo -S timeout 3 ./$program enp109s0"
    echo -e "\n>>> Waiting 5 seconds..."
    sleep 5

    echo -e "\n============================================="
    echo "Starting Experiment for node = $i"
    echo "============================================="

    run_cmd_on_device 2 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/experiments/ex2/server && export GO111MODULE=on && go mod tidy && nohup go run . > eBPF_sequencer_LT_tcBuffer_'$program'_4096_size'$tcBufferSize'_no_'$s'.log 2>&1 &"
    run_cmd_on_device 2 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/experiments/ex2/client && export GO111MODULE=on && go mod tidy && nohup go run . $((250*t)) 3200 > text.log 2>&1 &"
    run_cmd_on_device 5 "cd mainPlan/fabricWithEbpfSequencerExperiment/test-network/experiments && nohup ./udpDropDetect.sh eBPF_LT_tcBufferSize_'$tcBufferSize'_RPS_'$((250*t))'_no_'$s' > text.log 2>&1 &"

    echo -e "\n>>> Waiting 60 minutes..."
    sleep 270

    echo "Done iteration $t."
    IFS=' ' read -r ip user pass <<< "${DEVICES[5]}"
      sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" \
        "nohup echo '$pass' | sudo -S reboot 2>&1 &"

    sleep 150

    done
  done
done

# -----------------------------------------------------------------------------
# Completion message
# -----------------------------------------------------------------------------
echo ""
echo "==============================================================="
echo " All experiment iterations completed successfully!"
echo "==============================================================="
