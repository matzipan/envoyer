configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_BINARY_DIR}/config.vala)
configure_file (${CMAKE_SOURCE_DIR}/src/Services/IMessageViewerExtension.vala ${CMAKE_BINARY_DIR}/src/Services/IMessageViewerExtension.vala)
configure_file (${CMAKE_SOURCE_DIR}/src/Services/MessageViewerExtensionServer.vala ${CMAKE_BINARY_DIR}/src/Services/MessageViewerExtensionServer.vala)

set (APP_PKG_DEPS
	gobject-2.0
	gio-2.0
	libsoup-2.4
	libxml-2.0
	granite>=0.3
	gthread-2.0
	gtk+-3.0>=3.9.10
	webkit2gtk-4.0>=2.10.9
	libgda-5.0
)

set (APP_VALA_DEPS
	gobject-2.0
	gio-2.0
	libsoup-2.4
	libxml-2.0
	granite
	gtk+-3.0
	posix
	webkit2gtk-4.0>=2.10.9
	libgda-5.0
)

find_package (PkgConfig)

pkg_check_modules (APP_DEPS REQUIRED ${APP_PKG_DEPS})

add_definitions (${APP_DEPS_CFLAGS})
link_libraries (${APP_DEPS_LIBRARIES})
link_directories (${APP_DEPS_LIBRARY_DIRS})

link_directories (${CMAKE_BINARY_DIR})
include_directories (${CMAKE_BINARY_DIR})
include_directories (${CMAKE_SOURCE_DIR})
include_directories (${CMAKE_BINARY_DIR}/lib/mailcore2/src/include)
include_directories (${CMAKE_BINARY_DIR}/lib/basalt/lib)

set (APP_VALA_OPTIONS
	--thread
	--enable-checking
	--vapidir=${CMAKE_SOURCE_DIR}/vapi
	--debug
	--target-glib=2.47.6
	--disable-since-check
	${EXTRA_VALA_OPTIONS}
)

vala_precompile (APP_VALA_C envoyer
	main.vala
	Controllers/Application.vala
	Controllers/Database.vala
	FutureGranite/ThreePane.vala
	FutureGranite/HumanDateTime.vala
	Util/SidebarBuilder.vala
	Util/ThreadingHelper.vala
	Widgets/Main/Headerbar.vala
	Widgets/Main/Sidebar/AccountFoldersParentItem.vala
	Widgets/Main/Sidebar/FolderItem.vala
	Widgets/Main/Sidebar/IFolderItem.vala
	Widgets/Main/Sidebar/UnifiedFolderParentItem.vala
	Widgets/Main/Sidebar/UnifiedFolderChildItem.vala
	Widgets/Main/Sidebar/Wrapper.vala
	Widgets/Main/ConversationViewer.vala
	Widgets/Main/MessageViewer.vala
	Widgets/Main/MessageWebView.vala
	Widgets/Main/FolderConversationItem.vala
	Widgets/Main/FolderConversationsList.vala
	Widgets/Main/Window.vala
	Widgets/Composer/Headerbar.vala
	Widgets/Composer/Window.vala
	Widgets/Gravatar.vala
	Models/Settings.vala
	Models/Folder.vala
	Models/IFolder.vala
	Models/Message.vala
	Models/Sidebar/AccountFoldersParent.vala
	Models/Sidebar/UnifiedFolderChild.vala
	Models/Sidebar/UnifiedFolderParent.vala
	Models/AccountSummary.vala
	Models/Address.vala
	Models/ConversationThread.vala
	Models/Identity.vala
	${CMAKE_BINARY_DIR}/src/Services/IMessageViewerExtension.vala
	${CMAKE_BINARY_DIR}/config.vala
PACKAGES
	${APP_VALA_DEPS}
OPTIONS
	${APP_VALA_OPTIONS}
CUSTOM_VAPIS
	MailCoreInterface/smtp.vapi
	MailCoreInterface/imap.vapi
	${CMAKE_BINARY_DIR}/lib/basalt/lib/basalt.vapi
GENERATE_HEADER
	envoyer
GENERATE_VAPI
	envoyer
)

add_executable (envoyer
	${APP_VALA_C}
	${generated_resources}
	MailCoreInterface/imap.cpp
	MailCoreInterface/imap_fetch_folders.cpp
	MailCoreInterface/imap_fetch_messages.cpp
	MailCoreInterface/imap_html_rendering.cpp
	MailCoreInterface/smtp.cpp
)

target_link_libraries (envoyer
	z
	basalt
	MailCore
	${APP_DEPS_LIBRARIES}
	${LIBETPAN_LIBRARY}
	${CTEMPLATE_LIBRARY}
	${TIDY_LIBRARY}
	${LIBXML_LIBRARY}
	crypto
	pthread
	uuid
	icuuc
	icui18n
)

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

find_package (PkgConfig)

pkg_check_modules (WEBEXTENSION_DEPS REQUIRED ${WEBEXTENSION_PKG_DEPS})

add_definitions (${WEBEXTENSION_DEPS_CFLAGS})
link_libraries (${WEBEXTENSION_DEPS_LIBRARIES})
link_directories (${WEBEXTENSION_DEPS_LIBRARY_DIRS})

link_directories (${CMAKE_BINARY_DIR})
include_directories (${CMAKE_BINARY_DIR})
include_directories (${CMAKE_SOURCE_DIR})

set (WEBEXTENSION_VALA_OPTIONS
	--thread
	--enable-checking
	--debug
	--target-glib=2.47.6
	${EXTRA_VALA_OPTIONS}
)

vala_precompile (WEBEXTENSION_VALA_C envoyer-webextension
	WebExtensions/MessageViewerExtension.vala
	${CMAKE_BINARY_DIR}/src/Services/IMessageViewerExtension.vala
	${CMAKE_BINARY_DIR}/src/Services/MessageViewerExtensionServer.vala
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

add_library (envoyer-webextension SHARED ${WEBEXTENSION_VALA_C} ${generated_resources})
