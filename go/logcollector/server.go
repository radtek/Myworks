package main

import (
	"fmt"
	"io"
	"log"
	"net"
	"net/rpc"
	"os"
	"strconv"
	"strings"
)

type Server struct{}

func (this *Server) Status(i string, reply *string) error {
	*reply = i
	log.Println(*reply)
	return nil
}

func (this *Server) TcpConn(filename string, ret *int64) error {
	BUFFERSIZE := int64(1024)
	connection, err := net.Dial("tcp", "127.0.0.1:27000")
	if err != nil {
		log.Println(err)
	} else {
		fmt.Println("TCP Connection Established")
	}
	defer connection.Close()
	//bufferFileName := make([]byte, 64)
	bufferFileSize := make([]byte, 64)

	connection.Read(bufferFileSize)
	fileSize, _ := strconv.ParseInt(strings.Trim(string(bufferFileSize), ":"), 10, 64)

	//connection.Read(bufferFileName)
	//fileName := strings.Trim(string(bufferFileName), ":")

	newFile, err := os.OpenFile(filename, os.O_CREATE|os.O_RDWR|os.O_APPEND, 0660)

	if err != nil {
		log.Println(err)
	}
	defer newFile.Close()

	fmt.Println("BUFFER : ", BUFFERSIZE, "Filename : ", filename, "Sentsize : ", fileSize)
	var receivedBytes int64
	if fileSize > 0 {
		fmt.Printf("Received : ")
		for {
			if (fileSize - receivedBytes) < BUFFERSIZE {
				io.CopyN(newFile, connection, (fileSize - receivedBytes))
				if err != nil {
					log.Println(err)
				}
				connection.Read(make([]byte, (receivedBytes+BUFFERSIZE)-fileSize))
				if err != nil {
					log.Println(err)
				}
				receivedBytes += (fileSize - receivedBytes)
				//fmt.Printf("%d ", receivedBytes)
				fmt.Printf("%s\n", "#")
				newFile.WriteString("\n")
				break
			}
			io.CopyN(newFile, connection, BUFFERSIZE)
			if err != nil {
				log.Println(err)
			}
			receivedBytes += BUFFERSIZE
			//fmt.Printf("%d ", receivedBytes)
			fmt.Printf("%s", "#")
		}
	} else {
		receivedBytes = 0
		fmt.Println("File was not changed")
	}
	*ret = receivedBytes
	log.Printf("\nReceived bytes : %d \n", *ret)
	return nil
}

func server() {
	rpc.Register(new(Server))
	ln, err := net.Listen("tcp", ":9999")
	if err != nil {
		log.Println(err)
		return
	}
	log.Println("Server started and Listened")
	for {
		c, err := ln.Accept()
		if err != nil {
			log.Println(err)
			continue
		}
		go rpc.ServeConn(c)
	}
}

//var mlogger *log.Logger

func main() {
	flog, err := os.OpenFile("server.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		panic(err)
	}
	defer flog.Close()

	//	mlogger = log.New(flog, "INFO : ", log.Ldate|log.Ltime|log.Lshortfile)
	mlogger := io.MultiWriter(flog, os.Stdout)
	log.SetOutput(mlogger)

	go server()

	var input string
	fmt.Scanln(&input)
	defer log.Println("Shutdown Server")
}
