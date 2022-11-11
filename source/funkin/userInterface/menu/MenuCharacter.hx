package funkin.userInterface.menu;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;
import lime.utils.Assets;
import sys.FileSystem;
import sys.io.File;

typedef WeekCharacterDef =
{
	var image:String;
	var scale:Float;
	var position:Array<Int>;
	var idleAnim:Array<Dynamic>;
	var heyAnim:Array<Dynamic>;
	var flipX:Bool;
}

class MenuCharacter extends FlxSprite
{
	public var character:String = '';
	public var charJson:WeekCharacterDef;

	var baseX:Float = 0;
	var baseY:Float = 0;

	public function new(x:Float, newCharacter:String = 'bf')
	{
		super(x);
		y += 70;

		baseX = x;
		baseY = y;

		createCharacter(newCharacter);
	}

	public function createCharacter(newCharacter:String = 'bf', canChange:Bool = false)
	{
		this.character = newCharacter;

		var rawJson = null;
		var path:String = Paths.getPreloadPath('images/menus/base/storymenu/characters/' + newCharacter + '.json');

		if (!FileSystem.exists(path))
			path = Paths.getPreloadPath('images/menus/base/storymenu/characters/none.json');
		rawJson = File.getContent(path);

		charJson = cast Json.parse(rawJson);

		var tex = Paths.getSparrowAtlas('menus/base/storymenu/characters/' + charJson.image);
		frames = tex;

		if (newCharacter != null || newCharacter != '')
		{
			if (!visible)
				visible = true;

			animation.addByPrefix('idle', charJson.idleAnim[0], charJson.idleAnim[1], charJson.idleAnim[2]);

			if (charJson.heyAnim != null)
				animation.addByPrefix('hey', charJson.heyAnim[0], charJson.heyAnim[1], charJson.heyAnim[2]);

			animation.play('idle');

			if (canChange)
			{
				setGraphicSize(Std.int(width * charJson.scale));
				setPosition(baseX + charJson.position[0], baseY + charJson.position[1]);
				updateHitbox();
			}

			flipX = charJson.flipX;
		}
		else
			visible = false;

		antialiasing = !Init.getSetting('Disable Antialiasing');
		character = newCharacter;
	}
}
