package funkin;

/**
	The character class initialises any and all characters that exist within gameplay. For now, the character class will
	stay the same as it was in the original source of the game. I'll most likely make some changes afterwards though!
**/
import base.*;
import base.SongLoader.LegacySection;
import base.SongLoader.Song;
import dependency.FNFSprite;
import flixel.FlxG;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxPoint;
import flixel.util.FlxSort;
import funkin.background.TankmenBG;
import funkin.compatibility.PsychChar;
import haxe.Json;
import states.PlayState;
import states.substates.GameOverSubstate;
import sys.io.File;

using StringTools;

enum abstract CharacterOrigin(String) to String
{
	var UNDERSCORE;
	var PSYCH_ENGINE;
	var SUPER_ENGINE;
	var FUNKIN_COCOA;
}

typedef CharacterData =
{
	var offsetX:Float;
	var offsetY:Float;
	var camOffsetX:Float;
	var camOffsetY:Float;
	var icon:String;
	var noteSkin:String;
	var singDuration:Float;
	var antialiasing:Bool;
	var quickDancer:Bool;
	var barColor:Array<Float>;
}

class Character extends FNFSprite
{
	public var curCharacter:String = 'bf';

	public var holdTimer:Float = 0;

	public var animationNotes:Array<Dynamic> = [];
	public var idlePos:Array<Float> = [0, 0];

	public var characterData:CharacterData;

	public var debugMode:Bool = false;
	public var isPlayer:Bool = false;
	public var quickDancer:Bool = false;

	public var hasMissAnims:Bool = false;

	public var characterScripts:Array<ScriptHandler> = [];

	public var idleSuffix:String = '';

	public var stunned:Bool = false; // whether the Character is dead or not

	public var bopSpeed:Int = 2;

	// FOR PSYCH COMPATIBILITY
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;
	public var specialAnim:Bool = false;
	public var heyTimer:Float = 0;

	public var characterType:String = UNDERSCORE;
	public var characterOrigin:CharacterOrigin;

	public var missSect:Array<String> = ['singLEFTmiss', 'singDOWNmiss', 'singUPmiss', 'singRIGHTmiss'];

	public function new(?isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
	}

	public function setCharacter(xPos:Float, yPos:Float, character:String):Character
	{
		curCharacter = character;

		characterData = {
			offsetY: 0,
			offsetX: 0,
			camOffsetY: 0,
			camOffsetX: 0,
			singDuration: 4,
			icon: null,
			quickDancer: false,
			noteSkin: "NOTE_assets",
			antialiasing: !character.endsWith('-pixel'),
			barColor: [161, 161, 161]
		};

		switch (character)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
		}

		if (ForeverTools.fileExists('characters/$character/' + character + '.json'))
			characterType = PSYCH_ENGINE;

		switch (character)
		{
			default:
				try
				{
					if (characterType == PSYCH_ENGINE)
						generatePsychChar(character);
					else
						generateBaseChar(character);
				}
				catch (e)
				{
					trace('Character Error: $character is invalid!');
					generatePlaceholder();
				}
		}

		if (characterData.icon == null)
			characterData.icon = character;

		for (missAnim in missSect)
		{
			if (animOffsets.exists(missAnim))
				hasMissAnims = true;
		}

		if (isPlayer) // reverse player flip
		{
			flipX = !flipX;

			// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf') && (!curCharacter.endsWith('-dead')))
				flipLeftRight();
			//
		}
		else if (curCharacter.startsWith('bf') && (!curCharacter.endsWith('-dead')))
			flipLeftRight();

		antialiasing = characterData.antialiasing;

		recalcDance();
		dance();

		setPosition(x, y);

