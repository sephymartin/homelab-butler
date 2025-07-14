package handlers

import (
	"net/http"
	"strconv"
	"strings"
	"time"

	"homelab-butler/database"
	"homelab-butler/models"

	"github.com/gin-gonic/gin"
)

// GetHosts 获取所有主机列表
func GetHosts(c *gin.Context) {
	var hosts []models.Host
	
	// 获取查询参数
	hosts_groups := c.Query("hosts_groups")
	format := c.Query("format") // 支持 format=text 参数
	ipFirst := c.Query("ip_first") // 支持 ip_first=1 参数
	
	// 从数据库查询主机记录
	db := database.GetDB()
	query := db
	
	// 如果指定了组别，则按组别过滤
	if hosts_groups != "" {
		// 支持逗号分隔的多个组别
		groupList := strings.Split(hosts_groups, ",")
		// 清理空白字符
		for i, group := range groupList {
			groupList[i] = strings.TrimSpace(group)
		}
		query = query.Where("hosts_group IN ?", groupList)
	}
	
	if err := query.Find(&hosts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "查询主机列表失败",
			"message": err.Error(),
		})
		return
	}

	// 检查是否需要返回 text 格式
	acceptHeader := c.GetHeader("Accept")
	if format == "text" || acceptHeader == "text/plain" {
		// 返回 hosts 文件格式
		var hostsContent string
		for _, host := range hosts {
			if ipFirst == "1" {
				// 格式: 域名    IP地址
				hostsContent += host.Domain + "\t\t" + host.IPAddr + "\n"
			} else {
				// 默认格式: IP地址    域名
				hostsContent += host.IPAddr + "\t\t" + host.Domain + "\n"
			}
		}
		
		c.Header("Content-Type", "text/plain; charset=utf-8")
		c.String(http.StatusOK, hostsContent)
		return
	}

	// 默认返回 JSON 格式
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "获取主机列表成功",
		"data":    hosts,
		"total":   len(hosts),
	})
}

// GetHostByID 根据ID获取主机信息
func GetHostByID(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "无效的主机ID",
			"message": err.Error(),
		})
		return
	}

	var host models.Host
	db := database.GetDB()
	if err := db.First(&host, uint(id)).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "主机不存在",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "获取主机信息成功",
		"data":    host,
	})
}

// CreateHostRequest 创建主机请求结构
type CreateHostRequest struct {
	IPAddr     string `json:"ip_addr" binding:"required"`
	Domain     string `json:"domain" binding:"required"`
	HostsGroup string `json:"hosts_group"`
	Remark     string `json:"remark"`
}

// CreateHost 创建新主机记录
func CreateHost(c *gin.Context) {
	var req CreateHostRequest
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "请求参数无效",
			"message": err.Error(),
		})
		return
	}

	// 设置默认组别
	if req.HostsGroup == "" {
		req.HostsGroup = "default_group"
	}

	// 创建主机对象
	host := models.Host{
		IPAddr:      req.IPAddr,
		Domain:      req.Domain,
		HostsGroup:  req.HostsGroup,
		Remark:      req.Remark,
		CreatedBy:   getUserID(c),
		CreatedTime: time.Now(),
		UpdatedBy:   getUserID(c),
		UpdatedTime: time.Now(),
	}

	db := database.GetDB()
	if err := db.Create(&host).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "创建主机记录失败",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"code":    201,
		"message": "创建主机记录成功",
		"data":    host,
	})
}

// UpdateHostRequest 更新主机请求结构
type UpdateHostRequest struct {
	IPAddr     string `json:"ip_addr"`
	Domain     string `json:"domain"`
	HostsGroup string `json:"hosts_group"`
	Remark     string `json:"remark"`
}

// UpdateHost 更新主机信息
func UpdateHost(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "无效的主机ID",
			"message": err.Error(),
		})
		return
	}

	var host models.Host
	db := database.GetDB()
	
	// 检查主机是否存在
	if err := db.First(&host, uint(id)).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "主机不存在",
			"message": err.Error(),
		})
		return
	}

	var req UpdateHostRequest
	// 绑定更新数据
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "请求参数无效",
			"message": err.Error(),
		})
		return
	}

	// 更新字段
	if req.IPAddr != "" {
		host.IPAddr = req.IPAddr
	}
	if req.Domain != "" {
		host.Domain = req.Domain
	}
	if req.HostsGroup != "" {
		host.HostsGroup = req.HostsGroup
	}
	if req.Remark != "" {
		host.Remark = req.Remark
	}
	
	// 设置更新信息
	host.UpdatedBy = getUserID(c)
	host.UpdatedTime = time.Now()

	// 更新记录
	if err := db.Save(&host).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "更新主机信息失败",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "更新主机信息成功",
		"data":    host,
	})
}

// DeleteHost 删除主机记录
func DeleteHost(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "无效的主机ID",
			"message": err.Error(),
		})
		return
	}

	db := database.GetDB()
	
	// 硬删除
	if err := db.Delete(&models.Host{}, uint(id)).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "删除主机记录失败",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "删除主机记录成功",
	})
}

// getUserID 从上下文中获取用户ID
func getUserID(c *gin.Context) int64 {
	// 从JWT token或session中获取用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		return 0 // 默认用户ID
	}
	
	if id, ok := userID.(int64); ok {
		return id
	}
	
	return 0
} 