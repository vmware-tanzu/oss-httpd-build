# **Release Notes for Pivotal Build of Apache HTTP Server httpd-2.4.29-171109**

## **What’s in the Release Notes**

These release notes cover the following topics:

* Package Description

* Included Components

* RHEL 7 Users

* Ubuntu 16.04 Users

* Microsoft Windows Users

* Installation

* Instance Creation

## **Package Description**

This package is a courtesy build of Pivotal's [https://github.com/appsuite/oss-httpd-build](https://github.com/appsuite/oss-httpd-build) framework, to provide a reference for customers of Pivotal's support for the open source Apache HTTP Server project. This includes Apache HTTP Server (httpd), along with a number of frequently updated library components (dependencies).

This package is structured to allow parallel installation of multiple releases of Apache HTTP Server and related components. It contains one directory tree, labeled

httpd-2.4.29-171109

This represents the version of httpd and the effective date of all components bundled in the package, in this example, all components are current as of 9 November 2017.

Unlike many httpd distributions, the end user instance configuration, server content and logs and are not modified in this directory tree. See the section on Instance Creation for details of creating a server instance with these user maintained files.

In order to build httpd from scratch, see additional details at the github oss-httpd-build project. A tarball of unix sources and zipfile of windows sources is provided alongside the binary release downloads, for ready reference.

## **Included Components**

The following components are included in this 2.4.29-171109 build; those marked (*) are not compiled on RHEL 7 and Ubuntu 16.04, but the OS Vendor's distribution packages are used, instead:

* Apache HTTP Server 2.4.29

* Apache APR library 1.6.3

* Apache APR-iconv library 1.2.2 (*)

* Apache APR-util library 1.6.1

* brotli compression library 1.0.1

* libexpat 2.2.5 (*)

* libxml2 2.9.7 (*)

* Lua language 5.3.4 (*)

* nghttp2 library 1.27.0

* OpenSSL library 1.1.0g

* PCRE library 8.41 (*)

* Zlib compression library 1.2.11 (*)

## **RHEL 7 Users**

The RHEL 7 package requires several commonly installed packages to be available, these may be provisioned with the following command;

$ yum install libuuid expat libxml2 lua pcre zlib

