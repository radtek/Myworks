package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()

	router.POST("/upload", func(c *gin.Context) {
		form, _ := c.MultipartForm()
		files := form.File["upload[]"]

		for _, file := range files {
			log.Println("Upload Requested : " + file.Filename)

			dst := "/home/lambda955/devcode/go/src/gintest/" + file.Filename
			err := c.SaveUploadedFile(file, dst)
			if err != nil {
				log.Println(err)
			} else {
				log.Println(file.Filename + " Uploaded!")
			}
		}
		c.String(http.StatusOK, fmt.Sprintf("%d files uploaded!\n", len(files)))
	})
	router.Run(":8080")
}
