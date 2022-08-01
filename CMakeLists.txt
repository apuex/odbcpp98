cmake_minimum_required(VERSION 2.8...3.20)
cmake_policy(SET CMP0054 NEW)
project(odbcpp98 CXX)

option(ODBCPP98_DISABLE_TESTS "Do not build tests" OFF)
option(ODBCPP98_ENABLE_COVERAGE "Enable test coverage reporting for GCC/clang" OFF)
option(ODBCPP98_ENABLE_UNICODE "Enable Unicode support" OFF)

set(CMAKE_CXX_STANDARD 98)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
message(STATUS "odbcpp98 compile: C++${CMAKE_CXX_STANDARD}")

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_COMPILER_IS_GNUCXX)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -Wall -Wnarrowing -Werror")
  include(CheckCXXCompilerFlag)

  if (ODBCPP98_ENABLE_COVERAGE)
    add_compile_options(--coverage -O0)
    link_libraries(gcov)
    message(STATUS "odbcpp98 build: Enable test coverage - Yes")
  endif()

elseif(CMAKE_CXX_COMPILER_ID MATCHES "Intel")
    string(REGEX REPLACE "[/-]W[0-4]" "/W4" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    if (NOT (CMAKE_VERSION VERSION_LESS 3.6.0)) # Compiler features for Intel in CMake 3.6+
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Qstd=c++03")
    endif()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /QaxCORE-AVX2")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /fp:precise")
    set(CMAKE_CXX_FLAGS_DEBUG   "${CMAKE_CXX_FLAGS_DEBUG}   /Od")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O3")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Qipo")
