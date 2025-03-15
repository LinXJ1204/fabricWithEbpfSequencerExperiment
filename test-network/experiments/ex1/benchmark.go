package main

import (
	"fmt"
	"strconv"
	"sync"
	"time"

	"github.com/hyperledger/fabric-gateway/pkg/client"
)

var wg1 sync.WaitGroup

// Function to measure TPS for asynchronous transactions (TransferAsset)
func measureTPSTransferAssetAsync(contract *client.Contract, numTransactions int, workload int) {
	errCount := 0
	txCount := 0
	ltCount := 0
	totalLt := 0
	var mu sync.Mutex  // Mutex for thread-safe error count updates
	var mu1 sync.Mutex // Mutex for thread-safe error count updates

	timeout := make(chan bool, 1)
	go func() {
		time.Sleep(90 * time.Second)
		timeout <- true
	}()

	for i := 0; i < numTransactions; i++ {
		wg1.Add(1)
		assetId := "asset" + strconv.Itoa(int(time.Now().UnixNano())) // Generate random asset IDs
		time.Sleep(time.Duration(1/float64(workload)*1000000) * time.Microsecond)
		select {
		case <-timeout:
			i = numTransactions
			wg1.Done()
		default:
			go func(i int) {
				defer wg1.Done()
				if i%25 == 0 {
					latency, err := createAssetWithLatency(contract, assetId)
					if err != nil {
						mu.Lock()
						errCount++
						mu.Unlock()
					} else {
						mu1.Lock()
						txCount++
						ltCount++
						totalLt += int(latency)
						mu1.Unlock()
					}
				} else {
					err := createAsset(contract, assetId)
					if err != nil {
						mu.Lock()
						errCount++
						mu.Unlock()
					} else {
						mu1.Lock()
						txCount++
						mu1.Unlock()
					}
				}
			}(i)
		}
	}

	wg1.Wait() // Wait for all async transactions to complete
	fmt.Printf("=======Transaction Average Latency: %d =======\n", totalLt/ltCount)
}
