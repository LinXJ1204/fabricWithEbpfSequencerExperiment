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

	for i := 0; i < numTransactions; i++ {
		wg.Add(1)
		assetId := "asset" + strconv.Itoa(rand.Intn(1000000)) // Generate random asset IDs
		createAsset(contract, assetId)
		go func(i int) {
			defer wg.Done()
			transferAssetAsync(contract, assetId) // Submit an asynchronous transaction
		}(i)
	}

	wg.Wait() // Wait for all async transactions to complete
	elapsedTime := time.Since(startTime).Seconds()
	tps := float64(numTransactions) / elapsedTime
	fmt.Printf("\nAsynchronous TransferAsset Transactions Per Second (TPS): %.2f\n", tps)
}
