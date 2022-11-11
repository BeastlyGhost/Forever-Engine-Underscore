package states.menus;

import base.Conductor;
import base.CoolUtil;
import base.MusicBeat.MusicBeatState;
import base.SongLoader.LegacySong;
import base.SongLoader.Song;
import base.WeekParser;
import dependency.Discord;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.*;
import funkin.Alphabet;
import funkin.userInterface.HealthIcon;
import openfl.media.Sound;
import sys.FileSystem;
import sys.thread.Mutex;
import sys.thread.Thread;

using StringTools;

class FreeplayMenu extends MusicBeatState
{
	static var curSelected:Int = 0;

	var curDifficulty:Int = 1;

	// background variables
	var mainColor:FlxColor = FlxColor.WHITE;
	var bg:FlxSprite;
	var scoreBG:FlxSprite;

	// score variables
	var scoreText:FlxText;
	var diffText:FlxText;
	var rateText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var lerpAcc:Float = 0.00;
	var intendedAcc:Float = 0.00;
	var intendedRank:String = 'N/A';

	// song variables
	var songThread:Thread;
	var threadActive:Bool = true;
	var mutex:Mutex;
	var songToPlay:Sound;
	var songRate:Float = 1;
	var curSongPlaying:Int = -1;
	var curPlaying:Bool = false;

	// reset score variables
	var lockedMovement:Bool = false;
	var isResetting:Bool = false;

	var grpSongs:FlxTypedGroup<Alphabet>;
	var songs:Array<SongMetadata> = [];

	var iconArray:Array<HealthIcon> = [];
	var existingSongs:Array<String> = [];
	var existingDifficulties:Array<Array<String>> = [];

	override function create()
	{
		super.create();

		mutex = new Mutex();

		// load week jsons before adding week songs
		WeekParser.loadJsons(false);

		loadSongs(true);

		#if DISCORD_RPC
		Discord.changePresence('CHOOSING A SONG', 'Freeplay Menu');
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menus/base/menuDesat'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, CoolUtil.swapSpaceDash(songs[i].songName), true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
		}

