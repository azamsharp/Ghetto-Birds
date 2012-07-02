/*
 * Kobold2D™ --- http://www.kobold2d.org
 *
 * Copyright (c) 2011 John Wordsworth. http://www.johnwordsworth.com
 * Released under MIT License in Germany (LICENSE-Kobold2D.txt).
 */

#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"

/** */
@interface Box2DDebugLayer : CCLayer 
{
	GLESDebugDraw* _debugDraw;
	b2World* _boxWorld;
    int _ptmRatio;
}

/** Return an autoreleased debug layer */
+(id)debugLayerWithWorld:(b2World *)world ptmRatio:(int)ptmRatio;
+(id)debugLayerWithWorld:(b2World *)world ptmRatio:(int)ptmRatio flags:(uint32)flags;

/** Initialise a debug layer with the given parameters. */
-(id)initWithWorld:(b2World *)world ptmRatio:(int)ptmRatio;
-(id)initWithWorld:(b2World *)world ptmRatio:(int)ptmRatio flags:(uint32)flags;

@end