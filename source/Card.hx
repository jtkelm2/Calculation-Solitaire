package;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class Card extends FlxSprite
{
	public var faceUp:Bool;
	public var canClick(default, set):Bool;
	public var midFlip:Bool;

	public var slot:Slot;

	public var cardIndex:Int;
	public var val:Int;

	var isHovered:Bool;

	public function new(x:Float, y:Float, cardIndex:Int):Void
	{
		super(x, y);
		this.cardIndex = cardIndex;
		val = cardIndex % 13 + 1;
		faceUp = false;
		canClick = false;
		midFlip = false;
		isHovered = false;
		loadGraphic("assets/Deck.png", true, Globals.cardWidth, Globals.cardHeight);

		// The card starts out face down
		animation.frameIndex = 52;

		Globals.signals.hoverChanged.add((card) ->
		{
			isHovered = (card == this);
		});
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!midFlip)
		{
			if (isHovered && canClick)
			{
				scale.x = FlxMath.bound(scale.x + 2 * elapsed, 1, 1.2);
				scale.y = FlxMath.bound(scale.y + 2 * elapsed, 1, 1.2);
			}
			else
			{
				scale.x = FlxMath.bound(scale.x - 2 * elapsed, 1, 1.2);
				scale.y = FlxMath.bound(scale.y - 2 * elapsed, 1, 1.2);
			}
		}
	}

	public function moveTo(targetSlot:Slot, ?callback:Card->Void):Void
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
				if (callback != null)
				{
					callback(this);
				};
				Globals.events.queue.push(CardFinishedTravel(this));
			}
		});
	}

	public function flip(?callback:Card->Void):Void
	{
		midFlip = true;
		FlxTween.tween(this.scale, {x: 0, y: 1}, Globals.flipTime, {
			ease: FlxEase.quadOut,
			onComplete: (_) ->
			{
				if (faceUp)
					(animation.frameIndex = 52)
				else
					(animation.frameIndex = cardIndex);
				FlxTween.tween(this.scale, {x: 1, y: 1}, Globals.flipTime, {
					ease: FlxEase.quadOut,
					onComplete: (_) ->
					{
						faceUp = !faceUp;
						midFlip = false;
						if (callback != null)
						{
							callback(this);
						};
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

	function set_canClick(bool:Bool):Bool
	{
		if (!bool)
		{
			isHovered = false;
		}
		canClick = bool;
		return bool;
	}
}
