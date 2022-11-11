import base.CoolUtil;
import base.debug.Overlay;
import flixel.FlxG;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import funkin.Highscore;
import funkin.PlayerSettings;
import openfl.filters.BitmapFilter;
import openfl.filters.ColorMatrixFilter;
import states.*;
import sys.FileSystem;

using StringTools;

/** 
	Enumerator for settingtypes
**/
enum SettingTypes
{
	Checkmark;
	Selector;
	State;
}

/**
	This is the initialisation class. if you ever want to set anything before the game starts or call anything then this is probably your best bet.
	A lot of this code is just going to be similar to the flixel templates' colorblind filters because I wanted to add support for those as I'll
	most likely need them for skater, and I think it'd be neat if more mods were more accessible.
**/
class Init extends FlxState
{
	/*
		Okay so here we'll set custom settings. As opposed to the previous options menu, everything will be handled in here with no hassle.
		This will read what the second value of the key's array is, and then it will categorise it, telling the game which option to set it to.

		0 - boolean, true or false checkmark
		1 - choose string
		2 - choose number (for fps so its low capped at 30)
		3 - offsets, this is unused but it'd bug me if it were set to 0
		might redo offset code since I didnt make it and it bugs me that it's hardcoded the the last part of the controls menu
	 */
	public static var FORCED = 'forced';
	public static var NOT_FORCED = 'not forced';

	public static var comboOffset:Array<Float> = [0, 0];
	public static var ratingOffset:Array<Float> = [0, 0];

