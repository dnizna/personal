## $Id: oceanbase.lib.sh,v 1.0 2013/02/03 10:58 wschlich Exp wschlich $
## vim:ts=4:sw=4:tw=200:nu:ai:nowrap:

##
## REQUIRED PROGRAMS
## =================
## - rm
## - mkdir
## - ls
## - cp
## - mv

##
## application initialization function
## (command line argument parsing and validation etc.)
##

function __init() {

	## -- BEGIN YOUR OWN APPLICATION INITIALIZATION CODE HERE --

    if ! checkEnv;then
        __msg err "check env failed"
		return 2
	fi
	## parse command line options
	while getopts 't:qh' opt; do
		case "${opt}" in
			## option a
			h)
			    __msg info "Usage: ./oceanbase.sh -t build|rpm|quicktest|mysqltest|mytest|trxtest|histest|perf"
			    __msg info "quit"
				return 2
			    ;;
			t)
				TestName="${OPTARG}"
				;;
			## quiet operation
			q)
				declare -i __MsgQuiet=1
				;;
			## option without a required argument
			:)
				__die 2 "option -${OPTARG} requires an argument" # TODO FIXME: switch to __msg err
				;;
			## unknown option
			\?)
				__die 2 "unknown option -${OPTARG}" # TODO FIXME: switch to __msg err
				;;
			## this should never happen
			*)
				__die 2 "there's an error in the matrix!" # TODO FIXME: switch to __msg err
				;;
		esac
		__msg debug "command line argument: -${opt}${OPTARG:+ '${OPTARG}'}"
	done
	## check if command line options were given at all
	if [[ ${OPTIND} == 1 ]]; then
		__die 2 "no command line option specified" # TODO FIXME: switch to __msg err
	fi
	## shift off options + arguments
	let OPTIND--; shift ${OPTIND}; unset OPTIND
	args="${@}"
	set --

	if ! source ${__ScriptPath}/cfgs/${TestName}.cfg.sh;then
		__msg err "execute source ${TestName}.cfg.sh failed!!!" # TODO FIXME: switch to __msg err
        return 1;
	fi
    __msg notice "test ${TestName} init ok"

	return 0 # succeed

	## -- END YOUR OWN APPLICATION INITIALIZATION CODE HERE --

}

##
## application main function
##

function __main() {

	## -- BEGIN YOUR OWN APPLICATION MAIN CODE HERE --

	#for i in debug info notice warning err crit alert emerg; do


	#exampleFunction "${ApplicationVariable1}" "${ApplicationVariable2}"

	#fooFunction fooArgs

    ## OceanBase
    local  runtest=NoSuchMethod
	case "${TestName}" in
	    obsqltest)
		     runtest=obsqlTest
			 ;;
	    cppcheck)
		     runtest=cppCheck
			 ;;
	    build)
		     runtest=buildTest
		     ;;
	    rpm)
		     runtest=rpmTest
		     ;;
	    quicktest)
		     runtest=quickTest
			 ;;
	    mysqltest)
		     runtest=mysqlTest
			 ;;
	    mytest)
		     runtest=myTest
			 ;;
	    perf)
		     runtest=perfTest
			 ;;
	    tpcc)
		     runtest=tpccTest
			 ;;
	    trxtest)
		     runtest=trxTest
			 ;;
	    histest)
		     runtest=hisTest
			 ;;
	    *)
		     __msg info "invalid test name"
    esac
    if ! ${runtest} ;then
         __msg err "execute ${runtest} failed"
	     return 1
	else
	     __msg notice "execute ${runtest} succeed"
	fi
    
	return 0 # succeed

	## -- END YOUR OWN APPLICATION MAIN CODE HERE --

}
##
## build oceanbase
##
function buildTest() {
	cd $SRC_DIR
	make distclean
	./build.sh init || return 2
	./build.sh || return 2
	./configure ${ConfigureArguments} CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" || return 2
	cd $SRC_DIR/src
	make -j 10 || return 2
	cd $SRC_DIR/tools
	make -j 10 || return 2
	cd $SRC_DIR/tools/newsqltest
	make -j 10 || return 2
	cd $SRC_DIR/tools/io_fault
	make iof || return 2
	return 0
}

