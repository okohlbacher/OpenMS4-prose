cmake_minimum_required(VERSION 3.24)
project(OpenMSProSE VERSION 1.0.0 LANGUAGES CXX)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(GenerateExportHeader)
include(CTest)
include(cmake/OpenMS4Dependencies.cmake)

option(OPENMS_PROSE_BUILD_TOOL "Build the ProSE command-line executable" ON)
if(BUILD_TESTING)
  openms4_find_core(COMPONENTS TestSupport)
else()
  openms4_find_core()
endif()
openms4_source_revision(OpenMSProSE_SOURCE_REVISION OpenMSProSE_SOURCE_DIRTY)

# Core exports native dependencies, including its selected OpenMP configuration.
# The backend has no dependency on CLI or another tool package.
add_library(OpenMS_ProSE SHARED source/ProSEAlgorithm.cpp)
add_library(OpenMS::ProSE ALIAS OpenMS_ProSE)
target_compile_features(OpenMS_ProSE PUBLIC cxx_std_23)
target_link_libraries(OpenMS_ProSE PUBLIC OpenMS::Core)
target_include_directories(OpenMS_ProSE PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/generated>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
set_target_properties(OpenMS_ProSE PROPERTIES
  EXPORT_NAME ProSE VERSION ${PROJECT_VERSION} SOVERSION 1
  CXX_VISIBILITY_PRESET hidden VISIBILITY_INLINES_HIDDEN YES)
openms4_install_rpath(OpenMS_ProSE)
generate_export_header(OpenMS_ProSE
  EXPORT_FILE_NAME generated/OpenMS/ANALYSIS/ID/OpenMSProSEConfig.h
  EXPORT_MACRO_NAME OPENMSPROSE_DLLAPI)

install(TARGETS OpenMS_ProSE EXPORT OpenMSProSETargets
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/generated/OpenMS/ANALYSIS/ID/OpenMSProSEConfig.h
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/OpenMS/ANALYSIS/ID)
configure_package_config_file(cmake/OpenMSProSEConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/OpenMSProSEConfig.cmake
  INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/OpenMSProSE)
write_basic_package_version_file(${CMAKE_CURRENT_BINARY_DIR}/OpenMSProSEConfigVersion.cmake
  VERSION ${PROJECT_VERSION} COMPATIBILITY ExactVersion)
install(EXPORT OpenMSProSETargets NAMESPACE OpenMS::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/OpenMSProSE)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/OpenMSProSEConfig.cmake
  ${CMAKE_CURRENT_BINARY_DIR}/OpenMSProSEConfigVersion.cmake
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/OpenMSProSE)

if(BUILD_TESTING)
  add_executable(ProSEAlgorithm_test tests/source/ProSEAlgorithm_test.cpp ${OpenMS_TEST_SUPPORT_SOURCE})
  target_link_libraries(ProSEAlgorithm_test PRIVATE OpenMS::ProSE OpenMS::TestFramework)
  add_test(NAME ProSEAlgorithm_test COMMAND ProSEAlgorithm_test)

  set(OPENTIMS_DDA_TEST_DATA "" CACHE PATH "External Bruker DDA .d fixture for the ProSE integration test")
  set(OPENTIMS_TEST_FASTA "" CACHE FILEPATH "Matching FASTA database for the ProSE Bruker integration test")
  if(OPENTIMS_DDA_TEST_DATA OR OPENTIMS_TEST_FASTA)
    if(NOT OpenMS_WITH_OPENTIMS)
      message(FATAL_ERROR "ProSE Bruker integration requires an OpenMS SDK with Opentims enabled")
    endif()
    if(NOT IS_DIRECTORY "${OPENTIMS_DDA_TEST_DATA}" OR
       NOT EXISTS "${OPENTIMS_TEST_FASTA}" OR IS_DIRECTORY "${OPENTIMS_TEST_FASTA}")
      message(FATAL_ERROR "ProSE Bruker integration requires both OPENTIMS_DDA_TEST_DATA and OPENTIMS_TEST_FASTA")
    endif()
    add_executable(ProSEBrukerTims_test tests/source/ProSEBrukerTims_test.cpp ${OpenMS_TEST_SUPPORT_SOURCE})
    target_compile_definitions(ProSEBrukerTims_test PRIVATE
      OPENTIMS_DDA_TEST_DATA="${OPENTIMS_DDA_TEST_DATA}"
      OPENTIMS_TEST_FASTA="${OPENTIMS_TEST_FASTA}")
    target_link_libraries(ProSEBrukerTims_test PRIVATE OpenMS::ProSE OpenMS::TestFramework)
    add_test(NAME ProSEBrukerTims_test COMMAND ProSEBrukerTims_test)
  else()
    message(STATUS "ProSEBrukerTims_test not registered: external DDA and FASTA fixtures were not supplied")
  endif()
endif()

if(OPENMS_PROSE_BUILD_TOOL)
  openms4_find_package(OpenMSCLI)
  include(cmake/OpenMS4Tools.cmake)
  openms4_load_tools(package_tools)
  add_executable(ProSE src/ProSE.cpp)
  target_link_libraries(ProSE PRIVATE OpenMS::ProSE OpenMS::CLI)
  set_target_properties(ProSE PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/$<0:>")
  openms4_install_tools(prose bin ${package_tools})
endif()
