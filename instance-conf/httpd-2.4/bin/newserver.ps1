#
# VMware Instance Management Schema for Apache HTTP Server
#
# Copyright (C) 2017-2021 VMware, Inc.
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

# newserver.ps1
#
# This script creates a new server instance directory tree from an _instance/ template
#

$name = "newserver"
$OutputEncoding = [System.Text.Encoding]::UTF8
[IO.Directory]::SetCurrentDirectory($pwd)
 
$rootdir = $pwd -replace "\\", "/"
$httpdver = "2.4"
$httpddir = $null
$sourcedir = $null
$server = $null
$serverdir = $null
$update = $false
$overlay = $false
$quiet = $false
$enablessl = $false
$help = $false

Write-Host "newserver.ps1 script - deploy a new httpd server instance"
Write-Host ""

function syntax {
    Write-Host "Syntax:" $MyInvocation.ScriptName "[--options] [servername]"
    Write-Host "    --rootdir=/path-to-httpdserver  default is current dir"
    Write-Host "    --server=servername             host and default path name to create"
    Write-Host "    --serverdir=/path/to/instance   default is rootdir/{servername}/ target"
    Write-Host "    --overlay                       overlay existing {serverdir} files"
    Write-Host "    --update                        update only the {serverdir}/bin scripts"
    Write-Host ""
    Write-Host "    --httpdver=[2.4.9.0-64]         default is 2.4 [symlinked to current]"
    Write-Host "    --httpddir=/path/to/httpd       default is rootdir/httpd-{ver}/"
    Write-Host "    --sourcedir=/path/to/template   default is httpddir/_instance/ template"
    Write-Host "    --set token=value               replace @token@ with value"
    Write-Host "    --subst regex=value             replace regex with value (before --set)"
    Write-Host "    --quiet                         bypass all interactive prompts"
    Write-Host "    --help                          display this help information"
    Write-Host ""
}

$patterns = @()
$smap = @{
    "User" =  "httpd";
    "Group" = "httpd";
    "rel_sysconfdir" = "conf";
    "rel_logfiledir" = "logs";
    "exp_runtimedir" = "logs";
    "Port" =     80;
    "SSLPort" = 443;
    "FTPPort" =  21;
}
$inset = $false
$insubst = $false

foreach ($arg in $args) {
    if ($inset) {
        $map = ($arg -split "=", 2)
        if ($map.length -ne 2) {
            syntax
            Write-Host "FATAL: a token=value pair must follow --set"
            exit 1
        }
        $smap[$map[0]] = $map[1]
        $inset = $false
    }
    elseif ($insubst) {
        $map = ($arg -split "=", 2)
        if ($map.length -ne 2) {
            syntax
            Write-Host "FATAL: a token=value pair must follow --subst"
            exit 1
        }
        $patterns += $map[0], $map[1]
        $insubst = $false
    }
    elseif ($arg.StartsWith("--rootdir=")) {
        $rootdir = $arg.Substring("--rootdir=".Length)
    }
    elseif ($arg.StartsWith("--httpdver=")) {
        $httpdver = $arg.Substring("--httpdver=".Length)
    }
    elseif ($arg.StartsWith("--httpddir=")) {
        $httpddir = $arg.Substring("--httpddir=".Length)
    }
    elseif ($arg.StartsWith("--sourcedir=")) {
        $sourcedir = $arg.Substring("--sourcedir=".Length)
    }
    elseif ($arg.StartsWith("--server=")) {
        $server = $arg.Substring("--server=".Length)
    }
    elseif ($arg.StartsWith("--serverdir=")) {
        $serverdir = $arg.Substring("--serverdir=".Length)
    }
    elseif ($arg.StartsWith("--set=")) {
        $map = ($arg.Substring("--set=".Length) -split "=", 2)
        if ($map.length -ne 2) {
            syntax
            Write-Host "FATAL: a token=value pair must follow --set"
            exit 1
        }
        $smap[$map[0]] = $map[1]
    }
    elseif ($arg -eq "--set") { 
        $inset = $true
    }
    elseif ($arg.StartsWith("--subst=")) {
        $map = ($arg.Substring("--subst=".Length) -split "=", 2)
        if ($map.length -ne 2) {
            syntax
            Write-Host "FATAL: a token=value pair must follow --subst"
            exit 1
        }
        $patterns += $map[0], $map[1]
    }
    elseif ($arg -eq "--subst") { 
        $insubst = $true
    }
    elseif ($arg -eq "--overlay") { 
        $overlay = $true
    }
    elseif ($arg -eq "--update") { 
        $update = $true
    }
    elseif ($arg -eq "--quiet") {
        $quiet = $true
    }
    elseif ($arg -eq "--enablessl") {
        $enablessl = $true
    }
    elseif ($arg -eq "--help") {
        syntax
        exit
    }
    elseif ($arg[0] -eq "-") {
        syntax
        Write-Host "FATAL: unrecognized command line option" $arg
        exit 1
    }
    elseif ($server -eq $null) {
        $server = $arg
    }
    else {
        syntax
        Write-Host "FATAL: multiple command line arguments not supported, either"
        Write-Host "       specify server name or --server=name option, not both."
        exit 1
    }
}

