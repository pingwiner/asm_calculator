@echo off
del *.obj *.map
tasm calc.asm
tlink -t calc