package funkin.userInterface;

import base.Conductor;
import base.CoolUtil;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import states.PlayState;

using StringTools;

class ClassHUD extends FlxTypedGroup<FlxBasic>
{
	// set up variables and stuff here
	public var scoreBar:FlxText;

	var scoreColorTween:FlxTween;

	public var cornerMark:FlxText; // engine mark at the upper right corner
	public var centerMark:FlxText; // song display name and difficulty at the center

	public var healthBarBG:FlxSprite;
	public var healthBar:FlxBar;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var infoDisplay:String = CoolUtil.dashToSpace(PlayState.SONG.song);
	public var diffDisplay:String = CoolUtil.difficultyFromString();
	public var engineDisplay:String = "F.E. UNDERSCORE v" + Main.engineVersion + (Main.nightly ? '-NIGHTLY' : '');

	public var autoplayMark:FlxText;
	public var autoplaySine:Float = 0;

	var timingsMap:Map<String, FlxText> = [];

	private var barFillDir = RIGHT_TO_LEFT;

	private final barPlayer = FlxColor.fromRGB(PlayState.boyfriend.characterData.barColor[0], PlayState.boyfriend.characterData.barColor[1],
		PlayState.boyfriend.characterData.barColor[2]);
	private final barEnemy = FlxColor.fromRGB(PlayState.dad.characterData.barColor[0], PlayState.dad.characterData.barColor[1],
		PlayState.dad.characterData.barColor[2]);

