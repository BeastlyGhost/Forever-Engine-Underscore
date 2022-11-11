package funkin;

import flixel.FlxG;

using StringTools;

class Highscore
{
	#if (haxe >= "4.0.0")
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map();
	public static var songRanks:Map<String, String> = new Map();
	public static var songAccuracy:Map<String, Float> = new Map();
	#else
	public static var weekScores:Map<String, Int> = new Map<String, Int>();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRanks:Map<String, String> = new Map<String, String>();
	public static var songAccuracy:Map<String, Float> = new Map<String, Float>();
	#end

	public static function clearData(song:String, diff:Int = 0):Void
	{
		FlxG.save.bind('gameScores');

		var daSong:String = formatSong(song, diff);
		setScore(daSong, 0);
		setRank(daSong, 'N/A');
		setAccuracy(daSong, 0.00);
	}

	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);

		if (songScores.exists(daSong))
		{
			if (songScores.get(daSong) < score)
				setScore(daSong, score);
		}
		else
			setScore(daSong, score);
	}

	public static function saveWeekScore(week:Int = 1, score:Int = 0, ?diff:Int = 0):Void
	{
		var daWeek:String = formatSong('week' + week, diff);

		if (weekScores.exists(daWeek))
		{
			if (weekScores.get(daWeek) < score)
				setWeekScore(daWeek, score);
		}
		else
			setWeekScore(daWeek, score);
	}

	public static function saveRank(song:String, rank:String = 'N/A', ?diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);

		if (songRanks.exists(daSong))
		{
			if (getRankInt(songRanks.get(daSong)) < getRankInt(rank))
				setRank(daSong, rank);
		}
		else
			setRank(daSong, rank);
	}

	public static function saveAccuracy(song:String, accuracy:Float = 0.00, ?diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);

		if (songAccuracy.exists(daSong))
		{
			if (songAccuracy.get(daSong) < accuracy)
				setAccuracy(daSong, accuracy);
		}
		else
			setAccuracy(daSong, accuracy);
	}

	static function getRankInt(rank:String):Int
	{
		switch (rank)
		{
			case 'F':
				return 0;
			case 'E':
				return 1;
			case 'D':
				return 2;
			case 'C':
				return 3;
			case 'B':
				return 4;
			case 'A':
				return 5;
			case 'S':
				return 6;
			case 'S+':
				return 7;
			default:
				return -1;
		}
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	public static function formatSong(song:String, diff:Int):String
	{
		var daSong:String = song;

		var difficulty:String = CoolUtil.returnDifficultySuffix(diff).toLowerCase();
		daSong += difficulty;

		return daSong;
	}

	public static function getScore(song:String, diff:Int):Int
	{
		FlxG.save.bind('gameScores');

		if (!songScores.exists(formatSong(song, diff)))
			setScore(formatSong(song, diff), 0);

		return songScores.get(formatSong(song, diff));
	}

	public static function getWeekScore(week:Int, diff:Int):Int
	{
		FlxG.save.bind('gameScores');

		if (!weekScores.exists(formatSong('week' + week, diff)))
			setScore(formatSong('week' + week, diff), 0);

		return weekScores.get(formatSong('week' + week, diff));
	}

	public static function getRank(song:String, diff:Int):String
	{
		FlxG.save.bind('gameScores');

		if (!songRanks.exists(formatSong(song, diff)))
			setRank(formatSong(song, diff), Timings.returnScoreRating().toUpperCase());

		return songRanks.get(formatSong(song, diff));
	}

	public static function getAccuracy(song:String, diff:Int):Float
	{
		FlxG.save.bind('gameScores');

		if (!songAccuracy.exists(formatSong(song, diff)))
			setScore(formatSong(song, diff), 0);

		return songAccuracy.get(formatSong(song, diff));
	}

	static function setScore(song:String, score:Int):Void
	{
		FlxG.save.bind('gameScores');

		// Reminder that I don't need to format this song, it should come formatted!
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	static function setWeekScore(week:String, score:Int):Void
	{
		FlxG.save.bind('gameScores');

		// Reminder that I don't need to format this song, it should come formatted!
		weekScores.set(week, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	static function setRank(song:String, rank:String = 'N/A'):Void
	{
		FlxG.save.bind('gameScores');

		// Reminder that I don't need to format this song, it should come formatted!
		songRanks.set(song, rank);
		FlxG.save.data.songRanks = songRanks;
		FlxG.save.flush();
	}

	static function setAccuracy(song:String, accuracy:Float):Void
	{
		FlxG.save.bind('gameScores');

		// Reminder that I don't need to format this song, it should come formatted!
		songAccuracy.set(song, accuracy);
		FlxG.save.data.songAccuracy = songAccuracy;
		FlxG.save.flush();
	}

	public static function load():Void
	{
		FlxG.save.bind('gameScores');
		if (FlxG.save.data.weekScores != null)
		{
			weekScores = FlxG.save.data.weekScores;
		}
		if (FlxG.save.data.songScores != null)
		{
			songScores = FlxG.save.data.songScores;
		}
		if (FlxG.save.data.songRanks != null)
		{
			songRanks = FlxG.save.data.songRanks;
		}
		if (FlxG.save.data.songAccuracy != null)
		{
			songAccuracy = FlxG.save.data.songAccuracy;
		}
		FlxG.save.flush();
	}
}
