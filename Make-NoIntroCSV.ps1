$dats = get-childitem "*.dat"

$pool = @()
$datCount = ($dats).count

Write-Host "$datCount NoIntro.dat files found." -foregroundcolor cyan

foreach ($dat in $dats){
	[string]$datName = $dat.Name
	
	Write-Host "Processing $datName..." -foregroundcolor magenta
	[xml]$xml = Get-Content $dat

	foreach($game in $xml.ChildNodes.game.rom){
		[string]$name = $game.name
		#[string]$size = $game.size
		[string]$crc = $game.crc
		[string]$md5 = $game.md5
		[string]$sha1 = $game.sha1
		#[string]$status = $game.status

		$cart = New-Object PSObject

		$cart | Add-Member NoteProperty -Name "name" -value $name
		#$cart | Add-Member NoteProperty -Name "size" -value $size
		$cart | Add-Member NoteProperty -Name "crc" -value $crc
		$cart | Add-Member NoteProperty -Name "md5" -value $md5
		$cart | Add-Member NoteProperty -Name "sha1" -value $sha1
		#$cart | Add-Member NoteProperty -Name "status" -value $status

		$pool += $cart
	}
}

$pool | Export-CSV noIntroList.csv -NoTypeInformation

Write-Host "noIntroList.csv has been created." -foregroundcolor green

pause
