package states.substates;

import base.MusicBeat.MusicBeatSubstate;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.Note;
import funkin.Strumline.Receptor;

class NoteColorsSubstate extends MusicBeatSubstate
{
	public var notesGroup:FlxTypedGroup<Note>;

	public function new()
	{
		super();

		var bg = new FlxSprite(-85).loadGraphic(Paths.image('menus/base/menuDesat'));
		bg.scrollFactor.set(0, 0.18);
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = 0xCE64DF;
		bg.antialiasing = !Init.getSetting('Disable Antialiasing');
		add(bg);

		notesGroup = new FlxTypedGroup<Note>();
		add(notesGroup);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
			close();

		if (controls.BACK)
			close();
	}
}