function rpmTest() {
	
	cd $SRC_DIR
	make distclean
	./build.sh init || return 2
	./build.sh || return 2
	./configure ${ConfigureArguments} CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" || return 2
	make -j 10 -C src/ && make -j 10 -C tools/ || return 2
	#make -j 10 -C tests || return 2
	#&& make -j 10 -C tests/sql && make -j 10 -C tests/sstable && make -j 10 -C tests/obmysql && make -j 10 -C tests/compactsstable || return 2
	make -j 10 -C tools/newsqltest && make -j 10  -C tools/io_fault || return 2
	
	cd $SRC_DIR/rpm
	bash oceanbase-build.sh || return 2
	# will remove later
	__msg info "upload to http://10.232.4.35:8877"
	scp *.rpm admin@10.232.4.35:~/oceanbase/share/
	return 0
}
##
## Create a new config2.py
##
function createTestConfigPY() {
    
	__msg info "create config2.py"
	local ipAddr=$(getLocalIP)

    __msg info "localhost IP:$ipAddr"\
	
	local configPath=${SRC_DIR}/tools/deploy/config2.py
    cp -fr ${SRC_DIR}/tools/deploy/config.py $configPath

	echo "ObCfg.default_hosts='$ipAddr'.split()" >> ${configPath}
	__msg info "`tail -1 ${SRC_DIR}/tools/deploy/config2.py`"
    echo "${OB_NAME}=${OB_DEFINE}" >> ${configPath}
	__msg info "`tail -1 ${SRC_DIR}/tools/deploy/config2.py`"
    
}

##
## Create config2.py for perf test
##
function createPerfConfigPY() {
	__msg info "create config2.py"
	
	local configPath=${SRC_DIR}/tools/deploy/config2.py
    cp -fr ${SRC_DIR}/tools/deploy/config.py $configPath

    for t in ${TESTSET}
	do
	    local ps=disable
        local at=$t # scene name
		local obName=ob_${t}
		echo $t | grep "_ps$" > /dev/null;
		if [ $? -eq 0 ];then
		    ps=auto
            at=`echo $t | sed "s#_ps##g"`
		fi
		__msg info "test=$t ps=>$ps scene=$at ob=$obName"
		local obDefine=None
        if [ $at = "insert" ]  || [ $at = "delete" ] || [ $at = "update" ] || [ $at = "replace" ];then
		    obDefine="OBI(data_dir='$HOME/$obName/data',masters=$MASTERS, slaves=$SLAVES, ct=CT('benchmark', hosts=$CTS,test_mode='${at}',cs_rows=${CS_ROWS},ups_rows=${UPS_ROWS},test_threads=${TEST_THREADS}, max_seconds=${MAX_SECONDS}, ps_mode='${ps}', simon_host='10.232.23.15'))"
		elif [ $at = "mix_read" ];then
            obDefine="OBI(data_dir='$HOME/$obName/data',masters=$MASTERS, slaves=$SLAVES, ct=CT('benchmark', hosts=$CTS, test_mode='read', point_query=10 ,range_query=10 ,range_sum_query=10,range_order_query=10 ,range_distinct_query=10 ,point_join_query=1 ,range_join_query=1 ,range_sum_join_query=1 ,range_order_join_query=1 ,range_distinct_join_query=1,  cs_rows=${CS_ROWS},ups_rows=${UPS_ROWS}, test_threads=${TEST_THREADS}, max_seconds=${MAX_SECONDS}, ps_mode='${ps}', simon_host='10.232.23.15'))"
		else
     		obDefine="OBI(data_dir='$HOME/$obName/data',masters=$MASTERS, slaves=$SLAVES, ct=CT('benchmark', hosts=$CTS, test_mode='read', ${at}=1, cs_rows=${CS_ROWS}, ups_rows=${UPS_ROWS},test_threads=${TEST_THREADS}, max_seconds=${MAX_SECONDS}, ps_mode='${ps}', simon_host='10.232.23.15'))"
		fi

        echo "${obName}=${obDefine}" >> ${configPath}
	    __msg info "`tail -1 ${configPath}`"
	done
}



##
## Reboot ob until succeed
##
function rebootOB() {
	cd $SRC_DIR/tools/deploy
	
    local obName=${1}
	local -i reboot=0

	while [ $reboot -lt 3 ]
	do
	    __msg info "reboot $obName"
		local -i ret=`./deploy.py ${obName}.reboot| tail -1 | sed "s#.*, ##g" | sed "s#).*##g"`
        [ -z $ret ] && ret=2
        if [ $ret -ne 0 ] ;then
            let 'reboot=reboot+1'
	        __msg warning "reboot ${obName} failed, errno is $ret, retry ${reboot}"
	    else 
		    __msg notice "reboot ${obName} succeed"
			return 0
        fi
    done
	__msg err "reboot $obName failed after $reboot reties"
    return 2
}

##
## Check mysqltest
##
function checkMysqltest() {
    if ! which mysqltest;then
        return 2
	fi
	return 0
}

