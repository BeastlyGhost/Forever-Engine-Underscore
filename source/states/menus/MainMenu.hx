package states.menus;

import base.MusicBeat.MusicBeatState;
import dependency.Discord;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import states.substates.PauseSubstate;
import sys.FileSystem;

using StringTools;

/**
	This is the main menu state! Not a lot is going to change about it so it'll remain similar to the original, but I do want to condense some code and such.
	Get as expressive as you can with this, create your own menu!
**/
class MainMenu extends MusicBeatState
{
	public var menuItems:FlxTypedGroup<FlxSprite>;

	public static var curSelected:Float = 0;

	public var bg:FlxSprite;
	public var magenta:FlxSprite;
	public var camFollow:FlxObject;

	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;

	public var optionShit:Array<String> = ['story mode', 'freeplay', /*'mods',*/ 'credits', 'options'];

	public var forceCenter:Bool = true;

	public var menuItemScale:Float = 1;

	function setCameras()
	{
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);
	}

	override function create()
	{
		super.create();

		// make sure the music is playing
		ForeverTools.resetMenuMusic();

		#if DISCORD_RPC
		Discord.changePresence('MENU SCREEN', 'Main Menu');
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		// uh
		persistentUpdate = persistentDraw = true;

		setCameras();

		bg = new FlxSprite().loadGraphic(Paths.image('menus/base/menuBG'));
		bg.scrollFactor.set(0, 0.17);
		bg.setGraphicSize(Std.int(bg.width * 1.2));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = !Init.getSetting('Disable Antialiasing');
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menus/base/menuDesat'));
		magenta.scrollFactor.set(bg.scrollFactor.x, bg.scrollFactor.y);
		magenta.setGraphicSize(Std.int(bg.width));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = !Init.getSetting('Disable Antialiasing');
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var maxLength:Float = 58 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 160) + maxLength);
			menuItem.frames = Paths.getSparrowAtlas('menus/base/menuItems/' + optionShit[i]);

			menuItem.scale.set(menuItemScale, menuItemScale);

			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;

			if (forceCenter)
				menuItem.screenCenter(X);
			if (menuItem.ID % 2 == 0)
				menuItem.x += 1000;
			else
				menuItem.x -= 1000;

			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = !Init.getSetting('Disable Antialiasing');
			menuItem.updateHitbox();
		}

		var camLerp = Main.framerateAdjust(0.10);
		FlxG.camera.follow(camFollow, null, camLerp);

		updateSelection();

		var versionShit:FlxText = new FlxText(5, FlxG.height
			- 38, 0,
			"Forever Engine Legacy v"
			+ Main.foreverVersion
			+ "\nForever Engine Underscore v"
			+ Main.engineVersion
			+ (Main.nightly ? '-nightly' : ''), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font('vcr'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (!selectedSomethin)
		{
			if (controls.BACK || FlxG.mouse.justPressedRight)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
				Main.switchState(this, new TitleState());
			}

			if (controls.CHEAT)
			{
				persistentUpdate = false;
				persistentDraw = true;
				openSubState(new states.substates.EditorMenuSubstate(false));
			}

			var controlArray:Array<Bool> = [
				controls.UI_UP,
				controls.UI_DOWN,
				controls.UI_UP_P,
				controls.UI_DOWN_P,
				FlxG.mouse.wheel == 1,
				FlxG.mouse.wheel == -1
			];
			if ((controlArray.contains(true)))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i] == true)
					{
						if (i > 1)
						{
							if (i == 2 || i == 4)
								curSelected--;
							else if (i == 3 || i == 5)
								curSelected++;

							if (i == 2 || i == 3)
								FlxG.sound.play(Paths.sound('scrollMenu'));
						}
						if (curSelected < 0)
							curSelected = optionShit.length - 1;
						else if (curSelected >= optionShit.length)
							curSelected = 0;
					}
				}
			}

			if (controls.ACCEPT)
			{
				//
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				var flickerVal:Float = 0.06;

				if (Init.getSetting('Disable Flashing Lights'))
					flickerVal = 1;
				if (!Init.getSetting('Disable Flashing Lights'))
					FlxFlicker.flicker(magenta, 0.8, 0.1, false);

				menuItems.forEach(function(spr:FlxSprite)
				{
					if (curSelected != spr.ID)
					{
						FlxTween.tween(spr, {alpha: 0, x: FlxG.width * 2}, 0.4, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween)
							{
								spr.kill();
							}
						});
					}
					else
					{
						FlxFlicker.flicker(spr, 1, flickerVal, false, false, function(flick:FlxFlicker)
						{
							switch (optionShit[Math.floor(curSelected)])
							{
								case 'story mode':
									Main.switchState(this, new StoryMenu());
								case 'freeplay':
									Main.switchState(this, new FreeplayMenu());
								case 'mods':
									Main.switchState(this, new ModsMenu());
								case 'credits':
									Main.switchState(this, new CreditsMenu());
								case 'options':
									PauseSubstate.toOptions = false;
									transIn = FlxTransitionableState.defaultTransIn;
									transOut = FlxTransitionableState.defaultTransOut;
									Main.switchState(this, new OptionsMenu());
							}
						});
					}
				});
			}
		}

		if (Math.floor(curSelected) != lastCurSelected)
			updateSelection();

		super.update(elapsed);

		menuItems.forEach(function(menuItem:FlxSprite)
		{
			if (forceCenter)
				menuItem.screenCenter(X);
		});
	}

	var lastCurSelected:Int = 0;

	function updateSelection()
	{
		// reset all selections
		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			menuItems.members[Math.floor(curSelected)].scale.set(menuItemScale, menuItemScale);
		});

		var itemLength:Float = 0;
		if (menuItems.length > 4)
			itemLength = menuItems.length * 8;

		// set the sprites and all of the current selection
		camFollow.setPosition(menuItems.members[Math.floor(curSelected)].getGraphicMidpoint().x,
			menuItems.members[Math.floor(curSelected)].getGraphicMidpoint().y - itemLength);

		if (menuItems.members[Math.floor(curSelected)].animation.curAnim.name == 'idle')
			menuItems.members[Math.floor(curSelected)].animation.play('selected');

		menuItems.members[Math.floor(curSelected)].updateHitbox();

		lastCurSelected = Math.floor(curSelected);
	}
}
