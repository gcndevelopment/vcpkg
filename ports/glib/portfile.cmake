# Glib uses winapi functions not available in WindowsStore
vcpkg_fail_port_install(ON_TARGET "UWP")

# Glib relies on DllMain on Windows
if (VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_DYNAMIC_LIBRARY)
endif()

set(GLIB_VERSION 2.67.1)
vcpkg_download_distfile(ARCHIVE
    URLS "https://ftp.gnome.org/pub/gnome/sources/glib/2.67/glib-${GLIB_VERSION}.tar.xz"
    FILENAME "glib-${GLIB_VERSION}.tar.xz"
    SHA512 f7a576ab454633e6ad6ea00153a57f2f9d6bb20ec2c200fad43fe743192e3b912a7d4774e8c99594e3c53fa32853741c32a7df6c396226ea18c822e872c006dc)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    REF ${GLIB_VERSION}
    PATCHES
#        use-libiconv-on-windows.patch
        arm64-defines.patch
		meson.build.patch
)

configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt  ${SOURCE_PATH}/CMakeLists.txt COPYONLY)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/cmake DESTINATION ${SOURCE_PATH})
file(REMOVE_RECURSE ${SOURCE_PATH}/glib/pcre)
file(WRITE ${SOURCE_PATH}/glib/pcre/Makefile.in)
#file(REMOVE ${SOURCE_PATH}/glib/win_iconv.c)

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
file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
