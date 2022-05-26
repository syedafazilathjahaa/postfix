set -e
CC=clang  CXX=clang++ CFLAGS=-fsanitize=address LIB_FUZZING_ENGINE=afl++
export CC CXX
set $LLVM_CONFIG=/usr/bin/llvm-config-10
export LIB_FUZZING_ENGINE


cd postfix
make makefiles CCARGS="${CFLAGS}"
make
BASE=$PWD

# Compile fuzzers
cd ${BASE}/src/global
$CC $CFLAGS -DHAS_DEV_URANDOM -DSNAPSHOT -UUSE_DYNAMIC_LIBS -DDEF_SHLIB_DIR=\"no\" \
               -UUSE_DYNAMIC_MAPS -I. -I../../include -DNO_EAI -DDEF_SMTPUTF8_ENABLE=\"no\" \
                -g -O -DLINUX4 -Wformat -Wno-comment -fno-common -c $SRC/fuzz_tok822.c
$CC $CFLAGS $LIB_FUZZING_ENGINE -DHAS_DEV_URANDOM -DSNAPSHOT -UUSE_DYNAMIC_LIBS -DDEF_SHLIB_DIR=\"no\" \
               -UUSE_DYNAMIC_MAPS -I. -I../../include -DNO_EAI -DDEF_SMTPUTF8_ENABLE=\"no\" \
                -g -O -DLINUX4 -Wformat -Wno-comment -fno-common -c $SRC/fuzz_mime.c


# Link fuzzers
cd ${BASE}
$CC $CFLAGS $LIB_FUZZING_ENGINE=afl++ ./src/global/fuzz_tok822.o -o $OUT/fuzz_tok822 \
  ./lib/libglobal.a ./lib/libutil.a
$CC $CFLAGS $LIB_FUZZING_ENGINE ./src/global/fuzz_mime.o -o $OUT/fuzz_mime \
  ./lib/libglobal.a ./lib/libutil.a -ldb -lnsl