		loadUI();
		changeSelection(0, false);
	}

	function loadUI()
	{
		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - scoreText.width, 0).makeGraphic(Std.int(FlxG.width * 0.35), 106, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.alignment = CENTER;
		diffText.font = scoreText.font;
		diffText.x = scoreBG.getGraphicMidpoint().x;
		add(diffText);

		rateText = new FlxText(diffText.x, diffText.y + 36, 0, "", 24);
		rateText.alignment = CENTER;
		rateText.font = scoreText.font;
		rateText.x = scoreBG.getGraphicMidpoint().x;
		add(rateText);

		add(scoreText);
	}

	function loadSongs(includeCustom:Bool)
	{
		for (i in 0...WeekParser.weeksList.length)
		{
			// checking week's locked state before anything
			if (checkLock(WeekParser.weeksList[i]))
				continue;

			var baseWeek = WeekParser.loadedWeeks.get(WeekParser.weeksList[i]);

			var songs:Array<String> = [];
			var chars:Array<String> = [];
			var colors:Array<FlxColor> = [];

			if (!baseWeek.hideFreeplay) // no need to add week songs if they are hidden from the freeplay list;
			{
				// push song names and characters;
				for (i in 0...baseWeek.songs.length)
				{
					var baseArray = baseWeek.songs[i];

					songs.push(baseArray.name);
					chars.push(baseArray.character);

					// get out of my head get out of my head get out of my head GET OUT OF MY HEAD
					if (baseArray.colors != null)
						colors.push(FlxColor.fromRGB(baseArray.colors[0], baseArray.colors[1], baseArray.colors[2]));
					else
						colors.push(FlxColor.fromRGB(255, 255, 255));
				}

				addWeek(songs, i, chars, colors);
			}

			// add songs to the existing songs array to avoid duplicates;
			for (j in songs)
				existingSongs.push(j.toLowerCase());
		}

		if (includeCustom)
		{
			for (i in CoolUtil.returnAssetsLibrary('songs', ''))
			{
				if (!existingSongs.contains(i.toLowerCase()))
				{
					var icon:String = 'placeholder';
					var color:FlxColor = FlxColor.WHITE;
					var colorArray:Array<Int> = [255, 255, 255];
					var chartExists:Bool = FileSystem.exists(Paths.songJson(i, i));
					if (chartExists)
					{
						var castSong:LegacySong = Song.loadSong(i, i);
						icon = (castSong != null) ? castSong.player2 : 'placeholder';

						colorArray = castSong.color;

						if (colorArray != null)
							color = FlxColor.fromRGB(colorArray[0], colorArray[1], colorArray[2]);

						addSong(CoolUtil.spaceToDash(castSong.song), 1, icon, color);
					}
				}
			}
		}
	}

	function checkLock(week:String):Bool
	{
		var weekName = WeekParser.loadedWeeks.get(week);
		return (weekName.locked);
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, songColor:FlxColor)
	{
		var coolDiffs = [];
		for (i in CoolUtil.difficulties)
		{
			if (FileSystem.exists(Paths.songJson(songName, songName + '-' + i))
				|| (FileSystem.exists(Paths.songJson(songName, songName)) && i == "NORMAL"))
				coolDiffs.push(i);
		}

		if (coolDiffs.length > 0)
		{
			songs.push(new SongMetadata(songName, weekNum, songCharacter, songColor));
			existingDifficulties.push(coolDiffs);
		}
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>, ?songColor:Array<FlxColor>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];
		if (songColor == null)
			songColor = [FlxColor.WHITE];

		var num:Array<Int> = [0, 0];
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num[0]], songColor[num[1]]);

			if (songCharacters.length != 1)
				num[0]++;
			if (songColor.length != 1)
				num[1]++;
		}
	}

	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		FlxTween.color(bg, 0.35, bg.color, mainColor);

		var lerpVal = Main.framerateAdjust(0.1);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, lerpVal));
		lerpAcc = FlxMath.lerp(lerpAcc, intendedAcc, lerpVal);

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpAcc - intendedAcc) <= 0.01)
			lerpAcc = intendedAcc;

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var shiftP = FlxG.keys.pressed.SHIFT;
		var seven = FlxG.keys.justPressed.SEVEN;

		var shiftMult:Int = 1;
		if (shiftP)
			shiftMult = 3;

		if (songs.length > 0)
		{
			if (!lockedMovement)
			{
				if (upP)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (downP)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				/*
					Hold Scrolling Code
					@author ShadowMario
				 */

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
						changeDiff();
					}
				}

				if (FlxG.mouse.wheel != 0)
				{
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
					changeDiff();
				}
			}

			if (controls.BACK)
			{
				if (!isResetting)
				{
					threadActive = false;
					if (FlxG.sound.music != null && FlxG.sound.music.playing && !shiftP)
						FlxG.sound.music.stop();
					// CoolUtil.difficulties = CoolUtil.baseDifficulties;
					FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
					Main.switchState(this, new MainMenu());
				}
				else
				{
					FlxG.sound.play(Paths.sound('confirmMenu'), 0.4);
					isResetting = false;
					lockedMovement = false;
					diffText.text = '< ' + existingDifficulties[curSelected][curDifficulty] + ' - ' + intendedRank + ' >';
					diffText.color = FlxColor.WHITE;
				}
			}

			if (accepted)
				loadSong(true, true);
			else if (seven)
			{
				loadSong(false, false);
				persistentUpdate = false;
				persistentDraw = true;
				openSubState(new states.substates.EditorMenuSubstate(false));
			}

			if (controls.UI_LEFT_P && !shiftP)
				changeDiff(-1);
			else if (controls.UI_RIGHT_P && !shiftP)
				changeDiff(1);

			if (controls.UI_LEFT_P && shiftP)
				songRate -= 0.05;
			else if (controls.UI_RIGHT_P && shiftP)
				songRate += 0.05;

			if (controls.RESET && shiftP)
				songRate = 1;
			if (controls.RESET && !shiftP)
			{
				if (!isResetting)
				{
					lockedMovement = true;
					isResetting = true;
					diffText.text = 'DELETE SCORE?';
					diffText.color = FlxColor.RED;
					rateText.text = 'R = CONFIRM';
				}
				else
				{
					diffText.text = 'DATA DESTROYED';
					rateText.text = '';
					Highscore.clearData(songs[curSelected].songName, curDifficulty);
					FlxG.sound.play(Paths.sound('ANGRY'));
					iconArray[curSelected].animation.play('losing');
					isResetting = false;
					new FlxTimer().start(1, function(tmr:FlxTimer)
					{
						lockedMovement = false;
						diffText.text = '< ' + existingDifficulties[curSelected][curDifficulty] + ' - ' + intendedRank + ' >';
						diffText.color = FlxColor.WHITE;
						iconArray[curSelected].animation.play('static');
						changeSelection();
					});
				}
			}
		}

		if (songRate <= 0.5)
			songRate = 0.5;
		else if (songRate >= 3)
			songRate = 3;

		// for pitch playback
		FlxG.sound.music.pitch = songRate;

		if (!isResetting)
		{
			scoreText.text = 'PERSONAL BEST:' + lerpScore;
			rateText.text = '${Std.string(lerpAcc).substr(0, 4)}% [R] | RATE: ' + songRate + "x";
		}
		rateText.x = FlxG.width - rateText.width;
		repositionHighscore();

		mutex.acquire();
		if (songToPlay != null)
		{
			FlxG.sound.playMusic(songToPlay);

			if (FlxG.sound.music.fadeTween != null)
				FlxG.sound.music.fadeTween.cancel();

			FlxG.sound.music.volume = 0.0;
			FlxG.sound.music.fadeIn(1.0, 0.0, 1.0);
			songToPlay = null;
		}
		mutex.release();
	}

	function loadSong(go:Bool = true, stopThread:Bool = true)
	{
		var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(),
			CoolUtil.difficulties.indexOf(existingDifficulties[curSelected][curDifficulty]));

		if (existingDifficulties[curSelected][curDifficulty] == null)
			return;

		PlayState.SONG = Song.loadSong(poop, songs[curSelected].songName.toLowerCase());
		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = curDifficulty;
		PlayState.storyWeek = songs[curSelected].week;

		if (stopThread)
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
			threadActive = false;
		}
		if (go)
		{
			if (songRate < 1)
				PlayState.preventScoring = true; // lmao.
			Conductor.playbackRate = songRate;
			Main.switchState(this, new PlayState());
		}
	}

	var lastDifficulty:String;

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;
		if (lastDifficulty != null && change != 0)
			while (existingDifficulties[curSelected][curDifficulty] == lastDifficulty)
				curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = existingDifficulties[curSelected].length - 1;
		if (curDifficulty > existingDifficulties[curSelected].length - 1)
			curDifficulty = 0;

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedAcc = Highscore.getAccuracy(songs[curSelected].songName, curDifficulty);
		intendedRank = Highscore.getRank(songs[curSelected].songName, curDifficulty);

		diffText.text = '< ' + existingDifficulties[curSelected][curDifficulty] + ' - ' + intendedRank + ' >';
		lastDifficulty = existingDifficulties[curSelected][curDifficulty];
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedAcc = Highscore.getAccuracy(songs[curSelected].songName, curDifficulty);
		intendedRank = Highscore.getRank(songs[curSelected].songName, curDifficulty);

		mainColor = songs[curSelected].songColor;

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
			iconArray[i].alpha = 0.6;

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}

		changeDiff();
		changeSongPlaying();
	}

	function changeSongPlaying()
	{
		if (songThread == null)
		{
			songThread = Thread.create(function()
			{
				while (true)
				{
					if (!threadActive)
						return;

					var index:Null<Int> = Thread.readMessage(false);
					if (index != null)
					{
						if (index == curSelected && index != curSongPlaying)
						{
							var inst:Sound = Paths.songSounds(songs[curSelected].songName, 'Inst');

							if (index == curSelected && threadActive)
							{
								mutex.acquire();
								songToPlay = inst;
								mutex.release();

								curSongPlaying = curSelected;
							}
						}
					}
				}
			});
		}

		songThread.sendMessage(curSelected);
	}

	function repositionHighscore()
	{
		// Adhere the position of all the things (I'm sorry it was just so ugly before I had to fix it Shubs)
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.width = scoreText.width + 8;
		scoreBG.x = FlxG.width - scoreBG.width;
		diffText.x = scoreBG.x + (scoreBG.width / 2) - (diffText.width / 2);
		rateText.x = scoreBG.x + (scoreBG.width / 2) - (rateText.width / 2);
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var songColor:FlxColor = FlxColor.WHITE;

	public function new(song:String, week:Int, songCharacter:String, songColor:FlxColor)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.songColor = songColor;
	}
}
