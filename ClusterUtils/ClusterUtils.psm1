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

function Get-ClusterWMI
{
<#

.SYNOPSIS
The function makes a Cluster connection via WMI - the same as the Failover Cluster GUI does.

.DESCRIPTION
This function connects to the specified cluster name and determines if the nodes are responsive or not. It uses a similar
mechanism to how the Failover Cluster GUI operates (WMI), but the script will not hang and become unresponsive if the cluster
node is unresponsive, which is typically what happens with the Failover Cluster GUI.

.PARAMETER ClusterName
    The target Cluster we wish to connect to.

.EXAMPLE
    Get-ClusterWMI -ClusterName [ClusterName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$ClusterName )

    try
        {
            #requires -Module FailOverClusters
            Write-Host "Getting the cluster nodes…" -ForegroundColor Green -NoNewline;

            $nodes = (Get-ClusterNode -Cluster $ClusterName).name;
            Write-host "Found the following nodes:" 
            $nodes 
            Write-host "Running the WMI query..." 

            ForEach ($Node in $nodes) 
                { 
        
                Write-Host -NoNewline $node 

                if($Node.State -eq "Down") 
                    {
                        Write-Host -ForegroundColor White    " : Node down skipping" 
                    } 
                else 
                    {

                    Try 
                        { 
                            #success 
                            $result = (get-wmiobject -class "MSCluster_CLUSTER" -namespace "root\MSCluster" -authentication PacketPrivacy -computername $Node -erroraction stop).__SERVER 
                            Write-host -ForegroundColor Green      " : WMI query succeeded " 
                        } 
                    Catch 
                        { 
                            #Failure
                            Write-host -ForegroundColor Red -NoNewline  " : WMI Query failed " 
                            Write-host  "//"$_.Exception.Message 
                        } 
                    } 
   
               }
    
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
		}
}

function Get-ClusterNodeWeights
{ 
<#

.SYNOPSIS
The function gets the cluster node weights.

.DESCRIPTION
This function connects ClusterName specified and exposes the Node Weights.

.PARAMETER ClusterName
    The target Cluster we wish to connect to, and expose the Node Weighting from.

.EXAMPLE
    Get-ClusterNodeWeights -ClusterName [Cluster]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$ClusterName )

    try
        {   
            #requires -Module FailOverClusters

            # Find all of the nodes within this Cluster
            $ClusterNodes = Get-ClusterNode -Cluster $ClusterName;

            # Show the NodeName, State and NodeWeight of all nodes
            Write-Host "Current Node Weights are:" -Foreground Red;
            $ClusterNodes | ft -Property NodeName, State, NodeWeight;
        }
	Catch
		{
			Write-Host $_.Exception.ToString();
		}
}

function Get-ClusterNodeState
{
<#

.SYNOPSIS
The function connects to the specified cluster, and determines the state of the nodes within.

.DESCRIPTION
This function connects to the specified cluster, and determines:
1) All nodes
2) All Active Nodes and their Resource Groups
3) All Passive Nodes

.PARAMETER ClusterName
    The target Cluster we wish to connect to and return the node states from.