	/**
		* hi, gabi (ghost) here, I know this is an odd place to put a comment but i'm gonna try to be more descriptive
		* in regardless to variables and such from now on
		* i think it's nice to explain how at least some of these work at least for the sake of clarity and for making
		* things somewhat easier for everyone

		* here is the main setting format if you want to create a new one
		* set it to the `gameSettings` map and you should be good to go

		* `'Name' => [param1, Type, 'Description', NOT_FORCED`]

		* param1 can be either `true` | `false`, or a string value, like `'bepis'` or something
		* type can be anything on the `SettingTypes` enum,
		* `FORCED` means the main game will hide that option and force it to stay on the default parameter
	**/
	//
	public static var gameSettings:Map<String, Dynamic> = [
		// GAMEPLAY;
		'Downscroll' => [
			false,
			Checkmark,
			'Whether to have the receptors vertically flipped in gameplay.',
			NOT_FORCED
		],
		'Centered Receptors' => [
			false,
			Checkmark,
			"Center your notes, and repositions the enemy's notes to the sides of the screen.",
			NOT_FORCED
		],
		'Hide Opponent Receptors' => [
			false,
			Checkmark,
			"Whether to hide the Opponent's Notes during gameplay.",
			NOT_FORCED
		],
		'Ghost Tapping' => [
			false,
			Checkmark,
			"Enables Ghost Tapping, allowing you to press inputs without missing.",
			NOT_FORCED
		],
		'Ghost Miss Animations' => [
			true,
			Checkmark,
			"Enables Ghost Animations for pressing notes when pressing inputs, requires ghost tapping enabled",
			NOT_FORCED
		],
		"Hitsound Type" => ['default', Selector, 'Choose the Note Hitsound you prefer.', NOT_FORCED, ''],
		'Hitsound Volume' => [0, Selector, 'The volume for your Hitsounds.', NOT_FORCED],
		'Use Custom Note Speed' => [
			false,
			Checkmark,
			"Whether to override the song's scroll speed to use your own.",
			NOT_FORCED
		],
		'Scroll Speed' => [
			1,
			Selector,
			'Set your custom scroll speed for the Notes (NEEDS "Use Custom Note Speed" ENABLED).',
			NOT_FORCED
		],
		// TEXT;
		'Display Accuracy' => [
			true,
			Checkmark,
			'Whether to display your accuracy on the score bar during gameplay.',
			NOT_FORCED
		],
		'Skip Text' => [
			'freeplay only',
			Selector,
			'Decides whether to skip cutscenes and dialogue in gameplay. May be always, only in freeplay, or never.',
			NOT_FORCED,
			['never', 'freeplay only', 'always']
		],
		'Center Display' => [
			'Song Name',
			Selector,
			'What should we display on the Center Mark Text?',
			NOT_FORCED,
			['Song Name', 'Song Time', 'Nothing']
		],
		// META;
		'Auto Pause' => [
			true,
			Checkmark,
			'Whether to pause the game automatically if the window is unfocused.',
			NOT_FORCED
		],
		#if GAME_UPDATER
		'Check for Updates' => [
			true,
			Checkmark,
			"Whether to check for updates when opening the game.",
			NOT_FORCED
		],
		#end
		'GPU Rendering' => [
			false,
			Checkmark,
			"Whether the game should use your GPU to render images. [EXPERIMENTAL, takes effect after restart]",
			NOT_FORCED
		],
		"Framerate Cap" => [120, Selector, 'Define your maximum FPS.', NOT_FORCED, ['']],
		'FPS Counter' => [true, Checkmark, 'Whether to display the FPS counter.', NOT_FORCED],
		'Memory Counter' => [
			true,
			Checkmark,
			'Whether to display approximately how much memory is being used.',
			NOT_FORCED
		],
		'Debug Info' => [
			false,
			Checkmark,
			'Whether to display additional information, such as your current game state or elapsed framerate.',
			NOT_FORCED
		],
		'Overlay Opacity' => [50, Selector, "Set the opacity for the FPS Counter overlay.", NOT_FORCED],
		'Allow Console Window' => [
			true,
			Checkmark,
			'Whether to display a console window when F10 is pressed, useful for scripts.',
			NOT_FORCED
		],
		// USER INTERFACE;
		"UI Skin" => [
			'default',
			Selector,
			'Choose a UI Skin for judgements, combo, etc.',
			NOT_FORCED,
			''
		],
		'Judgement Stacking' => [
			true,
			Checkmark,
			"Whether Judgements should stack on top of eachother, also simplifies their animations if disabled.",
			NOT_FORCED
		],
		'Fixed Judgements' => [
			false,
			Checkmark,
			"Fixes the judgements to the camera instead of to the world itself, making them easier to read.",
			NOT_FORCED
		],
		'Judgement Recycling' => [
			true,
			Checkmark,
			"Rather than adding a new judgement on hit, objects are reused when possible, may cause layering issues.",
			NOT_FORCED
		],
		'Adjust Judgements' => [
			'',
			State,
			"Choose where your judgements should be, requires \"Fixed Judgements\" enabled.",
			NOT_FORCED
		],
		'Colored Health Bar' => [
			false,
			Checkmark,
			"Whether the Health Bar should follow the Character Icon colors.",
			NOT_FORCED
		],
		'Animated Score Color' => [
			true,
			Checkmark,
			"Whether the Score Bar should have an Animation for Hitting, based on your current ranking.",
			NOT_FORCED
		],
		'Hide User Interface' => [
			false,
			Checkmark,
			"Whether the Game HUD should be hidden during gameplay.",
			NOT_FORCED
		],
		'Counter' => [
			'None',
			Selector,
			'Choose whether you want somewhere to display your judgements, and where you want it.',
			NOT_FORCED,
			['None', 'Left', 'Right']
		],
		// NOTES AND HOLDS;
		"Note Skin" => [
			'default',
			Selector,
			'Choose a note skin, can also affect note splashes.',
			NOT_FORCED,
			''
		],
		"Clip Style" => [
			'stepmania',
			Selector,
			"Chooses a style for hold note clippings; StepMania: Holds under Receptors; FNF: Holds over receptors",
			NOT_FORCED,
			['StepMania', 'FNF']
		],
		'Arrow Opacity' => [
			80,
			Selector,
			"Set the opacity for your Strumline Notes [gray notes at the top / bottom].",
			NOT_FORCED
		],
		'Splash Opacity' => [
			50,
			Selector,
			"Set the opacity for your notesplashes, usually shown when hit a \"Sick!\" Judgement on Notes.",
			NOT_FORCED
		],
		"Hold Opacity" => [
			60,
			Selector,
			"Set the opacity for your hold notes.. Huh, why isnt the trail cut off?",
			NOT_FORCED
		],
		'No Camera Note Movement' => [
			false,
			Checkmark,
			'When enabled, left and right notes no longer move the camera.',
			NOT_FORCED
		],
		// ACCESSIBILITY;
		'Disable Antialiasing' => [
			false,
			Checkmark,
			'Whether to disable Anti-aliasing. can improve performance in Framerate.',
			NOT_FORCED
		],
		'Disable Flashing Lights' => [
			false,
			Checkmark,
			"Whether flashing elements on the menus should be disabled.",
			NOT_FORCED
		],
		'Disable Shaders' => [
			false,
			Checkmark,
			"Whether to disable Fragment / Vertex shaders during gameplay, can improve performance.",
			NOT_FORCED
		],
		'Reduced Movements' => [
			false,
			Checkmark,
			'Whether to reduce movements, like icons bouncing or beat zooms in gameplay.',
			NOT_FORCED
		],
		'Darkness Opacity' => [
			0,
			Selector,
			'Darkens non-ui elements, useful if you find the characters and backgrounds distracting.',
			NOT_FORCED
		],
		'Opacity Type' => [
			'World',
			Selector,
			'Choose where the Darkness Opacity Filter should be applied.',
			NOT_FORCED,
			['World', 'Notes']
		],
		'Filter' => [
			'none',
			Selector,
			'Choose a filter for colorblindness.',
			NOT_FORCED,
			['none', 'Deuteranopia', 'Protanopia', 'Tritanopia']
		],
		'Menu Song' => [
			#if FOREVER_ENGINE_WATERMARKS 'foreverMenu', #else 'freakyMenu', #end
			Selector,
			'Which song should we use for the Main Menu?',
			NOT_FORCED,
			''
		],
		'Pause Song' => [
			'breakfast',
			Selector,
			'Which song should we use for the Pause Menu?',
			NOT_FORCED,
			''
		],
		'Discord Rich Presence' => [
			true,
			Checkmark,
			"Whether to have your current game status displayed on Discord. [REQUIRES RESTART]",
			NOT_FORCED
		],
		// custom ones lol
		'Offset' => [Checkmark, 3],
		// USED BY OTHER STATES
		'Left Flashing State' => [
			false,
			Checkmark,
			"Whether you did left the flashing lights warning state.",
			NOT_FORCED
		],
	];

