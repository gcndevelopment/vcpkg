# Glib uses winapi functions not available in WindowsStore
vcpkg_fail_port_install(ON_TARGET "UWP")

# Glib relies on DllMain on Windows
if (VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_DYNAMIC_LIBRARY)
endif()

set(GI_VERSION 1.64.1)
vcpkg_download_distfile(ARCHIVE
    URLS "https://ftp.gnome.org/pub/gnome/sources/gobject-introspection/1.64/gobject-introspection-${GI_VERSION}.tar.xz"
    FILENAME "gobject-introspection-${GI_VERSION}.tar.xz"
	SHA512 7610871f7ed5778ea9813062ed6465d131af58c00bdea1bb51dde7f98f459f44ae453eb6d0c5bdc6f7dcd92d639816f4e0773ccd5673cd065d22dabc6448647c
    )
# 1.64.1
# SHA512 7610871f7ed5778ea9813062ed6465d131af58c00bdea1bb51dde7f98f459f44ae453eb6d0c5bdc6f7dcd92d639816f4e0773ccd5673cd065d22dabc6448647c	
# 1.66.1	
# SHA512 ea1e20cd94ff8af3572f417f35e96648ffc3e94a91d4e4c81adf99bb0f408ac21ecf40990f9dbd5f2e0f4e83360286ca5db88dbc45bd59289596a324acf7df3d
vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${GI_VERSION}
)

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
set(ENV{PYTHON_PATH} "${PYTHON3}")
vcpkg_find_acquire_program(FLEX)
get_filename_component(FLEX_DIR "${FLEX}" DIRECTORY)

# ;${PYTHON3_DIR};${CURRENT_PACKAGES_DIR}/lib/pkgconfig;${CURRENT_PACKAGES_DIR}/lib;${CURRENT_PACKAGES_DIR}/bin
# meson will not find flex unless it's on the PATH
set(ENV{PATH} "${FLEX_DIR};$ENV{PATH}")
# meson needs to find the .pc files to link the libraries successfully
set(ENV{PKG_CONFIG_PATH} "${_VCPKG_INSTALLED_DIR}/${TARGET_TRIPLET}/lib/pkgconfig")
# even w/ the .pc files, the main lib dir still needs to be added to LIB 
set(ENV{LIB} "${_VCPKG_INSTALLED_DIR}/${TARGET_TRIPLET}/lib;$ENV{LIB}")
# Python.h will not be found without inclusion as an extra include directory 
set(ENV{_CL_} " /I${_VCPKG_INSTALLED_DIR}/${TARGET_TRIPLET}/include/python3.9")
# This is needed to help python find the DLLs needed as python 3.8+ has different dll search behavior then prior
set(ENV{GI_EXTRA_BASE_DLL_DIRS} "${_VCPKG_INSTALLED_DIR}/${TARGET_TRIPLET}/bin")

if (VCPKG_TARGET_IS_WINDOWS OR VCPKG_TARGET_IS_OSX)
	vcpkg_configure_meson(
		SOURCE_PATH ${SOURCE_PATH}
		OPTIONS
		-Dpython=${PYTHON3}
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
