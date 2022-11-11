var bgGirls:FNFSprite;
var bgTrees:FNFSprite;
var treeLeaves:FNFSprite;

function generateStage()
{
	var stageDir:String = 'stages/school/images';

	var bgSky:FNFSprite = new FNFSprite().loadGraphic(Paths.image('weebSky', stageDir));
	bgSky.scrollFactor.set(0.1, 0.1);
	add(bgSky);

	var bgSchool:FNFSprite = new FNFSprite(-200, 0).loadGraphic(Paths.image('weebSchool', stageDir));
	bgSchool.scrollFactor.set(0.6, 0.90);
	add(bgSchool);

	var bgStreet:FNFSprite = new FNFSprite(-200).loadGraphic(Paths.image('weebStreet', stageDir));
	bgStreet.scrollFactor.set(0.95, 0.95);
	add(bgStreet);

	var fgTrees:FNFSprite = new FNFSprite(-200 + 170, 130).loadGraphic(Paths.image('weebTreesBack', stageDir));
	fgTrees.scrollFactor.set(0.9, 0.9);
	add(fgTrees);

	bgTrees = new FNFSprite(-200 - 380, -800);
	bgTrees.frames = Paths.getPackerAtlas('weebTrees', stageDir);
	bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
	bgTrees.animation.play('treeLoop');
	bgTrees.scrollFactor.set(0.85, 0.85);
	add(bgTrees);

	treeLeaves = new FNFSprite(-200, -40);
	treeLeaves.frames = Paths.getSparrowAtlas('petals', stageDir);
	treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
	treeLeaves.animation.play('leaves');
	treeLeaves.scrollFactor.set(0.85, 0.85);
	add(treeLeaves);

	bgGirls = new FNFSprite(-100, 190);
	bgGirls.frames = Paths.getSparrowAtlas('bgFreaks', stageDir);
	girlsState(PlayState.SONG.song.toLowerCase() == 'roses' ? true : false);
	bgGirls.animation.play('danceLeft');
	bgGirls.scrollFactor.set(0.9, 0.9);
	bgGirls.setGraphicSize(Std.int(bgGirls.width * PlayState.daPixelZoom));
	bgGirls.updateHitbox();
	add(bgGirls);

	bgSky.setGraphicSize(Std.int(bgSky.width * 6));
	bgSchool.setGraphicSize(Std.int(bgSky.width * 6));
	bgStreet.setGraphicSize(Std.int(bgSky.width * 6));
	bgTrees.setGraphicSize(Std.int(Std.int(bgSky.width * 6) * 1.4));
	fgTrees.setGraphicSize(Std.int(Std.int(bgSky.width * 6) * 0.8));
	treeLeaves.setGraphicSize(Std.int(bgSky.width * 6));

	bgSky.updateHitbox();
	bgSchool.updateHitbox();
	bgStreet.updateHitbox();
	bgTrees.updateHitbox();
	treeLeaves.updateHitbox();
	fgTrees.updateHitbox();
}

var danceDir:Bool = false;

function girlsDance()
{
	danceDir = !danceDir;

	if (bgGirls != null)
	{
		if (danceDir)
			bgGirls.animation.play('danceRight', true);
		else
			bgGirls.animation.play('danceLeft', true);
	}
}

function girlsState(scared:Bool = false)
{
	if (scared)
	{
		bgGirls.animation.addByIndices('danceLeft', 'BG fangirls dissuaded', CoolUtil.numberArray(14), "", 24, false);
		bgGirls.animation.addByIndices('danceRight', 'BG fangirls dissuaded', CoolUtil.numberArray(30, 15), "", 24, false);
	}
	else
	{
		bgGirls.animation.addByIndices('danceLeft', 'BG girls group', CoolUtil.numberArray(14), "", 24, false);
		bgGirls.animation.addByIndices('danceRight', 'BG girls group', CoolUtil.numberArray(30, 15), "", 24, false);
	}
	girlsDance();
}

function updateStage(curBeat:Int, boyfriend:Character, gf:Character, dad:Character)
{
	girlsDance();
}
