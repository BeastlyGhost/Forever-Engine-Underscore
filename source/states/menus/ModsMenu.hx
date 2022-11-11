package states.menus;

import base.MusicBeat.MusicBeatState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.Alphabet;
import sys.FileSystem;

using StringTools;

class ModsMenu extends MusicBeatState
{
	var alphaGroup:FlxTypedGroup<Alphabet>;
	var modList:Array<String> = [];

	var bg:FlxSprite;

	override function create()
	{
		super.create();

		// make sure there's nothing on the mod list
		modList = [];

		// make sure the music is playing
		ForeverTools.resetMenuMusic();

		bg = new FlxSprite(-80).loadGraphic(Paths.image('menus/base/menuDesat'));
		bg.scrollFactor.set(0, 0.18);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = 0xCE64DF;
		bg.antialiasing = !Init.getSetting('Disable Antialiasing');
		add(bg);

		try
		{
			for (mod in ModManager.getModFolders())
				modList.push(mod);
		}
		catch (e)
		{
			lime.app.Application.current.window.alert('Sorry, a fatal error has occurred!', "Fatal Error!");
		}

		alphaGroup = new FlxTypedGroup<Alphabet>();
		add(alphaGroup);

		for (i in 0...modList.length)
		{
			var blah:Alphabet = new Alphabet(0, 0, modList[i], true, false);
			blah.screenCenter();
			blah.y += (80 * (i - Math.floor(modList[i].length / 2)));
			blah.y += 10;
			blah.targetY = i;
			blah.disableX = true;
			blah.isMenuItem = true;
			blah.alpha = 0.6;
			alphaGroup.add(blah);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.BACK)
			Main.switchState(this, new states.menus.MainMenu());
	}
}
