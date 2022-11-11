package states.menus;

import base.MusicBeat.MusicBeatState;
import dependency.Discord;
import flash.display.BitmapData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxSpriteUtil;
import funkin.userInterface.AttachedSprite;
import openfl.display.BlendMode;

using StringTools;

typedef CreditsPrefDef =
{
	var bgSprite:String;
	var bgAntialiasing:Bool;
	var users:Array<CreditsUserDef>;
}

typedef CreditsUserDef =
{
	var name:String;
	var icon:String;
	var textData:Array<String>;
	var colors:Array<Int>;
	var urlData:Dynamic;
	var sectionName:String;
}

class CreditsMenu extends MusicBeatState
{
	var gradBG:GradSprite;
	var groupText:FlxText;

	static var curSelected:Int = -1;

	var curSocial:Int = -1;

	var userData:CreditsUserDef;
	var credData:CreditsPrefDef;

	var iconHolder:FlxSprite;
	var iconSprite:AttachedSprite;
	var userText:FlxText;
	var quoteText:FlxText;
	var labelText:FlxText;

	var socialsHolder:FlxSprite;
	var socialSprite:FlxSprite;
	var descText:FlxText;

	var mediaAnimsArray:Array<String> = ['NG', 'Twitter', 'Twitch', 'YT', 'GitHub'];

	var menuBack:FlxSprite;
	var backTween:FlxTween;
	var bDrop:FlxBackdrop;

	var descBG:FlxSprite;
	var desc:FlxText;

	var antialias:Bool = !Init.getSetting('Disable Antialiasing');

	override function create()
	{
		super.create();

		credData = haxe.Json.parse(Paths.getTextFromFile('credits.json'));

		#if DISCORD_RPC
		Discord.changePresence('READING THE CREDITS', 'Credits Menu');
		#end

		generateBackground();

		iconHolder = new FlxSprite(100, 170).makeGraphic(300, 400, 0x00000000);
		FlxSpriteUtil.drawRoundRect(iconHolder, 0, 0, 300, 400, 10, 10, 0x88000000);
		iconHolder.scrollFactor.set(0, 0);
		iconHolder.antialiasing = antialias;
		add(iconHolder);

		iconSprite = new AttachedSprite();
		iconSprite.scrollFactor.set(0, 0);
		iconSprite.antialiasing = antialias;
		add(iconSprite);

		generateUserText('N/A', 25);
		quoteText = new FlxText(0, 0, 0, 'ASPARAGUS', 32);
		quoteText.font = Paths.font('vcr');
		quoteText.scrollFactor.set(0, 0);
		quoteText.antialiasing = antialias;
		quoteText.alignment = "center";
		add(quoteText);

		labelText = new FlxText(0, 0, 0, 'UNKNOWN', 40);
		labelText.font = Paths.font('vcr');
		labelText.scrollFactor.set(0, 0);
		labelText.antialiasing = antialias;
		add(labelText);

		socialsHolder = new FlxSprite(iconHolder.x + iconHolder.width + 100, 170).makeGraphic(600, 400, 0x00000000);
		FlxSpriteUtil.drawRoundRect(socialsHolder, 0, 0, 600, 400, 10, 10, 0x88000000);
		socialsHolder.scrollFactor.set(0, 0);
		socialsHolder.antialiasing = antialias;
		add(socialsHolder);

		socialSprite = new FlxSprite(0, 0);
		socialSprite.frames = Paths.getSparrowAtlas('credits/PlatformIcons');
		for (anim in mediaAnimsArray)
			socialSprite.animation.addByPrefix('$anim', '$anim', 24, true);

		socialSprite.scale.set(0.6, 0.6);
		socialSprite.updateHitbox();
		socialSprite.x = socialsHolder.x + socialsHolder.width / 2 - socialSprite.width / 2;
		add(socialSprite);

		descText = new FlxText(0, 0, 0, 'What Is Love?', 32);
		descText.font = Paths.font('vcr');
		descText.scrollFactor.set(0, 0);
		descText.antialiasing = antialias;
		descText.alignment = "center";
		add(descText);

		var cinematic1:FlxSprite = new FlxSprite(0, -70).makeGraphic(FlxG.width + 100, 200, 0xFF000000);
		cinematic1.scrollFactor.set(0, 0);
		add(cinematic1);

		var cinematic2:FlxSprite = new FlxSprite(-20, FlxG.height - 120).makeGraphic(FlxG.width + 120, 200, 0xFF000000);
		cinematic2.scrollFactor.set(0, 0);
		add(cinematic2);

		curSelected = 0;
		curSocial = 0;
		changeSelection();
		updateSocial(0, false);
	}

