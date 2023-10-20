<#
.SYNOPSIS
	The Nve Module is a collection of Functions related to the Nested Virtualisation Environment

.DESCRIPTION
	The Nve Module files are broken up into a number of folders:

└───Nve
	|		Nve.psd1
	|		Nve.psm1
	|
	└───Private		<-- Helper functions and other code not advertised by module
	|
	└───Public		<-- Functions available via module
	|
	└───en-US		<-- Module help files

		Each Function within this module contains detailed Help information. 
		
		To view all Functions related to this module, type:

				Get-Command -Module Nve

		For further detail, type:
				
				Get-Help <function-name> -Full

		Feedback is always welcome, please contact your local admin personnel if you have any requests/bugs/fixes.
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