	public static var trueSettings:Map<String, Dynamic> = [];
	public static var settingsDescriptions:Map<String, String> = [];

	public static var gameControls:Map<String, Dynamic> = [
		'LEFT' => [[FlxKey.LEFT, A], 0],
		'DOWN' => [[FlxKey.DOWN, S], 1],
		'UP' => [[FlxKey.UP, W], 2],
		'RIGHT' => [[FlxKey.RIGHT, D], 3],
		'ACCEPT' => [[FlxKey.SPACE, Z, FlxKey.ENTER], 6],
		'BACK' => [[FlxKey.BACKSPACE, X, FlxKey.ESCAPE], 7],
		'PAUSE' => [[FlxKey.ENTER, P], 8],
		'RESET' => [[R, NUMPADMULTIPLY], 9],
		'CHEAT' => [[SEVEN, EIGHT], 10],
		'UI_UP' => [[FlxKey.UP, W], 13],
		'UI_DOWN' => [[FlxKey.DOWN, S], 14],
		'UI_LEFT' => [[FlxKey.LEFT, A], 15],
		'UI_RIGHT' => [[FlxKey.RIGHT, D], 16],
	];

	public static var filters:Array<BitmapFilter> = []; // the filters the game has active
	/// initalise filters here
	public static var gameFilters:Map<String, {filter:BitmapFilter, ?onUpdate:Void->Void}> = [
		"Deuteranopia" => {
			var matrix:Array<Float> = [
				0.43, 0.72, -.15, 0, 0,
				0.34, 0.57, 0.09, 0, 0,
				-.02, 0.03,    1, 0, 0,
				   0,    0,    0, 1, 0,
			];
			{filter: new ColorMatrixFilter(matrix)}
		},
		"Protanopia" => {
			var matrix:Array<Float> = [
				0.20, 0.99, -.19, 0, 0,
				0.16, 0.79, 0.04, 0, 0,
				0.01, -.01,    1, 0, 0,
				   0,    0,    0, 1, 0,
			];
			{filter: new ColorMatrixFilter(matrix)}
		},
		"Tritanopia" => {
			var matrix:Array<Float> = [
				0.97, 0.11, -.08, 0, 0,
				0.02, 0.82, 0.16, 0, 0,
				0.06, 0.88, 0.18, 0, 0,
				   0,    0,    0, 1, 0,
			];
			{filter: new ColorMatrixFilter(matrix)}
		}
	];

