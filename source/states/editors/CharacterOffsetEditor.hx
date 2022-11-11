package states.editors;

import base.MusicBeat;
import dependency.Discord;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUITabMenu;
import flixel.animation.FlxAnimation;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import funkin.Alphabet;
import funkin.Character;
import funkin.userInterface.HealthIcon;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import states.editors.data.PsychDropDown;

using StringTools;

/*
	Character Offset Editor, exports Characters and converts them to the Underscore Format, WORK IN PROGRESS;
 */
class CharacterOffsetEditor extends MusicBeatState
{
	var _file:FileReference;

	public static var instance:CharacterOffsetEditor;

	// characters
	var char:Character;
	var ghost:Character;

	public var curCharacter:String;
	public var curGhost:String;

	var isPlayer:Bool = false;

	var fromPlayState:Bool = false;

	var curAnim:Int = 0;

	var textAnim:FlxText;
	var dumbTexts:FlxTypedGroup<FlxText>;
	var animList:Array<String> = [];

	var ghostAnimList:Array<String> = [''];

	var camFollow:FlxObject;

	var camGame:FlxCamera;
	var camHUD:FlxCamera;

	var UI_box:FlxUITabMenu;

	public function new(curCharacter:String = 'bf', isPlayer:Bool = false, fromPlayState:Bool = false)
	{
		super();

		instance = this;

		curGhost = curCharacter;
		this.fromPlayState = fromPlayState;
		this.curCharacter = curCharacter;
		this.isPlayer = isPlayer;
	}