elseif(MSVC)
  string(REGEX REPLACE "/W[0-4]" "/W4" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
endif()

if(ODBCPP98_ENABLE_UNICODE)
  add_definitions(-DODBCPP98_ENABLE_UNICODE)
  if(MSVC)
    # Sets "Use Unicode Character Set" property in Visual Studio projects
    add_definitions(-DUNICODE -D_UNICODE)
  endif()
endif()

if(UNIX)
  # Try to find unixODBC first via odbc_config program.
  find_program(ODBC_CONFIG odbc_config
    PATHS $ENV{ODBC_PATH}/bin /usr/bin /usr/local/bin)
  if(ODBC_CONFIG)
    message(STATUS "odbcpp98 build: ODBC on Unix - unixODBC")
    set(ODBCLIB odbc)
    execute_process(COMMAND ${ODBC_CONFIG} --include-prefix
      OUTPUT_VARIABLE ODBC_INCLUDE_DIR OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(ODBC_CFLAGS "-I${ODBC_INCLUDE_DIR}")
    set(CMAKE_FLAGS "${CMAKE_FLAGS} ${ODBC_CFLAGS}")
    execute_process(COMMAND ${ODBC_CONFIG} --libs
      OUTPUT_VARIABLE ODBC_LINK_FLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)
  endif()

  # Fallback to finding unixODBC via install paths
  if(NOT ODBC_CONFIG)
    find_path(UnixODBC_INCLUDE_DIR uodbc_stats.h
      /usr/include
      /usr/local/include
      /usr/include/odbc
      /usr/local/include/odbc
      /usr/include/libodbc
      /usr/local/include/libodbc)
    if(UnixODBC_INCLUDE_DIR)
      set(ODBC_CONFIG 1)
      message(STATUS "odbcpp98 build: ODBC on Unix - unixODBC")
      set(ODBCLIB odbc)
      set(ODBC_CFLAGS "-I${UnixODBC_INCLUDE_DIR} -DHAVE_UNISTD_H -DHAVE_PWD_H -DHAVE_SYS_TYPES_H -DHAVE_LONG_LONG -DSIZEOF_LONG_INT=8")
    endif()
  endif()

  # Fallback to using iODBC
  if(NOT ODBC_CONFIG)
    find_program(ODBC_CONFIG iodbc-config
      PATHS $ENV{ODBC_PATH}/bin /usr/bin /usr/local/bin)
    if(ODBC_CONFIG)
      message(STATUS "odbcpp98 build: ODBC on Unix - iODBC")
      set(ODBCLIB iodbc)
      execute_process(COMMAND ${ODBC_CONFIG} --cflags
        OUTPUT_VARIABLE ODBC_CFLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)
      set(CMAKE_FLAGS "${CMAKE_FLAGS} ${ODBC_CFLAGS}")
      execute_process(COMMAND ${ODBC_CONFIG} --libs
        OUTPUT_VARIABLE ODBC_LINK_FLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)
      if(ODBCPP98_ENABLE_UNICODE)
        add_definitions(-DODBCPP98_USE_IODBC_WIDE_STRINGS)
      endif()
    endif()
  endif()

  if(NOT ODBC_CONFIG)
    message(FATAL_ERROR "can not find a suitable odbc driver manager")
  endif()

  message(STATUS "ODBC compile flags: ${ODBC_CFLAGS}")
  message(STATUS "ODBC link flags: ${ODBC_LINK_FLAGS}")
endif()

if(UNIX)
  set(ODBC_LIBRARIES ${ODBCLIB})
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${ODBC_LINK_FLAGS}")
elseif(MSVC OR CMAKE_CXX_COMPILER_ID MATCHES "Intel")
  set(ODBC_LIBRARIES odbc32.lib odbccp32.lib Ws2_32.lib)
elseif(MINGW)
  set(ODBC_LIBRARIES odbc32 odbccp32)
endif()

set(Boost_USE_STATIC_LIBS ON)
set(Boost_USE_MULTITHREADED ON)
find_package(Boost COMPONENTS locale REQUIRED)
if(Boost_FOUND)
  include_directories(${Boost_INCLUDE_DIRS})
  link_directories(${CMAKE_BINARY_DIR}/lib ${Boost_LIBRARY_DIRS})
else()
  message(FATAL_ERROR "can not find boost")
endif()

if(APPLE)
  set(CMAKE_MACOSX_RPATH ON)
  message(STATUS "Use rpaths on Mac OS X - ${CMAKE_MACOSX_RPATH}")

  # AppleClang complains of unused `-I/path/` arguments.
  # These are harmless and can be safely ignored.
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unused-command-line-argument")
endif()

add_library(odbcpp98 odbcpp98/odbcpp98.cpp odbcpp98/odbcpp98.h)

target_link_libraries(odbcpp98 ${Boost_LIBRARIES} ${ODBC_LIBRARIES})

target_include_directories(odbcpp98 PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<INSTALL_INTERFACE:include/odbcpp98>) # <prefix>/include/odbcpp98

if(UNIX)
  set_target_properties(odbcpp98 PROPERTIES
    COMPILE_FLAGS "${ODBC_CFLAGS}"
    LIBRARY_OUTPUT_DIRECTORY "lib")
endif()

set(ODBCPP98_CONFIG odbcpp98-config)
# 'make install' to the correct location
if(BUILD_SHARED_LIBS)
  install(TARGETS odbcpp98
    EXPORT ${ODBCPP98_CONFIG} # associate installed target files with export
    INCLUDES DESTINATION include
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin) # for Windows
else()
  install(TARGETS odbcpp98
    EXPORT ${ODBCPP98_CONFIG} # associate installed target files with export
    INCLUDES DESTINATION include
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)
endif()
# Install public include headers
install(FILES odbcpp98/odbcpp98.h DESTINATION include/odbcpp98)
# Make project importable from the install directory
## Generate and install *-config.cmake exporting targets from install tree.
install(EXPORT ${ODBCPP98_CONFIG} DESTINATION "lib/cmake/odbcpp98")
# Make project importable from the build directory
## Generate file *-config.cmake exporting targets from build tree.
export(TARGETS odbcpp98 FILE ${ODBCPP98_CONFIG}.cmake)

if(NOT ODBCPP98_DISABLE_TESTS)
  enable_testing()
  add_subdirectory(tests)
  if(NOT CMAKE_GENERATOR MATCHES "^Visual Studio")
    add_custom_target(check
      COMMAND ${CMAKE_CTEST_COMMAND} --force-new-ctest-process --output-on-failure
      DEPENDS tests)
  endif()
endif()

