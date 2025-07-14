CREATE TABLE `sys_hosts` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `ip_addr` varchar(32) NOT NULL COMMENT 'ip地址',
  `domain` varchar(100) NOT NULL COMMENT '域名',
  `hosts_group` varchar(32) NOT NULL DEFAULT 'default_group' COMMENT '组别',
  `remark` varchar(255) NOT NULL DEFAULT '' COMMENT '备注',
  `created_by` bigint DEFAULT '0' COMMENT '创建者',
  `created_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_by` bigint DEFAULT '0' COMMENT '更新者',
  `updated_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `ip_addr` (`ip_addr`,`domain`,`hosts_group`) USING BTREE
) COMMENT='hosts配置';