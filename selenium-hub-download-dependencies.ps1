Set-ExecutionPolicy ByPass
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

$seleniumDestinationFolder = "c:\selenium\"
$driverDestinationFolder = "c:\selenium\drivers\"

[system.io.directory]::CreateDirectory($seleniumDestinationFolder)
[system.io.directory]::CreateDirectory($driverDestinationFolder)

$seleniumServerDestination = $seleniumDestinationFolder + "selenium-server-standalone.jar"
wget http://goo.gl/PJUZfa -OutFile $seleniumServerDestination




$IEDriverZip="IEDriverServer_x64_2.48.0.zip"
$IEDriverZipPath=$driverDestinationFolder + $IEDriverZip
$IEDriverUrl="http://selenium-release.storage.googleapis.com/2.48/" + $IEDriverZip
Invoke-WebRequest $IEDriverUrl -OutFile $IEDriverZipPath
Extract-Zip -zipfilename $IEDriverZipPath -destination $driverDestinationFolder

$chromeDriverZip = "chromedriver_win32.zip";
$chromeDriverZipPath = $driverDestinationFolder + $chromeDriverZip;
$chromeDriverUrl = "http://chromedriver.storage.googleapis.com/2.20/"+ $chromeDriverZip;
Invoke-WebRequest $chromeDriverUrl -OutFile $chromeDriverZipPath
Extract-Zip -zipfilename $chromeDriverZipPath -destination $driverDestinationFolder

$seleniumDestinationFolder = "c:\selenium\"
$driverDestinationFolder = "c:\selenium\drivers\"
$newPath = $env:Path + ";" + $seleniumDestinationFolder + ";" + $driverDestinationFolder
[Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::Machine)