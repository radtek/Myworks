package main

import (
	"database/sql"
	"fmt"
	"log"
	"strconv"
	"time"

	influx "github.com/influxdata/influxdb1-client/v2"

	// For using simply sql package
	_ "gopkg.in/rana/ora.v4"
)

type sesTable struct {
	sid, serial                                                []int64
	lastWait, waitMicro, p1, p2, p3                            []float64
	userName, status, osUser, machine, program, process, sqlID []string
	lockWait, p1Text, p2Text, p3Text, event, waitClass, state  []string
}

func (secollect *sesTable) gather(dbinfo string) *sesTable {
	db, err := sql.Open("ora", dbinfo)
	defer db.Close()
	if err != nil {
		fmt.Println(err)
	}
	var query string
	query = "SELECT SID,SERIAL#,USERNAME,STATUS,OSUSER,MACHINE,PROGRAM,PROCESS,SQL_ID,LOCKWAIT,P1,P1TEXT,P2,P2TEXT,P3,P3TEXT,EVENT,WAIT_CLASS,TIME_SINCE_LAST_WAIT_MICRO,STATE,WAIT_TIME_MICRO FROM V$SESSION"
	rows, err := db.Query(query)
	if err != nil {
		fmt.Println(err)
	}
	defer rows.Close()

	for rows.Next() {
		var sid, serial int64
		var lastWait, waitMicro, p1, p2, p3 float64
		var userName, status, osUser, machine, program, process, sqlID string
		var lockWait, p1Text, p2Text, p3Text, event, waitClass, state string

		if err = rows.Scan(&sid, &serial, &userName, &status, &osUser, &machine, &program, &process, &sqlID, &lockWait, &p1, &p1Text, &p2, &p2Text, &p3, &p3Text, &event, &waitClass, &lastWait, &state, &waitMicro); err != nil {
			log.Fatal(err)
		}

		secollect.sid = append(secollect.sid, sid)
		secollect.serial = append(secollect.serial, serial)
		secollect.userName = append(secollect.userName, userName)
		secollect.status = append(secollect.status, status)
		secollect.osUser = append(secollect.osUser, osUser)
		secollect.machine = append(secollect.machine, machine)
		secollect.program = append(secollect.program, program)
		secollect.process = append(secollect.process, process)
		secollect.sqlID = append(secollect.sqlID, sqlID)
		secollect.lockWait = append(secollect.lockWait, lockWait)
		secollect.p1 = append(secollect.p1, p1)
		secollect.p1Text = append(secollect.p1Text, p1Text)
		secollect.p2 = append(secollect.p2, p2)
		secollect.p2Text = append(secollect.p2Text, p2Text)
		secollect.p3 = append(secollect.p3, p3)
		secollect.p3Text = append(secollect.p3Text, p3Text)
		secollect.event = append(secollect.event, event)
		secollect.waitClass = append(secollect.waitClass, waitClass)
		secollect.lastWait = append(secollect.lastWait, lastWait)
		secollect.state = append(secollect.state, state)
		secollect.waitMicro = append(secollect.waitMicro, waitMicro)

	}
	fmt.Println("Active session gather successed.")
	return secollect
}

func (secollect *sesTable) send() {
	//var query string
	var dbname string
	//var retention string
	var measurement string

	dbname = "storedata"
	//retention = ""
	measurement = "DTMDB_201906"

	c, err := influx.NewHTTPClient(influx.HTTPConfig{
		Addr: "http://localhost:8086",
	})
	if err != nil {
		fmt.Println("Error connecting InfluxDB Client: ", err.Error())
	}
	defer c.Close()
	bp, err := influx.NewBatchPoints(influx.BatchPointsConfig{
		Database:  dbname,
		Precision: "s",
		//RetentionPolicy: ""
	})
	if err != nil {
		fmt.Println(err)
	}

	for i := range secollect.sid {
		//query = fmt.Sprintf("INSERT %s", secollect.sqlID[i])
		tags := map[string]string{
			"sid":       strconv.FormatInt(secollect.sid[i], 10),
			"event":     secollect.event[i],
			"waitclass": secollect.waitClass[i],
			"state":     secollect.state[i],
		}
		fields := map[string]interface{}{
			"sqlID":     secollect.sqlID[i],
			"username":  secollect.userName[i],
			"serial":    secollect.serial[i],
			"status":    secollect.status[i],
			"osuser":    secollect.osUser[i],
			"machine":   secollect.machine[i],
			"program":   secollect.program[i],
			"process":   secollect.process[i],
			"lockWait":  secollect.lockWait[i],
			"p1":        secollect.p1[i],
			"p1text":    secollect.p1Text[i],
			"p2":        secollect.p2[i],
			"p2text":    secollect.p2Text[i],
			"p3":        secollect.p3[i],
			"p3text":    secollect.p3Text[i],
			"lastwait":  secollect.lastWait[i],
			"waitMicro": secollect.waitMicro[i],
		}
		point, err := influx.NewPoint(
			measurement,
			tags,
			fields,
			time.Now(),
		)
		if err != nil {
			log.Fatalln("Error: ", err)
		}

		bp.AddPoint(point)
	}
	err = c.Write(bp)
	if err != nil {
		fmt.Println(err)
	} else {
		fmt.Println("Collect Done!")
	}
	/*
		q := influx.NewQuery(query, dbname, retention)
		if response, err := c.Query(q); err == nil && response.Error() == nil {
			fmt.Println(response.Results)
		}
	*/
}

func main() {
	var db string
	var reculse time.Duration
	db = "system/dtmdb1!@dfcalldb:1534/DTMDB"
	reculse = 3
	for {
		var secol sesTable
		secol.gather(db)
		secol.send()
		time.Sleep(time.Second * reculse)
	}
}
