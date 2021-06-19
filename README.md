# OmerRepo
My works

In order to Run the game DOSBOX conf file (accessed from Windows start menu and choosing DOSBOX options file) need to be added following lines under [autoexe]:

[autoexec]
# Lines in this section will be run at startup.
# You can put your MOUNT lines here.

mount c: c:\
c:
cd tasm\bin

tasm /zi mem_game.asm
tlink /v mem_game.obj
#mem_game.exe
td mem_game.exe
