package;

import base.*;
import flixel.FlxG;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween.FlxTweenType;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import openfl.display.BlendMode;
import openfl.utils.AssetType;
import states.PlayState;
import sys.FileSystem;

using StringTools;

/**
	This class is used as an extension to many other forever engine stuffs, please don't delete it as it is not only exclusively used in forever engine
	custom stuffs, and is instead used globally.
**/
class ForeverTools
{
	public static var mustUpdate:Bool = false;
	public static var updateVersion:String = '';

	// set up maps and stuffs
	public static function resetMenuMusic(resetVolume:Bool = false, bpm:Int = 102)
	{
		// make sure the music is playing
		if (((FlxG.sound.music != null) && (!FlxG.sound.music.playing)) || (FlxG.sound.music == null))
		{
			var menuSong:String = 'freakyMenu';
			menuSong = Init.getSetting('Menu Song');

			var song = Paths.music('menus/main/$menuSong/$menuSong');
			FlxG.sound.playMusic(song, (resetVolume) ? 0 : 0.7);
			if (resetVolume)
				FlxG.sound.music.fadeIn(4, 0, 0.7);

			if (FlxG.sound.music.pitch != 1)
				FlxG.sound.music.pitch = 1;
			Conductor.changeBPM(bpm);
		}
	}

	public static function resetGame()
	{
		states.TitleState.initialized = false;
		FlxG.sound.music.fadeOut(0.3);
		FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
	}

	public static function returnSkin(skinAsset:String, assetModifier:String = 'base', changeableSkin:String = 'default', baseLibrary:String,
			?defaultChangeableSkin:String = 'default', ?defaultBaseAsset:String = 'base'):String
	{
		var realAsset = '$baseLibrary/$changeableSkin/$assetModifier/$skinAsset';
		if (!fileExists('images/' + realAsset + '.png', IMAGE))
		{
			realAsset = '$baseLibrary/$defaultChangeableSkin/$assetModifier/$skinAsset';
			if (!fileExists('images/' + realAsset + '.png', IMAGE))
				realAsset = '$baseLibrary/$defaultChangeableSkin/$defaultBaseAsset/$skinAsset';
		}

		return realAsset;
	}

	public static function killMusic(songsArray:Array<FlxSound>)
	{
		// neat function thing for songs
		for (i in 0...songsArray.length)
		{
			// stop
			songsArray[i].stop();
			songsArray[i].destroy();
		}
	}

	// does this even work at all?
	inline public static function fileExists(path:String, type:AssetType = TEXT, ?library:Null<String>):Bool
	{
		var assetExists = FileSystem.exists(Paths.getPath(path, type, library));
		var modExists = FileSystem.exists(ModManager.getModFile(path, type));

		if (assetExists || modExists)
			return true;

		return false;
	}

