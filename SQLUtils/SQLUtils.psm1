function Template-Basic
{
<#

.SYNOPSIS
Function Synopsis.

.DESCRIPTION
Function Description.

.PARAMETER Function-Parameters
    Parameter Descriptions.

.EXAMPLE
    Function Call examples.

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;    
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Template-SMO
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment and .

.DESCRIPTION
Connect to the specified SQL Server environment and .

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.EXAMPLE
    Get-..... -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $SMOServer = New-Object ('Microsoft.SQLServer.Management.Smo.Server') $($SQLConfig.SQLInstance);
            if ( $SMOServer -eq $null )
                {
                    Write-Host "Server $($SQLConfig.SQLInstance) cannot be contacted." -ForegroundColor Red;
                }
            else
                {
                    $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
                    $QueryText =  "";

                    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
                    $SqlConnection.ConnectionString = $CommandString;
                    $SqlConnection.Open();


                    $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
                    $Sqlcmd.Connection = $SqlConnection;
                    $SQLCmd.CommandText = $QueryText;

                    $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
                    $DataSet = New-Object System.Data.DataSet;
                    $DataAdapter.Fill($DataSet) | Out-Null;


                    $Data =$DataSet.Tables[0] | Format-Table;

                    return $Data;
                }
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Load-SQLSMOObjects
{
<#

.SYNOPSIS
Load the SQL Server SMO assembliy set.

.DESCRIPTION
Load the SQL Server SMO assemblies.

.PARAMETER None
    This Function has no parameters.

.EXAMPLE
    Load-SMO.

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( )

    try
        {
            # If we have the SQLServer module present on the system, it will automatically
            # load the SMO assemblies for us. If not, we will have to rely on the SQLPS
            # (older) module, and load the assemblies manually.
            If ( -not( Get-Module -name SqlServer ) ) 
                { 
                    If ( Get-Module -ListAvailable | Where-Object { $_.name -eq "SqlServer" } ) 
                        { 
                            Write-Host "Importing Module SqlServer..." -ForegroundColor Green -NoNewline;
                            Import-Module -Name SqlServer -DisableNameChecking | Out-Null;
                            Write-Host "Completed." -ForegroundColor Green;
                        } #end if module available then import 
                    else
                        { 
                            Write-Host "Module SqlServer is not available on this system." -ForegroundColor Yellow;
                            Write-Host "Please run 'Install-Module SqlServer' from the PowerShell Gallery for updated functionality." -ForegroundColor Yellow;
                            Write-Host "Reverting to SQLPS..." -ForegroundColor Yellow;
                            
                            $PSVersions = @(180,170,160,150,140,130,120,110,100,90);
                            ForEach ( $PSVersion in $PSVersions )
                                {
                                    $sqlpsreg="HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps"  + $PSVersion;
                                    $regkey = Get-ItemProperty $sqlpsreg -ErrorAction "SilentlyContinue";

                                    if ( $regkey -ne $null )  
                                        {  
                                            Write-Host "Loading SQL Server Provider (SQLPS) for Windows PowerShell $($PSVersion)." -ForegroundColor Green;
                                            $sqlpsPath = [System.IO.Path]::GetDirectoryName($regkey.Path);
                                            break; 
                                        }  
                                }

                            $assemblylist =   
                                "Microsoft.SqlServer.Management.Common", ` 
                                "Microsoft.SqlServer.Smo", ` 
                                "Microsoft.SqlServer.Dmf ", ` 
                                "Microsoft.SqlServer.Instapi ", ` 
                                "Microsoft.SqlServer.SqlWmiManagement ", `  
                                "Microsoft.SqlServer.ConnectionInfo ", ` 
                                "Microsoft.SqlServer.SmoExtended ", ` 
                                "Microsoft.SqlServer.SqlTDiagM ", ` 
                                "Microsoft.SqlServer.SString ", ` 
                                "Microsoft.SqlServer.Management.RegisteredServers ", ` 
                                "Microsoft.SqlServer.Management.Sdk.Sfc ", `  
                                "Microsoft.SqlServer.SqlEnum ", ` 
                                "Microsoft.SqlServer.RegSvrEnum ", ` 
                                "Microsoft.SqlServer.WmiEnum ", ` 
                                "Microsoft.SqlServer.ServiceBrokerEnum ", ` 
                                "Microsoft.SqlServer.ConnectionInfoExtended ", ` 
                                "Microsoft.SqlServer.Management.Collector ", ` 
                                "Microsoft.SqlServer.Management.CollectorEnum", ` 
                                "Microsoft.SqlServer.Management.Dac", ` 
                                "Microsoft.SqlServer.Management.DacEnum", ` 
                                "Microsoft.SqlServer.Management.Utility"; 

                            foreach ($asm in $assemblylist)  
                                {  
                                    $asm = [Reflection.Assembly]::LoadWithPartialName($asm)  
                                }  

                            Push-Location  
                            cd $sqlpsPath  
                            update-FormatData -prependpath SQLProvider.Format.ps1xml   
                            Pop-Location 
                        } #module not available 
                } # end if not module   
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-SQLInstance
{
<#

.SYNOPSIS
Internal Function to determine the SQL Server ServerName and InstanceName based off of the Instance
Parameter.

.DESCRIPTION
Common function, coded as an internal function (i.e. not exported out of this module) to determine
the SQL Server ServerName and InstanceName based off of the SQLInstance Parameter.

.PARAMETER Instance
    The Instance we are interested in.

.EXAMPLE
    Get-SQLInstance -SQLInstance.

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            [hashtable]$SQLConfig = @{};

            $SQLConfig.SQLInstance = $SQLInstance;
            

            if ( $SQLInstance.Contains('\') )
                {
                    # Its a Named Instance
                    $SQLConfig.NamedInstance = $true;
                    $SQLConfig.ServerName = $SQLInstance.Split('\\')[0];
                    $SQLConfig.InstanceName = $SQLInstance.Split('\\')[1];
                    $SQLConfig.ServiceName = "MSSQL$" + $SQLConfig.InstanceName;
                }
            else
                {
                    # Its a Default Instance
                    $SSQLConfig.NamedInstance = $false;
                    $SQLConfig.ServerName = $SQLInstance;
                    $SQLConfig.InstanceName = "MSSQLSERVER";
                    $SQLConfig.ServiceName = "MSSQLSERVER";
                }
            
            return $SQLConfig;  
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-SQLConfig
{
<#

.SYNOPSIS
The function gets the Server, Service and Configuration data for the prescribes SQL Server target.

.DESCRIPTION
This function connects to the SQL Server instance in a variety of different ways, in order to pull back
relevant and useful information about the environment. This includes, CPU and Memory, as well as Service
details and configuration values.

.PARAMETER SQLInstance
    The target SQL Server instance we wish to collect data from.

.EXAMPLE
    Get-SQLConfig -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            
            Load-SQLSMOObjects;
            
            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;
                        
            # Initialize a HashTable for the SQL Configuration Parameters
            Write-Host "Building the Configuration Hashtable for SQL Server: " -ForegroundColor Green -NoNewline;
            Write-Host "$SQLInstance" -ForegroundColor White;

            $SMOServer = New-Object ('Microsoft.SQLServer.Management.Smo.Server') $($SQLConfig.SQLInstance);

            $SQLConfig.ServerPhysicalMemory = $SMOServer.PhysicalMemory;
            $SQLConfig.NumaNodes = $SMOServer.AffinityInfo.NumaNodes;
            $SQLConfig.CPUs = $SMOServer.AffinityInfo.CPUs;
            $SQLConfig.AffinityAssignment = $SMOServer.AffinityInfo.AffinityType;


            $SQLConfig.MaxServerMemory = $SMOServer.Configuration.MaxServerMemory.ConfigValue;
            $SQLConfig.MinServerMemory = $SMOServer.Configuration.MinServerMemory.ConfigValue;
            $SQLConfig.XPCmdShellEnabled = $SMOServer.Configuration.XPCmdShellEnabled.ConfigValue;


            $svc = Get-WMIObject -ComputerName $SQLConfig.ServerName -query "select * from win32_service where name='$($SQLConfig.ServiceName)'";
            if ( $svc -eq $null )
                {
                    Write-Host "Unable to find Instance." -ForegroundColor Red;
                }
            else
                {
                    $ServiceAccount = ($svc.Properties | where { $_.Name -eq "StartName" } ).Value;
                    if ( $ServiceAccount.Contains(' ') )
                        {
                            $SQLConfig.ServiceAccount = "`"" + $ServiceAccount + "`"";
                        }
                    else
                        {
                            $SQLConfig.ServiceAccount = $ServiceAccount;
                        }
                    $SQLConfig.ServiceState = $svc.state;
                    $BinnDir = $svc.PathName;
                    $SQLConfig.BinnDir = $BinnDir.Substring(1, $BinnDir.LastIndexOf("\"));
                    $SQLConfig.Program = $SQLConfig.BinnDir + "sqlservr.exe";
                }

            $SQLConfig.ServerNameFQDN = ([System.Net.DNS]::GetHostByName($SQLConfig.ServerName)).Hostname;

            $mc = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $SQLConfig.ServerName;
            if ( $mc -eq $null )
                {
                    Write-Host "Unable to connect to Computer." -ForegroundColor Red;
                }
            else
                {
                    $si = $mc.ServerInstances | Where { $_.Name -eq $SQLConfig.InstanceName };
                }

            if ( $SQLConfig.NamedInstance -eq $true )
                {
                    # Its a Named Instance 
                    if ( ($si.ServerProtocols['Np'].ProtocolProperties | Where { $_.Name -eq "Enabled" }).Value -eq $true )
                        {
                            $SQLConfig.NamedPipes = ($si.ServerProtocols['Np'].ProtocolProperties | Where { $_.Name -eq "PipeName" }).Value;
                            $SQLConfig.SPN_Np = "SETSPN -S MSSQLSvc/" + $SQLConfig.ServerNameFQDN + ":" + $SQLConfig.InstanceName + " " + $SQLConfig.ServiceAccount;
                        }
                    else
                        {
                            $SQLConfig.NamedPipes = "Not Enabled";
                            $SQLConfig.SPN_Np = "Not Enabled";
                        }

                    if ( ($si.ServerProtocols['Tcp'].ProtocolProperties | Where { $_.Name -eq "Enabled" }).Value -eq $true )
                        {
                            $SQLConfig.TCPPort = $si.ServerProtocols['Tcp'].IPAddresses['IPAll'].IPAddressProperties['TcpDynamicPorts'].Value;
                            $SQLConfig.SPN_Tcp = "SETSPN -S MSSQLSvc/" + $SQLConfig.ServerNameFQDN + ":" + $SQLConfig.TCPPort + " " + $SQLConfig.ServiceAccount;
                        }
                    else
                        {
                            $SQLConfig.TCPPort = "Not Enabled";
                            $SQLConfig.SPN_Tcp = "Not Enabled";
                        }
                }
            else
                {
                    # Its a Default Instance
                    if ( ($si.ServerProtocols['Np'].ProtocolProperties | Where { $_.Name -eq "Enabled" }).Value -eq $true )
                        {
                            $SQLConfig.NamedPipes = ($si.ServerProtocols['Np'].ProtocolProperties | Where { $_.Name -eq "PipeName" }).Value;
                            $SQLConfig.SPN_Np = "SETSPN -S MSSQLSvc/" + $SQLConfig.ServerNameFQDN + " " + $SQLConfig.ServiceAccount;
                        }
                    else
                        {
                            $SQLConfig.NamedPipes = "Not Enabled";
                            $SQLConfig.SPN_Np = "Not Enabled";
                        }
                    if ( ($si.ServerProtocols['Tcp'].ProtocolProperties | Where { $_.Name -eq "Enabled" }).Value -eq $true )
                        {
                            $SQLConfig.TCPPort = $si.ServerProtocols['Tcp'].IPAddresses['IPAll'].IPAddressProperties['TcpPort'].Value;             
                            $SQLConfig.SPN_Tcp = "SETSPN -S MSSQLSvc/" + $SQLConfig.ServerNameFQDN + ":" + $SQLConfig.TCPPort + " " + $SQLConfig.ServiceAccount;
                        }
                    else
                        {
                            $SQLConfig.TCPPort = "Not Enabled";
                            $SQLConfig.SPN_Tcp = "Not Enabled";
                        }
                }
            
            $SQLConfig.DAC = "SQLCMD -S" + $SQLConfig.SQLInstance + " -A";

            $SQLConfig.PowerPlan = (Get-WmiObject -ComputerName $SQLConfig.ServerName -Class win32_powerplan -Namespace root\cimv2\power | `
                                    Where { $_.IsActive -eq $true }).ElementName;

            return $SQLConfig;

        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-SysAdminMembers
{
<#

.SYNOPSIS
The function lists the Members present within the SysAdmins Server Role inside SQL Server.

.DESCRIPTION
This function connects to the SQL Server instance and enumerates the Logins present within the
SysAdmin server role. This is useful to identify and members which have "god" level access within
SQL Server which shouldn't have.

.PARAMETER SQLInstance
    The target SQL Server instance we wish to collect data from.

.EXAMPLE
    Get-SysAdminMembers -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            [System.Collections.ArrayList]$Accounts = @();
            
            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
            $SqlConnection.ConnectionString = "Server = $($SQLConfig.SQLInstance); Database = Master; Integrated Security = True;"

            $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
            $SqlCmd.CommandText = "EXEC sp_helpsrvrolemember 'sysadmin';";
            $SqlCmd.Connection = $SqlConnection
            $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
            $SqlAdapter.SelectCommand = $SqlCmd
            $DataSet = New-Object System.Data.DataSet
            [void]$SqlAdapter.Fill($DataSet)


            # Output each Account
            $Accounts = $DataSet.Tables[0] | Format-Table;
 
            [void]$sqlConn.Close;

            return $Accounts; 
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-VLFCounts
{
<#

.SYNOPSIS
The function connects to the SQL Server Instance specified, and determines all of the VLFs for the database(s)
present on that instance.

.DESCRIPTION
This function connects to the SQL Server instance and loops through all of the databases present, determining the
VLF counts for those databases. No filtering is performed, this is simply a report of the current state. Data is 
returned through the PS pipeline and can be filtered upon return.

.PARAMETER SQLInstance
    The target SQL Server instance we wish to collect data from.

.EXAMPLE
    Get-VLFCounts -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
            $QueryText =  "DECLARE @MajorVersion INT

BEGIN TRY
	IF ( OBJECT_ID('tempdb..#VLF_temp1') IS NOT NULL )
		BEGIN
			DROP TABLE #VLF_temp1;
		END
	IF ( OBJECT_ID('tempdb..#VLF_temp2') IS NOT NULL )
		BEGIN
			DROP TABLE #VLF_temp2;
		END
	IF ( OBJECT_ID('tempdb..#VLF_db_total_temp') IS NOT NULL )
		BEGIN
			DROP TABLE #VLF_db_total_temp;
		END
	CREATE TABLE #VLF_temp1 (RecoveryUnitID int,
					  FileID varchar(3), FileSize numeric(20,0),
					  StartOffset bigint, FSeqNo bigint, Status char(1),
					  Parity varchar(4), CreateLSN numeric(25,0))
 	CREATE TABLE #VLF_temp2 (FileID varchar(3), FileSize numeric(20,0),
					  StartOffset bigint, FSeqNo bigint, Status char(1),
					  Parity varchar(4), CreateLSN numeric(25,0))

	CREATE TABLE #VLF_db_total_temp (name sysname, vlf_count int)
 
	DECLARE db_cursor CURSOR
	READ_ONLY
	FOR SELECT name FROM master.dbo.sysdatabases
 
	DECLARE @name sysname, @stmt varchar(40)
	OPEN db_cursor
 
	SELECT @MajorVersion = CONVERT(INT, LEFT(CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion')), 
							CHARINDEX('.', CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion'))) -1));

	FETCH NEXT FROM db_cursor INTO @name
	WHILE (@@fetch_status <> -1)
	BEGIN
		  IF (@@fetch_status <> -2)
		  BEGIN
				IF ( @MajorVersion > 10 )
					BEGIN
						INSERT INTO #VLF_temp1
						EXEC ('DBCC LOGINFO ([' + @name + ']) WITH NO_INFOMSGS')

						INSERT INTO #VLF_db_total_temp
						SELECT @name, COUNT(*) FROM #VLF_temp1

						TRUNCATE TABLE #VLF_temp1
					END
				ELSE
					BEGIN
						INSERT INTO #VLF_temp2
						EXEC ('DBCC LOGINFO ([' + @name + ']) WITH NO_INFOMSGS')

						INSERT INTO #VLF_db_total_temp
						SELECT @name, COUNT(*) FROM #VLF_temp2

						TRUNCATE TABLE #VLF_temp2
					END
		  END
		  FETCH NEXT FROM db_cursor INTO @name
	END
 
	CLOSE db_cursor
	DEALLOCATE db_cursor
 
 
	SELECT @@servername as [ServerName], name as [DBName], vlf_count as [VLFCount]
	FROM #VLF_db_total_temp
	ORDER BY vlf_count DESC;

	IF ( OBJECT_ID('tempdb..#VLF_temp1') IS NOT NULL )
		BEGIN
			DROP TABLE #VLF_temp1;
		END
	IF ( OBJECT_ID('tempdb..#VLF_temp2') IS NOT NULL )
		BEGIN
			DROP TABLE #VLF_temp2;
		END
	IF ( OBJECT_ID('tempdb..#VLF_db_total_temp') IS NOT NULL )
		BEGIN
			DROP TABLE #VLF_db_total_temp;
		END
END TRY 
BEGIN CATCH
    IF (XACT_STATE()) = -1  
    BEGIN  
        ROLLBACK TRANSACTION;  
    END;  
  
    IF (XACT_STATE()) = 1  
    BEGIN  
        COMMIT TRANSACTION;     
    END;

	-- Test if there are still open cursors and close them
	IF (SELECT CURSOR_STATUS('global','db_cursor')) >= -1
	BEGIN
		IF (SELECT CURSOR_STATUS('global','db_cursor')) > -1
			BEGIN
				CLOSE db_cursor
			END
		DEALLOCATE db_cursor
	END
END CATCH
"

            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = $CommandString;
            $SqlConnection.Open();


            $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
            $Sqlcmd.Connection = $SqlConnection;
            $SQLCmd.CommandText = $QueryText;

            $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
            $DataSet = New-Object System.Data.DataSet;
            $DataAdapter.Fill($DataSet) | Out-Null;


            $VLFCount = $DataSet.Tables[0] | Format-Table;

            return $VLFCount;
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-DBCCLastKnownGood
{
<#

.SYNOPSIS
The function connects to the SQL Server Instance specified, and determines the last DBCC CheckDB runs for each database.

.DESCRIPTION
This function connects to the SQL Server instance and loops through all of the databases present, determining the
last successful DBCC CHECKDB run for those databases. No filtering is performed, this is simply a report of the current 
state. Data is returned through the PS pipeline and can be filtered upon return.

.PARAMETER SQLInstance
    The target SQL Server instance we wish to collect DBCC CheckDB data from.

.EXAMPLE
    Get-DBCCLastKnownGood -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;
            
            $serverInstance = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $SQLConfig.SQLInstance;
            foreach($db in $serverInstance.Databases)
                {
                    Write-Debug "Getting CHECKDB Dates for $db"
                    if ($db.IsAccessible)
                        {
                            $DBCCLastRun = $db.ExecuteWithResults("DBCC DBINFO () WITH TABLERESULTS").Tables[0] | Where-Object {$_.Field -eq "dbi_dbccLastKnownGood"}

                            $DBCCinfo = $db | Select @{Name='Database Name'; Expression = {$db.Name}}, @{Name='DBCC-Date'; Expression={$DBCCLastRun.Value}}
                        }
                    Write-Output $DBCCinfo
                }
    
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-WaitStats
{
<#

.SYNOPSIS
The function connects to the SQL Server Instance specified, and pulls out the Wait Statistics for the instance.

.DESCRIPTION
This function connects to the SQL Server instance and uses a well known Wait Statistics T-SQL script to determine
the top Waits which are occuring on the instance. These are returned in a percentage ordered list.

.PARAMETER SQLInstance
    The target SQL Server instance we wish to collect Wait Statistics data from.

.EXAMPLE
    Get-WaitStats -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

           [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
            $QueryText =  "WITH [Waits] AS
    (SELECT
        [wait_type],
        [wait_time_ms] / 1000.0 AS [WaitS],
        ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
        [signal_wait_time_ms] / 1000.0 AS [SignalS],
        [waiting_tasks_count] AS [WaitCount],
       100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
        ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
    FROM sys.dm_os_wait_stats
    WHERE [wait_type] NOT IN (
        N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR',
        N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
        N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
        N'CHKPT', N'CLR_AUTO_EVENT',
        N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
 
        -- Maybe uncomment these four if you have mirroring issues
        N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE',
        N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD',
 
        N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC', N'FSAGENT',
        N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
 
        -- Maybe uncomment these six if you have AG issues
        N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
        N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
 
        N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP',
        N'LOGMGR_QUEUE', N'MEMORY_ALLOCATION_EXT',
        N'ONDEMAND_TASK_QUEUE',
        N'PREEMPTIVE_XE_GETTARGETSTATE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED',
        N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', N'QDS_ASYNC_QUEUE',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
        N'QDS_SHUTDOWN_QUEUE', N'REDO_THREAD_PENDING_WORK',
        N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
        N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH',
        N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
        N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP',
        N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT',
        N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS',
        N'WAITFOR', N'WAITFOR_TASKSHUTDOWN',
        N'WAIT_XTP_RECOVERY',
        N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
        N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
    AND [waiting_tasks_count] > 0
    )
SELECT
    MAX ([W1].[wait_type]) AS [WaitType],
    CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [Wait_S],
    CAST (MAX ([W1].[ResourceS]) AS DECIMAL (16,2)) AS [Resource_S],
    CAST (MAX ([W1].[SignalS]) AS DECIMAL (16,2)) AS [Signal_S],
    MAX ([W1].[WaitCount]) AS [WaitCount],
    CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [Percentage],
    CAST ((MAX ([W1].[WaitS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgWait_S],
    CAST ((MAX ([W1].[ResourceS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgRes_S],
    CAST ((MAX ([W1].[SignalS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgSig_S],
    CAST ('https://www.sqlskills.com/help/waits/' + MAX ([W1].[wait_type]) as XML) AS [Help/Info URL]
FROM [Waits] AS [W1]
INNER JOIN [Waits] AS [W2]
    ON [W2].[RowNum] <= [W1].[RowNum]
GROUP BY [W1].[RowNum]
HAVING SUM ([W2].[Percentage]) - MAX( [W1].[Percentage] ) < 95;
"

            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = $CommandString;
            $SqlConnection.Open();


            $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
            $Sqlcmd.Connection = $SqlConnection;
            $SQLCmd.CommandText = $QueryText;

            $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
            $DataSet = New-Object System.Data.DataSet;
            $DataAdapter.Fill($DataSet) | Out-Null;


            $Waits =$DataSet.Tables[0] | Format-Table;

            return $Waits;
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-LatchStats
{
<#

.SYNOPSIS
The function connects to the SQL Server Instance specified, and pulls out the Latch Statistics for the instance.

.DESCRIPTION
This function connects to the SQL Server instance and uses a well known Latch Statistics T-SQL script to determine
the top Latches which are occuring on the instance. These are returned in a percentage ordered list.

.PARAMETER SQLInstance
    The target SQL Server instance we wish to collect Latch Statistics data from.

.EXAMPLE
    Get-LatchStats -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
            $QueryText =  "WITH Latches AS
     (SELECT
         latch_class,
         wait_time_ms / 1000.0 AS WaitS,
         waiting_requests_count AS WaitCount,
         100.0 * wait_time_ms / SUM (wait_time_ms) OVER() AS Percentage,
         ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS RowNum
     FROM sys.dm_os_latch_stats
     WHERE latch_class NOT IN ('BUFFER')
     AND wait_time_ms > 0
     )
 SELECT
     W1.latch_class AS LatchClass, 
    CAST (W1.WaitS AS DECIMAL(14, 2)) AS Wait_S,
     W1.WaitCount AS WaitCount,
     CAST (W1.Percentage AS DECIMAL(14, 2)) AS Percentage,
     CAST ((W1.WaitS / W1.WaitCount) AS DECIMAL (14, 4)) AS AvgWait_S
 FROM Latches AS W1
 INNER JOIN Latches AS W2
     ON W2.RowNum <= W1.RowNum
 WHERE W1.WaitCount > 0
 GROUP BY W1.RowNum, W1.latch_class, W1.WaitS, W1.WaitCount, W1.Percentage
 HAVING SUM (W2.Percentage) - W1.Percentage < 95;
"

            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = $CommandString;
            $SqlConnection.Open();


            $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
            $Sqlcmd.Connection = $SqlConnection;
            $SQLCmd.CommandText = $QueryText;

            $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
            $DataSet = New-Object System.Data.DataSet;
            $DataAdapter.Fill($DataSet) | Out-Null;


            $Latches =$DataSet.Tables[0] | format-table;

            return $Latches;
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-BlockingChain
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment, and determine the session level
blocking chain - showing it for easy use.

.DESCRIPTION
Connect to teh specified SQL Server envrionment, and work through all of the existing sessions,
looking for the sessions which are lead blockers. Highlight those lead blockers and the chains of
other sessions which those lead blockers have generated.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.EXAMPLE
    Get-BlockingChain -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
            $QueryText =  "IF OBJECT_ID('tempdb..#Processes') IS NOT NULL
	DROP TABLE #Processes;

SELECT
    der.session_id, 
    der.blocking_session_id AS BlockingSessionID,
    DB_NAME(des.database_id) AS DatabaseName,
	des.program_name,
	des.host_process_id, 
    des.nt_domain,
	des.nt_user_name,
	dec.client_net_address,
	dec.client_tcp_port,
    der.wait_type,
	der.wait_time,
	der.last_wait_type,
    CAST(dest.text AS VARCHAR(MAX)) AS SQLText,
	deqp.query_plan AS SQLPlan
INTO  #Processes
FROM
	sys.dm_exec_requests der
INNER JOIN sys.dm_exec_sessions des
	ON der.session_id = des.session_id
INNER JOIN sys.dm_exec_connections dec
	ON der.session_id = dec.session_id
CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) AS dest
CROSS APPLY sys.dm_exec_query_plan(der.plan_handle) AS deqp
WHERE
	des.is_user_process = 1;

WITH Blocking(Session_ID, BlockingSessionID, DatabaseName, ProgramName, HostProcessID, Domain, UserName, ClientHost, ClientPort, WaitTime, WaitType, LastWaitType, BlockingStatement, BlockingPlan, RowNo, LevelRow)
AS
 (
     SELECT 
		s.session_id, 
		s.BlockingSessionID,
		s.DatabaseName, 
		s.Program_Name, 
		s.host_process_id,
		s.nt_domain, 
		s.nt_user_name,
		s.client_net_address,
		s.client_tcp_port,
		s.Wait_Time, 
		s.Wait_Type, 
		s.Last_Wait_Type, 
		s.SQLText, 
		s.SQLPlan,
		ROW_NUMBER() OVER(ORDER BY s.session_id), 0 AS LevelRow
     FROM 
		#Processes s
     INNER JOIN #Processes s1 
			ON s.session_id = s1.BlockingSessionID
     WHERE s.BlockingSessionID = 0
     UNION ALL
     SELECT 
		r.session_id,  
		r.BlockingSessionID, 
		r.DatabaseName, 
		r.Program_Name, 
		r.host_process_id,
		r.nt_domain, 
		r.nt_user_name,
		r.client_net_address,
		r.client_tcp_port,
		r.Wait_Time, 
		r.Wait_Type, 
		r.Last_Wait_Type, 
		r.SQLText,
		r.SQLPlan, 
		d.RowNo, 
		d.LevelRow + 1
     FROM #Processes r
     INNER JOIN Blocking d 
		ON r.BlockingSessionID = d.Session_id
     WHERE r.BlockingSessionID > 0
 )
 SELECT 
	CASE
		WHEN LevelRow = 0 THEN 'Lead Blocker' 
	ELSE 'Blocked'
	END AS [Blocking Status],
	Session_ID,
	BlockingSessionID,
	DatabaseName,
	ProgramName, 
	HostProcessID,
	ISNULL(Domain, '') + '\' + UserName AS UserName, 
	ClientHost,
	ClientPort,
	WaitTime, 
	WaitType, 
	LastWaitType, 
	BlockingStatement,
	BlockingPlan,
	RowNo,
	LevelRow 
FROM 
	Blocking
 ORDER BY 
	RowNo, LevelRow
"

            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = $CommandString;
            $SqlConnection.Open();


            $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
            $Sqlcmd.Connection = $SqlConnection;
            $SQLCmd.CommandText = $QueryText;

            $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
            $DataSet = New-Object System.Data.DataSet;
            $DataAdapter.Fill($DataSet) | Out-Null;


            $BlockChain =$DataSet.Tables[0] | Format-Table;

            return $BlockChain;
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-RunningAgentJobs
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment, and determine if there are any SQL Agent jobs
currently running.

.DESCRIPTION
Connect to the specified SQL Server envrionment, and determine if any of the scheduled SQL Agent jobs
are running.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.EXAMPLE
    Get-RunningAgentJobs -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
            $QueryText =  "DECLARE @is_sysadmin INT
DECLARE @job_owner SYSNAME

SELECT @is_sysadmin = ISNULL(IS_SRVROLEMEMBER(N'sysadmin'), 0)
SELECT @job_owner = SUSER_SNAME()


IF OBJECT_ID('tempdb..#xp_results') IS NOT NULL
	DROP TABLE #xp_results

CREATE TABLE #xp_results (
		job_id                UNIQUEIDENTIFIER NOT NULL,
		last_run_date         INT              NOT NULL,
	    last_run_time         INT              NOT NULL,
	    next_run_date         INT              NOT NULL,
	    next_run_time         INT              NOT NULL,
	    next_run_schedule_id  INT              NOT NULL,
	    requested_to_run      INT              NOT NULL,
	    request_source        INT              NOT NULL,
	    request_source_id     SYSNAME          COLLATE database_default NULL,
	    running               INT              NOT NULL,
	    current_step          INT              NOT NULL,
	    current_retry_attempt INT              NOT NULL,
	    job_state             INT              NOT NULL
		);


INSERT INTO #xp_results
EXECUTE master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @job_owner

SELECT
	sj.name
	, sj.enabled
	, sj.description
	, sj.start_step_id
	, xpr.job_id
	, xpr.current_step
	, xpr.running
	, CASE xpr.job_state
		WHEN 0 THEN 'Returns only those jobs that are not idle or suspended.'
		WHEN 1 THEN 'Executing.'
		WHEN 2 THEN 'Waiting for thread.'
		WHEN 3 THEN 'Between retries.'
		WHEN 4 THEN 'Idle.'
		WHEN 5 THEN 'Suspended.'
		WHEN 7 THEN 'Performing completion actions'
	  ELSE
		'Unknown State' END AS [Execution State]
	, xpr.last_run_date
	, xpr.last_run_time
	, xpr.next_run_date
	, xpr.next_run_time
	, xpr.requested_to_run
	, xpr.request_source	
FROM #xp_results xpr
INNER JOIN msdb.dbo.sysjobs sj ON  xpr.job_id = sj.job_id
WHERE xpr.job_state = 1
"

            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = $CommandString;
            $SqlConnection.Open();


            $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
            $Sqlcmd.Connection = $SqlConnection;
            $SQLCmd.CommandText = $QueryText;

            $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
            $DataSet = New-Object System.Data.DataSet;
            $DataAdapter.Fill($DataSet) | Out-Null;


            $RunningJobs =$DataSet.Tables[0] | Format-Table;

            return $RunningJobs;
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-FailedAgentJobs
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment, and determine if there are any failed SQL Agent jobs.
If there are, list them out.

.DESCRIPTION
Connect to the specified SQL Server envrionment, and determine if any of the scheduled SQL Agent jobs
hve failed.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.EXAMPLE
    Get-FailedAgentJobs -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>

    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $SMOServer = New-Object ('Microsoft.SQLServer.Management.Smo.Server') $($SQLConfig.SQLInstance);
            
            $FailedJobs = $SMOServer.JobServer.Jobs | `
                            Where { $_.LastRunOutcome -ne 'Succeeded' -AND $_.IsEnabled -eq $true } | `
                            Select Name, Category, LastRunDate, LastRunOutcome | Format-Table; 

            return $FailedJobs;
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}
    
function Get-DBStartupTimes
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment, and determine all of the database startup sections, and times
for each section.

.DESCRIPTION
Connect to the specified SQL Server envrionment, and determine for a particular database, what sections of the
database startup took the most time.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.PARAMETER Database
    The SQL Server Database to determine the startup timings for.

.EXAMPLE
    Get-DBStartupTimes -SQLInstance [ServerName | ServerName\InstanceName] -Database [DatabaseName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance,
            [Parameter(Mandatory=$true)][string]$Database )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $SQLConfig.Database = $Database;

            $SMOServer = New-Object ('Microsoft.SQLServer.Management.Smo.Server') $($SQLConfig.SQLInstance);
            if ( $SMOServer -eq $null )
                {
                    Write-Host "Server $($SQLConfig.SQLInstance) cannot be contacted." -ForegroundColor Red;
                }

            $SMODatabases = $SMOServer.Databases | Select Name;

            if ( $SMODatabases.Name -notcontains $SQLConfig.Database )
                {
                    Write-Host "The Database: $($SQLConfig.Database) does not exist on Server: $($SQLConfig.SQLInstance)." -ForegroundColor Red;
                }
            else
                {

                    $CommandString = "Server=$($SQLConfig.SQLInstance);Database=$($SQLConfig.Database);Integrated Security=True"
    
                    $QueryText =  "DECLARE @SQLCMD VARCHAR(128)
                                    SET @SQLCMD = 'DBCC DBTABLE (''' + DB_NAME() + ''') WITH TABLERESULTS';
                                    IF OBJECT_ID('tempdb.dbo.#StartupTimes') IS NOT NULL 
	                                    BEGIN
		                                    DROP TABLE #StartupTimes
	                                    END;

                                    CREATE TABLE #StartupTimes (
                                        ParentObject VARCHAR(255),
                                        Object       VARCHAR(255),
                                        Field        VARCHAR(255),
                                        Value        VARCHAR(255));

                                    INSERT INTO #StartupTimes
                                    EXECUTE ( @SQLCMD );

                                    SELECT * FROM #StartupTimes
                                    WHERE Field = 'StartupPhase'";

                    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
                    $SqlConnection.ConnectionString = $CommandString;
                    $SqlConnection.Open();


                    $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
                    $Sqlcmd.Connection = $SqlConnection;
                    $SQLCmd.CommandText = $QueryText;

                    $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
                    $DataSet = New-Object System.Data.DataSet;
                    $DataAdapter.Fill($DataSet) | Out-Null;


                    $DBStart =$DataSet.Tables[0] | Format-Table;

                    return $DBStart;
                }
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-PLEByNumaNode
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment, and display the PLE (Page Life Expectancy) by Numa Node. 

.DESCRIPTION
Connect to the specified SQL Server environment, and display the PLE (Page Life Expectancy) by Numa Node. 
This can be a very different measure from the overall PLE, and is a better metric to use.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.EXAMPLE
    Get-PLEByNumaNode -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
            $QueryText =  "SELECT 
	LTRIM(RTRIM(ple.[Node])) AS [Node]
	,LTRIM(STR([PageLife_S]/3600))+':'+REPLACE(STR([PageLife_S]%3600/60,2),SPACE(1),'0')+':'+REPLACE(STR([PageLife_S]%60,2),SPACE(1),'0') [PageLife (HH:MM:SS)] 
	,dp.[DatabasePages] AS [No. of BPool Pages] 
	,CONVERT(DECIMAL(15,3),dp.[DatabasePages] / 128) AS [BufferPool (MB)] 
FROM 
	( 
	SELECT [instance_name] [node],[cntr_value] [PageLife_S] 
	FROM sys.dm_os_performance_counters 
	WHERE [counter_name] = 'Page life expectancy' 
	) ple 
INNER JOIN 
	( 
	SELECT [instance_name] [node],[cntr_value] [DatabasePages] 
	FROM sys.dm_os_performance_counters 
	WHERE [counter_name] = 'Database pages' 
	) dp ON ple.[node] = dp.[node] 
"

            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = $CommandString;
            $SqlConnection.Open();


            $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
            $Sqlcmd.Connection = $SqlConnection;
            $SQLCmd.CommandText = $QueryText;

            $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
            $DataSet = New-Object System.Data.DataSet;
            $DataAdapter.Fill($DataSet) | Out-Null;


            $PLEData = $DataSet.Tables[0] | Format-Table;

            return $PLEData;
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-EnabledTraceFlags
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment, and display the enabled trace flags in force in the instance. 

.DESCRIPTION
Connect to the specified SQL Server environment, and display the enabled trace flags in force in the instance.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.EXAMPLE
    Get-EnabledTraceFlags -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;
                      
            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
            $QueryText =  "DBCC TRACEON(3604);DBCC TRACESTATUS;";

            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = $CommandString;
            $SqlConnection.Open();


            $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
            $Sqlcmd.Connection = $SqlConnection;
            $SQLCmd.CommandText = $QueryText;

            $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
            $DataSet = New-Object System.Data.DataSet;
            $DataAdapter.Fill($DataSet) | Out-Null;


            $TraceFlags =$DataSet.Tables[0] | Format-Table;

            return $TraceFlags;
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-QueryMemory
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment, and display a breakdown of the memory in use by SQL Server.

.DESCRIPTION
Connect to the specified SQL Server environment, and display a breakdown of the memory in use by SQL Server. 
This includes all Memory Broker Caches, Memory Grants, Optimiser Memory, Workspace Memory and Database Buffers.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.EXAMPLE
    Get-QueryMemory -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;
                        
            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
            $QueryText =  "WITH Memory AS
(
SELECT
	LTRIM(RTRIM(counter_name)) AS [counter_name],
	LTRIM(RTRIM(cntr_value)) AS [cntr_value],
	100. * cntr_value / SUM(cntr_value) OVER() AS pct,
	ROW_NUMBER() OVER(ORDER BY cntr_value DESC) AS rn
FROM
	sys.dm_os_performance_counters
WHERE
	object_name = '$($SQLConfig.ServiceName):Memory Manager'
AND	counter_name IN 
	(	
		'Connection Memory (KB)' --Specifies the total amount of dynamic memory the server is using for maintaining connections.
		,'Database Cache Memory (KB)' --Specifies the amount of memory the server is currently using for the database pages cache.
		,'Free Memory (KB)' -- Specifies the amount of committed memory currently not used by the server.
		,'Granted Workspace Memory (KB)' -- Specifies the total amount of memory currently granted to executing processes, such as hash, sort, bulk copy, and index creation operations.
		,'Lock Blocks' -- Specifies the current number of lock blocks in use on the server (refreshed periodically). A lock block represents an individual locked resource, such as a table, page, or row.
		,'Lock Blocks Allocated' -- Specifies the current number of allocated lock blocks. At server startup, the number of allocated lock blocks plus the number of allocated lock owner blocks depends on the SQL Server Locks configuration option. If more lock blocks are needed, the value increases.
		,'Lock Memory (KB)' -- Specifies the total amount of dynamic memory the server is using for locks.
		,'Lock Owner Blocks' -- Specifies the number of lock owner blocks currently in use on the server (refreshed periodically). A lock owner block represents the ownership of a lock on an object by an individual thread. Therefore, if three threads each have a shared (S) lock on a page, there will be three lock owner blocks.
		,'Lock Owner Blocks Allocated' -- Specifies the current number of allocated lock owner blocks. At server startup, the number of allocated lock owner blocks and the number of allocated lock blocks depend on the SQL Server Locks configuration option. If more lock owner blocks are needed, the value increases dynamically.
		,'Maximum Workspace Memory (KB)' -- Indicates the maximum amount of memory available for executing processes, such as hash, sort, bulk copy, and index creation operations.
		,'Memory Grants Outstanding' -- Specifies the total number of processes that have successfully acquired a workspace memory grant.
		,'Memory Grants Pending' -- Specifies the total number of processes waiting for a workspace memory grant.
		,'Optimizer Memory (KB)' -- Specifies the total amount of dynamic memory the server is using for query optimization.
		,'Reserved Server Memory (KB)' -- Indicates the amount of memory the server has reserved for future usage. This counter shows the current unused amount of memory initially granted that is shown in Granted Workspace Memory (KB).
		,'SQL Cache Memory (KB)'  -- Specifies the total amount of dynamic memory the server is using for the dynamic SQL cache.
		,'Stolen Server Memory (KB)' -- Specifies the amount of memory the server is using for purposes other than database pages.
		--,'Target Server Memory (KB)' -- Indicates the ideal amount of memory the server can consume.
		--,'Total Server Memory (KB)' -- Specifies the amount of memory the server has committed using the memory manager.
	))
SELECT 
	M1.counter_name,
	M1.cntr_value,
	CAST(M1.pct AS DECIMAL(12, 2)) AS [%],
	CAST(SUM(M2.pct) AS DECIMAL(12, 2)) AS [Running %]
FROM
	Memory AS M1
INNER JOIN Memory AS M2 ON M2.rn <= M1.rn
GROUP BY 
	M1.rn, M1.counter_name, M1.cntr_value, M1.pct
HAVING
	SUM(M2.pct) - M1.pct < 99.99 
ORDER BY 3 DESC	
OPTION (RECOMPILE)
"

            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = $CommandString;
            $SqlConnection.Open();


            $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
            $Sqlcmd.Connection = $SqlConnection;
            $SQLCmd.CommandText = $QueryText;

            $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
            $DataSet = New-Object System.Data.DataSet;
            $DataAdapter.Fill($DataSet) | Out-Null;


            $QueryMemory =$DataSet.Tables[0] | format-table;

            return $QueryMemory;
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-SlowLDFs
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment, and determine which LDFs are running slowly.

.DESCRIPTION
Connect to the specified SQL Server envrionment, and determine which LDFs are the slowest in terms of read
and write latency to the disk. Uses fn_virtual_file_stats to determine the timings.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.EXAMPLE
    Get-SlowLDFs -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

           [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
            $QueryText =  "SELECT 
	DB_NAME (vfs.database_id) AS [DB (LDF)],
	vfs.database_id,
	LEFT (mf.physical_name, 2) AS Drive,
	vfs.size_on_disk_bytes / 1024 / 1024 AS [Size On Disk (MB)],
    [ReadLatency (ms)] =
		CASE WHEN num_of_reads = 0
			THEN 0 ELSE (io_stall_read_ms / num_of_reads) END,
	[WriteLatency (ms)] =
		CASE WHEN num_of_writes = 0 
			THEN 0 ELSE (io_stall_write_ms / num_of_writes) END,
	[Latency (ms)] =
		CASE WHEN (num_of_reads = 0 AND num_of_writes = 0)
			THEN 0 ELSE (io_stall / (num_of_reads + num_of_writes)) END,
  --avg bytes per IOP
	AvgBPerRead =
		CASE WHEN num_of_reads = 0 
			THEN 0 ELSE (num_of_bytes_read / num_of_reads) END,
	AvgBPerWrite =
		CASE WHEN io_stall_write_ms = 0 
			THEN 0 ELSE (num_of_bytes_written / num_of_writes) END,
	AvgBPerTransfer =
		CASE WHEN (num_of_reads = 0 AND num_of_writes = 0)
			THEN 0 ELSE
				((num_of_bytes_read + num_of_bytes_written) / 
				(num_of_reads + num_of_writes)) END
FROM sys.dm_io_virtual_file_stats (NULL,NULL) AS vfs
INNER JOIN sys.master_files AS mf ON vfs.database_id = mf.database_id
	AND vfs.file_id = mf.file_id
WHERE vfs.file_id = 2
ORDER BY [WriteLatency (ms)] DESC"

            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = $CommandString;
            $SqlConnection.Open();


            $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
            $Sqlcmd.Connection = $SqlConnection;
            $SQLCmd.CommandText = $QueryText;

            $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
            $DataSet = New-Object System.Data.DataSet;
            $DataAdapter.Fill($DataSet) | Out-Null;

            $SlowLDFs = $DataSet.Tables[0] | Format-Table;

            return $SlowLDFs;
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-UserActivity
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment, and determine what activity a particular user has been doing 
within the specified database.

.DESCRIPTION
Connect to the specified SQL Server envrionment, and for the specified database, determine the most recent
activity of the specified user. NOTE - this function trawls through the transaction log, and could take some
time to execute.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.PARAMETER Database
    The database within the SQL Server instance to connect into and trawl the transaction log for.

.PARAMETER UserName
    The User for the SQL Server database to find activity for

.EXAMPLE
    Get-UserActivity -SQLInstance [ServerName | ServerName\InstanceName] -Database [DatabaseName] -User [UserName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance,
            [Parameter(Mandatory=$true)][string]$Database, 
            [Parameter(Mandatory=$true)][string]$User )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $SQLConfig.Database = $Database;
            $SQLConfig.User = $User;

            $SMOServer = New-Object ('Microsoft.SQLServer.Management.Smo.Server') $($SQLConfig.SQLInstance);
            if ( $SMOServer -eq $null )
                {
                    Write-Host "Server $($SQLConfig.SQLInstance) cannot be contacted." -ForegroundColor Red;
                }

            $SMODatabases = $SMOServer.Databases | Select Name;

            if ( $SMODatabases.Name -notcontains $SQLConfig.Database )
                {
                    Write-Host "The Database: $($SQLConfig.Database) does not exist on Server: $($SQLConfig.SQLInstance)." -ForegroundColor Red;
                }
            else
                {

                    $CommandString = "Server=$($SQLConfig.SQLInstance);Database=$($SQLConfig.Database);Integrated Security=True"
    
                    $QueryText =  "SELECT
    [Current LSN],
    [Operation],
    [Transaction ID],
    [Begin Time],
    LEFT ([Description], 40) AS [Description]
FROM
    fn_dblog (NULL, NULL)
WHERE
    [Transaction SID] = SUSER_SID ('$($SQLConfig.User)');"


                    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
                    $SqlConnection.ConnectionString = $CommandString;
                    $SqlConnection.Open();


                    $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
                    $Sqlcmd.Connection = $SqlConnection;
                    $SQLCmd.CommandText = $QueryText;

                    $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
                    $DataSet = New-Object System.Data.DataSet;
                    $DataAdapter.Fill($DataSet) | Out-Null;


                    $Activity =$DataSet.Tables[0] | Format-Table;

                    return $Activity;
                }
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-InstanceStartupTime
{
<#

.SYNOPSIS
Connect into the Specified SQL Server instance, and determine the time when the SQL Server last started.

.DESCRIPTION
Connect into the Specified SQL Server instance, and determine the time when the SQL Server last started.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.EXAMPLE
    Get-InstanceStartupTime -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;
            
            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
            $QueryText =  "EXEC sp_readerrorlog"

            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
            $SqlConnection.ConnectionString = $CommandString;
            $SqlConnection.Open();


            $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
            $Sqlcmd.Connection = $SqlConnection;
            $SQLCmd.CommandText = $QueryText;

            $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
            $DataSet = New-Object System.Data.DataSet;
            $DataAdapter.Fill($DataSet) | Out-Null;

            $InstanceHardStartupTime = ($DataSet.Tables[0].Rows | Where { $_.Text -match "SQL Server is starting at" }).LogDate;
            $InstanceSoftStartupTime = ($DataSet.Tables[0].Rows | Where { $_.Text -match "This instance of SQL Server has been using a process ID of" }).LogDate;

            Write-Host "Instance Hard Re-start at: $InstanceHardStartupTime" -ForegroundColor Green;
            Write-Host "Instance Soft Re-start(s) at: $InstanceSoftStartupTime" -ForegroundColor Green;

            return;

        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-LastSQLPatch
{
<#

.SYNOPSIS
Connect to the server hosting the SQL Server instance and determine the last patch time.

.DESCRIPTION
Connect to the server hosting the SQL Server instance, and determine from the Bootstrap folder structure,
what the last patch which was applied was, and also when it was applied.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.EXAMPLE
    Get-LastSQLPatch -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects; 

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;
    
            $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $SQLConfig.ServerName);
            $RegKey= $Reg.OpenSubKey("SOFTWARE\Microsoft\Microsoft SQL Server\$($SQLConfig.InstanceName)\MSSQLServer\CurrentVersion")
            $Version = $RegKey.GetValue("CurrentVersion");
            $MajorVersion = $Version.split('.')[0];

            $UnInstallList = Invoke-command -computer $($SQLConfig.ServerName) `
                            {Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty };
            $Data = $UnInstallList | `
            Where-Object { ($_.DisplayName -like "Hotfix*SQL*") -or ($_.DisplayName -like "Service Pack*SQL*") } | ` 
            Where-Object { ($_.DisplayVersion).split('.')[0] -eq $MajorVersion } | `
            Sort-Object -Property InstallDate | `
            Select InstallDate, KBNumber, ProductVersion, PatchProductVersion, PatchType, SPLevel, DisplayName, DisplayVersion | `
            Format-Table;

            Return $Data;

        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-CreateDBSnapshot
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment and database, and creates a new snapshot for that database.

.DESCRIPTION
Connect to the specified SQL Server environment and database, and creates a new snapshot for that database.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.PARAMETER DatabaseToSnapshot
    The SQL Server Database to create the snapshot for.

.PARAMETER SnapshotName
    The Name of the Snapshot which is being created.

.EXAMPLE
    Get-CreateDBSnapshot -SQLInstance [ServerName | ServerName\InstanceName] -DatabaseToSnapshot [DatabaseName] -SnapshotName [NewName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance,
            [Parameter(Mandatory=$true)][string]$DatabaseToSnapshot,
            [Parameter(Mandatory=$true)][string]$SnapshotName )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $SQLConfig.DatabaseToSnapshot = $DatabaseToSnapshot;
            $SQLConfig.SnapshotName = $SnapshotName;

            $SMOServer = New-Object ('Microsoft.SQLServer.Management.Smo.Server') $($SQLConfig.SQLInstance);
            if ( $SMOServer -eq $null )
                {
                    Write-Host "Server $($SQLConfig.SQLInstance) cannot be contacted." -ForegroundColor Red;
                }

            $SMODatabases = $SMOServer.Databases | Select Name;

            if ( $SMODatabases.Name -notcontains $SQLConfig.DatabaseToSnapshot )
                {
                    Write-Host "The Database: $($SQLConfig.DatabaseToSnapshot) does not exist on Server: $($SQLConfig.SQLInstance)." -ForegroundColor Red;
                }
            else
                {

                    $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
                    $QueryText =  "DECLARE @SQL NVARCHAR(MAX);
SELECT @SQL = 'CREATE DATABASE [$($SQLConfig.SnapshotName)] ON
' +
STUFF((SELECT ',(NAME = ' + 
Name + 
',FILENAME=''' +  
REVERSE(RIGHT(REVERSE(physical_name), LEN(physical_name) - CHARINDEX('.',REVERSE(physical_name), 1))) + 
'.ss','''' + 
')'
FROM sys.master_files
WHERE database_id = DB_ID('$($SQLConfig.DatabaseToSnapshot)')
AND [type] = 0 --ROWS
FOR XML PATH(''),TYPE).value('.','NVARCHAR(MAX)'),1,1,' ')
+ ' AS SNAPSHOT OF [$($SQLConfig.DatabaseToSnapshot)]';

EXEC sp_executesql @SQL;";

                    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
                    $SqlConnection.ConnectionString = $CommandString;
                    $SqlConnection.Open();


                    $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
                    $Sqlcmd.Connection = $SqlConnection;
                    $SQLCmd.CommandText = $QueryText;

                    $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
                    $DataSet = New-Object System.Data.DataSet;
                    $DataAdapter.Fill($DataSet) | Out-Null;


                    $DBSnap =$DataSet.Tables[0] | Format-Table;

                    return $DBSnap;
                }
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-DropDBSnapshot
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment, and drops an existing database snapshot.

.DESCRIPTION
Connect to the specified SQL Server environment, and drops the specified database snapshot.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.PARAMETER SnapshotToDrop
    The SQL Server Database to drop the snapshot of.

.EXAMPLE
    Get-CreateDBSnapshot -SQLInstance [ServerName | ServerName\InstanceName] -SnapshotToDrop [DatabaseName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance,
            [Parameter(Mandatory=$true)][string]$SnapshotToDrop )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $SQLConfig.SnapshotToDrop = $SnapshotToDrop;

            $SMOServer = New-Object ('Microsoft.SQLServer.Management.Smo.Server') $($SQLConfig.SQLInstance);
            if ( $SMOServer -eq $null )
                {
                    Write-Host "Server $($SQLConfig.SQLInstance) cannot be contacted." -ForegroundColor Red;
                }

            $SMODatabases = $SMOServer.Databases | Select Name;

            # Check if the Database exists
            if ( $SMODatabases.Name -notcontains $SQLConfig.SnapshotToDrop )
                {
                    Write-Host "The Database: $($SQLConfig.SnapshotToDrop) does not exist on Server: $($SQLConfig.SQLInstance)." -ForegroundColor Red;
                }
            
            # Check the Database is actually a snapshot
            $SMOSnapshots = $SMOServer.Databases | Where { $_.Name -eq $($SQLConfig.SnapshotToDrop) };
            if ( $SMOSnapshots.IsDatabaseSnapshot -ne $true )
                {
                    Write-Host "The Database: $($SQLConfig.SnapshotToDrop) is not a valid Snapshot." -ForegroundColor Red;
                }
            else
                {

                    $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
                    $QueryText =  "DROP DATABASE $($SQLConfig.SnapshotToDrop)";

                    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
                    $SqlConnection.ConnectionString = $CommandString;
                    $SqlConnection.Open();


                    $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
                    $Sqlcmd.Connection = $SqlConnection;
                    $SQLCmd.CommandText = $QueryText;

                    $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
                    $DataSet = New-Object System.Data.DataSet;
                    $DataAdapter.Fill($DataSet) | Out-Null;


                    $DBSnapDrop =$DataSet.Tables[0] | Format-Table;

                    return $DBSnapDrop;
                }
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-ProcedureCacheByStore
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment and breaks down the Procedure Cache by Store type.

.DESCRIPTION
Connect to the specified SQL Server environment and breaks down the Procedure Cache by Store type.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.EXAMPLE
    Get-ProcedureCacheByStore -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $SMOServer = New-Object ('Microsoft.SQLServer.Management.Smo.Server') $($SQLConfig.SQLInstance);
            if ( $SMOServer -eq $null )
                {
                    Write-Host "Server $($SQLConfig.SQLInstance) cannot be contacted." -ForegroundColor Red;
                }
            else
                {
                    $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
                    $QueryText =  "SELECT
	type AS [Store],
	CASE type
		WHEN 'MEMOBJ_CACHESTOREOBJCP' THEN 'Stored Procedures, functions and Triggers'
		WHEN 'MEMOBJ_CACHESTORESQLCP' THEN 'Adhoc, prepared & auto-parameterized'
		WHEN 'MEMOBJ_CACHESTOREXPROC' THEN 'Extended Proc (sp_executesql)'
		WHEN 'MEMOBJ_CACHESTOREPHDR' THEN 'Bound Trees'
		WHEN 'MEMOBJ_SQLMGR' THEN 'T-SQL Text of all Adhoc and prepared queries'
	END AS [Description],
	SUM(pages_in_bytes / 8192) AS [Pages Used],
	SUM(pages_in_bytes / 1024) AS [Size KB]
FROM
	sys.dm_os_memory_objects
WHERE
	type IN ('MEMOBJ_CACHESTOREOBJCP', 'MEMOBJ_CACHESTORESQLCP', 
			 'MEMOBJ_CACHESTOREXPROC', 'MEMOBJ_SQLMGR', 'MEMOBJ_CACHESTOREPHDR')
GROUP BY
	type";

                    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
                    $SqlConnection.ConnectionString = $CommandString;
                    $SqlConnection.Open();


                    $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
                    $Sqlcmd.Connection = $SqlConnection;
                    $SQLCmd.CommandText = $QueryText;

                    $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
                    $DataSet = New-Object System.Data.DataSet;
                    $DataAdapter.Fill($DataSet) | Out-Null;


                    $ProcCacheByStore =$DataSet.Tables[0] | Format-Table;

                    return $ProcCacheByStore;
                }
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-ProcedureCacheByDatabase
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment and breaks down the Procedure Cache by Database.

.DESCRIPTION
Connect to the specified SQL Server environment and breaks down the Procedure Cache by Database.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.EXAMPLE
    Get-ProcedureCacheByDatabase -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $SMOServer = New-Object ('Microsoft.SQLServer.Management.Smo.Server') $($SQLConfig.SQLInstance);
            if ( $SMOServer -eq $null )
                {
                    Write-Host "Server $($SQLConfig.SQLInstance) cannot be contacted." -ForegroundColor Red;
                }
            else
                {
                    $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
                    $QueryText =  "SELECT 
	CASE
		WHEN [pa].[value] = 32767 THEN 'Resource DB'
		WHEN [pa].[value] <> 32767 THEN DB_NAME (CONVERT (INT, [pa].[value]))
	END AS [DBName]
	, SUM (decp.size_in_bytes) / 1024 / 1024 AS [Total Size of Plan Cache (MB)]
FROM 
	sys.dm_exec_cached_plans decp
CROSS APPLY sys.dm_exec_plan_attributes ([decp].[plan_handle]) AS [pa]
WHERE [pa].[attribute] = 'dbid' 
GROUP BY
		CASE
		WHEN [pa].[value] = 32767 THEN 'Resource DB'
		WHEN [pa].[value] <> 32767 THEN DB_NAME (CONVERT (INT, [pa].[value]))
	END
ORDER BY 
	SUM (decp.size_in_bytes) / 1024 / 1024 DESC";

                    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
                    $SqlConnection.ConnectionString = $CommandString;
                    $SqlConnection.Open();


                    $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
                    $Sqlcmd.Connection = $SqlConnection;
                    $SQLCmd.CommandText = $QueryText;

                    $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
                    $DataSet = New-Object System.Data.DataSet;
                    $DataAdapter.Fill($DataSet) | Out-Null;


                    $ProcCacheByDB =$DataSet.Tables[0] | Format-Table;

                    return $ProcCacheByDB;
                }
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-DiskAndFileFreeSpace
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment and list file free space and disk free space.

.DESCRIPTION
Connect to the specified SQL Server environment and list file free space and disk free space .

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.EXAMPLE
    Get-DiskAndFileFreeSpace [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $SMOServer = New-Object ('Microsoft.SQLServer.Management.Smo.Server') $($SQLConfig.SQLInstance);
            if ( $SMOServer -eq $null )
                {
                    Write-Host "Server $($SQLConfig.SQLInstance) cannot be contacted." -ForegroundColor Red;
                }
            else
                {
                    $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
                    $QueryText =  "SET NOCOUNT ON
DECLARE @DBName NVARCHAR(100) = NULL, --Provide DBName if looking for a specific database or leave to get all databases details
        @Drive NVARCHAR(2) = NULL --Mention drive letter if you are concerned of only a single drive where you are running out of space
 
DECLARE @cmd NVARCHAR(4000)
IF (SELECT OBJECT_ID('tempdb.dbo.#DBName')) IS NOT NULL
DROP TABLE #DBName
CREATE TABLE #DBName (Name NVARCHAR(100))
 
IF @DBName IS NOT NULL
INSERT INTO #DBName SELECT @DBName
ELSE
INSERT INTO #DBName SELECT Name FROM sys.databases WHERE state_desc = 'ONLINE'
 
IF (SELECT OBJECT_ID('tempdb.dbo.##FileStats')) IS NOT NULL
DROP TABLE ##FileStats
CREATE TABLE ##FileStats (ServerName NVARCHAR(100), DBName NVARCHAR(100), FileType NVARCHAR(100), 
FileName NVARCHAR(100), FileCurrentSizeMB FLOAT, FileFreeSpaceMB FLOAT, FilePercentMBFree FLOAT, FileLocation NVARCHAR(1000))
 
WHILE (SELECT TOP 1 * FROM #DBName) IS NOT NULL
BEGIN
 
    SELECT @DBName = MIN(Name) FROM #DBName
 
    SET @cmd = 'USE [' + @DBName + ']
    INSERT INTO ##FileStats
    SELECT @@ServerName AS ServerName, DB_NAME() AS DbName, 
    CASE WHEN type = 0 THEN ''DATA'' ELSE ''LOG'' END AS FileType,
    name AS FileName, 
    size/128.0 AS CurrentSizeMB,  
    size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0 AS FreeSpaceMB,
    100*(1 - ((CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0)/(size/128.0))) AS PercentMBFree,
    physical_name AS FileLocation
    FROM sys.database_files'
     
    IF @Drive IS NOT NULL
    SET @cmd = @cmd + ' WHERE physical_name LIKE ''' + @Drive + ':\%'''
 
    EXEC sp_executesql @cmd
     
    DELETE FROM #DBName WHERE Name = @DBName
     
END
 
SELECT 
	DBName,
	FileLocation,
	FileType,
	CAST(FileCurrentSizeMB AS DECIMAL(18,2)) AS [FileCurrentSizeMB],
	CAST(FileFreeSpaceMB AS DECIMAL(18,2)) AS [FileFreeSpaceMB],
	CAST(FilePercentMBFree AS DECIMAL(18,2)) AS [FilePercentMBFree]
FROM ##FileStats
ORDER BY DBName DESC
 
DROP TABLE #DBName
DROP TABLE ##FileStats
";

                    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
                    $SqlConnection.ConnectionString = $CommandString;
                    $SqlConnection.Open();


                    $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
                    $Sqlcmd.Connection = $SqlConnection;
                    $SQLCmd.CommandText = $QueryText;

                    $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
                    $DataSet = New-Object System.Data.DataSet;
                    $DataAdapter.Fill($DataSet) | Out-Null;

                    $FileData = $DataSet.Tables[0] | Format-Table;

                    $DiskData = Get-WMIObject Win32_Logicaldisk -ComputerName $SQLConfig.ServerName | `
                                Select PSComputername, DeviceID, ` 
                                    @{Name="SizeGB";Expression={$_.Size/1GB -as [int]}}, `
                                    @{Name="FreeGB";Expression={[math]::Round($_.Freespace/1GB,2)}}, `
                                    @{Name="%Free";Expression={[math]::Round($_.Freespace/$_.Size,2) * 100 }} | `
                                    Format-Table;


                    return $FileData, $DiskData;
                }
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Get-LogSpaceUsage
{
<#

.SYNOPSIS
Connect to the specified SQL Server environment and show the Log space usage of all of the databases.

.DESCRIPTION
Connect to the specified SQL Server environment and show the Log space usage of all of the databases.

.PARAMETER SQLInstance
    The SQL Server instance to connect to, usually in the format of: ServerName (for the default instance)
    or ServerName\InstanceName (for a Named Instance).

.EXAMPLE
    Get-LogSpaceUsage -SQLInstance [ServerName | ServerName\InstanceName]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Version History

.LINK
 none

#>
    param ( [Parameter(Mandatory=$true)][string]$SQLInstance )

    try
        {
            Load-SQLSMOObjects;

            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;

            $SMOServer = New-Object ('Microsoft.SQLServer.Management.Smo.Server') $($SQLConfig.SQLInstance);
            if ( $SMOServer -eq $null )
                {
                    Write-Host "Server $($SQLConfig.SQLInstance) cannot be contacted." -ForegroundColor Red;
                }
            else
                {
                    $CommandString = "Server=$($SQLConfig.SQLInstance);Database=master;Integrated Security=True"
    
                    $QueryText =  "dbcc sqlperf(logspace)";

                    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
                    $SqlConnection.ConnectionString = $CommandString;
                    $SqlConnection.Open();


                    $SQLCmd = New-Object System.Data.SqlClient.Sqlcommand;
                    $Sqlcmd.Connection = $SqlConnection;
                    $SQLCmd.CommandText = $QueryText;

                    $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SQLCmd;
                    $DataSet = New-Object System.Data.DataSet;
                    $DataAdapter.Fill($DataSet) | Out-Null;


                    $Data =$DataSet.Tables[0] | Format-Table;

                    return $Data;
                }
            
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

function Set-SQLStartupParameters
{
<#

.SYNOPSIS
The function adds the specified Startup Parameters to the SQL Server instance.

.DESCRIPTION
This function takes the specified Startup Parameters, and adds them into the registry such that
upon the next instance restart, those Startup Parameters come into effect. The function finally 
forces a restart of the service.

.PARAMETER SQLInstance
    The target SQL Server instance we wish to collect data from.

.PARAMETER StartupParameters
    The Startup Parameters to be added to the SQL Server instance.

.EXAMPLE
    Set-SQLStartupParameters -SQLInstance [ServerName | ServerName\InstanceName] -StartupParameters [Startup Parameters]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>

    param ( [Parameter(Mandatory=$true)][string]$SQLInstance,
            [Parameter(Mandatory=$true)][string]$StartupParameters )

    try
        {

            Load-SQLSMOObjects;
    
            [bool]$SystemPaths = $false
            [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;


            #Use wmi to change account
            $mc = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $SQLConfig.ServerName;
            $svc = $mc.Services | Where-Object { $_.Name -eq $($SQLConfig.ServiceName) }

            Write-Host "Old Parameters for $($SQLConfig.InstanceName) :" -ForegroundColor Green;
    

            #Wrangle updated params with existing startup params (-d,-e,-l)
            $oldparams = $svc.StartupParameters -split ';'
            Write-Host $oldparams -ForegroundColor Green;

            $newparams = @()
            foreach($param in $StartupParameters)
                {
                    if($param.Substring(0,2) -match '-d|-e|-l')
                        {
                            $SystemPaths = $true
                            $newparams += $param
                            $oldparams = $oldparams | Where-Object {$_.Substring(0,2) -ne $param.Substring(0,2)}
                        }
                    else
                        {
                            $newparams += $param;
                        }
                }

            $newparams += $oldparams | Where-Object {$_.Substring(0,2) -match '-d|-e|-l'}
            $paramstring = ($newparams | Sort-Object) -join ';'

            Write-Verbose "New Parameters for $($SQLConfig.InstanceName) :"
            Write-Verbose $paramstring

            $wmisvc.StartupParameters = $paramstring
            $wmisvc.Alter()

            if ( $SystemPaths )
                {
                    Write-Host "You have changed the system paths for $i. Please make sure the paths are valid before Manually restarting the service";
                }


            Write-Warning "Startup Parameters for $i updated. Restarting the service for these changes to take effect.";

            #Get state of service 
            $servicestate = Get-Service -ComputerName $($SQLConfig.ServerName) -Name $($SQLConfig.ServiceName) -ErrorAction SilentlyContinue;
            if ( $servicestate.status -eq 'Stopped' -or $servicestate.status -eq $null )
                {
                    Continue;
                }
            else
                {
                    (Get-Service -ComputerName $($SQLConfig.ServerName) -Name $($SQLConfig.ServiceName)).Stop();
                }

            $servicestate = Get-Service -ComputerName $($SQLConfig.ServerName) -Name $($SQLConfig.ServiceName) -ErrorAction SilentlyContinue;
            if ( $servicestate.status -eq 'Stopped' )
                {
                    (Get-Service -ComputerName $($SQLConfig.ServerName) -Name $($SQLConfig.ServiceName)).Start();
                }
         }
	Catch
		{
			Write-Host $_.Exception.ToString();
		}
}

function Set-SQLSSLCertificate
{
<#

.SYNOPSIS
The function determines the SQL Server service based on the connection string, and the certificate provided on
the command line, and associates the Thumbprint with that SQL Server instance.

.DESCRIPTION
This function sets the SSL Certificate under the specified SQL Server instance to the specified Thumbprint. The 
SQL Server instance has to exist, and the certificate thumbprint has to exist in the local machine certificate store.

.PARAMETER SQLInstance
    The target SQL Server instance we wish to collect data from.

.PARAMETER Thumbprint
    The Certificate Thumbprint to be used by the SQL Server instance.

.EXAMPLE
    Set-SQLSSLCertificate -SQLInstance [ServerName | ServerName\InstanceName] -Thumbprint [Thumbprint]

.NOTES

 Author: Dr David Thulborn
 Company: Microsoft

 Version History:																				              
																								              
     Version 1.0   -   Current Version

.LINK
 none

#>

    param ( [Parameter(Mandatory=$true)][string]$SQLInstance,
            [Parameter(Mandatory=$true)][string]$Thumbprint )

    try
        {
            Load-SQLSMOObjects;
                        
           [hashtable]$SQLConfig = Get-SQLInstance -SQLInstance $SQLInstance;
    
            $SQLConfig.Thumbprint = $Thumbprint;
            
            # Check the SQL Instance is present
            $srv = Get-Service -ComputerName $($SQLConfig.ServerName) -Name $($SQLConfig.ServiceName) -ErrorAction SilentlyContinue;
            if ( $srv -eq $null )
                {
                    Write-Host "Service $($SQLConfig.ServiceName) was not found." -ForegroundColor Red;
                }

            # Check the Certificate is present
            $certs = Invoke-Command {Get-ChildItem cert: -recurse} -ComputerName $SQLConfig.ServerName;
            $cert = $Certs | Where { $_.Thumbprint -eq $($SQLConfig.Thumbprint) }
            if ( $cert -eq $null )
                {
                    Write-Host "Certificate with Thumbprint $($SQLConfig.Thumbprint) was not found." -ForegroundColor Red;
                }

            $registryPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($SQLConfig.InstanceName)\MSSQLServer\SuperSocketNetLib\";
            $ScriptCommand = "Set-ItemProperty -path $registryPath -name Certificate -value $($SQLConfig.Thumbprint)";
            $CommandScriptBlock = [Scriptblock]::Create($ScriptCommand)

            if (( $srv -ne $null ) -and ( $Certs -ne $null ))
                {
                    Invoke-Command -ComputerName $($SQLConfig.ServerName) -ScriptBlock $CommandScriptBlock -Credential $Credential;

                    #Get state of service 
                    $servicestate = Get-Service -ComputerName $($SQLConfig.ServerName) -Name $($SQLConfig.ServiceName) -ErrorAction SilentlyContinue;

                    Switch ($servicestate) 
                        {
                            'Stopped' 
                                {
                                    (Get-Service -ComputerName $($SQLConfig.ServerName) -Name $($SQLConfig.ServiceName)).Start();
                                }
                            'Running'
                                {
                                    (Get-Service -ComputerName $($SQLConfig.ServerName) -Name $($SQLConfig.ServiceName)).Stop();
                                    sleep 1;
                                    (Get-Service -ComputerName $($SQLConfig.ServerName) -Name $($SQLConfig.ServiceName)).Start();
                                }
                        }
                                     
                }        
                                
        }
    catch
        {
            Write-Host $_.Exception.ToString();
        }
}

Export-ModuleMember -Function 'Get-SQLConfig';
Export-ModuleMember -Function 'Get-SysAdminMembers';
Export-ModuleMember -Function 'Get-VLFCounts';
Export-ModuleMember -Function 'Get-DBCCLastKnownGood';
Export-ModuleMember -Function 'Get-WaitStats';
Export-ModuleMember -Function 'Get-LatchStats';
Export-ModuleMember -Function 'Get-BlockingChain';
Export-ModuleMember -Function 'Get-RunningAgentJobs';
Export-ModuleMember -Function 'Get-DBStartupTimes';
Export-ModuleMember -Function 'Get-PLEByNumaNode';
Export-ModuleMember -Function 'Get-EnabledTraceFlags';
Export-ModuleMember -Function 'Get-QueryMemory';
Export-ModuleMember -Function 'Get-SlowLDFs';
Export-ModuleMember -Function 'Get-UserActivity';
Export-ModuleMember -Function 'Get-FailedAgentJobs';
Export-ModuleMember -Function 'Get-InstanceStartupTime';
Export-ModuleMember -Function 'Get-LastSQLPatch';
Export-ModuleMember -Function 'Get-CreateDBSnapshot';
Export-ModuleMember -Function 'Get-DropDBSnapshot';
Export-ModuleMember -Function 'Get-ProcedureCacheByStore';
Export-ModuleMember -Function 'Get-ProcedureCacheByDatabase';
Export-ModuleMember -Function 'Get-DiskAndFileFreeSpace';
Export-ModuleMember -Function 'Get-LogSpaceUsage';
Export-ModuleMember -Function 'Set-SQLStartupParameters';
Export-ModuleMember -Function 'Set-SQLSSLCertificate';