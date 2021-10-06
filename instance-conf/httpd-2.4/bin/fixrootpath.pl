#!/usr/bin/perl
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

# fixrootpath.pl
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

use Getopt::Long;
use File::Find;
use Cwd;

my $DESTDIR   = Cwd::cwd;
my $SUBSTDIR  = '@@PRODUCT'.'_ROOT@@';

GetOptions('srcdir=s'   => \$SUBSTDIR,
	   'dstdir=s'   => \$DESTDIR);

if (length($DESTDIR) < 2) {
    print "Error; invalid --dstdir was given, or could not be determined by Cwd::cwd\n";
    exit 1;
}

if (length($SUBSTDIR) < 2) {
    print "Error; invalid --srcdir was given\n";
    exit 1;
}

my $STRIPDIR = $SUBSTDIR;
if ($^O =~ /Win32/) {
  $SUBSTDIR =~ s#[\/\\]+#[\\\/\\\\]\+#g;
} else {
  $SUBSTDIR =~ s#\/+#\\\/\+#g;
}

my $URIROOT = '(file\:)?\/\/' . $SUBSTDIR . "\\\/\+html\\\/\+";
my $STRIPDIR = $SUBSTDIR;
$STRIPDIR .= '\/+html\/+';

my $BSDESTDIR = $DESTDIR;
$BSDESTDIR =~ s#\\#/#g;

my $BSSDESTDIR = $DESTDIR;
$BSSDESTDIR =~ s#/#\\#g;

print "Replacing $SUBSTDIR with $DESTDIR\n";

my @dirs = @ARGV;

if (!scalar @ARGV) {
    @dirs = (cwd);
}

find(\&wanted, @dirs);

sub wanted {
	# $File::Find::dir has directory name, $_ filename
	# and $File::find::name has complete filename
	#
	my $filename  = $_;

	# ignore symlinks and others
	#
	return if (! -f || -B);

        # ignore subversion base files
        return if ($File::Find::dir =~ /\/.svn/ || $File::Find::dir =~ /\/CVS/);
        
        # Special case, executable names containing periods
        return if (/^httpd\.(worker|prefork|event)/);

        # General case, binary names
        return if (/\.(a|so|xs|sl|lib|dll|exe)$/);

        # Binary names with no period suffix, excluding script names
        if (!/\./) {
            return if ( !/^dbmmanage$/ && !/^envvars$/ && !/^envvars-std$/ 
                     && !/^apxs$/ && !/^httpdctl$/ && !/^apachectl$/
		     && !/^c_rehash$/ && !/-config$/);
        }
			
	my $permissions = (stat($filename))[2];
	my $timestamp   = (stat($filename))[9];
	my $tmpname     = $filename . ".tmp~";
	my $foundp      = 0;
	my $foundu      = 0;

        my $RELPATH = $File::Find::dir . '/';
        $RELPATH =~ s#(${STRIPDIR})##i;
        if ($^O =~ /Win32/) {
            $RELPATH =~ s#\\+#\/#;
        }        
        $RELPATH =~ s#^\/+##g;
        $RELPATH =~ s#[^\/]+#..#g;        

	if ($^O =~ /Win32/) {
	    # defines in the .h / Config.pm files must be double backslashed.
	    if ($filename =~ /\.h$/i || $filename =~ /Config.pm$/i) {
		$DESTDIR = $BSSDESTDIR;
	    } else {
		$DESTDIR = $BSDESTDIR;
	    }
	}

	if (!open(FHIN, "<".$filename)) {
	    warn "$0 could not open $filename: $!$/";
	    return;
	}
	if (!open(FHOUT, ">".$tmpname)) {
	    warn "$0 could not open $tmpname: $!$/";
	    return;
	}

	binmode FHIN;
	binmode FHOUT;

        while (<FHIN>) {
  	    if ($_ =~ s#(${URIROOT})#$RELPATH#g) {
		$foundu = 1;
	    }
  	    if ($_ =~ s#(${SUBSTDIR})#$DESTDIR#g) {
		$foundp = 1;
	    }
	    print FHOUT $_;  # this prints to tmpname'ed file
	}

	close(FHOUT);
	close(FHIN);

	if ($foundp || $foundu) {
            my $bakname = $filename . ".bak~";
	    rename($filename, $bakname);
	    rename($tmpname, $filename);
	    unlink($bakname);

	    my @filenames = ($filename);
	    utime $timestamp, $timestamp, @filenames;
	    chmod($permissions, $filename);

            print $File::Find::dir . '/' . $filename . "\n";
	}
	else {
	    unlink($tmpname);
        }
}
