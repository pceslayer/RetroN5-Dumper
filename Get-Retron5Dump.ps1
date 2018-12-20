#################################
#RetroN 5 ROM Dump Script
#Version 1.2
#Written by pCeSlAyEr
#################################
##Supress error messages to console##
$ErrorActionPreference = 'SilentlyContinue'

##Query output directory existance##
$outExists = (Get-ChildItem -dir | where {$_.name -match 'out'} | select Exists).Exists

##If output directory not exist then create##
if(!($outExists)){
	Write-Host "Out directory doesn't Exist... Creating..." -Foregroundcolor Yellow
	New-Item -ItemType directory -Name 'out' | out-null
	Start-Sleep 3
	clear
}

##Main menu select function##
function menuSelect{
	Write-Host '==============Retron 5 ROM Dump=============='
	Write-Host '1. Dump Rom - Enter Title Manually'
	Write-Host '2. Dump Rom - NoIntro Title Automatic'
	Write-Host '3. Quit and Exit'
	
	$selection = Read-Host 'Please make a selection'
	
	switch($selection){
		
		'1'{
			Write-Host 'You selected Dump Rom - Enter Title Manually' -Foregroundcolor magenta
			Write-Host ''
			dumpROM
		}
		'2'{
			Write-Host 'You selected Dump Rom - NoIntro Title Automatic' -Foregroundcolor magenta
			write-host ''
			dumpROMnoIntro
		}
			
		'3'{
			Write-Host 'Quitting...'
			return 
		}
		
		default{ 
			Write-Host 'Please select a valid option...' -Foregroundcolor yellow
			Write-Host ''
			Write-Host ''
			menuSelect
		}
	}
}

##Function to dump ROM with manually entered Title/Name##
function dumpROM{
	Write-Host 'Enter title of game you are dumping' -foregroundcolor cyan
	
	##Capture name input from user##
	[string]$gameTitle = Read-Host "Enter Title"

	##Call ADB.exe to copy dump.* ROM from Retron 5 to out directory##
	.\adb.exe pull /mnt/ram/. ./out

	##Import dump.* ROM file info to variable##
	$dump = Get-ChildItem ./out/dump.*
	
	##File dump.* does not exit throw error!##
	if(!($dump)){
		Write-Host ''
		Write-Host '!!!!!!!!!!!!!!!!!!!!' -Foregroundcolor red -Backgroundcolor black
		Write-Host 'ROM dump not found, please verify ADB is installed and can connect to your Retron 5.' -Foregroundcolor red -Backgroundcolor black
	}
	
	##File dump.part detected throw error/warning and delete##
	elseif($dump.Name -eq 'dump.part'){
		Write-Host ''
		Write-Host '!WARNING! Partial dump found!' -Foregroundcolor yellow -Backgroundcolor black
		Write-Host 'Disable Fast Cartridgle Loading and re-insert game cartridge in your Retron 5.' -Foregroundcolor yellow -Backgroundcolor black	
		
		Remove-Item $dump
	}
	
	##File dump.* exists so attempt to rename file##
	else{
		##Create game name based on user input and original file extension##
		[string]$extension = $dump.extension
		[string]$gameName = $gameTitle + $Extension
	
		##Rename dump.* to manually entered name##
		Rename-Item $dump -NewName $gameName

		Write-Host "$gameName ROM has been dumped successfully!"
	}
	
	##Call exitQuestion function##
	exitQuestion
}