.EXAMPLE
    Get-ClusterNodeStates -ClusterName [Cluster]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$ClusterName )

    try
        {
            #requires -Module FailoverClusters

            # Try to connect to the cluster specified.
            $Cluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
                    

            if ( $Cluster -eq $null )
                {
                    Write-Host "Cluster: $($ClusterName) not found." -ForegroundColor Red;
                }
            else
                {
                    Write-Host "Node Status for Cluster: $($ClusterName)." -ForegroundColor Green;

                    $AllNodes = (Get-ClusterNode -Cluster $ClusterName).name;
                    Write-Host "All Cluster Nodes: $($AllNodes)" -ForegroundColor Green;

                    $ActiveGroups = Get-ClusterGroup -Cluster $ClusterName;
                    Write-Host "Active Groups: $($ActiveGroups)" -ForegroundColor Green;

                    $ActiveNodes = ($ActiveGroups.OwnerNode).Name;
                    Write-Host "Active Nodes: $($ActiveNodes)." -ForegroundColor Green;

                    $PassiveNodes = $AllNodes | Where { $ActiveNodes -notcontains $_ }
                    Write-Host "Passive Nodes: $($PassiveNodes)." -ForegroundColor Green;
                }     
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-CompareClusterNodeHotfixes
{ 
<#

.SYNOPSIS
The function gets the cluster node Hotfixes, and compares them to see if there are any missing entries.

.DESCRIPTION
This function connects ClusterName specified and builds a list of all Hotfixes present on each server. It
then compares those hotfixes, and produces an output showing which nodes are missing which hotfixes.

.PARAMETER ClusterName
    The target Cluster we wish to connect to, and expose the Node Weighting from.

.EXAMPLE
    Get-CompareClusterNodeHotfixes -ClusterName [Cluster]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$ClusterName )

    try
        {   
            #requires -Module FailOverClusters
            $2008R2ClusterKBReference = @('KB974930', 'KB976571', 'KB978001', 'KB978562', 'KB979782', 'KB2277439', 'KB2294255', 'KB2353832', 'KB2353808', `
                                          'KB2446607', 'KB2462576', 'KB2485543', 'KB2494016', 'KB2494036', 'KB2494162', 'KB2496034', 'KB2512715', 'KB2520235', `
                                          'KB2531907', 'KB2549448', 'KB2549472', 'KB2550886', 'KB2550894', 'KB2552040', 'KB2559392', 'KB2575625', 'KB2578113', `
                                          'KB2579052', 'KB2580360', 'KB2606025', 'KB2648385', 'KB2637197', 'KB2639032', 'KB2616514', 'KB2652013', 'KB2673129', `
                                          'KB2674551', 'KB2687646', 'KB2685891', 'KB2687741', 'KB2741477', 'KB2777201', 'KB2779069');
            $2012ClusterKBReference = @('KB3090343', 'KB3062586', 'KB3018489', 'KB3048474', 'KB3004098', 'KB2916993', 'KB2929869', 'KB2913695', `
                                        'KB2878635', 'KB2894464', 'KB2838043', 'KB2803748', 'KB2770917', 'KB976424');
            $2012R2ClusterKBReference = @('KB3197874', 'KB3145432', 'KB3179574', 'KB3172614', 'KB3130944', 'KB3139896', 'KB3130939', 'KB3123538',
                                          'KB3091057', 'KB3013769', 'KB3000850', 'KB2919355', 'KB976424');
            $2016ClusterKBReference = @(); #To Be Added

            $DT = Get-Date -Format "yyyymmddHHmmss"
            $ErrorActionPreference = "SilentlyContinue"

            $Computers = @()
            $Hotfixes = @()
            $StorageDrivers = @()
            $SQLBuilds = @()
            $Result = @() 
            $Rlog = @()

            # Cluster Build Numbers
            # Windows Server 2016 		10.0* 
            # Windows Server 2012 R2 	6.3* 
            # Windows Server 2012 		6.2 
            # Windows Server 2008 R2 	6.1 
            # Windows Server 2008 		6.0 

            # Get the node names from the cluster
            $ClusNodeInfo = Get-WmiObject -Namespace root/mscluster -Class MSCluster_Node -ComputerName $ClusterName -EnableAllPrivileges -Authentication 6

            # Dig out the version of the cluster from the first node
            Switch ($ClusNodeInfo[1].MajorVersion)
                {
                    '10'
                        {   # Windows 2016
                            $WindowsKBReferenceFile = $2016ClusterKBReference;
                        }
                    '6'
                        {
                            Switch ( $ClusNodeInfo[1].MinorVersion )
                                {
                                    '1'
                                        {   # Windows 2008R2
                                            $WindowsKBReferenceFile = $2008R2KBReferenceFile
                                        }
                                    '2'
                                        {   # Windows 2012
                                            $WindowsKBReferenceFile = $2012KBReferenceFile
                                        }
                                    '3'
                                        {   # Windows 2012R2
                                            $WindowsKBReferenceFile = $2012R2KBReferenceFile
                                        }
                                    'default'
                                        {
                                            $WindowsKBReferenceFile = @();
                                        }
                                }
                        }
                    'default'
                        {
                            $WindowsKBReferenceFile = @();
                        }
                }
            
            ForEach ($hotfix in $WindowsKBReferenceFile | ? {$_.trim() -ne "" })
			    {
			   	    $h = New-Object System.Object 
                    $h | Add-Member -type NoteProperty -name "Server" -value "ANY" 
                    $h | Add-Member -type NoteProperty -name "Hotfix" -value $hotfix 
                    $hotfixes += $h
			    }

            # Loop through each node name and place it in the $Computers variable
            ForEach ($Node in $ClusNodeInfo)
                {
                    $Computers += $Node.Name
                }

            
            # Loop though Each Computer Node
            ForEach ($computer in $computers) 
                { 
		
                    # Get the Hotfixes using Get-Hotfix 
                    ForEach ($hotfix in (get-hotfix -computer $computer | select HotfixId)) 
                    { 
                        # Filter out returned Hotfixes named "File 1" - mainly happens on WS03
                        # Store system names and hotfixes in the $Hotfixes HashTable 
                        If ($Hotfix -notlike "*File 1*") 
                        {
                            $h = New-Object System.Object 
                            $h | Add-Member -type NoteProperty -name "Server" -value $computer 
                            $h | Add-Member -type NoteProperty -name "Hotfix" -value $hotfix.HotfixId 
                            $hotfixes += $h
                        }
                    }
                }

            # Goes through the HashTable and ensures there are only Unique Computer Names
            $ComputerList = $hotfixes | Select-Object -unique Server | Sort-Object Server | Where-Object Server -ne "ANY" 
     
            # Loop Thru all the sorted unique Hotfixes
            ForEach ($hotfix in $hotfixes | Select-Object -unique Hotfix | Sort-Object Hotfix) 
                { 
                    $h = New-Object System.Object 
                    $h | Add-Member -type NoteProperty -name "Hotfix" -value $hotfix.Hotfix
		
                    # Loop through the Computers to match up the Hotfixes to the Computer
                    ForEach ($computer in $ComputerList) 
                        { 
                            # Check to see if Hotfixes are present or missing.  If hotfix is present on computer add a "*" to the NodeName
                            # If Computer is missing Hotfix add Hotfix and Computer to additional HashTable $RL, and add a "---" the $h HashTable
                            If ($hotfixes | Select-Object |Where-Object {($computer.server -eq $_.server) -and ($hotfix.Hotfix -eq $_.Hotfix)})  
                                {
                                    $h | Add-Member -type NoteProperty -name $computer.server -value "*"
                                } 
                            else 
                                {
                                    $h | Add-Member -type NoteProperty -name $computer.server -value "!!!"
                                    $RL = New-Object System.Object
                                    $RL | Add-Member -type NoteProperty -name "Server" -value $computer.server
                                    $RL | Add-Member -type NoteProperty -name "Hotfix" -value $hotfix.Hotfix
                                    $RLog += $RL
                                } 
		                }
                    # Adds the either the "*" or "!!!" to the server name
                    $result += $h 
                } 

            return $result

        }
	Catch
		{
			Write-Host $_.Exception.ToString();
		}
}

function Get-DetailedClusterLogErrors
{
<#

.SYNOPSIS
Regenerate the Cluster Log and display the most recent error(s).

.DESCRIPTION
Function to connect to the specified cluster, regenerate the Cluster Log and display the most recent error(s).

.PARAMETER ClusterName
    Cluster Name we wish to connect to and investigate.

.PARAMETER LogDays
    The number of days of historical Cluster Log we wish to generate.

.EXAMPLE
    Get-ClusterLogErrors -ClusterName [ClusterName] -LogDays [1|2|3|4|5...]

.NOTES

 Author: Author Name
 Company: Company Name

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$ClusterName,
            [Parameter(Mandatory=$true)][int]$LogDays )

    try
        {
            #requires -Module FailoverClusters
            
            # Try to connect to the cluster specified.
            $Cluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue;
            $TimeSpan = $LogDays * 60 * 24;                  

            if ( $Cluster -eq $null )
                {
                    Write-Host "Cluster: $($ClusterName) not found." -ForegroundColor Red;
                }
            else
                {
                    $Nodes = (Get-ClusterNode -Cluster $ClusterName).name;

                    Set-ClusterLog -Cluster $ClusterName -level 5; # Set to Verbose Logging
                    Get-ClusterLog -Cluster $ClusterName -UseLocalTime -TimeSpan $TimeSpan;
                    Set-ClusterLog -Cluster $ClusterName -level 3; # Set back to default logging level                    

                    ForEach ( $Node in $Nodes )
                        {
                            $NodePath = "\\" + $Node + "\C`$\Windows\Cluster\Reports\Cluster.log";
                            $reader = [System.IO.File]::OpenText($NodePath);
                            while($null -ne ($line = $reader.ReadLine()))
                                {
                                    Write-Host "Cluster Log from $($Node):" -ForegroundColor Green;
                                    $line | Where { $_ -eq "ERR" };
                                }
                        }

                }   
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

Export-ModuleMember -Function 'Get-ClusterWMI';
Export-ModuleMember -Function 'Get-ClusterNodeWeights';
Export-ModuleMember -Function 'Get-ClusterNodeState';
Export-ModuleMember -Function 'Get-DetailedClusterLogErrors';
Export-ModuleMember -Function 'Get-CompareClusterNodeHotfixes';