# nohup docker build . -f /root/aur.Dockerfile -t vapoursynth-yuuno-codec:0.1 > run.log 2>&1 &

# FROM archlinux:base-devel as builder

# ARG BUILD_DATE
# LABEL Version='AUR Version'\
#       MAINTAINER='Learning Enocder' \
#       DESCRIPTTION='Bulid in ArchLinux；Driven by AUR; Built on ${BUILD_DATE}'


## Build codec
FROM rnbguy/archlinux-yay:latest AS codec
USER aur
RUN yay -Syu --noconfirm svt-av1-git x264-tmod-git l-smash-x264-tmod-git x265-git && \
    sudo -u root mkdir -p /build && sudo -u root chown -R aur /build  && \
    sudo -u root mkdir -p /build/bin && sudo -u root chown -R aur /build/bin  && \
    sudo -u root mkdir -p /build/lib && sudo -u root chown -R aur /build/lib  && \
    find /usr/lib -name "*lsmash.so*" -maxdepth 1 -type f | xargs -i cp -f {} /build/lib/ && \
    find /usr/lib -name "*x264.so*" -maxdepth 1 -type f | xargs -i cp -f {} /build/lib/ && \
    cp /usr/lib/libx265.so /build/lib/ && cp /usr/lib/libhdr10plus.so /build/lib/ && \
    find /usr/lib -name "libSvtAv1.so*" -maxdepth 1 -type f | xargs -i cp -f {} /build/lib/ && \
    cp /usr/bin/* /build/bin/


## COPY Compile
FROM rnbguy/archlinux-yay:latest as Main
COPY --from=codec /build/ /usr/
COPY ./yay* /tmp/
USER aur
## Build vapoursynth
RUN yay -Syyu --noconfirm zimg vapoursynth && \
    sudo -u root rm -rf /usr/lib/vapoursynth/libmiscfilters.so && \
    yay -Sya --noconfirm $(cat /tmp/yaylist1.txt | grep -Ev '^$|#' | tr -s "\r\n" " ") && \
    yay -Sya --noconfirm $(cat /tmp/yaylist2.txt | grep -Ev '^$|#' | tr -s "\r\n" " ")


## Install jupyter
ARG BUILD_DATE
MAINTAINER Learning Enocder
LABEL Version='AUR Version'\
      DESCRIPTTION='Bulid in ArchLinux；Driven by AUR; Built on ${BUILD_DATE}'
USER root
RUN  pacman -Syu --noconfirm python3 python-pip && \
     pip3 install yuuno jupyterlab

# FROM archlinux:base as Main
# COPY --from=codec /usr /usr
# COPY --from=vs /usr /usr
# COPY --from=vs /usr/lib/vapoursynth /usr/lib/vapoursynth/
# RUN yay -Sya --noconfirm python3 python-pip && \
#     pip3 install yuuno jupyterlab

ENV JUPYTER_CONFIG_DIR=/jupyter/config \
    JUPYTER_DATA_DIR=/jupyter/data \
    JUPYTER_RUNTIME_DIR=/jupyter/runtime \
    JUPYTER_VIDEO_DIR=/jupyter/video

## configure docker
WORKDIR /jupyter

VOLUME ["/jupyter"]
VOLUME ["/jupyter/video"]

EXPOSE 8888/tcp

## Start
# CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root", "--NotebookApp.token='frds'"]
CMD ["jupyter", "lab", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root", "--NotebookApp.token='frds'"]
