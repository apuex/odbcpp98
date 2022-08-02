option(ODBCPP98_DISABLE_VALGRIND "Enable the valgrind memory checker for the tests." OFF)

set(unit_tests
  odbcpp98-env-alloc-test
  )

##include(FetchContent)
#FetchContent_Declare(
#  googletest
#  URL https://github.com/google/googletest/archive/refs/tags/release-1.11.0.zip
#)
## For Windows: Prevent overriding the parent project's compiler/linker settings
#set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
#FetchContent_MakeAvailable(googletest)

if (NOT ODBCPP98_DISABLE_VALGRIND)
  find_program(MEMORYCHECK_COMMAND valgrind)
  if ("${MEMORYCHECK_COMMAND}" MATCHES "MEMORYCHECK_COMMAND-NOTFOUND")
    message(WARNING "Valgrind couldn't be found.")
    unset(MEMORYCHECK_COMMAND)
  else()
    set(MEMORYCHECK_COMMAND_OPTIONS --trace-children=yes --leak-check=full --error-exitcode=1 --suppressions=${CMAKE_CURRENT_SOURCE_DIR}/valgrind.supp)
  endif()
endif()

foreach(unit_test ${unit_tests})
  add_executable("${unit_test}" "${unit_test}.cpp")
  target_link_libraries("${unit_test}" ${Boost_LIBRARIES}) #gtest_main
  if(UNIX)
    set_target_properties("${unit_test}" PROPERTIES LINK_FLAGS_RELEASE -s)
  else()
  endif()
  if(MEMORYCHECK_COMMAND)
    add_test(NAME "${unit_test}"
      COMMAND "${MEMORYCHECK_COMMAND}" ${MEMORYCHECK_COMMAND_OPTIONS} "${CMAKE_CURRENT_BINARY_DIR}/${unit_test}")
  else()
    add_test(NAME "${unit_test}"
      COMMAND "./${unit_test}")
  endif()
endforeach()
