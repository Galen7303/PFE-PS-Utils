function Get-ActivePowerPlan {
    <#
.Synopsis
   List all servers that are using Power Plan that isn't High Performance

.DESCRIPTION
   Using Balanced power plan can result in poor performance on SQL Server. Check that all servers are using High Performance plan.
   
.EXAMPLE
   Get-ActivePowerPlan Server123

to get the active power plan from one server

.EXAMPLE
    
    $env:COMPUTERNAME | Get-ActivePowerPlan

Get active powerplan for current computer

results:

Power plan       PSComputerName
----------       --------------
High performance MININT-Computer


.INPUTS
   $Servers - list of servers to check
.OUTPUTS
   details of servers and active power plan are listed as output

   .NOTES

 Author: Jonathan Allen
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History
#>
    [CmdletBinding()]
    param(
        <# reference http://technet.microsoft.com/en-gb/library/hh847743.aspx #>
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]$Servers
    )
    begin {
        $ErrorActionPreference = 'Stop'
    }
    process {    
        $PPlans = @()
        $PPlanErrs = @()
        
        foreach ($Server in $Servers) {
            # "Checking powerplan on $Server" | write-verbose
            try {
                $PPlans += Get-CimInstance -Class win32_powerplan -Namespace root\cimv2\power -ComputerName $Server -Filter "isActive='true'" | select @{name = 'Power plan'; expression = {$_.elementName}}, PSComputerName 
            } 
            catch {
                "Access denied: $Server"
            }
        }
        
        return $PPlans
    }
}
