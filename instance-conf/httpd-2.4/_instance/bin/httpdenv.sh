#/bin/sh
#
# Copyright (c) 2017 Pivotal Software, Inc.  All rights reserved.
#
# httpdenv.sh
#
#   This script sets up environment variables to allow the user
#   to interact with Pivotal Web Server server instance scripts
#   and bundled /bin utilities from the command line.

PATH=@ServerRoot@/bin:@@PRODUCT_ROOT@@/httpd-2.4/bin:$PATH
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

