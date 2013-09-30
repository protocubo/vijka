package elebeta.queue;

interface Queue<Item> {

	/**
		Checks if the queue is empty
	**/
	public function isEmpty():Bool;

	/**
		Checks if the queue is _not_ empty
	**/
	public function notEmpty():Bool;
	
	/**
		Clears the queue
	**/
	public function clear():Void;

	/**
		Adds a new `item` to the queue
	**/
	public function add( item:Item ):Void;

	/**
		Returns the next item in the queue
	**/
	public function first():Null<Item>;

	/**
		Extracts and returns the next item in the queue
	**/
	public function pop():Null<Item>;

	/**
		Updates the position of `item` in the queue
	**/
	public function update( item:Item ):Void; 

}
