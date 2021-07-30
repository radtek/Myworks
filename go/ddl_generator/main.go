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

func writeLines(lines []string, path string) error {
	file, err := os.Create(path)
	if err != nil {
		return err
	}
	defer file.Close()

	w := bufio.NewWriter(file)
	for _, line := range lines {
		fmt.Fprintln(w, line)
	}
	return w.Flush()
}

type genTable struct {
	schema, table_name, table_comment, option,
	column, datatype, defval, nullable, col_comment, pk []string
}

func (gt *genTable) collect(lines []string) *genTable {
	for _, line := range lines {
		delimit := regexp.MustCompile(`/`)
		sp := delimit.Split(line, -1)
		//fmt.Println(line)
		//fmt.Println(sp[1])

		gt.table_comment = append(gt.table_name, sp[0])
		gt.table_name = append(gt.table_name, sp[1])
		gt.col_comment = append(gt.col_comment, sp[2])
		gt.column = append(gt.column, sp[3])
		gt.pk = append(gt.pk, sp[4])
		gt.datatype = append(gt.datatype, sp[5])
		gt.defval = append(gt.defval, sp[6])
		gt.nullable = append(gt.nullable, sp[7])
		gt.schema = append(gt.schema, sp[8])
		gt.option = append(gt.option, sp[9])

	}

	return gt
}

func (gt *genTable) generate() {
	var nullcnt, tabstart int

	for rows := range gt.column {
		if rows == 0 || gt.table_name[rows-1] != gt.table_name[rows] {

			fmt.Print("\n\n\n------------------------------------------------------------------------",
				"\n--", gt.schema[rows]+"."+gt.table_name[rows], "\t", gt.table_comment[rows],
				"\n------------------------------------------------------------------------\n")
			fmt.Println("CREATE TABLE ", gt.schema[rows]+"."+gt.table_name[rows], " (")
			nullcnt = 0
			tabstart = rows
		}
		if gt.nullable[rows] == "NOT NULL" {
			nullcnt = nullcnt + 1
			nullstr := strconv.Itoa(nullcnt)
			if len(nullstr) < 2 {
				nullstr = "0" + nullstr
			}
			fmt.Println(gt.column[rows], "\t", gt.datatype[rows], "\t", gt.defval[rows], "\t", "CONSTRAINT CK_"+gt.table_name[rows]+"_"+nullstr, gt.nullable[rows])
		} else {
			fmt.Println(gt.column[rows], "\t", gt.datatype[rows], "\t", gt.defval[rows], "\t")
		}
		if len(gt.table_name) == rows+1 || gt.table_name[rows] != gt.table_name[rows+1] {
			ts := tabstart
			var pkarr []string
			for ts < rows+1 {
				if strings.Replace(gt.pk[ts], "\t| ", "", -1) != "" {
					pkarr = append(pkarr, gt.column[ts])
				}
				ts++
			}
			if len(pkarr) > 0 {
				fmt.Print(", CONSTRAINT PK_"+gt.table_name[tabstart], " PRIMARY KEY", "("+strings.Join(pkarr, ",")+")\n")
			}
			fmt.Printf(")")
			fmt.Println(gt.option[tabstart], ";")
			fmt.Println("COMMENT ON TABLE", gt.schema[tabstart]+"."+gt.table_name[tabstart], "IS '"+gt.table_comment[tabstart]+"';")

			for tabstart < rows+1 {
				fmt.Println("COMMENT ON COLUMN", gt.schema[tabstart]+"."+gt.table_name[tabstart]+"."+gt.column[tabstart], "IS '"+gt.col_comment[tabstart]+"';")
				tabstart++
			}
		} else {
			fmt.Printf(", ")
		}

	}
}

func main() {
	var filename string
	filename = "tables.dat"

	flog, err := os.OpenFile("debug.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
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
	gts.collect(lines)
	gts.generate()
	//

	// for i, line := range lines {
	// 	fmt.Println(i, line)
	// }

	// if err := writeLines(lines, "generated_ddl.sql"); err != nil {
	// 	log.Fatalf("writeLines: %s", err)
	// }
}
