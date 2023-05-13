$ErrorActionPreference = "SilentlyContinue"

Write-Output "Persist Plugin Running..."

function helpmsg { 
    write-output "help message"
    Write-Host "####### This plugin is used To check for a big number of persistence places where malware can laverage #######"
    write-output "no arguments needed"
    }

if ($args -contains "-h") {
	helpmsg
	return
}

$currentDate = Get-Date   -Format "yyyyMMdd_HHmm"

$result = Join-Path -Path "." -ChildPath "Corners_$currentDate.txt"

$admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$seperator = "`n###################################################`n"


function print {
    param (
        [string]$Header,
        [Object]$data, 
		[string]$tech
    )
    
Out-File -FilePath $result -InputObject $Header -Encoding ASCII -Append
Out-File -FilePath $result -InputObject $tech -Encoding ASCII -Append
Out-File -FilePath $result -InputObject $seperator -Encoding ASCII -Append
Out-File -FilePath $result -InputObject $data -Encoding ASCII -Append
Out-File -FilePath $result -InputObject $seperator -Encoding ASCII -Append

}



# Registry Keys
$file = ".\artifacts\regkeys_persist.txt"

foreach ($key in Get-Content $file){
	$reg_key , $tech = $key.Split('-').Trim()
    $value = Get-ItemProperty -Path $reg_key
    print -Header $reg_key -data $value -tech $tech
}

# Registry values
$file = ".\artifacts\regvalues_persist.txt"

foreach ($key in Get-Content $file){
    


    $path, $valueName, $tech = $key.Split('-').Trim()
	$value =  Get-ItemProperty -Path $path -Name $valueName
	$Header = "$path`n$valueName"
    
	print -Header $Header -data $value.$valueName -tech $tech
}

# Startup folders Content
$tech = "Mittre Technique number T1547.001"
# Get the path to the current user's startup folder
$userStartupFolder = [Environment]::GetFolderPath('Startup')

# Get the path to the all users' startup folder
$allUsersStartupFolder = [Environment]::GetFolderPath('CommonStartup')

# Get the file names in the current user's startup folder
$userStartupFiles = Get-ChildItem -Path $userStartupFolder | Select-Object -ExpandProperty Name

# Get the file names in the all users' startup folder
$allUsersStartupFiles = Get-ChildItem -Path $allUsersStartupFolder | Select-Object -ExpandProperty Name

# Print the file names in both startup folders
	

	print -Header "Current user's startup folder files:" -data $userStartupFiles -tech $tech

	print -Header "All users' startup folder files:" -data $allUsersStartupFiles -tech $tech

# BITS job investigation
$tech = "Mittre Technique number T1197"
if (!$admin) {
	$res = Get-BitsTransfer | Select-Object -Property *
    	print -Header "BITS jobs:" -data $res -tech $tech
}else{
    $res = Get-BitsTransfer -AllUsers | Where-Object { $_.JobState -ne "Transferred" } | Select-Object -Property *
	  	print -Header "BITS jobs:" -data $res -tech $tech

}

# Active setup

$key = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\"
$tech = "Mittre Technique number T1547.014"
$keys = Get-ChildItem -Path $key
$Header = "Active SetUp"
	Out-File -FilePath $result -InputObject $Header -Encoding ASCII -Append

foreach ($item in $keys){
    $path_ = $item.name
    $path_ = $path_.Substring($path_.IndexOf("HKEY_LOCAL_MACHINE"))
    $path = $path_.Replace("HKEY_LOCAL_MACHINE", "HKLM:")   
	$value =  Get-ItemProperty -Path $path
	$value_ = $value.StubPath
	if ($value_) {
		$res = "$path`n$value_"
    	print -Header "" -data $res -tech $tech
	}
	

}

$res = gci -path "C:\Users\" -recurse -include *.lnk -ea SilentlyContinue | Select-String -Pattern "exe" | FL
$tech = "Mittre Technique number T1547.009"
print -Header "LNK Modification" -data $res -tech $tech

$key = "HKLM:\SYSTEM\CurrentControlSet\Services"
$tech = "Mittre Technique number T1543.003"
$res = ""
$entries = Get-ChildItem $key

foreach($entry in $entries){
	$path_ = $entry.name
    $path_ = $path_.Substring($path_.IndexOf("HKEY_LOCAL_MACHINE"))
    $path = $path_.Replace("HKEY_LOCAL_MACHINE", "HKLM:") 
	$prop = Get-ItemProperty $path 
	$name = $entry.Name
	$image = $prop.ImagePath
	$res += "$name`n_$image`n`n"
}

print -Header "Services and pathes" -data $res -tech $tech

$res = Get-WmiObject -Namespace root\subscription -Class __FilterToConsumerBinding
$tech = "Mittre Technique number T1546.003"

print -Header "WMI Subscription" -data $res -tech $tech

$res = $env:Path -split ';'
$tech = "Mittre Technique number T1574.007"
print -Header "Path variable (Hijacking techniques)" -data $res -tech $tech

$res = $env:COR_PROFILER
$tech = "Mittre Technique number T1574.012"

print ".Net CLR Libraries" -data $res -tech $tech

