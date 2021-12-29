# docker-civ4-pitboss-server
This is a docker image to run the Pitboss server of CivilizationIV
in a docker container. The game files are **not** included and must be mounted into the container.

# Civ4 Mod required!
This project targeting a hosting of Civ4 Pitboss games on a headless server.
It only support mods like "pbmod" who implements the changes for this.


# Creation of image
```
	docker build -t "pbserver" .
```


# Setup

Adapt variables in 'bin/pitbossctl' to link on
Civ4 folder and the ALTROOT root directory (see civ4mp-pbmod)
```
PATH_TO_CIV4="/home/$USER/Civ4"
PATH_TO_PBs="/home/$USER/PBs"
```

# Example with one game

```
bin/pitbossctl create "PB1" "PB Mod_v9" 2056 13373 3333
bin/pitbossctl start "PB1"
...
bin/pitbossctl stop "PB1"
bin/pitbossctl delete "PB1"
```

# Debugging
## Open shell in running instance
```
bin/pitbossctl shell "PB1"
```

## Show framebuffer, e.g. for error popups of the game
```
bin/pitbossctl screenshot "PB1"
```



## View output of application
```
bin/pitbossctl start "PB1"
bin/pitbossctl attach "PB1"
bin/pitbossctl shell "PB1"
    $ kill $(pgrep Civ4)
```


# Known Issues:

## Popup at early startup stage
Error message of popup: ***Caught unhandled exception creating XML parser object …***

Solution:

## Python Loading error of Civ4
Python error Popup and Logs/PythonErr2.log shows
```
  File "e:/main/civilization4/warlords/assets/python/system\random.py", line 109, in seed
  WindowsError: [Errno -2146893801] Windows Error 0x80090017
  Traceback (most recent call last):
    File "<string>", line 1, in ? 
    ImportError: No module named CvAppInterface
```

Reason: Calling wine in Dockerfiles is problematic because wine
starts multiple processes (wineserver, etc). This could spoil the .wine-Dir
if wine is called in multiple RUN-instructions, see
https://github.com/suchja/wine/issues/7


Solution: Bundle all wine stuff into one RUN call
(or just during instancing of container).
I did not test if a 'killall wineserver at each end of RUN helps.

EDIT: Nein, das hilft leider immer noch nicht! Es fehlen z.B. die *.reg-Dateien
nach wineboot --update + winetricks-call, auch wenn es in einem RUN kombiniert wird.
Ruft man es interaktiv auf läuft es, aber das dauert...


## OpenGL-Crash
Error:
```
Init Progress - step 9 / 9 - DONE
App Init start elapsed time = 9.33, uncached XML<BR>

CvEngine::shutdownGraphics

0024:err:wgl:init_opengl Failed to load libGL: libGL.so.1: cannot open shared object file: No such file or directory
0024:err:wgl:init_opengl OpenGL support is disabled.
wine: Unhandled page fault on read access to 00000000 at address 005F08DA (thread 0024), starting debugger...
```


Solution:
      Install lib with explicit architecture: libgl1-mesa-glx:i386


## X11 problem
Error message
```
App Init start elapsed time = 9.09, uncached XML<BR>

CvEngine::shutdownGraphics

wine: Unhandled page fault on read access to 00000000 at address 005F08DA (thread 0170), starting debugger...
01d0:err:user:load_desktop_driver failed to load L"winex11.drv"
```

Solution: Export DISPLAY variable to value from Xvfb, e.g. :0

## Server quits
Error message

```
==> PythonErr.log <==
  
    File "PbMain", line 8, in ?
      
        File "<string>", line 52, in load_module
          
            File "PbWizard", line 19, in ?

            IOError: [Errno 2] No such file or directory: 'Z:\\\\home\\\\[…]\\\\PBs\\\\PB1\\..\\Python\\v9\\PbWizard.py'
            Failed to load python module PbMain.
            ERR: Call function create failed. Can't find module PbMain


```

Solution: Adapt variable in CivilizationIV.ini:
***PitbossSMTPLogin=Z:\\home\\civpb\\PBs\\PB1***

TODO: Automatic substitution.


## Script run-pbserver quits if started by supervisord
Error message:
```
pbSettings.json not found in in '/home/civpb/_https_zulan.net/pb/PBs/PB1'
2021-12-29 09:06:58,476 INFO exited: pbserver (exit status 255; not expected)
```

Solution: $USER was empty if script is started by supervisord. The
environment variables had to be set manually in supervisord.conf.


