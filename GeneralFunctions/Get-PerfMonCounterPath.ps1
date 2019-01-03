Function Get-PerfMonCounterPath{
<#
.Synopsis
   Searches perfmon counters for counter name

.DESCRIPTION
   Takes a string of a counter name and returns all of the counter sets where the string is found in the name
   
.EXAMPLE
   cls
   Get-PerfMonCounterPath worktable

   returns all counter sets with paths where the counter name contains 'worktable'

.EXAMPLE
   cls
   Get-PerfMonCounterPath 'worktable'

   returns all counter sets with paths where the counter name contains 'worktable ' - 
   Enclose string in quotes to include preceding or trailing spaces

.EXAMPLE
   cls
   Get-PerfMonCounterPath phy*sec

   returns all counter sets with paths where the counter name contains 'phy' followed by 
   any characters followed by 'sec'

   .NOTES

 Author: Jonathan Allen
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History
#>
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true,
        ValueFromPipeline=$true)]
        [string]$CounterName
    )

    begin{}

    process{
        "Counters containing '$CounterName'`: " | Write-Output
        (Get-Counter -ComputerName $env:COMPUTERNAME -ListSet *).paths | ? {$_ -like "`*$CounterName`*"} | Write-Output
    }

    end{}
    
}