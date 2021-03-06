V8_HOME ?= /home/danielbevenius/work/google/v8_src/v8
v8_build_dir = $(V8_HOME)/out/x64.release_gcc
v8_buildtools_dir = $(V8_HOME)/buildtools/third_party
gtest_home = $(PWD)/deps/googletest/googletest
current_dir=$(shell pwd)

v8_include_dir = $(V8_HOME)/include
v8_src_dir = $(V8_HOME)/src
v8_gen_dir = $(v8_build_dir)/gen
v8_dylibs=-lv8 -lv8_libplatform -lv8_libbase
GTEST_FILTER ?= "*"
clang = "$(V8_HOME)/third_party/llvm-build/Release+Asserts/bin/clang"

clang_cmd=g++ -Wall -g $@.cc -o $@ -std=c++14 -Wcast-function-type \
	  -fno-exceptions -fno-rtti \
          -I$(v8_include_dir) \
          -I$(V8_HOME) \
          -I$(v8_build_dir)/gen \
          -L$(v8_build_dir) \
          $(v8_dylibs) \
          -Wl,-L$(v8_build_dir) -Wl,-lpthread

clang_test_cmd=g++ -Wall -g test/main.cc $@.cc -o $@  ./lib/gtest/libgtest-linux.a -std=c++14 \
	  -fno-exceptions -fno-rtti -Wcast-function-type -Wno-unused-variable \
	  -Wno-class-memaccess -Wno-comment -Wno-unused-but-set-variable \
	  -DV8_INTL_SUPPORT \
          -I$(v8_include_dir) \
          -I$(V8_HOME) \
          -I$(V8_HOME)/third_party/icu/source/common/ \
          -I$(v8_build_dir)/gen \
          -L$(v8_build_dir) \
          -I./deps/googletest/googletest/include \
          $(v8_dylibs) \
          -Wl,-L$(v8_build_dir) -Wl,-L/usr/lib64 -Wl,-lstdc++ -Wl,-lpthread

clang_gtest_cmd=g++ --verbose -Wall -O0 -g -c $(gtest_home)/src/gtest-all.cc \
          -o $(gtest_home)/gtest-all.o	-std=c++14 \
	  -fno-exceptions -fno-rtti \
          -I$(gtest_home) \
          -I$(gtest_home)/include


COMPILE_TEST = g++ -v -std=c++11 -O0 -g -I$(V8_HOME)/third_party/googletest/src/googletest/include -I$(v8_include_dir) -I$(v8_gen_dir) -I$(V8_HOME) $(v8_dylibs) -L$(v8_build_dir) -pthread  lib/gtest/libgtest.a

hello-world: hello-world.cc
	@echo "Using v8_home = $(V8_HOME)"
	$(clang_cmd)

persistent-obj: persistent-obj.cc
	$(clang_cmd)

.PHONY: gtest-compile
gtest-compile: 
	@echo "Building gtest library"
	$(clang_gtest_cmd)
	ar -rv $(PWD)/lib/gtest/libgtest-linux.a $(gtest_home)/gtest-all.o


.PHONY: run-hello
run-hello:
	@LD_LIBRARY_PATH=$(v8_build_dir)/ ./hello-world

.PHONY: gdb-hello
gdb-hello:
	@LD_LIBRARY_PATH=$(v8_build_dir)/ gdb --cd=$(v8_build_dir) --args $(current_dir)/hello-world
	

contexts: snapshot_blob.bin contexts.cc
	clang++ -O0 -g -I$(v8_include_dir) $(v8_dylibs) -L$(v8_build_dir) $@.cc -o $@ -pthread -std=c++0x -rpath $(v8_build_dir)

ns: snapshot_blob.bin ns.cc
	@echo "Using v8_home = $(v8_include_dir)"
	clang++ -O0 -g -I$(v8_include_dir) $(v8_dylibs) -L$(v8_build_dir) $@.cc -o $@ -pthread -std=c++0x -rpath $(v8_build_dir)

instances: snapshot_blob.bin instances.cc
	clang++ -O0 -g -fno-rtti -I$(v8_include_dir) $(v8_dylibs) -L$(v8_build_dir) $@.cc -o $@ -pthread -std=c++0x -rpath $(v8_build_dir)

run-script: run-script.cc
	$(clang_cmd) 

exceptions: snapshot_blob.bin exceptions.cc
	clang++ -O0 -g -fno-rtti -I$(v8_include_dir) -I$(V8_HOME) $(v8_dylibs) -L$(v8_build_dir) $@.cc $(v8_src_dir)/objects-printer.cc -o $@ -pthread -std=c++0x -rpath $(v8_build_dir)

snapshot_blob.bin:
	@cp $(v8_build_dir)/$@ .

check: test/local_test test/persistent-object_test test/maybe_test test/smi_test test/string_test test/context_test

test/local_test: test/local_test.cc
	$(COMPILE_TEST) test/main.cc $< -o $@

test/persistent-object_test: test/persistent-object_test.cc
	$(clang_test_cmd)

test/maybe_test: test/maybe_test.cc
	$(COMPILE_TEST) test/main.cc $< -o $@

test/smi_test: test/smi_test.cc
	$(COMPILE_TEST) test/main.cc $< -o $@

test/string_test: test/string_test.cc
	$(COMPILE_TEST) test/main.cc $< -o $@

test/jsobject_test: test/jsobject_test.cc
	$(clang_test_cmd)

test/ast_test: test/ast_test.cc
	$(COMPILE_TEST) -Wno-everything test/main.cc $< -o $@

test/context_test: test/context_test.cc
	$(COMPILE_TEST) test/main.cc $< -o $@

test/heap_test: test/heap_test.cc
	$(clang_test_cmd)

test/map_test: test/map_test.cc
	$(clang_test_cmd)

test/isolate_test: test/isolate_test.cc
	$(clang_test_cmd)

list-gtest:
	./test/smi_test --gtest_list_test

.PHONY: clean list-gtest

clean: 
	@rm -f hello-world
	@rm -f instances
	@rm -f run-script
	@rm -rf exceptions
	@rm -f natives_blob.bin
	@rm -f snapshot_blob.bin
	@rm -rf hello-world.dSYM
	@rm -rf test/local_test
	@rm -rf test/persistent-object_test
	@rm -rf test/maybe_test
	@rm -rf test/smi_test
	@rm -rf test/string_test
	@rm -rf test/jsobject_test
	@rm -rf test/ast_test
	@rm -rf test/context_test
	@rm -rf test/map_test
