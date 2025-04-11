#!/bin/bash
# Google520 - Linux 通用优化脚本
# 支持：Ubuntu/Debian/CentOS/RHEL等主流发行版

# 配置信息
REPO_OWNER="yhjyhjlqx"
REPO_NAME="Google520"
HOSTS_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/main/hosts"
TEMP_HOSTS="/tmp/google520_hosts"
BACKUP_DIR="/var/lib/google520_backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 检查依赖
check_deps() {
    local missing=()
    for cmd in curl wget grep; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}正在安装依赖：${missing[*]}${NC}"
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y "${missing[@]}"
        elif command -v yum &> /dev/null; then
            yum install -y "${missing[@]}"
        else
            echo -e "${RED}不支持的包管理器！请手动安装：${missing[*]}${NC}"
            exit 1
        fi
    fi
}

# 检查权限
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}错误：需要root权限${NC}"
        echo -e "请使用："
        echo -e "  sudo bash $0"
        exit 1
    fi
}

# 备份当前hosts
backup_hosts() {
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"
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
    echo -e "${YELLOW}获取最新配置...${NC}"
    if command -v wget &> /dev/null; then
        wget -q "$HOSTS_URL" -O "$TEMP_HOSTS" || {
            echo -e "${RED}下载失败！${NC}"
            exit 1
        }
    else
        curl -sSL "$HOSTS_URL" -o "$TEMP_HOSTS" || {
            echo -e "${RED}下载失败！${NC}"
            exit 1
        }
    fi
    echo -e "${GREEN}下载成功${NC}"
}

# 应用配置
apply_hosts() {
    echo -e "\n${YELLOW}应用优化配置...${NC}"
    {
        echo -e "\n# ===== Google520 配置 (更新于$TIMESTAMP) =====\n"
        cat "$TEMP_HOSTS"
        echo -e "\n# ===== 结束 Google520 配置 =====\n"
    } >> /etc/hosts

    # 验证应用行数
    if [ $(grep -c "Google520" /etc/hosts) -lt 3 ]; then
        echo -e "${RED}配置应用异常！${NC}"
        restore_backup
    else
        echo -e "${GREEN}配置应用成功${NC}"
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
        echo -e "${RED}未找到有效备份！${NC}"
    fi
    exit 1
}

# 刷新DNS
flush_dns() {
    echo -e "\n${YELLOW}刷新DNS缓存...${NC}"
    if systemctl is-active --quiet systemd-resolved; then
        systemctl restart systemd-resolved
    elif systemctl is-active --quiet nscd; then
        systemctl restart nscd
    elif systemctl is-active --quiet dnsmasq; then
        systemctl restart dnsmasq
    else
        echo -e "${YELLOW}未找到已知的DNS缓存服务${NC}"
    fi
    echo -e "${GREEN}DNS更新完成${NC}"
}

# 主流程
main() {
    echo -e "\n${GREEN}=== Google520 Linux优化工具 ===${NC}"
    check_root
    check_deps
    backup_hosts
    download_hosts
    apply_hosts
    flush_dns
    echo -e "\n${GREEN}=== 优化完成 ===${NC}"
    echo -e "提示：部分更改可能需要重启应用"
}

main
