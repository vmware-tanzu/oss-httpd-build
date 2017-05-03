#
# Pivotal OSS Build Schema for Apache HTTP Server
#
# Copyright (c) 2017 Pivotal Software, Inc.
#
# Pivotal licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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