	public function new()
	{
		super();

		// le healthbar setup
		var barY = FlxG.height * 0.875;
		if (Init.getSetting('Downscroll'))
			barY = 64;

		healthBarBG = new FlxSprite(0, barY);
		healthBarBG.loadGraphic(Paths.image(ForeverTools.returnSkin('healthBar', PlayState.assetModifier, PlayState.uiModifier, 'UI')));

		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, barFillDir, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8));
		healthBar.scrollFactor.set();
		updateBar();

		// healthBar
		add(healthBar);

		iconP1 = new HealthIcon(PlayState.boyfriend.characterData.icon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(PlayState.dad.characterData.icon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		scoreBar = new FlxText(FlxG.width / 2, Math.floor(healthBarBG.y + 30), 0, '');
		scoreBar.setFormat(Paths.font('vcr'), 18, FlxColor.WHITE);
		scoreBar.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		scoreBar.antialiasing = !Init.getSetting('Disable Antialiasing');
		add(scoreBar);

		cornerMark = new FlxText(0, 0, 0, engineDisplay);
		cornerMark.setFormat(Paths.font('vcr'), 18, FlxColor.WHITE);
		cornerMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		cornerMark.setPosition(FlxG.width - (cornerMark.width + 5), 5);
		cornerMark.antialiasing = true;
		add(cornerMark);

		centerMark = new FlxText(0, (Init.getSetting('Downscroll') ? FlxG.height - 40 : 10), 0, '', 24);
		centerMark.setFormat(Paths.font('vcr'), 24, FlxColor.WHITE);
		centerMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		centerMark.antialiasing = !Init.getSetting('Disable Antialiasing');
		centerMark.screenCenter(X);
		if (Init.getSetting('Center Display') != 'Nothing')
			add(centerMark);

		if (Init.getSetting('Center Display') == 'Song Name')
			centerMark.text = '- $infoDisplay [$diffDisplay] -';
		else if (Init.getSetting('Center Display') == 'Song Time')
			centerMark.alpha = 0;

		centerMark.x = Math.floor((FlxG.width / 2) - (centerMark.width / 2));

		autoplayMark = new FlxText(-5, (Init.getSetting('Downscroll') ? centerMark.y - 60 : centerMark.y + 60), FlxG.width - 800, '[AUTOPLAY]\n', 32);
		autoplayMark.setFormat(Paths.font("vcr"), 32, FlxColor.WHITE, CENTER);
		autoplayMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		autoplayMark.screenCenter(X);
		autoplayMark.visible = PlayState.bfStrums.autoplay;

		// repositioning for it to not be covered by the receptors
		if (Init.getSetting('Centered Receptors'))
		{
			if (Init.getSetting('Downscroll'))
				autoplayMark.y = autoplayMark.y - 125;
			else
				autoplayMark.y = autoplayMark.y + 125;
		}

		add(autoplayMark);

		// counter
		if (Init.getSetting('Counter') != 'None')
		{
			var judgementNameArray:Array<String> = [];
			for (i in Timings.judgementsMap.keys())
				judgementNameArray.insert(Timings.judgementsMap.get(i)[0], i);
			judgementNameArray.sort(function(Obj1:String, Obj2:String):Int
			{
				return FlxSort.byValues(FlxSort.ASCENDING, Timings.judgementsMap.get(Obj1)[0], Timings.judgementsMap.get(Obj2)[0]);
			});
			for (i in 0...judgementNameArray.length)
			{
				var textAsset:FlxText = new FlxText(5
					+ (!left ? (FlxG.width - 10) : 0),
					(FlxG.height / 2)
					- (counterTextSize * (judgementNameArray.length / 2))
					+ (i * counterTextSize), 0, '', counterTextSize);
				if (!left)
					textAsset.x -= textAsset.text.length * counterTextSize;
				textAsset.setFormat(Paths.font(counterTextFont), counterTextSize, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				textAsset.scrollFactor.set();
				timingsMap.set(judgementNameArray[i], textAsset);
				add(textAsset);
			}
		}

		updateScoreText();
		updateBar();
	}

	public var counterTextSize:Int = 18;
	public var counterTextFont:String = 'vcr';

	var left = (Init.getSetting('Counter') == 'Left');

	override public function update(elapsed:Float)
	{
		// pain, this is like the 7th attempt
		healthBar.percent = (PlayState.health * 50);

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		iconP1.updateAnim(healthBar.percent);
		iconP2.updateAnim(100 - healthBar.percent);

		if (autoplayMark.visible)
		{
			autoplaySine += 180 * (elapsed / 4);
			autoplayMark.alpha = 1 - Math.sin((Math.PI * autoplaySine) / 80);
		}

		if (Init.getSetting('Center Display') == 'Song Time')
			updateTime();
	}

	private var divider:String = " • ";

	private var tempScore:String;

	public function updateScoreText()
	{
		var displayAccuracy = Init.getSetting('Display Accuracy');
		var unrated = (Timings.comboDisplay == null || Timings.comboDisplay == '');

		tempScore = 'Score: ${PlayState.songScore}'
			+ (displayAccuracy ? divider + 'Accuracy: ${Std.string(Math.floor(Timings.getAccuracy() * 100) / 100)}%' : '')
			+ (displayAccuracy ? !unrated ? ' [' + Timings.comboDisplay + divider + Timings.returnScoreRating() + ']' : ' [' + Timings.returnScoreRating() + ']' : '')
			+ (displayAccuracy ? divider + 'Combo Breaks: ${PlayState.misses}' : '')
			+ '\n';

		scoreBar.text = tempScore;
		scoreBar.x = Math.floor((FlxG.width / 2) - (scoreBar.width / 2));

		// update counter
		if (Init.getSetting('Counter') != 'None')
		{
			for (i in timingsMap.keys())
			{
				timingsMap[i].text = '${(i.charAt(0).toUpperCase() + i.substring(1, i.length))}: ${Timings.gottenJudgements.get(i)}';
				timingsMap[i].x = (5 + (!left ? (FlxG.width - 10) : 0) - (!left ? (6 * counterTextSize) : 0));
			}
		}

		// update playstate
		PlayState.detailsSub = scoreBar.text;
		PlayState.updateRPC(false);
	}

	public function updateBar()
	{
		if (Init.getSetting('Colored Health Bar'))
			healthBar.createFilledBar(barEnemy, barPlayer);
		else
			healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		healthBar.scrollFactor.set();
		healthBar.updateBar();
	}

	public function updateTime()
	{
		var currentTime = flixel.util.FlxStringUtil.formatTime(Math.floor(Conductor.songPosition / 1000), false);
		var songLength = flixel.util.FlxStringUtil.formatTime(Math.floor((PlayState.songLength) / 1000), false);
		centerMark.text = '- [$currentTime / $songLength] -';

		// *center* the thing, will you?
		centerMark.x = Math.floor((FlxG.width / 2) - (centerMark.width / 2));
	}

	public function beatHit(curBeat:Int)
	{
		if (!Init.getSetting('Reduced Movements'))
		{
			iconP1.bop(60 / Conductor.bpm);
			iconP2.bop(60 / Conductor.bpm);
		}
	}

	public function tweenScoreColor(rating:String, perfect:Bool)
	{
		if (Init.getSetting('Animated Score Color'))
		{
			if (scoreColorTween != null)
				scoreColorTween.cancel();

			var judgeColors:Map<String, FlxColor> = [
				'sick' => FlxColor.CYAN,
				'good' => FlxColor.LIME,
				'bad' => FlxColor.ORANGE,
				'shit' => FlxColor.PURPLE,
				'miss' => FlxColor.RED,
			];

			var color:FlxColor = FlxColor.WHITE;
			for (judge => judgeColor in judgeColors)
			{
				if (judge == 'sick' && perfect)
					judgeColor = FlxColor.fromString('#F8D482'); // golden sicks;
				if (rating == judge)
					color = judgeColor;
			}

			scoreColorTween = FlxTween.color(scoreBar, 0.1, scoreBar.color, color, {
				onComplete: function(twn:FlxTween)
				{
					FlxTween.color(scoreBar, 0.75, scoreBar.color, FlxColor.WHITE);
					scoreColorTween = null;
				}
			});
		}
	}
}