function quickTest() {
	
	cd $SRC_DIR/tools/deploy 

    createTestConfigPY
    updateLocalBin
    
    if ! rebootOB $OB_NAME;then
	    __msg err "reboot $OB_NAME failed"
		return 2
	fi
     
	__msg info "run quick test after 5 seconds"
	sleep 5
	__msg info "start run c mysqltest"

	export PATH=$C_MYSQLTEST_DIR:$PATH
	if ! checkMysqltest;then
        __msg err "failed to find mysqltest, try 'which mysqltest'!!!"
		return 2
	fi
	./deploy.py ${OB_NAME}.mysqltest quick  | tee ./quicktest.log

    __msg info "check result"
    if grep FAILED ./quicktest.log;then
	   __msg err "some cases failed"
       ./deploy.py $OB_NAME.force_stop
       return 2
    fi
    
    __msg info "start to download mytest-1.1-SNAPSHOT-jar-with-dependencies.jar"
	if ! downloadMytest;then
        __msg err "failed to download mytest-1.1-SNAPSHOT-jar-with-dependencies.jar !!!"
		return 2
	fi
    __msg info "start run mytest(java)"
    export PATH=$JAVA_MYSQLTEST_DIR:$PATH
	if ! checkMysqltest;then
        __msg err "failed to find mysqltest, try 'which mysqltest'!!!"
		return 2
	fi
    ./deploy.py ${OB_NAME}.mysqltest testset=${CASE_FOF_MYTEST} | tee ./jdbctest.log
    __msg info "check result"
    if grep FAILED ./jdbctest.log;then
	   __msg err "some cases failed"
       ./deploy.py $OB_NAME.force_stop
       return 2
    fi
	__msg info "stop ob"
    ./deploy.py $OB_NAME.force_stop
	__msg info "quicktest succeed"
	return 0
}

function updateLocalBin() {
   __msg info "copy binaries from $SRC_DIR to deploy"
   ./copy.sh $SRC_DIR > /dev/null 2>&1
}

##
## mysql test
##
function killall() {

    for p in chunkserver mergeserver updateserver rootserver
    do
        pkill -9 -f $p
    done
}
function mysqlTest() {

	cd $SRC_DIR/tools/deploy 
      
	function prepare() {
        
        killall

	    createTestConfigPY
		updateLocalBin
	
	    export PATH=$MYSQLTEST_DIR:$PATH
        if ! checkMysqltest;then
            __msg err "failed to find mysqltest from PATH=$PATH"
		    return 2
	    fi
		return 0
	}

	function run() {
	   __msg info "remove old collected_log if exist"
	   rm -fr collected_log
       if [ ! -d ~/data ] ;then
            __msg warning "failed to find $HOME/data"
		    __msg warning "$OB_NAME will start without cs data"
	   fi
	   __msg info "start mysqltest"
	   ./deploy.py ${OB_NAME}.mysqltest with-cs-data ${MYSQLTEST_ARGUMENT} | tee ./mytestlog
	   #./deploy.py ${OB_NAME}.mysqltest testset=create,zhuweng_thinking | tee ./mytestlog
	   __msg info "mysqltest finish"
    }

	function generateLog() {
	    #__msg info "generate ob log report"
	    if [ ! -d ./collected_log ];then
            __msg err "failed to collect log"
			return 2
	    fi
        #__msg info "clean old ${LOG_DIR} if exist"
	    rm -fr ${LOG_DIR}
        #__msg info "move collected_log to ${LOG_DIR}"
        cp -r mysql_test/var/log collected_log/${BUILD_NUMBER}_mysqltest_result_log
        cp -r collected_log $LOG_DIR
        prepareMyTestLog ${LOG_DIR} ${LOG_URL} # index.html generated to see files within directory
	    mv ./mytestlog $LOG_DIR  # put mytestlog to it too, need further process by a py script
        $TXT2HTML_PATH $LOG_DIR/mytestlog # mytestlog.html will generated
	}

    prepare || return 2
    run
	generateLog || return 2

    #__msg info "stop ob"
    ./deploy.py ${OB_NAME}.force_stop > /dev/null 2>&1

	#__msg info "check fail case"
	if [[ $JOB_NAME = *_ps ]];then
		IGNOR_LIST=${EXCLUDE_CASE_PS}
	else
		IGNOR_LIST=${EXCLUDE_CASE}
	fi
    newFail=
	failList=`grep "FAIL LST" $LOG_DIR/mytestlog.html | awk -F'</font>' '{print $2}'`
    
	__msg info "fail  list =>  $failList "
	__msg info "ignor list =>  $IGNOR_LIST "
	for s in `echo $failList | sed "s#,# #g"`
	do
          echo $IGNOR_LIST | grep -w $s > /dev/null
		  if [ $? -ne 0 ];then
			 # __msg err "new fail case"
		     newFail="${newFail} $s"	 
		  fi
	done
	if [ -z "$newFail" ] ;then
        __msg  info "no new fail"
    else
        __msg err "new Fail List:  $newFail"
		return 2
	fi
	return 0
}

