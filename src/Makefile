OBJECTS_DIR = obj
SRC_DIR = src


all: drivers.com snake.exe

drivers.com: drivers.obj
    tlink /v /t drivers
drivers.obj: drivers.asm
    tasm /zi drivers.asm,,drivers.lst

snake.exe: snake.obj
    tlink /v snake
snake.obj: snake.asm
    tasm /zi snake.asm,,snake.lst

clean: 
    del drivers.com
    del drivers.obj
    del drivers.lst
    del drivers.map
    del snake.exe
    del snake.obj
    del snake.lst
    del snake.map