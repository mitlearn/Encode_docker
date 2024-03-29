# nohup docker build . -f /root/aur.Dockerfile -t vapoursynth-yuuno-codec:0.1 > run.log 2>&1 &
FROM rnbguy/archlinux-yay:latest AS yay
    ## Migrate folder
RUN yay -Sy && \
    sudo -u root mkdir -p /build && sudo -u root chown -R aur /build && \
    sudo -u root mkdir -p /build/bin && sudo -u root chown -R aur /build/bin && \
    sudo -u root mkdir -p /build/lib && sudo -u root chown -R aur /build/lib && \
    sudo -u root mkdir -p /build/site-packages && sudo -u root chown -R aur /build/site-packages

## Build codec
FROM yay AS codec
USER aur
RUN yay -Su --noconfirm svt-av1-git x264-tmod-git l-smash-x264-tmod-git && \
    ## .so Migrate
    find /usr/lib -name "*x26*" -maxdepth 1 -type f | xargs -i cp -f {} /build/lib/ && \
    find /usr/lib -name "*hdr10*" -maxdepth 1 -type f | xargs -i cp -f {} /build/lib/ && \
    find /usr/lib -name "*SvtAv1*" -maxdepth 1 -type f | xargs -i cp -f {} /build/lib/ && \
    ## .binary Migrate
    find /usr/bin -name "SvtAv1*" -maxdepth 1 -type f | xargs -i cp -f {} /build/bin/ && \
    find /usr/bin -name "x26*" -maxdepth 1 -type f | xargs -i cp -f {} /build/bin/

## COPY Compile
FROM yay as vs
COPY ./yay* /tmp/
USER aur
## Build vapoursynth
RUN yay -Su --noconfirm zimg-git vapoursynth-git && \
    yay -Sa --noconfirm $(cat /tmp/yaylist1.txt | grep -Ev '^$|#' | tr -s "\r\n" " ") && \
    sudo -u root rm -rf /usr/lib/vapoursynth/libmiscfilters.so && \
    yay -Sa --noconfirm $(cat /tmp/yaylist2.txt | grep -Ev '^$|#' | tr -s "\r\n" " ") && \
    ## .binary Migrate
    find /usr/bin -name "x265*" -maxdepth 1 -type f | xargs -i cp -f {} /build/bin/ && \
    find /usr/bin -name "vspipe*" -maxdepth 1 -type f | xargs -i cp -f {} /build/bin/ && \
    ## .so Migrate
    # find /usr/lib -name "*x26*" -maxdepth 1 -type f | xargs -i cp -f {} /build/lib/ && \
    # find /usr/lib -name "*hdr10*" -maxdepth 1 -type f | xargs -i cp -f {} /build/lib/ && \
    # find /usr/lib -name "*zimg*" -maxdepth 1 -type f | xargs -i cp -f {} /build/lib/ && \
    # find /usr/lib -name "libsw*" -maxdepth 1 -type f | xargs -i cp -f {} /build/lib/ && \
    # find /usr/lib -name "libav*" -maxdepth 1 -type f | xargs -i cp -f {} /build/lib/ && \
    # find /usr/lib -name "liblsmash*" -maxdepth 1 -type f | xargs -i cp -f {} /build/lib/ && \
    # find /usr/lib -name "*vapoursynth*" -maxdepth 1 -type f | xargs -i cp -f {} /build/lib/ && \
    find /usr/lib -name "lib*" -maxdepth 1 -type f | xargs -i cp -f {} /build/lib/ && \
    cp -rf /usr/lib/vapoursynth /build/lib/vapoursynth && \
    ## .py Migrate
    find $(python3 -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])') -maxdepth 1 -name "vapoursynth.so" -type f | xargs -i cp -f {} /build/site-packages/ && \
    find $(python3 -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])') -maxdepth 1 -name "*.py" -type f | xargs -i cp -f {} /build/site-packages/ && \
    find $(python3 -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])') -maxdepth 1 -name "vsutil" -type d | xargs -i cp -rf {} /build/site-packages/

## Main Stage
# FROM rnbguy/archlinux-yay:latest as Main
FROM archlinux:base
ARG BUILD_DATE
MAINTAINER Learning Enocder
LABEL Version='AUR Version'\
      DESCRIPTTION='Bulid in ArchLinux；Driven by AUR; Built on ${BUILD_DATE}'
COPY --from=codec /build/ /usr/
COPY --from=vs /build/ /tmp/
## Install jupyter
RUN  pacman -Syu --noconfirm python3 python-pip hwloc && \
     pip3 install yuuno jupyterlab && \
     ## Clean
     pip cache purge && pacman -Scc && \
     mv /tmp/bin/* /usr/bin && \
     mv -u /tmp/lib/* /usr/lib && \
     mv -u /tmp/site-packages/* $(python3 -c 'import sysconfig;print(sysconfig.get_paths()["purelib"])') && \
     rm -rf /tmp

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
