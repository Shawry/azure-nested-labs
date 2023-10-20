function Get-NveLocalTimes {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory)]
    [string]
    $UtcTime
  )

  try {
    $CurrentDate = (Get-Date -format 'o').Split('T')[0]
    $UtcDateTime = Get-Date -Date ("{0}T{1}:00.0000000+00:00" -f $CurrentDate, $UtcTime) -AsUtc

    $TimeZone = @{
      QLD = 'E. Australia Standard Time'
      NSW = 'AUS Eastern Standard Time'
      ACT = 'AUS Eastern Standard Time'
      VIC = 'AUS Eastern Standard Time'
      TAS = 'Tasmania Standard Time'
      SA  = 'Cen. Australia Standard Time'
      WA  = 'W. Australia Standard Time'
      NT  = 'AUS Central Standard Time'
    }

    $TimeZone.GetEnumerator() | Foreach-Object {

      $TzInfo = [System.TimeZoneInfo]::FindSystemTimeZoneById($_.Value)
      $LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UtcDateTime, $TzInfo)

      [PSCustomObject]@{
        TimeZone = $_.Value
        ApproxLocation = $_.Key
        LocalTime = ($LocalTime -split '\s', 2)[1] -replace ':00$',''
      }
    }
  }
  catch {
    Write-Output "Error: Unable to retrieve local times"
  }
}