##
## mytest log process
##
function prepareMyTestLog() {

    local logDir=${1}
	local href=${2} # maybe buildno is required

    > index.html
    
	for testDir in `ls $logDir`
    do  
        #sed -i "s#\$#<br>#g" $logDir/$testDir/*
	    for log in `ls $logDir/$testDir`
	    do  
		    local logPath=$logDir/${testDir}/${log}
		    mv $logPath $logPath.log
			echo "<a href=${href}/${testDir}/${log}.log> $testDir/$log </a>" >> index.html
            echo "<br>"  >> index.html
		done
        echo "<br><br>"  >> index.html
    done
	mv index.html $logDir
}
function obsqlTest() {

    cd $SRC_DIR/tools/deploy 
	export LD_PRELOAD=$OBSQL_DIR/lib/libobsql.so.0.0.0
   	export LD_LIBRARY_PATH=/home/xiaojun.chengxj/mysql-5.5.27/libmysql:/usr/local/lib:$LD_LIBRARY_PATH
	source $OBSQL_DIR/etc/libobsqlrc
	
	if ! mysqlTest;then
        return 2
	fi
	return 0
}

function myTest() {

    cd $SRC_DIR/tools/deploy 
    __msg info "start to download mytest"
    if ! downloadMytest;then
            __msg err "failed to download mytest !!!"
	    return 2
	    fi
	if ! mysqlTest;then
        return 2
	fi
	return 0
}



function perfTest() {

	cd $SRC_DIR/tools/deploy 
    
	function clear() {
	    # clear
	    __msg info "clear $LOG_DIR"
        rm -fr $LOG_DIR
        __msg info "backup old collected_log"
        rm -fr collected_log.bk
        [ -d collected_log ] && mv collected_log collected_log.bk
    }
	function prepare() {
	    
		__msg info "backup $DATA_PATH"
        cp -r $DATA_PATH $DATA_PATH.bk
		
		updateLocalBin
        
		__msg info "copy sysbench and ups_admin to benchmark dir"
	    
		cp tools/ups_admin benchmark
	    cp ${SYSBENCH_DIR}/sysbench benchmark
        
		__msg info "copy depend libs to lib tool"
	    cp -rf ${ThirdLibs}/lib/* lib/
        
		createPerfConfigPY
    }
    function run() {
        for t in ${TESTSET}
		do
		    local obName=ob_${t}
			
            if ! rebootOB $obName;then
	            __msg err "reboot $obName failed"
		        return 2
	        fi
            
            ./deploy.py $obName.obmysql extra="< benchmark/sbtest.sql "
			#openTraceLog $obName
			runCT $obName "sysbench"
	        
			__msg info "stop $obName"
	        ./deploy.py ${obName}.stop
		    ./deploy.py ${obName}.force_stop

		    __msg info "collect log"
		    ./deploy.py $obName.collect_log
	   	    __msg info "show result"
			cat collected_log/${obName}.*/benchmark_*.log | tail -30
		    
			__msg info "wait 60 seconds"
		    sleep 60

		done
          
	}
	function collect_data() {

        >  ${TABLE_INDEX}

	    echo "<table>" >> ${TABLE_INDEX}
	    echo "<tr><td>test</td><td>ps</td><td>TPS</td><td>AVG</td><td>95%</td></tr>" >> ${TABLE_INDEX}

	    local build=$BUILD_NUMBER
	    [ -z $BUILD_NUMBER ] && build=`date +%g%m%d%H`
	    echo "build" $build >> $DATA_PATH
		for t in $TESTSET
	    do
            local ps=disable
			echo $t | grep "_ps$" > /dev/null; 
	        if [ $? -eq 0 ];then
	            ps=auto
	        fi
	        
			__msg info "get ps=>$ps case=>$t result from log"
            local obName=ob_${t}
			local tps=`grep "read/write requests:" collected_log/$obName.* -r -h | sed "s#.*(##g" | sed "s# .*##g"`
			local avg=`grep "avg:" collected_log/$obName.* -r -h | sed "s#.* ##g" | sed "s#ms.*##g"`
			local min=`grep "min:" collected_log/$obName.* -r -h | sed "s#.* ##g" | sed "s#ms.*##g"`
			local max=`grep "max:" collected_log/$obName.* -r -h | sed "s#.* ##g" | sed "s#ms.*##g"`
		    local per=`grep "95 percentile:" collected_log/$obName.* -r -h | sed "s#.* ##g" | sed "s#ms.*##g"`

		    [ -z "$tps" ] && tps=0
		    [ -z "$avg" ] && avg=0
		    [ -z "$min" ] && min=0
		    [ -z "$max" ] && max=0
		    [ -z "$per" ] && per=0

		    __msg info "TPS: $tps Latency: avg=>$avg min=>$min max=>$max 95%=>$per"
	        
			echo ${t}_tps $tps >> ${DATA_PATH}
	        echo ${t}_avg $avg >> ${DATA_PATH}
		    echo ${t}_min $min >> ${DATA_PATH}
		    echo ${t}_max $max >> ${DATA_PATH}
		    echo ${t}_95% $per >> ${DATA_PATH}

	        if [ $t = "mix_read" ] || [ $t = "mix_read_ps" ];then
		          avg=`echo "scale=2;$avg/55"|bc`
		          per=`echo "scale=2;$per/55"|bc`
	        fi
	        echo "<tr><td>$t</td><td>$ps</td><td>$tps</td><td>$avg</td><td>$per</td></tr>" >>  ${TABLE_INDEX}
        done
	    echo "</table>" >>  ${TABLE_INDEX}
	}

    function collect_log() {
        __msg info "start collect log"
        local href=$LOG_URL
	    > index.html
	    for testDir in `ls -t collected_log`
	    do
	        for log in `ls collected_log/$testDir`
	        do
	            mv collected_log/${testDir}/${log} collected_log/${testDir}/${log}.log
		        echo "<a href=${href}/${testDir}/${log}.log> $testDir/$log </a>" >> index.html
		        echo "<br>"  >> index.html
		    done
		    echo "<br><br>"  >> index.html
		done
        echo "move collected_log to $LOG_DIR"
	    cp index.html collected_log
	    cp ${TABLE_INDEX}  collected_log
        cp -r collected_log $LOG_DIR
	    rm -fr `find $LOG_DIR -name *.profile.*`
	    __msg info "collect log ok"
    }

    clear
	prepare
    run
    collect_log
    collect_data
    
	return 0
}

