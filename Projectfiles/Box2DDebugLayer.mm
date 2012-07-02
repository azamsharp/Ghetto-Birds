/*
 * Kobold2D™ --- http://www.kobold2d.org
 *
 * Copyright (c) 2011 John Wordsworth. http://www.johnwordsworth.com
 * Released under MIT License in Germany (LICENSE-Kobold2D.txt).
 */

#import "Box2DDebugLayer.h"

@implementation Box2DDebugLayer

/** Create a debug layer with the given world and ptm ratio */
+(id)debugLayerWithWorld:(b2World *)world ptmRatio:(int)ptmRatio 
{
	id layer = [[self alloc] initWithWorld:world ptmRatio:ptmRatio];
#ifndef KK_ARC_ENABLED
	[layer autorelease];
#endif
	return layer;
}

/** Create a debug layer with the given world, ptm ratio and debug display flags */
+(id)debugLayerWithWorld:(b2World *)world ptmRatio:(int)ptmRatio flags:(uint32)flags
{
	id layer = [[self alloc] initWithWorld:world ptmRatio:ptmRatio flags:flags];
#ifndef KK_ARC_ENABLED
	[layer autorelease];
#endif
	return layer;
}

/** Create a debug layer with the given world and ptm ratio */
-(id)initWithWorld:(b2World*)world ptmRatio:(int)ptmRatio
{
    return [self initWithWorld:world ptmRatio:ptmRatio flags:b2Draw::e_shapeBit];
}

/** Create a debug layer with the given world, ptm ratio and debug display flags */
-(id)initWithWorld:(b2World*)world ptmRatio:(int)ptmRatio flags:(uint32)flags
{
	if ((self = [self init])) {
		_boxWorld = world;
        _ptmRatio = ptmRatio;
		_debugDraw = new GLESDebugDraw( ptmRatio );
        
		_boxWorld->SetDebugDraw(_debugDraw);
		_debugDraw->SetFlags(flags);		
	}
	
	return self;    
}

/** Clean up by deleting the debug draw layer. */
-(void)dealloc
{
	_boxWorld = NULL;
	
	if ( _debugDraw != NULL ) {
		delete _debugDraw;
	}
	
#ifndef KK_ARC_ENABLED
	[super dealloc];
#endif
}


/** Tweak a few OpenGL options and then draw the Debug Layer */
-(void)draw	
{
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	
	glPushMatrix();
	glScalef( CC_CONTENT_SCALE_FACTOR(), CC_CONTENT_SCALE_FACTOR(), 1.0f);
	_boxWorld->DrawDebugData();
	glPopMatrix();	
	
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);	
}

@end
