## rpm build variables
##
## 

export CLUSTER=1111 # 2233
export MASTERS="['10.232.36.177']"
export SLAVES="['10.232.36.177']"
export CTS="['10.232.36.177']"

export SYSBENCH_DIR=${__ScriptPath}
#export TESTSET="replace_ps replace insert insert_ps  mix_read  mix_read_ps update update_ps delete delete_ps point_query range_query range_sum_query range_order_query range_distinct_query"
export TESTSET="range_query"
#export TESTSET="point_query"
#export TESTSET="mix_read_ps"
export CS_ROWS=1000
export UPS_ROWS=1000
export TEST_THREADS=8
export MAX_SECONDS=30

export DATA_PATH=$HOME/test.out.$CLUSTER
# hudson will use below, pay attention to !!!
export LOG_URL=$JOB_URL/Benchmark_log_$CLUSTER
export LOG_DIR=$WORKSPACE/collected_log_perf_$CLUSTER
export TABLE_INDEX=${CLUSTER}_index.html
