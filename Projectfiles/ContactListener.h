/*
 * Kobold2D™ --- http://www.kobold2d.org
 *
 * Copyright (c) 2010-2011 Steffen Itterheim. 
 * Released under MIT License in Germany (LICENSE-Kobold2D.txt).
 */

#import "Box2D.h"

class ContactListener : public b2ContactListener
{
private:
	void BeginContact(b2Contact* contact);
	void EndContact(b2Contact* contact);
};