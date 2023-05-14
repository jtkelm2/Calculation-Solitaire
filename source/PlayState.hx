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
import flixel.math.FlxRandom;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

enum GameState
{
	WaitingSelection;
	CardSelected;
	CardInMotion;
	GameOver;
}

class PlayState extends FlxState
{
	var bg:FlxSprite;

	var selectedCard:Null<Card>;

	var hoverQueue:Array<Card>;
	var hoveredCard(default, set):Null<Card>;

	var smartKingCommentMade:Bool;

	var slotsGrp:FlxTypedGroup<Slot>;
	var slotsLookup:Array<Array<Slot>>;
	var slotTextGrp:FlxTypedGroup<FlxText>;

	var deck:Slot;
	var deckText:FlxText;

	var cards:Array<Card>;

	var gameState(default, set):GameState;
	var handle:Map<GameState, EventID->Void>;

	var previewGroup:FlxGroup;
	var previewWindow:PreviewWindow;

	var confettiGroup:FlxGroup;
	var confetti:Confetti;

	var instructionText:FlxText;

	override public function create():Void
	{
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

		Globals.flipTime = 0.2;
		Globals.travelTime = 0.45;

		Globals.foundationColor = 0xFFFFA300;
		Globals.tableauColor = 0xFF29ADFF;

		Globals.events = new Events();
		Globals.signals = new Signals();

		gameState = WaitingSelection;
		handle = [
			WaitingSelection => handleWaitingSelection,
			CardSelected => handleCardSelected,
			CardInMotion => handleCardInMotion,
			GameOver => handleGameOver
		];

		bg = new FlxSprite(0, 0, "assets/Table.png");
		add(bg);

		hoverQueue = [];
		smartKingCommentMade = false;

		slotsLookup = [for (_ in 0...5) []];
		slotsGrp = new FlxTypedGroup<Slot>();
		slotTextGrp = new FlxTypedGroup<FlxText>();
		add(slotsGrp);
		add(slotTextGrp);

		FlxG.plugins.add(new FlxMouseEventManager());

		// Create the deck

		deck = initSlot(Globals.deckX, Globals.deckY, DeckSlot);
		slotsLookup[0].push(deck);

		cards = [for (i in 0...52) initCard(i)];
		FlxG.random.shuffle(cards);
		for (card in cards)
		{
			deck.addCard(card);
		}

		deckText = new FlxText(Globals.deckX + Globals.cardWidth + Globals.alignmentHorGap, Globals.deckY + Globals.cardHeight / 2 - 16);
		deckText.size = 32;
		deckText.text = "x 52";

		Globals.signals.cardDrawn.add(signalSmartCommentOnDraw);
		Globals.signals.outOfCards.add(() ->
		{
			deckText.text = "...";
		});

		add(deckText);

		// Create the tableaux

		var x = Globals.tableauAlignmentX;
		var y = Globals.tableauAlignmentY;
		for (i in 1...5)
		{
			slotsLookup[0].push(initSlot(x, y, TableauSlot(i)));
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

		// Initialize preview window

		previewGroup = new FlxGroup();
		previewWindow = new PreviewWindow(previewGroup);
		add(previewGroup);

		// Initialize confetti

		confettiGroup = new FlxGroup();
		confetti = new Confetti(confettiGroup);
		add(confettiGroup);

		// Instruction text

		instructionText = new FlxText(0, 0, 0, "Space: Deck preview       R: Reset game\nF: Autoplay       (Hold) Shift: Cheat placements");
		instructionText.size = 32;
		instructionText.alignment = CENTER;
		instructionText.screenCenter(X);
		instructionText.y = FlxG.height - 100;
		Globals.signals.cardDrawn.add(_ -> instructionText.kill());
		add(instructionText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE)
		{
			Globals.events.queue.push(KeyPressed(Spacebar));
		}
		if (FlxG.keys.justReleased.SPACE)
		{
			Globals.events.queue.push(KeyReleased(Spacebar));
		}

		if (FlxG.keys.justReleased.F)
		{
			automateGame();
		}

		if (FlxG.keys.pressed.R)
		{
			var t:Float = 0;
			for (card in cards)
			{
				if (card.slot.slotType != DeckSlot)
				{
					t += 0.1;
					new FlxTimer().start(t, {
						_ -> if (card.slot.slotType != DeckSlot)
						{
							card.moveTo(deck);
							card.flip();
						}
					});
				}
			}
			new FlxTimer().start(0.7 + t + 2 * Globals.flipTime, function(_)
			{
				FlxG.resetGame();
			});
		}

		var event:EventID;
		while (Globals.events.queue.length > 0)
		{
			event = Globals.events.queue.pop();
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
		add(slot.cardsGrp);
		slotsGrp.add(slot);
		slotTextGrp.add(slot.txt);
		Globals.events.initClickable(SlotID(slot));
		return slot;
	}

	function willAccept(slot:Slot, card:Card):Bool
	{
		if (FlxG.keys.pressed.SHIFT)
		{
			return true;
		}
		if (slot.cards.length == slot.displayLimit)
		{
			return false;
		}
		switch slot.slotType
		{
			case FoundationSlot(rowIndex, foundationIndex):
				{
					return (slot.isReady && card.val == slot.val);
				}
			case TableauSlot(_):
				return (card.slot.slotType == DeckSlot);
			case DeckSlot:
				return false;
			case PreviewSlot:
				return false;
		}
	}

	function handleWaitingSelection(eventID:EventID):Void
	{
		switch eventID
		{
			case MouseOver(CardID(card)):
				addHover(card);
			case MouseOut(CardID(card)):
				removeHover(card);
			case MouseUp(CardID(card)):
				if (card.canClick)
				{
					card.highlight();
					if (!card.faceUp)
					{
						card.flip((_) ->
						{
							refreshHoveredCard();
							Globals.signals.cardDrawn.dispatch(card);
						});
					};
					selectedCard = card;
					gameState = CardSelected;
				}
			case KeyPressed(Spacebar):
				previewGroup.visible = true;
			case KeyReleased(Spacebar):
				previewGroup.visible = false;
			case _:
				{}
		}
	}

	function handleCardSelected(eventID:EventID):Void
	{
		switch eventID
		{
			case MouseOver(CardID(card)):
				{
					addHover(card);
				}
			case MouseOut(CardID(card)):
				{
					removeHover(card);
				}
			case MouseUp(CardID(card)):
				{
					if (card.canClick && selectedCard.slot.slotType != DeckSlot && card.slot.slotType != DeckSlot && card != selectedCard)
					{
						card.highlight();
						selectedCard.lowlight();
						selectedCard = card;
					}
				}
			case MouseDown(SlotID(slot)):
				{
					if (willAccept(slot, selectedCard))
					{
						selectedCard.moveTo(slot);
						selectedCard = null;
						gameState = CardInMotion;
					}
					else
					{
						if (selectedCard.slot.slotType != DeckSlot)
						{
							selectedCard.lowlight();
							new FlxTimer().start(0.1, _ ->
							{
								selectedCard = null;
								gameState = WaitingSelection;
							});
						}
					}
				}
			case KeyPressed(Spacebar):
				previewGroup.visible = true;
			case KeyReleased(Spacebar):
				previewGroup.visible = false;
			case _:
				{}
		}
	}

	function handleCardInMotion(eventID:EventID):Void
	{
		switch eventID
		{
			case CardFinishedTravel(card):
				switch (card.slot.slotType)
				{
					case FoundationSlot(rowIndex, foundationIndex):
						card.slot.isReady = false;
						if (foundationIndex < 13)
						{
							var nextSlot = slotsLookup[rowIndex][foundationIndex + 1];
							nextSlot.isReady = true;
							nextSlot.resetText();
						}
					case _: {}
				}

				switch (checkWinLoss())
				{
					case -1:
						previewGroup.visible = false;
						confetti.playDefeat();
						gameState = GameOver;
						return;
					case 1:
						previewGroup.visible = false;
						confetti.playVictory();
						makeCardsDance();
						gameState = GameOver;
						return;
					case _: {}
				}

				refreshHoveredCard();
				gameState = WaitingSelection;
			case MouseOver(CardID(card)):
				{
					addHover(card, false);
				}
			case MouseOut(CardID(card)):
				{
					removeHover(card, false);
				}
			case KeyPressed(Spacebar):
				previewGroup.visible = true;
			case KeyReleased(Spacebar):
				previewGroup.visible = false;
			case _:
				{};
		}
	}

	function handleGameOver(eventID:EventID):Void
	{
		switch eventID
		{
			case _:
				{}
		}
	}

	function checkWinLoss()
	{
		if (deck.occupied())
		{
			return 0;
		}

		var tableauxCards = getTopTableauxCards();
		if (tableauxCards.length > 0)
		{
			for (card in tableauxCards)
			{
				for (slot in getOpenSlots())
				{
					if (willAccept(slot, card))
					{
						return 0;
					}
				}
			}
			return -1;
		}
		return 1;
	}

	function getTopTableauxCards():Array<Card>
	{
		var tableauxCards:Array<Card> = [];
		for (slot in slotsLookup[0].slice(1, 5))
		{
			if (slot.occupied())
			{
				tableauxCards.push(slot.cards[slot.cards.length - 1]);
			}
		}
		return tableauxCards;
	}

	function getOpenSlots():Array<Slot>
	{
		var openSlots:Array<Slot> = [];
		for (foundation in slotsLookup.slice(1, 5))
		{
			for (slot in foundation.slice(1))
			{
				if (slot.isReady)
				{
					openSlots.push(slot);
					break;
				}
			}
		}
		return openSlots;
	}

	function makeCardsDance()
	{
		for (card in cards)
		{
			card.victoryDance();
		}
	}

	function signalSmartCommentOnDraw(card):Void
	{
		if (card.val == 13)
		{
			switch deck.cards.filter(deckCard -> deckCard.val == 13).length
			{
				case 4:
					if (deck.cards.length <= 40)
					{
						ephemeralComment("Sorry, I held onto that for a while, didn't I?");
						return;
					}
				case _:
					if (!smartKingCommentMade)
					{
						var hasOpenTableau = false;
						for (tableauSlot in slotsLookup[0].slice(1, 5))
							if (!tableauSlot.occupied() || tableauSlot.cards[tableauSlot.cards.length - 1].val == 13)
							{
								hasOpenTableau = true;
								break;
							}
						if (!hasOpenTableau)
						{
							ephemeralComment("... you have a place for that, right?");
							smartKingCommentMade = true;
							return;
						}
					}
			}
		}
		if (card.val == 11)
		{
			if (deck.cards.length >= 29 && deck.cards.filter(deckCard -> deckCard.val == 11).length == 2)
			{
				ephemeralComment("Friggin' jacks, am I right?");
				return;
			}
		}
		if (deck.cards.length < 2)
		{
			deckText.text = "...";
			return;
		}
		if (deck.cards.length < 5)
		{
			deckText.text = "... so didja win?";
			return;
		}
		deckText.text = 'x ${deck.cards.length - 1}';
	}

	function ephemeralComment(comment:String)
	{
		deckText.text = comment;
		var cardsLeft:Int = deck.cards.length;
		if (deck.cards[deck.cards.length - 1].faceUp)
		{
			cardsLeft--;
		}
		new FlxTimer().start(5, _ ->
		{
			deckText.text = 'x ${cardsLeft}';
		});
	}

	function addHover(card, ?refreshHover:Bool = true):Void
	{
		hoverQueue.push(card);
		hoverQueue.sort((c1, c2) ->
		{
			if (c1.isBelow(c2))
			{
				return -1;
			}
			else
			{
				return 1;
			}
		});
		if (refreshHover)
		{
			refreshHoveredCard();
		};
	}

	function removeHover(card, ?refreshHover:Bool = true):Void
	{
		hoverQueue.remove(card);
		if (refreshHover)
			refreshHoveredCard();
	}

	function refreshHoveredCard():Void
	{
		hoveredCard = hoverQueue[hoverQueue.length - 1];
	}

	function automateGame()
	{
		Globals.signals.stateChanged.add(() ->
		{
			if (gameState == CardSelected && !selectedCard.faceUp)
			{
				new FlxTimer().start(2 * Globals.flipTime, _ ->
				{
					makeRandomMove();
				});
			}
			else
			{
				makeRandomMove();
			}
		});
		makeRandomMove();
	}

	function makeRandomMove()
	{
		switch gameState
		{
			case WaitingSelection:
				for (card in getTopTableauxCards())
				{
					for (slot in getOpenSlots())
					{
						if (willAccept(slot, card))
						{
							Globals.events.queue.push(MouseUp(CardID(card)));
							return;
						}
					}
				}
				if (deck.cards.length > 0)
				{
					Globals.events.queue.push(MouseUp(CardID(deck.cards[deck.cards.length - 1])));
				}
			case CardSelected:
				for (slot in getOpenSlots())
				{
					if (willAccept(slot, selectedCard))
					{
						Globals.events.queue.push(MouseDown(SlotID(slot)));
						return;
					}
				}
				var openTableauSlots = slotsLookup[0].slice(1, 5).filter(slot -> willAccept(slot, selectedCard));
				Globals.events.queue.push(MouseDown(SlotID(openTableauSlots[FlxG.random.int(0, openTableauSlots.length - 1)])));
			case _:
				{}
		}
	}

	function set_hoveredCard(card:Null<Card>):Null<Card>
	{
		hoveredCard = card;
		Globals.signals.hoverChanged.dispatch(card);
		return card;
	}

	function set_gameState(gameState:GameState):GameState
	{
		this.gameState = gameState;
		Globals.signals.stateChanged.dispatch();
		return gameState;
	}
}
