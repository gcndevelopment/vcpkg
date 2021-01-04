# Glib uses winapi functions not available in WindowsStore
vcpkg_fail_port_install(ON_TARGET "UWP")

# Glib relies on DllMain on Windows
if (VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_DYNAMIC_LIBRARY)
endif()

set(GLIB_VERSION 2.66.4)
vcpkg_download_distfile(ARCHIVE
    URLS "https://ftp.gnome.org/pub/gnome/sources/glib/2.66/glib-${GLIB_VERSION}.tar.xz"
    FILENAME "glib-${GLIB_VERSION}.tar.xz"
    SHA512 b3bc3e6e5cca793139848940e5c0894f1c7e3bd3a770b213a1ea548ac54a2432aebb140ed54518712fb8af36382b3b13d5f7ffd3d87ff63cba9e2f55434f7260)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${GLIB_VERSION}
    PATCHES
#        use-libiconv-on-windows.patch
#        arm64-defines.patch
 		meson.build.patch
)

configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt  ${SOURCE_PATH}/CMakeLists.txt COPYONLY)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/cmake DESTINATION ${SOURCE_PATH})
file(REMOVE_RECURSE ${SOURCE_PATH}/glib/pcre)
file(WRITE ${SOURCE_PATH}/glib/pcre/Makefile.in)

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

if (selinux IN_LIST FEATURES AND NOT VCPKG_TARGET_IS_WINDOWS AND NOT EXISTS "/usr/include/selinux")
    message("Selinux was not found in its typical system location. Your build may fail. You can install Selinux with \"apt-get install selinux\".")
endif()

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    selinux HAVE_SELINUX
)
if (VCPKG_TARGET_IS_WINDOWS OR VCPKG_TARGET_IS_OSX)
	vcpkg_configure_meson(
		SOURCE_PATH ${SOURCE_PATH}
		OPTIONS
        -DG_OS_WIN32=ON
		-Dinstalled_tests=false
	)
	vcpkg_install_meson()
endif() 

vcpkg_copy_pdbs()
file(GLOB EXEFILES_RELEASE ${CURRENT_PACKAGES_DIR}/bin/*.exe)
file(GLOB EXEFILES_DEBUG ${CURRENT_PACKAGES_DIR}/debug/bin/*.exe)
file(COPY ${EXEFILES_RELEASE} DESTINATION ${CURRENT_PACKAGES_DIR}/tools/${PORT})
file(REMOVE ${EXEFILES_RELEASE} ${EXEFILES_DEBUG})
file(GLOB CONFIGFILE ${CURRENT_PACKAGES_DIR}/lib/glib-2.0/include/glibconfig.h)
file(COPY ${CONFIGFILE} DESTINATION ${CURRENT_PACKAGES_DIR}/include/glib-2.0)
vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/${PORT})

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

configure_file(
    ${SOURCE_PATH}/cmake/unofficial-glib-config.in.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/cmake/unofficial-glib-config.cmake
    @ONLY
)

vcpkg_fixup_pkgconfig()
file(INSTALL ${CMAKE_CURRENT_BINARY_DIR}/cmake/unofficial-glib-config.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/unofficial-glib)
file(INSTALL ${CMAKE_CURRENT_LIST_DIR}/cmake/unofficial-glib-targets.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/unofficial-glib)
file(INSTALL ${CMAKE_CURRENT_LIST_DIR}/cmake/unofficial-glib-targets-debug.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/unofficial-glib)
file(INSTALL ${CMAKE_CURRENT_LIST_DIR}/cmake/unofficial-glib-targets-release.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/unofficial-glib)
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
