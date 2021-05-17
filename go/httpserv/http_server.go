package main

import (
	"fmt"
	"log"
	"net/http"
	"strings"
)

func defaultHandler(w http.ResponseWriter, r *http.Request) {
	r.ParseForm()

	fmt.Println("default : ", r.Form)
	fmt.Println("path : ", r.URL.Path)
	fmt.Println("param : ", r.Form["test_param"])

	for k, v := range r.Form {
		fmt.Println("key : ", k)
		fmt.Println("val : ", strings.Join(v, ""))
	}

	fmt.Fprintf(w, "Golang webServer Working")
}
func main() {
	http.HandleFunc("/", defaultHandler)
	err := http.ListenAndServe(":9090", nil)

	if err != nil {
		log.Fatal("ListenAndServe : ", err)
	} else {
		fmt.Println("ListenAndServe Started! -> Port(9090)")
	}
}
