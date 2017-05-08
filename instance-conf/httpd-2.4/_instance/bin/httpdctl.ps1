#
# Pivotal Instance Management Schema for Apache HTTP Server
#
# Copyright (C) 2017-Present Pivotal Software, Inc. All rights reserved.
#
# This program and the accompanying materials are made available under
# the terms of the under the Apache License, Version 2.0 (the "License”);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# httpdctl.ps1  This script takes care of installing, starting and stopping
#               Pivotal Web Server services on the Windows platform, following
#               the same syntax as the unix httpdctl script.
#
# Be absolutely certain to save this file in Encoding 'UTF-8'.

$name = "httpdctl"
$OutputEncoding = [System.Text.Encoding]::UTF8

$server_root="@ServerRoot@"
$apache_root="@exp_httpddir@"
$apache_bin="$apache_root/bin/httpd.exe"
$apache_pid="$server_root/logs/httpd.pid" 
$service_name="Pivotal httpd @ServerInstance@"
$action="help"
$start_flags=""

Write-Host "httpdctl.ps1 - manage the $service_name server instance"
Write-Host "Copyright © 2017 Pivotal Software, Inc. All rights reserved."
Write-Host ""

if ($args.Count -gt 0) { 
    $action=$args[0]
    if ($args.Count -gt 1) {
        $start_flags = $args[1..($args.Count - 1)]
        for ($i = 0; $i -lt $start_flags.Count; ++$i) {
            if ($start_flags[$i].IndexOf(" ") -ge 0) {
                $start_flags[$i] = '"' + $start_flags[$i] + '"'
            }
        }
        $start_flags = [string]$start_flags
    }
} 

if (-not (Test-Path "$server_root/conf/httpd.conf")) {
    Write-Host "FATAL: $server_root/conf/httpd.conf not found"
    exit 1
}

if ($action -eq "start") {
    Write-Host "Starting $service_name"
    & $apache_bin -k start -n "$service_name" -d "$server_root" $start_flags
    $rv = $LastExitCode
    if ($?) {
        Write-Host "The $service_name service is running."
    }
    exit $rv
}
elseif ($action -eq "stop") {
    Write-Host "Stopping $service_name"
    & $apache_bin -k stop -n "$service_name"
    exit $LastExitCode
}
elseif ($action -eq "restart") {
    Write-Host "Restarting $service_name"
    & $apache_bin -k stop -n "$service_name"
    & $apache_bin -k start -n "$service_name" -d "$server_root" $start_flags
    $rv = $LastExitCode
    if ($?) {
        Write-Host "The $service_name service is running."
    }
    exit $rv
}
elseif ($action -eq "graceful") {
    Write-Host "Gracefully restarting $service_name"
    & $apache_bin -k restart -n "$service_name"
    exit $LastExitCode
}
elseif ($action -eq "status") {
    $env:RUNNING = 0
    if (Test-Path $apache_pid) {
        $env:PID = [Int64](get-content $apache_pid)
        $apid = "pid $env:PID"
    }
    else {
        $apid = "no pid file"
    }
    $scmstatus = (get-service "$service_name").Status.ToString().ToUpper()
    if ($scmstatus -eq "STOPPED") { $scmstatus = "NOT RUNNING" }
    if ($scmstatus -eq "RUNNING") { $env:RUNNING = 1 }
    $env:STATUS = "$service_name ($apid) $scmstatus"
    Write-Host $env:STATUS
}
elseif ($action -eq "configtest") {
    Write-Host "Configuration test results for $service_name"
    & $apache_bin -t -n "$service_name" -d "$server_root" $start_flags
    exit $LastExitCode
}
elseif ($action -eq "install") {
    Write-Host "Installing Windows service $service_name"
    & $apache_bin -k install -n "$service_name" -d "$server_root" $start_flags
    $rv = $LastExitCode
    if (! $?) {
        Write-Host ""
        Write-Host "FATAL: The $service_name service failed to install."
        exit $rv
    }
    Write-Host ""
    Write-Host "You should consider changing the 'Log On' system account property for"
    Write-Host "this $service_name service to a unique, unprivileged user account"
    Write-Host "to finish this configuration, before starting the service."
    Write-Host "The unprivileged user account should have write access only to the logs"
    Write-Host "and var directories within $server_root"
    Write-Host ""
}
elseif ($action -eq "uninstall") {
    Write-Host "Uninstalling Windows service $service_name"
    & $apache_bin -k stop -n "$service_name"
    & $apache_bin -k uninstall -n "$service_name"
    exit $LastExitCode
}
else {
    Write-Host "Usage: httpdctl.ps1 {command} {optional arguments}"
    Write-Host ""
    Write-Host "where {command} is one of:"
    Write-Host "    start"
    Write-Host "    stop"
    Write-Host "    restart"
    Write-Host "    graceful"
    Write-Host "    status"
    Write-Host "    configtest"
    Write-Host "    install"
    Write-Host "    uninstall"
    Write-Host ""
    if ($action -ne "help") {
        Write-Host "FATAL: Command $action was not recognized!"
        Write-Host ""
        exit 1
    }
}
