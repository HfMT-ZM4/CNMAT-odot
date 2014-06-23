#!/bin/sh

packagedirs=(clippings code default-definitions default-settings docs examples extensions externals extras help init interfaces java-classes java-doc javascript jsextensions jsui license.txt media misc patchers object-prototypes queries readme.txt source support templates)

git diff --exit-code > /dev/null
if [ $? -ne 0 ]; then
	echo "Your working directory contains uncommitted changes. Please commit them before making a release."
	exit 1;
fi

git diff --cached --exit-code > /dev/null
if [ $? -ne 0 ]; then
	echo "Your working directory contains modified files that have been staged for commit. Please commit them before making a release."
	exit 1;
fi

platform=`uname`
if [ $platform = "Darwin" ]; then
	platform="MacOSX"
fi

maxstagingdir=odot-Max-$platform
pdstagingdir=pd_release_package

#don't need to make a PD staging dir as it's already checked in and part of the repo
[ -d $maxstagingdir ] || mkdir -p $maxstagingdir

for f in ${packagedirs[*]}
do
	[ -e $f ] && cp -r $f $maxstagingdir
done

maxtarballname=odot-Max-$platform-`git describe --tags --long`-`git branch | egrep '^\*' | awk '{print $2}'`.tgz
pdtarballname=odot-PD-$platform-`git describe --tags --long`-`git branch | egrep '^\*' | awk '{print $2}'`.tgz

tar zcvf $maxtarballname $maxstagingdir
tar zcvf $pdtarballname $pdstagingdir
rm -rf $maxstagingdir