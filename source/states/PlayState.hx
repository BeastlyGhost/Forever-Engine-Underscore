package states;

import base.*;
import base.Controls.Control;
import base.MusicBeat.MusicBeatState;
import base.SongLoader.LegacySong;
import base.SongLoader.Song;
import base.SongLoader;
import dependency.*;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.OverlayShader;
import flixel.addons.display.FlxRuntimeShader;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import funkin.*;
import funkin.Strumline.Receptor;
import funkin.userInterface.*;
import lime.app.Application;
import openfl.display.BlendMode;
import openfl.display.GraphicsShader;
import openfl.events.KeyboardEvent;
import openfl.filters.ShaderFilter;
import states.editors.*;
import states.menus.*;
import states.substates.*;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if VIDEO_PLUGIN
import vlc.MP4Handler;
#end

class PlayState extends MusicBeatState
{
	// checks if stored memory should be cleared when leaving this state;
	public static var clearStored:Bool = true;

	// for scripts;
	public static var contents:PlayState;
	public static var scriptArray:Array<ScriptHandler>;

	// story mode stuffs, such as current week, difficulty, and song playlist;
	public static var storyWeek:Int = 0;
	public static var storyDifficulty:Int = 1;
	public static var isStoryMode:Bool = false;
	public static var storyPlaylist:Array<String> = [];
	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;

	// current stage name;
	public static var curStage:String = '';

	// stage variable so we can create stages later;
	public var stageBuild:Stage;

	// a stage group, for change stage events;
	public var stageGroup:FlxTypedGroup<Stage>;

	// song loading;
	public static var SONG:LegacySong;
	public static var generatedSong:Bool = false;
	public static var unspawnNotes:Array<Note>;

	// custom assets;
	public static var assetModifier:String = 'base';
	public static var uiModifier:String = 'default';

	// characters;
	public static var dad:Character;
	public static var gf:Character;
	public static var boyfriend:Character;

	// camera values;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	static var prevCamFollow:FlxObject;

	// Discord RPC variables;
	public static var songDetails:String = "";
	public static var detailsSub:String = "";
	public static var detailsPausedText:String = "";
	public static var iconRPC:String = "";
	public static var songLength:Float = 0;

	// girlfriend's headbop speed;
	public var gfSpeed:Int = 1;

	// timer for countdown ticks;
	public static var startTimer:FlxTimer;

	// other gameplay values;
	public var startingSong:Bool = false;
	public var endingSong:Bool = false;

	public var canPause:Bool = true;
	public var paused:Bool = false;

	public var startedCountdown:Bool = false;
	public var skipCountdown:Bool = false;
	public var inCutscene:Bool = false;

	// cameras;
	public static var camHUD:FlxCamera;
	public static var camGame:FlxCamera;
	public static var camAlt:FlxCamera;
	public static var dialogueHUD:FlxCamera;
	public static var comboHUD:FlxCamera;
	public static var strumHUD:Array<FlxCamera>;

	public var camDisplaceX:Float = 0;
	public var camDisplaceY:Float = 0; // might not use depending on result

	public static var cameraSpeed:Float = 1;
	public static var defaultCamZoom:Float = 1.05;
	public static var forceZoom:Array<Float>;
	public static var camZooming:Bool = true;

	// player status;
	public static var songScore:Int = 0;
	public static var health:Float = 1; // mario
	public static var maxHealth:Float = 2;
	public static var combo:Int = 0;
	public static var misses:Int = 0;
	public static var deaths:Int = 0; // luigi

	// stores your accuracy and ranking so we can save it later to the Highscores;
	public static var accuracy:Float = 0.00;
	public static var rank:String = 'N/A';

	// darkness background for stages / notes;
	public var darknessBG:FlxSprite;
	public var darknessLine1:FlxSprite;
	public var darknessLine2:FlxSprite;

	// i hate that i have to do this shit twice for the opponent strumlines but eh;
	public var darknessOpponent:FlxSprite;
	public var darknessLine3:FlxSprite;
	public var darknessLine4:FlxSprite;

	// game hud, which will be set up later;
	public static var uiHUD:ClassHUD;

	// fuck you ninjamuffin;
	public static var daPixelZoom:Float = 6;

	// strumlines;
	public static var dadStrums:Strumline;
	public static var bfStrums:Strumline;
	public static var strumLines:FlxTypedGroup<Strumline>;

	// stores all UI cameras in an array;
	public var allUIs:Array<FlxCamera> = [];

	// prevents your score, accuracy and ranking from saving;
	public static var preventScoring:Bool = false;

	// prevents you from going back to menus, also adds useful tools on the pause menu;
	public static var chartingMode:Bool = false;

	// prevents you from dying;
	public static var practiceMode:Bool = false;

	// allows time skipping and song ending via keybinds;
	public static var scriptDebugMode:Bool = false;

	// whether time was skipped, used to avoid misses when "traveling through time";
	public var usedTimeTravel:Bool = false;

	// set only once;
	public static var lastEditor:Int = 0;

	var curSection:Int = 0;

	// groups so we can recycle judgements and combo with ease;
	public var judgementsGroup:FlxTypedGroup<FNFSprite>;
	public var comboGroup:FlxTypedGroup<FNFSprite>;

	// a character group, for change character events;
	public var charGroup:FlxSpriteGroup;

	// stores the last judgement sprite object;
	public static var lastJudge:FNFSprite;
	// stores the last combo sprite objects in an array;
	public static var lastCombo:Array<FNFSprite>;

	var events:Array<TimedEvent> = [];

	function resetVariables()
	{
		contents = this;

		songScore = 0;
		rank = 'N/A';
		combo = 0;
		health = 1;
		misses = 0;
		scriptDebugMode = false;

		defaultCamZoom = 1.05;
		cameraSpeed = 1 * Conductor.playbackRate;
		forceZoom = [0, 0, 0, 0];

		scriptArray = [];
		lastCombo = [];

		assetModifier = 'base';
		uiModifier = 'default';
	}

	/**
	 * Simply put, a Function to Precache Sounds and Songs;
	 * when adding yours, make sure to use `FlxSound` and `volume = 0.00000001`;
	**/
	function precacheSounds()
	{
		var soundArray:Array<String> = [];

		// push your sound paths to this array
		if (Init.getSetting('Hitsound Volume') > 0)
			soundArray.push('hitsounds/${Init.getSetting("Hitsound Type")}/hit');

		for (i in soundArray)
		{
			var allSounds:FlxSound = new FlxSound().loadEmbedded(Paths.sound(i));
			allSounds.volume = 0.000001;
			allSounds.play();
		}

		for (i in 0...4)
		{
			var missSounds:FlxSound = new FlxSound().loadEmbedded(Paths.sound('missnote' + i));
			missSounds.volume = 0.000001;
			missSounds.play();
		}
	}

	/*
		a Function to Precache Images;
		will improve this system eventually;
	 */
	function precacheImages()
	{
		Paths.image('UI/default/base/alphabet');
		if (boyfriend.characterType == boyfriend.characterOrigin.UNDERSCORE)
			Paths.getSparrowAtlas(GameOverSubstate.character, 'characters/' + GameOverSubstate.character);
	}

