# EXPRESSCLUSTER X3.3 Schedule Mirroring on Windows Mirror Disk cluster
This article shows how to set EXPRESSCLUSTER X3.3 Schedule Mirroring for 2 nodes Windows Mirror Disk cluster.  
We assume that one failover group has one md resource.

```bat
<LAN>
 |
 |  +----------------------------+
 +--| Primary Server             |
 |  | - Windows Server           |
 |  | - EXPRESSCLUSTER X 3.3     |
 |  +----------------------------+
 |                                
 |  +----------------------------+
 +--| Secondary Server           |
 |  | - Windows Server           |
 |  | - EXPRESSCLUSTER X 3.3     |
 |  +----------------------------+
```

If your cluster configuration is differ from our assumption, please contact Support Team.

## What Schedule Mirroring is
Schedule Mirroring means that Mirroring is executed in the nighttime.  
In the daytime, Application is running and Mirroring is stopped. (Operation Time)  
In the nighttime, Mirroring is running and Application is stopped. (Mirroring Time)

- e.g.
	- Operation Time: 7:00am - 7:59pm
	- Mirroring Time: 8:00pm - 6:59am
	- Schedule Mirroring overflow
		1. Application is running at 7:00am
			- At this time, mirroring is stopped.
		1. Application stops at 8:00pm
		1. Mirroring starts at 8:00pm
		1. When Mirroring completes, mirroring stops again
		1. When Mirroring completes, Application starts

## Notification
- For Schedule Mirroring, You can NOT set Auto Failover and only Manual Failover can be set.
- For Schedule Mirroring, Application is stopped at the end of Operation time to stop I/O.
	- For example, if SQL Server is clustered, SQL Server instance service is stopped to stop its transaction.
