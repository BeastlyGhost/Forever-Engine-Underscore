function generateStage()
{
	// create stage graphics, just haxe code!

	var bg:FNFSprite = new FNFSprite(-600, -200).loadGraphic(Paths.image('stageback', stageDir));
	bg.antialiasing = true;
	bg.scrollFactor.set(0.9, 0.9);
	bg.active = false;
	add(bg);

	var stageFront:FNFSprite = new FNFSprite(-650, 600).loadGraphic(Paths.image('stagefront', stageDir));
	stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
	stageFront.updateHitbox();
	stageFront.antialiasing = true;
	stageFront.scrollFactor.set(0.9, 0.9);
	stageFront.active = false;
	add(stageFront);

	var stageCurtains:FNFSprite = new FNFSprite(-500, -300).loadGraphic(Paths.image('stagecurtains', stageDir));
	stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
	stageCurtains.updateHitbox();
	stageCurtains.antialiasing = true;
	stageCurtains.scrollFactor.set(1.3, 1.3);
	stageCurtains.active = false;
	add(stageCurtains);
}

function repositionPlayers(boyfriend, dad, gf)
{
	// function used to reposition players;
}

function updateStage(curBeat:Int, boyfriend:Character, gf:Character, dad:Character)
{
	// similar to beatHit, this function is used for stage updates *on beats*;
}

function updateStageSteps(curStep:Int, boyfriend:Character, gf:Character, dad:Character)
{
	// similar to stepHit, this function is used for stage updates *on steps*;
}

function updateStageConst(elapsed:Float, boyfriend:Character, gf:Character, dad:Character)
{
	// constant stage updates, similar to the update function;
}

function dadPosition(boyfriend:Character, gf:Character, dad:Character, camPos:FlxPoint)
{
	// used for adding special parameters on stages, e.g: Spirit Trail, Hide Girlfriend on Tutorial;
}
