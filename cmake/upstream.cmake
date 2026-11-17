# 上游接入：speexdsp（autotools）。
# 交叉时上游已由 scripts/local-cross.sh 编到 -DPKG_PREFIX 指向的前缀，
# 探针只负责链接静态库，不回头再编一遍上游（没有 pkg 目标）。

add_executable(speexdsp_harness test/pkg_speexdsp.c)
target_include_directories(speexdsp_harness PRIVATE "${PKG_PREFIX}/include")
target_link_directories(speexdsp_harness PRIVATE "${PKG_PREFIX}/lib")
target_link_libraries(speexdsp_harness PRIVATE speexdsp m)
target_compile_options(speexdsp_harness PRIVATE ${RVV_FLAGS})

add_test(NAME speexdsp_harness COMMAND speexdsp_harness)
