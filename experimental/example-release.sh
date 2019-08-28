# Example of invoking the oss-httpd-build schema to generate a release
#
# Invoke this from the parent of the oss-httpd-build directory
#

# Gather the sources into oss-httpd-build/

buildtype=release

if test ! -d oss-httpd-build ; then
    git clone https://github.com/appsuite/oss-httpd-build
else
    git pull oss-httpd-build
fi

cd oss-httpd-build/src

make -f ../mak/Makefile.gather GRP=complete BLD=$buildtype
make -f ../mak/Makefile.preconfig
cd ../..
manifest=oss-httpd-build/src/$buildtype-manifest-vars
cp $manifest ./complete-manifest-vars

datestamp=`date +%y%m%d`
lineends=oss-httpd-build/src/`awk -F = '/apr_srcdir=/{print $2}'<$manifest`/build/lineends.pl
package=`awk -F = '/httpd_srcdir=/{print $2}'<$manifest`-$datestamp-oss-httpd-build

echo "Clone the sources for a .zip (crlf) download"
mkdir win
cp -prf oss-httpd-build win/oss-httpd-build
cd win
echo "... cleaning git/svn artifacts"
find oss-httpd-build -name .git -a -type d | xargs rm -rf
find oss-httpd-build -name .git -a -type d | xargs rm -rf
perl $lineends --cr oss-httpd-build
echo "... compressing source zipfile"
zip -r -q -9 -X ../$package.zip oss-httpd-build
echo "Created $package.zip"
cd ..

# Rewrite the manifest for simplified linux builds

cd oss-httpd-build/src
mv $buildtype-manifest-vars complete-manifest-vars
# TODO: strip excess packages from the linux list
make -f ../mak/Makefile.gather GRP=complete BLD=$buildtype
make -f ../mak/Makefile.preconfig
cd ../..

echo "Clone the sources for a .tar.bz2 (lf) download"
mkdir unix
cp -prf oss-httpd-build unix/oss-httpd-build
cd unix
echo "... cleaning git/svn artifacts"
find oss-httpd-build -name .git -a -type d | xargs rm -rf
find oss-httpd-build -name .git -a -type d | xargs rm -rf
echo "... compressing source tarball"
tar -cjf ../$package.tar.bz2 oss-httpd-build
echo "Created $package.tar.bz2"
cd ..


