#
# Copyright © 2017 Pivotal Software, Inc. All rights reserved.
#
# httpdenv.ps1
#
#   This script sets up environment variables to allow the user
#   to interact with Pivotal Web Server bundled /bin utilities
#   from the command line.
#
# Be absolutely certain to save this file in Encoding 'UTF-8'.

$OutputEncoding = [System.Text.Encoding]::UTF8

$env:PATH = "@@PRODUCT_ROOT@@/httpd-2.4/bin;" + $env:PATH

$env:OPENSSL_CONF = "@@PRODUCT_ROOT@@/httpd-2.4/ssl/openssl.cnf"

