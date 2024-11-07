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
func measureTPSTransferAssetAsync(contract *client.Contract, numTransactions int, workload uint) {
	startTime := time.Now()

	errCount := 0
	txCount := 0
	var mu sync.Mutex  // Mutex for thread-safe error count updates
	var mu1 sync.Mutex // Mutex for thread-safe error count updates

	for i := 0; i < numTransactions; i++ {
		wg1.Add(1)
		assetId := "asset" + strconv.Itoa(int(time.Now().UnixNano())) // Generate random asset IDs
		time.Sleep(time.Duration(1/float64(workload)*1000) * time.Millisecond)
		go func(i int) {
			defer wg1.Done()
			err := createAsset(contract, assetId)
			if err != nil {
				fmt.Println("====ERROR 1s====")
				mu.Lock()
				errCount++
				mu.Unlock()
			} else {
				mu1.Lock()
				txCount++
				fmt.Println(txCount - 1)
				mu1.Unlock()
			}
		}(i)
	}

	wg1.Wait() // Wait for all async transactions to complete
	elapsedTime := time.Since(startTime).Seconds()
	tps := float64(txCount) / elapsedTime
	fmt.Printf("\nAsynchronous TransferAsset Transactions Per Second (TPS): %.2f\n", tps)
	fmt.Printf("\nAsynchronous TransferAsset Transactions Failed: %.2f\n", errCount)
}