##
## Run CT
## 
function runCT() {
	
	local obName=$1
	local process=$2

    __msg info "run ./deploy.py $obName.ct.reboot"
    ./deploy.py ${obName}.ct.reboot
	local start=`date "+%m/%d/%Y %H:%M"`
	__msg info "$obName client start at $start, and will finish about $MAX_SECONDS seconds later]"

    local s=0
    local flag=1
    local ct=`echo $CTS | cut -f2 -d"'"`
    while [ $s -lt $MAX_SECONDS ] && [ $flag -eq 1 ];
	do
	       sleep 10
	       let 's=s+10'
	       let 'a=s%1800'
	       if [ $a -eq 0 ];then
	           echo "[$s seconds passed...]"
	       fi
	       ssh $ct "ps uxf | grep $process | grep -v grep" > /dev/null;
	       if [ $? -ne 0 ];then
	           __msg warning "client has been gone ..."
	           flag=0
           fi
    done
	local stop=`date "+%m/%d/%Y %H:%M"`
	__msg info "now: $stop"

}
function trxTest() {
    function clear() {
	    __msg info "clear the last collected log under $WORKSPACE"
	    rm -fr $LOG_DIR
		__msg info "clear the last simon chart under $WORKSPACE"
	    rm -fr $SIMON_DIR

        __msg info "backup the last collected_log under deploy if exists"
		rm -fr collected_log.bk
        [ -d collected_log ] && mv collected_log collected_log.bk
	    __msg info "backup the last simon_chart under deploy if exists"
		rm -fr simon_chart.bk
	    [ -d simon_chart ] && mv simon_chart simon_chart.bk
	}

	function prepare() {
		updateLocalBin
        
		__msg debug "copy trxtest and ups_admin to trxtest dir"
		cp tools/ups_admin trxtest
	    cp ${TRXTEST_PATH} trxtest/
        
		__msg debug "copy depend libs to lib tool"
	    cp -rf ${ThirdLibs}/lib/* lib/
    	createOBConfigPY

	}
	function run(){
        if ! rebootOB $OB_NAME;then
	        __msg err "reboot $OB_NAME failed"
		    return 2
	    fi
	    
	    #openTraceLog $OB_NAME
		start=`date "+%m/%d/%Y %H:%M"`
        __msg info "trxtest begins at $start]"
        __msg info "http://${SIMON_HOST}:4080/simon/data?timestart=`encodeTime "$start"`&timestop=now&width=750&height=200&application=obtrxtest&report=trxtest+report&reportItem=trxtest&metric=trx_latency&metric=trx_per_second&legend=metric&multigraph=metric&timezone=Asia%2FShanghai&view=html"
		runCT $OB_NAME "trxtest"

        stop=`date "+%m/%d/%Y %H:%M"`
        __msg info "trxtest ends at $stop]"
        __msg info "http://${SIMON_HOST}:4080/simon/data?timestart=`encodeTime "$start"`&timestop=`encodeTime "$stop"`&width=750&height=200&application=obtrxtest&report=trxtest+report&reportItem=trxtest&metric=trx_latency&metric=trx_per_second&legend=metric&multigraph=metric&timezone=Asia%2FShanghai&view=html"

		__msg info "stop ob"
		./deploy.py ${OB_NAME}.force_stop
	    __msg info  "collect log"
		./deploy.py ${OB_NAME}.collect_log
		__msg info "print result"
		cat collected_log/${OB_NAME}.*/trxtest_*.log
        cp -r collected_log $LOG_DIR
	}

	function collect() {
		cp -r collected_log $LOG_DIR
        prepareMyTestLog $LOG_DIR $LOG_URL
        prepareTrxTestSimonChart "$start" "$stop"
	}
	
	cd $SRC_DIR/tools/deploy 
	clear
	prepare

	start=
	stop=
	
	if ! run;then
	    return 2
	fi
	
	collect

	return 0
}
function hisTest() {

    function prepare(){
		updateLocalBin
        
		__msg info "copy sysbench and ups_admin to benchmark dir"
	    
		cp tools/ups_admin histest
	    cp ${SYSBENCH_PATH} histest/sysbench_mt
        
		__msg info "copy depend libs to lib tool"
	    cp -rf ${ThirdLibs}/lib/* lib/
    	createOBConfigPY
        
	}
	function run(){
        if ! rebootOB $OB_NAME;then
	        __msg err "reboot $OB_NAME failed"
		    return 2
	    fi
         
		#echo "[SET ob_read_consistency=0]"
	    #./deploy.py ob$i.obmysql extra="-e'set ob_read_consistency=0'"
	    __msg info "create tables from table.sql"
	    ./deploy.py ${OB_NAME}.obmysql extra="-e'source ./histest/table.sql'"
		#echo "[SET ob_read_consistency=1]"
	    #./deploy.py ob$i.obmysql extra="-e'set ob_read_consistency=1'"

	    #openTraceLog $OB_NAME
		start=`date "+%m/%d/%Y %H:%M"`
        __msg info "Monitor: http://${SIMON_HOST}:4080/simon/data?timestart=`encodeTime "$start"`&timestop=now&width=700&height=200&application=oceanbase&report=sysbench+report&reportItem=sysbench&legend=cluster&legend=hostname&legend=metric&multigraph=metric&timezone=Asia%2FShanghai&view=html"
	    sleep 10
		__msg info "set block index cache to 1024M"
		./deploy.py $OB_NAME.obmysql extra="</home/xiaojun.chengxj/oceanbase-0.4/change_block_cache.sql"
		#./deploy.py $OB_NAME.obmysql extra="-e''"
		sleep 60
		#__msg info "restart ups to have new configure effect"
		__msg info "`./deploy.py $OB_NAME.get_master_ups`"
		./deploy.py $OB_NAME.cs0.stop
		sleep 3
		./deploy.py $OB_NAME.cs1.stop
		sleep 3
		./deploy.py $OB_NAME.cs2.stop
		sleep 3
		./deploy.py $OB_NAME.cs0.start
		sleep 3
		./deploy.py $OB_NAME.cs1.start
		sleep 3
		./deploy.py $OB_NAME.cs2.start
		sleep 3
		#./deploy.py $OB_NAME.ups0.start
		#sleep 30
		#./deploy.py $OB_NAME.ups1.stop
		#sleep 3
		#./deploy.py $OB_NAME.ups1.start
		sleep 60
		__msg info "`./deploy.py $OB_NAME.get_master_ups`"
		runCT $OB_NAME "sysbench_mt"
        stop=`date "+%m/%d/%Y %H:%M"`

		__msg info "stop ob"
		./deploy.py ${OB_NAME}.force_stop
	    __msg info  "collect log"
		./deploy.py ${OB_NAME}.collect_log
		__msg info "print result"
		cat collected_log/${OB_NAME}.*/histest_*.log
        cp -r collected_log $LOG_DIR
	}
	
	function clear(){
	    __msg info "clear the last collected log under $WORKSPACE"
	    rm -fr $LOG_DIR
		__msg info "clear the last simon chart under $WORKSPACE"
	    rm -fr $SIMON_DIR

        __msg info "backup the last collected_log under deploy if exists"
		rm -fr collected_log.bk
        [ -d collected_log ] && mv collected_log collected_log.bk
	    __msg info "backup the last simon_chart under deploy if exists"
		rm -fr simon_chart.bk
	    [ -d simon_chart ] && mv simon_chart simon_chart.bk
	}
    function collect_log() {
		cp -r collected_log $LOG_DIR
        prepareMyTestLog $LOG_DIR $LOG_URL
        prepareHisTestSimonChart "$start" "$stop"
	}

	start=
	stop=
	cd $SRC_DIR/tools/deploy 
	cp ${__ScriptPath}/deploy.py ./
    clear
	prepare
	if ! run;then
	    return 2
	fi
    collect_log

	return 0
}

