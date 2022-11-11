package base;

import base.SongLoader.LegacySong;
import flixel.FlxG;
import flixel.system.FlxSound;
import states.PlayState;

using StringTools;

/*
	Stuff like this is why this is a mod engine and not a rewrite.
	I'm not going to pretend to know what any of this does and I don't really have the motivation to
	go through it and rewrite it if I think it works just fine, but there are other aspects that I wanted to
	change about the game entirely which I wanted to rewrite so that's why I made this.

	I'll take a look later if it's important for anything. Otherwise, I don't think this code needs to be edited
	for things like other mods and such, maybe for base engine functions. who knows? we'll see.

	Told myself I wasn't gonna bother with this cus I was lazy but now I actually have to and I hate myself for not doing it earlier!
 */
typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Conductor
{
	public static var bpm:Float = 100;
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds

	public static var lastSongPos:Float;

	public static var songPosition:Float;
	public static var safeZoneOffset:Float = 0; // song chart offset;

	public static var songMusic:FlxSound;
	public static var songVocals:FlxSound;
	public static var playbackRate:Float = 1; // song playback speed (also affects pitch);

	public static var vocalArray:Array<FlxSound> = [];
	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static function mapBPMChanges(song:LegacySong)
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;

		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = Math.round(getSectionBeats(song, i) * 4);
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
	}

	public static function changeBPM(newBpm:Float, measure:Float = 4 / 4)
	{
		bpm = newBpm;

		crochet = ((60 / bpm) * 1000);
		stepCrochet = (crochet / 4) * measure;
	}

	/**
	 * new code for lengthInSteps that my friend ShadowMario made;
	 * it's probably unlikely, but if you didn't check out Psych Engine yet, give it a chance;
	 * it provides ease of access and reliability, along with mod support;
	 * https://github.com/ShadowMario/FNF-PsychEngine;
	**/
	static function getSectionBeats(song:LegacySong, section:Int)
	{
		var val:Null<Float> = null;
		if (song.notes[section] != null)
			val = song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}

	public static function bindMusic()
	{
		var songData = PlayState.SONG;

		songMusic = new FlxSound();
		songVocals = new FlxSound();

		songMusic.loadEmbedded(Paths.songSounds(songData.song, 'Inst'), false, true);
		FlxG.sound.list.add(songMusic);
		songMusic.pitch = playbackRate;

		if (songData.needsVoices)
		{
			// im assuming a lot of things here
			songVocals.loadEmbedded(Paths.songSounds(songData.song, 'Voices'), false, true);
			FlxG.sound.list.add(songVocals);
		}

		if (songVocals != null)
		{
			songVocals.pitch = playbackRate;
			vocalArray.push(songVocals);
		}
	}

	public static function startMusic()
	{
		songMusic.play();
		for (vocals in vocalArray)
		{
			if (vocals != null && !vocals.playing)
				vocals.play();
		}
		resyncVocals();
	}

	public static function pauseMusic()
	{
		songMusic.time = Math.max(songMusic.time, 0);
		songMusic.time = Math.min(songMusic.time, songMusic.length);
		songMusic.pause();

		for (vocals in vocalArray)
		{
			if (vocals != null && vocals.playing)
				vocals.pause();
		}
	}

	public static function stopMusic()
	{
		if (songMusic != null)
			songMusic.stop();
		for (vocals in vocalArray)
			if (vocals != null)
				vocals.stop();
	}

	public static function killMusic()
	{
		ForeverTools.killMusic([songMusic, allVocals()]);
	}

	public static function resyncVocals():Void
	{
		PlayState.contents.callFunc('resyncVocals', []);

		allVocals().pause();

		songMusic.play();
		songMusic.pitch = playbackRate;

		songPosition = songMusic.time;

		if (vocalArray != null)
		{
			if (songPosition <= songVocals.length)
				allVocals().time = songPosition;
			allVocals().play();
		}
	}

	public static function allVocals():FlxSound
	{
		for (v in vocalArray)
			return v;
		return null;
	}
}
