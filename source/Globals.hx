package;

import Events;
import flixel.util.FlxColor;

class Globals
{
	public static var cardWidth:Int;
	public static var cardHeight:Int;
	public static var foundationAlignmentX:Int;
	public static var foundationAlignmentY:Int;
	public static var tableauAlignmentX:Int;
	public static var tableauAlignmentY:Int;
	public static var deckX:Int;
	public static var deckY:Int;
	public static var alignmentVertGap:Int;
	public static var alignmentHorGap:Int;

	public static var flipTime:Float;
	public static var travelTime:Float;

	public static var foundationColor:FlxColor;

	public static var valToString:Map<Int, String> = [
		1 => "A", 2 => "2", 3 => "3", 4 => "4", 5 => "5", 6 => "6", 7 => "7", 8 => "8", 9 => "9", 10 => "10", 11 => "J", 12 => "Q", 13 => "K"
	];

	public static var signals:Signals = new Signals();
	public static var events:Events = new Events();
}
