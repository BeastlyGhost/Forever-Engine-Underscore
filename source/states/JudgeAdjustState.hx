package states;

import base.MusicBeat.MusicBeatState;
import dependency.FNFSprite;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.Character;
import funkin.Stage;
import funkin.Strumline;

using StringTools;

class JudgeAdjustState extends MusicBeatState
{
	var infoBar:FlxText;
	var stageBuild:Stage;
	var judge:FNFSprite;
	var combo:FNFSprite;

	var dadStrums:Strumline;
	var bfStrums:Strumline;

	var _camWorld:FlxCamera;
	var _camUI:FlxCamera;

	var judgeDefPos:FlxPoint;
	var comboDefPos:FlxPoint;
	var judgeNewPos:FlxPoint;
	var comboNewPos:FlxPoint;

	override function create()
	{
		super.create();
		var cursorAsset = ForeverTools.returnSkin('cursor', 'base', Init.trueSettings.get('UI Skin'), 'UI');
		var cursor:flixel.FlxSprite = new flixel.FlxSprite().loadGraphic(Paths.image(cursorAsset));

		FlxG.mouse.visible = true;
		FlxG.mouse.load(cursor.pixels);

		judgeDefPos = FlxPoint.get();
		comboDefPos = FlxPoint.get();

		_camWorld = new FlxCamera();
		_camUI = new FlxCamera();
		_camUI.bgColor.alpha = 0;

		FlxG.cameras.reset(_camWorld);
		FlxG.cameras.add(_camUI, false);

		stageBuild = new Stage('stage', true);
		add(stageBuild);

		var bfPlacement:Float = FlxG.width / 2 + (!Init.getSetting('Centered Receptors') ? FlxG.width / 4 : 0);
		var dadPlacement:Float = (FlxG.width / 2) - FlxG.width / 4;

		dadStrums = new Strumline(dadPlacement, Init.getSetting('Downscroll') ? FlxG.height - 200 : 0);
		bfStrums = new Strumline(bfPlacement, Init.getSetting('Downscroll') ? FlxG.height - 200 : 0);

		bfStrums.downscroll = Init.getSetting('Downscroll');
		dadStrums.downscroll = Init.getSetting('Downscroll');

		bfStrums.cameras = [_camUI];
		dadStrums.cameras = [_camUI];

		dadStrums.visible = (!Init.getSetting('Hide Opponent Receptors') || Init.getSetting('Centered Receptors'));

		infoBar = new FlxText((Init.getSetting('Downscroll') ? FlxG.height - 45 : 20), 0, '');
		infoBar.setFormat(Paths.font('vcr'), 32, FlxColor.WHITE);
		infoBar.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		infoBar.antialiasing = !Init.getSetting('Disable Antialiasing');
		add(infoBar);

		var assetModifier = PlayState.assetModifier;
		if (PlayState.assetModifier == null)
			assetModifier = 'base';

		judge = ForeverAssets.generateRating('sick', true, false, null, assetModifier, Init.getSetting('UI Skin'), 'UI', true);
		judge.cameras = [_camUI];
		add(judge);

		judgeDefPos.set(judge.x, judge.y);

		var comboString:String = Std.string(FlxG.random.int(0, 9));
		var stringArray:Array<String> = comboString.split("");

		for (scoreInt in 0...stringArray.length)
		{
			combo = ForeverAssets.generateCombo('combo_numbers', stringArray[scoreInt], true, null, assetModifier, Init.getSetting('UI Skin'), 'UI', false,
				FlxColor.WHITE, scoreInt, true);
			if (combo != null)
				combo.animation.play('combo-perfect');
			combo.cameras = [_camUI];
			combo.y += 50;
			combo.x += 100;
			add(combo);

			comboDefPos.set(combo.x, combo.y);
		}

		add(dadStrums);
		add(bfStrums);

		comboNewPos = FlxPoint.get(Init.comboOffset[0], Init.comboOffset[1]);
		judgeNewPos = FlxPoint.get(Init.ratingOffset[0], Init.ratingOffset[1]);
	}

	var mousePos:FlxPoint = new FlxPoint();
	var heldObject:String = null;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		infoBar.text = 'Rating Position: ' + judge.x + ' - ' + judge.y + ' • Combo Position: ' + combo.x + ' - ' + combo.y;
		infoBar.x = Math.floor((FlxG.width / 2) - (infoBar.width / 2));

		if (FlxG.mouse.justPressed)
		{
			heldObject = null;
			FlxG.mouse.getScreenPosition(_camUI, mousePos);
			if (FlxG.mouse.pressed && heldObject == null)
			{
				if (mousePos.x - combo.x >= 0 && mousePos.x - combo.x <= combo.width && mousePos.y - combo.y >= 0 && mousePos.y - combo.y <= combo.height)
				{
					heldObject = "combo";
					comboNewPos.x = Init.comboOffset[0];
					comboNewPos.y = Init.comboOffset[1];
				}
				else if (mousePos.x - judge.x >= 0 && mousePos.x - judge.x <= judge.width && mousePos.y - judge.y >= 0 && mousePos.y - judge.y <= judge.height)
				{
					heldObject = "judge";
					judgeNewPos.x = Init.ratingOffset[0];
					judgeNewPos.y = Init.ratingOffset[1];
				}
			}
		}

		if (FlxG.mouse.justReleased)
			heldObject = null;

		if (heldObject != null)
		{
			if (FlxG.mouse.justMoved)
			{
				var thisMousePos:FlxPoint = FlxG.mouse.getScreenPosition(_camUI);
				if (heldObject == "combo")
				{
					Init.comboOffset[0] = Math.round((thisMousePos.x - mousePos.x) + comboNewPos.x);
					Init.comboOffset[1] = Math.round((thisMousePos.y - mousePos.y) + comboNewPos.y);
				}
				else if (heldObject == "judge")
				{
					Init.ratingOffset[0] = Math.round((thisMousePos.x - mousePos.x) + judgeNewPos.x);
					Init.ratingOffset[1] = Math.round((thisMousePos.y - mousePos.y) + judgeNewPos.y);
				}
			}
		}

		combo.x = comboDefPos.x + Init.comboOffset[0];
		combo.y = comboDefPos.y + Init.comboOffset[1];

		judge.x = judgeDefPos.x + Init.ratingOffset[0];
		judge.y = judgeDefPos.y + Init.ratingOffset[1];

		if (controls.RESET)
		{
			Init.comboOffset = [0, 0];
			Init.ratingOffset = [0, 0];
		}

		if (controls.ACCEPT || controls.BACK)
		{
			Init.saveSettings();
			FlxG.mouse.visible = false;
			Main.switchState(this, new states.menus.OptionsMenu());
		}
	}
}
