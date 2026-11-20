# 上游接入：speexdsp（autotools）。两侧各从自己的 SRC_DIR 编一份 prefix。
if(NOT DEFINED PKG_PREFIX)
  set(PKG_PREFIX "${CMAKE_BINARY_DIR}/pkg/prefix")
  add_custom_target(pkg ALL
    COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/cmake/pkg-build.sh" "${SRC_DIR}" "${CMAKE_BINARY_DIR}" "${RVV_MARCH}" "$<IF:$<BOOL:${RVV_KERNELS}>,1,0>"
    COMMENT "构建上游 speexdsp（${SRC_DIR}）"
    VERBATIM)
  set(HAVE_PKG_TARGET TRUE)
endif()

add_executable(speexdsp_harness test/pkg_speexdsp.c)
if(HAVE_PKG_TARGET)
  add_dependencies(speexdsp_harness pkg)
endif()
target_include_directories(speexdsp_harness PRIVATE "${PKG_PREFIX}/include")
target_link_directories(speexdsp_harness PRIVATE "${PKG_PREFIX}/lib")
target_link_libraries(speexdsp_harness PRIVATE speexdsp m)
target_compile_options(speexdsp_harness PRIVATE ${RVV_FLAGS})

add_test(NAME speexdsp_harness COMMAND speexdsp_harness)
