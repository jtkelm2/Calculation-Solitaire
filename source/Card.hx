package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.mouse.FlxMouseEvent;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
 
class Card extends FlxSprite
{
	public var faceUp:Bool;
	public var canClick:Bool;

	public var slot:Slot;
	public var previousSlot:Slot;

	public var cardIndex:Int;
	public var val:Int;

	public function new(x:Float, y:Float, cardIndex:Int):Void
	{
		super(x, y);
		this.cardIndex = cardIndex;
		val = cardIndex % 13 + 1;
		faceUp = false;
		canClick = false;
		loadGraphic("assets/Deck.png", true, Globals.cardWidth, Globals.cardHeight);

		// The card starts out face down
		animation.frameIndex = 52;
	}

	public function magnify()
	{
		if (canClick) {
		scale.x = scale.y = 1.2;}
	}

	public function demagnify()
	{
		if (scale.x > 1)
			scale.x = scale.y = 1.0;
	}

	public function moveTo(targetSlot:Slot):Void
	{
		slot.cardsGrp.remove(this);
		targetSlot.cardsGrp.add(this); // Necessary so that card is rendered on top of others in targetSlot during the move
		FlxTween.tween(this, {x: targetSlot.x, y: targetSlot.y}, Globals.travelTime, {
			ease: FlxEase.quadOut,
			onComplete: function(?_)
			{
				slot.drawCard();
				targetSlot.addCard(this);
				slot = targetSlot;
				lowlight();
				Globals.eventListener.push(CardFinishedTravel(this));
			}
		});
	}

	public function flip():Void
	{
		canClick = false;
		FlxTween.tween(this.scale, {x: 0, y: 1}, Globals.flipTime, {
			ease: FlxEase.quadOut,
			onComplete: function(?_)
			{
				if (faceUp)
					(animation.frameIndex = 52)
				else
					(animation.frameIndex = cardIndex);
				FlxTween.tween(this.scale, {x: 1, y: 1}, Globals.flipTime, {
					ease: FlxEase.quadOut,
					onComplete: (_) -> {
						faceUp = !faceUp;
						canClick = true;
					}
				});
			}
		});
	}

	public function lowlight():Void
	{
		var frameIndex = animation.frameIndex;
		loadGraphic("assets/Deck.png", true, Globals.cardWidth, Globals.cardHeight);
		animation.frameIndex = frameIndex;
	}

	public function highlight():Void
	{
		var frameIndex = animation.frameIndex;
		loadGraphic("assets/DeckHighlight.png", true, Globals.cardWidth, Globals.cardHeight);
		animation.frameIndex = frameIndex;
	}

	public function isBelow(card:Null<Card>):Bool
	{
		if (card == null)
			(return false);
		if (card.slot != slot)
			(return false);
		return (slot.cards.indexOf(this) < slot.cards.indexOf(card));
	}
}
