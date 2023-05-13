# Store the current value of $ErrorActionPreference
$oldErrorActionPreference = $ErrorActionPreference

# Set $ErrorActionPreference to "SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"

[CmdletBinding()]
    param (
        [String]$target,
        [String]$baseline,
        [string]$key
    )



function helpmsg {
    write-output "help message"
    Write-Host "####### This plugin is used To compare an persist plugin output from a suspected machine and a baseline one #######"
    write-output "-target path of the suspected"
    write-output "-baseline path of the baseline"
}

if ($args -contains "-h") {
    helpmsg
    return  
  }

#Check for existence of HASH or PATH
if (!($target)) {
    Write-Host ""
    Write-Host -ForegroundColor Yellow 'Missing the target file PATH, you must supply one. -target'
    Write-Host ""
    exit
}

if (!($baseline)) {
    Write-Host ""
    Write-Host -ForegroundColor Yellow 'Missing the baseline file PATH, you must supply one. -baseline'
    Write-Host ""
    exit
}

Write-Output "Corners_baseline Plugin Running(the green is in your baseline)...`n"

$file2 = (get-content $target)
$file1 = (get-content $baseline)


$differences = compare-object $file1 $file2

foreach ($difference in $differences) {
    if ($difference.InputObject -notmatch "_[0-9A-F]{5}$") {
       
        if ($difference.InputObject -notmatch "\{[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}\}") {
            if ($difference.InputObject -in $file1) {
                Write-Host $difference.InputObject -ForegroundColor Green
            }
            else {
                Write-Host $difference.InputObject -ForegroundColor Red
            }

        }else{
            $line = $difference.InputObject -replace "\{[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}\}",""
            if ((Select-String -Path $target -Pattern $line -SimpleMatch) -ne $null -and (Select-String -Path $baseline -Pattern $line -SimpleMatch) -ne $null) {
            
            }
            else {
                if ($difference.InputObject -in $file1) {
                    Write-Host $difference.InputObject -ForegroundColor Green
                }
                else {
                    Write-Host $difference.InputObject -ForegroundColor Red
                }
                
            }
        }
    
        
    }else{
        $line = $difference.InputObject -replace "_[0-9A-F]{5}$",""
        if ((Select-String -Path $target -Pattern $line -SimpleMatch) -ne $null -and (Select-String -Path $baseline -Pattern $line -SimpleMatch) -ne $null) {
            
        }
        else {
            if ($difference.InputObject -in $file1) {
                Write-Host $difference.InputObject -ForegroundColor Green
            }
            else {
                Write-Host $difference.InputObject -ForegroundColor Red
            }
            
        }
    }
}

# Restore the original value of $ErrorActionPreference
$ErrorActionPreference = $oldErrorActionPreference
