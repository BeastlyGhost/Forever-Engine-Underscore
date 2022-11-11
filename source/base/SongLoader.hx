package base;

import haxe.Json;
import sys.io.File;

using StringTools;

/**
 * tbh, i think the legacy fnf format sucks ass
 * i'm gonna try to write a new one later with compatibility
 * for base game charts and such
 * -gabi (BeastlyGhost)
 */
typedef LegacySong =
{
	var song:String;
	var notes:Array<LegacySection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var noteSkin:String;
	var splashSkin:String;
	var author:String;
	var assetModifier:String;
	var validScore:Bool;
	var events:Array<Array<Dynamic>>;
	var ?offset:Float;
	var ?color:Array<Int>;

	@:optional public dynamic function copy():LegacySong;
}

typedef LegacySection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int; // for Legacy Charts;
	var sectionBeats:Float; // for Psych Engine v0.6+ chart compatibility;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

typedef SongInfo =
{
	var author:String;
	var assetModifier:String;
	var ?offset:Float;
	var ?color:Array<Int>;
}

typedef TimedEvent =
{
	public var strumTime:Float;
	public var event:String;
	public var val1:String;
	public var val2:String;
	public var val3:String;
	@:optional public var color:Array<Int>;
}

class Song
{
	public var song:String;
	public var notes:Array<LegacySection>;

	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadSong(jsonInput:String, ?folder:String):LegacySong
	{
		var rawJson:String = null;
		var rawMeta:String = null;
		var rawEvent:String = null;

		rawJson = getData(rawJson, folder, jsonInput);
		rawEvent = getData(rawJson, folder, 'events');
		rawMeta = getData(rawJson, folder, 'meta');

		dataCleanup(rawJson);
		dataCleanup(rawEvent);
		dataCleanup(rawMeta);

		if (rawMeta == null)
		{
			rawMeta = '{
				"author": "???",
				"assetModifier": "base",
				"offset": 0,
				"color": [255, 255, 255]
			}';
		}

		return parseSong(rawJson, rawMeta, rawEvent);
	}

	public static function parseSong(rawJson:String, rawMeta:String, rawEvent:String):LegacySong
	{
		var oldSong:LegacySong = cast Json.parse(rawJson).song;
		oldSong.validScore = true;
		oldSong.copy = function()
		{
			return cast {
				validScore: oldSong.validScore,
				stage: oldSong.stage,
				splashSkin: oldSong.splashSkin,
				speed: oldSong.speed,
				song: oldSong.song,
				player2: oldSong.player2,
				player1: oldSong.player1,
				notes: oldSong.notes,
				noteSkin: oldSong.noteSkin,
				needsVoices: oldSong.needsVoices,
				gfVersion: oldSong.gfVersion,
				events: [],
				bpm: oldSong.bpm,
				author: oldSong.author,
				assetModifiler: oldSong.assetModifier
			};
		};
		oldSong.events = parseEvent(rawEvent).copy();
		if (oldSong.events == null)
			oldSong.events = [];

		if (rawMeta != null)
		{
			var songMeta:SongInfo = cast Json.parse(rawMeta);

			// injecting info from the meta file if it's valid data, else get from the song data
			// please spare me I know it looks weird.
			if (songMeta.assetModifier != null)
				oldSong.assetModifier = songMeta.assetModifier;
			else if (songMeta.assetModifier == null)
				oldSong.assetModifier = oldSong.assetModifier;
			else
				oldSong.assetModifier == 'base';

			if (songMeta.author != null)
				oldSong.author = songMeta.author;
			else if (songMeta.author == null)
				oldSong.author = oldSong.author;
			else
				oldSong.author = '???';

			if (songMeta.offset != null)
				oldSong.offset = songMeta.offset;
			else if (songMeta.offset == null)
				oldSong.offset = oldSong.offset;
			else
				oldSong.offset = 0;

			if (songMeta.color != null)
				oldSong.color = songMeta.color;
			else if (songMeta.color == null)
				oldSong.color = oldSong.color;
			else
				oldSong.color = [255, 255, 255];
		}

		return oldSong;
	}

	static function getData(data:String, path:String, secondPath:String)
	{
		return try
		{
			data = File.getContent(Paths.songJson(path.toLowerCase(), secondPath.toLowerCase())).trim();
		}
		catch (e)
		{
			return data = null;
		}
	}

	static function dataCleanup(raw:String)
	{
		if (raw != null)
		{
			while (!raw.endsWith("}"))
				raw = raw.substr(0, raw.length - 1);
		}
	}

	static function parseEvent(rawEvent:String)
	{
		return try
		{
			var array:Array<Dynamic> = cast haxe.Json.parse(rawEvent).events;
			array.copy();
		}
		catch (e)
		{
			[];
		}
	}
}

class Section
{
	public var sectionNotes:Array<Dynamic> = [];

	public var lengthInSteps:Int = 16;
	public var sectionBeats:Float = 4;
	public var typeOfSection:Int = 0;
	public var gfSection:Bool = false;
	public var mustHitSection:Bool = true;

	/**
	 *	Copies the first section into the second section!
	 */
	public static var COPYCAT:Int = 0;

	public function new(sectionBeats:Float = 4, lengthInSteps:Int = 16)
	{
		this.sectionBeats = sectionBeats;
		this.lengthInSteps = lengthInSteps;
	}
}
