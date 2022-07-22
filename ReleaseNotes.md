# **Release Notes for VMware Build for Apache HTTP Server Package**

## **What’s in the Release Notes**

These release notes cover the following topics:

* Package Description
* Included Components
* RHEL 7 Users
* RHEL 8 Users
* Ubuntu 18.04 / 20.04 Users
* Microsoft Windows Users
* Installation
* Instance Creation
* Updating Instances

## **Package Description**

This package consists of Apache HTTP Server (httpd), along with a number of frequently updated library components (dependencies) required by httpd or one of its optional modules. This package is assembled with VMware's [https://github.com/vmware-tanzu/oss-httpd-build](https://github.com/vmware-tanzu/oss-httpd-build) OSS Build and Server Instance Schema for Apache HTTP Server.

This package is structured to allow parallel installation of multiple releases of Apache HTTP Server and related components. It contains one directory tree, labeled as httpd-{version}-{date tag} which represents the version of httpd and the effective date of all components bundled in the package.

Unlike many httpd distributions, the end user instance configuration, server content, and logs and are not modified in this program distribution tree. See the section on Instance Creation for details of creating a server instance with these user maintained files.

In order to build httpd from scratch, see additional details at VMware's [https://github.com/vmware-tanzu/oss-httpd-build](github oss-httpd-build) project. A tarball of unix sources and zipfile of windows sources is provided alongside the binary release downloads for ready reference.

Versions prior to 2.4.53 used the OpenSSL and PCRE-8.x legacy versions. As of httpd 2.4.53, OpenSSL release 3.0 and PCRE2 release 10.x are used instead. If modules were also compiled to consume OpenSSL or PCRE2 themselves, they must be rebuilt.

## **Included Components**

The following components are included in this build; those marked (\*) are not compiled for modern linux distributions, but the OS Vendor's distribution packages are used instead. Links to the user change notes and vulnerability indexes are illustrated below.

In cases where the project does not maintain a reference to specific CVE's in an easily web accessible format the [https://www.cvedetails.com/vulnerability-list/](https://www.cvedetails.com/vulnerability-list/) database link is provided; this list is not endorsed as complete or comprehensive and is offered for convenience only.

