package states;

import base.MusicBeat.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import openfl.display.BlendMode;
import states.menus.MainMenu;

/**
	a state for general warnings
	this is just code from the base game that i've made some slight improvements to
**/
class WarningState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warningText:FlxText;
	var warningType:String = 'flashing';

	var warningField:String = 'beep bop bo skdkdkdbebedeoop brrapadop';
	var fieldOffset:Float = 0;

	public function new(warningType:String = 'flashing')
	{
		super();
		this.warningType = warningType;
	}

	override function create()
	{
		super.create();

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		// uh
		persistentUpdate = persistentDraw = true;

		switch (warningType)
		{
			case 'update':
				warningField = "Hey, You're running an outdated version of"
					+ "\nForever Engine Underscore"
					+ "\n\nPress ENTER to Update from "
					+ Main.engineVersion
					+ ' to '
					+ ForeverTools.updateVersion
					+ '\nPress ESCAPE to ignore this message.'
					+ "\n\nif you wish to disable this\nUncheck \"Check for Updates\" on the Options Menu";
			case 'flashing':
				warningField = "Hey, quick notice that this mod contains Flashing Lights"
					+ "\nYou can Press ENTER to disable them now or ESCAPE to ignore"
					+ "\nyou can later manage flashing lights and other\naccessibility settings by going to the Options Menu"
					+ "\n\nYou've been warned\n";
				fieldOffset = 50;
		}

		generateBackground();

		warningText = new FlxText(0, 0, FlxG.width - fieldOffset, warningField, 32);
		warningText.setFormat(Paths.font("vcr"), 32, FlxColor.WHITE, CENTER);
		warningText.screenCenter();
		warningText.alpha = 0;
		warningText.antialiasing = !Init.getSetting('Disable Antialiasing');
		add(warningText);

		FlxTween.tween(warningText, {alpha: 1}, 0.4);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE)
		{
			FlxTransitionableState.skipNextTransIn = true;
			textFinishCallback(warningType);
		}
	}

	var background:FlxSprite;
	var darkBackground:FlxSprite;
	var funkyBack:FlxSprite;

	function generateBackground()
	{
		background = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [FlxColor.fromRGB(167, 103, 225), FlxColor.fromRGB(137, 20, 181)]);
		background.alpha = 0;
		add(background);

		darkBackground = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		darkBackground.setGraphicSize(Std.int(FlxG.width));
		darkBackground.scrollFactor.set();
		darkBackground.screenCenter();
		darkBackground.alpha = 0;
		add(darkBackground);

		funkyBack = new FlxSprite().loadGraphic(Paths.image('menus/chart/bg'));
		funkyBack.setGraphicSize(Std.int(FlxG.width));
		funkyBack.scrollFactor.set();
		funkyBack.blend = BlendMode.DIFFERENCE;
		funkyBack.screenCenter();
		funkyBack.alpha = 0;
		add(funkyBack);

		FlxTween.tween(background, {alpha: 0.6}, 0.4);
		FlxTween.tween(darkBackground, {alpha: 0.7}, 0.4);
		FlxTween.tween(funkyBack, {alpha: 0.07}, 0.4);
	}

	function textFinishCallback(type:String = 'flashing')
	{
		var bgSprites:Array<FlxSprite> = [background, darkBackground, funkyBack];

		switch (type)
		{
			case 'update':
				if (!FlxG.keys.justPressed.ESCAPE)
				{
					FlxG.sound.play(Paths.sound('confirmMenu'));
					FlxFlicker.flicker(warningText, 1, 0.06 * 2, true, false, function(flick:FlxFlicker)
					{
						leftState = true;
						warningText.alpha = 0;
						for (i in bgSprites)
							i.alpha = 0;
						CoolUtil.browserLoad('https://github.com/BeastlyGhost/Forever-Engine-Underscore');
						Main.switchState(this, new MainMenu());
					});
				}
				else
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					for (i in bgSprites)
						FlxTween.tween(i, {alpha: 0}, 0.6);
					FlxTween.tween(warningText, {alpha: 0}, 0.6, {
						onComplete: function(twn:FlxTween)
						{
							leftState = true;
							Main.switchState(this, new MainMenu());
						}
					});
				}
			case 'flashing':
				if (!FlxG.keys.justPressed.ESCAPE)
				{
					FlxG.sound.play(Paths.sound('confirmMenu'));
					Init.trueSettings.set('Disable Flashing Lights', true);
					FlxFlicker.flicker(warningText, 1, 0.06 * 2, true, false, function(flick:FlxFlicker)
					{
						Init.trueSettings.set('Left Flashing State', true);
						warningText.alpha = 0;
						for (i in bgSprites)
							i.alpha = 0;
						Main.switchState(this, new TitleState());
					});
				}
				else
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					for (i in bgSprites)
						FlxTween.tween(i, {alpha: 0}, 0.6);
					FlxTween.tween(warningText, {alpha: 0}, 0.6, {
						onComplete: function(twn:FlxTween)
						{
							Init.trueSettings.set('Left Flashing State', true);
							Main.switchState(this, new TitleState());
						}
					});
				}
		}
	}

	function endState(type:String)
	{
		switch (type)
		{
			case 'flashing':
				Main.switchState(this, new TitleState());
			case 'update':
				Main.switchState(this, new MainMenu());
		}
	}
}
