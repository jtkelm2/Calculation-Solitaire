package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.group.FlxGroup;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

enum CannonID
{
	Left;
	Right;
}

class Confetti
{
	var confettiCannonLeft:FlxEmitter;
	var confettiCannonRight:FlxEmitter;

	public function new(group:FlxGroup)
	{
		confettiCannonLeft = new FlxEmitter(FlxG.width / 5, FlxG.height, 50);
		confettiCannonRight = new FlxEmitter(4 * FlxG.width / 5, FlxG.height, 50);

		confettiCannonLeft.alpha.set(0.3, 0.8);
		confettiCannonRight.alpha.set(0.3, 0.8);

		confettiCannonLeft.lifespan.set(0);
		confettiCannonRight.lifespan.set(0);

		group.add(confettiCannonLeft);
		group.add(confettiCannonRight);
	}

	function setForVictory(confettiCannon:FlxEmitter, cannonID:CannonID)
	{
		confettiCannon.launchMode = CIRCLE;
		confettiCannon.speed.set(2000, 4000);
		confettiCannon.acceleration.set(0, 2000, 0, 2000);

		switch cannonID
		{
			case Left:
				confettiCannon.launchAngle.set(225, 340);
				confettiCannon.setPosition(FlxG.width / 5, FlxG.height);

			case Right:
				confettiCannon.launchAngle.set(200, 315);
				confettiCannon.setPosition(4 * FlxG.width / 5, FlxG.height);
		}

		var harmonyFoundation:Harmony = Globals.foundationColor.getAnalogousHarmony(10);
		var harmonyTableau:Harmony = Globals.tableauColor.getAnalogousHarmony(10);
		var colors:Array<FlxColor> = [
			harmonyFoundation.colder,
			harmonyFoundation.original,
			harmonyFoundation.warmer,
			harmonyTableau.colder,
			harmonyTableau.original,
			harmonyTableau.warmer
		];

		for (i in 0...50)
		{
			var p = new FlxParticle();

			var pSize = FlxG.random.int(5, 40);

			p.makeGraphic(pSize, pSize, colors[FlxG.random.int(0, 3)]);

			confettiCannon.add(p);
		}
	}

	function setForDefeat(confettiCannon:FlxEmitter)
	{
		confettiCannon.launchMode = SQUARE;
		confettiCannon.width = FlxG.width;
		confettiCannon.setPosition(0, 0);

		confettiCannon.alpha.set(0.5, 0.9);

		confettiCannon.velocity.set(-100, 200, 100);
		confettiCannon.acceleration.set(-50, 0, 50);

		for (i in 0...50)
		{
			var p = new FlxParticle();
			var pSize = FlxG.random.int(2, 20);

			p.makeGraphic(pSize, pSize, FlxColor.BLACK);

			confettiCannon.add(p);
		}
	}

	function multipleBursts(confettiCannon:FlxEmitter, bursts:Int = 1)
	{
		confettiCannon.start();
		if (bursts > 1)
		{
			new FlxTimer().start(0.5, _ ->
			{
				multipleBursts(confettiCannon, bursts - 1);
			});
		}
	}

	public function playVictory()
	{
		setForVictory(confettiCannonLeft, Left);
		setForVictory(confettiCannonRight, Right);
		multipleBursts(confettiCannonLeft, 5);
		multipleBursts(confettiCannonRight, 5);
	}

	public function playDefeat()
	{
		setForDefeat(confettiCannonLeft);
		confettiCannonLeft.start(false);
	}
}