		return this;
	}

	public function adjustPosition()
	{
		x += characterData.offsetX;
		y += (characterData.offsetY - (frameHeight * scale.y));
	}

	function flipLeftRight()
	{
		// get the old right sprite
		var oldRight = animation.getByName('singRIGHT').frames;

		// set the right to the left
		animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;

		// set the left to the old right
		animation.getByName('singLEFT').frames = oldRight;

		// insert ninjamuffin screaming I think idk I'm lazy as hell

		if (animation.getByName('singRIGHTmiss') != null)
		{
			var oldMiss = animation.getByName('singRIGHTmiss').frames;
			animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
			animation.getByName('singLEFTmiss').frames = oldMiss;
		}
	}

	override function update(elapsed:Float)
	{
		if (characterScripts != null)
		{
			for (i in characterScripts)
				i.call('update', [elapsed]);
		}

		/**
		 * Special Animations Code.
		 * @author: Shadow_Mario_
		**/

		if (!debugMode && animation.curAnim != null)
		{
			if (heyTimer > 0)
			{
				heyTimer -= elapsed * Conductor.playbackRate;
				if (heyTimer <= 0)
				{
					if (specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			}
			else if (specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

			switch (curCharacter)
			{
				case 'pico-speaker':
					if (animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
					{
						var noteData:Int = 1;
						if (animationNotes[0][1] > 2)
							noteData = 3;

						noteData += FlxG.random.int(0, 1);
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}
					if (animation.curAnim.finished)
						playAnim(animation.curAnim.name, false, false, animation.curAnim.frames.length - 3);
			}

			if (!skipDance && !specialAnim && !debugMode)
			{
				if (!isPlayer)
				{
					if (animation.curAnim.name.startsWith('sing'))
						holdTimer += elapsed;
					if (holdTimer >= Conductor.stepCrochet * (0.0011 / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1)) * characterData.singDuration)
					{
						holdTimer = 0;
						dance();
					}
				}
				else
				{
					if (animation.curAnim.name.startsWith('sing'))
						holdTimer += elapsed;
					else
						holdTimer = 0;
				}
			}

			if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished)
				dance();

			if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
				playAnim('danceRight');
			if ((animation.curAnim.name.startsWith('sad')) && (animation.curAnim.finished))
				playAnim('danceLeft');

			if (animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
			{
				playAnim(animation.curAnim.name + '-loop');
			}

			if (animation.curAnim.finished && animation.curAnim.name == 'idle')
			{
				if (animation.getByName('idlePost') != null)
					animation.play('idlePost', true, false, 0);
			}
		}

		super.update(elapsed);

		if (characterScripts != null)
		{
			for (i in characterScripts)
				i.call('postUpdate', [elapsed]);
		}
	}

	var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(?forced:Bool = false)
	{
		if (!debugMode)
		{
			if (!skipDance && !specialAnim && animation.curAnim != null)
			{
				if (danceIdle)
				{
					danced = !danced;
					if (danced)
						playAnim('danceRight$idleSuffix', forced);
					else
						playAnim('danceLeft$idleSuffix', forced);
				}
				else
					playAnim('idle$idleSuffix', forced);
			}
		}
	}

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (animation.getByName(AnimName) != null)
			super.playAnim(AnimName, Force, Reversed, Frame);

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
				danced = true;
			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	function loadMappedAnims()
	{
		var sections:Array<LegacySection> = Song.loadSong('picospeaker', PlayState.SONG.song.toLowerCase()).notes;
		for (section in sections)
		{
			for (note in section.sectionNotes)
			{
				animationNotes.push(note);
			}
		}
		animationNotes.sort(function(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
		{
			return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
		});
		TankmenBG.animationNotes = animationNotes;
	}

	private var settingCharacterUp:Bool = true;

	/**
	 * mostly used for Psych Engine Characters;
	 * @author Shadow_Mario_
	**/
	public function recalcDance()
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if (settingCharacterUp)
		{
			bopSpeed = (danceIdle ? 1 : 2);
		}
		else if (lastDanceIdle != danceIdle)
		{
			var calc:Float = bopSpeed;
			if (danceIdle)
				calc /= 2;
			else
				calc *= 2;

			bopSpeed = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	/**
	 * [Generates a Character in the Forever Engine Underscore Format]
	 * @param char returns the character that should be generated
	 */
	function generateBaseChar(char:String = 'bf')
	{
		var pushedScripts:Array<String> = [];
		var paths:Array<String> = ['characters/$char/config', 'characters/$char/config'];

		for (i in paths)
		{
			for (j in Paths.scriptExts)
			{
				if (j != null)
				{
					if (ForeverTools.fileExists(i + '.$j') && !pushedScripts.contains(i + '.$j'))
					{
						var script:ScriptHandler = new ScriptHandler(Paths.getPath(i + '.$j', TEXT));

						if (script.interp == null)
						{
							trace("Something terrible occured! Skipping.");
							continue;
						}

						characterScripts.push(script);
						pushedScripts.push(i + '.$j');
					}
				}
			}
		}

		var tex:FlxFramesCollection;

		var spriteType = "SparrowAtlas";

		if (ForeverTools.fileExists('characters/$char/$char.txt', TEXT))
			spriteType = "PackerAtlas";
		else
			spriteType = "SparrowAtlas";

		switch (spriteType)
		{
			case "PackerAtlas":
				tex = Paths.getPackerAtlas(char, 'characters/$char');
			default:
				tex = Paths.getSparrowAtlas(char, 'characters/$char');
		}

		frames = tex;

		// trace(interp, script);
		setVar('addByPrefix', function(name:String, prefix:String, ?frames:Int = 24, ?loop:Bool = false)
		{
			animation.addByPrefix(name, prefix, frames, loop);
		});

		setVar('addByIndices', function(name:String, prefix:String, indices:Array<Int>, ?frames:Int = 24, ?loop:Bool = false)
		{
			animation.addByIndices(name, prefix, indices, "", frames, loop);
		});

		setVar('addOffset', function(?name:String = "idle", ?x:Float = 0, ?y:Float = 0)
		{
			addOffset(name, x, y);
			if (name == 'idle')
				idlePos = [x, y];
		});

		setVar('set', function(name:String, value:Dynamic)
		{
			Reflect.setProperty(this, name, value);
		});

		setVar('setSingDuration', function(amount:Int)
		{
			characterData.singDuration = amount;
		});

		setVar('setOffsets', function(x:Float = 0, y:Float = 0)
		{
			characterData.offsetX = x;
			characterData.offsetY = y;
		});

		setVar('setCamOffsets', function(x:Float = 0, y:Float = 0)
		{
			characterData.camOffsetX = x;
			characterData.camOffsetY = y;
		});

		setVar('setScale', function(?x:Float = 1, ?y:Float = 1)
		{
			scale.set(x, y);
		});

		setVar('setIcon', function(swag:String = 'face') characterData.icon = swag);

		setVar('quickDancer', function(quick:Bool = false)
		{
			characterData.quickDancer = quick;
		});

		setVar('setBarColor', function(rgb:Array<Float>)
		{
			if (characterData.barColor != null)
				characterData.barColor = rgb;
			else
				characterData.barColor = [161, 161, 161];
			return true;
		});

		setVar('setDeathChar',
			function(char:String = 'bf-dead', lossSfx:String = 'fnf_loss_sfx', song:String = 'gameOver', confirmSound:String = 'gameOverEnd', bpm:Int)
			{
				GameOverSubstate.character = char;
				GameOverSubstate.deathSound = lossSfx;
				GameOverSubstate.deathMusic = song;
				GameOverSubstate.deathConfirm = confirmSound;
				GameOverSubstate.deathBPM = bpm;
			});

		setVar('get', function(variable:String)
		{
			return Reflect.getProperty(this, variable);
		});

		setVar('setGraphicSize', function(width:Int = 0, height:Int = 0)
		{
			setGraphicSize(width, height);
			updateHitbox();
		});

		setVar('playAnim', function(name:String, ?force:Bool = false, ?reversed:Bool = false, ?frames:Int = 0)
		{
			playAnim(name, force, reversed, frames);
		});

		setVar('isPlayer', isPlayer);
		setVar('characterData', characterData);
		if (PlayState.SONG != null)
			setVar('songName', PlayState.SONG.song.toLowerCase());
		setVar('flipLeftRight', flipLeftRight);

		if (characterScripts != null)
		{
			for (i in characterScripts)
				i.call('loadAnimations', []);
		}

		if (animation.getByName('danceLeft') != null)
			playAnim('danceLeft');
		else
			playAnim('idle');
	}

	public function setVar(key:String, value:Dynamic)
	{
		var allSucceed:Bool = true;
		if (characterScripts != null)
		{
			for (i in characterScripts)
			{
				i.set(key, value);

				if (!i.exists(key))
				{
					trace('${i.scriptFile} failed to set $key for its interpreter, continuing.');
					allSucceed = false;
					continue;
				}
			}
		}
		return allSucceed;
	}

	public function noteHit(dunceNote:funkin.Note)
	{
		if (characterScripts != null)
		{
			for (i in characterScripts)
				i.call('noteHit', [dunceNote]);
		}
	}

	public var psychAnimationsArray:Array<PsychAnimArray> = [];

	/**
	 * [Generates a Character in the Psych Engine Format, as a Compatibility Layer for them]
	 * [@author Shadow_Mario_]
	 * @param char returns the character that should be generated
	 */
	function generatePsychChar(char:String = 'bf')
	{
		var rawJson = File.getContent(Paths.getPath('characters/$char/' + char + '.json'));

		var json:PsychEngineChar = cast Json.parse(rawJson);

		var tex:FlxFramesCollection;

		var spriteType:String = "SparrowAtlas";
		var characterPath:String = 'characters/$char/' + json.image.replace('characters/', '');

		if (ForeverTools.fileExists('$characterPath.txt', TEXT))
			spriteType = "PackerAtlas";
		else
			spriteType = "SparrowAtlas";

		switch (spriteType)
		{
			case "PackerAtlas":
				tex = Paths.getPackerAtlas(json.image.replace('characters/', ''), 'characters/$char');
			default:
				tex = Paths.getSparrowAtlas(json.image.replace('characters/', ''), 'characters/$char');
		}

		frames = tex;

		psychAnimationsArray = json.animations;
		for (anim in psychAnimationsArray)
		{
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; // Bruh
			var animIndices:Array<Int> = anim.indices;
			if (animIndices != null && animIndices.length > 0)
				animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
			else
				animation.addByPrefix(animAnim, animName, animFps, animLoop);

			if (anim.offsets != null && anim.offsets.length > 1)
				addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
		}
		flipX = json.flip_x;

		// characterData.icon = json.healthicon;
		characterData.antialiasing = !json.no_antialiasing;
		characterData.barColor = json.healthbar_colors;
		characterData.singDuration = json.sing_duration;

		if (json.scale != 1)
		{
			setGraphicSize(Std.int(width * json.scale));
			updateHitbox();
		}

		if (animation.getByName('danceLeft') != null)
			playAnim('danceLeft');
		else
			playAnim('idle');

		characterData.offsetX = json.position[0];
		characterData.offsetY = json.position[1];
		characterData.camOffsetX = json.camera_position[0];
		characterData.camOffsetY = json.camera_position[1];
	}

	function generatePlaceholder()
	{
		frames = Paths.getSparrowAtlas('placeholder', 'characters/placeholder');

		animation.addByPrefix('idle', 'Idle', 24, false);
		animation.addByPrefix('singLEFT', 'Left', 24, false);
		animation.addByPrefix('singDOWN', 'Down', 24, false);
		animation.addByPrefix('singUP', 'Up', 24, false);
		animation.addByPrefix('singRIGHT', 'Right', 24, false);

		if (!isPlayer)
		{
			addOffset("idle", 0, -350);
			addOffset("singLEFT", 22, -353);
			addOffset("singDOWN", 17, -375);
			addOffset("singUP", 8, -334);
			addOffset("singRIGHT", 50, -348);
			characterData.camOffsetX = 30;
			characterData.camOffsetY = 330;
		}
		else
		{
			addOffset("idle", 0, -10);
			addOffset("singLEFT", 33, -6);
			addOffset("singDOWN", -48, -31);
			addOffset("singUP", -45, 11);
			addOffset("singRIGHT", -61, -14);
			characterData.camOffsetY = -5;
		}

		playAnim('idle');
		characterData.barColor = [161, 161, 161];
		characterData.offsetY = 350;
		curCharacter = 'placeholder';
	}
}
