# Set parameters
$md = <md resource name>
$group = <failover group name>
$primary = <Primary Server name>
$secondary = <Secondary Server name>
$timeout = <Mirroring Time>
$recoveryscript = <MirrorRecovery script name>
$logfilepath = <File path to output the log of this script>

# Don't edit from here
echo "-----------------------" | Out-File -Append $logfilepath
Get-Date -Format "yyyy/MM/dd HH:mm:ss" | Out-File -Append $logfilepath
echo "-----------------------" | Out-File -Append $logfilepath
echo "md name: $md" | Out-File -Append $logfilepath
echo "group name: $group" | Out-File -Append $logfilepath
echo "Primary Server name: $primary" | Out-File -Append $logfilepath
echo "Secondary Server name: $secondary" | Out-File -Append $logfilepath
echo "timeout: $timeout" | Out-File -Append $logfilepath
echo "Recovery Script: $recoveryscript" | Out-File -Append $logfilepath
echo "Log File: $logfilepath" | Out-File -Append $logfilepath
echo "" | Out-File -Append $logfilepath

# Get own server hostname
$myname = hostname
if($myname -ne $secondary){
    echo "Error! This is not Secondary Server." | Out-File -Append $logfilepath
    echo "hostname = $myname" | Out-File -Append $logfilepath
    clplogcmd -m "SM Error! Mis-configuration" -l ERR
    exit 1
}

# Check Active Server
echo "Execute: clpgrp -n $group" | Out-File -Append $logfilepath
$result = clpgrp -n $group
if(-not $?){
    echo "Error! Failed to execute clpgrp -n $group" | Out-File -Append $logfilepath
    echo $result | Out-File -Append $logfilepath
    clplogcmd -m "SM Error! Failed to get Active Server info" -l ERR
    exit 1
}
echo "Active Server: $result" | Out-File -Append $logfilepath
if($result -ne $primary){
    echo "Error! Cancel mirroring because $md resource is not active on Primary Server." | Out-File -Append $logfilepath
    clplogcmd -m "SM Error! md is not Active on Primary" -l ERR
    exit 1
}

# Stop md resource to stop I/O
echo "Execute: clprsc -t $md -f -h $primary" | Out-File -Append $logfilepath
$result = clprsc -t $md -f -h $primary
if(-not $?){
    echo "Error! Cancel mirroring because failed to stop $md resource" | Out-File -Append $logfilepath
    echo $result | Out-File -Append $logfilepath
    clplogcmd -m "SM Error! Failed to stop md resource" -l ERR
    exit 1
}

# Start Mirroring on Active Server
echo "Execute: clptrnreq -t EXEC_SCRIPT -h $primary -s $recoveryscript" | Out-File -Append $logfilepath
$result = clptrnreq -t EXEC_SCRIPT -h $primary -s $recoveryscript
if(-not $?)
{
    echo "Error! Executing MirrorRecovery.bat remotely was failed." | Out-File -Append $logfilepath
    echo $result | Out-File -Append $logfilepath
    clplogcmd -m "SM Error! Failed to start mirroring" -l ERR
}else{
    echo "Info: Executing MirrorRecovery.bat remotely was completed." | Out-File -Append $logfilepath
}

# Wait Mirroring complete on Standby Server
echo "Execute: clpmdctrl --rwait $md -timeout $timeout -rcancel" | Out-File -Append $logfilepath
clpmdctrl --rwait $md -timeout $timeout -rcancel
if(-not $?)
{
    echo "Error!: Mirroring wait was failed." | Out-File -Append $logfilepath
    echo $error[0] | Out-File -Append $logfilepath
    clplogcmd -m "SM Error! Failed to complete mirroring" -l ERR
}else{
    echo "Info: Mirroring wait was completed." | Out-File -Append $logfilepath
}

# Check md sync status
echo "Execute: clpmdstat -m $md" | Out-File -Append $logfilepath
$result = clpmdstat -m $md
if(-not $?){
    echo "Error! Failed to get md status." | Out-File -Append $logfilepath
    echo $error[0] | Out-File -Append $logfilepath
    clplogcmd -m "SM Error! Failed to get md sync status" -l ERR
}else{
    echo $result | Out-File -Append $logfilepath
    $result = $result | Select-String "Status" -CaseSensitive | Select-String "Normal" -CaseSensitive
    if($result -eq $null){
        echo "Error! Failed to synchronize $md resource." | Out-File -Append $logfilepath
        clplogcmd -m "SM Error! md is not synchronized" -l ERR
    }else{
        echo "Info: Succeeded to synchronize md." | Out-File -Append $logfilepath
    }
}

# Stop mirroring
echo "Execute: clpmdctrl -b $md" | Out-File -Append $logfilepath
clpmdctrl -b $md
if(-not $?){
    echo "Error! Failed to stop mirroring." | Out-File -Append $logfilepath
    echo $error[0] | Out-File -Append $logfilepath
    clplogcmd -m "SM Error! Failed to stop mirroring after synchronizing" -l ERR
    exit 1
}
echo "Info: Succeeded to stop mirroring." | Out-File -Append $logfilepath
clplogcmd -m "SM Success: Succeeded schedule mirroring."

# Start group
echo "Execute: clpgrp -t $group -h $primary" | Out-File -Append $logfilepath
clpgrp -t $group -h $primary
if(-not $?){
    echo "Warn: Failed to stop $group" | Out-File -Append $logfilepath
    echo $error[0] | Out-File -Append $logfilepath
    clplogcmd -m "SM Warning: Failed to restart group after synchronizing" -l WARN
    exit 1
}
echo "Execute: clpgrp -s $group -h $primary" | Out-File -Append $logfilepath
clpgrp -s $group -h $primary
if(-not $?){
    echo "Warn: Failed to start $group" | Out-File -Append $logfilepath
    echo $error[0] | Out-File -Append $logfilepath
    clplogcmd -m "SM Warning: Failed to restart group after synchronizing" -l WARN
    exit 1
}
echo "Info: Succeeded to start $group" | Out-File -Append $logfilepath

exit 0
