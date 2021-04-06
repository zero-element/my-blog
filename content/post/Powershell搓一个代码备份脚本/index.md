---
title: "Powershell搓一个代码备份脚本"
date: 2020-11-25
description: "学了下powershell，魔改了个备份脚本玩"
categories: [
  "折腾"
]
---

直接上代码

```powershell
echo "Backup Starting..."
$desDir = "Z:\backup\Code"
$sourceDir = "E:\Code"
$logDetail = "E:\log\"
$timeFile = $logDetail + "LastTime.txt"
$blackList = @("node_modules", "cache") # ignore
$nowTimeBegin = Get-Date
$nowData = $nowTimeBegin.Date

$fileContent = New-Object System.Collections.Generic.List[System.Object]
if (Test-Path $timeFile) {
    Get-Content $timeFile | ForEach-Object { $fileContent.Add($_) }
    $lastTimeBegin = [datetime]::ParseExact($fileContent[0], 'MM/dd/yyyy HH:mm:ss', $null)
    $lastTimeEnd = [datetime]::ParseExact($fileContent[1], 'MM/dd/yyyy HH:mm:ss', $null)
}
else {
    $lastTimeBegin = $nowTimeBegin # 第一次备份 所有文件要包含 Begin拉到现在
    $lastTimeEnd = $nowTimeBegin
}

if ( [System.Diagnostics.EventLog]::SourceExists("logFile") -eq 0) {
    [System.Diagnostics.EventLog]::CreateEventSource("logFile", "logFileS")
}
$log = Get-EventLog -List | Where-Object { $_.Log -eq "logFileS" }
$log.Source = "logFile"
Set-Location $sourceDir
$log.WriteEntry($nowData.ToShortDateString() + "backup started", "SuccessAudit")
$i = 0
$DetailRecord = New-Object System.Text.StringBuilder
[void] $DetailRecord.AppendLine([System.String]::Concat($nowData.ToShortDateString(), " backup details"))
[IO.Directory]::EnumerateFiles($sourceDir, "*", 1) | ForEach-Object { Get-Item $_ -Force } | # Get-Item是按batch执行，foreach会阻塞；这样写比较快
Where-Object { # 过滤ignore
    $file = $_
    ($null -eq ($blackList | Where-Object { $file.DirectoryName -match $_ }))
} |
Where-Object { (($_.LastWriteTime -gt $lastTimeEnd) -or ($_.LastWriteTime -lt $lastTimeBegin)) -and ($_.Mode.contains("a") -and !$_.Mode.contains("l")) } | # 早于上次备份开始或者晚于上次备份结束即为未备份文件 a为文件
ForEach-Object {
    $file = $_
    $newfold = [string]($file.DirectoryName).Replace($sourceDir, $desDir)
    if ([system.IO.Directory]::Exists($newfold) -eq 0) {
        $null = mkdir $newfold
    }
    $null = Copy-Item $file.FullName -Destination $newfold 
    try {
        $file.LastWriteTime = Get-Date
    }
    catch { # 只读文件
        $file.Attributes -= "ReadOnly"
        $file.LastWriteTime = Get-Date
        $file.Attributes += "ReadOnly"
    }
    $i++
    $msg = "{0}: {1} has been backup to {2}" -f $nowData.ToShortDateString(), $file.FullName, $newfold
    Write-Output $msg
    [void] $DetailRecord.AppendLine($msg)
    $newfold = ""
    $msg = ""
}
$nowTimeEnd = Get-Date
$logDetail = $logDetail + (Get-Date).Date.ToShortDateString().Replace("/", "").Replace("-", "") + ".log"
if ([System.IO.File]::Exists($logDetail) -gt 0) {
    [System.IO.File]::Delete($logDetail)
}
[System.IO.File]::AppendAllText($logDetail, $DetailRecord.ToString()) 
$email_smtp_host = "****"
$email_smtp_port = 587
$smtp = New-Object System.Net.Mail.SmtpClient($email_smtp_host, $email_smtp_port)
$smtp.EnableSsl = $true 
$UserName = "****@****.com"
$Password = "****"
$smtp.Credentials = New-Object System.Net.NetworkCredential($UserName, $Password)
[void] $smtp.Send("sender@****.com", "reciver@****.com", [System.String]::Concat($nowData.ToShortDateString(), " backup details(", $i, ")"), $DetailRecord.ToString())

$log.WriteEntry([System.String]::Concat($nowData.ToShortDateString(), " backup completed.", $i, " files have been copied to ", $desDir, ". Details in :", $logDetail, "."), "SuccessAudit")
Write-Output "$nowTimeBegin" "$nowTimeEnd" | Out-File $timeFile
Exit
```

PS: 备份了code但没备份blog，今天手滑把博客给扬了，手动重建ing（悲