##
## Get Local IP
##
function getLocalIP()
{
    echo `/sbin/ifconfig |grep "inet addr" | head -1 | sed "s#.*net addr:##g" | sed "s# Bcast.*##g"`
}

##
## Check variables in oceanbase.cfg.sh
##

function checkEnv() {
   for var in JAVA_HOME ThirdLibs TBLIB_ROOT EASY_ROOT SRC_DIR
   do
       local dirPath=`eval echo \\$${var}`
	   __msg info "check $var=$dirPath"
       if [ ! -d $dirPath ];then
           __msg err "$var=$dirPath is not valid directory"
		   return 2
       fi
   done
   for var in PATH LD_LIBRARY_PATH
   do
       local value=`eval echo \\$${var}`
	   __msg info "check $var=$value"
   done

   return 0
}

##
## Download mysqltest
##

function downloadMysqltest() {
   __msg info "wget '$MYSQLTEST_URL' -o ./mysqltest.down -O $SRC_DIR/mysqltest"
   if ! wget $MYSQLTEST_URL -o ./mysqltest.down -O $SRC_DIR/mysqltest;then
       return 2
   fi
   chmod +x $SRC_DIR/mysqltest
   return 0
}

##
## Download cppcheck
##

function downloadCppcheck() {
   __msg info "wget '$CPPCHECK_URL' -o ./cppcheck.down -O $SRC_DIR/cppcheck"
   if ! wget "$CPPCHECK_URL" -o ./cppcheck.down -O $SRC_DIR/cppcheck;then
       return 2
   fi
   chmod +x $SRC_DIR/cppcheck
   return 0
}



