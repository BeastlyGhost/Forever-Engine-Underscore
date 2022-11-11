package;

import base.debug.Overlay;
import dependency.Discord;
import dependency.FNFTransition;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import haxe.CallStack;
import haxe.io.Path;
import lime.app.Application;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.UncaughtErrorEvent;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

// Here we actually import the states and metadata, and just the metadata.
// It's nice to have modularity so that we don't have ALL elements loaded at the same time.
// at least that's how I think it works. I could be stupid!
class Main extends Sprite
{
	public static var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	public static var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).

	var gameZoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.

	public static var mainClassState:Class<FlxState> = states.TitleState; // specify the state where the game should start at;

	public static var engineVersion:String = '0.3'; // current forever engine underscore version;
	public static var foreverVersion:String = '0.3.1'; // current forever engine version;
	public static var nightly:Bool = true;

	public static var overlay:Overlay; // info counter that usually appears at the top left corner;
	public static var console:Console; // console that appears when you press F10 (if allowed);

	// calls a function to set the game up
	public function new()
	{
		super();

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		FlxTransitionableState.skipNextTransIn = true;

		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (gameZoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			gameZoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / gameZoom);
			gameHeight = Math.ceil(stageHeight / gameZoom);
			// this just kind of sets up the camera zoom in accordance to the surface width and camera zoom.
			// if set to negative one, it is done so automatically, which is the default.
		}

		addChild(new FlxGame(0, 0, Init, #if (flixel < "5.0.0") gameZoom, #end 120, 120, true));

		// begin the discord rich presence
		#if DISCORD_RPC
		if (Init.getSetting('Discord Rich Presence'))
		{
			Discord.initializeRPC();
			Discord.changePresence('');
		}
		#end

		#if desktop
		overlay = new Overlay(0, 0);
		updateOverlayAlpha(Init.trueSettings.get('Overlay Opacity') * 0.01);
		addChild(overlay);

		console = new Console();
		addChild(console);
		#end
	}

	public static function framerateAdjust(input:Float)
	{
		return input * (60 / FlxG.drawFramerate);
	}

	/*
		This is used to switch "rooms," to put it basically. Imagine you are in the main menu, and press the freeplay button.
		That would change the game's main class to freeplay, as it is the active class at the moment.
	 */
	public static function switchState(curState:FlxState, target:FlxState)
	{
		// Custom made Trans in
		mainClassState = Type.getClass(target);
		if (!FlxTransitionableState.skipNextTransIn)
		{
			curState.openSubState(new FNFTransition(0.35, false));
			FNFTransition.finishCallback = function()
			{
				FlxG.switchState(target);
			};
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxTransitionableState.skipNextTransOut = false;
		// load the state
		FlxG.switchState(target);
	}

	public static function updateFramerate(newFramerate:Int)
	{
		// flixel will literally throw errors at me if I dont separate the orders
		if (newFramerate > FlxG.updateFramerate)
		{
			FlxG.updateFramerate = newFramerate;
			FlxG.drawFramerate = newFramerate;
		}
		else
		{
			FlxG.drawFramerate = newFramerate;
			FlxG.updateFramerate = newFramerate;
		}
	}

	public static function updateOverlayAlpha(newAlpha:Float)
	{
		if (overlay != null)
			overlay.alpha = newAlpha;
	}

	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = StringTools.replace(dateNow, " ", "_");
		dateNow = StringTools.replace(dateNow, ":", "'");

		path = "crash/" + "FE-U_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: "
			+ e.error
			+ "\nPlease report this error to the GitHub page"
			+ "\nhttps://github.com/BeastlyGhost/Forever-Engine-Underscore"
			+ "\n\nCrash Handler written by: sqirra-rng\n"
			+ "\nForever Engine Underscore v"
			+ Main.engineVersion
			+ "\n";

		try // to make the game not crash if it can't save the crash file
		{
			if (!FileSystem.exists("crash"))
				FileSystem.createDirectory("crash");

			File.saveContent(path, errMsg + "\n");
		}

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		var crashDialoguePath:String = "FE-CrashDialog";

		#if windows
		crashDialoguePath += ".exe";
		#end

		if (FileSystem.exists(crashDialoguePath))
		{
			Sys.println("Found crash dialog: " + crashDialoguePath);
			new Process(crashDialoguePath, [path]);
		}
		else
		{
			Sys.println("No crash dialog found! Making a simple alert instead...");
			Application.current.window.alert(errMsg, "Error!");
		}

		#if DISCORD_RPC
		Discord.shutdownRPC();
		#end
		Sys.exit(1);
	}
}
