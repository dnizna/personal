## rpm build variables
##
## 

export OB_NAME=quick_ob
export C_MYSQLTEST_DIR=${__ScriptPath}
export JAVA_MYSQLTEST_DIR=${SRC_DIR}/tools/deploy/mysql_test/java
export MYTEST_JAR_URL="http://10.232.4.35:8877/mytest-1.1-SNAPSHOT-jar-with-dependencies.jar"
export OB_DEFINE="OBI(tpl=tpl,ms_port=26001,cs_port=26002,ups_port=26003,mysql_port=26004,rs_port=26005,ups_inner_port=26006,data_dir='$HOME/${OB_NAME}/data')"
export CASE_FOF_MYTEST="create"
