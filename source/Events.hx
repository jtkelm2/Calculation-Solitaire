package;

import flixel.FlxObject;
import flixel.input.mouse.FlxMouseEvent;
import flixel.util.FlxSignal;

enum ObjectID
{
	CardID(card:Card);
	SlotID(slot:Slot);
}

enum EventID
{
	MouseDown(objectID:ObjectID);
	MouseUp(objectID:ObjectID);
	MouseOver(objectID:ObjectID);
	MouseOut(objectID:ObjectID);
	CardFinishedTravel(card:Card);
}

class Events
{
	public var queue:Array<EventID>;

	public function initClickable(clickableID:ObjectID)
	{
		var pixelPerfect:Bool;
		var clickable:FlxObject;
		switch (clickableID)
		{
			case CardID(card):
				clickable = card;
				pixelPerfect = true;
			case SlotID(slot):
				clickable = slot;
				pixelPerfect = false;
		}
		FlxMouseEvent.add(clickable, (_) ->
		{
			Globals.events.queue.push(MouseDown(clickableID));
		}, (_) ->
			{
				Globals.events.queue.push(MouseUp(clickableID));
			}, (_) ->
			{
				Globals.events.queue.push(MouseOver(clickableID));
			}, (_) ->
			{
				Globals.events.queue.push(MouseOut(clickableID));
			}, true, true, pixelPerfect);
	}

	public function new()
	{
		queue = [];
	}
}

class Signals
{
	public var gameOver = new FlxSignal();
	public var gameReset = new FlxSignal();
	public var cardDrawn = new FlxTypedSignal<Card->Void>();
	public var outOfCards = new FlxSignal();
	public var hoverChanged = new FlxTypedSignal<Null<Card>->Void>();

	public function new() {}
}
