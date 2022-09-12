all: drivers.com Snake.exe

drivers.com: drivers.obj
    tlink /v /t drivers
drivers.obj: drivers.asm
    tasm /zi drivers.asm,,drivers.lst

Snake.exe: Snake.obj
    tlink /v Snake
Snake.obj: Snake.asm
    tasm /zi Snake.asm,,Snake.lst

clean: 
    del drivers.com
    del drivers.obj
    del drivers.lst
    del drivers.map
    del Snake.exe
    del Snake.obj
    del Snake.lst
    del Snake.map