package funkin.userInterface.menu;

import dependency.FNFSprite;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import funkin.Alphabet;

class Selector extends FlxTypedSpriteGroup<FlxSprite>
{
	var leftSelector:FNFSprite;
	var rightSelector:FNFSprite;

	var optionChosen:Alphabet;

	public var name(default, null):String;
	public var chosenOptionString(default, set):String;
	public var isNumber(default, null):Bool;
	public var options:Array<String>;

	public var stringFormat:String = ''; // shows up at the end of the selector name;

	public function set_chosenOptionString(newOption:String)
	{
		chosenOptionString = newOption;
		isNumber = Std.parseInt(newOption) != null;
		if (optionChosen != null)
		{
			optionChosen.isBold = !isNumber;
			optionChosen.text = newOption;
		}
		return newOption;
	}

	public function new(x:Float = 0, y:Float = 0, name:String, options:Array<String>)
	{
		super(x, y);

		this.name = name;
		this.options = options;

		leftSelector = createSelector('left');
		rightSelector = createSelector('right');

		add(leftSelector);
		add(rightSelector);

		optionChosen = new Alphabet();
		add(optionChosen);

		chosenOptionString = Std.string(Init.getSetting(name) + stringFormat);
	}

	static function createSelector(dir:String):FNFSprite
	{
		var returnSelector = new FNFSprite();
		returnSelector.frames = Paths.getSparrowAtlas('menus/base/storymenu/campaign_menu_UI_assets');

		returnSelector.animation.addByPrefix('idle', 'arrow $dir', 24, false);
		returnSelector.animation.addByPrefix('press', 'arrow push $dir', 24, false);
		returnSelector.setGraphicSize(Std.int(returnSelector.width * 0.8));
		returnSelector.addOffset('press', 0, -10);
		returnSelector.playAnim('idle');

		return returnSelector;
	}

	public function selectorPlay(whichSelector:String, animPlayed:String = 'idle')
	{
		switch (whichSelector)
		{
			case 'left':
				leftSelector.playAnim(animPlayed);
			case 'right':
				rightSelector.playAnim(animPlayed);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// oops magic numbers
		var shiftX:Int = 48;
		var shiftOption:Int = 20;

		leftSelector.x = x + shiftX;
		leftSelector.y = y + 35;

		rightSelector.x = leftSelector.x + name.length * 50 + shiftX / 4;
		rightSelector.y = leftSelector.y;

		// i kinda fixed that one visual bug lol -stilic
		optionChosen.x = rightSelector.x + rightSelector.width + shiftX / 2;
		optionChosen.y = leftSelector.y + (isNumber ? shiftOption : shiftOption / 2);
	}
}