	override public function create()
	{
		super.create();

		FlxG.sound.music.stop();
		var cursorAsset = ForeverTools.returnSkin('cursor', 'base', Init.trueSettings.get('UI Skin'), 'UI');
		var cursor:FlxSprite = new FlxSprite().loadGraphic(Paths.image(cursorAsset));

		FlxG.mouse.visible = true;
		FlxG.mouse.load(cursor.pixels);

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		// set up camFollow
		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		FlxG.camera.follow(camFollow);

		// add stage
		var greyBG:FlxSprite = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5);
		greyBG.makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.GRAY);
		add(greyBG);

		generateGhost(!curCharacter.startsWith('bf') || !curCharacter.endsWith('-player'));
		generateCharacter(!curCharacter.startsWith('bf') || !curCharacter.endsWith('-player'));

		// add texts
		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);

		textAnim = new FlxText(300, 16);
		textAnim.size = 26;
		textAnim.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		textAnim.scrollFactor.set();
		textAnim.cameras = [camHUD];
		add(textAnim);

		genCharOffsets();

		// add menu tabs
		var tabs = [
			{name: 'Preferences', label: 'Preferences'},
			{name: 'Characters', label: 'Characters'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camHUD];
		UI_box.resize(250, 125);
		UI_box.x = FlxG.width - 275;
		UI_box.y = 25;
		UI_box.scrollFactor.set();
		add(UI_box);

		addTextUI();
		addPreferencesUI();
		addCharactersUI();
	}

	var ghostAnimDropDown:PsychDropDown;
	var check_offset:FlxUICheckBox;

	function addPreferencesUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Preferences";

		check_offset = new FlxUICheckBox(10, 60, null, null, "Offset Mode", 100);
		check_offset.checked = true;

		var saveButton:FlxButton = new FlxButton(140, 30, "Save", function()
		{
			saveCharOffsets();
		});

		ghostAnimDropDown = new PsychDropDown(10, 30, PsychDropDown.makeStrIdLabelArray(ghostAnimList, true), function(animation:String)
		{
			if (ghostAnimList[0] != '' || ghostAnimList[0] != null)
				ghost.playAnim(ghostAnimList[Std.parseInt(animation)], true);
		});

		tab_group.add(new FlxText(ghostAnimDropDown.x, ghostAnimDropDown.y - 18, 0, 'Ghost Animation:'));
		tab_group.add(check_offset);
		tab_group.add(ghostAnimDropDown);
		tab_group.add(saveButton);
		UI_box.addGroup(tab_group);
	}

	var showGhost:Bool = false;
	var followCharOffset:Bool = true;

	var showGhostBttn:FlxButton;
	var followCharOffsetBttn:FlxButton;

	var characterSelectBttn:FlxButton;
	var ghostSelectBttn:FlxButton;
	var characterSelTextField:FlxText;
	var ghostSelTextField:FlxText;

	function addCharactersUI()
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Characters";

		var characters:Array<String> = CoolUtil.returnAssetsLibrary('characters', '');

		var resetBttn:FlxButton = new FlxButton(140, 30, "Reset Offsets", function()
		{
			var prevCharacter = curCharacter;
			var isPlayState = fromPlayState;
			Main.switchState(this, new CharacterOffsetEditor(prevCharacter, !prevCharacter.startsWith('bf'), isPlayState));
		});

		showGhostBttn = new FlxButton(140, 50, "Show Ghost", function()
		{
			if (!showGhost)
			{
				ghost.visible = true;
				showGhostBttn.text = 'Hide Ghost';
				showGhost = true;
			}
			else
			{
				ghost.visible = false;
				showGhostBttn.text = 'Show Ghost';
				showGhost = false;
			}
		});

		followCharOffsetBttn = new FlxButton(140, 70, "Follow: ON", function()
		{
			if (followCharOffset)
			{
				followCharOffset = false;
				followCharOffsetBttn.text = 'Follow: OFF';
			}
			else
			{
				followCharOffset = true;
				followCharOffsetBttn.text = 'Follow: ON';
			}
		});

		characterSelectBttn = new FlxButton(10, 30, "Change", function()
		{
			openSubState(new CharacterSelectorSubstate(false));
		});

		ghostSelectBttn = new FlxButton(10, characterSelectBttn.y + 40, "Change", function()
		{
			openSubState(new CharacterSelectorSubstate(true));
		});

		tab_group.add(resetBttn);
		tab_group.add(showGhostBttn);
		tab_group.add(followCharOffsetBttn);

		tab_group.add(ghostSelTextField);
		tab_group.add(ghostSelectBttn);
		tab_group.add(characterSelTextField);
		tab_group.add(characterSelectBttn);

		characterSelTextField.setPosition(characterSelectBttn.x, characterSelectBttn.y - 18);
		ghostSelTextField.setPosition(ghostSelectBttn.x, ghostSelectBttn.y - 18);

		UI_box.addGroup(tab_group);
	}

	function addTextUI()
	{
		characterSelTextField = new FlxText(0, 0, 0, 'Character: $curCharacter');
		add(characterSelTextField);

		ghostSelTextField = new FlxText(0, 0, 0, 'Ghost: $curGhost');
		add(ghostSelTextField);
	}

	override function update(elapsed:Float)
	{
		MusicBeatState.camBeat = camHUD;
		textAnim.text = (char.animation.curAnim.name != null ? char.animation.curAnim.name : '');
		ghost.flipX = char.flipX;

		characterSelTextField.text = 'Character: $curCharacter';
		ghostSelTextField.text = 'Ghost: $curGhost';

		ghost.visible = showGhost;
		char.alpha = (ghost.visible ? 0.85 : 1);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.mouse.visible = false;
			if (fromPlayState)
				Main.switchState(this, new states.PlayState());
			else
				Main.switchState(this, new states.menus.MainMenu());
		}

		if (FlxG.keys.justPressed.BACKSPACE)
		{
			FlxG.mouse.visible = false;
			Main.switchState(this, new states.menus.FreeplayMenu());
		}

		// camera controls
		if (FlxG.keys.justPressed.R)
		{
			FlxG.camera.zoom = 1;
		}

		if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3)
		{
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
			if (FlxG.camera.zoom > 3)
				FlxG.camera.zoom = 3;
		}
		if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1)
		{
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
			if (FlxG.camera.zoom < 0.1)
				FlxG.camera.zoom = 0.1;
		}

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
		{
			var addToCam:Float = 500 * elapsed;
			if (FlxG.keys.pressed.SHIFT)
				addToCam *= 4;

			if (FlxG.keys.pressed.I)
				camFollow.y -= addToCam;
			else if (FlxG.keys.pressed.K)
				camFollow.y += addToCam;

			if (FlxG.keys.pressed.J)
				camFollow.x -= addToCam;
			else if (FlxG.keys.pressed.L)
				camFollow.x += addToCam;
		}

		// character controls
		if (FlxG.keys.justPressed.F)
		{
			char.flipX = !char.flipX;
		}

		if (FlxG.keys.justPressed.W)
			updateAnimation(-1);
		if (FlxG.keys.justPressed.S)
			updateAnimation(1);

		if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
		{
			char.playAnim(animList[curAnim]);
		}

		if (check_offset.checked && char.animation.curAnim != null)
		{
			var holdingCtrl = FlxG.keys.pressed.CONTROL;
			var controlArray:Array<Bool> = [
				(holdingCtrl ? FlxG.keys.justPressed.LEFT : FlxG.keys.pressed.LEFT),
				(holdingCtrl ? FlxG.keys.justPressed.RIGHT : FlxG.keys.pressed.RIGHT),
				(holdingCtrl ? FlxG.keys.justPressed.UP : FlxG.keys.pressed.UP),
				(holdingCtrl ? FlxG.keys.justPressed.DOWN : FlxG.keys.pressed.DOWN),
			];

			for (i in 0...controlArray.length)
			{
				if (controlArray[i])
				{
					var holdShift = FlxG.keys.pressed.SHIFT;
					var multiplier = 1;
					if (holdShift)
						multiplier = 10;

					var arrayVal = 0;
					if (i > 1)
						arrayVal = 1;

					var negaMult:Int = 1;
					if (i % 2 == 1)
						negaMult = -1;
					if (char.animOffsets.get(animList[curAnim]) != null)
						char.animOffsets.get(animList[curAnim])[arrayVal] += negaMult * multiplier;

					updateTexts();
					genCharOffsets(false);
					char.playAnim(animList[curAnim], false);
					if (ghost.animation.curAnim != null
						&& char.animation.curAnim != null
						&& char.animation.curAnim.name == ghost.animation.curAnim.name)
					{
						ghost.playAnim(char.animation.curAnim.name, false);
					}
				}
			}
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
			saveCharOffsets();

		if (followCharOffset)
			ghost.setPosition(char.x, char.y);

		super.update(elapsed);
	}

	function updateAnimation(hey:Int)
	{
		curAnim += hey;

		if (curAnim < 0)
			curAnim = animList.length - 1;
		if (curAnim >= animList.length)
			curAnim = 0;
	}

	public function generateCharacter(isDad:Bool = true)
	{
		var genOffset:Array<Int> = [100, 100];

		if (!isDad)
			genOffset = [770, 450];

		if (curCharacter.startsWith('gf'))
			genOffset = [300, 100];

		if (char != null)
			remove(char);
		char = new Character(!isDad);
		char.setCharacter(genOffset[0], genOffset[1], curCharacter);
		char.debugMode = true;
		add(char);

		#if DISCORD_RPC
		Discord.changePresence('OFFSET EDITOR', 'Editing: ' + curCharacter);
		#end
	}

	public function generateGhost(isDad:Bool = true)
	{
		var genOffset:Array<Int> = [100, 100];

		if (!isDad)
			genOffset = [770, 450];

		if (curGhost.startsWith('gf'))
			genOffset = [300, 100];

		if (ghost != null)
			remove(ghost);
		ghost = new Character(!isDad);
		ghost.setCharacter(genOffset[0], genOffset[1], curGhost);
		ghost.debugMode = true;
		ghost.visible = false;
		ghost.color = 0xFF666688;
		add(ghost);
	}

	public function genCharOffsets(pushList:Bool = true, pushGhostList:Bool = true):Void
	{
		var daLoop:Int = 0;

		var i:Int = dumbTexts.members.length - 1;
		while (i >= 0)
		{
			var memb:FlxText = dumbTexts.members[i];
			if (memb != null)
			{
				memb.kill();
				dumbTexts.remove(memb);
				memb.destroy();
			}
			--i;
		}
		dumbTexts.clear();

		for (anim => offsets in char.animOffsets)
		{
			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, anim + ": " + offsets, 15);
			text.setFormat(Paths.font('vcr'), 18, FlxColor.WHITE);
			text.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
			text.scrollFactor.set();
			text.cameras = [camHUD];
			dumbTexts.add(text);

			if (!animList.contains(anim) && pushList)
				animList.push(anim);

			if (!ghostAnimList.contains(anim) && pushGhostList)
				ghostAnimList.push(anim);

			daLoop++;
		}

		textAnim.visible = true;
		if (dumbTexts.length < 1)
		{
			animList = ['[ERROR]'];

			var characterErrorFormat:String = '';

			switch (char.characterOrigin)
			{
				case UNDERSCORE:
					characterErrorFormat = 'ERROR! No animations found on Script
					\nmake sure the offsets exist on said script
					\nTry: addOffset(\'animationName\', xPosition, yPosition);';
				case PSYCH_ENGINE | SUPER_ENGINE | FUNKIN_COCOA:
					characterErrorFormat = 'ERROR! No animations found';
			}

			var text:FlxText = new FlxText(10, 38, 0, characterErrorFormat, 15);
			text.setFormat(Paths.font('vcr'), 18, FlxColor.WHITE);
			text.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
			text.scrollFactor.set();
			text.color = FlxColor.RED;
			text.cameras = [camHUD];
			dumbTexts.add(text);

			textAnim.visible = false;
		}
	}

	function saveCharOffsets():Void
	{
		var result = "function loadAnimations() {\n";
		var defaultAnimation = 'idle';
		var animXml = 'idle';

		/*
			result +=
			'
			   	addByPrefix("$anim", "$animXml");
			  	addOffset("$anim", ${offsets.join(", ")});
			';
		 */

		for (anim => offsets in char.animOffsets)
		{
			result += 'addOffset("$anim", ${offsets.join(", ")});\n';
			if (anim == 'danceRight' || anim == 'idle' || anim == 'firstDeath')
				defaultAnimation = anim;
		}
		result += 'playAnim("$defaultAnimation");';
		result += "\n}";

		if ((result != null) && (result != "function loadAnimations(){}"))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(result.trim(), curCharacter + ".hx");
		}
	}

	/**
	 * Called when the save file dialog is completed.
	 */
	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved OFFSET DATA.");
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
	 * Called if there is an error while saving the offset data.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Offset data");
	}

	function updateTexts():Void
	{
		dumbTexts.forEach(function(text:FlxText)
		{
			text.kill();
			dumbTexts.remove(text, true);
		});
	}
}

