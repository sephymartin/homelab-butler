package models

import (
	"time"
)

// Host 主机信息模型
type Host struct {
	ID          uint      `json:"id" gorm:"primaryKey;autoIncrement;comment:ID"`
	IPAddr      string    `json:"ip_addr" gorm:"not null;size:32;comment:ip地址;uniqueIndex:idx_ip_domain_group"`
	Domain      string    `json:"domain" gorm:"not null;size:100;comment:域名;uniqueIndex:idx_ip_domain_group"`
	HostsGroup  string    `json:"hosts_group" gorm:"not null;size:32;default:default_group;comment:组别;uniqueIndex:idx_ip_domain_group"`
	Remark      string    `json:"remark" gorm:"not null;size:255;default:'';comment:备注"`
	CreatedBy   int64     `json:"created_by" gorm:"default:0;comment:创建者"`
	CreatedTime time.Time `json:"created_time" gorm:"not null;default:CURRENT_TIMESTAMP;comment:创建时间"`
	UpdatedBy   int64     `json:"updated_by" gorm:"default:0;comment:更新者"`
	UpdatedTime time.Time `json:"updated_time" gorm:"not null;default:CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;comment:更新时间"`
}

// TableName 指定表名
func (Host) TableName() string {
	return "sys_hosts"
} 