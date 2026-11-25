#----------------------------------------------------------------
# Generated CMake target import file for configuration "RelWithDebInfo".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "mysqlservices" for configuration "RelWithDebInfo"
set_property(TARGET mysqlservices APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(mysqlservices PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELWITHDEBINFO "C"
  IMPORTED_LOCATION_RELWITHDEBINFO "${_IMPORT_PREFIX}/lib/mysqlservices.lib"
  )

list(APPEND _cmake_import_check_targets mysqlservices )
list(APPEND _cmake_import_check_files_for_mysqlservices "${_IMPORT_PREFIX}/lib/mysqlservices.lib" )

# Import target "server" for configuration "RelWithDebInfo"
set_property(TARGET server APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(server PROPERTIES
  IMPORTED_IMPLIB_RELWITHDEBINFO "${_IMPORT_PREFIX}/lib/server.lib"
  )

list(APPEND _cmake_import_check_targets server )
list(APPEND _cmake_import_check_files_for_server "${_IMPORT_PREFIX}/lib/server.lib" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