	inline public static function getSetting(setting:String)
	{
		return trueSettings.get(setting);
	}

	inline public static function setSetting(setting:String, value:Dynamic)
	{
		return trueSettings.set(setting, value);
	}

	override public function create():Void
	{
		// load base game highscores and settings;
		PlayerSettings.init();
		Highscore.load();

		// load forever settings;
		loadControls();
		loadSettings();

		#if !html5
		Main.updateFramerate(trueSettings.get("Framerate Cap"));
		#end

		// apply saved filters
		FlxG.game.setFilters(filters);

		// Some additional changes to default HaxeFlixel settings, both for ease of debugging and usability.
		FlxG.fixedTimestep = false; // This ensures that the game is not tied to the FPS
		// FlxG.mouse.useSystemCursor = true; // Use system cursor because it's prettier
		FlxG.mouse.visible = false; // Hide mouse on start
		FlxGraphic.defaultPersist = true; // make sure we control all of the memory

		CoolUtil.difficulties = CoolUtil.baseDifficulties.copy();

		Main.switchState(this, cast Type.createInstance(Main.mainClassState, []));
	}

	public static function loadSettings():Void
	{
		FlxG.save.bind('gameSettings');

		// set the true settings array
		// only the first variable will be saved! the rest are for the menu stuffs

		// IF YOU WANT TO SAVE MORE THAN ONE VALUE MAKE YOUR VALUE AN ARRAY INSTEAD
		for (setting in gameSettings.keys())
			trueSettings.set(setting, gameSettings.get(setting)[0]);

		// NEW SYSTEM, INSTEAD OF REPLACING THE WHOLE THING I REPLACE EXISTING KEYS
		// THAT WAY IT DOESNT HAVE TO BE DELETED IF THERE ARE SETTINGS CHANGES
		if (FlxG.save.data.settings != null)
		{
			var settingsMap:Map<String, Dynamic> = FlxG.save.data.settings;
			for (singularSetting in settingsMap.keys())
				if (gameSettings.get(singularSetting) != null && gameSettings.get(singularSetting)[3] != FORCED)
					trueSettings.set(singularSetting, FlxG.save.data.settings.get(singularSetting));
		}

		// lemme fix that for you
		if (!Std.isOfType(trueSettings.get("Framerate Cap"), Int)
			|| trueSettings.get("Framerate Cap") < 30
			|| trueSettings.get("Framerate Cap") > 360)
			trueSettings.set("Framerate Cap", 30);

		var similarSettings:Array<String> = [
			"Darkness Opacity",
			"Hitsound Volume",
			"Arrow Opacity",
			"Splash Opacity",
			"Overlay Opacity",
			"Hold Opacity"
		];

		for (i in similarSettings)
		{
			var defaultValue = 100;
			switch (i)
			{
				case 'Darkness Opacity':
					defaultValue = 0;
				case "Hitsound Volume":
					defaultValue = 0;
				case "Arrow Opacity":
					defaultValue = 80;
				case "Splash Opacity" | "Overlay Opacity":
					defaultValue = 50;
				case "Hold Opacity":
					defaultValue = 60;
			}
			if (!Std.isOfType(trueSettings.get(i), Int) || trueSettings.get(i) < 0 || trueSettings.get(i) > 100)
				trueSettings.set(i, defaultValue);
		}

		reloadCustomSkins();

		updateAll();

		if (FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;
		if (FlxG.save.data.comboOffset != null)
			comboOffset = FlxG.save.data.comboOffset;
		if (FlxG.save.data.ratingOffset != null)
			ratingOffset = FlxG.save.data.ratingOffset;

		if (!trueSettings.get('Left Flashing State'))
			Main.mainClassState = states.WarningState;

		saveSettings();
		updateAll();
	}

	public static function saveSettings():Void
	{
		// ez save lol
		FlxG.save.bind('gameSettings');
		FlxG.save.data.comboOffset = comboOffset;
		FlxG.save.data.ratingOffset = ratingOffset;
		FlxG.save.data.settings = trueSettings;
		FlxG.save.flush();
		updateAll();
	}

	public static function saveControls():Void
	{
		FlxG.save.bind('gameControls');
		FlxG.save.data.controls = gameControls;
		FlxG.save.flush();
	}

	public static function loadControls():Void
	{
		FlxG.save.bind('gameControls');
		if (FlxG.save != null && FlxG.save.data.controls != null)
		{
			if ((FlxG.save.data.controls != null) && (Lambda.count(FlxG.save.data.controls) == Lambda.count(gameControls)))
				gameControls = FlxG.save.data.controls;
		}

		saveControls();
	}

	public static function updateAll()
	{
		FlxG.autoPause = trueSettings.get('Auto Pause');

		Overlay.updateDisplayInfo(trueSettings.get('FPS Counter'), trueSettings.get('Memory Counter'), trueSettings.get('Debug Info'));

		#if !html5
		Main.updateFramerate(trueSettings.get("Framerate Cap"));
		#end

		Main.updateOverlayAlpha(trueSettings.get('Overlay Opacity') * 0.01);

		filters = [];
		FlxG.game.setFilters(filters);

		var theFilter:String = trueSettings.get('Filter');
		if (theFilter != 'none' && gameFilters.get(theFilter) != null)
		{
			var realFilter = gameFilters.get(theFilter).filter;

			if (realFilter != null)
				filters.push(realFilter);
		}
		FlxG.game.setFilters(filters);
	}

	public static function reloadCustomSkins()
	{
		// 'hardcoded' ui skins
		gameSettings.get("UI Skin")[4] = CoolUtil.returnAssetsLibrary('UI', 'images');
		if (!gameSettings.get("UI Skin")[4].contains(trueSettings.get("UI Skin")))
			trueSettings.set("UI Skin", 'default');

		gameSettings.get("Note Skin")[4] = CoolUtil.returnAssetsLibrary('noteskins/notes');
		if (!gameSettings.get("Note Skin")[4].contains(trueSettings.get("Note Skin")))
			trueSettings.set("Note Skin", 'default');

		gameSettings.get("Hitsound Type")[4] = CoolUtil.returnAssetsLibrary('hitsounds', 'sounds');
		if (!gameSettings.get("Hitsound Type")[4].contains(trueSettings.get("Hitsound Type")))
			trueSettings.set("Hitsound Type", 'default');

		gameSettings.get("Menu Song")[4] = CoolUtil.returnAssetsLibrary('menus/main', 'music');
		if (!gameSettings.get("Menu Song")[4].contains(trueSettings.get("Menu Song")))
			trueSettings.set("Menu Song", #if FOREVER_ENGINE_WATERMARKS 'foreverMenu' #else 'freakyMenu' #end);

		gameSettings.get("Pause Song")[4] = CoolUtil.returnAssetsLibrary('menus/pause', 'music');
		if (!gameSettings.get("Pause Song")[4].contains(trueSettings.get("Pause Song")))
			trueSettings.set("Pause Song", 'breakfast');
	}
}
