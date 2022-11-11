package base;

import flixel.FlxG;
import openfl.Assets;
import states.PlayState;
import sys.FileSystem;

using StringTools;

class CoolUtil
{
	public static var baseDifficulties:Array<String> = ["EASY", "NORMAL", "HARD"];

	public static var difficulties:Array<String> = [];

	public static var difficultyLength = difficulties.length;

	inline public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	inline public static function returnDifficultySuffix(number:Null<Int> = null):String
	{
		if (number == null)
			number = PlayState.storyDifficulty;
		var suffix:String = difficulties[number];
		suffix = (suffix != 'NORMAL' ? '-' + suffix : '');
		return suffix;
	}

	inline public static function difficultyFromString():String
	{
		var string = returnDifficultySuffix().replace('-', '');
		if (string == '' || string == null)
			string = 'NORMAL';
		return string;
	}

	public static function dashToSpace(string:String):String
	{
		return string.replace("-", " ");
	}

	public static function spaceToDash(string:String):String
	{
		return string.replace(" ", "-");
	}

	public static function swapSpaceDash(string:String):String
	{
		return StringTools.contains(string, '-') ? dashToSpace(string) : spaceToDash(string);
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];

		if (Assets.exists(path))
			daList = Assets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	public static function returnAssetsLibrary(library:String, ?subDir:String = 'images'):Array<String>
	{
		var libraryArray:Array<String> = [];
		var unfilteredLibrary = FileSystem.readDirectory('assets/$subDir/$library');

		try
		{
			if (FileSystem.exists('assets/$subDir/$library'))
			{
				for (folder in unfilteredLibrary)
					if (!folder.contains('.'))
						libraryArray.push(folder);
			}
		}
		catch (e)
		{
			trace('$subDir/$library is returning null');
		}

		// mods, will change this later
		/*
			var modRoot = ModManager.getModFile('$subDir/$library');
			var unfilteredMod = FileSystem.readDirectory(modRoot);

			if (FileSystem.exists(modRoot))
			{
				for (folder in unfilteredMod)
					if (!folder.contains('.'))
						libraryArray.push(folder);
			}
		 */

		return libraryArray;
	}

	public static function getAnimsFromTxt(path:String):Array<Array<String>>
	{
		var daList:Array<String> = [];

		if (Assets.exists(path))
			daList = Assets.getText(path).trim().split('\n');

		var swagOffsets:Array<Array<String>> = [];

		for (i in daList)
			swagOffsets.push(i.split('--'));

		return swagOffsets;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
			dumbArray.push(i);

		return dumbArray;
	}

	public static function browserLoad(site:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	/**
		Returns an array with the files of the specified directory.

		Example usage:

		var fileArray:Array<String> = CoolUtil.absoluteDirectory('scripts');
		trace(fileArray); -> ['mods/scripts/modchart.hx', 'assets/scripts/script.hx']
	**/
	public static function absoluteDirectory(file:String):Array<String>
	{
		if (!file.endsWith('/'))
			file = '$file/';

		var path:String = Paths.getPath(file);
		// if (!ForeverTools.fileExists(file))
		//	path = ModManager.getModFile(file);

		var absolutePath:String = FileSystem.absolutePath(path);
		var directory:Array<String> = FileSystem.readDirectory(absolutePath);

		if (directory != null)
		{
			var dirCopy:Array<String> = directory.copy();

			for (i in dirCopy)
			{
				var index:Int = dirCopy.indexOf(i);
				var file:String = '$path$i';
				dirCopy.remove(i);
				dirCopy.insert(index, file);
			}

			directory = dirCopy;
		}

		return if (directory != null) directory else [];
	}
}