##Function to dump ROM with automatic Title/Name based on NoIntro data##
function dumpROMnoIntro{
	Write-Host 'Insert cartridge into Retron 5 and press Enter to continue...' -foregroundcolor yellow
	pause

	Write-Host 'Copying ROM from Retron 5 and Renaming...' -foregroundcolor cyan
	
	##Call ADB.exe to copy dump.* ROM from Retron 5 to out directory##
	.\adb.exe pull /mnt/ram/. ./out

	##Import dump.* ROM file info to variable##
	$dump = Get-ChildItem ./out/dump.*
	
	##File dump.* does not exit throw error!##
	if(!($dump)){
		Write-Host ''
		Write-Host '!!!!!!!!!!!!!!!!!!!!' -Foregroundcolor red -Backgroundcolor black
		Write-Host 'ROM dump not found, please verify ADB is installed and can connect to your Retron 5.' -Foregroundcolor red -Backgroundcolor black
	}
	
	##File dump.part detected throw error/warning and delete##
	elseif($dump.Name -eq 'dump.part'){
		Write-Host ''
		Write-Host '!WARNING! Partial dump found!' -Foregroundcolor yellow -Backgroundcolor black
		Write-Host 'Disable Fast Cartridgle Loading and re-insert game cartridge in your Retron 5.' -Foregroundcolor yellow -Backgroundcolor black	
		
		Remove-Item $dump
	}
	
	##File dump.* exists so attempt to rename##
	else{
		##Get hashes for dump.* ROM##
		$sha1 = Get-FileHash $dump.FullName -Algorithm SHA1
		$md5 = Get-FileHash $dump.FullName -Algorithm MD5
		[string]$sha1Hash = $sha1.hash
		[string]$md5Hash = $md5.hash
		
		##Compare hashes to CSV for match##
		[string]$gameTitle = $csv.Where({($PSItem.sha1 -eq $sha1Hash) -and ($PSItem.md5 -eq $md5Hash)}).Name
		
		##No match Found for dump.NES ROM. Try to strip header and match##
		if(!($gameTitle) -and ($dump.Extension -eq '.NES')){
			Write-Host ''
			Write-Host 'No match was found in NoIntro CSV...' -Foregroundcolor red
			Write-Host 'Stripping header and comparing to NoIntro CSV...' -Foregroundcolor yellow
			
			##Create paths to create headerless temp.nes file##
			$directory = $dump.DirectoryName
			$extension = $dump.Extension
			$tempOut = $directory + '\temp' + $extension
			
			##Convert dump.nes to hex, remove first 16bytes and output to temp.nes##
			$bytes = [System.IO.File]::ReadAllBytes($dump)
			$bytesToTrim = 16
			$trimmedBytes = $bytes[$bytesToTrim..($bytes.length - 1)]
			[System.IO.File]::WriteAllBytes($tempOut, $trimmedBytes)
			
			##Import headerless temp.nes file info to variable##
			$temp = Get-ChildItem ./out/temp.*
		
			##Get hashes for headerless temp.nes##
			$tempsha1 = Get-FileHash $temp.FullName -Algorithm SHA1
			$tempmd5 = Get-FileHash $temp.FullName -Algorithm MD5
			[string]$tempsha1Hash = $tempsha1.hash
			[string]$tempmd5Hash = $tempmd5.hash
			
			##Compare hashes of headerless NES rom to CSV for match##
			[string]$tempGameTitle = $csv.Where({($PSItem.sha1 -eq $tempsha1Hash) -and ($PSItem.md5 -eq $tempmd5Hash)}).Name
			
			##No match for headerless ROM found so ask if you want manual input##
			if(!($tempGameTitle)){
				Write-Host ''
				Write-Host 'No match was found in NoIntro CSV even without header...' -Foregroundcolor red
				Write-Host ''				
				Write-Host '!WARNING! ROM dump will be deleted if No is selected.' -Foregroundcolor yellow
				Write-Host 'Do you want to manually name this ROM?' -Foregroundcolor cyan
				Write-Host "Enter Y for Yes / N for No" -foregroundcolor magenta
				$answer = Read-Host "Y/N"
				
				##If Yes ask for manual input##
				if($answer -eq 'Y'){
					Write-Host ''
					Write-Host 'Enter title of game you are dumping' -foregroundcolor cyan
					
					##Capture name input from user and add original file extension##
					[string]$gameTitle = Read-host "Enter Title"
					[string]$extension = $dump.extension
					[string]$gameName = $gameTitle + $Extension
					
					##Rename dump.nes to manually entered name##
					Rename-Item $dump -NewName $gameName
		
					Write-Host "$gameName ROM has been dumped successfully!"
					
					##Delete temp.nes file##
					Remove-Item $temp
				}
				
				##If anything other than Yes for manual input##
				else{
					##Delete both temp.nes and dump.nes##
					Remove-Item $dump
					Remove-Item $temp
				}
			}
			
			##Match was found for headerless temp.nes##
			else{
				Write-Host "$tempGameTitle was matched without header. Temp files will be Deleted." -Foregroundcolor cyan

				##Rename dump.nes to name found in CSV that matched headerless temp.nes file##
				Rename-Item $dump -NewName $tempGameTitle
				
				##Delete temp.nes file##
				Remove-Item $temp

				Write-Host "$tempGameTitle ROM has been dumped successfully!" -Foregroundcolor green
			}			
		}
		
		##No match Found for dump.* ROM and not NES file so ask if you want manual input##
		elseif(!($gameTitle) -and ($dump.Extension -ne '.NES')){
			Write-Host ''
			Write-Host 'No match was found in NoIntro CSV...' -Foregroundcolor red -Backgroundcolor black
			Write-Host ''				
			Write-Host '!WARNING! ROM dump will be deleted if No is selected.' -Foregroundcolor yellow
			Write-Host 'Do you want to manually name this ROM?' -Foregroundcolor cyan
			Write-Host "Enter Y for Yes / N for No" -foregroundcolor magenta
			
			$answer = Read-Host "Y/N"
			
			##If Yes ask for manual input##
			if($answer -eq 'Y'){
				Write-Host ''
				Write-Host 'Enter title of game you are dumping' -foregroundcolor cyan
				
				##Capture name input from user and add original file extension##
				[string]$gameTitle = Read-host "Enter Title"
				[string]$extension = $dump.extension
				[string]$gameName = $gameTitle + $Extension
		
				##Rename ROM to manually entered name##
				Rename-Item $dump -NewName $gameName
		
				Write-Host "$gameName ROM has been dumped successfully!"
			}
			
			##If anything other than Yes for manual input##
			else{ 
				##Delete dump.* ROM##
				Remove-Item $dump
			}
		}
		
		##Match was found for dump.^ ROM in NoIntro CSV##
		else{
			##Renamp dump.* ROM to matching name from NoIntro CSV##
			Rename-Item $dump -NewName $gameTitle
			
			Write-Host "$gameTitle ROM has been dumped successfully!"
		}
	}
	
	##Call exitQuestion function##
	exitQuestion
}
	
##Do you want to dump another? Function##
function exitQuestion{
	Write-Host ''
	Write-Host ''
	Write-Host "Do you want to dump another?" -foregroundcolor cyan
	Write-Host "Enter Y for Yes / N for No" -foregroundcolor magenta
	$answer = Read-Host "Y/N"
	
	if($answer -eq 'Y'){
		clear
		menuSelect 
	}
	elseif($answer -eq 'N'){ break }
	else{ exitQuestion }
}

##Import CSV of meged NoIntro dats##
$csv = import-csv "noIntroList.csv"

##Call menuSelect function##
menuSelect
