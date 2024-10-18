/*
Copyright 2021 IBM All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"path"
	"sync"

	"github.com/hyperledger/fabric-gateway/pkg/client"
)

var wgg sync.WaitGroup
var wg sync.WaitGroup

var peerEndpoints = [3]string{"dns:///192.168.50.230:12051", "dns:///192.168.50.224:13051", "dns:///192.168.50.213:14051"}
var gatewayPeers = [3]string{"peer0.org1.example.com", "peer1.org1.example.com", "peer2.org1.example.com"}

func main() {

	const tpsLoading = 50000

	p0 := ContractForEachPeer(peerEndpoints[0], gatewayPeers[0])
	p1 := ContractForEachPeer(peerEndpoints[1], gatewayPeers[1])
	p2 := ContractForEachPeer(peerEndpoints[2], gatewayPeers[2])

	// Add the number of goroutines to WaitGroup
	wgg.Add(3)

	// Launch goroutines for TPS experiment
	go func() {
		defer wgg.Done() // Mark this goroutine as done when finished
		measureTPSTransferAssetAsync(p0, tpsLoading)
	}()

	go func() {
		defer wgg.Done() // Mark this goroutine as done when finished
		measureTPSTransferAssetAsync(p1, tpsLoading)
	}()

	go func() {
		defer wgg.Done() // Mark this goroutine as done when finished
		measureTPSTransferAssetAsync(p2, tpsLoading)
	}()

	wgg.Wait() // Wait for all async transactions to complete
	fmt.Printf("=====Experiment Done=====")
}

func readFirstFile(dirPath string) ([]byte, error) {
	dir, err := os.Open(dirPath)
	if err != nil {
		return nil, err
	}

	fileNames, err := dir.Readdirnames(1)
	if err != nil {
		return nil, err
	}

	return os.ReadFile(path.Join(dirPath, fileNames[0]))
}

// Submit a transaction synchronously, blocking until it has been committed to the ledger.
func createAsset(contract *client.Contract, assetId string) error {
	fmt.Printf("\n--> Submit Transaction: CreateAsset, creates new asset with ID, Color, Size, Owner and AppraisedValue arguments \n")

	submitResult, commit, err := contract.SubmitAsync("CreateAsset", client.WithArguments(assetId, "yellow", "5", "Tom", "1300"))
	if err != nil {
		(fmt.Errorf("failed to submit transaction asynchronously: %w", err))
		return err
	}

	fmt.Printf("\n*** Successfully submitted transaction to transfer ownership from %s to Mark. \n", string(submitResult))
	fmt.Println("*** Waiting for transaction commit.")

	if commitStatus, err := commit.Status(); err != nil {
		(fmt.Errorf("failed to get commit status: %w", err))
		return err
	} else if !commitStatus.Successful {
		(fmt.Errorf("transaction %s failed to commit with status: %d", commitStatus.TransactionID, int32(commitStatus.Code)))
		return err
	}

	fmt.Printf("*** Transaction committed successfully\n")
	return nil
}

// Evaluate a transaction by assetID to query ledger state.
func readAssetByID(contract *client.Contract, assetId string) {
	fmt.Printf("\n--> Evaluate Transaction: ReadAsset, function returns asset attributes\n")

	evaluateResult, err := contract.EvaluateTransaction("ReadAsset", assetId)
	if err != nil {
		(fmt.Errorf("failed to evaluate transaction: %w", err))
	}
	result := formatJSON(evaluateResult)

	fmt.Printf("*** Result:%s\n", result)
}

// Submit transaction asynchronously, blocking until the transaction has been sent to the orderer, and allowing
// this thread to process the chaincode response (e.g. update a UI) without waiting for the commit notification
func transferAssetAsync(contract *client.Contract, assetId string) error {
	fmt.Printf("\n--> Async Submit Transaction: TransferAsset, updates existing asset owner")

	submitResult, commit, err := contract.SubmitAsync("TransferAsset", client.WithArguments(assetId, "Mark"))
	if err != nil {
		(fmt.Errorf("failed to submit transaction asynchronously: %w", err))
		return err
	}

	fmt.Printf("\n*** Successfully submitted transaction to transfer ownership from %s to Mark. \n", string(submitResult))
	fmt.Println("*** Waiting for transaction commit.")

	if commitStatus, err := commit.Status(); err != nil {
		(fmt.Errorf("failed to get commit status: %w", err))
		return err
	} else if !commitStatus.Successful {
		(fmt.Errorf("transaction %s failed to commit with status: %d", commitStatus.TransactionID, int32(commitStatus.Code)))
		return err
	}

	fmt.Printf("*** Transaction committed successfully\n")
	return nil
}

// Format JSON data
func formatJSON(data []byte) string {
	var prettyJSON bytes.Buffer
	if err := json.Indent(&prettyJSON, data, "", "  "); err != nil {
		panic(fmt.Errorf("failed to parse JSON: %w", err))
	}
	return prettyJSON.String()
}
