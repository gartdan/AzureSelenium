
function Extract-Zip
{
	param([string]$zipfilename, [string]$destination)

	if(test-path($zipfilename))
	{
		$shellApplication = new-object -com shell.application
		$zipPackage = $shellApplication.NameSpace($zipfilename)
		$destinationFolder = $shellApplication.NameSpace($destination)
		$destinationFolder.CopyHere($zipPackage.Items())
	}
}

function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}
function Enable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 1 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 1 -Force
    Stop-Process -Name Explorer
    Write-Host "IE Enhanced Security Configuration (ESC) has been enabled." -ForegroundColor Green
}
function Disable-UserAccessControl {
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000 -Force
    Write-Host "User Access Control (UAC) has been disabled." -ForegroundColor Green    
}


#hostname of this VM - change the domain if you are using Resource Manager or not
$hostName = $env:ComputerName.ToLower() + ".cloudapp.net"
$seleniumDestinationFolder = "c:\selenium\"
$driverDestinationFolder = "c:\selenium\drivers\"
$startupBat = "https://dcgresources.blob.core.windows.net/scripts/startup.bat"
$logFile = "c:\selenium\install.log"

Write-Output "Creating Directories"
[system.io.directory]::CreateDirectory($seleniumDestinationFolder)
[system.io.directory]::CreateDirectory($driverDestinationFolder)

Start-Transcript -path $logFile -append
Write-Output "Perfoming chocolatey install"
#Set-ExecutionPolicy ByPass
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

Write-Output "Downloading jar file"
$outFile = $seleniumDestinationFolder + "selenium-server-standalone.jar"
wget http://goo.gl/PJUZfa -OutFile $outFile 


Write-Output "Downloading IE Driver"
$IEDriverZip="IEDriverServer_x64_2.48.0.zip"
$IEDriverZipPath=$driverDestinationFolder + $IEDriverZip
$IEDriverUrl="http://selenium-release.storage.googleapis.com/2.48/" + $IEDriverZip
Invoke-WebRequest $IEDriverUrl -OutFile $IEDriverZipPath
Extract-Zip -zipfilename $IEDriverZipPath -destination $driverDestinationFolder 

Write-Output "Downloading Chrome Driver"
$chromeDriverZip = "chromedriver_win32.zip";
$chromeDriverZipPath = $driverDestinationFolder + $chromeDriverZip;
$chromeDriverUrl = "http://chromedriver.storage.googleapis.com/2.20/"+ $chromeDriverZip;
Invoke-WebRequest $chromeDriverUrl -OutFile $chromeDriverZipPath
Extract-Zip -zipfilename $chromeDriverZipPath -destination $driverDestinationFolder

Write-Output "Setting environment variables"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";" + $seleniumDestinationFolder, [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";" + $driverDestinationFolder, [EnvironmentVariableTarget]::Machine)

Write-Output "Setting firewall rules"
netsh advfirewall firewall add rule name="SeleniumIn" dir=in action=allow protocol=TCP localport=4444
netsh advfirewall firewall add rule name="SeleniumIn2" dir=in action=allow protocol=TCP localport=5555
netsh advfirewall firewall add rule name="SeleniumOut" dir=out action=allow protocol=TCP localport=4444
netsh advfirewall firewall add rule name="SeleniumOut2" dir=out action=allow protocol=TCP localport=5555
netsh advfirewall firewall add rule name="HttpIn" dir=in action=allow protocol=TCP localport=80
netsh advfirewall firewall add rule name="HttpIn2" dir=in action=allow protocol=TCP localport=443
netsh advfirewall firewall add rule name="PSRemoteIn" dir=in action=allow protocol=TCP localport=5985-5986

Write-Output "Disabling UAC"
Disable-UserAccessControl
Disable-InternetExplorerESC


Write-Output "Writing the startup file"
# Create Start.bat file 
$startupFile = @"
cd c:\selenium
java -jar selenium-server-standalone.jar -port 4444 -role hub -nodeTimeout 600
"@
$outFile = $seleniumDestinationFolder + "startnode.bat"
$startupFile > $outFile

#$outFile = $seleniumDestinationFolder + "startnode.bat"
#wget $startupBat -OutFile $outFile 
 
schtasks.exe /Create /SC ONLOGON /TN "StartSeleniumNode" /TR "cmd /c ""C:\selenium\startnode.bat"""

Write-Output "Installing packages" 
#install packages
choco install WindowsAzurePowershell -y
choco install googlechrome -y
choco install firefox -y
choco install phantomjs -y
choco install javaruntime -y

Write-Output "Restarting computer"
Stop-Transcript
Restart-Computer

