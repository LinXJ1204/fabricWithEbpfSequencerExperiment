package main

import (
	"encoding/binary"
	"fmt"
	"net"
	"sync"
	"time"
)

var (
	totalRequests int64 = 0
	totalLatency  int64 = 0
	mu            sync.Mutex
)

func main() {
	// Listen on UDP port
	listenAddr := ":8073"
	conn, err := net.ListenPacket("udp", listenAddr)
	if err != nil {
		fmt.Println("Error starting UDP server:", err)
		return
	}
	defer conn.Close()

	timeout := make(chan bool, 1)
	go func() {
		time.Sleep(270 * time.Second)
		timeout <- true
	}()

	// Buffer to receive packets
	buffer := make([]byte, 10000)

	go func() {
		for {
			// Read UDP packet
			n, addr, err := conn.ReadFrom(buffer)
			if err != nil {
				fmt.Println("Error reading UDP packet:", err)
				continue
			}

			// Ensure packet is at least 8 bytes (for timestamp)
			if n < 8 {
				fmt.Println("Received packet too small from", addr)
				continue
			}

			// Extract timestamp (first 8 bytes)
			sentTimestamp := binary.BigEndian.Uint64(buffer[2:10])
			sentTime := time.Unix(0, int64(sentTimestamp))

			// Compute latency
			receiveTime := time.Now()
			latency := receiveTime.Sub(sentTime).Microseconds() // Convert to microseconds

			// Update global stats
			mu.Lock()
			totalRequests++
			totalLatency += latency
			mu.Unlock()
		}
	}()

	select {
	case <-timeout:
		// Calculate average latency
		avgLatency := 0.0
		if totalRequests > 0 {
			avgLatency = float64(totalLatency) / float64(totalRequests)
		}
		fmt.Printf("Avg Latency: %.2f µs\n", avgLatency)
		return
	}
}

/* // printStats prints the average requests per second and average latency
func printStats() {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	var prevRequests int64 = 0

	for range ticker.C {
		mu.Lock()
		// Calculate RPS
		rps := totalRequests - prevRequests
		prevRequests = totalRequests

		// Calculate average latency
		avgLatency := 0.0
		if totalRequests > 0 {
			avgLatency = float64(totalLatency) / float64(totalRequests)
		}

		fmt.Printf("Requests/sec: %d | Avg Latency: %.2f µs\n", rps, avgLatency)
		mu.Unlock()
	}
}
*/
