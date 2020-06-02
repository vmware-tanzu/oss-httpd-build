#!/usr/bin/perl
#
# VMware Instance Management Schema for Apache HTTP Server
#
# Copyright (C) 2017-2020 VMware, Inc.
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

# newserver.pl
#
# This script creates a server instance director tree from an _instance/ template
#

use POSIX;
use Getopt::Long;
use File::Find;
use File::Spec;
use Cwd;

my $raw = "";
$raw = ":raw" unless (!$^V or ($^V lt v5.8.0));

my $rootdir = cwd;
my $httpdver = "2.4";
my $httpddir;
my $sourcedir;
my $server;
my $serverdir;
my $mpm;
my $update = 0;
my $overlay = 0;
my $quiet = 0;
my $enablessl = 0;
my $help = 0;
my @patterns;
my @plist;
my %smap = (
    MPM => "worker",
    User => "httpd",
    Group => "httpd",
    rel_sysconfdir => "conf",
    rel_logfiledir => "logs",
    exp_runtimedir => "logs",
);

if (!getuid()) {
    $smap{"Port"} =     80;
    $smap{"SSLPort"} = 443;
    $smap{"FTPPort"} =  21;
}
else {
    $smap{"Port"} =    8080;
    $smap{"SSLPort"} = 8443;
    $smap{"FTPPort"} = 8021;
}

print "newserver.pl script - deploy a new httpd server instance\n\n";
 
my $parseresult = GetOptions(
	'rootdir=s'       => \$rootdir,
	'httpdver=s'      => \$httpdver,
	'httpddir=s'      => \$httpddir,
	'sourcedir=s'     => \$sourcedir,
	'server=s'        => \$server,
	'serverdir=s'     => \$serverdir,
	'mpm=s'           => \$mpm,
	'overlay'         => \$overlay,
	'update'          => \$update,
	'quiet'           => \$quiet,
	'enablessl'       => \$enablessl,
	'help'            => \$help,
	'set=s%',         => \%smap,
	'subst=s@',       => \@plist,
);

for my $patn (@plist) {
    (my $find, my $repl) = split /=/, $patn, 2;
    push @patterns, [$repl, qr{$find}];
}

