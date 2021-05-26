# Ping with Timestamp in Powershell
ping -t 128.11.2.53 | ForEach {"{0} - {1}" -f (Get-Date),$_} > tes_pinglog.log
