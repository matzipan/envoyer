project (envoyer)
cmake_minimum_required (VERSION 3.5)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/)

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/envoyer")
set (GETTEXT_PACKAGE "envoyer")
set (RELEASE_NAME "")
set (VERSION "0.1")
set (VERSION_INFO "Development")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (APP_NAME "Envoyer")
set (PROJECT_FQDN "com.github.matzipan.envoyer")
set (WEBKIT_WEB_EXTENSION_DIRECTORY "${CMAKE_INSTALL_PREFIX}/lib/${PROJECT_FQDN}/")
set (DBUS_OBJECTS "/com/github/matzipan/envoyer")
set (PROJECT_DESCRIPTION "Mail for the Linux desktop")
set (DEBUG_LOGGING 0)

add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

include (ValaPrecompile)
include (ValaVersion)
find_package (Vala)

ensure_vala_version ("0.11.0" MINIMUM)

set (CMAKE_CXX_STANDARD 11)

find_program(CCACHE_FOUND ccache)
if(CCACHE_FOUND)
    message ("-- Using ccache")
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache) # Less useful to do it for linking, see edit2
endif(CCACHE_FOUND)

add_subdirectory (schemas)
add_subdirectory (lib/mailcore2/)
add_subdirectory (lib/basalt/)
add_subdirectory (src)

install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.matzipan.envoyer.desktop DESTINATION ${DATADIR}/applications/)
