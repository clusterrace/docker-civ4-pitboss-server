FROM ubuntu:bionic

# ARG MONO_VER="5.1.0"
# ARG GECKO_VER="2.47.1"
ARG USER="civpb"

# NOTE: We need wine and many libs in it's 32bit variant for Civ4
# This will be satified on debian based os by --add-architecture
# If this script should be converted on Arch Linux 
# use lib32-prefixed packages.

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        gnupg \
        wget \
    && echo 'deb https://dl.winehq.org/wine-builds/ubuntu/ bionic main' > /etc/apt/sources.list.d/wine.list \
    && echo 'deb http://ppa.launchpad.net/cybermax-dexter/sdl2-backport/ubuntu bionic main' > /etc/apt/sources.list.d/dexter.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BBB8BD3BBE6AD3419048EDC50795A9A788A59C82 \
    && curl -fsSL https://dl.winehq.org/wine-builds/winehq.key | apt-key add - \
    && apt-get update \
    && true

RUN    apt-get install -y --no-install-recommends \
        supervisor \
        libgl1-mesa-glx:i386 \
        winehq-stable \
# winetricks not required because we install msxml3.msi manually
#        winetricks \
# for run-pb-server \
        xvfb \
# for confirm-popup.sh x11-apps for xwd, x11-utils for xwininfo,  \
        x11-apps \
        x11-utils xdotool imagemagick \
        screen \
# for unbuffer. Otherwise 'docker run' do not show whole output \
        expect tcl \
# for startPitboss.py (currently not used) \
        python2.7 \
    && useradd -ms /bin/bash civpb \
    && mkdir /app \
    && chown civpb:civpb /app \
    && true

## Newer winetricks
#RUN wget -O "/usr/bin/winetricks" \
#      "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" \
#    && chmod +x /usr/bin/winetricks \
#    && true


# 3D dependencies of Civ4 (32 bit)
#RUN dpkg --add-architecture i386 \
#    && apt-get update \
#    && apt-get install -y --no-install-recommends \

# Download mono and gecko package for wine
#RUN mkdir -p /usr/share/wine/mono /usr/share/wine/gecko \
#    && wget https://dl.winehq.org/wine/wine-mono/${MONO_VER}/wine-mono-${MONO_VER}-x86.msi \
#        -O /usr/share/wine/mono/wine-mono-${MONO_VER}-x86.msi \
#    && wget https://dl.winehq.org/wine/wine-gecko/${GECKO_VER}/wine-gecko-${GECKO_VER}-x86.msi \
#        -O /usr/share/wine/gecko/wine-gecko-${GECKO_VER}-x86.msi \
#    && wget https://dl.winehq.org/wine/wine-gecko/${GECKO_VER}/wine-gecko-${GECKO_VER}-x86_64.msi \
#        -O /usr/share/wine/gecko/wine-gecko-${GECKO_VER}-x86_64.msi \
RUN mkdir -p /usr/share/wine
COPY files/msxml3.msi /usr/share/wine/.

RUN echo "Clean caches" \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && apt-get autoclean -y \
    && mkdir -p /tmp/.X11-unix \
    && chmod 1777 /tmp/.X11-unix \
    && true

USER ${USER}
ENV WINEPREFIX=/app WINEARCH=win32

# Do not remove sleep lines. They preventing a corrupt WINEDIR, I assume.
RUN wineboot --update \
    # && sleep 10 && kill $(ps | grep "win[e]server" ) \
    && sleep 10 \
    && rm "$WINEPREFIX/drive_c/windows/system32/msxml3.dll" \
#    && winetricks --unattended msxml3 \
    && wine msiexec /i "/usr/share/wine/msxml3.msi" /qn \
    && sleep 10 \
# Regsvr32 fixes xml loading error on civ4 startup
    && wine Regsvr32 "%windir%\system32\msxml3.dll" \
    && sleep 10 \
    && true


## Install Windows software. Commented out because it is not required.
#RUN  ls /usr/share/wine/*.msi \
#  && rm "$WINEPREFIX/drive_c/windows/system32/msxml3.dll" \
#  && wine msiexec /i "/usr/share/wine/msxml3.msi" /qn \
#  && wine Regsvr32 "%windir%\system32\msxml3.dll"
## Mono and Gecko not required, I assume.
##    && ls /usr/share/wine/mono/*.msi /usr/share/wine/gecko/*.msi \
##   && wine msiexec /i "/usr/share/wine/mono/wine-mono-${MONO_VER}-x86.msi" /qn \
##   && wine msiexec /i "/usr/share/wine/gecko/wine-gecko-${GECKO_VER}-x86.msi" /qn \
#    && true

# Create root directory for Civ4 Pitboss ALTROOT dir
#    The domain of the server is encoded into the folders name
#    to propagate this url to the clients. (for BTS_Wrapper)
#
#    Folder for this/first instance. Use PB2, ... for more
#    Use PB2, ... for more
#
#    ../PBs/ should also contain the 'Python' subfolder of civ4-mp/pbmod!!
#
#    Symbolic link just used for easier path structure 
#    during mount of container.
#RUN mkdir -p "/home/${USER}/_https_pb.zulan.net/pb" \
#    && ln -s "/home/${USER}/PBs" "/home/${USER}/_https_pb.zulan.net/pb/PBs" \
#    && true
# ======> Shifted into run-pb-server to made domain flexible.

# To wrap+log terminal output.
# TODO: Not required?! Use stdout_logfile=/dev/fd/1
COPY files/.screenrc /home/${USER}/.

USER root
COPY files/run-pb-server \
  files/civ4-extract-modname \
  files/confirm-popup \
  files/make-screenshot \
  files/fix-ids-in-container \
  files/run-gnu-screen \
  files/run-notepad \
  /usr/local/bin/

RUN chmod +x \
    /usr/local/bin/run-pb-server \
    /usr/local/bin/civ4-extract-modname \
    /usr/local/bin/confirm-popup \
    /usr/local/bin/make-screenshot \
    /usr/local/bin/fix-ids-in-container \
    /usr/local/bin/run-gnu-screen \
    /usr/local/bin/run-notepad

COPY files/supervisord.conf \
    /etc/supervisor/

# Parent for "PBs" mount
RUN mkdir /altroot \
    && chown civpb:civpb /altroot \
    && true

# Die ports dynamisch zu halten hat hier Vorteile. Bei fixen Ports
# kann man inner- und außerhalb des Containers nicht die gleichen 
# Konfigurationsdateien (pbSettings.json CivilizationIV.ini) nehmen, da dort
# die Ports enthalten sind. Die Dateien werden zum PBServer regelmäßig überschrieben.
# Die richtigen Ports werden vor dem Start von civ4-mp/pbmod/PBs/startPitboss.py bestimmt.
# 
#EXPOSE 2056 13373 3333
#  2056: PBServer clients
# 13373: PBServer optional webinterface
#  3333: PBServer optional interactive shell for running game

# Note: Expose-Ports werden nicht automatisch beim Starten weitergeleitet. 
#       Nur mit 'run -P ...' würden sie an höhere Ports delegiert.

#CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-c", "/etc/supervisor/supervisord.conf"]
