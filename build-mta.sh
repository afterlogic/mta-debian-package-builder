#!/bin/bash
rm -rf ./tmp
mkdir -p ./out
mkdir -p ./tmp/data/opt/afterlogic/html
mkdir -p ./tmp/data/opt/afterlogic/setup
mkdir -p ./tmp/data/opt/afterlogic/templates
mkdir -p ./tmp/data/usr/share
mkdir -p ./tmp/data/usr/share/doc/$PRODNAME
mkdir -p ./tmp/data/etc/$PRODNAME

cp -r ./mta/setup/* ./tmp/data/opt/afterlogic/setup
cp -r ./mta/templates/* ./tmp/data/opt/afterlogic/templates

rm -f ./$PRODFILE
wget https://afterlogic.com/download/$PRODFILE
unzip -qq ./$PRODFILE -d ./tmp/data/opt/afterlogic/html

mkdir ./tmp/control

INST_SIZE=`du -sk ./tmp/data/opt/afterlogic/html | awk '{print $1}'`
cp -f ./mta/$CTRLFILE ./tmp/control/control
sed -i "s/%S%/$INST_SIZE/g" ./tmp/control/control
VERNUM=`cat ./tmp/data/opt/afterlogic/html/VERSION`
VERNUM=`echo $VERNUM | cut -d'-' -f1`
sed -i "s/%V%/$VERNUM/g" ./tmp/control/control
sed -i "s/%P%/$PRODNAME/g" ./tmp/control/control

cp -f ./mta/changelog ./tmp/control/changelog
sed -i "s/%V%/$VERNUM/g" ./tmp/control/changelog
sed -i "s/%P%/$PRODNAME/g" ./tmp/control/changelog
sed -i "s/%S%/stable/g" ./tmp/control/changelog

find ./tmp/data/opt/afterlogic/html/ -type f -exec md5sum "{}" + > ./tmp/control/md5sums
sed -i "s/.\/tmp\/data//g" ./tmp/control/md5sums

cp ./mta/conffiles ./tmp/control/conffiles

cp ./mta/copyright ./tmp/data/usr/share/doc/$PRODNAME/copyright
cp ./tmp/control/changelog ./tmp/data/usr/share/doc/$PRODNAME/changelog
gzip ./tmp/data/usr/share/doc/$PRODNAME/changelog

cp ./mta/postinst ./tmp/control/postinst
chown 0755 ./tmp/control/postinst
cp ./mta/preinst ./tmp/control/preinst
chown 0755 ./tmp/control/preinst
cp ./mta/postrm ./tmp/control/postrm
chown 0755 ./tmp/control/postrm
cp ./mta/prerm ./tmp/control/prerm
chown 0755 ./tmp/control/prerm

cd ./tmp/data
tar czf ../data.tar.gz [a-z]*
cd ../control
tar czf ../control.tar.gz *

cd ..
echo 2.0 > debian-binary
ar r ../out/`echo $PRODNAME`_stable_`echo $VERNUM`_all.deb debian-binary control.tar.gz data.tar.gz
rm -f ../web/`echo $PRODNAME`.deb
cp ../out/`echo $PRODNAME`_stable_`echo $VERNUM`_all.deb ../web/`echo $PRODNAME`.deb