- While Operation Time, since mirroring is stopped, mdw monitor resource shows Caution "yellow icon" but please ignore it.
- If Application is not stopped at the beginning of Mirroring Time, Mirroring will not start.
- If Mirroring is not stopped after Mirroring is completed, Application will not start automatically. Please refer [Application Operation](https://github.com/EXPRESSCLUSTER/ScheduleMirroring/blob/main/2nodeWinMd_X33.md#application-operation)
- If Mirroring cannot complete in Mirroring Time every day, your system does NOT match Schedule Mirroring. Please consider to set Sync Mirroring.
- If you want to failover, you need to do it manually. Please refer [Failover Operation](https://github.com/EXPRESSCLUSTER/ScheduleMirroring/blob/main/2nodeWinMd_X33.md#failover-operation)
- If you execute failover, data which is not mirrored yet will be lost.

## Setup
This section shows how to set up existing md resource as Schedule Mirroring.

### On WebManager
1. Start Config Mode and change following settings:
	- Cluster Properties
		- Mirror Disk tab
			- Auto Mirror Recovery: UNCHECK
	- Servers Properties
		- Settings button
			- Add button
				- Name group1
				- Primary Server: Add
			- Add button
				- Name group2
				- Secondary Server: Add
	- Failover group Properties
		- Info tab
			- Use Server Group Setting: CHECK
		- Startup Server tab
			- Add: Both group1 and group2
		- Attribute tab
			- Failover Attribute
				- Prioritize failover policy in the server group: Select
				- Enable only manual failover among the server groups: CHECK

### On Primary Server
1. Log on to Primary Server with Administrator Account.
1. Create a folder:
	- C:\Program Files\EXPRESSCLUSTER\work\trnreq
1. Copy [MirrorRecovery.bat](https://github.com/EXPRESSCLUSTER/ScheduleMirroring/blob/main/scripts/mirrorRecovery_2nodeWin_X33.bat) to the folder:
	- C:\Program Files\EXPRESSCLUSTER\work\trnreq\MirrorRecovery.bat
1. Set md resource name in MirrorRecovery.bat
	- e.g.
		- You want to set Schedule Mirror for "md1" resource
		```bat
		set MDNAME=md1
		```

### On Secondary Server
1. Log on to Secondary Server with Administrator Account.
1. Create a folder for Schedule Mirroring files:
	- e.g. C:\ECX_SM
1. Copy [ScheduleMirror.ps1](https://github.com/EXPRESSCLUSTER/ScheduleMirroring/blob/main/scripts/scheduleMirror_2nodeWin_X33.ps1) to the folder:
	- e.g. C:\ECX_SM\ScheduleMirror.ps1
1. Set parameters in the ps1 script:
	- e.g.
		- You want to set Schedule Mirror for "md1" resource which belongs to "failover1" group
		- Primary Server name is "server1" and Secondary Server name is "server2"
		- Mirroring Time is 8:00pm - 6:59am (39540 sec)
		```bat
		$md = "md1"
		$group = "failover1"
		$primary = "server1"
		$secondary = "server2"
		$timeout = 39540
		$recoveryscript = "MirrorRecovery.bat"
		$logfilepath = "C:\ECX_SM\ScheduleMirrorLog.txt"
		```
1. Start Windows Task Scheduler and create a new task
	- General tab
		- Specify Administrator account for running account (To execute clpxxx command, you need to specify Administrator Account)
	- Actions tab
		- Specify C:\ECX_SM\ScheduleMirror.ps1
	- Triggers tab
		- Specify the beginning of Mirroring Time

### After setup
1. Run Schedule Mirroring for 2 or 3 days
1. On WebManager Alert View, confirm that the following message is recorded every day.
	```bat
	SM Success: Succeeded to synchronizing md resource.
	```
	- **Note:**
		- If it is not recorded and any other error messages ("SM Error!") are recorded many times, your system may NOT match Schedule Mirroring. Consider to set Sync Mirroring.
		- Contact Support with the following information:
			- Cluster log:  
				Collect log on WebManager
			- Mirror Statistics:  
				Collect all files under "C:\Program Files\EXPRESSCLUSTER\perf\disk" on BOTH servers
			- Schedule Mirror Log:  
				Collect all files under "C:\ECX_SM" on BOTH servers
		- If "C:\ECX_SM\ScheduleMirrorLog.txt" file gets huge, remove or archive old logs.
## Failover Operation
This section shows how to execute failover from Primary Server to Secondary Server.

### Failover
#### On Secondary Server
1. Log on to Secondary Server with Administrator Account.
1. On WebManager, check Alert View
	- In the case of Operation Time:
		- Confirm that the following md resource synchronized message is recorded in last Mirroring Time.
			```bat
			SM Success: Succeeded schedule mirroring.
			```
			- e.g.
				- If you are executing failover between Oct 5th 7:00am - Oct 5th 7:59pm, you need to confirm the message is recorded between Oct 4th 8:00pm - Oct 5th 6:59am.
	- In the case of Mirroring Time:
		- Confirm that the following message is recorded in this Mirroring Time.
			```bat
			SM Success: Succeeded schedule mirroring.
			```
			- e.g.
				- If you are executing failover between Oct 4th 8:00pm - Oct 5th 6:59am, you need to confirm the message is recorded between Oct 4th 8:00pm - Oct 5th 6:59am.
	- **Note:**
		- If md resource synchronized message is NOT recorded in specified time as the above, do NOT execute failover.  
			Contact Support with the following information:
			- Cluster log  
				Collect log on WebManager
			- Mirror Statistics  
				Collect all files under "C:\Program Files\EXPRESSCLUSTER\perf\disk" on BOTH servers
			- Schedule Mirror Log  
				-Collect all files under "C:\ECX_SM" on BOTH servers

1. If failover group is Online on Primary Server:
	1. Stop the group.
	1. Right click Schedule Mirroring target md resource and select "Details".
	1. Click Primary Server icon and make it RED. (Data on this server will not be the latest.)
	1. Click Execute and close.
1. Right click Schedule Mirroring target md resource and select "Details".
1. Click Secondary Server icon and make it GREEN. (Data on this server will be the latest.)
1. Click Execute and close.
1. Start failover group on Secondary Server.

- **Note:**
	- After these steps, Application starts with data at the last md synchronized time. And data after the last md synchronized time is lost.
	- After these steps, until execute [Failback Operation](https://github.com/EXPRESSCLUSTER/ScheduleMirroring/blob/main/2nodeWinMd_X33.md#failback-operation), mirroring will not be re-synchronized.

## Failback Operation
This section shows how to recover Primary Server and execute failback from Secondary Server to Primary Server.  
Until recovering Primary Server, md resource will not be re-synchronized.

### Recover Primary Server
#### On Primary Server
1. If Server1 is stopped:
	1. Start Server1.
1. Log on to Primary Server with Administrator Account.
1. On WebManager, confirm that Primary Server is status is Online.
1. Open md resource with the following command:
	```bat
	> mdopen <md resource name>
	```
1. Backup md resource Data Partition.
1. Close md resource with the following command:
	```bat
	> mdclose <md resource name>
	```
1. On WebManager, right click Schedule Mirroring target md resource and select "Details".
1. Click Primary Server icon and make it GREEN. (Disk Copy will be executed.)
1. Click Execute and close.
	- **Note:** After this step, Mirroring from Secondary Server to Primary Server will occur.

### Failback
#### On Primary Server
1. Log on to Primary Server with Administrator Account.
1. On WebManager, confirm that all status is GREEN.
1. Move failover group to Primary Server.
1. Right click Schedule Mirroring target md resource and select "Details".
1. Click Secondary Server icon and make it RED. (Data on this server will not be the latest.)

## Application Operation
This section shows how to recover Application if it is stopped although Operation Time starts.

#### On Primary Server
1. Log on to Primary Server with Administrator Account.
1. On WebManager, right click Schedule Mirroring target md resource and select "Details".
1. Check both servers icon color:
	- If Primary Server icon is GREEN:
		1. Click close
		1. Start failover group on Primary Server
	- If Primary Server icon is RED and Secondary Server icon is GREEN:
		1. Click close
		1. Start failover group on Secondary Server
		1. To move group to Primary Server, refer [Failback Operation] (https://github.com/EXPRESSCLUSTER/ScheduleMirroring/blob/main/2nodeWinMd_X33.md#failback-operation)
	- If Primary Server icon is GRAY and Secondary Server icon is GREEN:
		1. Click close
		1. Start failover group on Secondary Server
		1. To move group to Primary Server, refer [Failback Operation] (https://github.com/EXPRESSCLUSTER/ScheduleMirroring/blob/main/2nodeWinMd_X33.md#failback-operation)
	- Other
		- Contact Support with the following information:
			- Cluster log:  
				Collect log on WebManager
			- Mirror Statistics:  
				Collect all files under "C:\Program Files\EXPRESSCLUSTER\perf\disk" on BOTH servers
			- Schedule Mirror Log:  
				Collect all files under "C:\ECX_SM" on BOTH servers
