## rpm build variables
##
## 

export SIMON_HOST=10.232.23.15
export CLUSTER=2233 # 2233
export MASTERS="['10.232.23.15','10.232.23.16']"
export SLAVES="['10.232.23.15','10.232.23.16','10.232.23.17']"
export CTS="['10.232.23.17']"

export OB_NAME=ob_trxtest

export PS_MODE=auto
export CS_ROWS=10000000
export UPS_ROWS=5000000
export TEST_THREADS=16
export MAX_SECONDS=36000

export UPDATE_INT=1
export UPDATE_STR=1
export OB_DEFINE="OBI(data_dir='$HOME/$OB_NAME/data',masters=$MASTERS, slaves=$SLAVES, ct=CT('trxtest',simon_host='${SIMON_HOST}', hosts=$CTS,cs_rows=${CS_ROWS}, ups_rows=${UPS_ROWS}, test_threads=${TEST_THREADS}, max_seconds=${MAX_SECONDS},ps_mode='${PS_MODE}', int_update=${UPDATE_INT}, str_update=${UPDATE_STR}))"
export TRXTEST_PATH=${__ScriptPath}/trxtest
# hudson will use below, pay attention to !!!
export LOG_URL=${JOB_URL}/collected_log_${CLUSTER}
export LOG_DIR=$WORKSPACE/collected_log_${CLUSTER}
export SIMON_DIR=$WORKSPACE/simon_chart_${CLUSTER}
