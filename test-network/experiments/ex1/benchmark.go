package main

import (
	"fmt"
	"math/rand"
	"strconv"
	"time"

	"github.com/hyperledger/fabric-gateway/pkg/client"
)

// Function to measure TPS for asynchronous transactions (TransferAsset)
func measureTPSTransferAssetAsync(contract *client.Contract, numTransactions int) {
	startTime := time.Now()

	errCount := 0

	for i := 0; i < numTransactions; i++ {
		wg.Add(1)
		assetId := "asset" + strconv.Itoa(rand.Intn(1000000)) // Generate random asset IDs
		go func(i int) {
			defer wg.Done()
			err := createAsset(contract, assetId)
			if err != nil {
				errCount++
			} else {
				err = transferAssetAsync(contract, assetId) // Submit an asynchronous transaction
				if err != nil {
					errCount++
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
