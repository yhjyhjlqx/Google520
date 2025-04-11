#!/bin/bash
# Google520 - macOS 优化脚本
# 功能：更新Hosts以优化Google服务访问

# 配置信息
REPO_OWNER="yhjyhjlqx"
REPO_NAME="Google520"
HOSTS_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/main/hosts"
TEMP_HOSTS="/tmp/google520_hosts"
BACKUP_DIR="$HOME/.google520_backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 检查权限
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}错误：需要管理员权限${NC}"
        echo -e "请使用以下命令运行："
        echo -e "  sudo bash $0"
        exit 1
    fi
}

# 备份当前hosts
backup_hosts() {
    mkdir -p "$BACKUP_DIR"
    local backup_path="$BACKUP_DIR/hosts_$TIMESTAMP.bak"
    if cp /etc/hosts "$backup_path"; then
        echo -e "${YELLOW}已备份原hosts文件到：${NC}$backup_path"
    else
        echo -e "${RED}备份失败！${NC}"
        exit 1
    fi
}

# 下载最新配置
download_hosts() {
    echo -e "${YELLOW}下载最新Google520配置...${NC}"
    if curl -sSL "$HOSTS_URL" -o "$TEMP_HOSTS"; then
        echo -e "${GREEN}下载成功${NC}"
    else
        echo -e "${RED}下载失败！${NC}"
        exit 1
    fi
}

# 应用新配置
apply_hosts() {
    echo -e "\n${YELLOW}应用新配置...${NC}"
    {
        echo -e "\n# ===== Google520 配置 (更新于$TIMESTAMP) =====\n"
        cat "$TEMP_HOSTS"
        echo -e "\n# ===== 结束 Google520 配置 =====\n"
    } >> /etc/hosts
    
    # 验证行数
    original_lines=$(wc -l < "$TEMP_HOSTS")
    applied_lines=$(grep -c "Google520" /etc/hosts)
    
    if [ "$applied_lines" -ge "$original_lines" ]; then
        echo -e "${GREEN}配置应用成功${NC}"
    else
        echo -e "${RED}配置应用不完整！${NC}"
        restore_backup
    fi
}

# 恢复备份
restore_backup() {
    local latest_backup=$(ls -t "$BACKUP_DIR"/*.bak 2>/dev/null | head -1)
    if [ -f "$latest_backup" ]; then
        echo -e "\n${YELLOW}正在恢复备份...${NC}"
        if cp "$latest_backup" /etc/hosts; then
            echo -e "${GREEN}恢复成功${NC}"
        else
            echo -e "${RED}恢复失败！请手动检查/etc/hosts${NC}"
        fi
    else
        echo -e "${RED}未找到备份文件！${NC}"
    fi
    exit 1
}

# 刷新DNS
flush_dns() {
    echo -e "\n${YELLOW}刷新DNS缓存...${NC}"
    if killall -HUP mDNSResponder; then
        echo -e "${GREEN}DNS缓存已刷新${NC}"
    else
        echo -e "${RED}DNS刷新失败${NC}"
    fi
}

# 主流程
main() {
    echo -e "\n${GREEN}=== Google520 开始执行 ===${NC}"
    check_root
    backup_hosts
    download_hosts
    apply_hosts
    flush_dns
    echo -e "\n${GREEN}=== Google520 优化完成 ===${NC}"
    echo -e "提示：部分更改可能需要重启浏览器生效"
}

main
