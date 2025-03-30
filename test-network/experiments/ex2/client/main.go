package main

import (
	"encoding/binary"
	"fmt"
	"net"
	"os"
	"runtime"
	"strconv"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
)

var reqCount int64 // Atomic counter for requests sent

func main() {
	if len(os.Args) < 3 {
		fmt.Println("Usage: go run main.go <RPS> <MessageSize>")
		os.Exit(1)
	}

	// Parse command-line arguments
	rps, err := strconv.Atoi(os.Args[1])
	if err != nil || rps <= 0 {
		fmt.Println("Invalid RPS value")
		os.Exit(1)
	}
	msgSize, err := strconv.Atoi(os.Args[2])
	if err != nil || msgSize < 10 {
		fmt.Println("Invalid Message Size (minimum 10 bytes)")
		os.Exit(1)
	}

	destAddr := "192.168.50.184:7072" // Replace with actual target address and port

	// Create UDP connection
	conn, err := net.Dial("udp", destAddr)
	if err != nil {
		fmt.Println("Error creating UDP connection:", err)
		os.Exit(1)
	}
	defer conn.Close()

	// Set TTL to 171
	fd, err := getRawSocketFd(conn)
	if err != nil {
		fmt.Println("Error getting raw socket FD:", err)
		os.Exit(1)
	}
	err = syscall.SetsockoptInt(fd, syscall.IPPROTO_IP, syscall.IP_TTL, 170)
	if err != nil {
		fmt.Println("Error setting TTL:", err)
		os.Exit(1)
	}

	packetTemplate := make([]byte, msgSize)
	for i := 10; i < len(packetTemplate); i++ {
		packetTemplate[i] = byte(i % 256) // Fill with dummy data
	}

	numWorkers := runtime.NumCPU() * 2 // Number of workers based on CPU cores
	ratePerWorker := rps / numWorkers

	fmt.Printf("Starting %d workers with %d RPS each...\n", numWorkers, ratePerWorker)

	var wg sync.WaitGroup
	wg.Add(numWorkers)

	for i := 0; i < numWorkers; i++ {
		go func() {
			defer wg.Done()
			sendPackets(conn, packetTemplate, ratePerWorker)
		}()
	}

	wg.Wait()
	fmt.Printf("Total packets sent: %d\n", atomic.LoadInt64(&reqCount))
}

// sendPackets sends packets at the specified rate using a ticker for precise timing
func sendPackets(conn net.Conn, packetTemplate []byte, rate int) {
	ticker := time.NewTicker(time.Second / time.Duration(rate))
	defer ticker.Stop()

	packet := make([]byte, len(packetTemplate))
	copy(packet, packetTemplate)

	timeout := make(chan bool, 1)
	go func() {
		time.Sleep(60 * time.Second)
		timeout <- true
	}()

	for range ticker.C {
		select {
		case <-timeout:
			return
		default:
			timestamp := time.Now().UnixNano()
			binary.BigEndian.PutUint64(packet[2:10], uint64(timestamp)) // Embed timestamp

			if _, err := conn.Write(packet); err == nil {
				atomic.AddInt64(&reqCount, 1) // Increment atomic counter
			} else {
				fmt.Println("Error sending packet:", err)
				return
			}
		}
	}
}

// getRawSocketFd extracts the file descriptor from net.Conn
func getRawSocketFd(conn net.Conn) (int, error) {
	udpConn, ok := conn.(*net.UDPConn)
	if !ok {
		return -1, fmt.Errorf("not a UDP connection")
	}

	rawConn, err := udpConn.SyscallConn()
	if err != nil {
		return -1, err
	}

	var fd int
	err = rawConn.Control(func(f uintptr) {
		fd = int(f)
	})

	return fd, err
}
