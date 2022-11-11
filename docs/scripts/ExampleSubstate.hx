package;

var subBG:FlxSprite;
var text:FlxText;

function postCreate()
{
	trace('Initialized Base Script');
}

function update(elapsed:Float)
{
	if (FlxG.keys.justPressed.U)
	{
		game.paused = true;
		openSubState(new ScriptedSubstate('example'));
	}
}

function newSubstate(name:String = 'test')
{
	switch (name)
	{
		case 'test':
			subBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
			subBG.scrollFactor.set();
			subBG.alpha = 0;
			subBG.cameras = [PlayState.strumHUD];
			add(subBG);

			text = new FlxText(0, 0, 0, 'This is\nan Example\nCustom Substate\nusing hscript!', 64);
			text.screenCenter(FlxAxes.X, FlxAxes.Y);
			text.scrollFactor.set();
			text.cameras = [PlayState.strumHUD];
			add(text);

			FlxTween.tween(subBG, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		case 'test2':
			subBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
			subBG.scrollFactor.set();
			subBG.alpha = 0;
			subBG.cameras = [PlayState.strumHUD];
			add(subBG);

			text = new FlxText(0, 0, 0, 'This is\na second substate\ncreated using hscript!', 64);
			text.screenCenter(FlxAxes.X, FlxAxes.Y);
			text.scrollFactor.set();
			text.cameras = [PlayState.strumHUD];
			add(text);

			FlxTween.tween(subBG, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
	}
}

function substateCreate()
{
	// the create function for this substate
}

function substatePostCreate()
{
	trace('Post Create on Scripted Substate.');
}

function substateUpdate(elapsed:Float)
{
	// trace('Custom Substate Update.');

	if (FlxG.keys.justPressed.ESCAPE)
	{
		close();
	}
}

function substatePostUpdate(elapsed:Float)
{
	// trace('Post Custom Substate Update.');
}

function substateDestroy()
{
	trace('Custom Substate Destroyed.');
	game.remove(subBG);
	game.remove(text);
	game.paused = false;
}
