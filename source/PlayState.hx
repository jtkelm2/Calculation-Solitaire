package;

import Events;
import Slot.SlotType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.util.FlxFSM;
import flixel.group.FlxGroup;
import flixel.input.mouse.FlxMouseEvent;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

enum GameState {
	WaitingSelection;
	CardSelected;
	CardInMotion;
	GameOver;
}

class PlayState extends FlxState
{
	var bg:FlxSprite;
	var selectedCard:Null<Card>;
	var hoveredCard(default,set):Null<Card>;
	var slotsGrp:FlxTypedGroup<Slot>;
	var slotsLookup:Array<Array<Slot>>;
	var slotTextGrp:FlxTypedGroup<FlxText>;
	var deck:Slot;
	var deckText:FlxText;
	var cards:Array<Card>;
	var gameState:GameState;
	var handle:Map<GameState,EventID -> Void>;

	override public function create():Void
	{
		FlxG.console.registerObject("Globals", Globals);
		gameState = WaitingSelection;
		handle = [WaitingSelection => handleWaitingSelection, CardSelected => handleCardSelected, CardInMotion => handleCardInMotion, GameOver => handleGameOver];

		Globals.cardWidth = 70;
		Globals.cardHeight = 94;

		Globals.deckX = 100;
		Globals.deckY = 3;

		Globals.alignmentVertGap = 7;
		Globals.alignmentHorGap = 3;

		Globals.tableauAlignmentX = 200;
		Globals.tableauAlignmentY = 3 + Globals.cardHeight + Globals.alignmentVertGap;

		Globals.foundationAlignmentX = Globals.tableauAlignmentX + Globals.cardWidth + 20 * Globals.alignmentHorGap;
		Globals.foundationAlignmentY = Globals.tableauAlignmentY;

		Globals.flipTime = 0.4;
		Globals.travelTime = 0.5;

		Globals.foundationColor = 0xffa300;

		bg = new FlxSprite(0, 0, "assets/Table.png");
		add(bg);

		slotsLookup = [for (_ in 0...5) []];
		slotsGrp = new FlxTypedGroup<Slot>();
		slotTextGrp = new FlxTypedGroup<FlxText>();
		add(slotsGrp);
		add(slotTextGrp);

		FlxG.plugins.add(new FlxMouseEventManager());

		// Create the deck

		deck = initSlot(Globals.deckX, Globals.deckY, DeckSlot);
		cards = [for (i in 0...52) initCard(i)];
		FlxG.random.shuffle(cards);
		for (card in cards)
		{
			deck.addCard(card);
		}
		deckText = new FlxText(Globals.deckX + Globals.cardWidth + Globals.alignmentHorGap, Globals.deckY + Globals.cardHeight / 2 - 16);
		deckText.size = 32;
		deckText.text = "x 52";
		Globals.signals.cardDrawn.add((_) ->
		{
			deckText.text = "x " + deck.cards.length;
		});
		Globals.signals.outOfCards.add(() ->
		{
			deckText.text = "... so didja win?";
		});
		add(deckText);

		// Create the tableaux

		var x = Globals.tableauAlignmentX;
		var y = Globals.tableauAlignmentY;
		for (i in 1...5)
		{
			initSlot(x, y, TableauSlot(i));
			y += Globals.cardHeight + Globals.alignmentVertGap;
		}

		// Create the foundations

		y = Globals.foundationAlignmentY;
		for (i in 1...5)
		{
			x = Globals.foundationAlignmentX;
			for (j in 1...14)
			{
				slotsLookup[i][j] = initSlot(x, y, FoundationSlot(i, j));
				x += Globals.cardWidth + Globals.alignmentHorGap;
			}
			y += Globals.cardHeight + Globals.alignmentVertGap;
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		var event:EventID;
		while (Globals.eventListener.length > 0)
		{
			event = Globals.eventListener.pop();
			handle[gameState](event);
		}
	}

	function initCard(cardIndex:Int):Card
	{
		var card = new Card(0, 0, cardIndex);
		Globals.events.initClickable(CardID(card));
		return card;
	}

	function initSlot(x, y, slotType:SlotType):Slot
	{
		var slot = new Slot(x, y, slotType);
		if (slot.txt != null)
		{
			slotTextGrp.add(slot.txt);
		};
		add(slot.cardsGrp);
		slotsGrp.add(slot);
		Globals.events.initClickable(SlotID(slot));
		return slot;
	}

	function handleWaitingSelection(eventID:EventID):Void {
		switch eventID {
			case MouseOver(CardID(card)): {
				if (card.canClick) {
					hoveredCard = card;
					card.magnify();
				};
			}
			case MouseOut(CardID(card)): {
				card.demagnify();
				if (hoveredCard == card) {hoveredCard = null;}
			}
			case MouseUp(CardID(card)): {
				if (card.canClick) {
					card.highlight();
					if (!card.faceUp) {card.flip();};
					selectedCard = card;
					gameState = CardSelected;
				}
			}
            case _: {}
		}
	}

	function handleCardSelected(eventID:EventID):Void {
		switch eventID {
			case MouseOver(CardID(card)): {
				if (card.canClick) {
					hoveredCard = card;
					card.magnify();
				};
			}
			case MouseOut(CardID(card)): {
				card.demagnify();
				if (hoveredCard == card) {hoveredCard = null;}
			}
			case MouseUp(CardID(card)): {
				if (card.canClick && card.slot.slotType != DeckSlot) {
					card.highlight();
					selectedCard.lowlight();
					selectedCard = card;
				}
			}
            case MouseDown(SlotID(slot)): {
				if (willAccept(slot, selectedCard)) {
					selectedCard.moveTo(slot);
					selectedCard = null;
					gameState = CardInMotion;
				} else {
					selectedCard.lowlight();
					selectedCard = null;
					gameState = WaitingSelection;
				}
			}
			case _: {}
		}
	}

	function handleCardInMotion(eventID:EventID):Void {
		switch eventID {
			case CardFinishedTravel(card):
				gameState = WaitingSelection;
				switch (card.slot.slotType) {
					case FoundationSlot(rowIndex, foundationIndex): {
						if (foundationIndex < 13) {
							slotsLookup[rowIndex][foundationIndex+1].isReady = true;
						}
					}
					case _: {}
				}
			case MouseOver(CardID(card)): {
				if (card.canClick) {
					hoveredCard = card;
					card.magnify();
				};
			}
			case MouseOut(CardID(card)): {
				card.demagnify();
				if (hoveredCard == card) {hoveredCard = null;}
			}
			case _: {};
		}
	}

	function handleGameOver(eventID:EventID):Void {
		switch eventID {
			case _: {}
		}
	}

	function willAccept(slot:Slot, card:Card):Bool {
		if (slot.cards.length == slot.displayLimit) {return false;};
		switch slot.slotType {
			case FoundationSlot(rowIndex, foundationIndex): {
					if (card.val == slot.val) {
						if (foundationIndex == 1) {return true;}
						else {return slotsLookup[rowIndex][foundationIndex - 1].occupied();}
					}
					else {return false;}
				}
			case TableauSlot(_): return true;
			case DeckSlot: return false;
		}
	}

	function set_hoveredCard(card:Null<Card>):Null<Card> {
		hoveredCard = card;
		Globals.signals.hoverChanged.dispatch(card);
		return card;
	}
}