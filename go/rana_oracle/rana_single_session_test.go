package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"time"

	// For using simply sql package
	_ "gopkg.in/rana/ora.v4"
)

type sesTable struct {
	enc_all, dec_all string
	fault            int64
}

func (secollect *sesTable) gather(dbinfo string) *sesTable {
	db, err := sql.Open("ora", dbinfo)
	defer db.Close()
	if err != nil {
		fmt.Println(err)
	}
	for {
		var query string
		query = "SELECT DAMO.ENC_ALL('TEST') AS ENC_ALL, DAMO.DEC_ALL('QF7c/sICfVszezF01BFT3BCN') AS DEC_ALL, CASE WHEN DAMO.DEC_ALL('QF7c/sICfVszezF01BFT3BCN') = 'TEST' THEN 0 ELSE 1 END AS FAULT FROM DUAL"
		rows, err := db.Query(query)
		if err != nil {
			fmt.Println(err)
		}
		defer rows.Close()

		var reculse time.Duration
		reculse = 1

		for rows.Next() {
			var enc_all, dec_all string
			var fault int64

			if err = rows.Scan(&enc_all, &dec_all, &fault); err != nil {
				log.Fatal(err)
			}

			secollect.enc_all = enc_all
			secollect.dec_all = dec_all
			secollect.fault = fault

		}
		mlogger.Printf("BIDMGR - ENC: %s, DEC: %s, FAULT: %d", secollect.enc_all, secollect.dec_all, secollect.fault)
		time.Sleep(time.Second * reculse)
		//fmt.Println("gather succeded.")
	}
}

var mlogger *log.Logger

func main() {
	flog, err := os.OpenFile("qresult.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		panic(err)
	}
	defer flog.Close()

	mlogger = log.New(flog, "RESULT : ", log.Ldate|log.Ltime|log.Lshortfile)
	//mlogger := io.MultiWriter(flog, os.Stdout)
	//log.SetOutput(mlogger)

	var db string
	//var reculse time.Duration
	db = "user/pass@host:1521/SID"
	//reculse = 2
	//for {
	var secol sesTable
	secol.gather(db)
	//qresult := secol.gather(db)
	//	mlogger.Printf("BIDMGR - ENC: %s, DEC: %s, FAULT: %d", qresult.enc_all, qresult.dec_all, qresult.fault)
	//	time.Sleep(time.Second * reculse)
	//}
}
