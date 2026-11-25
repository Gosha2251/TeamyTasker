# Copyright (c) 2026, MariaDB plc
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1335  USA

SET(EXTERNAL_PLUGIN TRUE)
SET(SERVER_VERSION 11.4.14)
STRING(TOLOWER winx64 SYSTEM_NAME_AND_PROCESSOR)

GET_FILENAME_COMPONENT(basedir "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)

MACRO(DTRACE_INSTRUMENT)
ENDMACRO()
MACRO(ADD_VERSION_INFO)
ENDMACRO()
MACRO(MYSQL_INSTALL_TARGETS)
  INSTALL(TARGETS ${ARGV})
ENDMACRO()
MACRO(SET_PLUGIN_DEB_VERSION plugin ver)
  SET(CPACK_DEBIAN_PACKAGE_VERSION "1:${ver}+maria~${DEBIAN_ABBR}")
  SET(CPACK_DEBIAN_FILE_NAME "${CPACK_PACKAGE_NAME}-${ver}+maria~${DEBIAN_ABBR}_${DEBIAN_ARCH}.deb")
ENDMACRO()

ADD_LIBRARY(mariadb_private INTERFACE)
TARGET_INCLUDE_DIRECTORIES(mariadb_private INTERFACE ${basedir}/include/mysql/server/private)

INCLUDE(FeatureSummary)
INCLUDE("${CMAKE_CURRENT_LIST_DIR}/mariadb-plugin-targets.cmake")
INCLUDE("${CMAKE_CURRENT_LIST_DIR}/mariadb-plugin-defines.cmake")
TARGET_INCLUDE_DIRECTORIES(mysqlservices INTERFACE ${basedir}/include/mysql/server)

# Run at the beginning of MARIADB_ADD_PLUGIN
MACRO(EXTERNAL_PLUGIN_PRE)
  GET_PROPERTY(done GLOBAL PROPERTY done)
  IF(done)
    MESSAGE(FATAL_ERROR "Multiple MARIADB_ADD_PLUGIN() in the same project are not supported yet")
  ENDIF()
  SET_PROPERTY(GLOBAL PROPERTY done 1)
  IF (NOT ARG_COMPONENT)
    SET(ARG_COMPONENT ${target})
  ENDIF()
  IF (ARG_STATIC_ONLY OR PLUGIN_${plugin} MATCHES "STATIC")
    MESSAGE(FATAL_ERROR "Static plugin ${plugin} must be built from server source tree")
  ENDIF()
  IF(NOT ARG_AUTHOR)
    MESSAGE(FATAL_ERROR "Plugin ${plugin} has no AUTHOR")
  ENDIF()
  IF(NOT ARG_DESCRIPTION)
    MESSAGE(FATAL_ERROR "Plugin ${plugin} has no DESCRIPTION")
  ENDIF()
  IF(NOT ARG_VERSION)
    MESSAGE(FATAL_ERROR "Plugin ${plugin} has no VERSION")
  ENDIF()
  CMAKE_POLICY(PUSH)
  CMAKE_POLICY(SET CMP0048 NEW)
  PROJECT(${target} VERSION ${ARG_VERSION} DESCRIPTION "${ARG_DESCRIPTION}")
  CMAKE_POLICY(POP)
  SET(CPACK_PACKAGE_NAME "mariadb-plugin-${ARG_COMPONENT}")
  SET(CPACK_RPM_PACKAGE_NAME "MariaDB-plugin-${ARG_COMPONENT}")
  SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${ARG_DESCRIPTION}")
  SET(CPACK_RPM_PACKAGE_DESCRIPTION "${ARG_DESCRIPTION}")
  SET(CPACK_RPM_FILE_NAME RPM-DEFAULT)
  SET(CPACK_RPM_PACKAGE_LICENSE "GPLv2")
  SET(CPACK_RPM_PACKAGE_GROUP "Applications/Databases")
  SET(CPACK_RPM_PACKAGE_RELEASE "1%{?dist}")
  SET(CPACK_RPM_PACKAGE_VENDOR "${ARG_AUTHOR}")
  SET(CPACK_PACKAGE_RELOCATABLE FALSE)

  FOREACH(p ${INSTALL_PLUGINDIRABS} ${INSTALL_MYSQLTESTDIRABS}/plugin ${INSTALL_SYSCONF2DIR})
    WHILE(NOT prev STREQUAL ${p})
      LIST(APPEND CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION "${p}")
      SET(prev ${p})
      GET_FILENAME_COMPONENT(p "${p}" DIRECTORY)
    ENDWHILE()
  ENDFOREACH()

  SET(CPACK_DEBIAN_PACKAGE_MAINTAINER "${ARG_AUTHOR}")
  SET(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
  SET(CPACK_COMPONENTS_ALL TRUE) # for version-fiddling IF in plugin.cmake
  IF (DEB)
    # match autobake-deb.sh naming
    EXECUTE_PROCESS(COMMAND sh -c "echo $(lsb_release -si) $(lsb_release -sr)|sed 's/^\\(...\\)[^ ]* /\\L\\1/;s/\\.//g'"
	    RESULT_VARIABLE res OUTPUT_VARIABLE DEBIAN_ABBR OUTPUT_STRIP_TRAILING_WHITESPACE)
    EXECUTE_PROCESS(COMMAND sh -c "dpkg --print-architecture"
	    RESULT_VARIABLE res OUTPUT_VARIABLE DEBIAN_ARCH OUTPUT_STRIP_TRAILING_WHITESPACE)
    IF (NOT ("${DEBIAN_ABBR}_${DEBIAN_ARCH}" MATCHES "^(deb|ubu)[0-9]+_[a-z0-9_]+$"))
      message(FATAL_ERROR "Cannot get debian version (${DEBIAN_ABBR}) or architecture (${DEBIAN_ARCH})")
    endif()
  ENDIF()
ENDMACRO(EXTERNAL_PLUGIN_PRE)

# Run at the end of MARIADB_ADD_PLUGIN
MACRO(EXTERNAL_PLUGIN_POST)
  IF(ARG_RECOMPILE_FOR_EMBEDDED OR ARG_STORAGE_ENGINE)
    TARGET_LINK_LIBRARIES(${target} mariadb_private)
  ENDIF()
  SET(CPACK_RPM_PACKAGE_VERSION ${CPACK_RPM_${ARG_COMPONENT}_PACKAGE_VERSION})
  SET(CPACK_RPM_PACKAGE_REQUIRES  ${CPACK_RPM_${ARG_COMPONENT}_PACKAGE_REQUIRES})
  SET(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${SERVER_VERSION}-${ARG_VERSION}-${SYSTEM_NAME_AND_PROCESSOR}")

  IF (NOT RPM AND NOT DEB)
    FILE(WRITE "${CPACK_PACKAGE_FILE_NAME}.yml" "- name: ${target}
  filename: ${CPACK_PACKAGE_FILE_NAME}
  version: ${ARG_VERSION}
  server: ${SERVER_VERSION}
  platform: ${SYSTEM_NAME_AND_PROCESSOR}
  author: ${ARG_AUTHOR}
  description: ${ARG_DESCRIPTION}
  license: ${CPACK_RPM_PACKAGE_LICENSE}\n")
    INSTALL(FILES "${CPACK_PACKAGE_FILE_NAME}.yml" DESTINATION .)
  ENDIF()
ENDMACRO(EXTERNAL_PLUGIN_POST)

# Copyright (c) 2010, 2012, Oracle and/or its affiliates. All rights reserved.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1335  USA 

# The purpose of this file is to set the default installation layout.
#
# The current choices of installation layout are:
#
#  STANDALONE
#    Build with prefix=/usr/local/mysql, create tarball with install prefix="."
#    and relative links.  Windows zip uses the same tarball layout but without
#    the build prefix.
#
#  RPM
#    Build as per default RPM layout, with prefix=/usr
#
#  DEB
#    Build as per STANDALONE, prefix=/opt/mysql/server-$major.$minor
#
#  SVR4
#    Solaris package layout suitable for pkg* tools, prefix=/opt/mysql/mysql
#
# To force a directory layout, use -DINSTALL_LAYOUT=<layout>.
#
# The default is STANDALONE.
#
# There is the possibility to further fine-tune installation directories.
# Several variables can be overwritten:
#
# - INSTALL_BINDIR          (directory with client executables and scripts)
# - INSTALL_SBINDIR         (directory with mysqld)
# - INSTALL_SCRIPTDIR       (several scripts, rarely used)
# - INSTALL_SYSCONFDIR	    (my.cnf config file. Usually /etc or nothing)
# - INSTALL_SYSCONF2DIR     (additional config files, e.g. /etc/mysql/conf.d)
#
# - INSTALL_LIBDIR          (directory with client end embedded libraries)
# - INSTALL_PLUGINDIR       (directory for plugins)
#
# - INSTALL_INCLUDEDIR      (directory for MySQL headers)
#
# - INSTALL_DOCDIR          (documentation)
# - INSTALL_DOCREADMEDIR    (readme and similar)
# - INSTALL_MANDIR          (man pages)
# - INSTALL_INFODIR         (info pages)
#
# - INSTALL_SHAREDIR        (location of aclocal/mysql.m4)
# - INSTALL_MYSQLSHAREDIR   (MySQL character sets and localized error messages)
# - INSTALL_MYSQLTESTDIR    (mysql-test)
# - INSTALL_SQLBENCHDIR     (sql-bench)
# - INSTALL_SUPPORTFILESDIR (various extra support files)
#
# - INSTALL_MYSQLDATADIR    (data directory)
#
# - INSTALL_UNIX_ADDRDIR    (path to mysql.sock)
#
# - INSTALL_RUNDIR          (runtime state files that mariadbd must not write,
#                            e.g. what systemd reads as EnvironmentFile)
#

IF(NOT INSTALL_LAYOUT)
  IF(DEB)
    SET(INSTALL_LAYOUT "DEB")
  ELSEIF(RPM)
    SET(INSTALL_LAYOUT "RPM")
  ELSE()
    SET(INSTALL_LAYOUT "STANDALONE")
  ENDIF()
ENDIF()

SET(INSTALL_LAYOUT "${INSTALL_LAYOUT}"
CACHE STRING "Installation directory layout. Options are: STANDALONE (as in zip or tar.gz installer) RPM DEB SVR4")

IF(UNIX)
  IF(INSTALL_LAYOUT MATCHES "RPM")
    SET(default_prefix "/usr")
  ELSEIF(INSTALL_LAYOUT MATCHES "DEB")
    SET(default_prefix "/usr")
  ELSEIF(INSTALL_LAYOUT MATCHES "SVR4")
    SET(default_prefix "/opt/mysql/mysql")
  ELSE()
    SET(default_prefix "/usr/local/mysql")
  ENDIF()
  IF(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    SET(CMAKE_INSTALL_PREFIX ${default_prefix}
      CACHE PATH "install prefix" FORCE)
  ENDIF()
  SET(VALID_INSTALL_LAYOUTS "RPM" "STANDALONE" "DEB" "SVR4")
  LIST(FIND VALID_INSTALL_LAYOUTS "${INSTALL_LAYOUT}" ind)
  IF(ind EQUAL -1)
    MESSAGE(FATAL_ERROR "Invalid INSTALL_LAYOUT parameter:${INSTALL_LAYOUT}."
    " Choose between ${VALID_INSTALL_LAYOUTS}" )
  ENDIF()
ENDIF()

#
# STANDALONE layout
#
SET(INSTALL_BINDIR_STANDALONE           "bin")
SET(INSTALL_SBINDIR_STANDALONE          "bin")
SET(INSTALL_SCRIPTDIR_STANDALONE        "scripts")
#
SET(INSTALL_LIBDIR_STANDALONE           "lib")
SET(INSTALL_PLUGINDIR_STANDALONE        "lib/plugin")
#
SET(INSTALL_INCLUDEDIR_STANDALONE       "include/mysql")
#
SET(INSTALL_DOCDIR_STANDALONE           "docs")
SET(INSTALL_DOCREADMEDIR_STANDALONE     ".")
SET(INSTALL_MANDIR_STANDALONE           "man")
SET(INSTALL_INFODIR_STANDALONE          "docs")
#
SET(INSTALL_SHAREDIR_STANDALONE         "share")
SET(INSTALL_MYSQLSHAREDIR_STANDALONE    "share")
SET(INSTALL_MYSQLTESTDIR_STANDALONE     "mariadb-test")
SET(INSTALL_SQLBENCHDIR_STANDALONE      ".")
SET(INSTALL_SUPPORTFILESDIR_STANDALONE  "support-files")
#
SET(INSTALL_MYSQLDATADIR_STANDALONE     "data")

SET(INSTALL_UNIX_ADDRDIR_STANDALONE     "/tmp/mysql.sock")
SET(INSTALL_PAMDIR_STANDALONE           "share")
SET(INSTALL_PAMDATADIR_STANDALONE       "share")
#
# RPM layout
#
SET(INSTALL_BINDIR_RPM                  "bin")
SET(INSTALL_SBINDIR_RPM                 "sbin")
SET(INSTALL_SCRIPTDIR_RPM               "bin")
SET(INSTALL_SYSCONFDIR_RPM		"/etc")
SET(INSTALL_SYSCONF2DIR_RPM             "/etc/my.cnf.d")
#
IF(CMAKE_SIZEOF_VOID_P EQUAL 8)
  SET(INSTALL_LIBDIR_RPM                "lib64")
ELSE()
  SET(INSTALL_LIBDIR_RPM                "lib")
ENDIF()
SET(INSTALL_PLUGINDIR_RPM               "${INSTALL_LIBDIR_RPM}/mysql/plugin")
#
SET(INSTALL_INCLUDEDIR_RPM              "include/mysql")
#
SET(INSTALL_DOCDIR_RPM                  "share/doc")
SET(INSTALL_DOCREADMEDIR_RPM            "share/doc")
SET(INSTALL_INFODIR_RPM                 "share/info")
SET(INSTALL_MANDIR_RPM                  "share/man")
#
SET(INSTALL_SHAREDIR_RPM                "share")
SET(INSTALL_MYSQLSHAREDIR_RPM           "share/mariadb")
SET(INSTALL_MYSQLTESTDIR_RPM            "share/mariadb-test")
SET(INSTALL_SQLBENCHDIR_RPM             "")
SET(INSTALL_SUPPORTFILESDIR_RPM         "share/mariadb")
#
SET(INSTALL_MYSQLDATADIR_RPM            "/var/lib/mysql")

SET(INSTALL_UNIX_ADDRDIR_RPM            "${INSTALL_MYSQLDATADIR_RPM}/mysql.sock")
SET(INSTALL_SYSTEMD_UNITDIR_RPM         "/usr/lib/systemd/system")
SET(INSTALL_SYSTEMD_SYSUSERSDIR_RPM     "/usr/lib/sysusers.d")
SET(INSTALL_SYSTEMD_TMPFILESDIR_RPM     "/usr/lib/tmpfiles.d")
SET(INSTALL_RUNDIR_RPM                  "/run")
SET(INSTALL_PAMDIR_RPM                  "/${INSTALL_LIBDIR_RPM}/security")
SET(INSTALL_PAMDATADIR_RPM              "/etc/security")

#
# DEB layout
#
SET(INSTALL_BINDIR_DEB                  "bin")
SET(INSTALL_SBINDIR_DEB                 "sbin")
SET(INSTALL_SCRIPTDIR_DEB               "bin")
SET(INSTALL_SYSCONFDIR_DEB              "/etc")
SET(INSTALL_SYSCONF2DIR_DEB             "/etc/mysql/mariadb.conf.d")
#
SET(INSTALL_LIBDIR_DEB                  "lib/${CMAKE_CXX_LIBRARY_ARCHITECTURE}")
SET(INSTALL_PLUGINDIR_DEB               "lib/mysql/plugin")
#
SET(INSTALL_INCLUDEDIR_DEB              "include/mariadb")
#
SET(INSTALL_DOCDIR_DEB                  "share/doc")
SET(INSTALL_DOCREADMEDIR_DEB            "share/doc")
SET(INSTALL_MANDIR_DEB                  "share/man")
SET(INSTALL_INFODIR_DEB                 "share/info")
#
SET(INSTALL_SHAREDIR_DEB                "share")
SET(INSTALL_MYSQLSHAREDIR_DEB           "share/mariadb")
SET(INSTALL_MYSQLTESTDIR_DEB            "share/mariadb/mariadb-test")
SET(INSTALL_SQLBENCHDIR_DEB             ".")
SET(INSTALL_SUPPORTFILESDIR_DEB         "share/mariadb")
#
SET(INSTALL_MYSQLDATADIR_DEB            "/var/lib/mysql")

SET(INSTALL_RUNDIR_DEB                  "/run")
SET(INSTALL_UNIX_ADDRDIR_DEB            "${INSTALL_RUNDIR_DEB}/mysqld/mysqld.sock")
SET(INSTALL_SYSTEMD_UNITDIR_DEB         "/lib/systemd/system")
SET(INSTALL_SYSTEMD_SYSUSERSDIR_DEB     "/usr/lib/sysusers.d")
SET(INSTALL_SYSTEMD_TMPFILESDIR_DEB     "/usr/lib/tmpfiles.d")
SET(INSTALL_PAMDIR_DEB                  "/lib/${CMAKE_CXX_LIBRARY_ARCHITECTURE}/security")
SET(INSTALL_PAMDATADIR_DEB              "/etc/security")

#
# SVR4 layout
#
SET(INSTALL_BINDIR_SVR4                 "bin")
SET(INSTALL_SBINDIR_SVR4                "bin")
SET(INSTALL_SCRIPTDIR_SVR4              "scripts")
#
SET(INSTALL_LIBDIR_SVR4                 "lib")
SET(INSTALL_PLUGINDIR_SVR4              "lib/plugin")
#
SET(INSTALL_INCLUDEDIR_SVR4             "include/mysql")
#
SET(INSTALL_DOCDIR_SVR4                 "docs")
SET(INSTALL_DOCREADMEDIR_SVR4           ".")
SET(INSTALL_MANDIR_SVR4                 "man")
SET(INSTALL_INFODIR_SVR4                "docs")
#
SET(INSTALL_SHAREDIR_SVR4               "share")
SET(INSTALL_MYSQLSHAREDIR_SVR4          "share")
SET(INSTALL_MYSQLTESTDIR_SVR4           "mariadb-test")
SET(INSTALL_SQLBENCHDIR_SVR4            ".")
SET(INSTALL_SUPPORTFILESDIR_SVR4        "support-files")
#
SET(INSTALL_MYSQLDATADIR_SVR4           "/var/lib/mysql")

SET(INSTALL_UNIX_ADDRDIR_SVR            "/tmp/mysql.sock")

# Clear cached variables if install layout was changed
IF(OLD_INSTALL_LAYOUT)
  IF(NOT OLD_INSTALL_LAYOUT STREQUAL INSTALL_LAYOUT)
    SET(FORCE FORCE)
  ENDIF()
ENDIF()
SET(OLD_INSTALL_LAYOUT ${INSTALL_LAYOUT} CACHE INTERNAL "")

# Set INSTALL_FOODIR variables for chosen layout (for example, INSTALL_BINDIR
# will be defined  as ${INSTALL_BINDIR_STANDALONE} by default if STANDALONE
# layout is chosen)
GET_CMAKE_PROPERTY(ALL_VARS VARIABLES)
FOREACH (V ${ALL_VARS})
  IF (V MATCHES "^(INSTALL_([A-Z_0-9]+)DIR)_${INSTALL_LAYOUT}$")
    SET(var ${CMAKE_MATCH_1})
    SET(${var} "${${V}}" CACHE STRING "${CMAKE_MATCH_2} installation directory" ${FORCE})
    MARK_AS_ADVANCED(${var})

    IF(IS_ABSOLUTE "${${var}}")
      SET(${var}ABS "${${var}}")
    ELSE()
      SET(${var}ABS "${CMAKE_INSTALL_PREFIX}/${${var}}")
    ENDIF()
  ENDIF()
ENDFOREACH()

IF(NOT MYSQL_UNIX_ADDR)
  SET(MYSQL_UNIX_ADDR ${INSTALL_UNIX_ADDRDIR})
ENDIF()

IF(NOT INSTALL_RUNDIR)
  # No /run in a tarball installation - fall back to the socket directory.
  # Note that mariadbd can write there, so the isolation that /run gives to
  # packages (see EnvironmentFile= in mariadb.service) is not achieved.
  get_filename_component(MYSQL_UNIX_DIR ${MYSQL_UNIX_ADDR} DIRECTORY)
  SET(INSTALL_RUNDIR "${MYSQL_UNIX_DIR}" CACHE FILEPATH "Runtime state directory" ${FORCE})
ENDIF()


IF(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  SET(CMAKE_INSTALL_PREFIX ${basedir} CACHE PATH "install prefix" FORCE)
ENDIF()
IF(NOT INSTALL_SYSCONFDIR)
  SET(INSTALL_SYSCONFDIR  "etc")
  SET(INSTALL_SYSCONF2DIR "etc/my.cnf.d")
ENDIF()

# Copyright (c) 2009, 2018, Oracle and/or its affiliates.
# Copyright (c) 2011, 2019, MariaDB Corporation.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1335  USA

IF(NOT EXTERNAL_PLUGIN)
  STRING(CONCAT PARENT_SCOPE PARENT_SCOPE) # cannot use SET here
ENDIF()

FUNCTION(INSTALL_MYSQL_TEST from to)
  IF(INSTALL_MYSQLTESTDIR)
    IF(NOT WITH_WSREP)
      SET(EXCL_GALERA "(suite/(galera|wsrep|sys_vars/[rt]/(sysvars_)?wsrep).*|std_data/(galera|wsrep).*)")
    ELSE()
      SET(EXCL_GALERA "^DOES_NOT_EXIST$")
    ENDIF()
    INSTALL(
      DIRECTORY ${from}
      DESTINATION "${INSTALL_MYSQLTESTDIR}/${to}"
      USE_SOURCE_PERMISSIONS
      COMPONENT Test
      PATTERN "var" EXCLUDE
      PATTERN "lib/My/SafeProcess" EXCLUDE
      PATTERN "lib/t*" EXCLUDE
      PATTERN "CPack" EXCLUDE
      PATTERN "CMake*" EXCLUDE
      PATTERN "cmake_install.cmake" EXCLUDE
      PATTERN "mtr.out*" EXCLUDE
      PATTERN ".cvsignore" EXCLUDE
      PATTERN "*.am" EXCLUDE
      PATTERN "*.in" EXCLUDE
      PATTERN "Makefile" EXCLUDE
      PATTERN "*.vcxproj" EXCLUDE
      PATTERN "*.vcxproj.filters" EXCLUDE
      PATTERN "*.vcxproj.user" EXCLUDE
      PATTERN "CTest*" EXCLUDE
      PATTERN "*~" EXCLUDE
      REGEX "${EXCL_GALERA}" EXCLUDE
    )
  ENDIF()
ENDFUNCTION()

INCLUDE(CMakeParseArguments)

# MARIADB_ADD_PLUGIN(plugin_name source1...sourceN
# [STORAGE_ENGINE]
# [STATIC_ONLY|MODULE_ONLY]
# [MANDATORY|DEFAULT]
# [DISABLED]
# [NOT_EMBEDDED|RECOMPILE_FOR_EMBEDDED]
# [CLIENT]
# [MODULE_OUTPUT_NAME module_name]
# [STATIC_OUTPUT_NAME static_name]
# [COMPONENT component]
# [CONFIG cnf_file_name]
# [VERSION version_string]
# [LINK_LIBRARIES lib1...libN]
# [DEPENDS target1...targetN]

MACRO(MARIADB_ADD_PLUGIN)
  CMAKE_PARSE_ARGUMENTS(ARG
    "STORAGE_ENGINE;STATIC_ONLY;MODULE_ONLY;MANDATORY;DEFAULT;DISABLED;NOT_EMBEDDED;RECOMPILE_FOR_EMBEDDED;CLIENT"
    "MODULE_OUTPUT_NAME;STATIC_OUTPUT_NAME;COMPONENT;CONFIG;VERSION;AUTHOR;DESCRIPTION"
    "LINK_LIBRARIES;DEPENDS"
    ${ARGN}
  )
  IF(NOT WITHOUT_SERVER OR ARG_CLIENT)

  # Add common include directories
  INCLUDE_DIRECTORIES(${CMAKE_SOURCE_DIR}/include 
                    ${CMAKE_SOURCE_DIR}/sql
                    ${PCRE_INCLUDE_DIRS}
                    ${SSL_INCLUDE_DIRS}
                    ${ZLIB_INCLUDE_DIRS})

  LIST(GET ARG_UNPARSED_ARGUMENTS 0 plugin)
  SET(SOURCES ${ARG_UNPARSED_ARGUMENTS})
  LIST(REMOVE_AT SOURCES 0)
  STRING(TOUPPER ${plugin} plugin)
  STRING(TOLOWER ${plugin} target)

  IF (ARG_MANDATORY)
    UNSET(PLUGIN_${plugin} CACHE)
    SET(PLUGIN_${plugin} "YES")
  ELSE()
    SET (compat ".")
    # Figure out whether to build plugin.
    # recognize and support the maze of old WITH/WITHOUT combinations
    IF(WITHOUT_${plugin}_STORAGE_ENGINE
       OR WITHOUT_${plugin}
       OR WITHOUT_PLUGIN_${plugin}
       OR WITH_NONE)

      SET(compat "${compat}without")
    ENDIF()
    IF(WITH_${plugin}_STORAGE_ENGINE
       OR WITH_${plugin}
       OR WITH_PLUGIN_${plugin}
       OR WITH_ALL
       OR WITH_MAX
       OR WITH_MAX_NO_NDB
       OR ARG_DEFAULT)

      SET(compat "with${compat}")
    ENDIF()

    IF (ARG_DISABLED)
      SET(howtobuild NO)
    ELSEIF (compat STREQUAL ".")
      SET(howtobuild DYNAMIC)
    ELSEIF (compat STREQUAL "with.")
      IF (NOT ARG_MODULE_ONLY)
        SET(howtobuild STATIC)
      ELSE()
        SET(howtobuild DYNAMIC)
      ENDIF()
    ELSEIF (compat STREQUAL ".without")
      SET(howtobuild NO)
    ELSEIF (compat STREQUAL "with.without")
      SET(howtobuild STATIC)
    ENDIF()

    # NO - not at all
    # YES - static if possible, otherwise dynamic if possible, otherwise abort
    # AUTO - static if possible, otherwise dynamic, if possible
    # STATIC - static if possible, otherwise not at all
    # DYNAMIC - dynamic if possible, otherwise not at all
    SET(PLUGIN_${plugin} ${howtobuild}
      CACHE STRING "How to build plugin ${plugin}. Options are: NO STATIC DYNAMIC YES AUTO.")
  ENDIF()

  IF (NOT PLUGIN_${plugin} MATCHES "^(NO|YES|AUTO|STATIC|DYNAMIC)$")
    MESSAGE(FATAL_ERROR "Invalid value for PLUGIN_${plugin}")
  ENDIF()

  IF(EXTERNAL_PLUGIN)
    EXTERNAL_PLUGIN_PRE()
  ENDIF()

  # Validate that the requested build mode is compatible with what the
  # plugin actually supports. STATIC_ONLY plugins cannot be built as
  # dynamic modules, and MODULE_ONLY plugins cannot be linked statically.
  IF(PLUGIN_${plugin} STREQUAL "DYNAMIC" AND ARG_STATIC_ONLY)
    MESSAGE(FATAL_ERROR "Plugin ${plugin} is STATIC_ONLY and cannot be built"
      " with -DPLUGIN_${plugin}=DYNAMIC. Remove this option or use STATIC.")
  ELSEIF(PLUGIN_${plugin} STREQUAL "STATIC" AND ARG_MODULE_ONLY)
    MESSAGE(FATAL_ERROR "Plugin ${plugin} is MODULE_ONLY and cannot be built"
      " with -DPLUGIN_${plugin}=STATIC. Remove this option or use DYNAMIC.")
  ENDIF()

  IF(ARG_STORAGE_ENGINE)
    SET(with_var "WITH_${plugin}_STORAGE_ENGINE" )
  ELSE()
    SET(with_var "WITH_${plugin}")
  ENDIF()
  UNSET(${with_var} CACHE)

  IF(NOT ARG_DEPENDS)
    SET(ARG_DEPENDS)
  ENDIF()
  IF(NOT EXTERNAL_PLUGIN)
    SET(ARG_DEPENDS GenError ${ARG_DEPENDS})
  ENDIF()

  SET(definitions ";PLUGIN_NAME=\"${target}\";PLUGIN_LICENSE=PLUGIN_LICENSE_GPL")
  IF(ARG_VERSION)
    IF(NOT ARG_VERSION MATCHES "^([0-9]+)\\.([0-9]+)" OR CMAKE_MATCH_2 GREATER 255)
      MESSAGE(FATAL_ERROR "Plugin ${plugin} has invalid VERSION")
    ENDIF()
    SET(definitions "${definitions};PLUGIN_VERSION=\"${ARG_VERSION}\";PLUGIN_HEX_VERSION=${CMAKE_MATCH_1}*256+${CMAKE_MATCH_2}")
  ENDIF()
  IF(ARG_AUTHOR)
    SET(definitions "${definitions};PLUGIN_AUTHOR=\"${ARG_AUTHOR}\"")
  ENDIF()
  IF(ARG_DESCRIPTION)
    SET(definitions "${definitions};PLUGIN_DESCRIPTION=\"${ARG_DESCRIPTION}\"")
  ENDIF()

  IF(NOT ARG_MODULE_OUTPUT_NAME)
    IF(ARG_STORAGE_ENGINE)
      SET(ARG_MODULE_OUTPUT_NAME "ha_${target}")
    ELSE()
      SET(ARG_MODULE_OUTPUT_NAME "${target}")
    ENDIF()
  ENDIF()

  # Build either static library or module
  IF (PLUGIN_${plugin} MATCHES "(STATIC|AUTO|YES)" AND NOT ARG_MODULE_ONLY
      AND NOT ARG_CLIENT)

    IF(CMAKE_GENERATOR MATCHES "Makefiles|Ninja")
      # If there is a shared library from previous shared build,
      # remove it. This is done just for mysql-test-run.pl 
      # so it does not try to use stale shared lib as plugin 
      # in test.
      FILE(REMOVE 
        ${CMAKE_CURRENT_BINARY_DIR}/${ARG_MODULE_OUTPUT_NAME}${CMAKE_SHARED_MODULE_SUFFIX})
    ENDIF()

    ADD_LIBRARY(${target} STATIC ${SOURCES})
    DTRACE_INSTRUMENT(${target})
    ADD_DEPENDENCIES(${target} ${ARG_DEPENDS})
    RESTRICT_SYMBOL_EXPORTS(${target})
    IF(WITH_EMBEDDED_SERVER AND (NOT ARG_NOT_EMBEDDED))
      # Embedded library should contain PIC code and be linkable
      # to shared libraries (on systems that need PIC)
      IF(ARG_RECOMPILE_FOR_EMBEDDED OR NOT _SKIP_PIC)
        # Recompile some plugins for embedded
        ADD_CONVENIENCE_LIBRARY(${target}_embedded ${SOURCES})
        RESTRICT_SYMBOL_EXPORTS(${target}_embedded)
        DTRACE_INSTRUMENT(${target}_embedded)   
        IF(ARG_RECOMPILE_FOR_EMBEDDED)
          SET_TARGET_PROPERTIES(${target}_embedded 
            PROPERTIES COMPILE_DEFINITIONS "EMBEDDED_LIBRARY${definitions}")
        ENDIF()
        ADD_DEPENDENCIES(${target}_embedded ${ARG_DEPENDS})
        IF(ARG_LINK_LIBRARIES)
          TARGET_LINK_LIBRARIES (${target}_embedded ${ARG_LINK_LIBRARIES})
        ENDIF()
      ENDIF()
    ENDIF()

    IF(ARG_STATIC_OUTPUT_NAME)
      SET_TARGET_PROPERTIES(${target} PROPERTIES 
      OUTPUT_NAME ${ARG_STATIC_OUTPUT_NAME})
    ENDIF()

    IF(ARG_LINK_LIBRARIES)
      TARGET_LINK_LIBRARIES (${target} ${ARG_LINK_LIBRARIES})
    ENDIF()

    SET(${with_var} ON CACHE INTERNAL "Link ${plugin} statically to the server" FORCE)

    # Update mysqld dependencies
    SET (MYSQLD_STATIC_PLUGIN_LIBS ${MYSQLD_STATIC_PLUGIN_LIBS} 
      ${target} ${ARG_LINK_LIBRARIES} CACHE INTERNAL "" FORCE)

    IF(WITH_EMBEDDED_SERVER AND (NOT ARG_NOT_EMBEDDED))
      SET (EMBEDDED_PLUGIN_LIBS ${EMBEDDED_PLUGIN_LIBS}
      ${target} ${ARG_LINK_LIBRARIES} CACHE INTERNAL "" FORCE)
    ENDIF()

    IF(ARG_NOT_EMBEDDED)
      SET(builtin_entry "#ifndef EMBEDDED_LIBRARY\n builtin_maria_${target}_plugin,\n#endif")
    ELSE()
      SET(builtin_entry " builtin_maria_${target}_plugin,")
    ENDIF()

    IF(ARG_MANDATORY)
      SET (mysql_mandatory_plugins  
        "${mysql_mandatory_plugins}${builtin_entry}\n")
      SET (mysql_mandatory_plugins ${mysql_mandatory_plugins} ${PARENT_SCOPE})
    ELSE()
      SET (mysql_optional_plugins  
        "${mysql_optional_plugins}${builtin_entry}\n")
      SET (mysql_optional_plugins ${mysql_optional_plugins} ${PARENT_SCOPE})
    ENDIF()
  ELSEIF(PLUGIN_${plugin} MATCHES "(DYNAMIC|AUTO|YES)"
         AND NOT ARG_STATIC_ONLY AND NOT WITHOUT_DYNAMIC_PLUGINS)

    ADD_VERSION_INFO(${target} MODULE SOURCES)
    ADD_LIBRARY(${target} MODULE ${SOURCES}) 
    DTRACE_INSTRUMENT(${target})

    SET_TARGET_PROPERTIES (${target} PROPERTIES PREFIX "")
    IF (NOT ARG_CLIENT)
      SET_TARGET_PROPERTIES (${target} PROPERTIES
        COMPILE_DEFINITIONS "MYSQL_DYNAMIC_PLUGIN${definitions}")
    ENDIF()

    TARGET_LINK_LIBRARIES (${target} mysqlservices ${ARG_LINK_LIBRARIES})

    IF(WIN32)
      # A popular library, turns out many plugins need it for gethostname()
      TARGET_LINK_LIBRARIES (${target} ws2_32)
    ENDIF()

    IF(CMAKE_SYSTEM_NAME MATCHES AIX)
      TARGET_LINK_OPTIONS(${target} PRIVATE "-Wl,-bE:${CMAKE_SOURCE_DIR}/libservices/mysqlservices_aix.def")
    ENDIF()

    # Server plugins use symbols defined in mysqld executable.
    # Some operating systems like Windows and OSX and are pretty strict about 
    # unresolved symbols. Others are less strict and allow unresolved symbols
    # in shared libraries. On Linux for example, CMake does not even add 
    # executable to the linker command line (it would result into link error). 
    # Thus we skip TARGET_LINK_LIBRARIES on Linux, as it would only generate
    # an additional dependency.
    IF(ARG_RECOMPILE_FOR_EMBEDDED OR ARG_STORAGE_ENGINE)
      IF(MSVC OR CMAKE_SYSTEM_NAME MATCHES AIX)
        TARGET_LINK_LIBRARIES(${target} server)
      ELSEIF(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
        TARGET_LINK_LIBRARIES (${target} mariadbd)
      ENDIF()
    ELSEIF(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND NOT WITH_ASAN AND NOT WITH_TSAN AND NOT WITH_UBSAN AND NOT WITH_MSAN)
      TARGET_LINK_LIBRARIES (${target} "-Wl,--no-undefined")
    ENDIF()

    IF (ARG_DEPENDS)
      ADD_DEPENDENCIES(${target} ${ARG_DEPENDS})
    ENDIF()

    SET_TARGET_PROPERTIES(${target} PROPERTIES 
      OUTPUT_NAME "${ARG_MODULE_OUTPUT_NAME}")  
    # Install dynamic library
    IF(ARG_COMPONENT)
      IF(CPACK_COMPONENTS_ALL AND
         NOT CPACK_COMPONENTS_ALL MATCHES ${ARG_COMPONENT}
         AND INSTALL_SYSCONF2DIR)
        IF (ARG_STORAGE_ENGINE OR ARG_RECOMPILE_FOR_EMBEDDED)
          IF(RPM)
            STRING(REPLACE "-" "_" ver ${SERVER_VERSION})
            SET(ver " = ${ver}-%{release}")
          ELSE() # DEB
	    SET(ver " (= 1:${SERVER_VERSION}+maria~${DEBIAN_ABBR})")
          ENDIF()
        ELSE()
          SET(ver "")
        ENDIF()
        STRING(TOUPPER ${ARG_COMPONENT} ARG_COMPONENT_UPPER)
        SET(CPACK_COMPONENT_${ARG_COMPONENT_UPPER}SYMLINKS_GROUP ${ARG_COMPONENT} ${PARENT_SCOPE})
        SET(CPACK_COMPONENT_${ARG_COMPONENT_UPPER}_GROUP ${ARG_COMPONENT} ${PARENT_SCOPE})
        SET(CPACK_COMPONENTS_ALL ${CPACK_COMPONENTS_ALL} ${ARG_COMPONENT} ${ARG_COMPONENT}Symlinks)
        SET(CPACK_COMPONENTS_ALL ${CPACK_COMPONENTS_ALL} ${PARENT_SCOPE})

        IF (NOT ARG_CLIENT)
          SET(CPACK_RPM_${ARG_COMPONENT}_PACKAGE_REQUIRES "MariaDB-server${ver}" ${PARENT_SCOPE})
          SET(CPACK_DEBIAN_PACKAGE_DEPENDS "mariadb-server${ver}")
        ENDIF()
        SET(CPACK_RPM_${ARG_COMPONENT}_USER_FILELIST ${ignored} ${PARENT_SCOPE})
        IF (ARG_VERSION)
          SET(CPACK_RPM_${ARG_COMPONENT}_PACKAGE_VERSION ${SERVER_VERSION}_${ARG_VERSION} ${PARENT_SCOPE})
          SET_PLUGIN_DEB_VERSION(${target} ${SERVER_VERSION}-${ARG_VERSION})
        ENDIF()
        IF(NOT ARG_CLIENT AND UNIX)
          IF (NOT ARG_CONFIG)
            SET(ARG_CONFIG "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/${target}.cnf")
            FILE(WRITE ${ARG_CONFIG} "[mariadb]\nplugin-load-add=${ARG_MODULE_OUTPUT_NAME}.so\n")
          ENDIF()
          SET(CPACK_RPM_${ARG_COMPONENT}_USER_FILELIST ${ignored} "%config(noreplace) ${INSTALL_SYSCONF2DIR}/*" ${PARENT_SCOPE})
          SET(CPACK_RPM_${ARG_COMPONENT}_POST_INSTALL_SCRIPT_FILE ${CMAKE_SOURCE_DIR}/support-files/rpm/plugin-postin.sh ${PARENT_SCOPE})
          SET(CPACK_RPM_${ARG_COMPONENT}_POST_TRANS_SCRIPT_FILE ${CMAKE_SOURCE_DIR}/support-files/rpm/server-posttrans.sh ${PARENT_SCOPE})
        ENDIF()
      ENDIF()
    ELSE()
      SET(ARG_COMPONENT Server)
    ENDIF()
    MYSQL_INSTALL_TARGETS(${target} DESTINATION ${INSTALL_PLUGINDIR} COMPONENT ${ARG_COMPONENT})
    IF(ARG_CONFIG AND INSTALL_SYSCONF2DIR)
      INSTALL(FILES ${ARG_CONFIG} COMPONENT ${ARG_COMPONENT} DESTINATION ${INSTALL_SYSCONF2DIR})
    ENDIF()
  ENDIF()

  IF(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/mysql-test")
    INSTALL_MYSQL_TEST("${CMAKE_CURRENT_SOURCE_DIR}/mysql-test/" "plugin/${target}")
  ENDIF()

  IF(TARGET ${target})
    GET_TARGET_PROPERTY(plugin_type ${target} TYPE)
    STRING(REPLACE "_LIBRARY" "" plugin_type ${plugin_type})
    SET(have_target 1)
  ELSE()
    SET(plugin_type)
    SET(have_target 0)
  ENDIF()
  IF(ARG_STORAGE_ENGINE)
    ADD_FEATURE_INFO(${plugin} ${have_target} "Storage Engine ${plugin_type}")
  ELSEIF(ARG_CLIENT)
    ADD_FEATURE_INFO(${plugin} ${have_target} "Client plugin ${plugin_type}")
  ELSE()
    ADD_FEATURE_INFO(${plugin} ${have_target} "Server plugin ${plugin_type}")
  ENDIF()
  IF (EXTERNAL_PLUGIN)
    EXTERNAL_PLUGIN_POST()
  ENDIF()
  ENDIF(NOT WITHOUT_SERVER OR ARG_CLIENT)
ENDMACRO()

MACRO(MYSQL_ADD_PLUGIN)
  MARIADB_ADD_PLUGIN(${ARGV})
ENDMACRO()

# verify that all -DPLUGIN_xxx=YES plugins are being built
MACRO(VERIFY_PLUGINS)
  GET_CMAKE_PROPERTY(ALL_VARS VARIABLES)
  FOREACH (V ${ALL_VARS})
    IF (V MATCHES "^PLUGIN_")
      IF (${V} STREQUAL "YES")
        STRING(SUBSTRING ${V} 7 -1 plugin)
        STRING(TOLOWER ${plugin} target)
        IF (NOT TARGET ${target})
          MESSAGE(FATAL_ERROR "Plugin ${plugin} cannot be built")
        ENDIF()
      ENDIF()
    ENDIF()
  ENDFOREACH()
ENDMACRO()


IF(RPM)
  set(CPACK_GENERATOR "RPM")
ELSEIF(DEB)
  set(CPACK_GENERATOR "DEB")
ELSEIF(WIN32)
  set(CPACK_GENERATOR "ZIP")
ELSE()
  set(CPACK_GENERATOR "TGZ")
ENDIF()
