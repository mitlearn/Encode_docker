# nohup docker build . -f /root/aur.Dockerfile -t vapoursynth-yuuno-codec:0.1 > run.log 2>&1 &

FROM archlinux:base as builder

ARG BUILD_DATE
LABEL Version='AUR Version'\
      MAINTAINER='Learning Enocder' \
      DESCRIPTTION='Bulid in ArchLinux；Driven by AUR; Built on ${BUILD_DATE}'

# RUN pacman -Syyu --noconfirm && \
#     pacman-key --init && \
#     pacman -Sy --noconfirm  --noprogressbar archlinux-keyring && \
#     pacman -Sy --noconfirm --needed base-devel git gcc go rust wget nano cmake meson nasm yasm cython ninja cargo
     # git clone https://github.com/FFmpeg/FFmpeg.git --branch release/4.4 --depth 1 /home/frds/build/ffmpeg && \
     # cd /home/frds/build/ffmpeg && \
     # ./configure --enable-gpl --enable-version3 --disable-static --enable-shared --disable-all --disable-autodetect --enable-avcodec --enable-avformat --enable-swresample --enable-swscale --disable-asm --disable-debug && \
     # make -j$(nproc) && make install

FROM thann/yay:latest AS codec
RUN yay -Sy --noconfirm svt-av1-git x264-tmod-git l-smash-x264-tmod-git x265-git


FROM thann/yay:latest AS vs
COPY ./yay* /tmp/
USER root
RUN pacman -Sy --noconfirm zimg vapoursynth && \
    rm -rf /usr/lib/vapoursynth/libmiscfilters.so
USER build
#     yay -Sya --noconfirm zimg vapoursynth-git && \
RUN yay -Sya --noconfirm $(cat /tmp/yaylist1.txt | grep -Ev '^$|#' | tr -s "\r\n" " ") && \
    yay -Sya --noconfirm $(cat /tmp/yaylist2.txt | grep -Ev '^$|#' | tr -s "\r\n" " ")


FROM archlinux:base AS main
## COPY Compile
COPY --from=codec /tmp/yay /tmp/yay/
COPY --from=vs /usr /usr
COPY --from=vs /tmp/yay /tmp/yay/
# COPY --from=vs /usr/lib/vapoursynth /usr/lib/vapoursynth/
RUN pacman -Sy --noconfirm --needed --noprogressbar python python-pip && \
    pacman -U /tmp/yay/**/*.pkg.* && rm -f /tmp && \
    pip3 install yuuno jupyterlab

ENV JUPYTER_CONFIG_DIR=/jupyter/config \
    JUPYTER_DATA_DIR=/jupyter/data \
    JUPYTER_RUNTIME_DIR=/jupyter/runtime

## configure docker
WORKDIR /jupyter

VOLUME /jupyter

EXPOSE 8888/tcp

## Start
CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root", "--NotebookApp.token='frds'"]
