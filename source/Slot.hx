package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.input.mouse.FlxMouseEvent;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;

enum SlotType
{
	DeckSlot;
	TableauSlot(rowIndex:Int);
	FoundationSlot(rowIndex:Int, foundationIndex:Int);
	PreviewSlot;
}

class Slot extends FlxSprite
{
	public var slotType:SlotType;
	public var cardsGrp:FlxTypedGroup<Card>;
	public var cards:Array<Card>;

	public var val:Null<Int>;
	public var isReady:Bool;

	public var highlight:Bool;

	public var displayLimit:Int;
	public var offsetX:Int;
	public var offsetY:Int;

	public var txt:FlxText;

	public function new(x:Float, y:Float, slotType:SlotType)
	{
		super(x, y);
		this.slotType = slotType;
		offsetX = -16;
		offsetY = 0;
		displayLimit = 52;
		alpha = 0.8;
		width = Globals.cardWidth;
		height = Globals.cardHeight;
		cardsGrp = new FlxTypedGroup<Card>();
		cards = [];
		isReady = false;
		highlight = false;
		txt = new FlxText();

		switch (slotType)
		{
			case DeckSlot:
				loadGraphic("assets/FoundationSlot.png");
				alpha = 0;
				displayLimit = 5;
				offsetX = -5;
			case TableauSlot(rowIndex):
				loadGraphic("assets/TableauSlot.png");
				displayLimit = 13;
			case FoundationSlot(rowIndex, foundationIndex):
				loadGraphic("assets/FoundationSlot.png");
				displayLimit = 1;
				isReady = (foundationIndex == 1);
				val = (rowIndex * foundationIndex - 1) % 13 + 1;
				txt = new FlxText(x, y + height / 2 - 16, width, Globals.valToString[val], 32);

				txt.alignment = FlxTextAlign.CENTER;
				txt.setBorderStyle(FlxTextBorderStyle.SHADOW, 0xFF808080);
				txt.color = Globals.foundationColor;

				Globals.signals.hoverChanged.add(handleHoverChange);
			case PreviewSlot:
				loadGraphic("assets/FoundationSlot.png");
				alpha = 0;
				displayLimit = 4;
				offsetX = 0;
				offsetY = 20;
		};
		resetText();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (highlight)
		{
			txt.alpha = FlxMath.bound(txt.alpha + 0.1, 0.3, 1);
		}
		else
		{
			txt.alpha = FlxMath.bound(txt.alpha - 0.1, 0.3, 1);
		}
	}

	public function addCard(card:Card)
	{
		cardsGrp.add(card);
		cards.push(card);
		updatePile();
		card.slot = this;
	}

	public function drawCard(?cardToDraw:Card):Null<Card>
	{
		var card:Card;
		if (cardToDraw != null)
		{
			card = cardToDraw;
		}
		else
		{
			card = cards[cards.length - 1];
		}
		cards.remove(card);
		cardsGrp.remove(card);
		updatePile();
		return card;
	}

	function updatePile():Void
	{
		var j:Int = cards.length;

		for (i in 0...cards.length)
		{
			j--;
			if (i < displayLimit)
			{
				cards[j].reset(x + i * offsetX, y + i * offsetY);
			}
			else
			{
				cards[j].kill();
			}
			if (i > 0)
			{
				cards[j].canClick = false;
			}
			else
			{
				cards[j].canClick = true;
			}
		}
		switch (slotType)
		{
			case FoundationSlot(_, _):
				if (occupied())
				{
					cards[0].canClick = false;
				}
			case _:
				{}
		}
	}

	public function resetText():Void
	{
		highlight = isReady;
	}

	function handleHoverChange(card:Card):Void
	{
		if (card == null || !card.faceUp)
		{
			resetText();
		}
		else
		{
			switch (card.slot.slotType)
			{
				case FoundationSlot(_, _):
					resetText();
				case _:
					highlight = (card.val == this.val);
			}
		}
	}

	public function occupied():Bool
	{
		return (cards.length > 0);
	}

	override public function destroy():Void
	{
		// Make sure that this object is removed from the FlxMouseEventManager for GC
		FlxMouseEvent.remove(this);
		txt.destroy();
		cardsGrp.destroy();
		super.destroy();
	}
}
