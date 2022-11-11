package states.editors;

import base.Conductor;
import base.MusicBeat.MusicBeatState;
import base.SongLoader;
import dependency.AbsoluteText.EventText;
import dependency.AbsoluteText;
import dependency.BaseButton.ChartingButton;
import dependency.Discord;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.display.shapes.FlxShapeBox;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import funkin.Note;
import funkin.Strumline.Receptor;
import funkin.userInterface.HealthIcon;
import haxe.Json;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import states.menus.FreeplayMenu;

using StringTools;

#if sys
import sys.thread.Thread;
#end

/**
	As the name implies, this is the class where all of the charting state stuff happens, so when you press 7 the game
	state switches to this one, where you get to chart songs and such. I'm planning on overhauling this entirely in the future
	and making it both more practical and more user friendly.
**/
class ChartEditor extends MusicBeatState
{
	var _song:LegacySong;

	var _file:FileReference;

	var songMusic:FlxSound;
	var vocals:FlxSound;
	private var keysTotal = 8;

	var strumLine:FlxSprite;
	var strumGroup:FlxSpriteGroup;

	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var strumLineCam:FlxObject;

	public static var songPosition:Float = 0;
	public static var curSong:LegacySong;

	public static var gridSize:Int = 50;

	public var curSection:Null<Int> = 0;

	/**
	 * CURRENT / LAST PLACED NOTE;
	**/
	var curSelectedNote:Array<Dynamic>;

	var curNoteType:Int = 0;
	var playbackSpeed:Float = 1;
	var tempBpm:Float = 0;

	var dummyArrow:FlxSprite;
	var notesGroup:FlxTypedGroup<Note>;
	var holdsGroup:FlxTypedGroup<FlxSprite>;
	var sectionsGroup:FlxTypedGroup<FlxBasic>;
	var textsGroup:FlxTypedGroup<EventText>;

	var iconL:HealthIcon;
	var iconR:HealthIcon;

	var markerL:FlxSprite;
	var markerR:FlxSprite;

	final markerColors:Array<FlxColor> = [
		FlxColor.RED, FlxColor.BLUE, FlxColor.PURPLE, FlxColor.YELLOW, FlxColor.GRAY, FlxColor.PINK, FlxColor.ORANGE, FlxColor.CYAN, FlxColor.GREEN,
		FlxColor.LIME
	];
	var markerLevel:Int = 0;
	var scrollSpeed:Float = 0.75;

	final snapScrollArray:Array<Float> = [0.5, 0.75, 1, 1.05, 1.5, 2, 2.05, 2.5, 3, 3.05];
	final snapNameArray:Array<String> = ['4th', '8th', '12th', '16th', '20th', '24th', '32nd', '48th', '64th', '192th'];

	var arrowGroup:FlxTypedSpriteGroup<Receptor>;

	var buttonTextGroup:FlxTypedGroup<AbsoluteText>;
	var buttonGroup:FlxTypedGroup<ChartingButton>;

	var buttonArray:Array<Array<Dynamic>> = [];

