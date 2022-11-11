package states.substates;

import base.Conductor;
import base.MusicBeat.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.Character;
import states.*;
import states.menus.*;

class GameOverSubstate extends MusicBeatSubstate
{
	public var bf:Character;
	public var camFollow:FlxObject;

	var deathSong:FlxSound;
	var tankNoise:FlxSound;
	var confirmNoise:FlxSound;

	public static var character:String = 'bf-dead';
	public static var deathMusic:String = 'gameOver';
	public static var deathSound:String = 'fnf_loss_sfx';
	public static var deathConfirm:String = 'gameOverEnd';
	public static var deathBPM:Int = 100;

	public static var contents:GameOverSubstate;

	public static function resetGameOver()
	{
		character = 'bf-dead';
		deathMusic = 'gameOver';
		deathSound = 'fnf_loss_sfx';
		deathConfirm = 'gameOverEnd';
		deathBPM = 100;
	}

	override function create()
	{
		contents = this;
		PlayState.contents.callFunc('gameOverBegins', []);
		super.create();
	}

	public function new(x:Float, y:Float)
	{
		super();

		PlayState.contents.callFunc('gameOverPost', []);

		Conductor.songPosition = 0;

		// precache song
		deathSong = new FlxSound().loadEmbedded(Paths.music(deathMusic), false, true);
		deathSong.volume = (PlayState.SONG.stage == 'military' ? 0.2 : 1);
		FlxG.sound.list.add(deathSong);

		if (PlayState.SONG.stage == 'military')
		{
			// precache tankman sound
			tankNoise = new FlxSound().loadEmbedded(Paths.sound('jeff/jeffGameover-' + FlxG.random.int(1, 25)), false, true);
			FlxG.sound.list.add(tankNoise);
		}

		// precache confirm sound
		confirmNoise = new FlxSound().loadEmbedded(Paths.music(deathConfirm), false, true);
		FlxG.sound.list.add(confirmNoise);

		bf = new Character(true);
		bf.setCharacter(0, 0, character);
		bf.setPosition(x, y);
		add(bf);

		PlayState.boyfriend.destroy();

		camFollow = new FlxObject(bf.getGraphicMidpoint().x + 20, bf.getGraphicMidpoint().y - 20, 1, 1);
		add(camFollow);

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		bf.playAnim('firstDeath');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.contents.callFunc('update', [elapsed]);

		if (controls.ACCEPT)
			endBullshit(false);

		if (controls.BACK)
		{
			PlayState.deaths = 0;
			PlayState.chartingMode = false;

			endBullshit(true);
		}

		if (bf.animation.curAnim.name == 'firstDeath')
		{
			if (bf.animation.curAnim.curFrame == 12)
			{
				FlxG.camera.follow(camFollow, LOCKON, 0.01);
			}

			if (bf.animation.curAnim.finished)
			{
				if (!bf.debugMode)
					bf.playAnim('deathLoop');
				deathSong.play(false);
				Conductor.changeBPM(deathBPM);
				deathSong.persist = true;
				deathSong.looped = true;
			}
		}

		if (PlayState.SONG.stage == 'military')
		{
			if (bf.animation.curAnim.name == 'deathLoop')
			{
				tankNoise.play(false);
				tankNoise.onComplete = function()
				{
					if (!isEnding)
						deathSong.fadeIn(4, 0.2, 1);
				}
			}
		}
		PlayState.contents.callFunc('postUpdate', [elapsed]);

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
	}

	var isEnding:Bool = false;

	function endBullshit(leaving:Bool):Void
	{
		if (!isEnding)
		{
			deathSong.stop();
			if (tankNoise != null && tankNoise.playing)
				tankNoise.stop();

			if (!leaving)
			{
				isEnding = true;
				bf.playAnim('deathConfirm', true);
				confirmNoise.play(false);
				new FlxTimer().start(0.9, function(tmr:FlxTimer)
				{
					FlxG.camera.fade(FlxColor.BLACK, 0.7, false, function()
					{
						Main.switchState(this, new PlayState());
					});
				});
				PlayState.contents.callFunc('gameOverEnd', [true]);
			}
			else
			{
				FlxG.camera.fade(FlxColor.BLACK, 0.4, false, function()
				{
					if (PlayState.isStoryMode)
						Main.switchState(this, new StoryMenu());
					else
						Main.switchState(this, new FreeplayMenu());
				});
			}
		}
	}
}
