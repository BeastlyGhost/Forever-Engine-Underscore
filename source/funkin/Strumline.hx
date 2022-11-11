package funkin;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import states.PlayState;

using StringTools;

class Strumline extends FlxSpriteGroup
{
	public var receptors:FlxTypedSpriteGroup<Receptor>;
	public var splashNotes:FlxTypedSpriteGroup<NoteSplash>;
	public var notesGroup:FlxTypedSpriteGroup<Note>;
	public var holdsGroup:FlxTypedSpriteGroup<Note>;
	public var allNotes:FlxTypedSpriteGroup<Note>;

	public var character:Character;

	public var autoplay:Bool = true;
	public var downscroll:Bool = false;
	public var displayJudgements:Bool = false;
	public var doTween:Bool = false;

	public var keyAmount:Int = 4;
	public var xPos:Float = 0;
	public var yPos:Float = 0;

	public var receptorTexture:String = 'NOTE_assets';

	public function new(xPos:Float = 0, yPos:Float = 0, ?character:Character, ?receptorTexture:String, ?autoplay:Bool = true, ?displayJudgements:Bool = false,
			doTween:Bool = false, downscroll:Bool = false, ?keyAmount:Int = 4)
	{
		super();

		// initialize all groups;
		receptors = new FlxTypedSpriteGroup<Receptor>();
		splashNotes = new FlxTypedSpriteGroup<NoteSplash>();
		notesGroup = new FlxTypedSpriteGroup<Note>();
		holdsGroup = new FlxTypedSpriteGroup<Note>();
		allNotes = new FlxTypedSpriteGroup<Note>();

		// set the x and y positions;
		this.xPos = xPos;
		this.yPos = yPos;

		this.doTween = doTween;

		this.autoplay = autoplay;
		this.character = character;
		this.displayJudgements = displayJudgements;
		this.downscroll = downscroll;
		this.keyAmount = keyAmount;
		this.receptorTexture = receptorTexture;

		// regenerate the strumline;
		regenStrumline();
	}

	public function regenStrumline(?xNew:Float, ?yNew:Float, skipTween:Bool = false)
	{
		receptors.forEachAlive(function(receptor:Receptor)
		{
			receptor.destroy();
		});
		receptors.clear();

		splashNotes.forEachAlive(function(noteSplash:NoteSplash)
		{
			noteSplash.destroy();
		});
		splashNotes.clear();

		doTween = !skipTween;

		for (i in 0...keyAmount)
		{
			var receptor:Receptor = ForeverAssets.generateUIArrows(-20 + (xNew == null ? xPos : xNew), 25 + (yNew == null ? yPos : yNew), i, receptorTexture, PlayState.assetModifier);
			receptor.ID = i;

			receptor.x -= ((keyAmount / 2) * Receptor.swagWidth);
			receptor.x += (Receptor.swagWidth * i);
			receptors.add(receptor);

			receptor.initialX = Math.floor(receptor.x);
			receptor.initialY = Math.floor(receptor.y);
			receptor.angleTo = 0;
			receptor.y -= 10;
			receptor.playAnim('static');

			if (doTween)
			{
				receptor.alpha = 0;
				FlxTween.tween(receptor, {y: receptor.initialY, alpha: receptor.setAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				receptor.y = receptor.initialY;
				receptor.alpha = receptor.setAlpha;
			}

			if (displayJudgements)
			{
				var noteSplash:NoteSplash = ForeverAssets.generateNoteSplashes('noteSplashes', splashNotes, PlayState.assetModifier, 'noteskins/notes', i);
				splashNotes.add(noteSplash);
			}
		}

		if (Init.trueSettings.get("Clip Style").toLowerCase() == 'stepmania')
			add(holdsGroup);
		add(receptors);
		if (Init.trueSettings.get("Clip Style").toLowerCase() == 'fnf')
			add(holdsGroup);
		add(notesGroup);
		if (splashNotes != null)
			add(splashNotes);
	}

	public function createSplash(coolNote:Note)
	{
		// play animation in existing notesplashes
		var noteSplashRandom:String = (Std.string((FlxG.random.int(0, 1) + 1)));
		if (ForeverAssets.splashJson != null && ForeverAssets.splashJson.hasTwoAnims)
			splashNotes.members[coolNote.noteData].playAnim('anim' + noteSplashRandom);
		else
			splashNotes.members[coolNote.noteData].playAnim('anim1');
	}

	public function push(newNote:Note)
	{
		var chosenGroup = (newNote.isSustain ? holdsGroup : notesGroup);
		chosenGroup.add(newNote);
		allNotes.add(newNote);
		chosenGroup.sort(FlxSort.byY, (!downscroll) ? FlxSort.DESCENDING : FlxSort.ASCENDING);
	}
}

class Receptor extends FlxSprite
{
	/*  Oh hey, just gonna port this code from the previous Skater engine 
		(depending on the release of this you might not have it cus I might rewrite skater to use this engine instead)
		It's basically just code from the game itself but
		it's in a separate class and I also added the ability to set offsets for the arrows.

		uh hey you're cute ;)
	 */
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var noteData:Int = 0;

	public static var swagWidth:Float = 160 * 0.7;

	public var initialX:Int;
	public var initialY:Int;

	public var xTo:Float;
	public var yTo:Float;
	public var angleTo:Float;

	public var setAlpha:Float = Init.getSetting('Arrow Opacity') * 0.01;

	public var overrideAlpha:Bool = false;

	public var resetAnim:Float = 0;

	public static var actions:Array<String> = ['left', 'down', 'up', 'right'];
	public static var colors:Array<String> = ['purple', 'blue', 'green', 'red'];

	public function new(x:Float, y:Float, ?noteData:Int = 0)
	{
		// this extension is just going to rely a lot on preexisting code as I wanna try to write an extension before I do options and stuff
		super(x, y);
		animOffsets = new Map<String, Array<Dynamic>>();

		this.noteData = noteData;

		updateHitbox();
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (resetAnim > 0)
		{
			resetAnim -= elapsed;

			if (resetAnim < 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
	}

	// literally just character code
	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (!overrideAlpha)
			alpha = setAlpha;

		animation.play(AnimName, Force, Reversed, Frame);
		updateHitbox();

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
		animOffsets[name] = [x, y];
}