[http://www.apache.org/dist/httpd/CHANGES_2.4]  
[http://httpd.apache.org/security/vulnerabilities_24.html]
* Apache APR library 1.7  
[http://www.apache.org/dist/apr/CHANGES-APR-1.7]
* Apache APR-iconv library 1.2 (\*)  
[http://www.apache.org/dist/apr/CHANGES-APR-ICONV-1.2]
* Apache APR-util library 1.6  
[http://www.apache.org/dist/apr/CHANGES-APR-UTIL-1.6]
* brotli compression library  
[https://github.com/google/brotli/releases]
* Curl  
[https://curl.haxx.se/changes.html]  
[https://curl.haxx.se/docs/security.html]
* Jansson (\*)  
[https://jansson.readthedocs.io/en/latest/changes.html]
* libexpat (\*)  
[https://github.com/libexpat/libexpat/blob/master/expat/Changes]
* libxml2 (\*)  
[https://www.cvedetails.com/vulnerability-list/vendor_id-1962/product_id-3311/Xmlsoft-Libxml2.html]  
[http://www.xmlsoft.org/news.html] (out of date)
* Lua language (\*)  
[https://www.cvedetails.com/vulnerability-list/vendor_id-13641/product_id-28436/LUA-LUA.html]  
[https://www.lua.org/bugs.html]
* nghttp2 library  
[https://github.com/nghttp2/nghttp2/releases]
* OpenSSL library  
[https://www.openssl.org/news/vulnerabilities.html]  
[https://www.openssl.org/news/changelog.html]
* PCRE library (\*)  
[https://www.cvedetails.com/vulnerability-list/vendor_id-3265/product_id-33513/Pcre-Pcre2.html]  
[https://www.pcre.org/changelog.txt]
* Zlib compression library (\*)  
[https://www.cvedetails.com/vulnerability-list/vendor_id-72/product_id-1820/GNU-Zlib.html]  
[https://zlib.net/ChangeLog.txt]

## **RHEL 7 Users**

The RHEL 7 package requires several commonly installed packages to be available, these may be provisioned with the following command;
```
$ yum install expat jansson libuuid libxml2 lua pcre2 zlib
```
In order to use the provided apxs utility, additional packages are required as indicated at the [https://github.com/vmware-tanzu/oss-httpd-build](https://github.com/vmware-tanzu/oss-httpd-build) README page.

## **RHEL 8 Users**

The RHEL 7 package is compatible with RHEL 8 and Fedora 30+, and requires some less commonly installed packages to be available. These may all be provisioned with the following command;

$ dnf install expat jansson libuuid libxcrypt libxml2 lua pcre2 zlib

On some later flavors of linux, libxcrypt may go by the package designation libxcrypt-compat instead.

## **Ubuntu 18.04 and 20.04 Users**

The Ubuntu 18.04 package (compatible with 20.04) requires several commonly installed packages to be available, these may be provisioned with the following command;
```
$ apt-get install libexpat1 libjansson4 liblua5.3-0 libpcre2-8-0 libuuid1 libxml2 zlib1g
```
In order to use the provided apxs utility, additional packages are required as indicated at the [https://github.com/vmware-tanzu/oss-httpd-build](https://github.com/vmware-tanzu/oss-httpd-build) README page.

## **Microsoft Windows Users**

This package is built using Visual C++ 19 and C Runtime version 14, components of Microsoft Visual Studio 2022. Windows Server 2022 and Windows Server 2019 are both suitable for deployment. Windows 11 and Windows 10 Desktop are suitable for developer evaluation but are not suitable for server deployment, as Microsoft restricts the Windows Desktop license, limiting aspects of the operating system behavior including the Windows Sockets API, and tunes the process scheduler to deliver a better desktop experience.

Users must obtain and install the "Microsoft Visual C++ Redistributable for Visual Studio 2022", x64 edition; from [https://visualstudio.microsoft.com/downloads/](https://visualstudio.microsoft.com/downloads/) (currently this is listed under Other Tools and Frameworks, and provides support for Visual Studio 2015, 2017 and 2019 as well.) Install the x64 flavor, and observe the prerequisites noted for that package. Installing this package from Microsoft ensures that this runtime is updated by the Windows Update service for security vulnerabilities within the Universal C Runtime itself.

Note that Pivotal convenience packages prior to httpd 2.4.53 were built with Visual Studio 2017 or 2019. This may cause issues for users who have compiled third-party modules. Users are advised to rebuild any such modules before combining them with these newer packages.

This package relies upon Windows PowerShell to execute the httpd control scripts on Windows computers. All supported Windows versions have PowerShell installed by default, but specific installations of Windows may not. To check whether your version of Windows has PowerShell installed, go to Start > All Programs > Accessories and check for **Windows PowerShell** in the list.

If Windows PowerShell is not already installed, install it as directed at; 

  https://docs.microsoft.com/en-us/powershell/scripting/setup/setup-reference

If necessary, enable Windows PowerShell for script processing; script processing may be disabled by default;

1. Start PowerShell from the Start Menu as an Administrator by opening Start > All Programs > Accessories > Windows PowerShell, then right-clicking on Windows PowerShell and selecting Run as Administrator. A PowerShell window starts.

2. Check the current PowerShell setting by executing the following command:  
`PS prompt> Get-ExecutionPolicy`

3. If the command returns Restricted, it means that PowerShell is not yet enabled. Enable it to allow local script processing at a minimum by executing the following command:  
`PS prompt> Set-ExecutionPolicy RemoteSigned`

4. You can choose a different execution policy for your organization if you want, as well as enable PowerShell using Group and User policies. Typically, only the Administrator will be using the server control scripts, so the RemoteSigned execution policy should be adequate in most cases.

Windows users must also take note that extracting the zip file contents using the File Explorer from a remote drive or volume, or from an untrusted "blocked" file will result in untrusted and non-executable files and scripts. For the windows binary package, copy the .zip file to a local drive before using the File Explorer extraction tool. If the .zip file was downloaded, then using the Windows File Explorer examine the .zip file properties, and under 'Security' below the 'Attributes' item, check the "Unblock" checkbox to mark the zip file contents as trusted. If the 'Security' item is not present, the file is already unblocked.

In the command-line examples given below, unzip is provided by info-zip, while mklink is an intrinsic cmd.exe command which is not available from PowerShell.

## **Installation**

Create the desired install path, such as `/opt/apache/webserver` or `c:\apache\webserver`, and unpack the tar.bz2 or .zip file into that directory. From this root directory, invoke the fixrootpath script to correct the embedded paths to the current path, and finally create a symlink when ready to adopt this installation as the "accepted" httpd-2.4 installation path.

During an upgrade, restart each server instance individually and verify the correct operation of that instance's hosts. If there is a problem resulting from an upgrade, simply restore the symlink to the previously installed httpd path, and restart the servers with the old version to avoid unnecessary interruption. When correct operation is verified the older httpd version can be expunged.

Unix users (running as root);
```
$ mkdir -p /opt/apache/webserver  
$ cd /opt/apache/webserver  
$ tar -xjvf {path-to}/httpd-{version-tag}-{arch}.tar.bz2  
$ httpd-{version-tag}/bin/fixrootpath.pl httpd-{version-tag}  
$ ln -s httpd-{version-tag} httpd-2.4  
```

Windows users (in a Command window 'Run as Administrator');
```
C:\> mkdir \Apache\WebServer  
C:\> cd \Apache\WebServer  
C:\Apache\WebServer> unzip {path-to}\httpd-{version-tag}-windows-x64.zip  
C:\Apache\WebServer> powershell httpd-{version-tag}\bin\fixrootpath.ps1 httpd-{version-tag}  
C:\Apache\WebServer> mklink /d httpd-2.4 httpd-{version-tag}  
```

**Instance Creation**

This distribution of Apache HTTP Server is parameterized to allow multiple instances to be created and managed independently, without duplicating the binary files. The instance directory is typically named for a primary server hostname and contains the instance-specific directories conf, htdocs, logs and ssl (for certificates and keys).

Unix users (running as root);
```
$ cd /opt/apache/webserver  
$ httpd-2.4/bin/newserver.pl --server {hostname}  
$ cd {hostname}  
$ bin/httpdctl install  
$ bin/httpdctl start
```

Windows users (in PowerShell 'Run as Administrator');
```
PS C:\> cd \Apache\WebServer  
PS C:\Apache\WebServer> httpd-2.4\bin\newserver.ps1 --server {hostname}  
PS C:\Apache\WebServer> cd {hostname}  
PS C:\Apache\WebServer\example.com> bin\httpdctl.ps1 install  
PS C:\Apache\WebServer\example.com> bin\httpdctl.ps1 start
```

Modify the files in `{hostname}/conf/` to customize the server behavior. Use the httpdenv script in the bin directory of the instance to have access to the various tools shipped in the httpd-2.4 bin directory;
```
$ . bin/httpdenv.sh
```

Or on Windows;
```
PS C:\Apache\WebServer\example.com> bin\httpdenv.ps1
```

The `httpdctl uninstall` command will remove the service from automatic startup at boot time.

**Updating Instances**

In general, no special action is required when upgrading between httpd-2.4.x releases, directives should be backwards-compatible. Restarting the server with httpdctl should be sufficient. From time to time, httpdctl itself is upgraded, and to update the instance with refreshed control scripts, it is best to uninstall any system service associated with the instance, use the --update feature of newserver.ps, and finally re-install the system service (with potentially a new service name.)

Unix Users (running as root);

1. Stop and uninstall the old instance:
```
$ cd /opt/apache/webserver
$ {instance}/bin/httpdctl stop
$ {instance}/bin/httpdctl uninstall
```
2. Update the httpdctl script with new features plus any revised service names:
```
$ httpd-2.4/bin/newserver.pl --server={instance} --update
```
3. Install and start the service with the new name:
```
$ {instance}/bin/httpdctl install
$ {instance}/bin/httpdctl start
```
4. Repeat steps 1-3 for each server instance.

Windows Users (in PowerShell 'Run as Administrator');

1. Stop and uninstall the old instance:
```
PS > cd C:\Apache\WebServer
PS C:\Apache\WebServer> {instance}\bin\httpdctl.ps1 stop
PS C:\Apache\WebServer> {instance}\bin\httpdctl.ps1 uninstall
```
2. Update the httpdctl script with new features plus any revised service names:
```
PS C:\...> httpd-2.4\bin\newserver.ps1 --server={instance} --update
```
3. Install and start the service with the new name:
```
PS C:\Apache\WebServer> {instance}\bin\httpdctl install
PS C:\Apache\WebServer> {instance}\bin\httpdctl start
```
4. Repeat steps 1-3 for each server instance.

