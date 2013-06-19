## rpm build variables
##
## 

#export ConfigureArguments="--with-release --without-test-case"
export ConfigureArguments="--with-release"
export CPPFLAGS="-I${ThirdLibs}/include"
export LDFLAGS="-L${ThirdLibs}/lib -L${ThirdLibs}/lib64"
export LANG="zh_CN.UTF-8"
