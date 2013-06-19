## $Id: example.cfg.sh,v 1.2 2009/10/01 15:47:19 wschlich Exp wschlich $
## vim:ts=4:sw=4:tw=200:nu:ai:nowrap:

##
## application settings
##

export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64
export ThirdLibs=/usr
export TBLIB_ROOT=/opt/csr/common/
export EASY_ROOT=/usr
export EASY_LIB_PATH=/usr/lib64 

export LD_LIBRARY_PATH=$TBLIB_ROOT/lib:${ThirdLibs}/lib:${ThirdLibs}/lib64:/usr/lib64/mysql:$LD_LIBRARY_PATH
# src directory
if [ "z" = "z$WORKSPACE" ];then
    export WORKSPACE=/home/admin/dev
fi
export SRC_DIR=${WORKSPACE}/oceanbase