/*
	this stinks but whatever.
 */
class CharacterSelectorSubstate extends MusicBeatSubstate
{
	static var curSelected:Int = 0;

	var grpChars:FlxTypedGroup<Alphabet>;

	var characters:Array<String> = [];
	var existingCharacters:Array<String> = [];
	var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;

	public var isGhost:Bool = false;

	public function new(isGhost:Bool)
	{
		super();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		this.isGhost = isGhost;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		for (i in CoolUtil.returnAssetsLibrary('characters', ''))
		{
			if (!existingCharacters.contains(i.toLowerCase()) && !i.endsWith('-dead'))
				characters.push(i);
		}

		grpChars = new FlxTypedGroup<Alphabet>();
		add(grpChars);

		for (i in 0...characters.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, CoolUtil.swapSpaceDash(characters[i]), true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpChars.add(songText);

			var icon:HealthIcon = new HealthIcon(characters[i]);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
		}
		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;

		if (characters.length > 1)
		{
			if (upP)
				changeSelection(-1);
			if (downP)
				changeSelection(1);
			if (FlxG.mouse.wheel != 0)
				changeSelection(-1 * FlxG.mouse.wheel);
		}

		if (controls.ACCEPT || FlxG.mouse.justPressed)
		{
			var editorInstance = CharacterOffsetEditor.instance;
			var daSelected = grpChars.members[curSelected].text;

			if (!isGhost)
			{
				editorInstance.curCharacter = daSelected;
				editorInstance.generateCharacter(!daSelected.startsWith('bf') || !daSelected.endsWith('-player'));
				editorInstance.genCharOffsets(true, false);
			}
			else
			{
				editorInstance.curGhost = daSelected;
				editorInstance.generateGhost(!daSelected.startsWith('bf') || !daSelected.endsWith('-player'));
				editorInstance.genCharOffsets(false, true);
			}

			close();
		}

		if (controls.BACK || FlxG.mouse.justPressedRight)
			close();
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = characters.length - 1;
		if (curSelected >= characters.length)
			curSelected = 0;

		for (i in 0...iconArray.length)
			iconArray[i].alpha = 0.6;

		iconArray[curSelected].alpha = 1;

		var bullShit:Int = 0;

		for (item in grpChars.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}
	}
}
