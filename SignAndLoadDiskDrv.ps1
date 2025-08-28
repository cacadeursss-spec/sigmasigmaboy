# 1. Variables
$DriverPath = "C:\ProgramData\DriverVault\diskdrv.sys"
$CertName = "DiskDrvCert"
$CertFile = "C:\DiskDrvCert.cer"
$ServiceName = "diskdrv"

# 2. Create a self-signed certificate
$cert = New-SelfSignedCertificate -Type CodeSigningCert `
    -Subject "CN=$CertName" `
    -KeyExportPolicy Exportable `
    -CertStoreLocation "Cert:\LocalMachine\My"

# 3. Export certificate for trust
Export-Certificate -Cert $cert -FilePath $CertFile

# 4. Import into Trusted Root CA
Import-Certificate -FilePath $CertFile -CertStoreLocation "Cert:\LocalMachine\Root"

# 5. Sign the driver
Set-AuthenticodeSignature -FilePath $DriverPath -Certificate $cert

# 6. Remove existing SC service if exists
if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
    sc.exe delete $ServiceName
    Start-Sleep -Seconds 2
}

# 7. Create new SC service pointing to driver
sc.exe create $ServiceName type= kernel start= auto binPath= "$DriverPath"

# 8. Start the driver
sc.exe start $ServiceName

# 9. Confirm driver status
Get-WmiObject Win32_SystemDriver | Where-Object {$_.Name -eq $ServiceName} | Select Name, State, Started
