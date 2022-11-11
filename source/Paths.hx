package;

/*
	Aw hell yeah! something I can actually work on!
 */
import base.CoolUtil;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.media.Sound;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class Paths
{
	// Here we set up the paths class. This will be used to
	// Return the paths of assets and call on those assets as well.
	inline public static var SOUND_EXT = "ogg";
	inline public static var VIDEO_EXT = "mp4";

	// level we're loading
	public static var currentLevel:String;

	// mod level
	public static var currentMod:String = 'default';

	public static var scriptExts:Array<String> = ['hx', 'hxs', 'hscript', 'hxc'];

	// set the current level top the condition of this function if called
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	// stealing my own code from psych engine
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedTextures:Map<String, RectangleTexture> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [
		'assets/music/menus/${Init.getSetting('Pause Song')}/${Init.getSetting('Pause Song')}.$SOUND_EXT',
		'assets/music/menus/${Init.getSetting('Menu Song')}/${Init.getSetting('Menu Song')}.$SOUND_EXT'
	];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		var counter:Int = 0;
		for (key in currentTrackedAssets.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				var obj = currentTrackedAssets.get(key);
				if (obj != null)
				{
					obj.bitmap.lock();
					var isTexture:Bool = currentTrackedTextures.exists(key);
					if (isTexture)
					{
						var texture = currentTrackedTextures.get(key);
						texture.dispose();
						texture = null;
						currentTrackedTextures.remove(key);
					}
					@:privateAccess
					if (openfl.Assets.cache.hasBitmapData(key))
					{
						openfl.Assets.cache.removeBitmapData(key);
						FlxG.bitmap._cache.remove(key);
					}
					// trace('removed $key, ' + (isTexture ? 'is a texture' : 'is not a texture'));
					obj.bitmap.disposeImage(); // btw shoutouts to Raltyro :)
					obj.destroy();
					currentTrackedAssets.remove(key);
					counter++;
				}
			}
		}
		// trace('removed $counter assets');
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory()
	{
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
	}

	public static function returnGraphic(key:String, folder:String = 'images', ?library:String)
	{
		var isMod:Bool = false;
		if (FileSystem.exists(ModManager.getModFile('$folder/$key.png', IMAGE)))
			isMod = true;

		var path = getPath('$folder/$key.png', IMAGE, library);
		var mod = ModManager.getModFile('$folder/$key.png', IMAGE);

		if (FileSystem.exists(isMod ? mod : path))
		{
			if (!currentTrackedAssets.exists(key))
			{
				var bitmap = BitmapData.fromFile(isMod ? mod : path);
				var newGraphic:FlxGraphic;
				if (Init.getSetting('GPU Rendering'))
				{
					bitmap.lock();
					var texture = FlxG.stage.context3D.createRectangleTexture(bitmap.width, bitmap.height, BGRA, true);
					texture.uploadFromBitmapData(bitmap);
					currentTrackedTextures.set(key, texture);
					bitmap.dispose();
					bitmap.disposeImage();
					bitmap = null;
					// trace('new texture $key, bitmap is $bitmap');
					newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture), false, key, false);
				}
				else
				{
					newGraphic = FlxGraphic.fromBitmapData(bitmap, false, key, false);
					// trace('new bitmap $key, not textured');
				}
				currentTrackedAssets.set(key, newGraphic);
			}
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		var errorSnd:flixel.system.FlxSound = new flixel.system.FlxSound();
		errorSnd.loadEmbedded(Paths.sound('cancelMenu'));
		if (errorSnd != null && !errorSnd.playing)
			errorSnd.play();
		trace('graphic is returning null at $key with gpu rendering ${Init.getSetting('GPU Rendering')}');
		return FlxGraphic.fromRectangle(0, 0, 0);
	}

	static public function getTextFromFile(key:String, type:AssetType = TEXT, ?library:Null<String>):String
	{
		if (FileSystem.exists(ModManager.getModFile(key)))
			return File.getContent(ModManager.getModFile(key));

		if (FileSystem.exists(getPreloadPath(key)))
			return File.getContent(getPreloadPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			levelPath = getLibraryPathForce(key, '');
			if (FileSystem.exists(levelPath))
				return File.getContent(levelPath);
		}
		return Assets.getText(getPath(key, type, library));
	}

	public static function returnSound(path:String, key:String, ?library:String)
	{
		var modFile:String = ModManager.getModFile('$path/$key.$SOUND_EXT');
		modFile = modFile.substring(modFile.indexOf(':') + 1, modFile.length);
		if (FileSystem.exists(modFile))
		{
			if (!currentTrackedSounds.exists(modFile))
				currentTrackedSounds.set(modFile, Sound.fromFile(modFile));
			localTrackedAssets.push(key);
			return currentTrackedSounds.get(modFile);
		}

		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);

		if (!currentTrackedSounds.exists(gottenPath))
			currentTrackedSounds.set(gottenPath, Sound.fromFile(gottenPath));
		localTrackedAssets.push(key);
		return currentTrackedSounds.get(gottenPath);
	}

	//
	inline public static function getPath(file:String, ?type:AssetType, ?library:Null<String>)
	{
		if (library != null)
			return getLibraryPath(file, library);

		var levelPath = getLibraryPathForce(file, "mods");
		if (OpenFlAssets.exists(levelPath, type))
			return levelPath;

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library/$file';
	}

	public inline static function getPreloadPath(file:String)
	{
		var returnPath:String = 'assets/$file';
		if (!FileSystem.exists(returnPath))
		{
			try
			{
				returnPath = CoolUtil.swapSpaceDash(returnPath);
			}
			catch (e)
			{
				trace('$file not found, trying to search for mods...');
				returnPath = ModManager.getModFile('$file');
				if (!FileSystem.exists(returnPath))
					returnPath = CoolUtil.swapSpaceDash(ModManager.getModFile('$file'));
			}
		}
		return returnPath;
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		if (FileSystem.exists(ModManager.getModFile(key, TEXT)))
			return ModManager.getModFile(key, TEXT);

		return getPath('$key.txt', TEXT, library);
	}

	inline static public function songJson(song:String, secondSong:String, ?library:String)
	{
		var songPath:String = 'songs/${song.toLowerCase()}/${secondSong.toLowerCase()}.json';

		var isMod:Bool = false;
		if (FileSystem.exists(ModManager.getModFile(songPath, TEXT)))
			isMod = true;

		return (isMod ? ModManager.getModFile(songPath, TEXT) : getPath(songPath, TEXT, library));
	}

	static public function sound(key:String, ?library:String):Dynamic
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Dynamic
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function formatPath(path:String)
	{
		return CoolUtil.swapSpaceDash(path).toLowerCase();
	}

	inline static public function songSounds(song:String, songFile:String)
	{
		var songKey:String = '${CoolUtil.swapSpaceDash(song.toLowerCase())}/$songFile';
		var sound = returnSound('songs', songKey);
		return sound;
	}

	inline static public function image(key:String, folder:String = 'images', ?library:String)
	{
		var returnAsset:FlxGraphic = returnGraphic(key, folder, library);
		return returnAsset;
	}

	public static function font(key:String, ?library:String)
	{
		var font:String = getPath('fonts/$key.ttf', TEXT, library);
		var extensions:Array<String> = ['.ttf', '.otf'];

		for (extension in extensions)
		{
			var newPath:String = getPath('fonts/$key$extension', TEXT, library);
			if (FileSystem.exists(newPath))
			{
				/*
					clear any dots, means that something like "vcr.tff" would become "vcr";
					we are doing this because we already added an extension earlier;
					EDIT: does this even work?;
				 */
				if (key.contains('.'))
					key.substring(0, key.indexOf('.'));
				return newPath;
			}
		}

		return font; // fallback in case the font or path doesn't exist;
	}

	inline static public function getSparrowAtlas(key:String, folder:String = 'images', ?library:String)
	{
		var graphic:FlxGraphic = returnGraphic(key, folder, library);
		return (FlxAtlasFrames.fromSparrow(graphic, File.getContent(file('$folder/$key.xml', library))));
	}

	inline static public function getPackerAtlas(key:String, folder:String = 'images', ?library:String)
	{
		return (FlxAtlasFrames.fromSpriteSheetPacker(image(key, folder, library), file('$folder/$key.txt', library)));
	}

	inline static public function video(key:String, ?library:String)
	{
		var modFile:String = ModManager.getModFile('videos/$key.$VIDEO_EXT');
		if (FileSystem.exists(modFile))
			return modFile;
		return getPath('videos/$key.$VIDEO_EXT', TEXT, library);
	}
}
