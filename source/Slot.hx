package;

import flixel.FlxSprite;
// import flixel.addons.ui.FlxClickArea;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

enum SlotType
{
	DeckSlot;
	TableauSlot(rowIndex:Int);
	FoundationSlot(rowIndex:Int, foundationIndex:Int);
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
		alpha = 0.8;
		width = Globals.cardWidth;
		height = Globals.cardHeight;
		cardsGrp = new FlxTypedGroup<Card>();
		cards = [];
		isReady = false;

		switch (slotType)
		{
			case DeckSlot:
				loadGraphic("assets/FoundationSlot.png");
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

				Globals.signals.hoverChanged.add((card) -> {
					if (card == null || card.faceUp != true) {resetText();}
					else {
						if (card.val == this.val) {highlightText();} else {lowlightText();}
					}
				});
		};
		resetText();
	}

	public function addCard(card:Card)
	{
		cardsGrp.add(card);
		cards.push(card);
		updatePile();
		card.slot = this;
	}

	public function drawCard():Null<Card>
	{
		var card = cards.pop();
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
				cards[j].demagnify();
			}
			else
			{
				cards[j].canClick = true;
			}
		}
		switch (slotType) {
			case FoundationSlot(_,_): cards[0].canClick = false;
			case _: {}
		}
	}

	public function highlightText():Void
	{
		if (txt != null) {txt.alpha = 1;}
	}

	public function lowlightText():Void
	{
		if (txt != null) {txt.alpha = 0.3;}
	}

	public function resetText():Void
	{
		if (isReady) {highlightText();} else {lowlightText();}
	}

	public function occupied():Bool
	{
		return (cards.length > 0);
	}
}
