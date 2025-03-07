if(NOT WIN32 AND USE_MPEG)
	if(NOT MPEG_PATH AND NOT BUILD_STATIC)
		find_package(MPG123 QUIET)
		
		if(MPG123_FOUND)
			set(MPEG_SOURCE "(system)")
		endif()
	endif()
	if(MPEG_PATH OR BUILD_STATIC OR NOT MPG123_FOUND)
		FetchDependency(MPEG
			DIR mpg123
			DOWNLOAD https://downloads.sourceforge.net/mpg123/mpg123-1.28.2.tar.bz2
			SUBDIR mpg123-1.28.2
		)
		
		set(MPEG_LINK_PATH ${MPEG_BIN}/bin/usr/local/lib/libmpg123.a)
		
		if(NOT EXISTS ${MPEG_LINK_PATH})
			add_custom_target(MPEG_MAKE ALL
				COMMAND ./configure --enable-static=yes --enable-shared=no && make && make install DESTDIR="${MPEG_BIN}/bin" && make clean
				WORKING_DIRECTORY ${MPEG_PATH}
			)
		endif()
		
		add_library(mpg123 STATIC IMPORTED)
		set_target_properties(mpg123 PROPERTIES
			IMPORTED_LOCATION ${MPEG_LINK_PATH}
		)
	endif()
endif()
if(NOT USE_MPEG)
	unset(MPEG_SOURCE)
endif()
