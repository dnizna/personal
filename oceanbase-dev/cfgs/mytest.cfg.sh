## rpm build variables
##
## 
export OB_NAME=ob1
export MYSQLTEST_DIR=$SRC_DIR/tools/deploy/mysql_test/java
export MYTEST_JAR_URL="http://10.232.4.35:8877/mytest-1.2-SNAPSHOT-jar-with-dependencies.jar"
#export OB_DEFINE="OBI(masters=['10.232.23.15','10.232.23.16'], slaves=['10.232.23.15','10.232.23.16','10.232.23.17'],app_name='collect', tpl = dict(schema_template=read('collect.schema')), data_dir='$HOME/$OB_NAME/data', cs_data_path='$HOME/$OB_NAME/data')"
export OB_DEFINE="OBI(app_name='collect', tpl = dict(schema_template=read('collect.schema')), data_dir='$HOME/$OB_NAME/data', cs_data_path='$HOME/$OB_NAME/data')"

export TXT2HTML_PATH=${__ScriptPath}/txt2html.py

# hudson will use below, pay attention to !!!
export LOG_URL=$BUILD_URL/collected_log_mytest
export LOG_DIR=$WORKSPACE/collected_log_mytest

export EXCLUDE_CASE="type_float ps_1 type_datetime select_error join_null autocommit type_date show revoke trx_3 ps_3 join trx_basic delete_bug206717 set trx_1 rowkey_is_char update trx_2 master_ups_lost_causedby_switch_twice trx_4 deadlock_causedby_ups_switch  trx_5 empty_input"

export EXCLUDE_CASE_PS="type_float ps_1 type_datetime select_error join_null autocommit  union type_date show binary_protocol trx_3 join trx_basic delete_bug206717 many_columns jdbc_trx_with_merge special_hook set  trx_1 build_in_func_test rowkey_is_char update trx_2 master_ups_lost_causedby_switch_twice  trx_4 deadlock_causedby_ups_switch  trx_5 empty_input join_bigid_bug206703"
