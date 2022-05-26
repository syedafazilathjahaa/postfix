set -e
make CC=afl-clang-fast CFLAGS=-fsanitize=address


rm -rf afl-build
git clone --depth=1 https://github.com/AFLplusplus/AFLplusplus afl-build
cd afl-build

make source-only
ar ru FuzzingEngine.a afl-compiler-rt.o utils/aflpp_driver/aflpp_driver.o

cp -f FuzzingEngine.a afl-fuzz afl-showmap ../
echo "Success: link fuzz target against FuzzingEngine.a!"



./build_afl.bash
# Compile target using ASan, coverage instrumentation, and link against FuzzingEngine.a
$CXX -fsanitize=address fuzz_mime.c FuzzingEngine.a -o fuzzer
$CXX -fsanitize=address fuzz_tok822.c FuzzingEngine.a -o fuzzer
# Test out the build by fuzzing it. INPUT_CORPUS is a directory containing files. Ctrl-C when done.
AFL_SKIP_CPUFREQ=1 ./afl-fuzz -i $INPUT_CORPUS -o output -m none ./fuzzer
# Create a fuzzer build to upload to ClusterFuzz.
zip fuzzer-build.zip fuzzer afl-fuzz afl-showmap



  
  
  
  
  
  
  
  
  
  

