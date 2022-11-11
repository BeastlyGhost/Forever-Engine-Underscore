package base;

import base.*;
import dependency.*;
import flixel.*;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.effects.FlxTrail;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.*;
import flixel.system.*;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.scaleModes.StageSizeScaleMode;
import flixel.text.FlxText;
import flixel.tweens.*;
import flixel.ui.FlxBar;
import flixel.util.*;
import funkin.*;
import lime.app.Application;
import openfl.display.GraphicsShader;
import openfl.filters.ShaderFilter;
import states.PlayState;
import states.substates.ScriptedSubstate;
import sys.io.File;

using StringTools;

class ScriptHandler extends SScript
{
	public function new(file:String, ?preset:Bool = true)
	{
		super(file, preset);
		traces = false;
	}

	override public function preset():Void
	{
		super.preset();

		// will use import on scripts later so this won't be needed!

		set('FlxG', FlxG);
		set('FlxBasic', FlxBasic);
		set('FlxObject', FlxObject);
		set('FlxCamera', FlxCamera);
		set('FlxSprite', FlxSprite);
		set('FlxText', FlxText);
		set('FlxTextBorderStyle', FlxTextBorderStyle);
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		set('FlxSound', FlxSound);
		set('FlxTimer', FlxTimer);
		set('FlxTween', FlxTween);
		set('FlxEase', FlxEase);
		set('FlxMath', FlxMath);
		set('FlxSound', FlxSound);
		set('FlxGroup', FlxGroup);
		set('FlxTypedGroup', FlxTypedGroup);
		set('FlxSpriteGroup', FlxSpriteGroup);
		set('FlxTypedSpriteGroup', FlxTypedSpriteGroup);
		set('FlxStringUtil', FlxStringUtil);
		set('FlxAtlasFrames', FlxAtlasFrames);
		set('FlxSort', FlxSort);
		set('Application', Application);
		set('FlxGraphic', FlxGraphic);
		set('FlxAtlasFrames', FlxAtlasFrames);
		set('File', File);
		set('FlxTrail', FlxTrail);
		set('FlxShader', FlxShader);
		set('FlxBar', FlxBar);
		set('FlxBackdrop', FlxBackdrop);
		set('StageSizeScaleMode', StageSizeScaleMode);
		set('FlxBarFillDirection', FlxBarFillDirection);
		#if (flixel < "5.0.0")
		set('FlxAxes', FlxAxes);
		set('FlxPoint', FlxPoint);
		#end
		set('GraphicsShader', GraphicsShader);
		set('ShaderFilter', ShaderFilter);

		set('AtlasFrameMaker', dependency.textureatlas.AtlasFrameMaker);

		// CLASSES (FOREVER);
		set('Init', Init);
		set('ColorSwap', ColorSwap);
		set('ForeverAssets', ForeverAssets);
		set('ForeverTools', ForeverTools);
		set('FNFSprite', FNFSprite);
		set('Discord', Discord);
		set('ScriptedSubstate', ScriptedSubstate);

		// CLASSES (BASE);
		set('Alphabet', Alphabet);
		set('Character', Character);
		set('controls', Controls);
		set('CoolUtil', CoolUtil);
		set('Conductor', Conductor);
		set('PlayState', PlayState);
		set('Main', Main);
		set('Note', Note);
		set('Strumline', Strumline);
		set('Receptor', Strumline.Receptor);
		set('HealthIcon', funkin.userInterface.HealthIcon);
		set('Paths', Paths);
		set('Stage', Stage);
		set('Timings', Timings);

		set('getVarFromClass', function(instance:String, variable:String)
		{
			Reflect.field(Type.resolveClass(instance), variable);
		});
	}
}
