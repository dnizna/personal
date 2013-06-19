## rpm build variables
##
## 

export CLUSTER=2233 # 2233
export MASTERS="['10.209.144.37','10.209.144.38']"
#export SLAVES="['10.232.36.181','10.232.36.182','10.232.36.183']"
export CTS="['10.209.144.39','10.209.144.38','10.209.144.37']"
export SLAVES="['10.209.144.39','10.209.144.38','10.209.144.37']"

export CLUSTER=1111 # 2233
export MASTERS="['10.209.144.37','10.209.144.38']"
#export SLAVES="['10.232.36.181','10.232.36.182','10.232.36.183']"
export CTS="['10.209.144.39','10.209.144.38']"
export SLAVES="['10.209.144.37','10.209.144.38']"

export OB_NAME=ob_histest
export PS_MODE=auto
export CS_ROWS=10000
export UPS_ROWS=10000
export TEST_THREADS=32
export MAX_SECONDS=720000
export FREEZE_SECONDS=900
export FREEZE_REPEAT=10000
export SIMON_HOST=10.232.4.35
export OB_DEFINE="OBI(data_dir='/data',clog_dir='/data/log1',masters=$MASTERS, slaves=$SLAVES, ct=CT('histest', hosts=$CTS,cs_rows=${CS_ROWS}, ups_rows=${UPS_ROWS}, test_threads=${TEST_THREADS}, max_seconds=${MAX_SECONDS}, freeze_seconds=${FREEZE_SECONDS}, freeze_repeat=${FREEZE_REPEAT},ps_mode='${PS_MODE}', simon_host='${SIMON_HOST}'), dev='bond0.212')"

export SYSBENCH_PATH=${__ScriptPath}/sysbench

# hudson will use below, pay attention to !!!
export LOG_URL=${JOB_URL}/collected_log_${CLUSTER}
export LOG_DIR=$WORKSPACE/collected_log_${CLUSTER}
export SIMON_DIR=$WORKSPACE/simon_chart_${CLUSTER}
