FROM registry.fedoraproject.org/fedora:28
RUN dnf install -y wine winetricks file xorg-x11-server-Xvfb p7zip mesa-dri-drivers cups-pdf uid_wrapper && dnf clean all
ARG gid=1000
RUN groupadd -g $gid user
ARG uid=1000
RUN useradd -u $uid -g user user
RUN mkdir /data && chown user /data

RUN chmod a+rx /usr/lib/cups/backend/cups-pdf
RUN mv /usr/lib/cups/backend/cups-pdf /usr/lib/cups/backend/cups-pdf.orig && chmod a+rx /usr/lib/cups/backend/cups-pdf.orig
COPY cups-pdf-wrapper /usr/lib/cups/backend/cups-pdf
COPY cups-files.conf cups-pdf.conf printers.conf /etc/cups/
RUN chgrp -R user /etc/cups && chmod g+r /etc/cups/*
RUN sed -i -e 's%^LogLevel.*%LogLevel debug%' -e 's%^Listen localhost%# &%' -e 's%^Listen /.*%Listen /tmp/cups/cupsd.sock%' /etc/cups/cupsd.conf

USER user
ENV WINEARCH=win64
RUN xvfb-run winetricks -q vcrun2017
RUN winetricks -q win7
WORKDIR /home/user
COPY sketchupmake-2017-2-2555-90782-en-x64.exe /home/user/
RUN echo '9841792f170d803ae95a2741c44cce38e618660f98a1a3816335e9bf1b45a337  sketchupmake-2017-2-2555-90782-en-x64.exe' | sha256sum -c
RUN 7za x sketchupmake-2017-2-2555-90782-en-x64.exe SketchUp2017-x64.msi && wine64 msiexec /i SketchUp2017-x64.msi /quiet && rm -f SketchUp2017-x64.msi
RUN ls -la ".wine/drive_c/Program Files/SketchUp/SketchUp 2017/SketchUp.exe"
RUN sed -i 's/"LogPixels"=dword:.*/"LogPixels"=dword:00000080/' .wine/system.reg

COPY wine-tmp-list wine-data-list /
RUN mkdir .tmp-template
RUN while read i ; do mkdir -p "$( dirname .tmp-template/"$i" )" && ( test -e .wine/"$i" || mkdir -p .wine/"$i" ) && mv .wine/"$i" .tmp-template/"$i" && ln -sv /tmp/wine/"$i" .wine/"$i" ; done < /wine-tmp-list
RUN while read i ; do mkdir -p "$( dirname .wine-template/"$i" )" && ( test -e .wine/"$i" || mkdir -p .wine/"$i" ) && mv .wine/"$i" .wine-template/"$i" && ln -sv /data/.sketchup-run/wine/"$i" .wine/"$i" ; done < /wine-data-list
ENV WINEPREFIX=/home/user/.wine
COPY run-sketchup /usr/local/bin/
RUN rm -f /home/user/.wine/drive_c/users/user/"My Documents" && ln -sv /data /home/user/.wine/drive_c/users/user/"My Documents"

ENTRYPOINT [ "/usr/local/bin/run-sketchup" ]
LABEL RUN 'docker run --read-only --tmpfs /tmp -v /tmp/.wine-$(id -u) -e DISPLAY=$DISPLAY --security-opt=label:type:spc_t --user=$(id -u):$(id -g) -v /tmp/.X11-unix/X0:/tmp/.X11-unix/X0 --device=/dev/dri/card0:/dev/dri/card0 -v $(pwd):/data --rm sketchup'
LABEL RUN_OPTS '--tmpfs /tmp -v /tmp/.wine-$SUDO_UID -e DISPLAY=$DISPLAY -v /tmp/.X11-unix/X0:/tmp/.X11-unix/X0 --device=/dev/dri/card0:/dev/dri/card0'
