FROM registry.fedoraproject.org/fedora:28
RUN dnf install -y wine winetricks file xorg-x11-server-Xvfb p7zip mesa-dri-drivers && dnf clean all
ARG uid=1000
RUN useradd -u $uid user
USER user
ENV WINEARCH=win64
RUN xvfb-run winetricks -q vcrun2017
RUN winetricks -q corefonts
RUN winetricks -q win7
RUN winetricks -q dotnet452
COPY sketchupmake-2017-2-2555-90782-en-x64.exe /home/user/
WORKDIR /home/user
RUN echo '9841792f170d803ae95a2741c44cce38e618660f98a1a3816335e9bf1b45a337  sketchupmake-2017-2-2555-90782-en-x64.exe' | sha256sum -c
RUN 7za x sketchupmake-2017-2-2555-90782-en-x64.exe SketchUp2017-x64.msi && wine64 msiexec /i SketchUp2017-x64.msi /quiet && rm -f SketchUp2017-x64.msi
RUN ls -la ".wine/drive_c/Program Files/SketchUp/SketchUp 2017/SketchUp.exe"

ENTRYPOINT [ "wine64", ".wine/drive_c/Program Files/SketchUp/SketchUp 2017/SketchUp.exe" ]
LABEL RUN 'docker run --tmpfs /tmp -e DISPLAY=$DISPLAY --security-opt=label:type:spc_t --user=$(id -u):$(id -g) -v /tmp/.X11-unix/X0:/tmp/.X11-unix/X0 --device=/dev/dri/card0:/dev/dri/card0 --rm sketchup'