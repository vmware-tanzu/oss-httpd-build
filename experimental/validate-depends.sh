#!/usr/bin/bash
#
# VMware OSS Build Schema for Apache HTTP Server
# Copyright (c) 2017-2020 VMware, Inc.
# Licensed under the Apache Software License 2.0
# 
# validate-depends.sh : Review required -dev[el] dependencies

if test -f /etc/redhat-release; then
    echo RedHat development package dependencies:
    if which dnf >/dev/null 2>&1; then 
        dnf list expat-devel libxml2-devel lua-devel pcre-devel zlib-devel
    else
        yum list expat-devel libxml2-devel lua-devel pcre-devel zlib-devel
    fi
elif test -f /etc/debian_version; then
    echo Ubuntu development package dependencies:
    dpkg-query --list libexpat1-dev libxml2-dev zlib1g-dev liblua5.2-0 libpcre3-dev
    echo '[Note pcre2(10.x) and lua(5.3) are not presently supported]'
else
    echo Unrecognized architecture.
    echo Verify the following development dependency packages are installed:
    echo 'Expat(2.x)  libxml2(2.9)  lua(5.2+)  pcre(8.x)  zlib(1.2)'
    echo '[Note pcre2(10.x) is not presently supported]'
fi
