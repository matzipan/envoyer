configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_BINARY_DIR}/config.vala)

set (PKG_DEPS
	gobject-2.0
    gio-2.0
    camel-1.2>=3.19.92
    evolution-data-server-1.2>=3.19.92
    libebook-1.2>=3.19.92
    libebook-contacts-1.2>=3.19.92
    libedataserver-1.2>=3.19.92
	libedataserverui-1.2>=3.19.92
    libsoup-2.4
    libxml-2.0
    granite>=0.3
    gthread-2.0
    gtk+-3.0>=3.9.10
	webkit2gtk-4.0>=2.10.9
)

set (VALA_DEPS
	gobject-2.0
    gio-2.0
    camel-1.2
    libebook-1.2
    libebook-contacts-1.2
    libedataserver-1.2
    libedataserverui-1.2
    libsoup-2.4
    libxml-2.0
    granite
    gtk+-3.0
	posix
	webkit2gtk-4.0>=2.10.9
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

vala_precompile(VALA_C envoyer
	Main.vala
    Application.vala
	Services/Session.vala 
    Services/Settings.vala
	FutureGranite/ExpandableItem.vala
    FutureGranite/SimpleExpandableItem.vala
	FutureGranite/NestedListBox.vala
	Util/SidebarBuilder.vala
	Parsers/ParserRegistry.vala
	Parsers/IParser.vala
	Parsers/MultipartAlternativeParser.vala
	Parsers/TextHtmlParser.vala
    Widgets/Headerbar.vala
    Widgets/FolderItem.vala
    Widgets/IFolderItem.vala
    Widgets/UnifiedFolderParentItem.vala
    Widgets/UnifiedFolderChildItem.vala
    Widgets/AccountFoldersParentItem.vala
    Widgets/ConversationViewer.vala
    Widgets/MessageViewer.vala
    Widgets/Sidebar.vala
	Widgets/ConversationItem.vala
	Widgets/FolderThreadsList.vala
	Widgets/FolderLabel.vala
    Widgets/Window.vala
    Models/Folder.vala
    Models/IFolder.vala
    Models/Message.vala
    Models/UnifiedFolderChild.vala
    Models/UnifiedFolderParent.vala
    Models/AccountSummary.vala
    Models/ConversationThread.vala
    ${CMAKE_BINARY_DIR}/config.vala
PACKAGES
	${VALA_DEPS}
OPTIONS  
	${VALA_OPTIONS}
GENERATE_HEADER
	envoyer
GENERATE_VAPI
	envoyer
)

add_executable(envoyer ${VALA_C} ${generated_resources})

