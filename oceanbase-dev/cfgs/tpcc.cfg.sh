## rpm build variables
##
## 

export SIMON_HOST=10.232.23.15
export CLUSTER=2233 # 2233
export MASTERS="['10.232.23.15','10.232.23.16']"
export SLAVES="['10.232.23.15','10.232.23.16','10.232.23.17']"
export CTS="['10.232.23.15','10.232.23.16','10.232.23.17']"

export OB_NAME=ob_tpcc
export MAX_SECONDS=36000
export OB_DEFINE="OBI(data_dir='/home/admin/ob_tpcc/data',masters=$MASTERS, slaves=$SLAVES,ct=CT('tpcc',simon_host='10.232.23.15',hosts=$CTS , warmup_time=300, running_time=$MAX_SECONDS,warehouse=1))"
export TPCCLOAD_PATH=${__ScriptPath}/tpcc_load
export TPCCSTART_PATH=${__ScriptPath}/tpcc_start

# hudson will use below, pay attention to !!!
export LOG_URL=${JOB_URL}/collected_log_${CLUSTER}
export LOG_DIR=$WORKSPACE/collected_log_${CLUSTER}
export SIMON_DIR=$WORKSPACE/simon_chart_${CLUSTER}