if ($inset -or $insubst) {
    syntax
    Write-Host "FATAL: a token=value pair must follow --set or --subst"
    exit 1
}

if ($server -eq $null) {
    syntax
    Write-Host "FATAL: server name must be specified"
    exit 1
}

$rootdir = [IO.Path]::GetFullPath($rootdir) -replace "\\", "/"

if ($httpddir -eq $null) {
    $httpddir = "$rootdir/httpd-$httpdver"
    $failcause = "       --rootdir and --httpdver must be valid"
}
else {
    $httpddir = [IO.Path]::GetFullPath($httpddir) -replace "\\", "/"
    $failcause = "       --httpddir must be valid"
}

if (-not (Test-Path "$httpddir/bin/httpd.exe")) {
    syntax
    Write-Host "FATAL: $httpddir/bin/httpd.exe not found."
    Write-Host $failcause
    exit 1
}

if ($sourcedir -eq $null) {
    $sourcedir = "$httpddir/_instance"
    $failcause = "       --rootdir and --httpdver must be valid"
}
else {
    $sourcedir = [IO.Path]::GetFullPath($sourcedir) -replace "\\", "/"
    $failcause = "       --sourcedir must be valid"
}

if (-not (Test-Path "$sourcedir/conf/httpd.conf")) {
    syntax
    Write-Host "FATAL: $sourcedir instance template not found."
    Write-Host $failcause
    exit 1
}

if ($serverdir -eq $null) {
    $serverdir = "$rootdir/$server"
    $failcause = "       --server must be unique"
}
else {
    $serverdir = [IO.Path]::GetFullPath($serverdir) -replace "\\", "/"
    $failcause = "       --serverdir must be unique"
}

if ((-not $overlay) -and (-not $update) -and (Test-Path $serverdir)) {
    syntax
    Write-Host "FATAL: $serverdir already exists."
    Write-Host $failcause
    exit 1
}

if (-not (Test-Path $serverdir)) {
    if ($overlay -or $update) {
        syntax
        Write-Host "FATAL: $serverdir does not exist."
        Write-Host "       Server directory must exist to --update or --overlay."
        exit 1
    }
    $parentdir = Split-Path $serverdir -parent
    if (-not (Test-Path $parentdir)) {
        syntax
        Write-Host "FATAL: $parentdir does not exist."
        Write-Host "       The parent directory must exist."
        exit 1
    }
}

# It is highly unadvised to --set these overrides, that is not supported;
#
if (-not $smap.ContainsKey("ServerInstance")) { $smap["ServerInstance"] = $server }
if (-not $smap.ContainsKey("ServerRoot"))     { $smap["ServerRoot"] = $serverdir }
if (-not $smap.ContainsKey("exp_cgidir"))     { $smap["exp_cgidir"] = "$serverdir/cgi-bin" }
if (-not $smap.ContainsKey("exp_htdocsdir"))  { $smap["exp_htdocsdir"] = "$serverdir/htdocs" }
if (-not $smap.ContainsKey("exp_ftpdocsdir")) { $smap["exp_ftpdocsdir"] = "$serverdir/ftpdocs" }
if (-not $smap.ContainsKey("exp_httpddir"))   { $smap["exp_httpddir"] = $httpddir }

$promptrex = [regex] '^\s*([^ \r\n]*)\s*$'

function prompt([string]$promptstr)
{
    $retval = Read-Host -prompt $promptstr
    $promptrex.Replace($retval, '$1') | out-null
    return $retval
}

