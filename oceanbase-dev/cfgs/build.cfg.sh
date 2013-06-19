##
## rpm build variables
##
export ConfigureArguments="--with-release --without-test-case"
#export ConfigureArguments=""
export CPPFLAGS="-I${ThirdLibs}/include"
export LDFLAGS="-L${ThirdLibs}/lib -L${ThirdLibs}/lib64"
