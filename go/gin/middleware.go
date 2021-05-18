package main

import (
	"fmt"
	"io"
	"os"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	// Disable Console(Log) Color
	gin.DisableConsoleColor() // Always on ForceConsoleColor()

	// Logging to a file.
	f, _ := os.Create("gin.log")
	gin.DefaultWriter = io.MultiWriter(f)
	// When Logging Both, Log and Console
	// gin.DefaultWriter = io.Multiwriter(f, os.Stdout)

	// In gin.Default(), included Logger/Recovery option.
	// router := gin.Default()

	// Non-Default Middleware
	router := gin.New() // Blank gin
	router.Use(gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {

		// Use Custom Logger Format
		return fmt.Sprintf("%s - [%s] \"%s %s %s %d %s \"%s\" %s\"\n",
			param.ClientIP,
			param.TimeStamp.Format(time.RFC1123),
			param.Method,
			param.Path,
			param.Request.Proto,
			param.StatusCode,
			param.Latency,
			param.Request.UserAgent(),
			param.ErrorMessage,
		)
	}))
	// Automatic Recovery option when meet crash or 500 status.
	router.Use(gin.Recovery())

	router.GET("/ping", func(c *gin.Context) {
		c.String(200, "pong")
	})

	router.Run(":8080")
}