	function generateUserText(text:Dynamic, size:Int)
	{
		userText = new FlxText(0, 0, 0, text, size);
		userText.font = Paths.font('vcr');
		userText.scrollFactor.set(0, 0);
		userText.antialiasing = antialias;
		add(userText);
	}

	function generateBackground()
	{
		gradBG = new GradSprite(FlxG.width, FlxG.height, [0xFF000000, 0xFFffffff]);
		add(gradBG);
		if (credData.bgSprite != null || credData.bgSprite.length > 0)
		{
			menuBack = new FlxSprite().loadGraphic(Paths.image(credData.bgSprite));
			menuBack.antialiasing = !credData.bgAntialiasing;
			menuBack.updateHitbox();
		}
		else
		{
			menuBack = new FlxSprite().loadGraphic(Paths.image('menus/base/menuDesat'));
			menuBack.antialiasing = antialias;
		}
		add(menuBack);
		menuBack.blend = MULTIPLY;

		bDrop = new FlxBackdrop(Paths.image('menus/base/grid'), 8, 8, true, true, 1, 1);
		bDrop.velocity.x = 30;
		bDrop.velocity.y = 30;
		bDrop.screenCenter();
		add(bDrop);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		bDrop.alpha = 0.5;

		// MESSY CONTROLS SECTION

		if (controls.UI_UP_P || (!FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel == 1))
			changeSelection(-1);
		else if (controls.UI_DOWN_P || (!FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel == -1))
			changeSelection(1);

		if (controls.UI_LEFT_P || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel == 1))
			updateSocial(-1);
		else if (controls.UI_RIGHT_P || (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel == -1))
			updateSocial(1);

		if (controls.BACK || FlxG.mouse.justPressedRight)
			Main.switchState(this, new MainMenu());

