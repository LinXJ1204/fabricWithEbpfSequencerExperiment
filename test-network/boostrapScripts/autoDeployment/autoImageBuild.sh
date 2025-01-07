# Each entry:  DeviceIndex => "IPAddress Username Password"
declare -A DEVICES
DEVICES["0"]="192.168.50.224 nsd nsd"
DEVICES["1"]="192.168.50.213 nsd nsd"
DEVICES["2"]="192.168.50.230 udrt nsd12345"
DEVICES["3"]="192.168.50.239 nsd1235 nsd12345"
DEVICES["4"]="192.168.50.219 nsd12345 nsd12345"
DEVICES["5"]="192.168.50.16 nmsl777 nmsl777"

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

# 1) bringUpNode/orderer.sh on Device0
run_cmd_on_device 0 "cd mainPlan/fabricWithEbpfSequencer && git checkout feat/baseline && git pull && make docker"

# 2) bringUpNode/orderer1.sh on Device1
run_cmd_on_device 1 "cd mainPlan/fabricWithEbpfSequencer && git checkout feat/baseline && git pull && make docker"

# 3) bringUpNode/orderer2.sh on Device2
run_cmd_on_device 2 "cd mainPlan/fabricWithEbpfSequencer && git checkout feat/baseline && git pull && make docker"

# 4) sudo bringUpNode/orderer3.sh on Device3
run_cmd_on_device 3 "cd mainPlan/fabricWithEbpfSequencer && git checkout feat/baseline && git pull && make docker"

# 5) sudo bringUpNode/orderer4.sh on Device4
run_cmd_on_device 4 "cd mainPlan/fabricWithEbpfSequencer && git checkout feat/baseline && git pull && make docker"

# 6) sudo bringUpNode/orderer4.sh on Device4
run_cmd_on_device 5 "cd mainPlan/fabricWithEbpfSequencer && git checkout feat/baseline && git pull && make docker"