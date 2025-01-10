#!/bin/bash
set -xe

ODBC_BRANCH=$1
SERVER_VERSION=$2
WORK_DIR=/hdd/hdd5/jbshi/odbc_auto_test

# 准备测试目录
if [ -d "$WORK_DIR/workdir" ]
then
    rm -rf $WORK_DIR/workdir
fi
mkdir -p $WORK_DIR/workdir/codes $WORK_DIR/workdir/single/web $WORK_DIR/workdir/single/tzdb
# 准备server
if [ -d "$WORK_DIR/../prepare/server/$SERVER_VERSION" ]
then
    cp -Rf $WORK_DIR/../prepare/server/$SERVER_VERSION/* $WORK_DIR/workdir/single
else
    for i in dolphindb libDolphinDB.so libgcc_s.so.1 libgfortran.so.3 libgfortran.so.5 libquadmath.so.0 libstdc++.so.6 libtcmalloc.so.4 libunwind.so.8
    do
        wget "ftp://ftp.dolphindb.cn/origin/release${SERVER_VERSION}/Release/ALL/release2/cmake_release_all/$i" --ftp-user=ftpuser --ftp-password=DolphinDB123 -O $WORK_DIR/workdir/single/$i
    done
    wget "ftp://ftp.dolphindb.cn/origin/release$(echo $SERVER_VERSION | cut -d '.' -f 1,2)/dolphindb.dos" --ftp-user=ftpuser --ftp-password=DolphinDB123 -O $WORK_DIR/workdir/single/dolphindb.dos
fi
cp -Rf $WORK_DIR/../prepare/server/tzdb/* $WORK_DIR/workdir/single/tzdb
cp -Rf $WORK_DIR/../prepare/server/web/* $WORK_DIR/workdir/single/web
cp -Rf $WORK_DIR/../prepare/odbc/config/single/* $WORK_DIR/workdir/single
wget "ftp://ftp.dolphindb.cn/License/internal/dolphindb.lic" --ftp-user=ftpuser --ftp-password=DolphinDB123 -O $WORK_DIR/workdir/single/dolphindb.lic
chmod +x $WORK_DIR/workdir/single/dolphindb
# 启动docker
docker restart odbc_auto_test
# 启动server
docker exec odbc_auto_test bash -c "cd /root/odbc_auto_test/workdir/single && sh ./startSingle.sh"
# 拉取代码
set +x
git clone -b $ODBC_BRANCH https://jianbo.shi%40dolphindb.com:%21s1017539527@dolphindb.net/dolphindb/dolphindb-odbc.git $WORK_DIR/workdir/codes
set -x
# 获取lib
for i in libddbodbc.so libDolphinDBAPI.so
do
    wget "ftp://ftp.dolphindb.cn/origin/$ODBC_BRANCH/Release/dolphindb-odbc/ABI0/1.0.2u/$i" --ftp-user=ftpuser --ftp-password=DolphinDB123 -O $WORK_DIR/workdir/$i
done
# 修改配置
echo -e "[DolphinDB ODBC Driver]\nDescription=DolphinDB ODBC Driver\nDriver=/root/odbc_auto_test/workdir/libddbodbc.so" > $WORK_DIR/workdir/odbcinst.ini
echo -e "[dolphindb]\nDriver=DolphinDB ODBC Driver\nServer=192.168.100.26\nDatabase=dfs://testdb\nPort=35998\nUid=admin\nPwd=123456" > $WORK_DIR/workdir/odbc.ini
docker exec odbc_auto_test bash -c "cp -f /root/odbc_auto_test/workdir/odbc*.ini /root/unixODBC/etc/"
cp -f $WORK_DIR/../prepare/odbc/config/config.cpp $WORK_DIR/workdir/codes/test/config.cpp
# 编译
mkdir -p $WORK_DIR/workdir/codes/build
docker exec odbc_auto_test bash -c "cd /root/odbc_auto_test/workdir/codes/build && cmake .. -DRUN_GTEST=ON -DBUILD_ONLY_GTEST=ON && make -j"
# test
docker exec odbc_auto_test bash -c "cd /root/odbc_auto_test/workdir/codes/build && LD_LIBRARY_PATH=/root/odbc_auto_test/workdir:/root/unixODBC/lib ./BasicTest --gtest_output=xml:output.xml" || true
cp -f $WORK_DIR/workdir/codes/build/output.xml $WORK_DIR/workdir/output.xml
cp -f $WORK_DIR/../prepare/odbc/gtest.xsl $WORK_DIR/workdir/gtest.xsl
cp -f $WORK_DIR/../prepare/odbc/report.py $WORK_DIR/workdir/report.py
cd $WORK_DIR/workdir/ && /hdd/hdd5/jbshi/miniconda3/envs/py312/bin/python3.12 ./report.py
docker stop odbc_auto_test

# docker run -itd --network host --name odbc_auto_test -p 35998:35998 -v /hdd/hdd5/jbshi/odbc_auto_test:/root/odbc_auto_test odbc_auto_test:1.0