	public static function checkUpdates()
	{
		// check for updates
		if (Init.getSetting('Check for Updates') && !Main.nightly)
		{
			trace('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/BeastlyGhost/Forever-Engine-Underscore/master/gameVersion.txt");
			http.onData = function(data:String)
			{
				updateVersion = data.split('\n')[0].trim();
				var curVersion:String = Main.engineVersion.trim();
				trace('Your Version: ' + curVersion + ' - Latest Version: ' + updateVersion);

				if (updateVersion != curVersion)
				{
					trace('version mismatch!');
					mustUpdate = true;
				}
			}
			http.onError = function(error)
			{
				trace('error: $error');
			}
			http.request();
		}
	}

	public static function returnCam(cam:String)
	{
		switch (cam)
		{
			case 'camgame' | 'camGame' | 'game' | 'world':
				return PlayState.camGame;
			case 'camhud' | 'camHUD' | 'hud' | 'ui':
				return PlayState.camHUD;
			case 'strumhud' | 'strumHUD' | 'strum' | 'strumlines':
				for (strumhud in PlayState.strumHUD)
					return strumhud;
		}
		return PlayState.camGame;
	}

	public static function returnTweenType(type:String = ''):FlxTweenType
	{
		switch (type.toLowerCase())
		{
			case 'backward':
				return FlxTweenType.BACKWARD;
			case 'looping':
				return FlxTweenType.LOOPING;
			case 'oneshot':
				return FlxTweenType.ONESHOT;
			case 'persist':
				return FlxTweenType.PERSIST;
			case 'pingpong':
				return FlxTweenType.PINGPONG;
		}
		return FlxTweenType.PERSIST;
	}

	public static function returnTweenEase(ease:String = '')
	{
		switch (ease.toLowerCase())
		{
			case 'linear':
				return FlxEase.linear;
			case 'backin':
				return FlxEase.backIn;
			case 'backinout':
				return FlxEase.backInOut;
			case 'backout':
				return FlxEase.backOut;
			case 'bouncein':
				return FlxEase.bounceIn;
			case 'bounceinout':
				return FlxEase.bounceInOut;
			case 'bounceout':
				return FlxEase.bounceOut;
			case 'circin':
				return FlxEase.circIn;
			case 'circinout':
				return FlxEase.circInOut;
			case 'circout':
				return FlxEase.circOut;
			case 'cubein':
				return FlxEase.cubeIn;
			case 'cubeinout':
				return FlxEase.cubeInOut;
			case 'cubeout':
				return FlxEase.cubeOut;
			case 'elasticin':
				return FlxEase.elasticIn;
			case 'elasticinout':
				return FlxEase.elasticInOut;
			case 'elasticout':
				return FlxEase.elasticOut;
			case 'expoin':
				return FlxEase.expoIn;
			case 'expoinout':
				return FlxEase.expoInOut;
			case 'expoout':
				return FlxEase.expoOut;
			case 'quadin':
				return FlxEase.quadIn;
			case 'quadinout':
				return FlxEase.quadInOut;
			case 'quadout':
				return FlxEase.quadOut;
			case 'quartin':
				return FlxEase.quartIn;
			case 'quartinout':
				return FlxEase.quartInOut;
			case 'quartout':
				return FlxEase.quartOut;
			case 'quintin':
				return FlxEase.quintIn;
			case 'quintinout':
				return FlxEase.quintInOut;
			case 'quintout':
				return FlxEase.quintOut;
			case 'sinein':
				return FlxEase.sineIn;
			case 'sineinout':
				return FlxEase.sineInOut;
			case 'sineout':
				return FlxEase.sineOut;
			case 'smoothstepin':
				return FlxEase.smoothStepIn;
			case 'smoothstepinout':
				return FlxEase.smoothStepInOut;
			case 'smoothstepout':
				return FlxEase.smoothStepInOut;
			case 'smootherstepin':
				return FlxEase.smootherStepIn;
			case 'smootherstepinout':
				return FlxEase.smootherStepInOut;
			case 'smootherstepout':
				return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	public static function returnBlendMode(str:String):BlendMode
	{
		return switch (str)
		{
			case "normal": BlendMode.NORMAL;
			case "darken": BlendMode.DARKEN;
			case "multiply": BlendMode.MULTIPLY;
			case "lighten": BlendMode.LIGHTEN;
			case "screen": BlendMode.SCREEN;
			case "overlay": BlendMode.OVERLAY;
			case "hardlight": BlendMode.HARDLIGHT;
			case "difference": BlendMode.DIFFERENCE;
			case "add": BlendMode.ADD;
			case "subtract": BlendMode.SUBTRACT;
			case "invert": BlendMode.INVERT;
			case _: BlendMode.NORMAL;
		}
	}

	public static function setTextAlign(str:String):FlxTextAlign
	{
		return switch (str)
		{
			case "center": FlxTextAlign.CENTER;
			case "justify": FlxTextAlign.JUSTIFY;
			case "left": FlxTextAlign.LEFT;
			case "right": FlxTextAlign.RIGHT;
			case _: FlxTextAlign.LEFT;
		}
	}

	public static function returnColor(str:String = ''):FlxColor
	{
		switch (str.toLowerCase())
		{
			case "black":
				FlxColor.BLACK;
			case "white":
				FlxColor.WHITE;
			case "blue":
				FlxColor.BLUE;
			case "brown":
				FlxColor.BROWN;
			case "cyan":
				FlxColor.CYAN;
			case "gray":
				FlxColor.GRAY;
			case "green":
				FlxColor.GREEN;
			case "lime":
				FlxColor.LIME;
			case "magenta":
				FlxColor.MAGENTA;
			case "orange":
				FlxColor.ORANGE;
			case "pink":
				FlxColor.PINK;
			case "purple":
				FlxColor.PURPLE;
			case "red":
				FlxColor.RED;
			case "transparent":
				FlxColor.TRANSPARENT;
		}
		return FlxColor.WHITE;
	}

	public static function getPoint(point:String):FlxAxes
	{
		switch (point.toLowerCase())
		{
			case 'x':
				return FlxAxes.X;
			case 'y':
				return FlxAxes.Y;
			case 'xy':
				return FlxAxes.XY;
		}
		return FlxAxes.XY;
	}

	public static function fromHSB(hue:Float, sat:Float, brt:Float, alpha:Float):FlxColor
	{
		return FlxColor.fromHSB(hue, sat, brt, alpha);
	}

	public static function fromRGB(red:Int, green:Int, blue:Int, alpha:Int):FlxColor
	{
		return FlxColor.fromRGB(red, green, blue, alpha);
	}

	public static function fromRGBFloat(red:Float, green:Float, blue:Float, alpha:Float):FlxColor
	{
		return FlxColor.fromRGBFloat(red, green, blue, alpha);
	}

	public static function fromInt(value:Int):FlxColor
	{
		return FlxColor.fromInt(value);
	}

	public static function fromString(str:String):FlxColor
	{
		return FlxColor.fromString(str);
	}
}