function promptyn([string]$promptstr)
{
    while ($true) {
        $response = prompt($promptstr)
        if ($response -eq "y") { return $true }
        if ($response -eq "n") { return $false }
    }
}

if ((-not $quiet) -and (-not $update)) {
    if (promptyn("Enable SSL and create a default key [y/n]? ")) {
        $enablessl = $true
        $patterns += "#(Include @rel_sysconfdir@/extra/httpd-ssl.conf)", '$1'
        $patterns += "#(LoadModule ssl_module)", '$1'
        $patterns += "#(LoadModule socache_shmcb_module)", '$1'
    }
    if (-not $smap.ContainsKey("HostName")) { $smap["HostName"] = $server }
    $resp = prompt("Server hostname (e.g. www.example.com) [" + $smap['HostName'] + "]? ")
    if (-not ($resp -eq "")) { $smap["HostName"] = $resp }
    if (-not $smap.ContainsKey("ServerAdmin")) {
        $smap["ServerAdmin"] = "webmaster`@" + $smap["HostName"]
    }
    $resp = prompt("Administrator email [" + $smap["ServerAdmin"] + "]? ")
    if (-not ($resp -eq "")) { $smap["ServerAdmin"] = $resp }
 
    $port = prompt("Port for http:// traffic        [" + $smap['Port'] + "]? ")
    if (([int]("0$port")) -gt 0) { $smap["Port"] = $port }
    if ($enablessl) {
        $port = prompt("Port for https:// SSL traffic  [" + $smap['SSLPort'] + "]? ")
        if (([int]("0$port")) -gt 0) { $smap["SSLPort"] = $port }
    }
}
else {
    if (-not $smap.ContainsKey("HostName")) { $smap["HostName"] = $server }
    if (-not $smap.ContainsKey("ServerAdmin")) { 
        $smap["ServerAdmin"] = "webmaster`@$smap['HostName']"
    }
}

if ($update) {
    Write-Host ""
    Write-Host "Updating server instance scripts in " $serverdir "/bin"
    Write-Host "from the " $sourcedir 
    Write-Host "template instance tree"
} else {
    Write-Host ""
    Write-Host "Creating new server instance" $serverdir
    Write-Host "from the " $sourcedir 
    Write-Host "template instance tree"
}

if (-not ((Test-Path -PathType container "$serverdir") -or ($(mkdir "$serverdir") -is [System.IO.DirectoryInfo]))) {
    Write-Host "FATAL: failed to create directory $serverdir"
    Write-Host "       Permissions problem or missing parent directory?"
    exit 1
}
if (-not (Test-Path "$serverdir/ssl"))       { mkdir "$serverdir/ssl" | out-null }
if (-not (Test-Path "$serverdir/logs"))      { mkdir "$serverdir/logs" | out-null }
if (-not (Test-Path "$serverdir/logs/safe")) { mkdir "$serverdir/logs/safe" | out-null }
if (-not (Test-Path "$serverdir/var"))       { mkdir "$serverdir/var" | out-null }

foreach ($map in $smap.keys) {
    $patterns += ("@" + $map + "@"), $smap[$map]
}

for ($i = 0; $i -lt $patterns.length; $i += 2) {
    $patterns[$i] = [regex]$patterns[$i]
}

$ignoreext = @{".exe" = $null; ".dll" = $null; ".so"  = $null; ".pdb" = $null;
               ".lib" = $null; ".obj" = $null; ".exp" = $null; ".ico" = $null;
               ".png" = $null; ".gif" = $null; ".jpg" = $null; ".jpeg" = $null}

