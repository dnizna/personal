## rpm build variables
##
## 
export OB_NAME=ob_obsql
export OB_DEFINE="OBI(app_name='collect', tpl = dict(schema_template=read('collect.schema')), data_dir='$HOME/$OB_NAME/data', cs_data_path='$HOME/$OB_NAME/data')"
export TXT2HTML_PATH=${__ScriptPath}/txt2html.py
export OBSQL_DIR=/home/admin/oceanbase
export MYSQLTEST_DIR=${OBSQL_DIR}/tools
# hudson will use below, pay attention to !!!
export LOG_URL=$BUILD_URL/collected_log_mysqltest
export LOG_DIR=$WORKSPACE/collected_log_mysqltest
