#!/bin/bash
# FOR LINUX, based off of setup.bat

# go to https://haxe.org/download/linux/ to install the latest version of Haxe
# or refer to your distribution's package manager in order to install the package

# if using the binary from the download link
# you may or may not need to run "haxelib setup"
# you may also need to run "chmod +x setup" to mark this file as an executable

haxelib install lime
haxelib install openfl
haxelib install flixel
haxelib install flixel-addons
haxelib install flixel-ui
haxelib install flixel-tools
haxelib install hscript
haxelib install hxCodec
haxelib install hxcpp-debug-server
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib git SScript https://github.com/BeastlyGhost/SScript-Ghost