$srcpath = ($sourcedir -replace "/", "\")
$dstpath = ($serverdir -replace "/", "\")

function fixfiles ($srcfilesarg)
{
    foreach ($srcfile in $srcfilesarg) {
        $srcname = [string]($srcfile.FullName)
        $dstname = $srcname
        $dstname = $dstname.Replace($srcpath, $dstpath)
        if ($srcfile.PSIsContainer) {
             if (-not (Test-Path $dstname)) { mkdir $dstname | out-null }
             $subfiles = (get-childitem -path $srcname)
             if ($subfiles.length -gt 0) { fixfiles $subfiles }
        }
        elseif (($srcfile.Extension.length -lt 1) -or ($ignoreext.ContainsKey($srcfile.Extension.ToLower()))) {
            Copy-Item $srcname $dstname
        }
        else {
            try {
                $repl = $false
                $contents = Get-Content -Encoding UTF8 -path $srcname
                for ($i = 0; $i -lt $contents.length; ++$i) {
                    for ($j = 0; $j -lt $patterns.length; $j += 2) {
                        $newtxt = $patterns[$j].Replace($contents[$i], $patterns[$j + 1])
                        if ($newtxt -ne $contents[$i]) {
                            $repl = $true; $contents[$i] = $newtxt
                        }
                    }
                }
                if ($repl) {
                    $contents | out-file $dstname -enc utf8
                }
                else {
                    Copy-Item $srcname $dstname
                }
            }
            catch {
                Copy-Item $srcname $dstname
            }
        }
    }
}

if ($update) {
    $sourcedir = "$sourcedir/bin"
}

$files = (get-childitem -path $sourcedir)
fixfiles $files

$env:path = (("$httpddir\bin;" -replace "/", "\") + $env:path)

if ((-not $quiet) -and $enablessl) {
    $env:OPENSSL_CONF = "$httpddir/ssl/openssl.cnf"
    $opensslbin = ("$httpddir\bin\openssl.exe" -replace "/", "\")
    $sslfiles = ("$serverdir/ssl/" + $smap["HostName"])
    Write-Host ""
    $bits = prompt("Size of SSL RSA key, in bits [2048]? ")
    if ([int]"0$bits" -lt 512) { $bits = "2048" }
    & $opensslbin genrsa -out "$sslfiles`.key" $bits
    if (-not $?) {
        Write-Host "FATAL: failed to invoke openssl genrsa.  The package may be" 
        Write-Host "       incompatible with your OS or CPU architecture, or your"
        Write-Host "       install may be misconfigured (wrong user id, etc)."
        Write-Host ""
        Write-Host "       This error can also result from installing the product"
        Write-Host "       into a path with characters not available in the current"
        Write-Host "       code page, such as using a Cryllic character in a Japanese"
        Write-Host "       PowerShell console session."
        exit 1
    }
    Write-Host ""
    Write-Host "Created $sslfiles`.key"
    $binok = $false
    while (-not $binok) {
        Write-Host ""
        Write-Host "Choose a passphrase to encrypt the .pem backup copy of this key"
        Write-Host ""
        & $opensslbin rsa -aes256 -check -in "$sslfiles`.key" -out "$sslfiles`.pem"
        $binok = $?
    }
    $binok = $false
    while (-not $binok) {
        Write-Host ""
        Write-Host "Fill in information for this certificate."
        Write-Host "(The Common Name (CN) below MUST match ServerName!)"
        Write-Host ""
        & $opensslbin req -new -key "$sslfiles`.key" -out "$sslfiles`.csr"
        $binok = $?
    }
    & $opensslbin x509 -req -days 366 -sha256 -in "$sslfiles`.csr" -signkey "$sslfiles`.key" -out "$sslfiles`.crt"
    Write-Host ""
    Write-Host "SSL files generated as $sslfiles`.*"
    Write-Host " .key - unencryped private key (perm 0600 for security)."
    Write-Host " .pem - aes256 encrypted private key - back up this file!"
    Write-Host " .csr - certificate signing request - submit this to the CA."
    Write-Host " .crt - self-signed certificate, replace with cert signed by the CA."
    Write-Host "Be certain to record the passphrase to decrypt the .pem file."
    Write-Host "Never transmit the .key file or cause it to be readable by others!"
}

if ($update) {
    Write-Host ""
    Write-Host "Server instance scripts updated in"
    Write-Host "   " $serverdir "/bin"
    Write-Host ""
    Write-Host "Modify $serverdir/bin/httpdctl.ps1"
    Write-Host "to make additional adjustments"
} else {
    Write-Host ""
    Write-Host "New server instance created in"
    Write-Host "   " $serverdir
    Write-Host ""
    Write-Host "Modify $serverdir/conf/httpd.conf"
    Write-Host "and $serverdir/bin/httpdctl.ps1"
    Write-Host "to make additional adjustments"
    Write-Host ""
    Write-Host "Install the service by invoking "
    Write-Host "    `"$serverdir/bin/httpdctl.ps1`" install"
}
