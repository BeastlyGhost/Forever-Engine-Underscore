package funkin;

import funkin.*;
import states.PlayState;

/**
	Here's a class that calculates timings and judgements for the songs and such
**/
class Timings
{
	//
	public static var accuracy:Float;
	public static var trueAccuracy:Float;

	public static var perfectCombo:Bool = true;

	// from left to right
	// judgement id, max milliseconds, score from it and percentage
	public static var judgementsMap:Map<String, Array<Dynamic>> = [
		"sick" => [0, 45, 350, 100, 'MFC'],
		"good" => [1, 90, 150, 75, 'GFC'],
		"bad" => [2, 135, 0, 25, 'FC'],
		"shit" => [3, 157.5, -50, -150],
		"miss" => [4, 180, -100, -175],
	];

	public static var msThreshold:Float = 0;

	// set the score judgements for later use
	public static var scoreRating:Map<String, Int> = [
		"S+" => 100,
		"S" => 95,
		"A" => 90,
		"B" => 85,
		"C" => 80,
		"D" => 75,
		"E" => 70,
		"F" => 65,
	];

	public static var ratingFinal:String = "N/A";
	public static var notesHit:Int = 0;
	public static var segmentsHit:Int = 0;
	public static var comboDisplay:String = '';

	public static var gottenJudgements:Map<String, Int> = [];
	public static var smallestRating:String;

	public static function callAccuracy()
	{
		// reset the accuracy to 0%
		accuracy = 0.001;
		trueAccuracy = 0;

		// reset ms threshold
		var biggestThreshold:Float = 0;
		for (i in judgementsMap.keys())
			if (judgementsMap.get(i)[1] > biggestThreshold)
				biggestThreshold = judgementsMap.get(i)[1];
		msThreshold = biggestThreshold;

		// set the gotten judgement amounts
		for (judgement in judgementsMap.keys())
			gottenJudgements.set(judgement, 0);
		smallestRating = 'sick';

		notesHit = 0;
		segmentsHit = 0;
		perfectCombo = true;

		ratingFinal = "N/A";
		comboDisplay = '';
	}

	public static function updateAccuracy(judgement:Int, ?isSustain:Bool = false, ?segmentCount:Int = 1)
	{
		if (!isSustain)
		{
			notesHit++;
			accuracy += (Math.max(0, judgement));
		}
		else
		{
			accuracy += (Math.max(0, judgement) / segmentCount);
		}
		trueAccuracy = (accuracy / notesHit);

		if (trueAccuracy >= 100)
			trueAccuracy = 100;

		updateFCDisplay();
		updateScoreRating();

		PlayState.contents.callFunc('updateAccuracy', []);
	}

	public static function updateFCDisplay()
	{
		var gottenFC = judgementsMap.get(smallestRating)[4];

		// update combo display
		comboDisplay = '';

		if (gottenFC != null)
			comboDisplay = gottenFC;
		else if (PlayState.misses < 10)
			comboDisplay = 'SDCB';

		// this updates the most so uh
		PlayState.uiHUD.updateScoreText();
	}

	public static function updateScoreRating()
	{
		var biggest:Int = 0;
		for (score in scoreRating.keys())
		{
			if ((scoreRating.get(score) <= trueAccuracy) && (scoreRating.get(score) >= biggest))
			{
				biggest = scoreRating.get(score);
				ratingFinal = score;
			}
		}
	}

	public static function getAccuracy()
	{
		return trueAccuracy;
	}

	public static function returnScoreRating()
	{
		return ratingFinal;
	}
}
