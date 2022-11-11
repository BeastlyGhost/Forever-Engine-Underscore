package funkin;

import base.*;
import dependency.FNFSprite;
import flixel.FlxG;
import funkin.Strumline.Receptor;
import states.PlayState;

using StringTools;

class Note extends FNFSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var noteAlt:Float = 0;
	public var noteType(default, set):Int = 0;

	public var noteString:String = '';
	public var noteSect:String = '';
	public var noteTimer:Float = 0;

	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustain:Bool = false;

	// offsets
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var lowPriority:Bool = false;
	public var hitboxLength:Float = 1;

	public var useCustomSpeed:Bool = Init.getSetting('Use Custom Note Speed');
	public var noteSpeed(default, set):Float;

	public function set_noteSpeed(value:Float):Float
	{
		if (noteSpeed != value)
		{
			noteSpeed = value;
			updateSustainScale();
		}
		return noteSpeed;
	}

	public var noteQuant:Int = -1;
	public var noteVisualOffset:Float = 0;
	public var noteDirection:Float = 0;

	public var parentNote:Note;
	public var childrenNotes:Array<Note> = [];

	// it has come to this.
	public var endHoldOffset:Float = Math.NEGATIVE_INFINITY;

	public var healthGain:Float = 0.023;
	public var healthLoss:Float = 0.0475;
	public var holdHeight:Float = 0.72;

	public var hitSounds:Bool = true;
	public var canHurt:Bool = false;
	public var cpuIgnore:Bool = false;
	public var gfNote:Bool = false;
	public var updateAccuracy:Bool = true;

	public var hitsoundSuffix = '';

	function resetNote(isGf:Bool = false)
	{
		hitSounds = true;
		updateAccuracy = true;
		cpuIgnore = false;
		canHurt = false;
		gfNote = isGf;
		lowPriority = false;
		noteString = '';
	}

	function set_noteType(type:Int):Int
	{
		switch (type)
		{
			case 1: // gf notes
				resetNote(true);
			case 2: // mines
				healthLoss = 0.065;
				updateAccuracy = true;
				hitSounds = false;
				cpuIgnore = true;
				canHurt = true;
				gfNote = false;
				lowPriority = true;
				noteString = 'miss';
			default: // anything else
				resetNote(false);
		}
		return type;
	}

	public function new(strumTime:Float, noteData:Int, noteAlt:Float, ?prevNote:Note, ?isSustain:Bool = false, ?noteType:Int = 0, ?noteString:String,
			?noteSect:String, ?noteTimer:Float = 0)
	{
		super(x, y);

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		this.noteType = noteType;
		this.noteString = noteString;
		this.noteSect = noteSect;
		this.noteTimer = noteTimer;
		this.isSustain = isSustain;

		if (noteType == null || noteType <= 0)
			noteType = 0;

		if (noteString == null)
			noteString = '';

		if (noteSect == null)
			noteSect = '';

		if (noteTimer == null || noteTimer <= 0)
			noteTimer = 0;

		// oh okay I know why this exists now
		y -= 2000;

		this.strumTime = strumTime;
		this.noteData = noteData;
		this.noteAlt = noteAlt;

		// determine parent note
		if (isSustain && prevNote != null)
		{
			parentNote = prevNote;
			if (parentNote.noteSect != null)
				this.noteSect = parentNote.noteSect;
			if (parentNote.noteString != null)
				this.noteString = parentNote.noteString;
			if (parentNote.noteTimer != 0)
				this.noteTimer = parentNote.noteTimer;
			while (parentNote.parentNote != null)
				parentNote = parentNote.parentNote;
			parentNote.childrenNotes.push(this);

			hitSounds = false;
		}
		else if (!isSustain)
			parentNote = null;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			if (strumTime > Conductor.songPosition - (Timings.msThreshold * hitboxLength)
				&& strumTime < Conductor.songPosition + (Timings.msThreshold * hitboxLength))
				canBeHit = true;
			else
				canBeHit = false;
		}
		else // make sure the note can't be hit if it's the dad's I guess
			canBeHit = false;

		if (tooLate || (parentNote != null && parentNote.tooLate))
			alpha = 0.3;
	}

	public function updateSustainScale()
	{
		if (isSustain)
		{
			if (prevNote != null && prevNote.exists)
			{
				if (prevNote.isSustain)
				{
					// listen I dont know what i was doing but I was onto something (-yoshubs)
					// yoshubs this literally works properly (-gabi)
					prevNote.scale.y = (prevNote.width / prevNote.frameWidth) * ((Conductor.stepCrochet / 100) * (1.07 / holdHeight)) * noteSpeed;
					prevNote.updateHitbox();
					offsetX = prevNote.offsetX;
				}
				else
					offsetX = ((prevNote.width / 2) - (width / 2));
			}
		}
	}

	public static function returnQuantNote(assetModifier:String, strumTime:Float, noteData:Int, noteAlt:Float, ?isSustain:Bool = false, ?prevNote:Note = null,
			?noteType:Int = 0):Note
	{
		var newNote:Note = new Note(strumTime, noteData, noteAlt, prevNote, isSustain, noteType);
		newNote.holdHeight = 0.862;

		// actually determine the quant of the note
		determineQuantIndex(strumTime, newNote);

		// note quants
		switch (assetModifier)
		{
			default:
				// inherit last quant if hold note
				if (isSustain && prevNote != null)
					newNote.noteQuant = prevNote.noteQuant;
				// base quant notes
				if (!isSustain)
				{
					switch (noteType)
					{
						case 2: // pixel mines
							if (assetModifier == 'pixel')
							{
								newNote.loadGraphic(Paths.image(ForeverTools.returnSkin('mines', assetModifier, '', 'noteskins/mines')), true, 17, 17);
								newNote.animation.add(Receptor.actions[noteData] + 'Scroll', [0, 1, 2, 3, 4, 5, 6, 7], 12);
							}
							else
							{
								newNote.loadGraphic(Paths.image(ForeverTools.returnSkin('mines', assetModifier, '', 'noteskins/mines')), true, 133, 128);
								newNote.animation.add(Receptor.actions[noteData] + 'Scroll', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 12);
							}

						default:
							// in case you're unfamiliar with these, they're ternary operators, I just dont wanna check for pixel notes using a separate statement
							var newNoteSize:Int = (assetModifier == 'pixel') ? 17 : 157;
							newNote.loadGraphic(Paths.image(ForeverTools.returnSkin('NOTE_quants', assetModifier, Init.getSetting("Note Skin"),
								'noteskins/notes', 'quant')),
								true, newNoteSize, newNoteSize);

							newNote.animation.add('leftScroll', [0 + (newNote.noteQuant * 4)]);
							// LOL downscroll thats so funny to me
							newNote.animation.add('downScroll', [1 + (newNote.noteQuant * 4)]);
							newNote.animation.add('upScroll', [2 + (newNote.noteQuant * 4)]);
							newNote.animation.add('rightScroll', [3 + (newNote.noteQuant * 4)]);
					}
				}
				else
				{
					switch (noteType)
					{
						case 2:
							newNote.kill();
						default:
							// quant holds
							newNote.loadGraphic(Paths.image(ForeverTools.returnSkin('HOLD_quants', assetModifier, Init.getSetting("Note Skin"),
								'noteskins/notes', 'quant')),
								true, (assetModifier == 'pixel') ? 17 : 109, (assetModifier == 'pixel') ? 6 : 52);
							newNote.animation.add('hold', [0 + (newNote.noteQuant * 4)]);
							newNote.animation.add('holdend', [1 + (newNote.noteQuant * 4)]);
							newNote.animation.add('roll', [2 + (newNote.noteQuant * 4)]);
							newNote.animation.add('rollend', [3 + (newNote.noteQuant * 4)]);
					}
				}

				var sizeThing = 0.7;
				if (noteType == 5)
					sizeThing = 0.8;

				if (assetModifier == 'pixel')
				{
					newNote.antialiasing = false;
					newNote.setGraphicSize(Std.int(newNote.width * PlayState.daPixelZoom));
					newNote.updateHitbox();
				}
				else
				{
					newNote.setGraphicSize(Std.int(newNote.width * sizeThing));
					newNote.updateHitbox();
					newNote.antialiasing = !Init.getSetting('Disable Antialiasing');
				}
		}

		if (!isSustain)
			newNote.animation.play(Receptor.actions[noteData] + 'Scroll');

		if (isSustain && prevNote != null)
		{
			newNote.noteSpeed = prevNote.noteSpeed;
			newNote.alpha = Init.getSetting('Hold Opacity') * 0.01;

			newNote.animation.play('holdend');
			newNote.updateHitbox();

			if (prevNote.isSustain)
			{
				prevNote.animation.play('hold');

				// prevNote.scale.y *= Conductor.stepCrochet / 100 * (43 / 52) * 1.5 * prevNote.noteSpeed;
				// prevNote.updateHitbox();
			}
		}

		return newNote;
	}

	public static function reloadNote(texture:String, changeable:String = '', assetModifier:String, newNote:Note)
	{
		var pixelNoteID:Array<Int> = [4, 5, 6, 7];

		if (texture.length < 2 || texture == null)
		{
			if (assetModifier == 'pixel')
			{
				if (newNote.isSustain)
					texture = 'arrowEnds';
				else
					texture = 'arrows-pixels';
			}
			else
				texture = 'NOTE_assets';
		}

		if (assetModifier != 'pixel')
		{
			newNote.frames = Paths.getSparrowAtlas(ForeverTools.returnSkin(texture, assetModifier, changeable, 'noteskins/notes'));

			newNote.animation.addByPrefix(Receptor.colors[newNote.noteData] + 'Scroll', Receptor.colors[newNote.noteData] + '0');
			newNote.animation.addByPrefix(Receptor.colors[newNote.noteData] + 'holdend', Receptor.colors[newNote.noteData] + ' hold end');
			newNote.animation.addByPrefix(Receptor.colors[newNote.noteData] + 'hold', Receptor.colors[newNote.noteData] + ' hold piece');

			newNote.animation.addByPrefix('purpleholdend', 'pruple end hold'); // PA god dammit.
		}
		else
		{
			if (newNote.isSustain)
			{
				newNote.loadGraphic(Paths.image(ForeverTools.returnSkin(texture, assetModifier, changeable, 'noteskins/notes')), true, 7, 6);
				newNote.animation.add(Receptor.colors[newNote.noteData] + 'holdend', [pixelNoteID[newNote.noteData]]);
				newNote.animation.add(Receptor.colors[newNote.noteData] + 'hold', [pixelNoteID[newNote.noteData] - 4]);
			}
			else
			{
				newNote.loadGraphic(Paths.image(ForeverTools.returnSkin(texture, assetModifier, changeable, 'noteskins/notes')), true, 17, 17);
				newNote.animation.add(Receptor.colors[newNote.noteData] + 'Scroll', [pixelNoteID[newNote.noteData]], 12);
			}
		}
	}

	/**
	 * Custom Note Functions (for when you hit a note), this should execute in PlayState;
	**/
	public function goodNoteHit(newNote:Note, ?ratingTiming:String)
	{
		var hitsound = Init.getSetting('Hitsound Type');
		switch (newNote.noteType)
		{
			case 2:
				PlayState.contents.decreaseCombo(true);
				PlayState.health -= healthLoss;
			default:
				if (newNote.hitSounds)
				{
					if (Init.getSetting('Hitsound Volume') > 0 && newNote.canBeHit)
						FlxG.sound.play(Paths.sound('hitsounds/$hitsound/hit$hitsoundSuffix'), Init.getSetting('Hitsound Volume'));
				}
		}
	}

	/**
	 * [Specify what to do when a note is missed];
	 */
	public function noteMissActions(?coolNote:Note)
	{
		switch (coolNote.noteType)
		{
			default:
				// do nothing;
		}
	}

	public static function determineQuantIndex(strumTime:Float, newNote:Note)
	{
		/*
			I have to credit like 3 different people for these LOL they were a hassle
			but its gede pixl and scarlett, thank you SO MUCH for baring with me
		 */
		final quantArray:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 192]; // different quants

		var songOffset:Float = 0;
		var curBPM:Float = Conductor.bpm;
		var newTime = strumTime;

		final beatTimeSeconds:Float = (60 / curBPM); // beat in seconds
		final beatTime:Float = beatTimeSeconds * 1000; // beat in milliseconds
		final measureTime:Float = beatTime * 4; // assumed 4 beats per measure?

		final smallestDeviation:Float = measureTime / quantArray[quantArray.length - 1];

		songOffset = (PlayState.SONG != null ? PlayState.SONG.offset : 0);

		if (newNote.noteQuant == -1)
		{
			for (i in 0...Conductor.bpmChangeMap.length)
			{
				if (strumTime > Conductor.bpmChangeMap[i].songTime)
				{
					curBPM = Conductor.bpmChangeMap[i].bpm;
					newTime = strumTime - Conductor.bpmChangeMap[i].songTime;
				}
			}

			for (quant in 0...quantArray.length)
			{
				// please generate this ahead of time and put into array :)
				// I dont think I will im scared of those
				final quantTime = (measureTime / quantArray[quant]);
				if ((newTime + songOffset #if !neko + Init.trueSettings['Offset'] #end + smallestDeviation) % quantTime < smallestDeviation * 2)
				{
					// here it is, the quant, finally!
					newNote.noteQuant = quant;
					break;
				}
			}
		}

		return quantArray.length - 1;
	}
}
