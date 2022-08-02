# nohup docker build . -f /root/aur.Dockerfile -t encoder-docker:0.1 > run.log 2>&1 &

FROM rnbguy/archlinux-yay:latest AS base
USER aur
RUN yay -Syy --noconfirm

## Build codec
FROM base AS codec
RUN yay -S --noconfirm svt-av1-git x264-tmod-git l-smash-x264-tmod-git x265-git

## COPY Compile
FROM base AS vs
# COPY --from=codec /usr/ /usr/
## Build vapoursynth
RUN yay -Sy --noconfirm zimg vapoursynth-git && \
    sudo -u root rm -rf /usr/lib/vapoursynth/libmiscfilters.so && \
    yay -Sa --noconfirm $(cat /tmp/yaylist1.txt | grep -Ev '^$|#' | tr -s "\r\n" " ") && \
    yay -Sa --noconfirm $(cat /tmp/yaylist2.txt | grep -Ev '^$|#' | tr -s "\r\n" " ")

FROM archlinux:base AS main
## Install jupyter
ARG BUILD_DATE
MAINTAINER mitlearn
LABEL Version='AUR Version'\
      DESCRIPTTION='Bulid in ArchLinux；Driven by AUR; Built on ${BUILD_DATE}'
COPY --from=codec /usr/ /usr/
COPY --from=vs /usr/ /usr/
# USER root
RUN pacman -Syyu --noconfirm python3 python-pip && \
    pip install yuuno jupyterlab && pip cache purge && \
    pacman -Scc && pacman -Qqdt | pacman -Rs -


## Configure docker
ENV JUPYTER_CONFIG_DIR=/jupyter/config \
    JUPYTER_DATA_DIR=/jupyter/data \
    JUPYTER_RUNTIME_DIR=/jupyter/runtime \
    VIDEO_DIR=/jupyter/video

WORKDIR /jupyter

VOLUME ["/jupyter"]
VOLUME ["/jupyter/video"]

EXPOSE 8888/tcp

## Start
# CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root", "--NotebookApp.token='frds'"]
CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root", "--NotebookApp.token='frds'"]