package funkin.userInterface;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import sys.FileSystem;

using StringTools;

class HealthIcon extends FlxSprite
{
	// rewrite using da new icon system as ninjamuffin would say it
	public var sprTracker:FlxSprite;
	public var initialWidth:Float = 0;
	public var initialHeight:Float = 0;

	public var icon:String = 'bf';
	public var suffix:String = '';

	// script values
	public var canBounce:Bool = true;
	public var scaleFactorX:Float = 1.2;
	public var scaleFactorY:Float = 1.2;
	public var easeValue:String = 'expoOut';

	public function new(icon:String = 'bf', isPlayer:Bool = false)
	{
		super();
		updateIcon(icon, isPlayer);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	// dynamic, to avoid having 31 billion if statements;
	public dynamic function updateAnim(health:Float)
	{
		if (health < 20 && animation.getByName('losing') != null)
			animation.play('losing');
		else if (health > 85 && animation.getByName('winning') != null)
			animation.play('winning');
		else
			animation.play('static');
	}

	var bounceTween:FlxTween;

	public function bop(time:Float)
	{
		if (!canBounce)
			return;

		scale.set(scaleFactorX, scaleFactorY);
		if (bounceTween != null)
			bounceTween.cancel();
		bounceTween = FlxTween.tween(this.scale, {x: 1, y: 1}, time / base.Conductor.playbackRate, {ease: ForeverTools.returnTweenEase(easeValue)});
	}

	public function updateIcon(char:String = 'bf', isPlayer:Bool = false)
	{
		var trimmedChar:String = char;
		if (trimmedChar.contains('-'))
			trimmedChar = trimmedChar.substring(0, trimmedChar.indexOf('-'));

		var iconPath = char;
		if (!ForeverTools.fileExists('characters/$char/icon$suffix.png', IMAGE))
		{
			if (iconPath != trimmedChar)
				iconPath = trimmedChar;
			else
				iconPath = 'placeholder';
		}

		var iconGraphic:FlxGraphic = Paths.image('$iconPath/icon$suffix', 'characters');
		var iconWidth = 1;

		iconWidth = Std.int(iconGraphic.width / 150) - 1;
		iconWidth = iconWidth + 1;

		loadGraphic(iconGraphic);
		loadGraphic(iconGraphic, true, Std.int(iconGraphic.width / iconWidth), iconGraphic.height);

		animation.add('static', [0], 0, false, isPlayer);
		animation.add('losing', [1], 0, false, isPlayer);
		animation.add('winning', [2], 0, false, isPlayer);

		animation.play('static');

		scrollFactor.set();
		updateHitbox();

		initialWidth = width;
		initialHeight = height;

		antialiasing = (!icon.endsWith('-pixel') || !Init.getSetting('Disable Antialiasing'));
	}
}
