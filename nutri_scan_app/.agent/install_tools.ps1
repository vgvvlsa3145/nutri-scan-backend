$zip = "C:\Users\Sweet.Vellyn_Vgvvlsa\Downloads\cmdline_tools_latest.zip"
$dest = "C:\Users\Sweet.Vellyn_Vgvvlsa\AppData\Local\Android\sdk\cmdline-tools"
$temp = "$dest\temp"
$final = "$dest\latest"

Write-Host "Checking for existing latest..."
If (Test-Path $final) { Remove-Item $final -Recurse -Force }

Write-Host "Extracting..."
Expand-Archive -Path $zip -DestinationPath $temp -Force

Write-Host "Moving..."
Move-Item -Path "$temp\cmdline-tools" -Destination $final

Write-Host "Cleaning up..."
Remove-Item $temp -Recurse -Force
Write-Host "Done."
