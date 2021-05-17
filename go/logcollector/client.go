package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net"
	"net/rpc"
	"os"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
)

const BUFFERSIZE = 1024

// Make tcp Listener and Call sendfile()
func tcpfile(c *rpc.Client, filename string) {
	var res int64
	// Make TCP Listen port
	fserv, err := net.Listen("tcp", ":27000")
	if err != nil {
		log.Println(err)
	}
	defer fserv.Close()
	// Send filename and Call Remotely connect from server
	go c.Call("Server.TcpConn", filename, &res)
	// Accept connection
	conn, err := fserv.Accept()
	if err != nil {
		log.Println(err)
	}
	// Verify file rotate status
	lastfile, statfile, offset := verifile(filename)
	fmt.Println("Return Value : ", lastfile, " ", statfile, " ", offset)
	// continue from last sent
	sendfile(conn, lastfile, statfile, offset)
	if err != nil {
		log.Println(err)
	}
	// When file rotated, send current file
	if lastfile != filename {
		//time.Sleep(time.Millisecond * 500)
		go c.Call("Server.TcpConn", filename, &res)
		conn, err := fserv.Accept()
		if err != nil {
			log.Println(err)
		}
		sendfile(conn, filename, statfile, 0)
		if err != nil {
			log.Println(err)
		}
	}
}

// Verify source logfile switched
func verifile(filename string) (string, string, int64) {
	// get file status (size comparing)
	fileinfo, err := os.Stat(filename)
	if err != nil {
		log.Println(err)
	}
	fileSize := fileinfo.Size()
	fmt.Println("fileSize : ", fileSize)
	lastat := filename + ".stat"

	lafile, err := ioutil.ReadFile(lastat)
	if err != nil {
		log.Println(err)
	}

	labyte, err := strconv.Atoi(string(lafile))
	fmt.Println("lafile : ", string(lafile), "labyte : ", labyte)
	// When Log Rotate, Return Last rotated file
	if labyte > int(fileSize) {
		dir, _ := ioutil.ReadDir(".")
		exp := strings.Split(filename, ".")
		sort.Slice(dir, func(i, j int) bool {
			return dir[i].ModTime().Unix() > dir[j].ModTime().Unix()
		})
		var filelist []string
		for _, fl := range dir {
			if lt, _ := regexp.MatchString(".stat", fl.Name()); !lt {
				fi, err := regexp.MatchString(exp[0], fl.Name())
				if err == nil && fi {
					filelist = append(filelist, fl.Name())
				}
			}
		}
		// fmt.Println("Filelist : ", filelist)
		if len(filelist) > 1 {
			filename = filelist[1]
		} else {
			log.Println("Lastfile not Exist or offset status error : return original filename")
		}
	}
	return filename, lastat, int64(labyte)
}

// send file to sever through tcp
func sendfile(connection net.Conn, filename string, lastat string, offset int64) error {
	defer connection.Close()
	file, err := os.Open(filename)
	if err != nil {
		log.Println(err)
	}
	defer file.Close()
	fileinfo, err := file.Stat()
	if err != nil {
		log.Println(err)
	}

	lafile, err := os.OpenFile(lastat, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0660)
	if err != nil {
		log.Println(err)
	}
	defer lafile.Close()

	lafile.WriteString(strconv.FormatInt(fileinfo.Size(), 10))
	if err != nil {
		log.Println(err)
	}

	_, err = file.Seek(offset, 0)
	if err != nil {
		log.Println(err)
	}
	// send filename, filesize after filling 64 bytes
	fileSize := fillString(strconv.FormatInt(fileinfo.Size()-offset, 10), 64)
	//fileName := fillString(fileinfo.Name(), 64)
	connection.Write([]byte(fileSize))
	//connection.Write([]byte(fileName))
	// send file
	sendBuffer := make([]byte, BUFFERSIZE)
	for {
		_, err = file.Read(sendBuffer)
		if err == io.EOF {
			log.Printf("%s has been sent, closing connection.\n", filename)
			break
		}
		connection.Write(sendBuffer)
	}
	return nil
}

// fill string 64 bytes for receive side buffer
func fillString(returnString string, toLength int) string {
	for {
		lenString := len(returnString)
		if lenString < toLength {
			returnString = returnString + ":"
			continue
		}
		break
	}
	return returnString
}

func main() {
	var c *rpc.Client
	var filename string
	var svradr string
	var svrprt string
	var sleeptime time.Duration
	// logfile name for collecting
	filename = "sqltrace.log"
	// time for log collect delayed (second)
	sleeptime = 30
	// Server address
	svradr = "127.0.0.1"
	// Sever connection port
	svrprt = "9999"

	// MultiWriter Logger (stdout, logfile)
	flog, err := os.OpenFile("client.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	mlogger := io.MultiWriter(os.Stdout, flog)
	log.SetOutput(mlogger)

	svr := svradr + ":" + svrprt
	// Initial first rpc connection
	c, err = rpc.Dial("tcp", svr)
	if err != nil {
		log.Println(err)
	}
	defer c.Close()

	for {
		// Check server connection using RemoteCall
		var status string
		err = c.Call("Server.Status", "Connection Alive", &status)
		if err != nil {
			// when error reconnect server
			c, err = rpc.Dial("tcp", svr)
			if err != nil {
				// may have some problem network or something
				log.Println(err)
			}
		}
		// make tcp connection and send logfile
		tcpfile(c, filename)

		c.Close()
		time.Sleep(time.Second * sleeptime)
	}
}
