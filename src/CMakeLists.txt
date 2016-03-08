find_package(PkgConfig)
pkg_check_modules(GOBJECT REQUIRED gobject-2.0)
pkg_check_modules(GIO REQUIRED gio-2.0)
pkg_check_modules(CAMEL REQUIRED camel-1.2)
pkg_check_modules(EDS REQUIRED evolution-data-server-1.2)
pkg_check_modules(EBOOK REQUIRED libebook-1.2)
pkg_check_modules(EBOOK_CONTACTS REQUIRED libebook-contacts-1.2)
pkg_check_modules(SOUP REQUIRED libsoup-2.4)
pkg_check_modules(XML REQUIRED libxml-2.0)

set(CFLAGS
	${GOBJECT_CFLAGS} ${GOBJECT_CFLAGS_OTHER}
	${GIO_CFLAGS} ${GIO_CFLAGS_OTHER}
	${CAMEL_CFLAGS} ${CAMEL_CFLAGS_OTHER}
	${EDS_CFLAGS} ${EDS_CFLAGS_OTHER}
	${EBOOK_CFLAGS} ${EBOOK_CFLAGS_OTHER}
	${EBOOK_CONTACTS_CFLAGS} ${EBOOK_CONTACTS_CFLAGS_OTHER}
	${SOUP_CFLAGS} ${SOUP_CFLAGS_OTHER}
	${XML_CFLAGS} ${XML_CFLAGS_OTHER}
)
add_definitions(${CFLAGS})

set(LIBS
	${GOBJECT_LIBRARIES}
	${GIO_LIBRARIES}
	${CAMEL_LIBRARIES}
	${EDS_LIBRARIES}
	${EBOOK_LIBRARIES}
	${EBOOK_CONTACTS_LIBRARIES}
	${SOUP_LIBRARIES}
	${XML_LIBRARIES}
)
link_libraries(${LIBS})

set(LIB_PATHS
	${GOBJECT_LIBRARY_DIRS}
	${GIO_LIBRARY_DIRS}
	${CAMEL_LIBRARY_DIRS}
	${EDS_LIBRARY_DIRS}
	${EBOOK_CONTACTS_LIBRARY_DIRS}
	${SOUP_LIBRARY_DIRS}
	${XML_LIBRARY_DIRS}
)
link_directories(${LIB_PATHS})

set(VALAC_OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/bindings/vapi
    --metadatadir=${CMAKE_SOURCE_DIR}/bindings/metadata
    --thread
    --enable-checking
    --debug
    --enable-deprecated
    ${EXTRA_VALA_OPTIONS}
)

vala_precompile(VALA_C sample
	main.vala 
PACKAGES
	gio-2.0 
 	libebook-1.2
 	libebook-contacts-1.2
 	libedataserver-1.2
 	libsoup-2.4
 	libxml-2.0
 	camel-1.2
	posix 
OPTIONS  
	${VALAC_OPTIONS}
GENERATE_HEADER
	sample
GENERATE_VAPI
	sample
)

add_executable(sample ${VALA_C})
