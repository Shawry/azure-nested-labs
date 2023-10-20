function Generalize-NveVm {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory)]
    [NveLab] $Lab,

    [Parameter()]
    [UInt16] $TimeOut = 300
  )
  
  try {

    Write-Output "Preparing the Lab for Capture"

    try {
      $PowerState = Get-AzVM -ResourceGroupName $Lab.ResourceGroupName -Name $Lab.VmName -Status |
        Select-Object -ExpandProperty Statuses | Where-Object Code -match '^PowerState' | Select-Object -ExpandProperty DisplayStatus
    }
    catch {
      Write-NveError $_ "Unable to get the VM state"
    }
    
    if($PowerState -ne 'VM running') {
      try {
        Write-Output ("VM not running, Powerstate:'{0}', starting now" -f $PowerState)
        Start-AzVm -ResourceGroupName $Lab.ResourceGroupName -Name $Lab.VmName | Out-Null
        Write-Output "VM Started. Sleeping for 60 secs to allow startup"
        Start-Sleep -Seconds 60
      }
      catch {
        Write-NveError $_ "Unable to start the VM. Ensure the VM is running and run the runbook again"
      }   
    }
    try {
      Write-Output "Conducting Sysprep on VM"
     
      if(-Not (Test-Path "$($env:TEMP)/sysprep.ps1")) {
        $Sysprep = @"
        Remove-Item -Path C:\Windows\Panther -Recurse -Force -ea SilentlyContinue | Out-Null
        C:\Windows\System32\Sysprep\sysprep.exe /oobe /shutdown /generalize /mode:vm | Out-Null  
"@
        Add-Content -Path "$($env:TEMP)/sysprep.ps1" -Value $Sysprep
      }
      
      Invoke-AzVMRunCommand -ResourceGroupName $Lab.ResourceGroupName -VMName $Lab.VmName -CommandId 'RunPowerShellScript' -ScriptPath "$($env:TEMP)/sysprep.ps1" | Out-Null
      Write-Output "Sysprep operation completed"
    }
    catch {
      Write-NveError $_ "Failed to run sysprep on VM"
    }

    # Wait for the sysprep to complete
    Start-Sleep -Seconds 30
    $TimeLapsed = 30
    do {
      $PowerState = $PowerState = Get-AzVM -ResourceGroupName $Lab.ResourceGroupName -Name $Lab.VmName -Status |
        Select-Object -ExpandProperty Statuses | Where-Object Code -match '^PowerState' | Select-Object -ExpandProperty DisplayStatus

      if($PowerState -notmatch '^VM stopped$|^VM deallocated$') {
        
        if($TimeLapsed -ge $TimeOut) {
          Write-Output "Timed out waiting for VM to complete shut down. Seek admin help to complete the capture"
          throw "Timed out waiting for VM to complete shut down. Seek admin help to complete the capture"
        }
        else {
          Write-Output "Waiting for shut down to complete. Sleeping for 30 secs. Time lapsed: $TimeLapsed secs. Remaining Image Versions:{0}. Timeout due at: $TimeOut secs"
          $TimeLapsed += 30
          Start-Sleep -Seconds 30
        }
      }
      else {
        Write-Output "Shut down complete"
        $ShutDownCompleted = $true
      }
    }
    until ($ShutDownCompleted)

    Set-AzVM -ResourceGroupName $Lab.ResourceGroupName -Name $Lab.VmName -Generalized | Out-Null
    Write-Output "VM has been set to Generalized"
    Stop-AzVM -ResourceGroupName $Lab.ResourceGroupName -Name $Lab.VmName -Force | Out-Null
    Write-Output "VM has been deallocated"
  }
  catch {
      Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  }
}