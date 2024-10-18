package main

import (
	"fmt"
	"math/rand"
	"strconv"
	"sync"
	"time"

	"github.com/hyperledger/fabric-gateway/pkg/client"
)

// Function to measure TPS for asynchronous transactions (TransferAsset)
func measureTPSTransferAssetAsync(contract *client.Contract, numTransactions int, workload uint) {
	startTime := time.Now()

	errCount := 0
	var mu sync.Mutex // Mutex for thread-safe error count updates

	for i := 0; i < numTransactions; i++ {
		wg.Add(1)
		assetId := "asset" + strconv.Itoa(rand.Intn(1000000)) // Generate random asset IDs
		time.Sleep(time.Duration(1/workload*1000) * time.Millisecond)
		go func(i int) {
			defer wg.Done()
			err := createAsset(contract, assetId)
			if err != nil {
				mu.Lock()
				errCount++
				mu.Unlock()
			} else {
				err = transferAssetAsync(contract, assetId) // Submit an asynchronous transaction
				if err != nil {
					mu.Lock()
					errCount++
					mu.Unlock()
				}
			}
		}(i)
	}

	wg.Wait() // Wait for all async transactions to complete
	elapsedTime := time.Since(startTime).Seconds()
	tps := float64(numTransactions) / elapsedTime
	fmt.Printf("\nAsynchronous TransferAsset Transactions Per Second (TPS): %.2f\n", tps)
	fmt.Printf("\nAsynchronous TransferAsset Transactions Failed: %.2f\n", errCount)
}
