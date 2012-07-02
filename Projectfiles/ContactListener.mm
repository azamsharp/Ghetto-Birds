/*
 * Kobold2D™ --- http://www.kobold2d.org
 *
 * Copyright (c) 2010-2011 Steffen Itterheim. 
 * Released under MIT License in Germany (LICENSE-Kobold2D.txt).
 */

#import "ContactListener.h"
#import "cocos2d.h"

void ContactListener::BeginContact(b2Contact* contact)
{
	b2Body* bodyA = contact->GetFixtureA()->GetBody();
	b2Body* bodyB = contact->GetFixtureB()->GetBody();
	CCSprite* spriteA = (__bridge CCSprite*)bodyA->GetUserData();
	CCSprite* spriteB = (__bridge CCSprite*)bodyB->GetUserData();
	
	if (spriteA != NULL && spriteB != NULL)
	{
		//spriteA.color = ccMAGENTA;
		//spriteB.color = ccMAGENTA;
	}
}

void ContactListener::EndContact(b2Contact* contact)
{
	b2Body* bodyA = contact->GetFixtureA()->GetBody();
	b2Body* bodyB = contact->GetFixtureB()->GetBody();
	CCSprite* spriteA = (__bridge CCSprite*)bodyA->GetUserData();
	CCSprite* spriteB = (__bridge CCSprite*)bodyB->GetUserData();
	
	if (spriteA != NULL && spriteB != NULL)
	{
		spriteA.color = ccWHITE;
		spriteB.color = ccWHITE;
	}
}