	/**
	 * Sorts through possible notes, author @Shadow_Mario
	 */
	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, Std.int(a.strumTime), Std.int(b.strumTime));
	}

	function doTweenCheck(isDad:Bool = false):Bool
	{
		if (isDad && Init.getSetting('Centered Receptors'))
			return false;
		if (skipCountdown)
			return false;
		return true;
	}

	public function new(songPosition:Float = null):Void
	{
		// set song position before beginning
		if (songPosition == null)
			Conductor.songPosition = -(Conductor.crochet * 4);
		else if (songPosition > -(Conductor.crochet * 4))
			skipCountdown = true;

		super();
	}

	function generateCharacters()
	{
		dad = new Character(false);
		boyfriend = new Character(true);
		gf = new Character(false);

		if (SONG.gfVersion.length < 1 || SONG.gfVersion == null)
			gf.setCharacter(0, 0, stageBuild.returnGFtype(curStage))
		else
			gf.setCharacter(0, 0, SONG.gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		dad.setCharacter(0, 0, SONG.player2);
		boyfriend.setCharacter(0, 0, SONG.player1);

		// add characters
		if (stageBuild.spawnGirlfriend)
			add(gf);

		add(stageBuild.layers);

		add(dad);
		add(boyfriend);
		add(stageBuild.foreground);

		// force them to dance
		dad.dance();
		gf.dance();
		boyfriend.dance();

		characterPostGeneration();
	}

	function regenerateCharacters()
	{
		remove(gf);
		remove(dad);
		remove(boyfriend);

		// add characters
		if (stageBuild.spawnGirlfriend)
			add(gf);

		add(stageBuild.layers);

		add(dad);
		add(boyfriend);
		add(stageBuild.foreground);

		// force them to dance
		dad.dance();
		gf.dance();
		boyfriend.dance();

		characterPostGeneration();
	}

	function characterPostGeneration()
	{
		boyfriend.setPosition(stageBuild.stageJson.bfPos[0], stageBuild.stageJson.bfPos[1]);
		dad.setPosition(stageBuild.stageJson.dadPos[0], stageBuild.stageJson.dadPos[1]);
		gf.setPosition(stageBuild.stageJson.gfPos[0], stageBuild.stageJson.gfPos[1]);

		boyfriend.adjustPosition();
		dad.adjustPosition();

		stageBuild.repositionPlayers(curStage, boyfriend, gf, dad);
		stageBuild.dadPosition(curStage, boyfriend, gf, dad, new FlxPoint(gf.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100));
		defaultCamZoom = stageBuild.stageJson.defaultZoom;
	}

	function loadUIDarken()
	{
		remove(darknessBG);
		remove(darknessLine1);
		remove(darknessLine2);
		remove(darknessLine3);
		remove(darknessLine4);

		if (Init.getSetting('Opacity Type') == 'Notes')
		{
			// unoptimized darkness background for notes;
			darknessBG = new FlxSprite(0, 0).makeGraphic(100 * 4 + 50, FlxG.height, FlxColor.BLACK);

			var lineColorP1 = 0xFF66FF33;

			if (Init.getSetting('Colored Health Bar'))
				lineColorP1 = FlxColor.fromRGB(boyfriend.characterData.barColor[0], boyfriend.characterData.barColor[1], boyfriend.characterData.barColor[2]);

			darknessLine1 = new FlxSprite(0, 0).makeGraphic(5, FlxG.height, lineColorP1);
			darknessLine2 = new FlxSprite(0, 0).loadGraphicFromSprite(darknessLine1);

			add(darknessBG);
			add(darknessLine1);
			add(darknessLine2);

			for (dark in [darknessBG, darknessLine1, darknessLine2])
			{
				dark.alpha = 0;
				dark.cameras = [camHUD];
				dark.scrollFactor.set();
				dark.screenCenter(Y);
			}

			// for the opponent
			if (!Init.getSetting('Centered Receptors'))
			{
				var lineColorP2 = 0xFFFF0000;

				if (Init.getSetting('Colored Health Bar'))
					lineColorP2 = FlxColor.fromRGB(dad.characterData.barColor[0], dad.characterData.barColor[1], dad.characterData.barColor[2]);

				darknessOpponent = new FlxSprite(0, 0).loadGraphicFromSprite(darknessBG);
				darknessLine3 = new FlxSprite(0, 0).makeGraphic(5, FlxG.height, lineColorP2);
				darknessLine4 = new FlxSprite(0, 0).loadGraphicFromSprite(darknessLine3);

				add(darknessOpponent);
				add(darknessLine3);
				add(darknessLine4);

				for (dark in [darknessOpponent, darknessLine3, darknessLine4])
				{
					dark.alpha = 0;
					dark.cameras = [camHUD];
					dark.scrollFactor.set();
					dark.screenCenter(Y);
				}
			}
		}
		else
		{
			darknessBG = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
			darknessBG.alpha = (Init.getSetting('Darkness Opacity') * 0.01);
			darknessBG.scrollFactor.set(0, 0);
			add(darknessBG);
		}
	}

	// at the beginning of the playstate
	override public function create()
	{
		super.create();

		// reset any values and variables that are static
		resetVariables();

		Timings.callAccuracy();

		// stop any existing music tracks playing
		Conductor.stopMusic();
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// create the game camera
		camGame = new FlxCamera();

		// create the hud camera (separate so the hud stays on screen)
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		// create an alternative camera, in case you need a third one for scripts
		camAlt = new FlxCamera();
		camAlt.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camAlt, false);

		allUIs.push(camHUD);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		// default song
		if (SONG == null)
			SONG = Song.loadSong('test', 'test');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		GameOverSubstate.resetGameOver();

		curStage = "";

		// call the song's stage if it exists
		if (SONG.stage != null)
			curStage = SONG.stage;
		else
			curStage = 'unknown';

		try
		{
			setupScripts();
		}
		catch (e)
		{
			logTrace('Uncaught Error: $e', 3, camAlt);
		}

		stageBuild = new Stage(PlayState.curStage);
		//add(stageBuild);

		stageGroup = new FlxTypedGroup<Stage>();
		add(stageGroup);

		stageGroup.add(stageBuild);

		// set up characters
		generateCharacters();

		charGroup = new FlxSpriteGroup();
		charGroup.alpha = 0.00001;

		var camPos:FlxPoint = new FlxPoint(gf.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

		uiModifier = Init.getSetting("UI Skin");
		assetModifier = SONG.assetModifier;

		add(charGroup); // for changecharacter;

		// set song position before beginning
		Conductor.songPosition = -(Conductor.crochet * 4);

		// EVERYTHING SHOULD GO UNDER THIS, IF YOU PLAN ON SPAWNING SOMETHING LATER ADD IT TO STAGEBUILD OR FOREGROUND
		// darkens the notes / stage according to the opacity type option
		loadUIDarken();

		// strum setup
		strumLines = new FlxTypedGroup<Strumline>();

		// generate the song
		generateSong();

		// set the camera position to the center of the stage
		camPos.set(gf.x + (gf.frameWidth / 2), gf.y + (gf.frameHeight / 2));

		// create the game camera
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(camPos.x, camPos.y);
		// check if the camera was following someone previously
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);
		add(camFollowPos);

		// actually set the camera up
		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		startingSong = true;
		startedCountdown = true;

		// initialize ui elements
		var bfPlacement:Float = FlxG.width / 2 + (!Init.getSetting('Centered Receptors') ? FlxG.width / 4 : 0);
		var dadPlacement:Float = (FlxG.width / 2) - FlxG.width / 4;

		var downscroll = Init.getSetting('Downscroll');

		var bfData = boyfriend.characterData;
		var dadData = dad.characterData;

		dadStrums = new Strumline(dadPlacement, downscroll ? FlxG.height - 200 : 0, dad, dadData.noteSkin, true, false, doTweenCheck(true), downscroll, 4);
		bfStrums = new Strumline(bfPlacement, downscroll ? FlxG.height - 200 : 0, boyfriend, bfData.noteSkin, false, true, doTweenCheck(false), downscroll, 4);

		dadStrums.visible = !Init.getSetting('Hide Opponent Receptors');

		strumLines.add(dadStrums);
		strumLines.add(bfStrums);

		// generate a new strum camera
		strumHUD = [];
		for (i in 0...strumLines.length)
		{
			// generate a new strum camera
			strumHUD[i] = new FlxCamera();
			strumHUD[i].bgColor.alpha = 0;

			strumHUD[i].cameras = [camHUD];
			allUIs.push(strumHUD[i]);
			FlxG.cameras.add(strumHUD[i], false);
			// set this strumline's camera to the designated camera
			strumLines.members[i].cameras = [strumHUD[i]];
			// for whatever reason notes would spawn outside the strumline camera
			strumLines.members[i].allNotes.cameras = [strumHUD[i]];
		}

		if (Init.getSetting('Centered Receptors'))
		{
			for (i in 0...PlayState.dadStrums.members.length)
			{
				PlayState.dadStrums.members[i].x += 320;
				PlayState.dadStrums.members[i].alpha = 0.35;
			}

			for (i in 0...PlayState.dadStrums.receptors.members.length)
				PlayState.dadStrums.receptors.members[i].visible = false;
		}

		add(strumLines);

		uiHUD = new ClassHUD();
		add(uiHUD);
		uiHUD.visible = !Init.getSetting('Hide User Interface');
		uiHUD.cameras = [camHUD];

		judgementsGroup = new FlxTypedGroup<FNFSprite>();
		comboGroup = new FlxTypedGroup<FNFSprite>();
		add(judgementsGroup);
		add(comboGroup);

		comboHUD = new FlxCamera();
		comboHUD.bgColor.alpha = 0;
		comboHUD.cameras = [camHUD];
		allUIs.push(comboHUD);

		FlxG.cameras.add(comboHUD, false);

		// precache judgements and combo before using them;
		popJudgement('sick', false, true, true);

		// create a hud over the hud camera for dialogue
		dialogueHUD = new FlxCamera();
		dialogueHUD.bgColor.alpha = 0;
		FlxG.cameras.add(dialogueHUD, false);

		keysArray = [
			copyKey(Init.gameControls.get('LEFT')[0]),
			copyKey(Init.gameControls.get('DOWN')[0]),
			copyKey(Init.gameControls.get('UP')[0]),
			copyKey(Init.gameControls.get('RIGHT')[0])
		];
		for (i in 0...noteControls.length)
			bindsArray[i] = controls.getInputsFor(noteControls[i], Gamepad(0));

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		Paths.clearUnusedMemory();

		// call the funny intro cutscene depending on the song
		if (!skipCutscenes())
			songCutscene();
		else
			startCountdown();

		callFunc('postCreate', []);
	}

	public function playVideo(name:String)
	{
		#if VIDEO_PLUGIN
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if (!FileSystem.exists(filepath))
		#else
		if (!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			if (endingSong)
				endSong();
			else
				callTextbox();
			return;
		}

		var video:MP4Handler = new MP4Handler();
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			if (endingSong)
				endSong();
			else
				callTextbox();
			return;
		}
		#else
		FlxG.log.warn('Platform not supported!');
		if (endingSong)
			endSong();
		else
			callTextbox();
		return;
		#end
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}

	/*
		input system functions
		for pressing and releasing notes
	 */
	public var keysArray:Array<Array<FlxKey>>;
	public var holdingKeys:Array<Bool> = [];

	public function handleInput(key:Int, pressed:Bool)
	{
		holdingKeys[key] = pressed;

		if (pressed)
		{
			if (generatedSong)
			{
				var previousTime:Float = Conductor.songPosition;
				Conductor.songPosition = Conductor.songMusic.time;
				// improved this a little bit, maybe its a lil
				var possibleNoteList:Array<Note> = [];
				var pressedNotes:Array<Note> = [];

				bfStrums.allNotes.forEachAlive(function(daNote:Note)
				{
					if ((daNote.noteData == key) && daNote.canBeHit && !daNote.isSustain && !daNote.tooLate && !daNote.wasGoodHit)
						possibleNoteList.push(daNote);
				});
				possibleNoteList.sort(sortHitNotes);

				// if there is a list of notes that exists for that control
				if (possibleNoteList.length > 0)
				{
					var eligable = true;
					// loop through the possible notes
					for (coolNote in possibleNoteList)
					{
						for (jumpNote in pressedNotes)
						{
							if (Math.abs(jumpNote.strumTime - coolNote.strumTime) >= 10)
								eligable = false;
						}

						if (eligable)
						{
							goodNoteHit(coolNote, bfStrums.receptors.members[coolNote.noteData], bfStrums); // then hit the note
							pressedNotes.push(coolNote);
						}
						// end of this little check
					}
					//
				}
				else
				{ // else just call bad notes
					if (!Init.getSetting('Ghost Tapping'))
					{
						if (startingSong) // mash warning
						{
							logTrace('Stop Spamming!', 1, false, PlayState.dialogueHUD);
							uiHUD.tweenScoreColor('miss', false);
						}
						else if (!inCutscene || !endingSong)
							missNoteCheck(true, key, bfStrums, true);
					}
					else
					{
						// thought it would look funny maybe;
						if (Init.getSetting('Ghost Miss Animations'))
						{
							var stringSect:String = Receptor.actions[key].toUpperCase();
							if (bfStrums.character != null)
							{
								var stringSuffix:String = bfStrums.character.hasMissAnims ? 'miss' : '';
								bfStrums.character.playAnim('sing' + stringSect + stringSuffix);
							}
						}
					}
				}

				Conductor.songPosition = previousTime;
			}

			if (bfStrums.receptors.members[key] != null && bfStrums.receptors.members[key].animation.curAnim.name != 'confirm')
				bfStrums.receptors.members[key].playAnim('pressed', true);
		}
		else
			// receptor reset
			if (key >= 0 && bfStrums.receptors.members[key] != null)
				bfStrums.receptors.members[key].playAnim('static');
	}

	public function onKeyPress(event:KeyboardEvent):Void
	{
		if (!bfStrums.autoplay && FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate))
		{
			var key:Int = getKeyFromEvent(event.keyCode);
			if (key >= 0 && !holdingKeys[key])
				handleInput(key, true);
			callFunc('onKeyPress', [key]);
		}
	}

	public function onKeyRelease(event:KeyboardEvent):Void
	{
		if (!bfStrums.autoplay && FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate))
		{
			var key:Int = getKeyFromEvent(event.keyCode);
			if (key >= 0)
				handleInput(key, false);
			callFunc('onKeyRelease', [key]);
		}
	}

	function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
						return i;
				}
			}
		}
		return -1;
	}

	var noteControls:Array<Control> = [NOTE_LEFT, NOTE_DOWN, NOTE_UP, NOTE_RIGHT];
	var bindsArray:Array<Array<Int>> = [];

	function controllerInput()
	{
		if (controls.gamepads.length > 0)
		{
			var gamepad:FlxGamepad = FlxG.gamepads.getByID(controls.gamepads[0]);
			if (gamepad != null)
			{
				for (i in 0...noteControls.length)
				{
					var bind:Array<Int> = bindsArray[i];
					if (gamepad.anyJustPressed(bind))
						handleInput(i, true);
					if (gamepad.anyJustReleased(bind))
						handleInput(i, false);
				}
			}
		}
	}

	var lastSection:Int = 0;

	@:isVar public var songSpeed(get, default):Float = 0;

	function get_songSpeed()
		return songSpeed * Conductor.playbackRate;

	function set_songSpeed(value:Float):Float
	{
		var offset:Float = songSpeed / value;
		for (note in bfStrums.allNotes)
		{
			if (note.isSustain && !note.animation.curAnim.name.endsWith('end'))
			{
				note.scale.y *= offset;
				note.updateHitbox();
			}
		}
		for (note in dadStrums.allNotes)
		{
			if (note.isSustain && !note.animation.curAnim.name.endsWith('end'))
			{
				note.scale.y *= offset;
				note.updateHitbox();
			}
		}

		return cast songSpeed = value;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		callFunc('update', [elapsed]);

		stageBuild.stageUpdateConstant(elapsed, boyfriend, gf, dad);

		if (health > maxHealth)
			health = maxHealth;

		// dialogue checks
		if (dialogueBox != null && dialogueBox.alive)
		{
			// wheee the shift closes the dialogue
			if (FlxG.keys.justPressed.SHIFT)
				dialogueBox.closeDialog();

			// the change I made was just so that it would only take accept inputs
			if (controls.ACCEPT && dialogueBox.textStarted)
			{
				var sound = 'cancelMenu';

				if (dialogueBox.portraitData.confirmSound != null)
					sound = dialogueBox.portraitData.confirmSound;

				try
				{
					if (sound == null)
						FlxG.sound.play(Paths.sound('cancelMenu'));
					else
						FlxG.sound.play(Paths.sound(sound));
				}
				dialogueBox.curPage += 1;

				if (dialogueBox.curPage == dialogueBox.dialogueData.dialogue.length)
					dialogueBox.closeDialog();
				else
					dialogueBox.updateDialog();

				// for custom fonts
				if (dialogueBox.boxData.textType == 'custom')
				{
					dialogueBox.alphabetText.finishedLine = false;
					dialogueBox.handSelect.visible = false;
				}
			}
		}

		if (!inCutscene)
		{
			// pause the game if the game is allowed to pause and enter is pressed
			if (controls.PAUSE && startedCountdown && canPause)
			{
				pauseGame();
				// open pause substate
				openSubState(new PauseSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			}

			// make sure you're not cheating lol
			if (!isStoryMode)
			{
				if (controls.CHEAT)
				{
					pauseGame();
					openSubState(new EditorMenuSubstate(true, true));
				}

				if (FlxG.keys.justPressed.FIVE)
				{
					preventScoring = true;
					practiceMode = !practiceMode;
				}

				if (FlxG.keys.justPressed.SIX)
				{
					preventScoring = true;
					bfStrums.autoplay = !bfStrums.autoplay;
					uiHUD.scoreBar.visible = !bfStrums.autoplay;
					uiHUD.autoplayMark.visible = bfStrums.autoplay;
					uiHUD.autoplayMark.alpha = 1;
					uiHUD.autoplaySine = 0;
				}
			}

			Conductor.songPosition += elapsed * 1000 * Conductor.playbackRate;
			if (startingSong && startedCountdown && Conductor.songPosition >= 0)
				startSong();

			if (generatedSong && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
			{
				curSection = Std.int(curStep / 16);
				if (curSection != lastSection)
				{
					// section reset stuff
					var lastMustHit:Bool = PlayState.SONG.notes[lastSection].mustHitSection;
					if (PlayState.SONG.notes[curSection].mustHitSection != lastMustHit)
					{
						camDisplaceX = 0;
						camDisplaceY = 0;
					}
					lastSection = Std.int(curStep / 16);
				}

				var mustHit = PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection;
				var altSection = PlayState.SONG.notes[Std.int(curStep / 16)].altAnim;
				var gfSection = PlayState.SONG.notes[Std.int(curStep / 16)].gfSection;

				setVar('mustHit', mustHit);
				setVar('gfSection', gfSection);
				setVar('altSection', altSection);
				setVar('curSection', curSection);

				if (!mustHit && !gfSection)
				{
					var char = dad;

					var getCenterX = char.getMidpoint().x + 100;
					var getCenterY = char.getMidpoint().y - 100;

					camFollow.setPosition(getCenterX + camDisplaceX + char.characterData.camOffsetX,
						getCenterY + camDisplaceY + char.characterData.camOffsetY);

					if (char.curCharacter == 'mom')
						Conductor.songVocals.volume = 1;
				}
				else if (mustHit && !gfSection)
				{
					var char = boyfriend;

					var getCenterX = char.getMidpoint().x - 100;
					var getCenterY = char.getMidpoint().y - 100;
					switch (curStage)
					{
						case 'limo':
							getCenterX = char.getMidpoint().x - 300;
						case 'mall':
							getCenterY = char.getMidpoint().y - 200;
						case 'school':
							getCenterX = char.getMidpoint().x - 200;
							getCenterY = char.getMidpoint().y - 200;
						case 'schoolEvil':
							getCenterX = char.getMidpoint().x - 200;
							getCenterY = char.getMidpoint().y - 200;
					}

					camFollow.setPosition(getCenterX + camDisplaceX - char.characterData.camOffsetX,
						getCenterY + camDisplaceY + char.characterData.camOffsetY);
				}
				else if (gfSection && !mustHit || gfSection && mustHit)
				{
					var char = gf;

					var getCenterX = char.getMidpoint().x + 100;
					var getCenterY = char.getMidpoint().y - 100;

					camFollow.setPosition(getCenterX + camDisplaceX + char.characterData.camOffsetX,
						getCenterY + camDisplaceY + char.characterData.camOffsetY);
				}
			}

			var lerpVal = (elapsed * 2.4) * cameraSpeed;
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

			var easeLerp = 1 - Main.framerateAdjust(0.05);

			// camera stuffs
			if (camZooming)
			{
				FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom + forceZoom[0], FlxG.camera.zoom, easeLerp);
				for (hud in allUIs)
					hud.zoom = FlxMath.lerp(1 + forceZoom[1], hud.zoom, easeLerp);
			}

			// not even forcezoom anymore but still
			FlxG.camera.angle = FlxMath.lerp(0 + forceZoom[2], FlxG.camera.angle, easeLerp);
			for (hud in allUIs)
				hud.angle = FlxMath.lerp(0 + forceZoom[3], hud.angle, easeLerp);

			// Controls

			// RESET = Quick Game Over Screen
			if (controls.RESET && !startingSong && !isStoryMode)
			{
				health = 0;
			}
			if (!startingSong && !endingSong)
				doGameOverCheck();

			// spawn in the notes from the array
			if ((unspawnNotes[0] != null) && ((unspawnNotes[0].strumTime - Conductor.songPosition) < 3500))
			{
				var dunceNote:Note = unspawnNotes[0];
				var strumline = (dunceNote.mustPress ? bfStrums : dadStrums);

				// push note to its correct strumline
				strumLines.members[
					Math.floor((dunceNote.noteData + (dunceNote.mustPress ? 4 : 0)) / strumline.keyAmount)
				].push(dunceNote);

				callFunc('noteSpawn', [dunceNote, dunceNote.noteData, dunceNote.noteType, dunceNote.isSustain]);
				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
			}

			noteCalls();
		}

		if (!isStoryMode && !startingSong && !endingSong && scriptDebugMode)
		{
			if (FlxG.keys.justPressed.F5)
				eventNoteHit('Change Stage', PlayState.curStage, '0');

			if (FlxG.keys.justPressed.ONE)
			{
				preventScoring = true;
				endSong();
			}
			if (FlxG.keys.justPressed.TWO)
			{
				if (!usedTimeTravel && Conductor.songPosition + 10000 < Conductor.songMusic.length)
				{ // Go 10 seconds into the future, @author Shadow_Mario_
					preventScoring = true;
					usedTimeTravel = true;
					Conductor.songMusic.pause();
					Conductor.songVocals.pause();
					Conductor.songPosition += 10000;

					noteCleanup(Conductor.songPosition);

					Conductor.songMusic.time = Conductor.songPosition;
					Conductor.songVocals.time = Conductor.songPosition;

					Conductor.songMusic.play();
					Conductor.songVocals.play();

					new FlxTimer().start(0.5, function(tmr:FlxTimer)
					{
						usedTimeTravel = false;
					});
				}
			}
		}

		if (events.length > 0)
			checkEvents();
		callFunc('postUpdate', [elapsed]);
	}

	function noteCleanup(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}
	}

	function noteCalls()
	{
		if (!bfStrums.autoplay)
			controllerInput();

		for (strumline in strumLines)
		{
			for (receptor in strumline.receptors)
			{
				if (strumline.autoplay && receptor.animation.curAnim.name == 'confirm' && receptor.animation.curAnim.finished)
					receptor.playAnim('static', true);
			}

			if (strumline.splashNotes != null)
			{
				for (i in 0...strumline.splashNotes.length)
				{
					strumline.splashNotes.members[i].x = strumline.receptors.members[i].x - 48;
					strumline.splashNotes.members[i].y = strumline.receptors.members[i].y + (Receptor.swagWidth / 6) - 56;
				}
			}
		}

		// set the notes x and y
		if (generatedSong && startedCountdown)
		{
			for (strumline in strumLines)
			{
				var downscrollMult = (strumline.downscroll ? -1 : 1) * FlxMath.signOf(songSpeed);
				strumline.allNotes.forEachAlive(function(strumNote:Note)
				{
					// set custom note speeds and stuff;
					if (strumNote.useCustomSpeed)
						strumNote.noteSpeed = Init.getSetting('Scroll Speed');
					else
						strumNote.noteSpeed = Math.abs(songSpeed);

					var strumData = Math.floor(strumNote.noteData);

					var receptorX:Float = strumline.receptors.members[strumData].x;
					var receptorY:Float = strumline.receptors.members[strumData].y;
					var psuedoY:Float = (downscrollMult * -((Conductor.songPosition - strumNote.strumTime) * (0.45 * strumNote.noteSpeed)));
					var psuedoX:Float = 25 + strumNote.noteVisualOffset;

					strumNote.y = receptorY
						+ strumNote.offsetY
						+ (Math.cos(flixel.math.FlxAngle.asRadians(strumNote.noteDirection)) * psuedoY)
						+ (Math.sin(flixel.math.FlxAngle.asRadians(strumNote.noteDirection)) * psuedoX);
					// painful math equation
					strumNote.x = receptorX
						+ (Math.cos(flixel.math.FlxAngle.asRadians(strumNote.noteDirection)) * psuedoX)
						+ (Math.sin(flixel.math.FlxAngle.asRadians(strumNote.noteDirection)) * psuedoY);

					// also set note rotation
					strumNote.angle = -strumNote.noteDirection;

					// shitty note hack I hate it so much
					if (strumNote.isSustain)
					{
						strumNote.y -= ((strumNote.height / 2) * downscrollMult);

						if ((strumNote.animation.curAnim.name.endsWith('holdend') || strumNote.animation.curAnim.name.endsWith('rollend'))
							&& (strumNote.prevNote != null))
						{
							strumNote.y -= ((strumNote.prevNote.height / 2) * downscrollMult);
							if (strumline.downscroll)
							{
								strumNote.y += (strumNote.height * 2);
								if (strumNote.endHoldOffset == Math.NEGATIVE_INFINITY)
									strumNote.endHoldOffset = (strumNote.prevNote.y - (strumNote.y + strumNote.height));
								else
									strumNote.y += strumNote.endHoldOffset;
							}
							else
								strumNote.y += ((strumNote.height / 2) * downscrollMult);
							// this system is funny like that
						}
						var center:Float = receptorY + Receptor.swagWidth / (1.4 * (assetModifier == 'pixel' ? 2 : 1));
						if (strumline.downscroll)
						{
							strumNote.flipY = true;
							if (strumNote.y - strumNote.offset.y * strumNote.scale.y + strumNote.height >= center
								&& (strumline.autoplay
									|| (strumNote.wasGoodHit || (strumNote.prevNote != null && strumNote.prevNote.wasGoodHit))))
							{
								var swagRect = new FlxRect(0, 0, strumNote.frameWidth, strumNote.frameHeight);
								swagRect.height = (center - strumNote.y) / strumNote.scale.y;
								swagRect.y = strumNote.frameHeight - swagRect.height;
								strumNote.clipRect = swagRect;
							}
						}
						else
						{
							if (strumNote.y + strumNote.offset.y * strumNote.scale.y <= center
								&& (strumline.autoplay
									|| (strumNote.wasGoodHit || (strumNote.prevNote != null && strumNote.prevNote.wasGoodHit))))
							{
								var swagRect = new FlxRect(0, 0, strumNote.width / strumNote.scale.x, strumNote.height / strumNote.scale.y);
								swagRect.y = (center - strumNote.y) / strumNote.scale.y;
								swagRect.height -= swagRect.y;
								strumNote.clipRect = swagRect;
							}
						}
					}

					// hell breaks loose here, we're using nested scripts!
					mainControls(strumNote, strumline);

					// check where the note is and make sure it is either active or inactive
					if (strumNote.y > FlxG.height)
					{
						strumNote.active = false;
						strumNote.visible = false;
					}
					else
					{
						strumNote.visible = true;
						strumNote.active = true;
					}

					if (!strumNote.tooLate
						&& strumNote.strumTime < Conductor.songPosition - (Timings.msThreshold)
						&& !strumNote.wasGoodHit)
					{
						if ((!strumNote.tooLate) && (strumNote.mustPress) && (!strumNote.canHurt))
						{
							if (!strumNote.isSustain)
							{
								strumNote.tooLate = true;
								for (note in strumNote.childrenNotes)
									note.tooLate = true;

								Conductor.songVocals.volume = 0;
								strumNote.noteMissActions(strumNote);

								callFunc('noteMiss', [strumNote]);

								missNoteCheck((Init.getSetting('Ghost Tapping') && !startingSong) ? true : false, strumNote.noteData, strumline, true);
								// ambiguous name
								if (strumNote.updateAccuracy)
									Timings.updateAccuracy(0);
							}
							else if (strumNote.isSustain)
							{
								if (strumNote.parentNote != null)
								{
									var parentNote = strumNote.parentNote;
									if (!parentNote.tooLate)
									{
										var breakFromLate:Bool = false;
										if (!breakFromLate)
										{
											missNoteCheck((Init.getSetting('Ghost Tapping') && !startingSong) ? true : false, strumNote.noteData, strumline,
												true);
											for (note in parentNote.childrenNotes)
												note.tooLate = true;
										}
									}
								}
							}
						}
					}

					// if the note is off screen (above)
					if ((((!strumline.downscroll) && (strumNote.y < -strumNote.height))
						|| ((strumline.downscroll) && (strumNote.y > (FlxG.height + strumNote.height))))
						&& (strumNote.tooLate || strumNote.wasGoodHit))
						destroyNote(strumline, strumNote);
				});

				// unoptimised asf camera control based on strums
				strumCameraRoll(strumline.receptors, (strumline == bfStrums));
			}
		}

		// reset boyfriend's animation
		if ((boyfriend != null && boyfriend.animation != null)
			&& (boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.characterData.singDuration)
			&& (!holdingKeys.contains(true) || bfStrums.autoplay))
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
		}
	}

	function destroyNote(strumline:Strumline, daNote:Note)
	{
		daNote.active = false;
		daNote.exists = false;

		var chosenGroup = (daNote.isSustain ? strumline.holdsGroup : strumline.notesGroup);
		// note damage here I guess
		daNote.kill();
		if (strumline.allNotes.members.contains(daNote))
			strumline.allNotes.remove(daNote, true);
		if (chosenGroup.members.contains(daNote))
			chosenGroup.remove(daNote, true);
		daNote.destroy();
	}

	function goodNoteHit(coolNote:Note, receptor:Receptor, strumline:Strumline)
	{
		if (!coolNote.wasGoodHit)
		{
			// lmao;
			callFunc(!coolNote.mustPress ? 'opponentNoteHit' : 'goodNoteHit', [coolNote, strumline]);
			strumline.character.noteHit(coolNote);

			coolNote.wasGoodHit = true;
			Conductor.songVocals.volume = 1;
			receptor.playAnim('confirm', true);

			coolNote.goodNoteHit(coolNote, (coolNote.strumTime < Conductor.songPosition ? "late" : "early"));

			var gfSection = PlayState.SONG.notes[curSection].gfSection;
			characterPlayAnimation(coolNote, (coolNote.gfNote || gfSection ? gf : strumline.character));

			// special thanks to sam, they gave me the original system which kinda inspired my idea for this new one
			if (strumline.displayJudgements)
			{
				// get the note ms timing
				var noteDiff:Float = Math.abs(coolNote.strumTime - Conductor.songPosition);

				// loop through all avaliable judgements
				var foundRating:String = 'miss';
				var lowestThreshold:Float = Math.POSITIVE_INFINITY;
				for (myRating in Timings.judgementsMap.keys())
				{
					var myThreshold:Float = Timings.judgementsMap.get(myRating)[1];
					if (noteDiff <= myThreshold && (myThreshold < lowestThreshold))
					{
						foundRating = myRating;
						lowestThreshold = myThreshold;
					}
				}

				if (!coolNote.canHurt)
				{
					if (!coolNote.isSustain)
					{
						increaseCombo(foundRating, coolNote.noteData, strumline);
						popUpScore(foundRating, coolNote.strumTime < Conductor.songPosition, Timings.perfectCombo, strumline, coolNote);

						if (coolNote.childrenNotes.length > 0)
							Timings.notesHit++;

						healthCall(Timings.judgementsMap.get(foundRating)[3]);
					}
					else
					{
						// call updated accuracy stuffs
						if (coolNote.parentNote != null)
						{
							if (coolNote.updateAccuracy)
								Timings.updateAccuracy(100, true, coolNote.parentNote.childrenNotes.length);
							healthCall(100 / coolNote.parentNote.childrenNotes.length);
						}
					}
				}
			}

			if (!coolNote.isSustain)
				destroyNote(strumline, coolNote);
		}
	}

	public function missNoteCheck(?includeAnimation:Bool = false, direction:Int = 0, strumline:Strumline, popMiss:Bool = false, lockMiss:Bool = false)
	{
		if (strumline.autoplay || usedTimeTravel)
			return;

		if (includeAnimation)
		{
			var stringDirection:String = Receptor.actions[direction];

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			if (strumline.character != null && strumline.character.hasMissAnims)
				strumline.character.playAnim('sing' + stringDirection.toUpperCase() + 'miss', lockMiss);
		}
		decreaseCombo(popMiss);
	}

	public function characterPlayAnimation(coolNote:Note, character:Character)
	{
		// alright so we determine which animation needs to play
		// get alt strings and stuffs
		var stringArrow:String = '';
		var altString:String = '';

		var baseString = 'sing' + Receptor.actions[coolNote.noteData].toUpperCase();

		// I tried doing xor and it didnt work lollll
		if (coolNote.noteAlt > 0)
			altString = '-alt';

		var altSection = (SONG.notes[Math.floor(curStep / 16)] != null) && (SONG.notes[Math.floor(curStep / 16)].altAnim);
		if ((altSection) && (character.animOffsets.exists(baseString + '-alt')))
		{
			if (altString != '-alt')
				altString = '-alt';
			else
				altString = '';
		}

		switch (coolNote.noteType)
		{
			case 2: // mines
				if (stringArrow != coolNote.noteSect)
				{
					if (character.animOffsets.exists('hurt'))
						stringArrow = 'hurt';
					else
						stringArrow = baseString + 'miss';
				}
				character.specialAnim = true;
				character.heyTimer = 0.6;
			default: // anything else
				var noteString:String = coolNote.noteString != null && coolNote.noteString != '' ? coolNote.noteString : '';
				if (coolNote.noteSect != null && coolNote.noteSect != '')
					stringArrow = coolNote.noteSect;
				else
					stringArrow = baseString + altString + noteString;
				character.specialAnim = false;
		}

		if (character != null)
		{
			var finalString:String = stringArrow != null ? stringArrow : baseString;
			character.playAnim(finalString, true);
			if (stringArrow == coolNote.noteSect && coolNote.noteTimer > 0)
			{
				character.specialAnim = true;
				character.heyTimer = coolNote.noteTimer;
			}
			character.holdTimer = 0;
		}
	}

	function mainControls(daNote:Note, strumline:Strumline):Void
	{
		var notesPressedAutoplay = [];

		// here I'll set up the autoplay functions
		if (strumline.autoplay)
		{
			// check if the note was a good hit
			if (daNote.strumTime <= Conductor.songPosition)
			{
				// kill the note, then remove it from the array
				if (strumline.displayJudgements)
					notesPressedAutoplay.push(daNote);

				if ((!daNote.canHurt && daNote.mustPress) || (!daNote.cpuIgnore && !daNote.mustPress))
					goodNoteHit(daNote, strumline.receptors.members[daNote.noteData], strumline);
			}
		}

		if (!strumline.autoplay)
		{
			// check for hold notes
			strumline.holdsGroup.forEachAlive(function(coolNote:Note)
			{
				if ((coolNote.parentNote != null && coolNote.parentNote.wasGoodHit)
					&& coolNote.canBeHit
					&& coolNote.mustPress
					&& !coolNote.tooLate
					&& holdingKeys[coolNote.noteData])
					goodNoteHit(coolNote, strumline.receptors.members[coolNote.noteData], strumline);
			});
		}
	}

	function strumCameraRoll(cStrum:FlxTypedSpriteGroup<Receptor>, mustHit:Bool)
	{
		if (!Init.getSetting('No Camera Note Movement'))
		{
			var noteStep = PlayState.SONG.notes[curSection];
			var camDisplaceExtend:Float = 15;
			if (noteStep != null)
			{
				if ((noteStep.mustHitSection && mustHit) || (!noteStep.mustHitSection && !mustHit))
				{
					camDisplaceX = 0;
					if (cStrum.members[0].animation.curAnim.name == 'confirm')
						camDisplaceX -= camDisplaceExtend;
					if (cStrum.members[3].animation.curAnim.name == 'confirm')
						camDisplaceX += camDisplaceExtend;

					camDisplaceY = 0;
					if (cStrum.members[1].animation.curAnim.name == 'confirm')
						camDisplaceY += camDisplaceExtend;
					if (cStrum.members[2].animation.curAnim.name == 'confirm')
						camDisplaceY -= camDisplaceExtend;
				}
			}
		}
		//
	}

	public function pauseGame()
	{
		callFunc('pauseGame', []);

		// pause discord rpc
		updateRPC(true);

		// pause game
		paused = true;

		// pause music
		Conductor.pauseMusic();

		// update drawing stuffs
		persistentUpdate = false;
		persistentDraw = true;

		// stop all tweens and timers
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer)
		{
			if (!tmr.finished)
				tmr.active = false;
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween)
		{
			if (!twn.finished)
				twn.active = false;
		});
	}

	override public function onFocus():Void
	{
		if (!paused)
			updateRPC(false);
		callFunc('onFocus', []);
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		var strumline:Strumline = null;
		for (strum in strumLines)
			strumline = strum;
		if (canPause && !paused && !inCutscene && !strumline.autoplay && !Init.getSetting('Auto Pause') && startedCountdown)
		{
			pauseGame();
			// open pause substate
			openSubState(new PauseSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}
		callFunc('onFocusLost', []);
		super.onFocusLost();
	}

	public static function updateRPC(pausedRPC:Bool)
	{
		#if DISCORD_RPC
		var displayRPC:String = (pausedRPC) ? detailsPausedText : songDetails;

		if (health > 0)
		{
			if (Conductor.songPosition > 0 && !pausedRPC)
				Discord.changePresence(displayRPC, detailsSub, null, null, iconRPC, true, songLength - Conductor.songPosition);
			else
				Discord.changePresence(displayRPC, detailsSub, null, null, iconRPC);
		}
		#end
	}

	function popUpScore(baseRating:String, timing:Bool, perfect:Bool, strumline:Strumline, coolNote:Note)
	{
		// set up the rating
		var score:Int = 50;

		// create the note splash if you hit a sick
		if (baseRating == "sick")
			popNoteSplash(coolNote, coolNote.noteType, strumline);
		else
			// if it isn't a sick, and you had a sick combo, then it becomes not sick :(
			if (Timings.perfectCombo)
				Timings.perfectCombo = false;

		if (!strumline.autoplay)
			popJudgement(baseRating, timing, perfect);
		else
			popJudgement('sick', false, perfect);

		if (coolNote.updateAccuracy)
			Timings.updateAccuracy(Timings.judgementsMap.get(baseRating)[3]);
		score = Std.int(Timings.judgementsMap.get(baseRating)[2]);

		if (!practiceMode)
			songScore += score;

		// tween score color based on your rating;
		uiHUD.tweenScoreColor(baseRating, perfect);
	}

	public function popNoteSplash(coolNote:Note, noteType:Int, strumline:Strumline)
	{
		// play animation in existing notesplashes
		var noteSplashRandom:String = (Std.string((FlxG.random.int(0, 1) + 1)));
		if (strumline.splashNotes != null)
		{
			if (ForeverAssets.splashJson != null && ForeverAssets.splashJson.hasTwoAnims)
				strumline.splashNotes.members[coolNote.noteData].playAnim('anim' + noteSplashRandom, true);
			else
				strumline.splashNotes.members[coolNote.noteData].playAnim('anim1', true);
		}
	}

	var createdColor = FlxColor.fromRGB(204, 66, 66);

	function popJudgement(newRating:String, lateHit:Bool, perfect:Bool, ?cached:Bool = false)
	{
		/*
			so you might be asking
			"oh but if the rating isn't sick why not just reset it"
			because miss judgements can pop, and they dont mess with your sick combo
		 */
		var rating = ForeverAssets.generateRating('$newRating', perfect, lateHit, judgementsGroup, assetModifier, uiModifier, 'UI');
		if (!Init.getSetting('Judgement Recycling'))
			insert(members.indexOf(strumLines), rating);

		if (!cached)
		{
			if (!Init.getSetting('Judgement Stacking'))
			{
				if (!Init.getSetting('Judgement Recycling'))
					insert(members.indexOf(strumLines), rating);
				if (lastJudge != null)
					lastJudge.kill();
				if (rating != null && rating.alive)
					lastJudge = rating;
			}

			Timings.gottenJudgements.set(newRating, Timings.gottenJudgements.get(newRating) + 1);
			if (Timings.smallestRating != newRating)
			{
				if (Timings.judgementsMap.get(Timings.smallestRating)[0] < Timings.judgementsMap.get(newRating)[0])
					Timings.smallestRating = newRating;
			}
		}

		if (Init.getSetting('Fixed Judgements'))
		{
			// bound to camera
			if (!cached)
				rating.cameras = [comboHUD];
		}

		if (cached)
			rating.alpha = 0.000001;

		var comboString:String = Std.string(combo);
		var stringArray:Array<String> = comboString.split("");

		var negative = false;
		if ((comboString.startsWith('-')) || (combo == 0))
			negative = true;

		if (lastCombo != null)
		{
			while (lastCombo.length > 0)
			{
				lastCombo[0].kill();
				lastCombo.remove(lastCombo[0]);
			}
		}

		for (scoreInt in 0...stringArray.length)
		{
			var comboNum = ForeverAssets.generateCombo('combo_numbers', stringArray[scoreInt], (!negative ? perfect : false), comboGroup, assetModifier,
				uiModifier, 'UI', negative, createdColor, scoreInt);
			if (!Init.getSetting('Judgement Recycling'))
				insert(members.indexOf(strumLines), comboNum);

			if (comboNum != null)
				comboNum.animation.play('combo' + (Timings.perfectCombo ? '-perfect' : ''));

			if (!Init.getSetting('Judgement Stacking'))
			{
				if (!Init.getSetting('Judgement Recycling'))
					insert(members.indexOf(strumLines), comboNum);
				lastCombo.push(comboNum);
			}

			if (Init.getSetting('Fixed Judgements'))
			{
				if (!cached)
					comboNum.cameras = [comboHUD];
				comboNum.y += 50;
			}
			comboNum.x += 100;

			if (cached)
				comboNum.alpha = 0.000001;
		}

		judgementsGroup.sort(FNFSprite.depthSorting, FlxSort.DESCENDING);
		comboGroup.sort(FNFSprite.depthSorting, FlxSort.DESCENDING);
	}

	public function decreaseCombo(?popMiss:Bool = false)
	{
		if (combo > 5 && gf.animOffsets.exists('sad'))
			gf.playAnim('sad');

		if (combo > 0)
			combo = 0; // bitch lmao
		else
			combo--;

		// misses
		if (!practiceMode)
			songScore -= 10;

		if (!endingSong)
			misses++;

		if (popMiss)
		{
			popJudgement("miss", true, false);
			healthCall(Timings.judgementsMap.get("miss")[3]);
			uiHUD.tweenScoreColor("miss", false);
		}

		// gotta do it manually here lol
		Timings.updateFCDisplay();
	}

	function increaseCombo(?baseRating:String, ?direction = 0, ?strumline:Strumline)
	{
		// trolled this can actually decrease your combo if you get a bad/shit/miss
		if (baseRating != null)
		{
			if (Timings.judgementsMap.get(baseRating)[3] > 0)
			{
				if (combo < 0)
					combo = 0;
				combo += 1;
			}
			else
				missNoteCheck(true, direction, strumline, false, true);
		}
	}

	function healthCall(?ratingMultiplier:Float = 0)
	{
		// health += 0.012;
		var healthBase:Float = 0.06;
		health += (healthBase * (ratingMultiplier / 100));
	}

	function generateSong():Void
	{
		// set the song speed;
		songSpeed = SONG.speed;

		// change bpm
		Conductor.changeBPM(SONG.bpm);

		songDetails = CoolUtil.dashToSpace(SONG.song)
			+ ' ['
			+ CoolUtil.difficultyFromString()
			+ '] - by '
			+ SONG.author
			+ ' (${Conductor.playbackRate}x)';

		detailsPausedText = "Paused - " + songDetails;
		detailsSub = "";

		updateRPC(false);

		// call song
		Conductor.bindMusic();

		// push notes to the main note array
		unspawnNotes = ChartParser.loadChart(SONG);
		events = ChartParser.loadEvents(SONG.events);

		for (i in events)
		{
			if (events.length > 0)
				pushedEvent(i);
		}

		// song is done.
		generatedSong = true;
	}

	function startSong():Void
	{
		callFunc('startSong', []);

		startingSong = false;

		if (!paused)
		{
			Conductor.startMusic();
			Conductor.songMusic.onComplete = endSong.bind();
			FlxTween.tween(uiHUD.centerMark, {alpha: 1});

			#if DISCORD_RPC
			// Song duration in a float, useful for the time left feature
			songLength = Conductor.songMusic.length;

			// Updating Discord Rich Presence (with Time Left)
			updateRPC(false);
			#end
		}
	}

	override function stepHit()
	{
		super.stepHit();

		if (Math.abs(Conductor.songMusic.time - (Conductor.songPosition - Conductor.safeZoneOffset)) > (20 * Conductor.playbackRate)
			|| (PlayState.SONG.needsVoices
				&& Math.abs(Conductor.songVocals.time - (Conductor.songPosition - Conductor.safeZoneOffset)) > (20 * Conductor.playbackRate)))
		{
			Conductor.resyncVocals();
		}

		stageBuild.stageUpdateSteps(curStep, boyfriend, gf, dad);

		callFunc('stepHit', [curStep]);
	}

	function charactersDance(curBeat:Int)
	{
		for (i in strumLines)
		{
			if (i.character != null
				&& (!i.character.danceIdle && curBeat % i.character.bopSpeed == 0)
				|| (i.character.danceIdle && curBeat % Math.round(gfSpeed * i.character.bopSpeed) == 0))
			{
				if (i.character.animation.curAnim.name.startsWith("idle") // check if the idle exists before dancing
					|| i.character.animation.curAnim.name.startsWith("dance"))
					i.character.dance();
			}
		}

		if (gf != null && curBeat % Math.round(gfSpeed * gf.bopSpeed) == 0)
		{
			if (gf.animation.curAnim.name.startsWith("idle") || gf.animation.curAnim.name.startsWith("dance"))
				gf.dance();
		}
	}

	private var isDead:Bool = false;

	function doGameOverCheck()
	{
		callFunc('doGameOverCheck', []);

		if (!practiceMode && health <= 0 && !isDead)
		{
			paused = true;
			persistentUpdate = false;
			persistentDraw = false;
			boyfriend.stunned = true;

			Conductor.stopMusic();

			deaths += 1;

			for (hud in allUIs)
				hud.visible = false;
			dialogueHUD.visible = false;
			camAlt.visible = false;

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			FlxG.sound.play(Paths.sound(GameOverSubstate.deathSound));

			#if DISCORD_RPC
			Discord.changePresence("Game Over - " + songDetails, detailsSub, null, null, iconRPC);
			#end
			isDead = true;
			return true;
		}
		return false;
	}

	override function beatHit()
	{
		super.beatHit();

		if (camZooming)
		{
			if ((FlxG.camera.zoom < 1.35 && curBeat % 4 == 0) && (!Init.getSetting('Reduced Movements')))
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.05;
				for (hud in strumHUD)
					hud.zoom += 0.05;
			}
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
			}
		}

		uiHUD.beatHit(curBeat);

		charactersDance(curBeat);

		// stage stuffs
		stageBuild.stageUpdate(curBeat, boyfriend, gf, dad);

		callFunc('beatHit', [curBeat]);
	}

	/* ===== substate stuffs ===== */
	override function openSubState(SubState:FlxSubState)
	{
		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (Conductor.songMusic != null && !startingSong)
				Conductor.startMusic();

			FlxTimer.globalManager.forEach(function(tmr:FlxTimer)
			{
				if (!tmr.finished)
					tmr.active = true;
			});

			FlxTween.globalManager.forEach(function(twn:FlxTween)
			{
				if (!twn.finished)
					twn.active = true;
			});
			paused = false;

			updateRPC(false);
		}

		Paths.clearUnusedMemory();

		callFunc('closeSubState', []);

		super.closeSubState();
	}

	function checkEvents()
	{
		while (events.length > 0)
		{
			var line:TimedEvent = events[0];
			if (line != null)
			{
				if (Conductor.songPosition < line.strumTime)
					break;

				eventNoteHit(line.event, line.val1, line.val2, line.val3);
				events.shift();
			}
		}
	}

	function pushedEvent(event:TimedEvent)
	{
		// trace('Event Name: ${event.event}, Event V1: ${event.val1}, Event V2: ${event.val2}, Event V3: ${event.val3}');

		switch (event.event)
		{
			case 'Change Character':
				var char:Character = new Character(false);
				char.setCharacter(0, 0, event.val2);
				charGroup.add(char);
			case 'Change Stage':
				var newStage:Stage = new Stage(event.val1);
				stageGroup.add(newStage);
				new FlxTimer().start(0.005, function(tmr:FlxTimer)
				{
					newStage.visible = false;
				});
		}
	}

	public var songSpeedTween:FlxTween;

	public function eventNoteHit(event:String, value1:String, value2:String, ?value3:String)
	{
		/* NOTE: unhardcode this later */
		switch (event)
		{
			case 'Set GF Speed':
				var speed:Int = Std.parseInt(value1);
				if (Math.isNaN(speed) || speed <= 0)
					speed = 1;
				gfSpeed = speed;
			case 'Change Character':
				var changeTimer:FlxTimer;
				var timer:Float = Std.parseFloat(value3);
				if (Math.isNaN(timer))
					timer = 0;
				if (value1 == null || value1.length < 1)
					value1 == 'dad';

				changeTimer = new FlxTimer().start(timer, function(tmr:FlxTimer)
				{
					switch (value1.toLowerCase().trim())
					{
						case 'bf' | 'boyfriend' | 'player' | '0':
							boyfriend.setCharacter(770, 450, value2);
							uiHUD.iconP1.updateIcon(value2, true);
						case 'gf' | 'girlfriend' | 'spectator' | '2':
							gf.setCharacter(300, 100, value2);
						case 'dad' | 'dadOpponent' | 'opponent' | '1':
							dad.setCharacter(100, 100, value2);
							uiHUD.iconP2.updateIcon(value2, false);
					}
					uiHUD.updateBar();
				});
			case 'Change Stage':
				var changeTimer:FlxTimer;
				var timer:Float = Std.parseFloat(value2);
				if (Math.isNaN(timer))
					timer = 0;

				changeTimer = new FlxTimer().start(timer, function(tmr:FlxTimer)
				{
					remove(stageBuild.layers);
					remove(stageBuild.foreground);

					stageGroup.forEach(function(stage:Stage)
					{
						if (stage.curStage != value1)
							stageGroup.remove(stageBuild);
					});

					stageBuild = new Stage(value1);
					stageGroup.add(stageBuild);

					curStage = value1;

					regenerateCharacters();
					loadUIDarken();
				});
			case 'Camera Flash':
				var timer:Float = Std.parseFloat(value2);
				if (Math.isNaN(timer) || timer <= 0)
					timer = 0.6;
				if (value1 == null)
					value1 = 'white';
				FlxG.camera.flash(ForeverTools.returnColor('$value1'), timer);
			case 'Hey!':
				var timer:Float = Std.parseFloat(value2);
				if (Math.isNaN(timer) || timer <= 0)
					timer = 0.6;
				if (value1 == null || value1.length < 1)
					value1 == 'bf';

				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | 'player' | '0':
						if (boyfriend.animOffsets.exists('hey'))
						{
							boyfriend.playAnim('hey', true);
							boyfriend.specialAnim = true;
							boyfriend.heyTimer = timer;
						}
					case 'gf' | 'girlfriend' | 'spectator' | '2':
						if (gf.animOffsets.exists('hey'))
							gf.playAnim('hey', true);
						else if (gf.animOffsets.exists('cheer'))
							gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = timer;
					case 'dad' | 'dadOpponent' | 'opponent' | '1':
						if (dad.animOffsets.exists('hey'))
						{
							dad.playAnim('hey', true);
							dad.specialAnim = true;
							dad.heyTimer = timer;
						}
				}
			case 'Play Animation':
				var timer:Float = Std.parseFloat(value3);
				if (Math.isNaN(timer) || timer <= 0)
					timer = 0.6;
				if (value1 == null || value1.length < 1)
					value1 == 'dad';

				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | 'player' | '0':
						if (boyfriend.animOffsets.exists(value1))
						{
							boyfriend.playAnim(value1, true);
							boyfriend.specialAnim = true;
							boyfriend.heyTimer = timer;
						}
					case 'gf' | 'girlfriend' | 'spectator' | '2':
						if (gf.animOffsets.exists(value1))
						{
							gf.playAnim(value1, true);
							gf.specialAnim = true;
							gf.heyTimer = timer;
						}
					case 'dad' | 'dadOpponent' | 'opponent' | '1':
						if (dad.animOffsets.exists(value1))
						{
							dad.playAnim(value1, true);
							dad.specialAnim = true;
							dad.heyTimer = timer;
						}
				}
			case 'Multiply Scroll Speed':
				if (Init.getSetting('Use Custom Note Speed'))
					return;

				var mult:Float = Std.parseFloat(value1);
				var timer:Float = Std.parseFloat(value2);
				if (Math.isNaN(mult))
					mult = 1;
				if (Math.isNaN(timer))
					timer = 0;

				var speed = SONG.speed * mult;

				if (mult <= 0)
				{
					songSpeed = speed;
				}
				else
				{
					if (songSpeedTween != null)
						songSpeedTween.cancel();
					songSpeedTween = FlxTween.tween(this, {songSpeed: speed}, timer / Conductor.playbackRate, {
						ease: ForeverTools.returnTweenEase(value3),
						onComplete: function(twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}
		}

		callFunc('eventNoteHit', [event, value1, value2, value3]);
	}

	/*
		Extra functions and stuffs
	 */
	/// song end function at the end of the playstate lmao ironic I guess
	var endSongEvent:Bool = false;

	function endSong():Void
	{
		callFunc('endSong', []);

		canPause = false;
		endingSong = true;
		inCutscene = false;

		if (!endSongEvent)
		{
			if (checkTextbox())
				endSongEvent = true;
		}

		Conductor.stopMusic();
		deaths = 0;

		// set ranking
		rank = Timings.returnScoreRating().toUpperCase();
		accuracy = Math.floor(Timings.getAccuracy() * 100) / 100;

		if (SONG.validScore && !preventScoring)
		{
			Highscore.saveScore(SONG.song, songScore, storyDifficulty);
			Highscore.saveRank(SONG.song, rank, storyDifficulty);
			Highscore.saveAccuracy(SONG.song, accuracy, storyDifficulty);
		}

		if (chartingMode)
		{
			// enable memory cleaning
			clearStored = true;
			Main.switchState(this, (lastEditor == 1 ? new ChartEditor() : new OriginalChartEditor()));
		}
		else if (!isStoryMode)
		{
			if ((!endSongEvent))
			{
				// enable memory cleaning
				clearStored = true;
				Main.switchState(this, new FreeplayMenu());
			}
			else
			{
				if (!skipCutscenes())
					songCutscene();
			}
		}
		else
		{
			// set the campaign's score higher
			campaignScore += songScore;
			campaignMisses += misses;

			// remove a song from the story playlist
			storyPlaylist.remove(storyPlaylist[0]);

			// check if there aren't any songs left
			if ((storyPlaylist.length <= 0) && (!endSongEvent))
			{
				// play menu music
				ForeverTools.resetMenuMusic();

				// enable memory cleaning
				clearStored = true;

				// set up transitions
				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;
				FlxTransitionableState.skipNextTransIn = false;
				FlxTransitionableState.skipNextTransOut = false;

				// change to the menu state
				Main.switchState(this, new StoryMenu());

				// save the week's score if the score is valid
				if (SONG.validScore && !preventScoring)
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);

				// flush the save
				FlxG.save.flush();
			}
			else
			{
				if (!skipCutscenes())
					songCutscene();
			}
		}
	}

	public function callDefaultSongEnd()
	{
		inCutscene = false;
		if (isStoryMode)
		{
			var difficulty:String = CoolUtil.returnDifficultySuffix().toLowerCase();

			PlayState.SONG = Song.loadSong(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
			Conductor.killMusic();

			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			clearStored = false;

			Main.switchState(this, new PlayState());
		}
		else
		{
			// enable memory cleaning
			clearStored = true;
			Main.switchState(this, new FreeplayMenu());
		}
	}

	var dialogueBox:DialogueBox;

	public function songCutscene()
	{
		callFunc(endingSong ? 'songEndCutscene' : 'songIntroCutscene', []);
		inCutscene = true;

		if (endingSong)
		{
			switch (SONG.song.toLowerCase())
			{
				default:
					if (comboHUD.visible) // bandaid fix;
						callTextbox();
			}
		}
		else
		{
			switch (SONG.song.toLowerCase())
			{
				default:
					if (comboHUD.visible) // bandaid fix;
						callTextbox();
			}
		}
	}

	function checkTextbox():Bool
	{
		var dialogueFileStr:String = 'dialogue';
		dialogueFileStr = (endingSong ? 'dialogueEnd' : 'dialogue');
		var dialogPath = Paths.file('songs/' + SONG.song.toLowerCase() + '/$dialogueFileStr.json');

		if (sys.FileSystem.exists(dialogPath))
			return true;

		return false;
	}

	public function callTextbox()
	{
		if (checkTextbox())
		{
			if (!endingSong)
				startedCountdown = false;

			var dialogueFileStr:String = 'dialogue';
			dialogueFileStr = (endingSong ? 'dialogueEnd' : 'dialogue');

			dialogueBox = DialogueBox.createDialogue(sys.io.File.getContent(Paths.file('songs/' + SONG.song.toLowerCase() + '/$dialogueFileStr.json')));
			dialogueBox.cameras = [dialogueHUD];
			dialogueBox.whenDaFinish = (endingSong ? callDefaultSongEnd : startCountdown);

			add(dialogueBox);
		}
		else
			(endingSong ? callDefaultSongEnd() : startCountdown());
	}

	public static function skipCutscenes():Bool
	{
		// pretty messy but an if statement is messier
		if (Init.getSetting('Skip Text') != null && Std.isOfType(Init.getSetting('Skip Text'), String))
		{
			switch (cast(Init.getSetting('Skip Text'), String))
			{
				case 'never':
					return false;
				case 'freeplay only':
					if (!isStoryMode)
						return true;
					else
						return false;
				default:
					return true;
			}
		}
		return false;
	}

	public static var swagCounter:Int = 0;

	function startCountdown():Void
	{
		inCutscene = false;

		Conductor.songPosition = -(Conductor.crochet * 5);
		swagCounter = 0;

		camHUD.visible = true;

		precacheImages();
		precacheSounds();

		if (Init.getSetting('Opacity Type') == 'Notes')
		{
			darknessBG.x = bfStrums.receptors.members[0].x + 20;
			darknessLine1.x = darknessBG.x - 5;
			darknessLine2.x = FlxG.width - darknessBG.x + 2;
			FlxTween.tween(darknessBG, {alpha: (Init.getSetting('Darkness Opacity') * 0.01)}, 0.5, {ease: FlxEase.circOut});
			if (Init.getSetting('Darkness Opacity') > 0)
			{
				FlxTween.tween(darknessLine1, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(darknessLine2, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			}

			if (!Init.getSetting('Centered Receptors'))
			{
				darknessOpponent.x = dadStrums.receptors.members[0].x + 20;
				darknessLine3.x = darknessOpponent.x - 5;
				darknessLine4.x = FlxG.width - darknessOpponent.x + 2;
				FlxTween.tween(darknessOpponent, {alpha: (Init.getSetting('Darkness Opacity') * 0.01)}, 0.5, {ease: FlxEase.circOut});
				if (Init.getSetting('Darkness Opacity') > 0)
				{
					FlxTween.tween(darknessLine3, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
					FlxTween.tween(darknessLine4, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
				}
			}
		}

		callFunc('startCountdown', []);

		startTimer = new FlxTimer().start(Conductor.crochet / 1000 / Conductor.playbackRate, function(tmr:FlxTimer)
		{
			startedCountdown = true;

			charactersDance(curBeat);

			stageBuild.stageUpdate(curBeat, boyfriend, gf, dad);

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', [
				ForeverTools.returnSkin('prepare', assetModifier, uiModifier, 'UI'),
				ForeverTools.returnSkin('ready', assetModifier, uiModifier, 'UI'),
				ForeverTools.returnSkin('set', assetModifier, uiModifier, 'UI'),
				ForeverTools.returnSkin('go', assetModifier, uiModifier, 'UI')
			]);

			var introAlts:Array<String> = introAssets.get('default');
			for (value in introAssets.keys())
			{
				if (value == PlayState.curStage)
					introAlts = introAssets.get(value);
			}

			if (skipCountdown)
			{
				swagCounter = 4;
				Conductor.songPosition = -5; // delay start position so the ends before it
			}
			else
			{
				switch (swagCounter)
				{
					case 0:
						var prepare:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						prepare.scrollFactor.set();
						prepare.updateHitbox();

						prepare.cameras = [camHUD];

						if (assetModifier == 'pixel')
							prepare.setGraphicSize(Std.int(prepare.width * PlayState.daPixelZoom));

						prepare.screenCenter();
						add(prepare);
						FlxTween.tween(prepare, {y: prepare.y += 50, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								prepare.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('countdown/intro3-' + assetModifier), 0.6);
						Conductor.songPosition = -(Conductor.crochet * 4);
					case 1:
						var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						ready.scrollFactor.set();
						ready.updateHitbox();

						ready.cameras = [camHUD];

						if (assetModifier == 'pixel')
							ready.setGraphicSize(Std.int(ready.width * PlayState.daPixelZoom));

						ready.screenCenter();
						add(ready);
						FlxTween.tween(ready, {y: ready.y += 50, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								ready.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('countdown/intro2-' + assetModifier), 0.6);
						Conductor.songPosition = -(Conductor.crochet * 3);
					case 2:
						var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						set.scrollFactor.set();

						set.cameras = [camHUD];

						if (assetModifier == 'pixel')
							set.setGraphicSize(Std.int(set.width * PlayState.daPixelZoom));

						set.screenCenter();
						add(set);
						FlxTween.tween(set, {y: set.y += 50, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								set.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('countdown/intro1-' + assetModifier), 0.6);
						Conductor.songPosition = -(Conductor.crochet * 2);
					case 3:
						var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[3]));
						go.scrollFactor.set();

						go.cameras = [camHUD];

						if (assetModifier == 'pixel')
							go.setGraphicSize(Std.int(go.width * PlayState.daPixelZoom));

						go.updateHitbox();

						go.screenCenter();
						add(go);
						FlxTween.tween(go, {y: go.y += 50, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								go.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('countdown/introGo-' + assetModifier), 0.6);
						Conductor.songPosition = -(Conductor.crochet * 1);
				}
			}
			swagCounter += 1;
			callFunc('countdownTick', [swagCounter]);
		}, 5);
	}

	override public function destroy()
	{
		callFunc('destroy', []);

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		super.destroy();
	}

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Init.getSetting('Disable Antialiasing') && Std.isOfType(Object, FlxSprite))
			cast(Object, FlxSprite).antialiasing = false;
		return super.add(Object);
	}

	function setupScripts()
	{
		var dirs:Array<Array<String>> = [
			CoolUtil.absoluteDirectory('scripts'),
			CoolUtil.absoluteDirectory('songs/${CoolUtil.swapSpaceDash(PlayState.SONG.song.toLowerCase())}')
		];

		for (dir in dirs)
		{
			for (script in dir)
			{
				if (dir != null && dir.length > 0)
				{
					for (ext in Paths.scriptExts)
					{
						if (script != null && script.length > 0 && script.endsWith('.$ext'))
							scriptArray.push(new ScriptHandler(script));
					}
				}
			}
		}

		callFunc('create', []);
	}

	function reloadScripts()
	{
		scriptArray = [];
		setupScripts();
	}

	public function callFunc(key:String, args:Array<Dynamic>)
	{
		if (scriptArray != null)
		{
			for (i in scriptArray)
				i.call(key, args);
			if (generatedSong)
				setLocalVars();
		}
	}

	public function setVar(key:String, value:Dynamic)
	{
		var allSucceed:Bool = true;
		if (scriptArray != null)
		{
			for (i in scriptArray)
			{
				i.set(key, value);

				if (!i.exists(key))
				{
					trace('${i.scriptFile} failed to set $key for its interpreter, continuing.');
					allSucceed = false;
					continue;
				}
			}
		}
		return allSucceed;
	}

	function setLocalVars()
	{
		// GENERAL
		setVar('game', PlayState.contents);

		if (uiHUD != null)
			setVar('ui', uiHUD);

		setVar('logTrace', function(text:String, time:Float, onConsole:Bool = false)
		{
			logTrace(text, time, onConsole, dialogueHUD);
		});

		setVar('add', add);
		setVar('remove', remove);
		setVar('openSubState', openSubState);

		// debug mode aliases
		setVar('haxeScriptDebug', PlayState.scriptDebugMode);
		setVar('hscriptDebug', PlayState.scriptDebugMode);
		setVar('isDebug', PlayState.scriptDebugMode);
		setVar('scriptDebugMode', PlayState.scriptDebugMode);

		// CHARACTERS
		setVar('songName', PlayState.SONG.song.toLowerCase());

		if (boyfriend != null)
		{
			setVar('bf', boyfriend);
			setVar('boyfriend', boyfriend);
			setVar('bfName', boyfriend.curCharacter);
		}

		if (dad != null)
		{
			setVar('dad', dad);
			setVar('dadOpponent', dad);
			setVar('dadName', dad.curCharacter);
		}

		if (gf != null)
		{
			setVar('gf', gf);
			setVar('girlfriend', gf);
			setVar('gfName', gf.curCharacter);
		}

		if (bfStrums != null)
			setVar('bfStrums', bfStrums);
		if (dadStrums != null)
			setVar('dadStrums', dadStrums);
		if (strumLines != null)
			setVar('strumLines', strumLines);
		if (allUIs != null)
			setVar('allUIs', allUIs);
		if (camGame != null)
			setVar('camGame', camGame);
		if (camHUD != null)
			setVar('camHUD', camHUD);
		if (camAlt != null)
			setVar('camAlt', camAlt);
		if (dialogueHUD != null)
			setVar('dialogueHUD', dialogueHUD);
		if (comboHUD != null)
			setVar('comboHUD', comboHUD);
		if (strumHUD != null)
			setVar('strumHUD', strumHUD);

		setVar('score', songScore);
		setVar('combo', combo);
		setVar('health', health);
		setVar('maxHealth', maxHealth);
		setVar('hits', Timings.notesHit);
		setVar('misses', misses);
		setVar('deaths', deaths);

		setVar('curBeat', curBeat);
		setVar('curStep', curStep);

		setVar('setProperty', function(key:String, value:Dynamic)
		{
			var dotList:Array<String> = key.split('.');

			if (dotList.length > 1)
			{
				var reflector:Dynamic = Reflect.getProperty(this, dotList[0]);

				for (i in 1...dotList.length - 1)
					reflector = Reflect.getProperty(reflector, dotList[i]);

				Reflect.setProperty(reflector, dotList[dotList.length - 1], value);
				return true;
			}

			Reflect.setProperty(this, key, value);
			return true;
		});

		setVar('getProperty', function(variable:String)
		{
			var dotList:Array<String> = variable.split('.');

			if (dotList.length > 1)
			{
				var reflector:Dynamic = Reflect.getProperty(this, dotList[0]);

				for (i in 1...dotList.length - 1)
					reflector = Reflect.getProperty(reflector, dotList[i]);

				return Reflect.getProperty(reflector, dotList[dotList.length - 1]);
			}

			return Reflect.getProperty(this, variable);
		});
	}
}
