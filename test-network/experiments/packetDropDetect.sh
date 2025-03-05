#!/bin/bash
INTERFACE="enp109s0"
LOG_FILE="tc_buffer_status.log"

while true; do
    echo "Timestamp: $(date)" >> $LOG_FILE
    tc -s qdisc show dev $INTERFACE >> $LOG_FILE
    echo "----------------------------------" >> $LOG_FILE
    sleep 1
done
