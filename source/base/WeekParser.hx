package base;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

typedef WeekDataDef =
{
	var songs:Array<WeekSongDef>;
	var locked:Bool;
	var weekCharacters:Array<String>;
	var weekName:String;
	var weekImage:String;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
}

typedef WeekSongDef =
{
	var name:String;
	var character:String;
	var colors:Array<Int>;
}

class WeekParser
{
	public static var loadedWeeks:Map<String, WeekDataDef> = [];
	public static var weeksList:Array<String> = [];

	public static function loadJsons(isStoryMode:Bool = false)
	{
		loadedWeeks.clear();
		weeksList = [];

		var list:Array<String> = CoolUtil.coolTextFile(Paths.txt('weeks/weekList'));
		for (i in 0...list.length)
		{
			if (!loadedWeeks.exists(list[i]))
			{
				var week:WeekDataDef = parseJson(Paths.file('weeks/' + list[i] + '.json'));
				if (week != null)
				{
					if (week != null && (isStoryMode && !week.hideStoryMode) || (!isStoryMode && !week.hideFreeplay))
					{
						loadedWeeks.set(list[i], week);
						weeksList.push(list[i]);
					}
				}
			}
		}
	}

	public static function parseJson(path:String):WeekDataDef
	{
		var rawJson:String = null;

		if (FileSystem.exists(path))
			rawJson = File.getContent(path);

		return Json.parse(rawJson);
	}
}
