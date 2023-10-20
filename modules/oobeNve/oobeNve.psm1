<#
.SYNOPSIS
	The oobeNve Module is a collection of Functions related to the oobe Nested Virtualisation Environment

.DESCRIPTION
	The oobeNve Module files are broken up into a number of folders:

└───oobeNve
	|		oobeNve.psd1
	|		oobeNve.psm1
	|
	└───Private		<-- Helper functions and other code not advertised by module
	|
	└───Public		<-- Functions available via module
	|
	└───en-US		<-- Module help files

		Each Function within this module contains detailed Help information. 
		
		To view all Functions related to this module, type:

				Get-Command -Module oobeNve

		For further detail, type:
				
				Get-Help <function-name> -Full

		Feedback is always welcome, please contact your local oobe personnel if you have any requests/bugs/fixes.
#>

$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Recurse -ErrorAction SilentlyContinue )
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Recurse -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($File in @($Private + $Public))
{
	Try 
	{
		. $File.Fullname
	}
	Catch 
	{
		Write-Error -Message "Failed to import function $($File.Fullname): $($_.Exception.Message)"
	}
}

Export-ModuleMember -Function $Public.Basename