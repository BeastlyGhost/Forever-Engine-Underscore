package states.substates.editors;

import base.MusicBeat.MusicBeatSubstate;
import dependency.FNFSprite;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.Alphabet;
import funkin.userInterface.menu.Checkmark;
import funkin.userInterface.menu.Selector;

enum SettingTypes
{
	Checkmark;
	Selector;
}

class PreferenceSubstate extends MusicBeatSubstate
{
	//
	var blackTopBar:FlxSprite;
	var blackBottomBar:FlxSprite;

	var topText:FlxText;

	var purpleTopBar:FlxSprite;
	var purpleBottomBar:FlxSprite;

	var background:FlxSprite;
	var purpleBarColor:FlxColor;
	var topTextString:String = '';

	// ya i copied these from OptionsMenu
	var categoryMap:Map<String, Dynamic>;
	var activeSubgroup:FlxTypedGroup<Alphabet>;
	var attachments:FlxTypedGroup<FlxBasic>;

	var curSelection = 0;
	var curSelectedScript:Void->Void;
	var curCategory:String;

	var lockedMovement:Bool = false;

	var closing = false;

	/**
	 * a map for your settings, feel free to add or remove as you please
	 * will rewrite settings later as they use code from Options and Init
	**/
	public static var chartSettings:Map<String, Dynamic> = [
		'Boyfriend Hitsounds' => [true],
		'Opponent Hitsounds' => [true],
		'Audio Offset' => [0],
	];

	public function new(camera:FlxCamera, menu:String)
	{
		super();

		if (menu == 'prefs')
		{
			purpleBarColor = FlxColor.fromRGB(81, 0, 130);
			topTextString = 'PREFERENCES MENU';
		}
		else
		{
			purpleBarColor = FlxColor.fromRGB(0, 213, 255);
			topTextString = 'HELP MENU';
		}

		//
		background = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		background.alpha = 0;
		add(background);

		blackTopBar = new FlxSprite(0, -75).makeGraphic(FlxG.width, 75, FlxColor.BLACK);
		add(blackTopBar);

		topText = new FlxText(blackTopBar.x + 15, blackTopBar.y + 15, topTextString);
		topText.setFormat(Paths.font("vcr"), 24);
		add(topText);

		blackBottomBar = new FlxSprite(0, FlxG.height).makeGraphic(FlxG.width, 75, FlxColor.BLACK);
		add(blackBottomBar);

		//
		purpleTopBar = new FlxSprite(blackTopBar.x, blackTopBar.y + 60).makeGraphic(FlxG.width, 8, purpleBarColor);
		add(purpleTopBar);

		purpleBottomBar = new FlxSprite(blackBottomBar.x, blackBottomBar.y + 9).makeGraphic(FlxG.width, 8, purpleBarColor);
		add(purpleBottomBar);

		//
		blackTopBar.cameras = [camera];
		blackBottomBar.cameras = [camera];
		topText.cameras = [camera];
		background.cameras = [camera];

		purpleBottomBar.cameras = [camera];
		purpleTopBar.cameras = [camera];
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
		}

		popObjects();
	}

	function popObjects()
	{
		blackTopBar.y = FlxMath.lerp(0, blackTopBar.y, 0.75);
		blackBottomBar.y = FlxMath.lerp(FlxG.height - blackBottomBar.height, blackBottomBar.y, 0.75);
		topText.y = blackTopBar.y + 15;

		purpleTopBar.y = blackTopBar.y + 60;
		purpleBottomBar.y = blackBottomBar.y + 9;

		background.alpha = FlxMath.lerp(150 / 255, background.alpha, 0.75);
	}
}
