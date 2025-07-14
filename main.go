package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"homelab-butler/database"
	"homelab-butler/handlers"
)

func main() {
	// 初始化数据库连接
	if err := database.InitDB(); err != nil {
		log.Fatalf("数据库初始化失败: %v", err)
	}

	// 设置Gin模式
	gin.SetMode(gin.ReleaseMode)

	// 创建路由器
	r := gin.Default()

	// 添加CORS中间件
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		
		c.Next()
	})

	// 健康检查接口
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"message": "服务运行正常",
		})
	})

	// API路由组
	api := r.Group("/api/v1")
	{
		// 主机相关路由
		hosts := api.Group("/hosts")
		{
			hosts.GET("", handlers.GetHosts)           // 获取所有主机
			hosts.GET("/:id", handlers.GetHostByID)    // 根据ID获取主机
			hosts.POST("", handlers.CreateHost)        // 创建新主机
			hosts.PUT("/:id", handlers.UpdateHost)     // 更新主机信息
			hosts.DELETE("/:id", handlers.DeleteHost)  // 删除主机
		}
	}

	// 兼容原始"/hosts"路径的路由
	r.GET("/hosts", handlers.GetHosts)

	// 加载配置获取端口
	config, err := database.LoadConfig()
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	// 启动服务器
	port := fmt.Sprintf(":%d", config.Server.Port)
	log.Printf("服务器启动在端口 %s", port)
	log.Printf("API文档地址: http://localhost%s", port)
	log.Printf("健康检查: http://localhost%s/health", port)
	log.Printf("主机列表: http://localhost%s/hosts", port)
	
	if err := r.Run(port); err != nil {
		log.Fatalf("服务器启动失败: %v", err)
	}
} 