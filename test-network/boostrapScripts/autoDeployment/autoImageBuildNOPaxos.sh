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

echo ""
echo "=================="
echo " Step 2: Setup   "
echo "=================="

run_cmd_on_device 0 "cd mainPlan/fabricWithEbpfSequencer && git checkout feat/nopaxos && git pull && make docker"

run_cmd_on_device 1 "cd mainPlan/fabricWithEbpfSequencer && git checkout feat/nopaxos && git pull && make docker"

run_cmd_on_device 2 "cd mainPlan/fabricWithEbpfSequencer && git checkout feat/nopaxos && git pull && make docker"

run_cmd_on_device 3 "cd mainPlan/fabricWithEbpfSequencer && git checkout feat/nopaxos && git pull && make docker"

run_cmd_on_device 4 "cd mainPlan/fabricWithEbpfSequencer && git checkout feat/nopaxos && git pull && make docker"

run_cmd_on_device 5 "cd mainPlan/fabricWithEbpfSequencer && git checkout feat/nopaxos && git pull && make docker"

run_cmd_on_device 6 "cd mainPlan/fabricWithEbpfSequencer && git checkout feat/nopaxos && git pull && make docker"
