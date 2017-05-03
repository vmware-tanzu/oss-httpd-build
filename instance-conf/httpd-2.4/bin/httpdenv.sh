#/bin/sh
#
# Pivotal OSS Instance Management Schema for Apache HTTP Server
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

#
# httpdenv.sh
#
#   This script sets up environment variables to allow the user
#   to interact with Pivotal Web Server bundled /bin utilities
#   from the command line.

PATH=@@PRODUCT_ROOT@@/httpd-2.4/bin:$PATH
export PATH

LD_LIBRARY_PATH=@@PRODUCT_ROOT@@/httpd-2.4/lib${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

OPENSSL_CONF=@@PRODUCT_ROOT@@/httpd-2.4/ssl/openssl.cnf
export OPENSSL_CONF

MANPATH=@@PRODUCT_ROOT@@/httpd-2.4/man:$MANPATH
export MANPATH

# If the user exec's this script, offer them a helpful hint;
#
if test "`echo $0|sed \"s#.*/##\"`" = "httpdenv" ; then
    echo Using sh or bash, remember begin the command line with a period
    echo '.' followed by a space and this script name to call this script
    echo and set up the tools environment variables in the current context.
fi

