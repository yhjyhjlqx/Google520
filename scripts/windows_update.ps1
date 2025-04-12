<#
.SYNOPSIS
    Google520 - Windows 系统优化脚本
.DESCRIPTION
    自动更新Hosts以优化Google服务访问，支持自动备份和恢复
.EXAMPLE
    PS> .\windows_update.ps1
    以普通用户运行（会自动请求管理员权限）
#>

# 配置参数
$RepoOwner = "yhjyhjlqx"
$RepoName = "Google520"
$HostsUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/main/hosts"
$TempDir = Join-Path $env:TEMP "Google520"
$BackupDir = Join-Path $env:ProgramData "Google520\backups"
$SystemHosts = "$env:windir\System32\drivers\etc\hosts"
$LogFile = Join-Path $TempDir "update_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# 颜色定义
$Color = @{
    Success = 'Green'
    Error   = 'Red'
    Warning = 'Yellow'
    Info    = 'Cyan'
}

# 初始化环境
function Initialize-Environment {
    if (-not (Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir | Out-Null }
    if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir | Out-Null }
    
    Start-Transcript -Path $LogFile -Append | Out-Null
    Write-Host "=== Google520 Windows 优化工具 ===" -ForegroundColor $Color.Info
    Write-Host "项目地址: https://github.com/$RepoOwner/$RepoName"
    Write-Host "日志文件: $LogFile`n"
}

# 检查管理员权限
function Test-AdminPrivilege {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 备份当前Hosts
function Backup-Hosts {
    try {
        $backupPath = Join-Path $BackupDir "hosts_$(Get-Date -Format 'yyyyMMdd_HHmmss').bak"
        Copy-Item $SystemHosts $backupPath -Force
        Write-Host "[√] 已备份原hosts文件到: $backupPath" -ForegroundColor $Color.Success
        return $backupPath
    }
    catch {
        Write-Host "[×] 备份失败: $_" -ForegroundColor $Color.Error
        exit 1
    }
}

# 下载最新配置
function Download-Hosts {
    try {
        $tempHosts = Join-Path $TempDir "google520_hosts"
        Write-Host "[i] 下载最新Google520配置..." -ForegroundColor $Color.Info
        
        # 使用TLS 1.2协议确保安全下载
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest $HostsUrl -OutFile $tempHosts -UseBasicParsing
        
        if (Test-Path $tempHosts) {
            Write-Host "[√] 下载成功 ($((Get-Item $tempHosts).Length bytes)" -ForegroundColor $Color.Success
            return $tempHosts
        }
        else {
            throw "下载文件不存在"
        }
    }
    catch {
        Write-Host "[×] 下载失败: $_" -ForegroundColor $Color.Error
        exit 1
    }
}

# 应用新配置
function Apply-Hosts {
    param(
        [string]$TempHostsPath
    )
    
    try {
        Write-Host "`n[i] 应用新配置..." -ForegroundColor $Color.Info
        
        # 添加配置标记
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $divider = "#" * 40
        $configHeader = @"
`n$divider
# Google520 配置 (更新于 $timestamp)
$divider
"@
        $configFooter = @"
`n$divider
# 结束 Google520 配置
$divider
"@

        # 追加新配置
        Add-Content -Path $SystemHosts -Value $configHeader
        Get-Content $TempHostsPath | Add-Content -Path $SystemHosts
        Add-Content -Path $SystemHosts -Value $configFooter
        
        # 验证行数
        $originalLines = (Get-Content $TempHostsPath).Count
        $appliedLines = (Select-String -Path $SystemHosts -Pattern "Google520" -AllMatches).Matches.Count
        
        if ($appliedLines -ge $originalLines) {
            Write-Host "[√] 配置应用成功 (添加 $originalLines 行)" -ForegroundColor $Color.Success
        }
        else {
            throw "配置不完整 (预期 $originalLines 行，实际 $appliedLines 行)"
        }
    }
    catch {
        Write-Host "[×] 应用失败: $_" -ForegroundColor $Color.Error
        Restore-Backup
    }
}

# 恢复备份
function Restore-Backup {
    try {
        $latestBackup = Get-ChildItem $BackupDir -Filter "*.bak" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        
        if ($latestBackup) {
            Write-Host "[!] 正在恢复备份..." -ForegroundColor $Color.Warning
            Copy-Item $latestBackup.FullName $SystemHosts -Force
            Write-Host "[√] 已从备份恢复: $($latestBackup.Name)" -ForegroundColor $Color.Success
        }
        else {
            Write-Host "[×] 未找到有效备份！" -ForegroundColor $Color.Error
        }
    }
    catch {
        Write-Host "[×] 恢复失败: $_" -ForegroundColor $Color.Error
    }
    exit 1
}

# 刷新DNS缓存
function Flush-DNS {
    try {
        Write-Host "`n[i] 刷新DNS缓存..." -ForegroundColor $Color.Info
        ipconfig /flushdns | Out-Null
        Write-Host "[√] DNS缓存已刷新" -ForegroundColor $Color.Success
    }
    catch {
        Write-Host "[×] DNS刷新失败: $_" -ForegroundColor $Color.Error
    }
}

# 主流程
function Main {
    Initialize-Environment
    
    # 检查管理员权限
    if (-not (Test-AdminPrivilege)) {
        Write-Host "[!] 需要管理员权限" -ForegroundColor $Color.Warning
        Start-Process pwsh "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }

    # 执行流程
    $backupPath = Backup-Hosts
    $tempHosts = Download-Hosts
    Apply-Hosts -TempHostsPath $tempHosts
    Flush-DNS
    
    Write-Host "`n=== Google520 优化完成 ===" -ForegroundColor $Color.Success
    Write-Host "提示: 部分更改可能需要重启浏览器生效`n"
    Stop-Transcript
}

# 入口点
Main
