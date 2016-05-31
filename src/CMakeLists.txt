configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_SOURCE_DIR}/src/config.vala)

set (PKG_DEPS
	gobject-2.0
    gio-2.0
    camel-1.2>=3.19.92
    evolution-data-server-1.2>=3.19.92
    libebook-1.2>=3.19.92
    libebook-contacts-1.2>=3.19.92
    libsoup-2.4
    libxml-2.0
    granite>=0.3
    gtksourceview-3.0>=3.10
    gthread-2.0
    gtk+-3.0>=3.9.10
)

set (VALA_DEPS
	gobject-2.0
    gio-2.0
    camel-1.2
    libebook-1.2
    libebook-contacts-1.2
    libedataserver-1.2
    libsoup-2.4
    libxml-2.0
    granite
    gtksourceview-3.0
    gtk+-3.0
	posix
)

find_package(PkgConfig)

pkg_check_modules (DEPS REQUIRED ${PKG_DEPS})

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

link_directories(${CMAKE_BINARY_DIR})
include_directories(${CMAKE_BINARY_DIR})
include_directories(${CMAKE_SOURCE_DIR})


set(VALA_OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/bindings/vapi
    --metadatadir=${CMAKE_SOURCE_DIR}/bindings/metadata
    --thread
    --enable-checking
    --debug
    --enable-deprecated
    --target-glib=2.47.6
    ${EXTRA_VALA_OPTIONS}
)

vala_precompile(VALA_C pantheon-mail-ng	
	Main.vala
    Application.vala
	Services/Session.vala 
    Services/Settings.vala
    Widgets/Headerbar.vala
    Widgets/FolderItem.vala
    Widgets/ExpandableItem.vala
    Widgets/SimpleExpandableItem.vala
    Widgets/UnifiedFolderParentItem.vala
    Widgets/UnifiedFolderChildItem.vala
    Widgets/AccountFoldersParentItem.vala
    Widgets/NestedListBox.vala
    Widgets/Sidebar.vala
	Widgets/ConversationItem.vala
	Widgets/FolderThreadsList.vala
    Widgets/Window.vala
    Models/Folder.vala
    Models/AccountSummary.vala
    Models/ConversationThread.vala
    config.vala
PACKAGES
	${VALA_DEPS}
OPTIONS  
	${VALA_OPTIONS}
GENERATE_HEADER
	pantheon-mail-ng
GENERATE_VAPI
	pantheon-mail-ng
)

add_executable(pantheon-mail-ng ${VALA_C} ${generated_resources})

