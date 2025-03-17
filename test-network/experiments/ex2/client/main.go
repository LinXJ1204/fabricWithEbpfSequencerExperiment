package main

import (
	"fmt"
	"net"
	"os"
	"strconv"
	"syscall"
	"time"
)

func main() {
	param1 := os.Args[1] // First argument (should be an integer)
	rps, _ := strconv.Atoi(param1)
	msgNum := rps * 60 * 1

	param2 := os.Args[2] // First argument (should be an integer)
	msgSize, _ := strconv.Atoi(param2)

	timeout := make(chan bool, 1)
	go func() {
		time.Sleep(1 * time.Minute)
		timeout <- true
	}()

	// UDP target address
	destAddr := "192.168.50.184:7072" // Replace with the actual target address and port

	// Create UDP socket
	conn, err := net.Dial("udp", destAddr)
	if err != nil {
		fmt.Println("Error creating UDP connection:", err)
		os.Exit(1)
	}
	defer conn.Close()

	// Get raw file descriptor
	fd, err := getRawSocketFd(conn)
	if err != nil {
		fmt.Println("Error getting raw socket FD:", err)
		os.Exit(1)
	}

	// Set TTL (Time-To-Live) to 171
	err = syscall.SetsockoptInt(fd, syscall.IPPROTO_IP, syscall.IP_TTL, 171)
	if err != nil {
		fmt.Println("Error setting TTL:", err)
		os.Exit(1)
	}

	packet := make([]byte, msgSize)
	// Fill remaining bytes with dummy data
	for i := 10; i < len(packet); i++ {
		packet[i] = byte(i % 256)
	}

	tt := time.Duration(1/float64(rps)*1000000) * time.Microsecond

	fmt.Println(1 / float64(rps) * 1000000)
	txCount := 0

	for txCount < msgNum {
		time.Sleep(tt)
		txCount++
	}

	fmt.Println("Total txs sent: %d \n", txCount)
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
