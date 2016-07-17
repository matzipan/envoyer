#
# Main application
#

configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_BINARY_DIR}/config.vala)

set (APP_PKG_DEPS
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

set (APP_VALA_DEPS
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

pkg_check_modules (APP_DEPS REQUIRED ${APP_PKG_DEPS})

add_definitions(${APP_DEPS_CFLAGS})
link_libraries(${APP_DEPS_LIBRARIES})
link_directories(${APP_DEPS_LIBRARY_DIRS})

link_directories(${CMAKE_BINARY_DIR})
include_directories(${CMAKE_BINARY_DIR})
include_directories(${CMAKE_SOURCE_DIR})

set(APP_VALA_OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/bindings/vapi
    --metadatadir=${CMAKE_SOURCE_DIR}/bindings/metadata
    --thread
    --enable-checking
    --debug
    --enable-deprecated
    --target-glib=2.47.6
    ${EXTRA_VALA_OPTIONS}
)

vala_precompile(APP_VALA_C envoyer
	Main.vala
    Application.vala
	Services/Session.vala 
    Services/Settings.vala
	Services/IMessageViewerExtension.vala
	FutureGranite/ExpandableItem.vala
    FutureGranite/SimpleExpandableItem.vala
	FutureGranite/NestedListBox.vala
	FutureGranite/ThreePane.vala
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
    Widgets/MessageWebView.vala
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
	${APP_VALA_DEPS}
OPTIONS  
	${APP_VALA_OPTIONS}
GENERATE_HEADER
	envoyer
GENERATE_VAPI
	envoyer
)

add_executable(envoyer ${APP_VALA_C} ${generated_resources})

#
# WebKitWebExtension
#

set (WEBEXTENSION_PKG_DEPS
	gobject-2.0
	webkit2gtk-web-extension-4.0>=2.10.9
)

set (WEBEXTENSION_VALA_DEPS
	gobject-2.0
	webkit2gtk-web-extension-4.0>=2.10.9
)

find_package(PkgConfig)

pkg_check_modules (WEBEXTENSION_DEPS REQUIRED ${WEBEXTENSION_PKG_DEPS})

add_definitions(${WEBEXTENSION_DEPS_CFLAGS})
link_libraries(${WEBEXTENSION_DEPS_LIBRARIES})
link_directories(${WEBEXTENSION_DEPS_LIBRARY_DIRS})

link_directories(${CMAKE_BINARY_DIR})
include_directories(${CMAKE_BINARY_DIR})
include_directories(${CMAKE_SOURCE_DIR})

set(WEBEXTENSION_VALA_OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/bindings/vapi
    --metadatadir=${CMAKE_SOURCE_DIR}/bindings/metadata
    --thread
    --enable-checking
    --debug
    --enable-deprecated
    --target-glib=2.47.6
    ${EXTRA_VALA_OPTIONS}
)

vala_precompile(WEBEXTENSION_VALA_C envoyer-webextension
    Services/IMessageViewerExtension.vala
    Services/MessageViewerExtensionServer.vala
	WebExtensions/MessageViewerExtension.vala
    ${CMAKE_BINARY_DIR}/config.vala
PACKAGES
	${WEBEXTENSION_VALA_DEPS}
OPTIONS  
	${WEBEXTENSION_VALA_OPTIONS}
GENERATE_HEADER
	envoyer-webextension
GENERATE_VAPI
	envoyer-webextension
)

add_library(envoyer-webextension SHARED ${WEBEXTENSION_VALA_C} ${generated_resources})
