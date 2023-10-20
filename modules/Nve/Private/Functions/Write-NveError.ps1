<#
.SYNOPSIS
  The Write-NveError function is used to correct the broken error handling within Azure portal's error output view.

.DESCRIPTION
  The error output view of the Automation Account is kind of broken in PowerShell v7 (preview). 
  v7 uses $ErrorView = 'ConciseView' by default, and this does not display well in the portal. Nor does 'NormalView' for that matter.

  This function is used to add ErrorDetails to the ErrorRecord and rethrow the Exception down the stack.
  Any Runbooks that use this method should encapsulate the code with a try block and call Write-Error in the final catch block.
  ie:

  try{
      Some-FunctionThatUsesWriteNveAzError
  }
  catch {
      Write-Error $PSItem
  }

  This will push the final ErrorDetails property to the Azure portal's output view correctly.

.NOTES
  Author: Ryan Shaw

.EXAMPLE
  try {
    Some-FunctionThatCausesAnException
  }
  catch {
    Write-NveError -ErrorRecord $_ -Message 'This function failed during ...'
  }

.EXAMPLE
  try {
    Some-FunctionThatCausesAnException 
  } 
  catch {
    Write-NveError $_ 'This function failed during ...'
  }
#>
function Write-NveError {

  [CmdletBinding()]
  Param(
    [Parameter(Mandatory, Position = 0)]
    $ErrorRecord,

    [Parameter(Position = 1)]
    $Message
  )

  $ErrorRecord.ErrorDetails ??= $ErrorRecord.Exception.Message
  $ErrorRecord.ErrorDetails = "{0}{1}" -f ($Message ? "$Message | " : ''), $ErrorRecord.ErrorDetails
  $PSCmdlet.ThrowTerminatingError($ErrorRecord)
}
