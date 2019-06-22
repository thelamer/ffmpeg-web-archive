FROM alpine:3.9 as fetch-stage

# environment variables
ARG SOURCE_FOLDER="/sources"
ARG TARS_FOLDER="/tmp/tarballs"

# versions
ENV \
 AOM=v1.0.0 \
 FDKAAC=0.1.5 \
 FONTCONFIG=2.13.91 \
 FREETYPE=2.8.1 \
 FRIBIDI=0.19.7 \
 KVAZAAR=1.2.0 \
 LAME=3.99.5 \
 LIBASS=0.14.0 \
 LIBDRM=2.4.98 \
 LIBVA=2.4.1 \
 LIBVDPAU=1.2 \
 LIBVIDSTAB=1.1.0 \
 NVCODEC=n9.0.18.1 \
 OGG=1.3.2 \
 OPENCOREAMR=0.1.5 \
 OPENJPEG=2.3.1 \
 OPUS=1.3 \
 THEORA=1.1.1 \
 VORBIS=1.3.6 \
 VPX=1.8.0 \
 X264=last_stable_x264 \
 X265=3.0 \
 XVID=1.3.4

# urls for source codes not using git pull. 
ARG NON_GIT_URL_LIST="\
https://github.com/mstorsjo/fdk-aac/archive/v${FDKAAC}.tar.gz \
https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG}.tar.bz2 \
https://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE}.tar.gz \
https://github.com/fribidi/fribidi/archive/${FRIBIDI}.tar.gz \
https://github.com/ultravideo/kvazaar/archive/v${KVAZAAR}.tar.gz \
http://downloads.sourceforge.net/project/lame/lame/3.99/lame-${LAME}.tar.gz \
https://github.com/libass/libass/archive/${LIBASS}.tar.gz \
https://dri.freedesktop.org/libdrm/libdrm-${LIBDRM}.tar.gz \
https://github.com/intel/libva/archive/${LIBVA}.tar.gz \
http://downloads.xiph.org/releases/ogg/libogg-${OGG}.tar.gz \
http://downloads.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-${OPENCOREAMR}.tar.gz \
https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG}.tar.gz \
https://archive.mozilla.org/pub/opus/opus-${OPUS}.tar.gz \
http://downloads.xiph.org/releases/theora/libtheora-${THEORA}.tar.gz \
https://github.com/georgmartius/vid.stab/archive/v${LIBVIDSTAB}.tar.gz \
http://downloads.xiph.org/releases/vorbis/libvorbis-${VORBIS}.tar.gz \
https://github.com/webmproject/libvpx/archive/v${VPX}.tar.gz \
https://download.videolan.org/pub/videolan/x264/snapshots/${X264}.tar.bz2 \
https://download.videolan.org/pub/videolan/x265/x265_${X265}.tar.gz \
http://downloads.xvid.org/downloads/xvidcore-${XVID}.tar.gz"


# install fetch packages
RUN \
 apk add --no-cache \
	bash \
	curl \
	bzip2 \
	git \
	wget \
	xz
	
# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# make folders
RUN \
 mkdir -p \
	"${SOURCE_FOLDER}" \
	${TARS_FOLDER}

RUN \
 echo "\n**** fetch git based source codes ****" && \
 git clone \
	--branch ${AOM} \
	--depth 1 https://aomedia.googlesource.com/aom \
	"${SOURCE_FOLDER}"/aom && \
 git clone \
        --branch ${NVCODEC} \
        --depth 1 https://git.videolan.org/git/ffmpeg/nv-codec-headers.git \
	"${SOURCE_FOLDER}"/ffnvcodec && \
 git clone \
	--branch libvdpau-${LIBVDPAU} \
	--depth 1 https://gitlab.freedesktop.org/vdpau/libvdpau.git \
	"${SOURCE_FOLDER}"/libvdpau && \
 echo -e "\n**** fetch non-git source codes ****" && \
 set -ex && \
 echo -e "\n$NON_GIT_URL_LIST" | tr " " "\\n" >> /tmp/non_git_url_list && \
 while read -r urls; do \
	FILE_EXTENSION=$(echo "$urls" | sed 's/.*\///'); \
	rm -f "${TARS_FOLDER}/${FILE_EXTENSION}"; \
	curl -o \
		"${TARS_FOLDER}/${FILE_EXTENSION}" -L -C - "$urls" \
		--max-time 40 \
		--retry 5 \
		--retry-delay 3 \
		--retry-max-time 240; \
	tar xf "${TARS_FOLDER}/${FILE_EXTENSION}" -C "${SOURCE_FOLDER}"; \
 done < /tmp/non_git_url_list && \
 echo -e "\n**** fetch and apply config.sub and config.guess for issues with arm64 builds. ****" && \
 curl -o "${TARS_FOLDER}/config.sub" -L -C - \
	'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD' \
		--max-time 40 \
		--retry 5 \
		--retry-delay 3 \
		--retry-max-time 240 && \
 curl -o "${TARS_FOLDER}/config.guess" -L -C - \
	'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' \
		--max-time 40 \
		--retry 5 \
		--retry-delay 3 \
		--retry-max-time 240 && \
 set +ex && \
 find "${SOURCE_FOLDER}"/ -name 'config.sub' -exec cp -v "${TARS_FOLDER}/config.sub" {} \; && \
 find "${SOURCE_FOLDER}"/ -name 'config.guess' -exec cp -v "${TARS_FOLDER}/config.guess" {} \; && \
 echo "**** cleanup ****" && \
 rm -rf \
	/tmp/*
