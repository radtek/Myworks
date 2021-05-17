package main

import (
	"fmt"

	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()

	v1 := router.Group("/v1")
	{
		v1.POST("/login", func(c *gin.Context) {
			fmt.Println("loginEndpoint")
		})
		v1.POST("/submit", func(c *gin.Context) {
			fmt.Println("submitEndpoint")
		})
		v1.POST("/read", func(c *gin.Context) {
			fmt.Println("readEndpoint")
		})
	}

	v2 := router.Group("/v2")
	{
		v2.POST("/login", func(c *gin.Context) {
			fmt.Println("loginEndpoint")
		})
		v2.POST("/submit", func(c *gin.Context) {
			fmt.Println("submitEndpoint")
		})
		v2.POST("/read", func(c *gin.Context) {
			fmt.Println("readEndpoint")
		})
	}

	router.Run(":8080")
}

// [GIN-debug] POST   /v1/login                 --> main.main.func1 (3 handlers)
// [GIN-debug] POST   /v1/submit                --> main.main.func2 (3 handlers)
// [GIN-debug] POST   /v1/read                  --> main.main.func3 (3 handlers)
// [GIN-debug] POST   /v2/login                 --> main.main.func4 (3 handlers)
// [GIN-debug] POST   /v2/submit                --> main.main.func5 (3 handlers)
// [GIN-debug] POST   /v2/read                  --> main.main.func6 (3 handlers)
/* [GIN-debug] Listening and serving HTTP on :8080 */
