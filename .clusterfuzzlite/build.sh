set -e
CC=clang  CXX=clang++ CFLAGS=-fsanitize=address
export CC CXX
set $LLVM_CONFIG=/usr/bin/llvm-config-10


cd postfix
make makefiles CCARGS="${CFLAGS}"
make
BASE=$PWD


rm -rf afl-build
git clone --depth=1 https://github.com/AFLplusplus/AFLplusplus afl-build
cd afl-build
make source-only
ar ru FuzzingEngine.a afl-compiler-rt.o utils/aflpp_driver/aflpp_driver.o 

cp -f FuzzingEngine.a afl-fuzz afl-showmap ../
echo "Success: link fuzz target against FuzzingEngine.a!"

# Compile target using ASan, coverage instrumentation, and link against FuzzingEngine.a
$CC -fsanitize=address .clusterfuzzlite/fuzz_mime.c FuzzingEngine.a -o fuzz_mime
$CC -fsanitize=address .clusterfuzzlite/fuzz_tok822.c FuzzingEngine.a -o fuzz_tok822

# Test out the build by fuzzing it. INPUT_CORPUS is a directory containing files. Ctrl-C when done.

AFL_SKIP_CPUFREQ=1 ./afl-fuzz -i $INPUT_CORPUS -o output -m none ./fuzz_mime
AFL_SKIP_CPUFREQ=1 ./afl-fuzz -i $INPUT_CORPUS -o output -m none ./fuzz_tok822


# Create a fuzzer build to upload to ClusterFuzz.
zip fuzz_mime-build.zip fuzz_mime afl-fuzz afl-showmap
zip fuzz_tok822-build.zip fuzz_tok822 afl-fuzz afl-showmap
