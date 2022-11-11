package states.substates;

import base.MusicBeat.MusicBeatSubstate;
import flixel.FlxG;

class ScriptedSubstate extends MusicBeatSubstate
{
	public static var stateName:Null<String>;
	public static var contents:ScriptedSubstate;

	override function create()
	{
		contents = this;

		PlayState.contents.callFunc('substateCreate', []);
		PlayState.contents.setVar('close', close);

		super.create();
		PlayState.contents.callFunc('substatePostCreate', []);
	}

	public function new(stateName:Null<String>)
	{
		ScriptedSubstate.stateName = stateName;
		PlayState.contents.callFunc('newSubstate', [stateName]);
		super();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		PlayState.contents.callFunc('substateUpdate', [stateName, elapsed]);
		super.update(elapsed);
		PlayState.contents.callFunc('substatePostUpdate', [stateName, elapsed]);
	}

	override function destroy()
	{
		PlayState.contents.callFunc('substateDestroy', [stateName]);
		super.destroy();
	}
}
