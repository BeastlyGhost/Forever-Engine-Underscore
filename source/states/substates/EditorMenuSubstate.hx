package states.substates;

import base.MusicBeat.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.Alphabet;
import sys.thread.Mutex;
import sys.thread.Thread;

/*
	Substate used to load engine editors
	e.g: Chart Editor, Character Offset Editor, etc
 */
class EditorMenuSubstate extends MusicBeatSubstate
{
	var alphabetGroup:FlxTypedGroup<Alphabet>;
	var optionsArray:Array<String> = ['Original Chart Editor', 'Character Offset Editor', 'Chart Editor'];
	var curSelected:Int = 0;

	var music:FlxSound;

	public static var fromPause:Bool = false;

	private var mutex:Mutex;

	var playState:Bool = false;

	var player:String = 'bf';

	public function new(playMusic:Bool = true, playState:Bool = false)
	{
		super();

		this.playState = playState;

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		if (PlayState.SONG != null)
			player = (PlayState.SONG.player2 != null ? PlayState.SONG.player2 : 'dad');

		if (playMusic)
		{
			mutex = new Mutex();
			Thread.create(function()
			{
				mutex.acquire();
				music = new FlxSound().loadEmbedded(Paths.music('menus/prototype/prototype'), true, true);
				music.volume = 0;
				music.play(false, FlxG.random.int(0, Std.int(music.length / 2)));
				FlxG.sound.list.add(music);
				mutex.release();
			});
		}

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		alphabetGroup = new FlxTypedGroup<Alphabet>();
		add(alphabetGroup);

		for (i in 0...optionsArray.length)
		{
			var option:Alphabet = new Alphabet(0, (70 * i) + 30, optionsArray[i], true, false);
			option.isMenuItem = true;
			option.disableX = true;
			option.targetY = i;
			alphabetGroup.add(option);
		}

		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (music != null && music.playing && music.volume < 0.5)
			music.volume += 0.01 * elapsed;

		if (controls.UI_UP_P)
		{
			changeSelection(-1);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if (controls.ACCEPT && !fromPause)
		{
			var daSelected:String = optionsArray[curSelected];
			base.Conductor.stopMusic();
			if (FlxG.sound.music.playing)
				FlxG.sound.music.stop();

			switch (daSelected)
			{
				case 'Original Chart Editor':
					PlayState.chartingMode = true;
					PlayState.preventScoring = true;
					PlayState.lastEditor = 0;
					Main.switchState(this, new states.editors.OriginalChartEditor());

				case 'Chart Editor':
					PlayState.chartingMode = true;
					PlayState.preventScoring = true;
					PlayState.lastEditor = 1;
					Main.switchState(this, new states.editors.ChartEditor());

				case 'Character Offset Editor':
					Main.switchState(this, new states.editors.CharacterOffsetEditor(player, false, playState));
			}
		}

		// unlock controls or something idk will change this later
		new FlxTimer().start(0.6, function(timer:FlxTimer)
		{
			if (fromPause)
				fromPause = false;
		}, 1);

		if (controls.BACK)
			close();
	}

	override function destroy()
	{
		if (music != null)
			music.destroy();
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length)
			curSelected = 0;

		var bullShit:Int = 0;
		for (item in alphabetGroup.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
}
