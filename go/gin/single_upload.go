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
		file, _ := c.FormFile("file")
		log.Println(file.Filename)

		dst := "/home/lambda955/devcode/go/src/gintest/" + file.Filename
		err := c.SaveUploadedFile(file, dst)
		if err != nil {
			log.Println(err)
		} else {
			c.String(http.StatusOK, fmt.Sprintf("%s uploaded!", file.Filename))
		}
	})

	router.Run(":8080")
}
// curl -X POST http://localhost:8080/upload -F "file=@/Users/appleboy/test.zip" -H "Content-Type: multipart/form-data"
