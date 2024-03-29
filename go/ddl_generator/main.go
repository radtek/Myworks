package main

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"os"
	"regexp"
	"strconv"
	"strings"
)

func readLines(path string) ([]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}
	return lines, scanner.Err()
}

type genTable struct {
	schema, table_name, table_comment, option,
	column, datatype, defval, nullable, col_comment, pk []string
}

func (gt *genTable) Collect(lines []string, del string) *genTable {
	for _, line := range lines {
		delimit := regexp.MustCompile(del)
		sp := delimit.Split(line, -1)
		//fmt.Println(line)
		//fmt.Println(sp[1])
		splen := len(sp)
		if splen == 10 {
			gt.table_comment = append(gt.table_comment, sp[0])
			gt.table_name = append(gt.table_name, sp[1])
			gt.col_comment = append(gt.col_comment, sp[2])
			gt.column = append(gt.column, sp[3])
			gt.pk = append(gt.pk, sp[4])
			gt.datatype = append(gt.datatype, sp[5])
			gt.defval = append(gt.defval, sp[6])
			gt.nullable = append(gt.nullable, sp[7])
			gt.schema = append(gt.schema, sp[8])
			gt.option = append(gt.option, sp[9])
		} else if splen < 2 {
			log.Fatalln("Critical - Delimiter not matched with data file.")
		} else if splen > 10 {
			log.Fatalln("Critical - Field Exceeded, Some field may has delimiter. Check data.")
		} else {
			log.Fatalln("Critical - Field Saperate unnomally, Check Delimiter and Datafile.")
		}
	}

	return gt
}
func ck_datatype(dt string) bool {
	rep := regexp.MustCompile(`\s+`)
	sdt := strings.Split(strings.ToUpper(rep.ReplaceAllString(dt, "")), "(")
	curdt := sdt[0]

	if curdt == "CHAR" || curdt == "VARCHAR2" || curdt == "NCHAR" || curdt == "NVARCHAR" || curdt == "LONG" || curdt == "CLOB" || curdt == "NCLOB" || curdt == "NUMBER" || curdt == "FLOAT" || curdt == "BINARY_FLOAT" || curdt == "BINARY_DOUBLE" || curdt == "DATE" || curdt == "TIMESTAMP" || curdt == "BLOB" || curdt == "BFILE" {
		return true
	} else {
		return false
	}
}
func (gt *genTable) Check() {
	var errcnt int = 0
	var tabstart int

	log.Println("■■ Check Process Start  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■")

	for rows := range gt.column {
		if rows == 0 || gt.table_name[rows-1] != gt.table_name[rows] {
			tabstart = rows
		}
		rep := regexp.MustCompile(`\s+`)
		curtab := rep.ReplaceAllString(gt.table_name[rows], "")

		if curtab == "" {
			log.Println("Critical - line NO.", rows+1, ": Has empty Table id. Please check.")
			errcnt = errcnt + 1

		}
		err := ck_datatype(gt.datatype[rows])
		if err == false {
			log.Println("Critical - line NO.", rows+1, ": ", gt.datatype[rows], "Datatype not valid. Please check.")
			errcnt = errcnt + 1
		}
		if len(gt.table_name) == rows+1 || gt.table_name[rows] != gt.table_name[rows+1] {
			tabbegin := tabstart

			for tabbegin < rows+1 {
				var dupcnt int = 0
				ts := tabstart
				curcol := rep.ReplaceAllString(gt.column[tabbegin], "")
				//fmt.Println("curcol : ", curcol)

				for ts < rows+1 {
					cpcol := rep.ReplaceAllString(gt.column[ts], "")
					//fmt.Println("cpcol :", cpcol)

					if curcol == cpcol {
						dupcnt = dupcnt + 1
						//fmt.Println(dupcnt)

						if dupcnt > 1 {
							if tabbegin != ts {
								log.Println("Critical - Line No.", tabbegin+1, ",", ts+1, ": Column -'"+curcol+"' has same name in Table '"+gt.table_name[tabbegin]+"'. Please check.")
							}
							errcnt = errcnt + 1
						}
					}
					ts++
				}
				tabbegin++
			}
		}

	}
	if errcnt > 0 {
		log.Fatal("Tables or Datatypes were not valid. Please check error.log.")
	} else {
		log.Println("■■ Check Complete, Start Generate ■■■■■■■■■■■■■■■■■■■■■■■■■■")
	}
}

