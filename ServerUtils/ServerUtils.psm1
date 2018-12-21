function Template
{
    param ( [Parameter(Mandatory=$true)][string]$SQLConnectionString )

    try
        {
            #requires -Module FailOverClusters
                
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-DiskCapacity
{
<#

.SYNOPSIS
The function connects to the Specified Server (Stand-Alone or Cluster) and returns the Disk Capacities.

.DESCRIPTION
This function connects to the specified Server (Stand-Alone or Cluster), determining the allocated disk capacities.
If the Server specified is a Cluster, then it enumerates all of the nodes contained within that cluster, then
loops through all of those nodes, determining the allocated disks within that node and their capacity.

.PARAMETER ServerName
    The target Server (Stand-Alone or Cluster) we wish to connect to, and return the disk capacit(ies) from.

.EXAMPLE
    Get-DiskCapacity -ServerName [Stand-Alone or Cluster]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$ServerName )

    try
        {
            #requires -Module FailOverClusters

            # Try to connect to the cluster specified.
            $Cluster = Get-Cluster -Name $ServerName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
                    

            if ( $Cluster -eq $null )
                {
                    # This is not a clustered Server, its a Stand-Alone
                    $nodes = $ServerName;
                }
            else
                {
                    # It is Clustered
                    $nodes = (Get-ClusterNode -Cluster $ServerName).name;
                }

            ForEach ( $Node in $Nodes )
                {

                    $ArrVolumes = @();

                    $SumCapacity  = 0
                    $SumFreespace = 0
                    $SumUsedSpace = 0

                    Write-Output "$Node  - [Volumes] "

                    try
                        {
                            $Volumes = Get-WmiObject -Computername $Node -Class Win32_Volume `
                                        | ?{$_.Drivetype -eq 3 -and $_.Capacity -gt 0} `
                                        |  Select Caption, Label, Capacity, Freespace, Blocksize `
                                        | sort Caption;
                        }
                    catch
                        {
                            Write-Host " Unable to find information for $Node" -ForegroundColor Red; 
                        }

                     ForEach($Volume in $Volumes)  
                        {
                            $UsedSpace = [Long]$Volume.Capacity - [Long]$Volume.freespace;              
                            $PercentUsed = $UsedSpace / [Long]$Volume.Capacity;  
              
                            if ( $PercentUsed -gt 0.90 ) 
                                {
                                    $Comments = "[Warning over 90% Usage]"
                                }
                            else
                                {
                                    $Comments = "";
                                }
         
                            [string]$x=$Volume.Caption
                            $x=$x.padright(25)
                            $x=$x.substring(0,24)
                            $VolumeInfo = New-Object PSObject
                            #$VolumeInfo | Add-Member NoteProperty Volume       -Value $Volume.Caption
                            $VolumeInfo | Add-Member NoteProperty Volume        -Value $x
                            $VolumeInfo | Add-Member NoteProperty Label         -Value $Volume.Label
                            $VolumeInfo | Add-Member NoteProperty Capacity      -Value ("{0,8:N2}GB" -f ($Volume.Capacity / 1GB ))        
                            $VolumeInfo | Add-Member NoteProperty Used_Space    -Value ("{0,8:N2}Gb" -f ($UsedSpace / 1GB)) 
                            $VolumeInfo | Add-Member NoteProperty Free_Space    -Value ("{0,8:N2}Gb" -f ($Volume.freespace / 1GB )) 
                            $VolumeInfo | Add-Member NoteProperty Percent_Used  -Value ("{0,12:P2}" -f ($PercentUsed))      
                            $VolumeInfo | Add-Member NoteProperty Blocksize     -Value ("{0,8:N0}K" -f ($Volume.Blocksize / 1Kb))
                            $VolumeInfo | Add-Member NoteProperty Comments      -Value $Comments
                            # Add object to an array of objects
                            $ArrVolumes += $VolumeInfo     
         
                            #*=============================================================================
                            #* Totals
                            #*=============================================================================
                            $SumCapacity = $SumCapacity + $Volume.Capacity
                            $SumFreespace = $SumFreespace + $Volume.freespace
                            $SumUsedSpace = $SumUsedSpace + $UsedSpace
                        }

                    $VolumeInfo = New-Object PSObject
                    $VolumeInfo | Add-Member NoteProperty Volume        -Value "*** Total Storage"
                    $VolumeInfo | Add-Member NoteProperty Capacity      -Value ("{0,8:N2}GB" -f ($SumCapacity / 1GB ))        
                    $VolumeInfo | Add-Member NoteProperty Used_Space    -Value ("{0,8:N2}Gb" -f ($SumUsedSpace / 1GB)) 
                    $VolumeInfo | Add-Member NoteProperty Free_Space    -Value ("{0,8:N2}Gb" -f ($SumFreespace / 1GB )) 
                    $PercentUsed = $SumUsedSpace / [Long]$SumCapacity    
                    $VolumeInfo | Add-Member NoteProperty Percent_Used  -Value ("{0,12:P2}" -f ($PercentUsed))    
                    $VolumeInfo | Add-Member NoteProperty Blocksize     -Value "***" 
                    $VolumeInfo | Add-Member NoteProperty Comments      -Value ""  
            
                    # Add object to an array of objects
                    $ArrVolumes += $VolumeInfo   

                    #*=============================================================================
                    #* Output Results
                    #*=============================================================================
                    $ArrVolumes = $ArrVolumes | Format-Table -Autosize
                }

            return $ArrVolumes;
                
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
		}
}

function Add-RemoteAdmin
{
<#

.SYNOPSIS
The function connects to the Specified Server and adds the nominated account into the Administrators Group.

.DESCRIPTION
This function connects to the specified Server and adds the specified account into the Administrators Group.
The account can be a domain or local account.

.PARAMETER ServerName
    The target Server we wish to connect to, and Add accounts into the Administrators Group on.


.PARAMETER AccountToAdd
    The Account we wish to Add into the Administrators Group on the specified server. This can be a domain account, or
    a local account.


.EXAMPLE
    Add-RemoteAdmin -ServerName [Server] -AccountToAdd [Domain\Account]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$ServerName,
            [Parameter(Mandatory=$true)][string]$AccountToAdd )

    try
        {
            # Add Account to Remote Computer Admin Group
            if ( $AccountToAdd -contains "\" )
                {
                    $Domain, $UserName = $AccountToAdd.Split('\');
                }
            else
                {
                    $Domain = $env:userdomain;
                    $UserName = $AccountToAdd;
                }

            $AdminGroup = [ADSI]"WinNT://$ServerName/Administrators,group";
            $User = [ADSI]"WinNT://$DomainName/$UserName,user";
            $AdminGroup.Add($User.Path);
    
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-RemoteAdminMembers
{
<#

.SYNOPSIS
The function connects to the Specified Server and lists the accounts within the Administrators Group.

.DESCRIPTION
The function connects to the Specified Server and lists the accounts within the Administrators Group.

.PARAMETER ServerName
    The target Server we wish to connect to, and enumerate the members of the Administrators Group.

.EXAMPLE
    Get-RemoteAdminMembers -ServerName [Server]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$ServerName )

    try
        {

            $admins = Get-WmiObject win32_groupuser –ComputerName $ServerName | Where {$_.groupcomponent –like '*"Administrators"'} 
            $admins = $admins |% {  
                    $_.partcomponent –match ".+Domain\=(.+)\,Name\=(.+)$" > $nul  
                    $matches[1].trim('"') + "\" + $matches[2].trim('"')  
                    }  

            return $admins;
    
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Set-ServerPowerPlan
{
<#

.SYNOPSIS
Set the Server Power Plan to either 'Balanced' or 'High Performance' as required.

.DESCRIPTION
Set the Server level Power Plan to either 'Balanced' or 'High Performance' as required.

.PARAMETER ServerName
    The ServerName of the server we would like to set the Power Plan on.

.PARAMETER PowerPlan
    The Power Plan we would like to set.

.EXAMPLE
    Set-ServerPowerPlan -ServerName [Server] -PowerPlan ['Balanced' | 'High Performance']

.NOTES

 Author: Author Name
 Company: Company Name

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$ServerName, 
            [Parameter(Mandatory=$true)][ValidateSet('High Performance','Balanced')][string]$PowerPlan )

    try
        {
            # Set the PowerPlan
            $p = Get-WMIObject -Class win32_powerplan -Namespace root\cimv2\power -ComputerName $ServerName -Filter "ElementName ='$($PowerPlan)'";
            $p.Activate();
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
		}
}

function Get-LastWindowsPatch
{
<#

.SYNOPSIS
Connect to the server and determine the last patch time.

.DESCRIPTION
Connect to the server what the last patch which was applied was, and also when it was applied.

.PARAMETER ServerName
    The ServerName to connect to.

.EXAMPLE
    Get-LastWindowsPatch -ServerName [ServerName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$ServerName )

    try
        {

            $Data = Invoke-command -computer $ServerName { Get-Hotfix } | `
                    Sort-Object -Property InstalledOn | `
                    Format-Table;

            Return $Data;

        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

Export-ModuleMember -Function 'Get-DiskCapacity';
Export-ModuleMember -Function 'Add-RemoteAdmin';
Export-ModuleMember -Function 'Get-RemoteAdminMembers';
Export-ModuleMember -Function 'Get-LastWindowsPatch';
Export-ModuleMember -Function 'Set-ServerPowerPlan';