##
## Download java mytest
##

function downloadMytest() {
   
   if ! wget "$MYTEST_JAR_URL" -o ./mytest.down -O $SRC_DIR/tools/deploy/mysql_test/java/mytest.jar;then
       return 2
   fi
   return 0
}

##
##
##
function openTraceLog() {

    local obName=$1
	local rsNum=$(echo $CLUSTER/1000|bc)
	local upsNum=$(echo $CLUSTER%1000/100|bc)
	local msNum=$(echo $CLUSTER%100/10|bc)
	local csNum=$(echo $CLUSTER%10|bc)

    local i=0
	while [ $i -lt $rsNum ];
	do
	    #./deploy.py $obName.rs${i}.kill -41
		let 'i++'
	done
	local i=0
	while [ $i -lt $csNum ];
	do
	    ./deploy.py $obName.cs${i}.kill -41
		let 'i++'
	done
	local i=0
	while [ $i -lt $upsNum ];
	do
	    #./deploy.py $obName.ups${i}.kill -41
		let 'i++'
	done
	local i=0
	while [ $i -lt $msNum ];
	do
	    ./deploy.py $obName.ms${i}.kill -41
		let 'i++'
	done
}


##
## cppcheck
##
function cppCheck() {

	cd $SRC_DIR
    if [ -z $CPPCHECK_PATH ];then
        if ! downloadCppcheck;then
            __msg err "failed to download cppcheck from $CPPCHECK_URL"
			return 2
		else
		    export CPPCHECK_PATH=$SRC_DIR/cppcheck
		fi
	fi
	__msg info "start cppcheck"
	if ! $CPPCHECK_PATH src -j 4  -q --xml > $CPPCHECK_RESULT 2>&1;then
	    return 2
	fi
	return 0
}

##
## Create config2.py for history test
##
function createOBConfigPY() {
  
	__msg info "create config2.py"
	local ipAddr=$(getLocalIP)

    __msg info "localhost IP:$ipAddr"\
	
	local configPath=${SRC_DIR}/tools/deploy/config2.py
    cp -fr ${SRC_DIR}/tools/deploy/config.py $configPath

    echo "${OB_NAME}=${OB_DEFINE}" >> ${configPath}
	__msg info "`tail -1 ${SRC_DIR}/tools/deploy/config2.py`"
   
}

encodeTime() {
   d=$1
   # / => %2F  , : => %3A ,  => + , 12/20/2012 10:00
   myd=`echo $d | cut -f1 -d" "`
   myt=`echo $d | cut -f2 -d" "`
   m=`echo $myd | cut -f1 -d"/"`
   d=`echo $myd | cut -f2 -d"/"`
   y=`echo $myd | cut -f3 -d"/"`
   h=`echo $myt | cut -f1 -d":"`
   s=`echo $myt | cut -f2 -d":"`

   echo "${m}%2F${d}%2F${y}+${h}%3A${s}"
}

