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

    [TimeZones].GetEnumNames() | Foreach-Object {

      $TzInfo = [System.TimeZoneInfo]::FindSystemTimeZoneById([TimeZones]::$_)
      $LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UtcDateTime, $TzInfo)

      [PSCustomObject]@{
        TimeZone = [TimeZones]::$_
        ApproxLocation = $_
        LocalTime = ($LocalTime -split '\s', 2)[1] -replace ':00$',''
      }
    }
  }
  catch {
    Write-Output "Error: Unable to retrieve local times"
  }
}