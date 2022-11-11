package funkin.userInterface.menu;

import dependency.FNFSprite;

using StringTools;

class Checkmark extends FNFSprite
{
	public var parent:Alphabet;

	override public function update(elapsed:Float)
	{
		if (parent != null)
			setPosition(parent.x + parent.width + 10, parent.y - 35);

		if (animation != null)
		{
			if ((animation.finished) && (animation.curAnim.name == 'true'))
				playAnim('true finished');
			if ((animation.finished) && (animation.curAnim.name == 'false'))
				playAnim('false finished');
		}

		super.update(elapsed);
	}
}
