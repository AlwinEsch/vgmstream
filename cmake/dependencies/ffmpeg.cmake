if(USE_FFMPEG)
	if(NOT FFMPEG_PATH AND NOT BUILD_STATIC)
		# FFmpeg detection
		if(WIN32)
			find_package(FFmpeg)
		else()
			find_package(FFmpeg QUIET)
		endif()
		
		if(NOT FFMPEG_LIBRARIES)
			if(WIN32)
				set_ffmpeg(OFF TRUE)
			else()
				set(FFmpeg_FOUND NO)
			endif()
		else()
			if(${AVCODEC_VERSION} VERSION_LESS 57)
				if(WIN32)
					set_ffmpeg(OFF TRUE)
					message("libavcodec version mismatch ${AVCODEC_VERSION} expected >=57")
				else()
					set(FFmpeg_FOUND NO)
				endif()
			elseif(${AVUTIL_VERSION} VERSION_LESS 55)
				if(WIN32)
					set_ffmpeg(OFF TRUE)
					message("libavutil version mismatch ${AVUTIL_VERSION} expected >=55")
				else()
					set(FFmpeg_FOUND NO)
				endif()
			elseif(${SWRESAMPLE_VERSION} VERSION_LESS 2)
				if(WIN32)
					set_ffmpeg(OFF TRUE)
					message("libswresample version mismatch ${SWRESAMPLE_VERSION} expected >=2")
				else()
					set(FFmpeg_FOUND NO)
				endif()
			endif()
		endif()
		
		if(FFmpeg_FOUND)
			set(FFMPEG_SOURCE "(system)")
		endif()
	endif()
	if(USE_FFMPEG AND NOT WIN32 AND (NOT FFmpeg_FOUND OR FFMPEG_PATH OR BUILD_STATIC))
		set(USE_FFMPEG_LIBOPUS OFF)
		if(NOT EMSCRIPTEN)
			find_package(PkgConfig REQUIRED)
			pkg_check_modules(PC_OPUS QUIET opus>=1.1)
			if(PC_OPUS_FOUND)
				set(USE_FFMPEG_LIBOPUS ON)
			endif()
		endif()
		
		FetchDependency(FFMPEG
			DIR ffmpeg
			GIT_REPOSITORY https://git.ffmpeg.org/ffmpeg.git
			GIT_TAG n4.4
		)
		
		if(FFMPEG_PATH)
			set(FFMPEG_CONF_PARSER
				ac3 mpegaudio xma vorbis opus
			)
			set(FFMPEG_CONF_DEMUXER
				ac3 asf xwma mov oma ogg tak dsf wav aac dts dtshd mp3 bink flac msf xmv caf ape smacker pcm_s8 spdif mpc mpc8
			)
			set(FFMPEG_CONF_DECODER
				ac3 wmapro wmav1 wmav2 wmavoice wmalossless xma1 xma2 dca tak dsd_lsbf dsd_lsbf_planar dsd_mbf dsd_msbf_planar aac atrac3 atrac3p mp1float mp2float mp3float binkaudio_dct binkaudio_rdft flac pcm_s16be pcm_s16be_planar pcm_s16le pcm_s16le_planar vorbis ape adpcm_ima_qt smackaud pcm_s8 pcm_s8_planar mpc7 mpc8 alac adpcm_ima_dk3 adpcm_ima_dk4
			)
			if(USE_FFMPEG_LIBOPUS)
				list(APPEND FFMPEG_CONF_DECODER libopus)
			else()
				list(APPEND FFMPEG_CONF_DECODER opus)
			endif()
			set(FFMPEG_CONF_DISABLE_PARSER
				mpeg4video h263
			)
			set(FFMPEG_CONF_DISABLE_DECODER
				mpeg2video h263 h264 mpeg1video mpeg2video mpeg4 hevc vp9
			)
			string(REPLACE ";" "," FFMPEG_CONF_PARSER "${FFMPEG_CONF_PARSER}")
			string(REPLACE ";" "," FFMPEG_CONF_DEMUXER "${FFMPEG_CONF_DEMUXER}")
			string(REPLACE ";" "," FFMPEG_CONF_DECODER "${FFMPEG_CONF_DECODER}")
			string(REPLACE ";" "," FFMPEG_CONF_DISABLE_PARSER "${FFMPEG_CONF_DISABLE_PARSER}")
			string(REPLACE ";" "," FFMPEG_CONF_DISABLE_DECODER "${FFMPEG_CONF_DISABLE_DECODER}")
			set(FFMPEG_CONF_ARGS
				--enable-static
				--disable-shared
				--enable-gpl
				--disable-doc
				--disable-ffplay
				--disable-ffprobe
				--disable-avdevice
				--disable-ffmpeg
				--disable-postproc
				--disable-avfilter
				--disable-swscale
				--disable-network
				--disable-swscale-alpha
				--disable-vdpau
				--disable-dxva2
				--disable-amf
				--disable-cuda
				--disable-d3d11va
				--disable-ffnvcodec
				--disable-nvenc
				--disable-nvdec
				--disable-hwaccels
				--disable-sdl2
				--disable-iconv
				--disable-everything
				--enable-hwaccels
				--enable-swresample
				--enable-parser=${FFMPEG_CONF_PARSER}
				--enable-demuxer=${FFMPEG_CONF_DEMUXER}
				--enable-decoder=${FFMPEG_CONF_DECODER}
				--disable-parser=${FFMPEG_CONF_DISABLE_PARSER}
				--disable-decoder=${FFMPEG_CONF_DISABLE_DECODER}
				--disable-cuvid
				--disable-version3
				--extra-libs=-static
				--extra-cflags=--static
				--pkg-config-flags=--static
			)
			if(USE_FFMPEG_LIBOPUS)
				list(APPEND FFMPEG_CONF_ARGS
					--enable-libopus
				)
			endif()
			if(EMSCRIPTEN)
				list(APPEND FFMPEG_CONF_ARGS
					--cc=emcc
					--ranlib=emranlib
					--enable-cross-compile
					--target-os=none
					--arch=x86
					--disable-runtime-cpudetect
					--disable-asm
					--disable-fast-unaligned
					--disable-pthreads
					--disable-w32threads
					--disable-os2threads
					--disable-debug
					--disable-stripping
					--disable-safe-bitstream-reader
				)
			endif()
			
			set(FFMPEG_LINK_PATH ${FFMPEG_BIN}/bin/usr/local/lib)
			set(FFMPEG_INCLUDE_DIRS ${FFMPEG_BIN}/bin/usr/local/include)
			
			if(NOT EXISTS ${FFMPEG_LINK_PATH}/libavutil.a)
				if(EMSCRIPTEN)
					add_custom_target(FFMPEG_MAKE ALL
						COMMAND emconfigure ./configure ${FFMPEG_CONF_ARGS} && emmake make && make install DESTDIR="${FFMPEG_BIN}/bin" && make clean
						WORKING_DIRECTORY ${FFMPEG_PATH}
					)
				else()
					add_custom_target(FFMPEG_MAKE ALL
						COMMAND ./configure ${FFMPEG_CONF_ARGS} && make && make install DESTDIR="${FFMPEG_BIN}/bin" && make clean
						WORKING_DIRECTORY ${FFMPEG_PATH}
					)
				endif()
			endif()
			
			foreach(LIB avutil avformat swresample avcodec)
				add_library(${LIB} STATIC IMPORTED)
				set_target_properties(${LIB} PROPERTIES
					IMPORTED_LOCATION ${FFMPEG_LINK_PATH}/lib${LIB}.a
				)
			endforeach()
			
			if(EMSCRIPTEN)
				FetchDependency(ZLIB
					DIR zlib
					DOWNLOAD https://zlib.net/zlib-1.2.11.tar.xz
					SUBDIR zlib-1.2.11
				)
				
				add_subdirectory(${ZLIB_PATH} ${ZLIB_BIN})
				target_include_directories(example PRIVATE ${ZLIB_PATH})
				target_include_directories(minigzip PRIVATE ${ZLIB_PATH})
				target_include_directories(example64 PRIVATE ${ZLIB_PATH})
				target_include_directories(minigzip64 PRIVATE ${ZLIB_PATH})
				
				add_library(z STATIC IMPORTED)
				set_target_properties(z PROPERTIES
					IMPORTED_LOCATION ${ZLIB_BIN}/libz.a
				)
			endif()
		endif()
	endif()
endif()
if(NOT USE_FFMPEG)
	unset(FFMPEG_SOURCE)
endif()
