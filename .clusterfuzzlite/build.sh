set -e
CC=afl-clang-fast  CXX=afl-clang-fast++ CFLAGS=-fsanitize=address

set $LLVM_CONFIG=/usr/bin/llvm-config-10
set $gcc=/usr/bin/gcc.exe /usr/lib/gcc /usr/share/man/man1/gcc.1.gz

export AFL_SKIP_OSSFUZZ=1
export AFL_LLVM_INSTRUMENT=CLASSIC
export AFL_LLVM_MODE_WORKAROUND=0
export CC CXX

rm -rf afl-build
git clone --depth=1 https://github.com/AFLplusplus/AFLplusplus afl-build
cd afl-build
CC=afl-clang-fast
CXX=afl-clang-fast++
export CC CXX

make source-only
ar ru FuzzingEngine.a afl-compiler-rt.o utils/aflpp_driver/aflpp_driver.o

cp -f FuzzingEngine.a afl-fuzz afl-showmap ../
echo "Success: link fuzz target against FuzzingEngine.a!"




# Compile target using ASan, coverage instrumentation, and link against FuzzingEngine.a
$CC -fsanitize=address fuzz_mime.c FuzzingEngine.a -o fuzzer
$CC -fsanitize=address fuzz_tok822.c FuzzingEngine.a -o fuzzer
# Test out the build by fuzzing it. INPUT_CORPUS is a directory containing files. Ctrl-C when done.
AFL_SKIP_CPUFREQ=1 ./afl-fuzz -i $INPUT_CORPUS -o output -m none ./fuzzer
# Create a fuzzer build to upload to ClusterFuzz.
zip fuzzer-build.zip fuzzer afl-fuzz afl-showmap 
  
  
  
  

