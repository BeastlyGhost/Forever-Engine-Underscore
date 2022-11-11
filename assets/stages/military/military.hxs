var smokeL:FNFSprite;
var smokeR:FNFSprite;
var tankWatchtower:FNFSprite;
var tankGround:FNFSprite;
var tankmanRun:FlxSpriteGroup;
var tankdude0:FNFSprite;
var tankdude1:FNFSprite;
var tankdude2:FNFSprite;
var tankdude3:FNFSprite;
var tankdude4:FNFSprite;
var tankdude5:FNFSprite;
var groupDudes:FlxSpriteGroup;
var tankResetShit:Bool = false;
var tankMoving:Bool = false;
var tankAngle:Float = FlxG.random.int(-90, 45);
var tankSpeed:Float = FlxG.random.float(5, 7);
var tankX:Float = 400;

function moveTank()
{
	tankAngle += tankSpeed * FlxG.elapsed;
	if (tankGround != null)
	{
		tankGround.angle = (tankAngle - 90 + 15);
		tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
		tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
	}
}

function generateStage()
{
	var stageDir:String = 'stages/military/images';

	var sky:FNFSprite = new FNFSprite(-400, -400).loadGraphic(Paths.image('tankSky', stageDir));
	sky.scrollFactor.set(0, 0);
	add(sky);

	var tankCloudX:Int;
	var tankCloudY:Int;

	tankCloudX = FlxG.random.int(-700, -100);
	tankCloudY = FlxG.random.int(-20, 20);

	var clouds:FNFSprite = new FNFSprite(tankCloudX, tankCloudY).loadGraphic(Paths.image('tankClouds', stageDir));
	clouds.scrollFactor.set(0.1, 0.1);
	clouds.active = true;
	clouds.velocity.x = FlxG.random.float(5, 15);
	add(clouds);

	var mountains:FNFSprite = new FNFSprite(300, -20).loadGraphic(Paths.image('tankMountains', stageDir));
	mountains.scrollFactor.set(0.2, 0.2);
	mountains.setGraphicSize(Std.int(mountains.width * 1.2));
	mountains.updateHitbox();
	add(mountains);

	var buildings:FNFSprite = new FNFSprite(-200, 0).loadGraphic(Paths.image('tankBuildings', stageDir));
	buildings.scrollFactor.set(0.3, 0.3);
	buildings.setGraphicSize(Std.int(buildings.width * 1.1));
	buildings.updateHitbox();
	add(buildings);

	var ruins:FNFSprite = new FNFSprite(-200, 0).loadGraphic(Paths.image('tankRuins', stageDir));
	ruins.scrollFactor.set(0.35, 0.35);
	ruins.setGraphicSize(Std.int(ruins.width * 1.1));
	ruins.updateHitbox();
	add(ruins);

	smokeL = new FNFSprite(-200, -100);
	smokeL.frames = Paths.getSparrowAtlas('smokeLeft', stageDir);
	smokeL.animation.addByPrefix('smokeLeft', 'SmokeBlurLeft');
	smokeL.antialiasing = !Init.getSetting('Disable Antialiasing');
	smokeL.scrollFactor.set(0.4, 0.4);
	add(smokeL);

	smokeR = new FNFSprite(1100, -100);
	smokeR.frames = Paths.getSparrowAtlas('smokeRight', stageDir);
	smokeR.animation.addByPrefix('smokeRight', 'SmokeRight');
	smokeR.antialiasing = !Init.getSetting('Disable Antialiasing');
	smokeR.scrollFactor.set(0.4, 0.4);
	add(smokeR);

	tankWatchtower = new FNFSprite(100, 50);
	tankWatchtower.frames = Paths.getSparrowAtlas('tankWatchtower', stageDir);
	tankWatchtower.animation.addByPrefix('watchtower', 'watchtower gradient color');
	tankWatchtower.antialiasing = !Init.getSetting('Disable Antialiasing');
	tankWatchtower.scrollFactor.set(0.5, 0.5);
	add(tankWatchtower);

	tankGround = new FNFSprite(300, 300);
	tankGround.frames = Paths.getSparrowAtlas('tankRolling', stageDir);
	tankGround.animation.addByPrefix('bgTank', 'BG tank w lighting');
	tankGround.antialiasing = !Init.getSetting('Disable Antialiasing');
	tankGround.scrollFactor.set(0.5, 0.5);
	add(tankGround);

	tankmanRun = new FlxSpriteGroup();
	add(tankmanRun);

	var ground:FNFSprite = new FNFSprite(-420, -150).loadGraphic(Paths.image('tankGround', stageDir));
	ground.setGraphicSize(Std.int(ground.width * 1.15));
	ground.updateHitbox();
	add(ground);
	moveTank();

	groupDudes = new FlxSpriteGroup();

	tankdude0 = new FNFSprite(-500, 650);
	tankdude0.frames = Paths.getSparrowAtlas('tank0', stageDir);
	tankdude0.animation.addByPrefix('fg', 'fg');
	tankdude0.antialiasing = !Init.getSetting('Disable Antialiasing');
	tankdude0.scrollFactor.set(1.7, 1.5);
	groupDudes.add(tankdude0);

	tankdude1 = new FNFSprite(-300, 750);
	tankdude1.frames = Paths.getSparrowAtlas('tank1', stageDir);
	tankdude1.animation.addByPrefix('fg', 'fg');
	tankdude1.antialiasing = !Init.getSetting('Disable Antialiasing');
	tankdude1.scrollFactor.set(2, 0.2);
	groupDudes.add(tankdude1);

	tankdude2 = new FNFSprite(450, 750);
	tankdude2.frames = Paths.getSparrowAtlas('tank2', stageDir);
	tankdude2.animation.addByPrefix('fg', 'groupDudes');
	tankdude2.antialiasing = !Init.getSetting('Disable Antialiasing');
	tankdude2.scrollFactor.set(1.5, 1.5);
	groupDudes.add(tankdude2);

	tankdude4 = new FNFSprite(1300, 750);
	tankdude4.frames = Paths.getSparrowAtlas('tank4', stageDir);
	tankdude4.animation.addByPrefix('fg', 'fg');
	tankdude4.antialiasing = !Init.getSetting('Disable Antialiasing');
	tankdude4.scrollFactor.set(1.5, 1.5);
	groupDudes.add(tankdude4);

	tankdude5 = new FNFSprite(1620, 750);
	tankdude5.frames = Paths.getSparrowAtlas('tank5', stageDir);
	tankdude5.animation.addByPrefix('fg', 'fg');
	tankdude5.antialiasing = !Init.getSetting('Disable Antialiasing');
	tankdude5.scrollFactor.set(1.5, 1.5);
	groupDudes.add(tankdude5);

	tankdude3 = new FNFSprite(1300, 750);
	tankdude3.frames = Paths.getSparrowAtlas('tank3', stageDir);
	tankdude3.animation.addByPrefix('fg', 'fg');
	tankdude3.antialiasing = !Init.getSetting('Disable Antialiasing');
	tankdude3.scrollFactor.set(3.5, 2.5);
	groupDudes.add(tankdude3);

	foreground.add(groupDudes);

	if (gfVersion == 'pico-speaker')
	{
		var tankmen:TankmenBG = new TankmenBG(20, 500, true);
		tankmen.resetShit(20, 600, true);
		tankmen.strumTime = 10;
		tankmanRun.add(tankmen);

		if (tankmen != null)
		{
			for (i in 0...TankmenBG.animationNotes.length)
			{
				if (FlxG.random.bool(16))
				{
					var man:TankmenBG = tankmanRun.recycle(TankmenBG);
					man.strumTime = TankmenBG.animationNotes[i][0];
					man.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
					tankmanRun.add(man);
				}
			}
		}
	}
}

function repositionPlayers(boyfriend:Character, gf:Character, dad:Character)
{
	if (songName == 'stress')
		gf.y -= 150;
}

function updateStage(curBeat:Int, boyfriend:Character, gf:Character, dad:Character)
{
	if (smokeL != null)
		smokeL.playAnim('smokeLeft');
	if (smokeR != null)
		smokeR.playAnim('smokeRight');
	if (tankWatchtower != null)
		tankWatchtower.playAnim('watchtower');
	if (groupDudes != null)
	{
		for (i in 0...groupDudes.length)
		{
			if (groupDudes.members[i] != null)
				groupDudes.members[i].playAnim('fg');
		}
	}
}

function updateStageConst(elapsed:Float, boyfriend:Character, gf:Character, dad:Character)
{
	moveTank();
}