func (gt *genTable) Generate() {
	var nullcnt, tabstart int

	file, err := os.Create("DDL_GEN.sql")
	if err != nil {
		log.Println(err)
	}
	defer file.Close()

	w := bufio.NewWriter(file)

	for rows := range gt.column {
		if rows == 0 || gt.table_name[rows-1] != gt.table_name[rows] {

			fmt.Fprint(w, "\n\n\n--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■",
				"\n--", gt.schema[rows]+"."+gt.table_name[rows], "\t", gt.table_comment[rows],
				"\n--■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■\n")
			fmt.Fprintln(w, "CREATE TABLE ", gt.schema[rows]+"."+gt.table_name[rows], " (")
			nullcnt = 0
			tabstart = rows
		}

		rep := regexp.MustCompile(`\s+`)
		curcol := rep.ReplaceAllString(gt.column[rows], "")
		curdef := rep.ReplaceAllString(gt.defval[rows], "")

		if curcol != "" {
			fmt.Fprint(w, gt.column[rows], "\t", gt.datatype[rows], "\t")
			if curdef != "" {
				fmt.Fprint(w, "DEFAULT ", gt.defval[rows], "\t")
			}
			if gt.nullable[rows] == "NOT NULL" {
				nullcnt = nullcnt + 1
				nullstr := strconv.Itoa(nullcnt)
				if len(nullstr) < 2 {
					nullstr = "0" + nullstr
				}

				fmt.Fprint(w, "CONSTRAINT CK_"+gt.table_name[rows]+"_"+nullstr, "\t", gt.nullable[rows], "\n")
			} else {
				fmt.Fprint(w, "\n")
			}

		} else {
			log.Println("Warning - Line No.", rows, ": Excluded in Table Creation, Cause Column ID was EMPTY!")
		}
		if len(gt.table_name) == rows+1 || gt.table_name[rows] != gt.table_name[rows+1] {
			ts := tabstart
			var pkarr []string
			for ts < rows+1 {
				if rep.ReplaceAllString(gt.pk[ts], "") != "" {
					if rep.ReplaceAllString(gt.column[ts], "") != "" {
						pkarr = append(pkarr, gt.column[ts])
					}
				}
				ts++
			}
			if len(pkarr) > 0 {
				fmt.Fprint(w, ", CONSTRAINT PK_"+gt.table_name[tabstart], " PRIMARY KEY", "("+strings.Join(pkarr, ",")+")\n")
			}
			fmt.Fprintf(w, ")")
			fmt.Fprintln(w, gt.option[tabstart], ";")
			fmt.Fprintln(w, "COMMENT ON TABLE", gt.schema[tabstart]+"."+gt.table_name[tabstart], "IS '"+gt.table_comment[tabstart]+"';")

			ts = tabstart

			for ts < rows+1 {
				cc := rep.ReplaceAllString(gt.column[ts], "")
				if cc != "" {
					fmt.Fprintln(w, "COMMENT ON COLUMN", gt.schema[tabstart]+"."+gt.table_name[tabstart]+"."+gt.column[ts], "IS '"+gt.col_comment[ts]+"';")
				}
				ts++
			}
		} else {
			stcol := rep.ReplaceAllString(gt.column[rows], "")
			nexcol := rep.ReplaceAllString(gt.column[rows+1], "")
			if nexcol != "" {
				if rows != tabstart || stcol != "" {
					fmt.Fprintf(w, ", ")
				}
			}
		}

	}
	w.Flush()
}

func main() {
	var filename string
	var del string

	fmt.Print("",
		"\n■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■",
		"\n■■ DDL_Generator  ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■",
		"\n■■ 2021/08/02     ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■",
		"\n■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■",
		"\n\n\nInsert Delimiter : (Default = , ) ")
	fmt.Scanln(&del)
	if del == "" {
		del = ","
	}
	fmt.Print("\nInsert Data Filename : (Default = tables.dat ) ")
	fmt.Scanln(&filename)
	if filename == "" {
		filename = "tables.dat"
	}
	fmt.Print("",
		"\n■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■",
		"\n")

	flog, err := os.OpenFile("error.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Println(err)
	}
	mlogger := io.MultiWriter(os.Stdout, flog)
	log.SetOutput(mlogger)

	lines, err := readLines(filename)
	if err != nil {
		log.Fatalf("readLines: %s", err)
	}

	gts := new(genTable)
	gts.Collect(lines, del)
	gts.Check()
	gts.Generate()

	fmt.Print("■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■",
		"\nGenerate Done.",
		"\n■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■",
		"\n")
}
