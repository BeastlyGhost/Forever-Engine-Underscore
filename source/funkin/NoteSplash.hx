package funkin;

import dependency.FNFSprite;

/**
	Create the note splashes in week 7 whenever you get a sick!
**/
class NoteSplash extends FNFSprite
{
	public var noteData:Int;

	public function new(noteData:Int)
	{
		super(x, y);

		this.noteData = noteData;

		alpha = 0.000001;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// kill the note splash if it's done
		if (animation != null && animation.finished)
		{
			// set the splash to invisible
			if (alpha != 0.000001)
				alpha = 0.000001;
		}
	}

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		// make sure the animation is visible
		if (ForeverAssets.splashJson.overrideSettings)
		{
			if (ForeverAssets.splashJson.splashAlpha >= 0)
				alpha = ForeverAssets.splashJson.splashAlpha;
		}
		else
		{
			if (Init.getSetting('Splash Opacity') >= 0)
				alpha = Init.getSetting('Splash Opacity') * 0.01;
		}

		super.playAnim(AnimName, Force, Reversed, Frame);
	}
}
