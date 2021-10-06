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

# fixrootpath.ps1
#
# This script searches and replaces the installation paths specified by:
#
#   --srcdir=path or string to be replaced 
#   --dstdir=/path/to/destination/installation
#
# This package of Apache HTTP Server includes two patterns to replace:
#
#   @@ PRODUCT_ROOT @@    --  the product root path
#   @@ SERVER_ROOT @@     --  one /path-to-root/servers/{instance}
#                             to be used for individual server instances
#
# Invoking this script from the product root path will default the
# @@ PRODUCT_ROOT @@ to the current working directory
#
# NOTE: the whitespace within the @@ ... @@ patterns above is to prevent
# this script from modifying it's own documentation - do not include the
# spaces when specifying these patterns.

$name = "fixrootpath"
$OutputEncoding = [System.Text.Encoding]::UTF8
 
Write-Host "fixrootpath.ps1 script - adjusts paths or strings in text files"
Write-Host ""

function syntax {
    Write-Host "fixrootpath.ps1 [--srcdir={pattern}] [--dstdir={pattern}] [path [path...]]"
    Write-Host "    --srcdir={pattern}  expression to replace, defaults to @@PRODUCT`_ROOT@@"
    Write-Host "    --dstdir={string}   replacement path, defaults to current working"
    Write-Host "                        directory using forward-slash notation,"
    Write-Host "                        e.g. C:/Apache/WebServer"
    Write-Host ""
    Write-Host "The path list may contain one or more explicit file names or path names"
    Write-Host "to recursively search for non-binary files.  The default path to recurse"
    Write-Host "is the current working directory."
}

$srcdir = "@@PRODUCT`_ROOT@@"
$dstdir = $pwd -replace "\\", "/"
 
foreach ($arg in $args) {
    if ($arg.StartsWith("--srcdir=")) {
        $srcdir = $arg.Substring("--srcdir=".Length)
    }
    elseif ($arg.StartsWith("--dstdir=")) {
        $dstdir = $arg.Substring("--dstdir=".Length)
    }
    elseif ($arg -eq "--help") {
        syntax
        exit
    }
    elseif ($arg.StartsWith("--")) {
        syntax
        Write-Host "FATAL: unrecognized command line option" $arg
        exit 1
    }
    elseif ((-not (Test-Path $arg)) -or ((get-childitem -path $arg).length -lt 1)) {
        syntax
        Write-Host "FATAL: file or folder" $arg "not found"
        exit 1
    }
}

$rex = [regex] $srcdir

Write-Host "Replacing" $srcdir "with" $dstdir

$ignoreext = @{".exe" = $null; ".dll" = $null; ".so"  = $null; ".pdb" = $null;
               ".lib" = $null; ".obj" = $null; ".exp" = $null; ".ico" = $null;
               ".png" = $null; ".gif" = $null; ".jpg" = $null; ".jpeg" = $null}

function fixfiles ($files) {
    foreach ($file in $files) {
        $origname = $file.FullName
        if ($file.PSIsContainer) {
             $subfiles = (get-childitem -path $origname)
             if ($subfiles.length -gt 0) { fixfiles $subfiles }
        }
        elseif (($file.Extension.length -lt 1) -or (-not $ignoreext.ContainsKey($file.Extension.ToLower()))) {
             try {
                 $repl = $false
                 $contents = Get-Content -Encoding UTF8 -path $origname
                 for ($i = 0; $i -lt $contents.length; ++$i) {
                     $newtxt = $rex.Replace($contents[$i], $dstdir)
                     if ($newtxt -ne $contents[$i]) {
                         $repl = $true; $contents[$i] = $newtxt
                     }
                 }
                 if ($repl) {
                     $contents | out-file $origname -enc utf8
                     Write-Host "Modified" $origname
                 }
             }
             catch {
             }
        }
    }
}

$files = $null
foreach ($arg in $args) {
    if (-not $arg.StartsWith("--")) {
        $files = (get-childitem -path $arg)
        fixfiles $files
    }
}

if ($files -eq $null) {
    $files = (get-childitem -path ".")
    fixfiles $files
} 

Write-Host "Replacement complete"