In order to use the provided apxs utility, additional packages are required as indicated at the [https://github.com/appsuite/oss-httpd-build](https://github.com/appsuite/oss-httpd-build) README page.

## **Ubuntu 16.04 Users**

The Ubuntu 16.04 package requires several commonly installed packages to be available, these may be provisioned with the following command;

$ apt-get -y install libexpat1 lua5.3 libpcre3 libxml2-dev zlib1g

In order to use the provided apxs utility, additional packages are required as indicated at the [https://github.com/appsuite/oss-httpd-build](https://github.com/appsuite/oss-httpd-build) README page.

## **Microsoft Windows Users**

This package is built using Visual C++ 19.11 and C Runtime version 14.11, components of Microsoft Visual Studio 2017. Windows Server 2016 and Windows Server 2012 are suitable for deployment. Windows 10 is suitable for developer evaluation, however Microsoft is known to deliberately hobble various aspects of the Windows Sockets API and process scheduler to deliver a better desktop experience.

Users must obtain and install the "Microsoft Visual C++ Redistributable for Visual Studio 2017", x64 edition; from [https://www.visualstudio.com/downloads/](https://www.visualstudio.com/downloads/) (currently this is the last item in the list) and observe the prerequisites noted for that package. Installing this package from Microsoft ensures that the runtime is updated by the Windows Update service for any new security vulnerabilities of the C Runtime itself.

This package relies upon Windows PowerShell to execute the httpd control scripts on Windows computers. All supported Windows versions have PowerShell installed by default, but specific installations of Windows may not. To check whether your version of Windows has PowerShell installed, go to Start > All Programs > Accessories and check for **Windows PowerShell** in the list.

If Windows PowerShell is not already installed, install it as directed at; 

https://docs.microsoft.com/en-us/powershell/scripting/setup/setup-reference

If necessary, enable Windows PowerShell for script processing; script processing may be disabled by default;

1. Start PowerShell from the Start Menu as an Administrator by opening Start > All Programs > Accessories > Windows PowerShell, then right-clicking on Windows PowerShell and selecting Run as Administrator. A PowerShell window starts.

2. Check the current PowerShell setting by executing the following command:

3. PS prompt> Get-ExecutionPolicy 

4. If the command returns Restricted, it means that PowerShell is not yet enabled. Enable it to allow local script processing at a minimum by executing the following command:

5. PS prompt> Set-ExecutionPolicy RemoteSigned 

6. You can choose a different execution policy for your organization if you want, as well as enable PowerShell using Group and User policies. Typically, only the Administrator will be using the server control scripts, so the RemoteSigned execution policy should be adequate in most cases.

## **Installation**

Create the desired install path, such as /opt/pivotal/webserver or c:\pivotal\webserver, and unpack the tar.bz2 or .zip file into that directory. From this root directory, then invoke the fixrootpath script to correct the embedded paths to the current path, and finally create a symlink when ready to adopt this installation as the "accepted" httpd-2.4 installation path.

During an upgrade, restart each server instance individually and verify the correct operation of that instance's hosts. If there is a problem resulting from an upgrade, simply restore the symlink to the previously installed httpd path, and restart the servers with the old version to avoid unnecessary interruption. When correct operation is verified the older httpd version can be expunged.

Unix users, running as root;

$ mkdir -p /opt/pivotal/webserver$ cd /opt/pivotal/webserver$ tar -xjvf *path-to*/httpd-2.4.29-171109-*{arch}*.tar.bz2$ ln -s httpd-2.4.29-171109 httpd-2.4$ httpd-2.4/bin/fixrootpath.pl httpd-2.4.29-171109

Windows users (running as Administrator);

C:\> mkdir \Pivotal\WebServerC:\> cd \Pivotal\WebServerC:\Pivotal\WebServer> unzip *path-to*\httpd-2.4.29-171109-windows.zipC:\Pivotal\WebServer> mklink /d httpd-2.4 httpd-2.4.29-171109C:\Pivotal\WebServer> powershellPS C:\...\WebServer> httpd-2.4\bin\fixrootpath.ps1 httpd-2.4.29-171109

Windows users should note that extracting the zip file contents from a remote drive using the File Explorer results in untrusted executable files and scripts. Copy the .zip file to a local drive before using the File Explorer extraction tool.

**Instance Creation**

This distribution of Apache HTTP Server is parameterized to allow multiple instances to be created and managed independently, without duplicating the binary files. The instance directory is typically named for a primary server hostname and contains the instance-specific directories conf, htdocs, logs and ssl (for certificates and keys).

Unix users, running as root;

$ cd /opt/pivotal/webserver$ httpd-2.4/bin/newserver.ps1 --server *{host}*$ cd *{host}*$ bin/httpdctl install$ bin/httpdctl start

Windows users (in PowerShell as user Administrator);

PS C:\> cd \Pivotal\WebServerPS C:\Pivotal\WebServer> httpd-2.4\bin\newserver.ps1 --server *{host}*PS C:\Pivotal\WebServer> cd *{host}*PS C:\Pivotal\WebServer\example.com> bin\httpdctl.ps1 installPS C:\Pivotal\WebServer\example.com> bin\httpdctl.ps1 start

Modify the {host}/conf/ files to customize the server behavior. Use the httpdenv script in the bin directory of the instance to have access to the various tools shipped in the httpd-2.4 bin directory;

$ . bin/httpdenv.sh

Or on Windows;

PS C:\Pivotal\WebServer\example.com> bin\httpdenv.ps1

The httpdctl uninstall command will remove the service from automatic startup at boot time.