function prepareHisTestSimonChart() {
    local start="$1"
	local stop="$2"
    mkdir -p $SIMON_DIR
    > $SIMON_DIR/index.html
	__msg info "start to generate simon chart"
	for metric in  prepare_latency prepare_rps request_latency requests_per_second
    do
        wget "http://${SIMON_HOST}:4080/simon/data?timestart=-2h&timestop=now&width=750&height=200&application=oceanbase&report=sysbench+report&reportItem=sysbench&cluster=histest_monitor&metric=$metric&legend=cluster&legend=hostname&legend=metric&timezone=Asia%2FShanghai&view=html" -O ./histesttmp
		local img_url=`grep "simon/png/" ./histesttmp | sed "s#.*img src=\"##g" | sed "s#\".*>##g"`
	    rm -fr ./histesttmp
	    wget "http://${SIMON_HOST}:4080$img_url" -O  $SIMON_DIR/$metric.png -o /tmp/.a
	    echo "<h3>$metric</h3><br>" >> $SIMON_DIR/index.html
		echo "<img src=$metric.png></img><br>" >> $SIMON_DIR/index.html
	done
	__msg info "generate simon chart finish"
}
function prepareTrxTestSimonChart() {

    local start="$1"
	local stop="$2"

    mkdir -p $SIMON_DIR
    > $SIMON_DIR/index.html
	__msg info "start to generate simon chart"
    for suffix in  trx query update_int update_str select_for_update delete insert 
    do
      for prefix in  per_second latency 
      do
        metric=${suffix}_${prefix}
        wget "http://${SIMON_HOST}:4080/simon/data?timestart=$start&timestop=$stop&width=750&height=200&application=obtrxtest&report=trxtest+report&reportItem=trxtest&metric=$metric&legend=metric&multigraph=metric&timezone=Asia%2FShanghai&view=html" -O ./trxtesttmp -o /tmp/.a
        img_url=`grep "simon/png/" ./trxtesttmp | sed "s#.*img src=\"##g" | sed "s#\".*>##g"`
        rm -fr ./trxtesttmp
        wget "http://${SIMON_HOST}:4080$img_url" -O    $SIMON_DIR/$metric.png -o /tmp/.a
        echo "<h3>$metric</h3><br>" >> $SIMON_DIR/index.html
        echo "<img src=$metric.png></img><br>" >> $SIMON_DIR/index.html
      done
    done
	__msg info "generate simon chart finish"
}


function tpccTest() {
    function clear() {
	    __msg info "clear the last collected log under $WORKSPACE"
	    rm -fr $LOG_DIR
		__msg info "clear the last simon chart under $WORKSPACE"
	    rm -fr $SIMON_DIR

        __msg info "backup the last collected_log under deploy if exists"
		rm -fr collected_log.bk
        [ -d collected_log ] && mv collected_log collected_log.bk
	    __msg info "backup the last simon_chart under deploy if exists"
		rm -fr simon_chart.bk
	    [ -d simon_chart ] && mv simon_chart simon_chart.bk
	}

	function prepare() {
		updateLocalBin
        
		__msg debug "copy tpcc_load tpcc_start to dir"
	    cp ${TPCCLOAD_PATH} tpcc/
	    cp ${TPCCSTART_PATH} tpcc/
        
		__msg debug "copy depend libs to lib tool"
	    cp -rf ${ThirdLibs}/lib/* lib/
    	createOBConfigPY

	}
	function run(){
        if ! rebootOB $OB_NAME;then
	        __msg err "reboot $OB_NAME failed"
		    return 2
	    fi
	    
	    openTraceLog $OB_NAME
		start=`date "+%m/%d/%Y %H:%M"`
        __msg info "tpcc begins at $start]"
        __msg info "http://${SIMON_HOST}:4080/simon/data?timestart=`encodeTime "$start"`&timestop=now&width=750&height=200&application=obtrxtest&report=trxtest+report&reportItem=trxtest&metric=trx_latency&metric=trx_per_second&legend=metric&multigraph=metric&timezone=Asia%2FShanghai&view=html"
		runCT $OB_NAME "tpcc_start"

        stop=`date "+%m/%d/%Y %H:%M"`
        __msg info "tpcc ends at $stop]"
        __msg info "http://${SIMON_HOST}:4080/simon/data?timestart=`encodeTime "$start"`&timestop=`encodeTime "$stop"`&width=750&height=200&application=obtrxtest&report=trxtest+report&reportItem=trxtest&metric=trx_latency&metric=trx_per_second&legend=metric&multigraph=metric&timezone=Asia%2FShanghai&view=html"

		__msg info "stop ob"
		./deploy.py ${OB_NAME}.force_stop
	    __msg info  "collect log"
		./deploy.py ${OB_NAME}.collect_log
		__msg info "print result"
		cat collected_log/${OB_NAME}.*/tpcc_*.log
        cp -r collected_log $LOG_DIR
	}

	function collect() {
		cp -r collected_log $LOG_DIR
        prepareMyTestLog $LOG_DIR $LOG_URL
        prepareTrxTestSimonChart "$start" "$stop"
	}
	
	cd $SRC_DIR/tools/deploy 
	clear
	prepare

	start=
	stop=
	
	if ! run;then
	    return 2
	fi
	
	collect

	return 0
}
