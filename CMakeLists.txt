project (pantheon-mail-ng C)
cmake_minimum_required (VERSION 2.6)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/)
include (ValaPrecompile)
include (ValaVersion)

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/pantheon-mail-ng")
set (GETTEXT_PACKAGE "pantheon-mail-ng")
set (RELEASE_NAME "TARS")
set (VERSION "0.1")
set (VERSION_INFO "Development")
set (CMAKE_C_FLAGS "-ggdb")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$")
set (APP_NAME "Mail-ng")
set (PROJECT_FQDN "org.pantheon.mail-ng")
set (PROJECT_DESCRIPTION "Next gen components for the mail app")

# disable C compiler warnings
add_definitions (-w)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

find_package (Vala)

ensure_vala_version ("0.11.0" MINIMUM)

add_subdirectory (po)
add_subdirectory (schemas)
add_subdirectory (src)





install(TARGETS ${pantheon-mail-ng} RUNTIME
  DESTINATION bin)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/pantheon-mail-ng.desktop
  DESTINATION ${DATADIR}/applications/)

#install assets
file(GLOB assets "${CMAKE_CURRENT_SOURCE_DIR}/data/assets/*")
install (FILES ${assets}
DESTINATION ${DATADIR}/pantheon-mail-ng/)
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/data/pantheon-mail-ng.svg"
  DESTINATION ${DATADIR}/pixmaps/)