if (!defined($server) && ($#ARGV >= 0) && $parseresult) {
    $server = $ARGV[0];
    shift;
}

if (($#ARGV >= 0) || !$parseresult || $help) {
    syntax();
    if (!$help) {
        print "FATAL: command line arguments could not be parsed.\n";
        if ($parseresult) {
            print "       Specify server name or --server=name option, not both.\n";
        }
    }
    print "\n";
    exit !$help;
}

if (!defined($server)) {
    syntax();
    print "FATAL: server name must be specified\n\n";
    exit 1;
}

if (!File::Spec->file_name_is_absolute($rootdir)) {
    $rootdir = File::Spec->rel2abs($rootdir);
}

if (defined($httpddir)) {
    if (!File::Spec->file_name_is_absolute($httpddir)) {
        $httpddir = File::Spec->rel2abs($httpddir);
    }
    $failcause = "       --httpddir must be valid\n\n";
}
else {
    $httpddir = $rootdir."/httpd-".$httpdver;
    $failcause = "       --rootdir and --httpdver must be valid\n\n";
}

if (!-e $httpddir."/bin/httpd" && !-e $httpddir."/bin/httpd.exe") {
    syntax();
    print "FATAL: " . $httpddir . "/ is not available.\n" . $failcause;
    exit 1;
}

if (defined($sourcedir)) {
    if (!File::Spec->file_name_is_absolute($sourcedir)) {
        $sourcedir = File::Spec->rel2abs($sourcedir);
    }
    $failcause = "       --sourcedir must be valid\n\n";
}
else {
    $sourcedir = $httpddir."/_instance";
    $failcause = "       --rootdir and --httpdver must be valid\n\n";
}
if (!-e $sourcedir."/conf/httpd.conf") {
    syntax();
    print "FATAL: " . $sourcedir . "/ is not available.\n" . $failcause;
    exit 1;
}

if (!defined($serverdir)) {
    $serverdir = $rootdir."/".$server;
    $failcause = "       --server must be unique\n\n";
}
else {
    if (!File::Spec->file_name_is_absolute($serverdir)) {
        $serverdir = File::Spec->rel2abs($serverdir);
    }
    $failcause = "       --serverdir must be unique\n\n";
}

if (defined($mpm) &&
        ($^O eq "MSWin32" || !-e $httpddir."/modules/mod_mpm_".$mpm.".so")) {
    syntax();
    print "FATAL: --mpm=".$mpm." is invalid for this platform and version.\n";
    exit 1;
}

if (defined($mpm)) {
    $smap{"MPM"} = $mpm;
}

if (!$overlay && !$update && -e $serverdir) {
    syntax();
    print "FATAL: " . $serverdir . " exists.\n" . $failcause;
    exit 1;
}

if (! -d $serverdir) {
    if ($overlay || $update) {
        syntax();
        print "FATAL: " . $serverdir . " does not exist.\n" . 
              "       Server directory must exist to --update or --overlay.";
        exit 1;
    }
    $parentdir = File::Spec->updir($serverdir);
    if (! -d $parentdir) {
        syntax();
        print "FATAL: " . $parentdir . " does not exist.\n" . 
              "       The parent directory must exist.";
        exit 1;
    }
}

my @dirs;
if ($update) {
    @dirs = (
        $sourcedir . "/bin"
    );
} else {
    @dirs = (
        $sourcedir . "/bin",
        $sourcedir . "/cgi-bin",
        $sourcedir . "/conf",
        $sourcedir . "/ftpdocs",
        $sourcedir . "/htdocs"
    );
}

# It is highly unadvised to --set these overrides, that is not supported;
#
$smap{"ServerInstance"} = $server if (!defined($smap{"ServerInstance"}));
$smap{"ServerRoot"} = $serverdir if (!defined($smap{"ServerRoot"}));
$smap{"exp_cgidir"} = $serverdir . "/cgi-bin" if (!defined($smap{"exp_cgidir"}));
$smap{"exp_htdocsdir"} = $serverdir . "/htdocs" if (!defined($smap{"exp_htdocsdir"}));
$smap{"exp_ftpdocsdir"} = $serverdir . "/ftpdocs" if (!defined($smap{"exp_ftpdocsdir"}));
$smap{"exp_httpddir"} = $httpddir if (!defined($smap{"exp_httpddir"}));

if (!$update && !$quiet) {
    if (promptyn("\nEnable SSL and create a default key [y/n]? ")) {
	$enablessl = 1;
	push @patterns, ["Include \@rel_sysconfdir\@/extra/httpd-ssl.conf",
			 qr{#Include \@rel_sysconfdir\@/extra/httpd-ssl.conf}];	
	push @patterns, ["LoadModule ssl_module",
			 qr{#LoadModule ssl_module}];	
	push @patterns, ["LoadModule socache_shmcb_module",
			 qr{#LoadModule socache_shmcb_module}];	
    }
    $smap{"HostName"} = $server if (!length($smap{"HostName"}));
    $name = prompt("Server hostname (e.g. www.example.com) [$smap{'HostName'}]? ");
    $smap{"HostName"} = $name if (length($name));
    if (!length($smap{"ServerAdmin"})) {
        $smap{"ServerAdmin"} = "webmaster\@".$smap{"HostName"};
    }
    $name = prompt("Administrator email [$smap{'ServerAdmin'}]? ");
    $smap{"ServerAdmin"} = $name if (length($name));
    
    $port = prompt("Port for http:// traffic        [$smap{'Port'}]? ");
    $smap{"Port"} = $port if (int($port));
    if ($enablessl) {
        $port = prompt("Port for https:// traffic       [$smap{'SSLPort'}]? ");
        $smap{"SSLPort"} = $port if (int($port));
    }
}
else {
    $smap{"HostName"} = $server if (!length($smap{"HostName"}));
    if (!length($smap{"ServerAdmin"})) {
        $smap{"ServerAdmin"} = "webmaster\@".$smap{"HostName"};
    }
}

my @vfgrnam = getgrnam($smap{"Group"});
if (!@vfgrnam) {
    if (getuid()) {
        print "FATAL: group $smap{'Group'} does not exist.  Rerun this utility\n"
            . "       as user root to create the $smap{'Group'} group before the\n"
            . "       requested instance can be created.\n";
        exit 1;
    }
    if ($^O eq 'aix') {$cmd = '/usr/bin/mkgroup'}
                 else {$cmd = '/usr/sbin/groupadd'};
    if ($^O eq 'linux') {$cmd .= ' -r'};
    if (system($cmd . " $smap{'Group'}")) {  
        print "FATAL: failed to create system group $smap{'Group'}.\n";
        exit 1;
    }
    print "Created $smap{'Group'} system group\n\n";
    @vfgrnam = getgrnam($smap{"Group"});
}

my @vfpwnam = getpwnam($smap{"User"});
if (!@vfpwnam) {
    if (getuid()) {
        print "FATAL: account $smap{'User'} does not exist.  Rerun this utility\n"
            . "       as user root or create the $smap{'User'} user account before\n"
            . "       requested instance can be created.\n";
        exit 1;
    }
    if ($^O eq 'aix') {
        if (!-e '/var/empty') {
            mkdir('/var/empty', 0755);
            chown 0, 0, '/var/empty';
        }
        $cmd = "/usr/bin/mkuser pgrp=$smap{'Group'} groups=$smap{'Group'},staff"
             . " gecos='Apache HTTP Server unprivileged user' home=/var/empty"
             . " account_locked=true login=false rlogin=false";
    } else {
        $cmd = "/usr/sbin/useradd -g $smap{'Group'}"
             . " -c 'Apache HTTP Server unprivileged user'";
        if ($^O eq 'linux') {
            # linux alone supports -r 'system' accounts and a 'nologin' shell
            $cmd .= ' -r -s /sbin/nologin';
        }
        else {
            # hpux and solaris may use /bin/false for sh
            $cmd .= ' -s /bin/false';
        }
        # Linux and solaris may use / - this has adverse effects on aix, hpux
        if ($^O ne 'hpux') {$cmd .= ' -d /';};
    }
    if (system($cmd . " $smap{'User'}")) {
        print "FATAL: failed to create system user account $smap{'User'}.\n";
        exit 1;
    }
    print "Created $smap{'User'} system user account\n\n";
    @vfpwnam = getpwnam($smap{"User"});
}

if ($update) {
    print "\nUpdating server instance scripts in ".$serverdir . "/bin\n".
          "from the ".$sourcedir."/bin\n".
          "template instance tree\n";
} else {
    print "\nCreating new server instance ".$serverdir . "\n".
          "from the ".$sourcedir."\n".
          "template instance tree\n";
}

# logs/safe/ and var/ are writable work areas for the unprivileged worker
# but must be treated as confidential including per-user session secrets
#
# logs/ must never be writable by the unprivileged worker. httpd modules
# carefully assign specific ownership/rights to specific logs/ files during 
# the startup phase as root.  The contents of the logs/ tree may also 
# contain confidential or per-user session secrets.
#
if (!(-e $serverdir || mkdir($serverdir))) {
    print "FATAL: failed to create directory $serverdir\n".
          "       Permissions problem or missing parent directory?\n";
    exit 1;
}
mkdir $serverdir."/ssl"              if (!-e $serverdir . "/ssl");
mkdir($serverdir."/logs", 0750)      if (!-e $serverdir . "/logs");
mkdir($serverdir."/logs/safe", 0700) if (!-e $serverdir . "/logs/safe");
mkdir($serverdir."/var", 0770)       if (!-e $serverdir . "/var");

chown @vfpwnam[2], @vfgrnam[2], $serverdir."/logs/safe", $serverdir."/var";
chown getuid(), @vfgrnam[2], $serverdir."/logs";

find(\&wanted, @dirs);

if (!$quiet && $enablessl) {
    if ($^O =~ /Win32/) {
        $ENV{'PATH'} = $httpddir . "\\bin;" . $ENV{'PATH'};
    } else {
        my $libpathvar = "LD_LIBRARY_"."PATH";
        if ($^O eq "aix")  { $libpathvar = "LIBPATH"; }
        $ENV{$libpathvar} = $httpddir . "/lib" . 
                            (length $ENV{$libpathvar} > 0 ? ":" : "") . 
                            $ENV{$libpathvar};
    }

    $ENV{"OPENSSL_CONF"} = $httpddir . "/ssl/openssl.cnf";
    my $opensslbin = "\"" . $httpddir . "/bin/openssl\"";
    my $sslfiles = $serverdir . "/ssl/" . $smap{"HostName"};

    $bits = prompt("\nSize of SSL RSA key, in bits [2048]? ");
    $bits = 2048 if (int($bits) < 512); 
    sysopen(FH, $sslfiles.".key", O_RDWR|O_CREAT, 0600);
    close(FH);
    if (system ($opensslbin . " genrsa -out \"$sslfiles.key\" $bits")) {
        print "FATAL: failed to invoke openssl genrsa.  The package may be\n" 
            . "       incompatible with your OS or CPU architecture, or your\n"
            . "       install may be misconfigured (wrong user id, etc).";
        exit 1;
    }
    print "\nCreated ".$sslfiles.".key\n";

    sysopen(FH, $sslfiles.".pem", O_RDWR|O_CREAT, 0640);
    close(FH);
    do {
        print "\nChoose a passphrase to encrypt the .pem backup copy ".
              "of this key\n"; 
    } while (system($opensslbin . " rsa -aes256 -check" .
                    " -in \"$sslfiles.key\" -out \"$sslfiles.pem\""));
    sysopen(FH, $sslfiles.".csr", O_RDWR|O_CREAT, 0640);
    close(FH);
    do {
        print "\nFill in information for this certificate.\n";
        print "(The Common Name (CN) below MUST match ServerName!):\n\n";
    } while (system($opensslbin . " req -new -key \"$sslfiles.key\"" .
                                  " -out \"$sslfiles.csr\""));
    system($opensslbin . " x509 -req -days 366 -sha256 -in \"$sslfiles.csr\"" .
                         " -signkey \"$sslfiles.key\" -out \"$sslfiles.crt\"");
    print "\nSSL files generated as ".$sslfiles.".*\n".
          " .key - unencryped private key (perm 0600 for security).\n".
          " .pem - aes256 encrypted private key - back up this file!\n".
          " .csr - certificate signing request - submit this to the CA.\n".
          " .crt - self-signed certificate, replace with cert signed by the CA.\n".
          "Be certain to record the passphrase to decrypt the .pem file.\n".
          "Never transmit the .key file or cause it to be readable by others!\n";
}

if (!$quiet) {
    if ($update) {
        print "\nServer instance scripts updated in\n".
              "    ".$serverdir."/bin\n\n".
              "Modify ".$serverdir."/bin/httpdctl\n".
              "to make additional adjustments.\n\n";
    } else {
        print "\nNew server instance created in\n".
              "    ".$serverdir."\n\n".
              "Modify ".$serverdir."/conf/httpd.conf\n".
              "and ".$serverdir."/bin/httpdctl\n".
              "to make additional adjustments.\n\n";
    }
}

sub syntax {
    print "Syntax: $0 [--options] [servername]\n\n".
     "\t--rootdir=/path-to-httpdserver  default is current dir\n".
     "\t--server=servername             host and default path name to create\n".
     "\t--serverdir=/path/to/instance   default is rootdir/{servername}/ target\n".
     "\t--update                        update only {serverdir}/bin scripts\n".
     "\t--overlay                       overlay existing {serverdir} files\n\n".
     "\t--mpm=[worker|prefork|event]    unix process model, default is worker\n".
     "\t--httpdver=[2.4.9.0-64]         default is 2.4 [symlinked to current]\n".
     "\t--httpddir=/path/to/httpd       default is rootdir/httpd-{ver}/\n".
     "\t--sourcedir=/path/to/template   default is httpddir/_instance/ template\n".
     "\t--set token=value               replace @token@ with value\n".
     "\t--subst regex=value             replace regex with value (before --set)\n".
     "\t--quiet                         bypass all interactive prompts\n".
     "\t--help                          display this help information\n\n";
}

sub prompt {
    my $promptstr = shift;
    print $promptstr;
    my $response = <STDIN>;
    $response =~ s/^\s*//;
    $response =~ s/\s*$//;
    return $response;
}

sub promptyn {
    my $promptstr = shift;
    while (1) {
        my $response = prompt($promptstr);
        return 1 if $response =~ /[Yy]/;    
        return 0 if $response =~ /[Nn]/;    
    }
}
 
sub wanted {
    # $File::Find::dir has directory name, $_ filename
    # and $File::find::name has complete filename
    #
    my $filename  = $_;

    my $srcfile = $File::Find::dir . '/' . $_;
    my $dstdir = $File::Find::dir;
    $dstdir =~ s{$sourcedir}{$serverdir};
    my $dstfile = $dstdir . '/' . $_;

    mkdir($dstdir) unless (-e $dstdir);

    # ignore symlinks and others
    #
    return unless (-f);

    my $permissions = (stat($srcfile))[2];
    my $timestamp   = (stat($srcfile))[9];
    my $foundp      = 0;

    if (!open(FHIN, "<".$raw, $srcfile)) {
 	warn "$0 could not open $srcfile: $!$/";
	return;
    }
	
    if (!open(FHOUT, ">".$raw, $dstfile)) {
 	warn "$0 could not open $dstfile: $!$/";
	return;
    }

    if (-B || m|/htdocs/| || m|/webapps/|) {

        my $buf;

	while (1) {

	    my $buflen = sysread(FHIN,$buf,16384);

	    if (!defined($buflen)) {
 		warn "$0 failure reading $srcfile: $!$/";
		close(FHOUT);
		close(FHIN);
		unlink($dstfile);
		return;
	    }

            last if ($buflen < 1);

	    my $res = syswrite(FHOUT,$buf,$buflen);

	    if (!defined($res) || ($res < $buflen)) {
 		warn "$0 failure writing $dstfile: $!$/";
		close(FHOUT);
		close(FHIN);
		unlink($dstfile);
		return;
	    }
        }
    }
    else {
	while (<FHIN>) {
	    for my $patn (@patterns) {
		(my $repl, my $find) = @$patn;
		$foundp = 1 if s{$find}{$repl}g;
	    }
            while ((my $find, my $repl) = each %smap) {
		$foundp = 1 if s{\@$find\@}{$repl}g;
	    }
	    print FHOUT $_;
	}
    }

    close(FHOUT);
    close(FHIN);

    my @filenames = ($dstfile);
    utime $timestamp, $timestamp, @filenames unless ($foundp);
    chmod($permissions, $dstfile);
}

