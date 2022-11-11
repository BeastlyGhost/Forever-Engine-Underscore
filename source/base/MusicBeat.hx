package base;

import base.Conductor.BPMChangeEvent;
import dependency.FNFUIState;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.PlayerSettings;

/* 
	Music beat state happens to be the first thing on my list of things to add, it just so happens to be the backbone of
	most of the project in its entirety. It handles a couple of functions that have to do with actual music and songs and such.

	I'm not going to change any of this because I don't truly understand how songplaying works, 
	I mostly just wanted to rewrite the actual gameplay side of things.
 */
class MusicBeatState extends FNFUIState
{
	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	public var decStep:Float = 0;
	public var decBeat:Float = 0;

	public static var camBeat:FlxCamera;

	var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function destroy()
	{
		super.destroy();
	}

	// class create event
	override function create()
	{
		// dump
		if ((!Std.isOfType(this, states.PlayState)) && states.PlayState.clearStored)
			Paths.clearStoredMemory();

		if ((!Std.isOfType(this, states.PlayState)) && (!Std.isOfType(this, states.editors.OriginalChartEditor)))
			Paths.clearUnusedMemory();

		camBeat = FlxG.camera;

		super.create();

		// For debugging
		FlxG.watch.add(Conductor, "songPosition");
		FlxG.watch.add(this, "curBeat");
		FlxG.watch.add(this, "curStep");
	}

	// class 'step' event
	override function update(elapsed:Float)
	{
		updateContents();

		super.update(elapsed);
	}

	public function updateContents()
	{
		updateCurStep();
		updateBeat();

		// delta time bullshit
		var trueStep:Int = curStep;
		for (i in storedSteps)
			if (i < oldStep)
				storedSteps.remove(i);
		for (i in oldStep...trueStep)
		{
			if (!storedSteps.contains(i) && i > 0)
			{
				curStep = i;
				stepHit();
				skippedSteps.push(i);
			}
		}
		if (skippedSteps.length > 0)
			skippedSteps = [];
		curStep = trueStep;

		if (oldStep != curStep && curStep > 0 && !storedSteps.contains(curStep))
			stepHit();
		oldStep = curStep;
	}

	var oldStep:Int = 0;
	var storedSteps:Array<Int> = [];
	var skippedSteps:Array<Int> = [];

	public function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		decBeat = decStep / 4;
	}

	public function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		decStep = lastChange.stepTime + (Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet;
		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();

		if (!storedSteps.contains(curStep))
			storedSteps.push(curStep);
	}

	public function beatHit():Void
	{
	}

	var textField:FlxText;
	var fieldTween:FlxTween;

	public function logTrace(input:String, duration:Float, traceOnConsole:Bool = true, cam:FlxCamera)
	{
		if (traceOnConsole)
			trace(input);
		if (textField != null)
		{
			var oldField:FlxText = cast textField;
			FlxTween.tween(oldField, {alpha: 0}, 0.2, {
				onComplete: function(twn:FlxTween)
				{
					remove(oldField);
					oldField.destroy();
				}
			});
			textField = null;
		}

		if (fieldTween != null)
		{
			fieldTween.cancel();
			fieldTween = null;
		}

		if (input != '' && duration > 0)
		{
			textField = new FlxText(0, 0, FlxG.width, input);
			textField.setFormat(Paths.font("vcr"), 32, 0xFFFFFFFF, CENTER);
			textField.setBorderStyle(OUTLINE, 0xFF000000, 2);
			textField.alpha = 0;
			textField.screenCenter(X);
			textField.cameras = [cam];
			add(textField);

			fieldTween = FlxTween.tween(textField, {alpha: 1}, 0.2, {
				onComplete: function(twn:FlxTween)
				{
					fieldTween = FlxTween.tween(textField, {alpha: 0}, 0.2, {
						startDelay: duration,
						onComplete: function(twn:FlxTween)
						{
							remove(textField);
							textField.destroy();
							textField = null;
							if (fieldTween == twn)
								fieldTween = null;
						}
					});
				}
			});
		}
	}
}

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}

	var curStep:Int = 0;
	var curBeat:Int = 0;

	var decStep:Float = 0;
	var decBeat:Float = 0;

	var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function update(elapsed:Float)
	{
		// everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		super.update(elapsed);
	}

	function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		decStep = lastChange.stepTime + ((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	function updateBeat()
	{
		curBeat = Math.floor(curStep / 4);
		decBeat = decStep / 4;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
	}
}
