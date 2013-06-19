## rpm build variables
##
## 
export OB_NAME=ob1
export MYSQLTEST_DIR=${__ScriptPath}
export OB_DEFINE="OBI(app_name='collect', tpl = dict(schema_template=read('collect.schema')), data_dir='$HOME/$OB_NAME/data', cs_data_path='$HOME/$OB_NAME/data')"
export TXT2HTML_PATH=${__ScriptPath}/txt2html.py

# hudson will use below, pay attention to !!!
export LOG_URL=$BUILD_URL/collected_log_mysqltest
export LOG_DIR=$WORKSPACE/collected_log_mysqltest

export EXCLUDE_CASE="affect_rows join_null ps_affect_rows desc rowkey_is_char update master_ups_lost_causedby_switch_twice deadlock_causedby_ups_switch jdbc_parallel_trx jdbc_trx_with_merge  jdbc_autocommit  jdbc_ps_complex"
export EXCLUDE_CASE_PS="affect_rows type_datetime select_error join_null ps_affect_rows union type_date binary_protocol join special_hook set build_in_func_test desc rowkey_is_char update master_ups_lost_causedby_switch_twice deadlock_causedby_ups_switch jdbc_parallel_trx jdbc_trx_with_merge  jdbc_autocommit  jdbc_ps_complex"
