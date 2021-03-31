# IN Powershell TERM # 
# xcopy.ps1 -source c:\temp\sorc -destination c:\temp\dest -log c:\temp\xcopy.log
# IN CMD # 
# powershell.exe -ExecutionPolicy Bypass xcopy.ps1 -source c:\temp\sorc -destination c:\temp\dest -log c:\temp\xcopy.log

# Parameter area #######################################################################
[CmdletBinding()]
Param(
   [Parameter(Mandatory=$True)]
   [string]$source,
   [Parameter(Mandatory=$True)]
   [String]$destination,
   [Parameter(Mandatory=$False)]
   [String]$log
)
if (!($log)) {
    $log = "c:\temp\xcopy.log"
}
$Error.Clear()

# Start Script ########################################################################
$cp_list=(gci $source)

foreach($eachsource in $cp_list)
{
	Write-Host $eachsource
	$name=($eachsource.Name)
	
	$name | Out-File -FilePath $log -Append 

	if ($eachsource.Mode.Trim('-') -eq 'd')
	{
		&xcopy /I /D /E /C /H /K /O /Y $source\$name $destination\$name | Out-File -FilePath $log -Append 
	}
	else
	{
		&xcopy /I /D /E /C /H /K /O /Y $source\$name $destination\ | Out-File -FilePath $log -Append 
	}
}
"$Error" | Out-File $log -Append