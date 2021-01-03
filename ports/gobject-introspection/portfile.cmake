# Glib uses winapi functions not available in WindowsStore
vcpkg_fail_port_install(ON_TARGET "UWP")

# Glib relies on DllMain on Windows
if (VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_DYNAMIC_LIBRARY)
endif()

set(GI_VERSION 1.66.1)
vcpkg_download_distfile(ARCHIVE
    URLS "https://ftp.gnome.org/pub/gnome/sources/gobject-introspection/1.66/gobject-introspection-${GI_VERSION}.tar.xz"
    FILENAME "gobject-introspection-${GI_VERSION}.tar.xz"
	SHA512 ea1e20cd94ff8af3572f417f35e96648ffc3e94a91d4e4c81adf99bb0f408ac21ecf40990f9dbd5f2e0f4e83360286ca5db88dbc45bd59289596a324acf7df3d
    )

vcpkg_find_acquire_program(FLEX)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${GI_VERSION}
)

if (VCPKG_TARGET_IS_WINDOWS OR VCPKG_TARGET_IS_OSX)
	vcpkg_configure_meson(
		SOURCE_PATH ${SOURCE_PATH}
	)
	vcpkg_install_meson()
    vcpkg_copy_pdbs()
	file(GLOB EXEFILES_RELEASE ${CURRENT_PACKAGES_DIR}/bin/*.exe)
	file(GLOB EXEFILES_DEBUG ${CURRENT_PACKAGES_DIR}/debug/bin/*.exe)
	file(COPY ${EXEFILES_RELEASE} DESTINATION ${CURRENT_PACKAGES_DIR}/tools/${PORT})
	file(REMOVE ${EXEFILES_RELEASE} ${EXEFILES_DEBUG})
	vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/${PORT})

	file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
	file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)
	vcpkg_fixup_pkgconfig()
endif() 

#file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
