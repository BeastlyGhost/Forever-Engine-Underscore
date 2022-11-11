@echo off
color 0a
title FNF: Forever Engine - Running Game (DEBUG MODE)
cd ..
echo BUILDING...
echo IF IT CRASHES AFTER THE TITLESCREEN OR WHEN GOING TO PLAYSTATE
echo TRY BINDING THE RESET KEYS TO ANYTHING ON A RELEASE BUILD
haxelib run lime test windows -debug
echo. 
echo DONE
pause