	override public function create()
	{
		super.create();

		generateBackground();

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
			_song = Song.loadSong('test', 'test');

		#if DISCORD_RPC
		Discord.changePresence('CHART EDITOR', 'Charting: ' + _song.song + ' [${CoolUtil.difficultyFromString()}] - by ' + _song.author, null, null, null,
			true);
		#end

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		tempBpm = _song.bpm;

		generateGrid();

		notesGroup = new FlxTypedGroup<Note>();
		holdsGroup = new FlxTypedGroup<FlxSprite>();
		sectionsGroup = new FlxTypedGroup<FlxBasic>();
		textsGroup = new FlxTypedGroup<EventText>();
		buttonGroup = new FlxTypedGroup<ChartingButton>();
		buttonTextGroup = new FlxTypedGroup<AbsoluteText>();

		generateNotes();

		add(sectionsGroup);
		add(holdsGroup);
		add(notesGroup);
		add(textsGroup);
		add(buttonGroup);
		add(buttonTextGroup);

		generateButtons();

		strumLineCam = new FlxObject(0, 0);
		strumLineCam.screenCenter(X);

		// epic strum line
		strumGroup = new FlxSpriteGroup(0, 0);

		strumLine = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width / 2), 2);
		strumGroup.add(strumLine);
		strumGroup.screenCenter(X);

		// add quant markers;
		markerL = new FlxSprite(-8, -12).loadGraphic(Paths.image('menus/chart/marker'));
		markerR = new FlxSprite((FlxG.width / 2) - 8, -12).loadGraphic(Paths.image('menus/chart/marker'));
		strumGroup.add(markerL);
		strumGroup.add(markerR);

		// add health icons;
		iconL = new HealthIcon(_song.player2, false);
		iconR = new HealthIcon(_song.player1, true);
		iconL.setGraphicSize(Std.int(iconL.width / 2));
		iconR.setGraphicSize(Std.int(iconR.width / 2));

		iconL.setPosition(-64, -128);
		iconR.setPosition(strumLine.width - 80, -128);

		strumGroup.add(iconL);
		strumGroup.add(iconR);

		// add icons, the strumline, and the quant markers;
		add(strumGroup);

		// cursor
		dummyArrow = new FlxSprite().makeGraphic(gridSize, gridSize);
		dummyArrow.alpha = 0.6;
		add(dummyArrow);

		// and now the epic note thingies
		arrowGroup = new FlxTypedSpriteGroup<Receptor>(0, 0);
		for (i in 0...keysTotal)
		{
			var typeReal:Int = i;
			if (typeReal > 3)
				typeReal -= 4;

			var noteModifier:String = (_song.assetModifier == 'pixel' ? 'arrows-pixels' : 'NOTE_assets');

			var newArrow:Receptor = ForeverAssets.generateUIArrows(((FlxG.width / 2) - ((keysTotal / 2) * gridSize)) + ((i - 1) * gridSize),
				_song.assetModifier == 'pixel' ? -55 : -80, typeReal, noteModifier, _song.assetModifier);

			newArrow.ID = i;
			newArrow.setGraphicSize(gridSize);
			newArrow.updateHitbox();
			newArrow.alpha = 0.9;
			if (_song.assetModifier == 'pixel')
				newArrow.antialiasing = false;
			else
				newArrow.antialiasing = !Init.getSetting('Disable Antialiasing');

			// lol silly idiot
			newArrow.playAnim('static');

			arrowGroup.add(newArrow);
		}
		add(arrowGroup);
		arrowGroup.x -= 1;

		// code from the playstate so I can separate the camera and hud
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		FlxG.camera.follow(strumLineCam);

		generateUI();

		var cursorAsset = ForeverTools.returnSkin('cursor', 'base', Init.trueSettings.get('UI Skin'), 'UI');
		var cursor:FlxSprite = new FlxSprite().loadGraphic(Paths.image(cursorAsset));

		FlxG.mouse.visible = true;
		FlxG.mouse.load(cursor.pixels);
	}

	var songText:FlxText;
	var helpTxt:FlxText;
	var prefTxt:FlxText;
	var infoTextChart:FlxText;
	var infoStringSnap:String = '4th';

	function generateUI()
	{
		songText = new FlxText(0, 20, 0, "", 16);
		songText.setFormat(Paths.font("vcr"), 20, FlxColor.WHITE, LEFT);
		songText.scrollFactor.set();
		add(songText);

		songText.text = '${_song.song.toUpperCase()} <${CoolUtil.difficultyFromString()}> BY ${_song.author.toUpperCase()}\n';

		var sidebar = new FlxShapeBox(916, 160, 326, 480, {thickness: 24, color: FlxColor.WHITE}, FlxColor.WHITE);
		sidebar.alpha = (26 / 255);
		sidebar.cameras = [camHUD];
		add(sidebar);

		// FlxG.height - 120

		var constTextSize:Int = 24;
		infoTextChart = new FlxText(5, FlxG.height - (constTextSize * 6) - 5, 0, 'TEST', constTextSize);
		infoTextChart.setFormat(Paths.font("vcr"), constTextSize);
		infoTextChart.cameras = [camHUD];
		add(infoTextChart);

		/*
			helpTxt = new FlxText(0, 0, 0, "", 16);
			helpTxt.setFormat(Paths.font("vcr"), 20, FlxColor.WHITE, LEFT);
			helpTxt.scrollFactor.set();
			add(helpTxt);

			prefTxt = new FlxText(0, 0, 0, "", 16);
			prefTxt.setFormat(Paths.font("vcr"), 20, FlxColor.WHITE, LEFT);
			prefTxt.scrollFactor.set();
			add(prefTxt);

			helpTxt.text = 'PRESS BACKSPACE FOR HELP';
			prefTxt.text = 'PRESS ENTER FOR PREFERENCES';
			helpTxt.setPosition(FlxG.width - (helpTxt.width + 5), FlxG.height - 55);
			prefTxt.setPosition(FlxG.width - (prefTxt.width + 5), FlxG.height - 30);
		 */
	}

	function updateHUD()
	{
		// update info text;
		infoTextChart.text = 'BEAT: ${FlxMath.roundDecimal(decBeat, 2)}'
			+ ' - STEP: ${FlxMath.roundDecimal(decStep, 2)}'
			+ '\nTIME: ${FlxMath.roundDecimal(Conductor.songPosition / 1000, 2)} / ${FlxMath.roundDecimal(songMusic.length / 1000, 2)}'
			+ '\nSNAP: ${infoStringSnap}'
			+ ' - BPM: ${_song.bpm}'
			+ '\n\nRATE: ${songMusic.pitch}';

		// update markers if needed;
		markerL.color = markerColors[markerLevel];
		markerR.color = markerColors[markerLevel];

		notesGroup.forEachAlive(function(epicNote:Note)
		{
			var songCrochet = (Math.floor(Conductor.songPosition / Conductor.stepCrochet));

			// do epic note calls for strum stuffs
			if (songCrochet == Math.floor(epicNote.strumTime / Conductor.stepCrochet) && songMusic.playing)
			{
				var data:Null<Int> = epicNote.noteData;

				if (data > -1 && epicNote.mustPress != _song.notes[curSection].mustHitSection)
					data += 4;

				if (epicNote.noteData > -1)
				{
					arrowGroup.members[data].playAnim('confirm', true);
					arrowGroup.members[data].resetAnim = (epicNote.sustainLength / 1000) + 0.2;
				}

				if (!hitSoundsPlayed.contains(epicNote))
				{
					FlxG.sound.play(Paths.sound('hitsounds/${Init.getSetting('Hitsound Type').toLowerCase()}/hit'));
					hitSoundsPlayed.push(epicNote);
				}
			}
		});
	}

	var hitSoundsPlayed:Array<Note> = [];

	override public function update(elapsed:Float)
	{
		curStep = recalculateSteps();

		if (FlxG.keys.justPressed.SPACE)
		{
			if (songMusic.playing)
			{
				songMusic.pause();
				vocals.pause();
				// playButtonAnimation('pause');
			}
			else
			{
				vocals.play();
				songMusic.play();

				// reset note tick sounds
				hitSoundsPlayed = [];

				// playButtonAnimation('play');
			}
		}

		if (!FlxG.keys.pressed.SHIFT)
		{
			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				if (curStep <= 0)
					return;

				songMusic.pause();
				vocals.pause();

				var daTime:Float = 700 * FlxG.elapsed;

				if (FlxG.keys.pressed.W)
				{
					songMusic.time -= daTime;
				}
				else
					songMusic.time += daTime;

				vocals.time = songMusic.time;
			}
		}
		else
		{
			if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
			{
				if (curStep <= 0)
					return;

				songMusic.pause();
				vocals.pause();

				var daTime:Float = Conductor.stepCrochet * 2;

				if (FlxG.keys.justPressed.W)
				{
					songMusic.time -= daTime;
				}
				else
					songMusic.time += daTime;

				vocals.time = songMusic.time;
			}
		}

		if (FlxG.mouse.wheel != 0)
		{
			songMusic.pause();
			vocals.pause();

			songMusic.time = Math.max(songMusic.time - (FlxG.mouse.wheel * Conductor.stepCrochet * scrollSpeed), 0);
			songMusic.time = Math.min(songMusic.time, songMusic.length);
			vocals.time = songMusic.time;
		}

		if (FlxG.keys.justPressed.LEFT)
			changeMouseScroll(-1);
		if (FlxG.keys.justPressed.RIGHT)
			changeMouseScroll(1);

		// strumline camera stuffs!
		Conductor.songPosition = songMusic.time;

		strumGroup.y = getYfromStrum(Conductor.songPosition);
		strumLineCam.y = strumGroup.y + (FlxG.height / 3);
		arrowGroup.y = strumGroup.y;

		coolGradient.y = strumLineCam.y - (FlxG.height / 2);
		coolGrid.y = strumLineCam.y - (FlxG.height / 2);

		_song.bpm = tempBpm;

		// PLAYBACK SPEED CONTROLS //
		var holdingShift = FlxG.keys.pressed.SHIFT;
		var holdingLB = FlxG.keys.pressed.LBRACKET;
		var holdingRB = FlxG.keys.pressed.RBRACKET;
		var pressedLB = FlxG.keys.justPressed.LBRACKET;
		var pressedRB = FlxG.keys.justPressed.RBRACKET;

		if (!holdingShift && pressedLB || holdingShift && holdingLB)
			playbackSpeed -= 0.01;
		if (!holdingShift && pressedRB || holdingShift && holdingRB)
			playbackSpeed += 0.01;
		if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB))
			playbackSpeed = 1;
		//

		if (playbackSpeed <= 0.5)
			playbackSpeed = 0.5;
		if (playbackSpeed >= 3)
			playbackSpeed = 3;

		songMusic.pitch = playbackSpeed;
		vocals.pitch = playbackSpeed;

		super.update(elapsed);

		if (FlxG.mouse.x > (fullGrid.x)
			&& FlxG.mouse.x < (fullGrid.x + fullGrid.width)
			&& FlxG.mouse.y > 0
			&& FlxG.mouse.y < (getYfromStrum(songMusic.length)))
		{
			var fakeMouseX = FlxG.mouse.x - fullGrid.x;
			dummyArrow.x = (Math.floor((fakeMouseX) / gridSize) * gridSize) + fullGrid.x;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridSize) * gridSize;

			// moved this in here for the sake of not dying
			if (FlxG.mouse.justPressed)
			{
				if (!FlxG.mouse.overlaps(notesGroup))
				{
					// add note funny
					var noteStrum = getStrumTime(dummyArrow.y);

					var notesSection = Math.floor(noteStrum / (Conductor.stepCrochet * 16));
					var noteData = adjustSide(Math.floor((dummyArrow.x - fullGrid.x) / gridSize), _song.notes[notesSection].mustHitSection);
					var noteType = curNoteType;
					var noteSus = 0; // ninja you will NOT get away with this

					// noteCleanup(notesSection, noteStrum, noteData);
					// _song.notes[notesSection].sectionNotes.push([noteStrum, noteData, noteSus]);

					if (noteData > -1)
						generateChartNote(noteData, noteStrum, noteSus, 0, noteType, notesSection, true);
					/*
						else
							generateChartEvent(noteStrum, eValue1, eValue2, eName, true);
					 */
					autosaveSong();
					// updateSelection(_song.notes[notesSection].sectionNotes[_song.notes[notesSection].sectionNotes.length - 1], notesSection, true);
					// isPlacing = true;
				}
				else
				{
					notesGroup.forEachAlive(function(note:Note)
					{
						if (FlxG.mouse.overlaps(note))
						{
							if (FlxG.keys.pressed.CONTROL)
							{
								// selectNote(note);
							}
							else
							{
								note.kill();
								notesGroup.remove(note);
								note.destroy();
							}
						}
					});
				}
			}
		}

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(buttonGroup))
			{
				buttonGroup.forEach(function(button:ChartingButton)
				{
					if (FlxG.mouse.overlaps(button))
					{
						button.onClick(null);
					}
				});
			}
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
		{
			autosaveSong();
			saveLevel();
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.R)
		{
			loadAutosave();
		}

		#if debug
		if (FlxG.keys.justPressed.LEFT && FlxG.keys.pressed.A)
			Main.switchState(this, new TestState());
		#end

		if (FlxG.keys.justPressed.ESCAPE)
		{
			autosaveSong();
			songPosition = songMusic.time;
			PlayState.SONG = _song;
			FlxG.mouse.visible = false;

			ForeverTools.killMusic([songMusic, vocals]);

			Paths.clearUnusedMemory();

			Main.switchState(this, new PlayState());
		}

		if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.ESCAPE)
		{
			autosaveSong();
			FlxG.mouse.visible = false;
			ForeverTools.killMusic([songMusic, vocals]);

			Paths.clearUnusedMemory();

			// CoolUtil.difficulties = CoolUtil.baseDifficulties;

			Main.switchState(this, new FreeplayMenu());
		}

		updateHUD();
	}

	function changeMouseScroll(newSpd:Int)
	{
		markerLevel += newSpd;
		if (markerLevel < 0)
			markerLevel = snapScrollArray.length - 1;
		if (markerLevel > snapScrollArray.length - 1)
			markerLevel = 0;
		scrollSpeed = snapScrollArray[markerLevel];
		infoStringSnap = snapNameArray[markerLevel];
	}

	override public function stepHit()
	{
		super.stepHit();

		// call all rendered notes lol
		notesGroup.forEach(function(epicNote:Note)
		{
			if ((epicNote.y > (strumLineCam.y - (FlxG.height / 2) - epicNote.height))
				|| (epicNote.y < (strumLineCam.y + (FlxG.height / 2))))
			{
				epicNote.alive = true;
				epicNote.visible = true;
			}
			else
			{
				epicNote.alive = false;
				epicNote.visible = false;
			}
		});
	}

	override public function beatHit()
	{
		super.beatHit();
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, 0, (songMusic.length / Conductor.stepCrochet) * gridSize, 0, songMusic.length);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, songMusic.length, 0, (songMusic.length / Conductor.stepCrochet) * gridSize);
	}

	function getSectionBeats(?section:Null<Int> = null)
	{
		if (section == null)
			section = curSection;
		var val:Null<Float> = null;

		if (_song.notes[section] != null)
			val = _song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}

	var fullGrid:FlxTiledSprite;

	function generateGrid()
	{
		// create new sprite
		var base:FlxSprite = FlxGridOverlay.create(gridSize, gridSize, gridSize * 2, gridSize * 2, true, FlxColor.WHITE, FlxColor.BLACK);
		fullGrid = new FlxTiledSprite(null, gridSize * keysTotal, gridSize);
		// base graphic change data
		var newAlpha = (26 / 255);
		base.graphic.bitmap.colorTransform(base.graphic.bitmap.rect, new ColorTransform(1, 1, 1, newAlpha));
		fullGrid.loadGraphic(base.graphic);
		fullGrid.screenCenter(X);

		// fullgrid height
		fullGrid.height = (songMusic.length / Conductor.stepCrochet) * gridSize;
		add(fullGrid);
	}

	public var sectionLineGraphic:FlxGraphic;
	public var sectionCameraGraphic:FlxGraphic;
	public var sectionStepGraphic:FlxGraphic;

	private function regenerateSection(section:Int, placement:Float)
	{
		// this will be used to regenerate a box that shows what section the camera is focused on

		// oh and section information lol
		var sectionLine:FlxSprite = new FlxSprite(FlxG.width / 2 - (gridSize * (keysTotal / 2)) - (extraSize / 2), placement);
		sectionLine.frames = sectionLineGraphic.imageFrame;
		sectionLine.alpha = (88 / 255);

		// section camera
		var sectionExtend:Float = 0;
		if (_song.notes[section].mustHitSection)
			sectionExtend = (gridSize * (keysTotal / 2));

		var sectionCamera:FlxSprite = new FlxSprite(FlxG.width / 2 - (gridSize * (keysTotal / 2)) + (sectionExtend), placement);
		sectionCamera.frames = sectionCameraGraphic.imageFrame;
		sectionCamera.alpha = (88 / 255);
		sectionsGroup.add(sectionCamera);

		// set up section numbers
		for (i in 0...2)
		{
			var sectionNumber:FlxText = new FlxText(0, sectionLine.y - 12, 0, Std.string(section), 20);
			// set the x of the section number
			sectionNumber.x = sectionLine.x - sectionNumber.width - 5;
			if (i == 1)
				sectionNumber.x = sectionLine.x + sectionLine.width + 5;

			sectionNumber.setFormat(Paths.font("vcr"), 24, FlxColor.WHITE);
			sectionNumber.antialiasing = false;
			sectionNumber.alpha = sectionLine.alpha;
			sectionsGroup.add(sectionNumber);
		}

		for (i in 1...Std.int(getSectionBeats() * 4 / 4))
		{
			// create a smaller section stepper
			var sectionStep:FlxSprite = new FlxSprite(FlxG.width / 2 - (gridSize * (keysTotal / 2)) - (extraSize / 2), placement + (i * (gridSize * 4)));
			sectionStep.frames = sectionStepGraphic.imageFrame;
			sectionStep.alpha = sectionLine.alpha;
			sectionsGroup.add(sectionStep);
		}

		sectionsGroup.add(sectionLine);
	}

	var sectionsMax = 0;

	function generateNotes()
	{
		// GENERATING THE GRID NOTES!
		notesGroup.clear();
		holdsGroup.clear();
		textsGroup.clear();

		// sectionsMax = 1;
		generateSection();
		for (section in 0..._song.notes.length)
		{
			sectionsMax = section;
			curSection = section;
			regenerateSection(section, 16 * gridSize * section);
			setNewBPM(section);
			for (i in _song.notes[section].sectionNotes)
			{
				// note stuffs
				var daNoteAlt = 0;
				if (i.length > 2)
					daNoteAlt = i[3];
				var daNoteType = i[3];
				generateChartNote(i[1], i[0], i[2], daNoteAlt, daNoteType, section, false);
			}
		}
		// lolll
		// sectionsMax--;
	}

	var extraSize = 6;

	function generateSection()
	{
		// pregenerate assets so it doesnt destroy your ram later
		sectionLineGraphic = FlxG.bitmap.create(gridSize * keysTotal + extraSize, 2, FlxColor.WHITE);
		sectionCameraGraphic = FlxG.bitmap.create(Std.int(gridSize * (keysTotal / 2)), 16 * gridSize, FlxColor.fromRGB(43, 116, 219));
		sectionStepGraphic = FlxG.bitmap.create(gridSize * keysTotal + extraSize, 1, FlxColor.WHITE);
	}

	function loadSong(daSong:String):Void
	{
		if (songMusic != null)
			songMusic.stop();

		if (vocals != null)
			vocals.stop();

		songMusic = new FlxSound();
		vocals = new FlxSound();

		songMusic.loadEmbedded(Paths.songSounds(daSong, 'Inst'), false, true);
		if (_song.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.songSounds(daSong, 'Voices'), false, true);

		FlxG.sound.list.add(songMusic);
		FlxG.sound.list.add(vocals);

		songMusic.play();
		vocals.play();

		if (curSong == _song)
			songMusic.time = songPosition * songMusic.pitch;
		curSong = _song;
		songPosition = 0;

		pauseMusic();

		songMusic.onComplete = function()
		{
			ForeverTools.killMusic([songMusic, vocals]);
			loadSong(daSong);
		};
	}

	private function generateChartNote(daNoteInfo, daStrumTime, daSus, daNoteAlt, daNoteType, noteSection, pushNote:Bool)
	{
		var note:Note = ForeverAssets.generateArrow(_song.assetModifier, daStrumTime, daNoteInfo % 4, 0, false, null, daNoteType);
		note.sustainLength = daSus;
		note.setGraphicSize(gridSize, gridSize);
		note.updateHitbox();

		note.screenCenter(X);
		note.x -= ((gridSize * (keysTotal / 2)) - (gridSize / 2));
		note.x += Math.floor(adjustSide(daNoteInfo, _song.notes[noteSection].mustHitSection) * gridSize);

		note.y = Math.floor(getYfromStrum(daStrumTime));

		if (pushNote)
			_song.notes[noteSection].sectionNotes.push([daStrumTime, daNoteInfo % 8, daSus, '']);

		notesGroup.add(note);

		generateSustain(daStrumTime, daNoteInfo, daSus, daNoteAlt, daNoteType, note);

		// attach a text to their respective notetype;
		if (daNoteType != null && daNoteType != 0)
		{
			var noteTypeNum:EventText = new EventText(0, 0, 100, Std.string(daNoteType), 24);
			noteTypeNum.setFormat(Paths.font("vcr"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noteTypeNum.xAdd = -26;
			noteTypeNum.yAdd = 10;
			noteTypeNum.borderSize = 1;
			textsGroup.add(noteTypeNum);
			noteTypeNum.tracker = note;
		}

		note.mustPress = !_song.notes[curSection].mustHitSection;
		if (daNoteInfo > 3)
			note.mustPress = !note.mustPress;
	}

	private function generateSustain(daStrumTime:Float = 0, daNoteInfo:Int = 0, daSus:Float = 0, daNoteAlt:Float = 0, daNoteType:Int = 0, prevNote:Note)
	{
		if (daSus > 0 && prevNote != null)
		{
			// just old code from legacy
			var constSize = Std.int(gridSize / 3);

			var hold:Note = ForeverAssets.generateArrow(_song.assetModifier, daStrumTime + (Conductor.stepCrochet * daSus) + Conductor.stepCrochet,
				daNoteInfo % 4, daNoteAlt, true, prevNote, daNoteType);

			hold.setGraphicSize(constSize, getNoteVert(daSus / 2));
			hold.updateHitbox();
			hold.x = prevNote.x + constSize;
			hold.y = prevNote.y + (gridSize / 2);

			var holdEnd:Note = ForeverAssets.generateArrow(_song.assetModifier, daStrumTime + (Conductor.stepCrochet * daSus) + Conductor.stepCrochet,
				daNoteInfo % 4, daNoteAlt, true, hold, daNoteType);
			holdEnd.setGraphicSize(constSize, constSize);
			holdEnd.updateHitbox();
			holdEnd.x = hold.x;
			holdEnd.y = prevNote.y + (hold.height) + (gridSize / 2);

			holdsGroup.add(hold);
			holdsGroup.add(holdEnd);
			//
		}
	}

	function getNoteVert(newHoldLength:Float)
	{
		var constSize = Std.int(gridSize / 3);
		return Math.floor(FlxMath.remapToRange(newHoldLength, 0, Conductor.stepCrochet * songMusic.length, 0, gridSize * songMusic.length) - constSize);
	}

	var coolGrid:FlxBackdrop;
	var coolGradient:FlxSprite;

	private function generateBackground()
	{
		coolGrid = new FlxBackdrop(null, 1, 1, true, true, 1, 1);
		coolGrid.loadGraphic(Paths.image('menus/chart/grid'));
		coolGrid.alpha = (32 / 255);
		add(coolGrid);

		// gradient
		coolGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
			FlxColor.gradient(FlxColor.fromRGB(188, 158, 255, 200), FlxColor.fromRGB(80, 12, 108, 255), 16));
		coolGradient.alpha = (32 / 255);
		add(coolGradient);
	}

	function generateButtons():Void
	{
		// x, y, text on button, text size, child (optional), size ("" (medium), "big", or "small"),
		// function that will be called when pressed (optional)

		buttonArray = [
			[FlxG.width - 350, 320, "CHANGE CREDITS", 20, null, "medium", null],
			[FlxG.width - 350, 430, "CHANGE SONG NAME", 20, null, "medium", null],
			[FlxG.width - 350, 580, "SAVE CHART", 20, null, "small", null]
		];

		buttonGroup.clear();
		buttonTextGroup.clear();

		var void:Void->Void = null;

		for (i in buttonArray)
		{
			if (i != null)
			{
				// trace(i);

				switch (i[2].toLowerCase())
				{
					case 'reload song':
						void = function()
						{
							loadSong(PlayState.SONG.song);
							FlxG.resetState();
						};

					case 'save song':
						void = function()
						{
							saveLevel();
						}

					case 'load autosave':
						void = function()
						{
							PlayState.SONG = Song.parseSong(FlxG.save.data.autosave, null, null);
							FlxG.resetState();
						}
					default:
						void = i[6];
				}

				var button:ChartingButton = new ChartingButton(i[0], i[1], i[5], null);
				button.child = i[4];
				button.clickThing = void;
				buttonGroup.add(button);

				var text:AbsoluteText = new AbsoluteText(i[2], i[3], button, 10, 10);
				text.scrollFactor.set();
				buttonTextGroup.add(text);
			}
		}
	}

	function adjustSide(noteData:Int, sectionTemp:Bool)
	{
		return (sectionTemp ? ((noteData + 4) % 8) : noteData);
	}

	function setNewBPM(section:Int)
	{
		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSection].bpm);
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}
	}

	function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (songMusic.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((songMusic.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function autosaveSong():Void
	{
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && data.length > 0)
		{
			FlxG.save.data.autosave = data;
		}
		FlxG.save.flush();
	}

	function loadAutosave():Void
	{
		try
		{
			PlayState.SONG = Song.parseSong(FlxG.save.data.autosave, null, null);
			FlxG.resetState();
		}
		catch (e)
		{
			return;
		}
	}

	// save things
	function saveLevel()
	{
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

	function pauseMusic()
	{
		songMusic.time = Math.max(songMusic.time, 0);
		songMusic.time = Math.min(songMusic.time, songMusic.length);

		resyncVocals();
		songMusic.pause();
		vocals.pause();
	}

	function resyncVocals():Void
	{
		vocals.pause();

		songMusic.play();
		Conductor.songPosition = songMusic.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}
}