		if (controls.ACCEPT && Reflect.field(credData.users[curSelected].urlData, mediaAnimsArray[curSocial]) != null)
			CoolUtil.browserLoad(Reflect.field(credData.users[curSelected].urlData, mediaAnimsArray[curSocial]));
	}

	var mainColor:FlxColor = FlxColor.WHITE;

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = credData.users.length - 1;
		if (curSelected >= credData.users.length)
			curSelected = 0;

		var pastColor = ((credData.users[curSelected - 1] != null) ? FlxColor.fromRGB(credData.users[curSelected - 1].colors[0],
			credData.users[curSelected - 1].colors[1], credData.users[curSelected - 1].colors[2]) : 0xFFffffff);
		mainColor = FlxColor.fromRGB(credData.users[curSelected].colors[0], credData.users[curSelected].colors[1], credData.users[curSelected].colors[2]);

		gradBG.flxColorTween([pastColor, mainColor]);
		FlxTween.color(bDrop, 0.35, bDrop.color, mainColor);

		iconSprite.loadGraphic(Paths.image('credits/' + credData.users[curSelected].icon));
		iconSprite.y = iconHolder.y + 2;
		iconSprite.x = iconHolder.x + iconHolder.width / 2 - iconSprite.width / 2;
		FlxTween.tween(iconSprite, {y: iconHolder.y + iconHolder.height - iconSprite.height}, 0.2, {type: BACKWARD, ease: FlxEase.elasticOut});

		userText.text = credData.users[curSelected].name;
		if (userText.width > iconHolder.width - 2)
			userText.setGraphicSize(Std.int(iconHolder.width - 2), 0);
		userText.updateHitbox();
		userText.y = iconSprite.y + iconSprite.height + 2;
		userText.x = iconHolder.x + iconHolder.width / 2 - userText.width / 2;
		FlxTween.tween(userText, {y: (iconHolder.y + iconHolder.height - userText.height)}, 0.2, {type: BACKWARD, ease: FlxEase.elasticOut});

		quoteText.text = credData.users[curSelected].textData[1];
		if (quoteText.width > iconHolder.width - 2)
			quoteText.setGraphicSize(Std.int(iconHolder.width - 2), 0);
		quoteText.updateHitbox();
		quoteText.y = userText.y + userText.height + 2;
		quoteText.x = iconHolder.x + iconHolder.width / 2 - quoteText.width / 2;
		FlxTween.tween(quoteText, {y: (iconHolder.y + iconHolder.height - quoteText.height)}, 0.2, {type: BACKWARD, ease: FlxEase.elasticOut});

		descText.text = credData.users[curSelected].textData[0] + '\n';
		if (descText.width > socialsHolder.width - 2)
			descText.setGraphicSize(Std.int(socialsHolder.width - 2), 0);
		descText.updateHitbox();
		descText.y = socialsHolder.y + socialsHolder.height / 2 - descText.height / 2;
		descText.x = socialsHolder.x + socialsHolder.width / 2 - descText.width / 2;
		FlxTween.tween(descText, {y: (socialsHolder.y + socialsHolder.height - descText.height)}, 0.2, {type: BACKWARD, ease: FlxEase.elasticOut});

		var validLabel = (credData.users[curSelected].sectionName != null && credData.users[curSelected].sectionName.length > 0);
		if (validLabel)
			labelText.text = credData.users[curSelected].sectionName;

		if (labelText.width > iconHolder.width - 2)
			labelText.setGraphicSize(Std.int(iconHolder.width - 2), 0);
		labelText.updateHitbox();

		labelText.y = iconHolder.y + iconHolder.height - labelText.height - 9;
		labelText.x = iconHolder.x + 2;
		if (labelText.text == credData.users[curSelected].sectionName) // lol
			FlxTween.tween(labelText, {x: (iconHolder.x - labelText.width)}, 0.2, {type: BACKWARD, ease: FlxEase.elasticOut});

		curSocial = 0;
		updateSocial(0, false);
	}

	public function updateSocial(huh:Int = 0, playSound:Bool = true)
	{
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSocial += huh;
		mediaAnimsArray = Reflect.fields(credData.users[curSelected].urlData);

		if (curSocial < 0)
			curSocial = mediaAnimsArray.length - 1;
		if (curSocial >= mediaAnimsArray.length)
			curSocial = 0;

		socialSprite.animation.play(mediaAnimsArray[curSocial]);
		socialSprite.x = socialsHolder.x + socialsHolder.width / 2 - socialSprite.width / 2;
		socialSprite.y = socialsHolder.y;
	}
}

class GradSprite extends FlxSprite // Just wanted to add some stuff (alternative for createGradientFlxSprite)
{
	var _width:Int;
	var _height:Int;
	var _bitmap:BitmapData;

	public var _colors:Array<FlxColor>;

	public function new(w:Int, h:Int, colors:Array<FlxColor>)
	{
		super();
		_width = w;
		_height = h;
		updateColors(colors);
	}

	public function updateColors(colors:Array<FlxColor>)
	{
		_colors = colors;
		_bitmap = FlxGradient.createGradientBitmapData(_width, _height, colors);
		pixels = _bitmap;
		pixels.lock();
	}

	public function flxColorTween(colors:Array<FlxColor>, duration:Float = 0.35)
	{
		for (i in 0...colors.length)
		{
			var formerColor:FlxColor = _colors[i];
			FlxTween.num(0.0, 1.0, duration, {ease: FlxEase.linear}, function(v:Float)
			{
				_colors[i] = FlxColor.interpolate(formerColor, colors[i], v);
				pixels.dispose();
				pixels.unlock();
				updateColors(_colors);
			});
		}
	}
}
