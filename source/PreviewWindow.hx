package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;

class PreviewWindow
{
	var cards:Array<Card>;
	var slots:Array<Slot>;
	var backdrop:FlxSprite;
	var header:FlxText;

	public function new(group:FlxGroup)
	{
		var centerX = FlxG.width / 2;
		var centerY = FlxG.height / 2;

		var previewWidth = 13 * Globals.cardWidth + 14 * Globals.alignmentHorGap;
		var previewHeight = 3 * Globals.alignmentVertGap + Globals.cardHeight + 92;
		var previewX = centerX - previewWidth / 2;
		var previewY = centerY - previewHeight / 2;
		backdrop = new FlxSprite(previewX, previewY, "assets/PreviewWindow.png");
		backdrop.setGraphicSize(previewWidth, previewHeight);
		backdrop.updateHitbox();
		group.add(backdrop);

		header = new FlxText();
		header.text = "Cards in deck:";
		header.size = 32;
		header.screenCenter(X);
		header.y = previewY + Globals.alignmentVertGap;
		group.add(header);

		slots = [];
		var slotX = previewX + Globals.alignmentHorGap;
		var slotY = previewY + 2 * Globals.alignmentVertGap + 32;
		var slot:Slot;

		// Initialize the preview slots
		for (i in 0...13)
		{
			slot = new Slot(slotX, slotY, PreviewSlot);
			slots.push(slot);
			group.add(slot);
			slotX += Globals.cardWidth + Globals.alignmentHorGap;
		}

		// Put the cards in the preview slots
		cards = [];
		var card:Card;
		for (cardIndex in 0...52)
		{
			card = new Card(0, 0, cardIndex);
			card.animation.frameIndex = cardIndex;
			cards.push(card);
			slots[card.val - 1].addCard(card);
			group.add(card);
		}

		Globals.signals.cardDrawn.add(updateCardDrawn);

		group.visible = false;
	}

	function updateCardDrawn(drawnCard:Card)
	{
		var previewCard:Card = null;
		for (card in cards)
		{
			if (card.cardIndex == drawnCard.cardIndex)
			{
				previewCard = card;
				break;
			}
		}
		if (previewCard != null)
		{
			cards.remove(previewCard);
			previewCard.slot.drawCard(previewCard);
			previewCard.kill();
		}
	}
}
