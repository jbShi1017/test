#!/bin/bash
set -x

PYTHON_VERSION=$1
SERVER_VERSION=$2
PYTHON_BRANCH=$3
WORK_DIR=/hdd/hdd5/jbshi/py_auto_test

# 准备测试目录
if [ -d "$WORK_DIR/$PYTHON_VERSION" ]
then
    rm -rf $WORK_DIR/$PYTHON_VERSION
fi
mkdir -p $WORK_DIR/$PYTHON_VERSION/codes $WORK_DIR/$PYTHON_VERSION/workdir $WORK_DIR/$PYTHON_VERSION/single/web $WORK_DIR/$PYTHON_VERSION/cluster/web $WORK_DIR/$PYTHON_VERSION/single/tzdb $WORK_DIR/$PYTHON_VERSION/cluster/tzdb
# 准备server
if [ -d "$WORK_DIR/../prepare/server/$SERVER_VERSION" ]
then
    cp -Rf $WORK_DIR/../prepare/server/$SERVER_VERSION/* $WORK_DIR/$PYTHON_VERSION/single
    cp -Rf $WORK_DIR/../prepare/server/$SERVER_VERSION/* $WORK_DIR/$PYTHON_VERSION/cluster
else
    for i in dolphindb libDolphinDB.so libgcc_s.so.1 libgfortran.so.3 libgfortran.so.5 libquadmath.so.0 libstdc++.so.6 libtcmalloc.so.4 libunwind.so.8
    do
        wget "ftp://ftp.dolphindb.cn/origin/release${SERVER_VERSION}/Release/ALL/release2/cmake_release_all/$i" --ftp-user=ftpuser --ftp-password=DolphinDB123 -O $WORK_DIR/$PYTHON_VERSION/single/$i
        cp -f $WORK_DIR/$PYTHON_VERSION/single/$i $WORK_DIR/$PYTHON_VERSION/cluster/$i
    done
    wget "ftp://ftp.dolphindb.cn/origin/release$(echo $SERVER_VERSION | cut -d '.' -f 1,2)/dolphindb.dos" --ftp-user=ftpuser --ftp-password=DolphinDB123 -O $WORK_DIR/$PYTHON_VERSION/single/dolphindb.dos
    cp -f $WORK_DIR/$PYTHON_VERSION/single/dolphindb.dos $WORK_DIR/$PYTHON_VERSION/cluster/dolphindb.dos
fi
cp -Rf $WORK_DIR/../prepare/server/web/* $WORK_DIR/$PYTHON_VERSION/single/web
cp -Rf $WORK_DIR/../prepare/server/web/* $WORK_DIR/$PYTHON_VERSION/cluster/web
cp -Rf $WORK_DIR/../prepare/py/config/single_$PYTHON_VERSION/* $WORK_DIR/$PYTHON_VERSION/single
cp -Rf $WORK_DIR/../prepare/py/config/cluster_$PYTHON_VERSION/* $WORK_DIR/$PYTHON_VERSION/cluster
wget "ftp://ftp.dolphindb.cn/License/internal/dolphindb.lic" --ftp-user=ftpuser --ftp-password=DolphinDB123 -O $WORK_DIR/$PYTHON_VERSION/single/dolphindb.lic
cp -f $WORK_DIR/$PYTHON_VERSION/single/dolphindb.lic $WORK_DIR/$PYTHON_VERSION/cluster/dolphindb.lic
chmod +x $WORK_DIR/$PYTHON_VERSION/single/dolphindb
chmod +x $WORK_DIR/$PYTHON_VERSION/cluster/dolphindb
# 启动docker
docker restart py_auto_test_$PYTHON_VERSION
# 启动server
docker exec py_auto_test_$PYTHON_VERSION bash -c "cd /root/py_auto_test/$PYTHON_VERSION/single && sh ./startSingle.sh"
docker exec py_auto_test_$PYTHON_VERSION bash -c "cd /root/py_auto_test/$PYTHON_VERSION/cluster/clusterDemo && sh ./startController.sh && sh ./startAgent.sh"
# 拉取代码
git clone -b $PYTHON_BRANCH https://jianbo.shi%40dolphindb.com:%21s1017539527@dolphindb.net/dolphindb/python-sdk.git $WORK_DIR/$PYTHON_VERSION/codes
# 安装依赖
docker exec py_auto_test_$PYTHON_VERSION bash -c "python$PYTHON_VERSION -m pip install -r /root/py_auto_test/$PYTHON_VERSION/codes/test/requirements.txt"
if [ -d "$WORK_DIR/../prepare/py/whl/$PYTHON_BRANCH" ]
then
    docker exec py_auto_test_$PYTHON_VERSION bash -c "python$PYTHON_VERSION -m pip uninstall dolphindb -y && python$PYTHON_VERSION -m pip install /root/py_auto_test/../prepare/py_$PYTHON_BRANCH/dolphindb-*cp${PYTHON_VERSION//./}*.whl"
else
    # 编译
    cd $WORK_DIR/$PYTHON_VERSION/codes
    CIBW_BUILD=cp${PYTHON_VERSION//./}* /hdd/hdd5/jbshi/miniconda3/envs/py312/bin/python -m cibuildwheel --platform linux
    docker exec py_auto_test_$PYTHON_VERSION bash -c "python$PYTHON_VERSION -m pip uninstall dolphindb -y && python$PYTHON_VERSION -m pip install /root/py_auto_test/$PYTHON_VERSION/codes/wheelhouse/dolphindb-*cp${PYTHON_VERSION//./}*.whl"
fi
# 更新配置
cp -f $WORK_DIR/../prepare/py/config/settings_$PYTHON_VERSION.py $WORK_DIR/$PYTHON_VERSION/codes/test/setup/settings.py
docker exec py_auto_test_$PYTHON_VERSION bash -c "cd /root/py_auto_test/$PYTHON_VERSION/codes/test && python$PYTHON_VERSION -m pytest"
docker stop py_auto_test_$PYTHON_VERSION

# docker run -itd --network host --name py_auto_test_3.6 -p 35800:35800 -p 35700:35700 -p 35701:35701 -p 35702:35702 -p 35703:35703 -p 35704:35704 -p 35705:35705 -v /hdd/hdd5/jbshi/py_auto_test:/root/py_auto_test py_auto_test:1.0
# docker run -itd --network host --name py_auto_test_3.7 -p 35801:35801 -p 35710:35710 -p 35711:35711 -p 35712:35712 -p 35713:35713 -p 35714:35714 -p 35715:35715 -v /hdd/hdd5/jbshi/py_auto_test:/root/py_auto_test py_auto_test:1.0
# docker run -itd --network host --name py_auto_test_3.8 -p 35802:35802 -p 35720:35720 -p 35721:35721 -p 35722:35722 -p 35723:35723 -p 35724:35724 -p 35725:35725 -v /hdd/hdd5/jbshi/py_auto_test:/root/py_auto_test py_auto_test:1.0
# docker run -itd --network host --name py_auto_test_3.9 -p 35803:35803 -p 35730:35730 -p 35731:35731 -p 35732:35732 -p 35733:35733 -p 35734:35734 -p 35735:35735 -v /hdd/hdd5/jbshi/py_auto_test:/root/py_auto_test py_auto_test:1.0
# docker run -itd --network host --name py_auto_test_3.10 -p 35804:35804 -p 35740:35740 -p 35741:35741 -p 35742:35742 -p 35743:35743 -p 35744:35744 -p 35745:35745 -v /hdd/hdd5/jbshi/py_auto_test:/root/py_auto_test py_auto_test:1.0
# docker run -itd --network host --name py_auto_test_3.11 -p 35805:35805 -p 35750:35750 -p 35751:35751 -p 35752:35752 -p 35753:35753 -p 35754:35754 -p 35755:35755 -v /hdd/hdd5/jbshi/py_auto_test:/root/py_auto_test py_auto_test:1.0
# docker run -itd --network host --name py_auto_test_3.12 -p 35806:35806 -p 35760:35760 -p 35761:35761 -p 35762:35762 -p 35763:35763 -p 35764:35764 -p 35765:35765 -v /hdd/hdd5/jbshi/py_auto_test:/root/py_auto_test py_auto_test:1.0
# docker stop py_auto_test_3.6 py_auto_test_3.7 py_auto_test_3.8 py_auto_test_3.9 py_auto_test_3.10 py_auto_test_3.11  py_auto_test_3.12
