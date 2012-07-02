/*
 * Kobold2D™ --- http://www.kobold2d.org
 *
 * Copyright (c) 2010-2011 Steffen Itterheim. 
 * Released under MIT License in Germany (LICENSE-Kobold2D.txt).
 */

#import "PhysicsLayer.h"
#import "Box2DDebugLayer.h"

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
const float PTM_RATIO = 32.0f;

const int TILESIZE = 32;
const int TILESET_COLUMNS = 9;
const int TILESET_ROWS = 19;


@interface PhysicsLayer (PrivateMethods)
-(void) enableBox2dDebugDrawing;
-(void) addSomeJoinedBodies:(CGPoint)pos;
-(void) addNewSpriteAt:(CGPoint)p;
-(b2Vec2) toMeters:(CGPoint)point;
-(CGPoint) toPixels:(b2Vec2)vec;
@end

@implementation PhysicsLayer

-(id) init
{
	if ((self = [super init]))
	{
		CCLOG(@"%@ init", NSStringFromClass([self class]));

		glClearColor(0.1f, 0.0f, 0.2f, 1.0f);
		
		// Construct a world object, which will hold and simulate the rigid bodies.
		b2Vec2 gravity = b2Vec2(0.0f, -10.0f);
		world = new b2World(gravity);
		world->SetAllowSleeping(YES);
		//world->SetContinuousPhysics(YES);
		
		// uncomment this line to draw debug info
		[self enableBox2dDebugDrawing];

		contactListener = new ContactListener();
		world->SetContactListener(contactListener);
		
		// for the screenBorder body we'll need these values
		CGSize screenSize = [CCDirector sharedDirector].winSize;
		float widthInMeters = screenSize.width / PTM_RATIO;
		float heightInMeters = screenSize.height / PTM_RATIO;
		b2Vec2 lowerLeftCorner = b2Vec2(0, 0);
		b2Vec2 lowerRightCorner = b2Vec2(widthInMeters, 0);
		b2Vec2 upperLeftCorner = b2Vec2(0, heightInMeters);
		b2Vec2 upperRightCorner = b2Vec2(widthInMeters, heightInMeters);
		
		// Define the static container body, which will provide the collisions at screen borders.
		b2BodyDef screenBorderDef;
		screenBorderDef.position.Set(0, 0);
		b2Body* screenBorderBody = world->CreateBody(&screenBorderDef);
		b2EdgeShape screenBorderShape;
		
		// Create fixtures for the four borders (the border shape is re-used)
		screenBorderShape.Set(lowerLeftCorner, lowerRightCorner);
		screenBorderBody->CreateFixture(&screenBorderShape, 0);
		screenBorderShape.Set(lowerRightCorner, upperRightCorner);
		screenBorderBody->CreateFixture(&screenBorderShape, 0);
		screenBorderShape.Set(upperRightCorner, upperLeftCorner);
		screenBorderBody->CreateFixture(&screenBorderShape, 0);
		screenBorderShape.Set(upperLeftCorner, lowerLeftCorner);
		screenBorderBody->CreateFixture(&screenBorderShape, 0);
		
		NSString* message = @"Tap Screen For More Awesome!";
		if ([CCDirector sharedDirector].currentPlatformIsMac)
		{
			message = @"Click Window For More Awesome!";
		}
		
		CCLabelTTF* label = [CCLabelTTF labelWithString:message fontName:@"Marker Felt" fontSize:32];
		[self addChild:label];
		[label setColor:ccc3(222, 222, 255)];
		label.position = CGPointMake(screenSize.width / 2, screenSize.height - 50);
		
		// Use the orthogonal tileset for the little boxes
		CCSpriteBatchNode* batch = [CCSpriteBatchNode batchNodeWithFile:@"dg_grounds32.png" capacity:TILESET_ROWS * TILESET_COLUMNS];
		[self addChild:batch z:0 tag:kTagBatchNode];
		
		// Add a few objects initially
		for (int i = 0; i < 9; i++)
		{
			[self addNewSpriteAt:CGPointMake(screenSize.width / 2, screenSize.height / 2)];
		}
		
		[self addSomeJoinedBodies:CGPointMake(screenSize.width / 4, screenSize.height - 50)];
		
		[self scheduleUpdate];
		
		[KKInput sharedInput].accelerometerActive = YES;
	}

	return self;
}

-(void) dealloc
{
	delete contactListener;
	delete world;

#ifndef KK_ARC_ENABLED
	[super dealloc];
#endif
}

-(void) enableBox2dDebugDrawing
{
	// Using John Wordsworth's Box2DDebugLayer class now
	// The advantage is that it draws the debug information over the normal cocos2d graphics,
	// so you'll still see the textures of each object.
	const BOOL useBox2DDebugLayer = YES;

	
	float debugDrawScaleFactor = 1.0f;
#if KK_PLATFORM_IOS
	debugDrawScaleFactor = [[CCDirector sharedDirector] contentScaleFactor];
#endif
	debugDrawScaleFactor *= PTM_RATIO;

	UInt32 debugDrawFlags = 0;
	debugDrawFlags += b2Draw::e_shapeBit;
	debugDrawFlags += b2Draw::e_jointBit;
	//debugDrawFlags += b2Draw::e_aabbBit;
	//debugDrawFlags += b2Draw::e_pairBit;
	//debugDrawFlags += b2Draw::e_centerOfMassBit;

	if (useBox2DDebugLayer)
	{
		Box2DDebugLayer* debugLayer = [Box2DDebugLayer debugLayerWithWorld:world
																  ptmRatio:PTM_RATIO
																	 flags:debugDrawFlags];
		[self addChild:debugLayer z:100];
	}
	else
	{
		debugDraw = new GLESDebugDraw(debugDrawScaleFactor);
		if (debugDraw)
		{
			debugDraw->SetFlags(debugDrawFlags);
			world->SetDebugDraw(debugDraw);
		}
	}
}

-(CCSprite*) addRandomSpriteAt:(CGPoint)pos
{
	CCSpriteBatchNode* batch = (CCSpriteBatchNode*)[self getChildByTag:kTagBatchNode];
	
	int idx = CCRANDOM_0_1() * TILESET_COLUMNS;
	int idy = CCRANDOM_0_1() * TILESET_ROWS;
	CGRect tileRect = CGRectMake(TILESIZE * idx, TILESIZE * idy, TILESIZE, TILESIZE);
	CCSprite* sprite = [CCSprite spriteWithBatchNode:batch rect:tileRect];
	sprite.position = pos;
	[batch addChild:sprite];
	
	return sprite;
}

-(void) bodyCreateFixture:(b2Body*)body
{
	// Define another box shape for our dynamic bodies.
	b2PolygonShape dynamicBox;
	float tileInMeters = TILESIZE / PTM_RATIO;
	dynamicBox.SetAsBox(tileInMeters * 0.5f, tileInMeters * 0.5f);
	
	// Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &dynamicBox;	
	fixtureDef.density = 0.3f;
	fixtureDef.friction = 0.5f;
	fixtureDef.restitution = 0.6f;
	body->CreateFixture(&fixtureDef);
	
}

-(void) addSomeJoinedBodies:(CGPoint)pos
{
	// Create a body definition and set it to be a dynamic body
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	
	// position must be converted to meters
	bodyDef.position = [self toMeters:pos];
	bodyDef.position = bodyDef.position + b2Vec2(-1, -1);
	bodyDef.userData = (__bridge void*)[self addRandomSpriteAt:pos];
	b2Body* bodyA = world->CreateBody(&bodyDef);
	[self bodyCreateFixture:bodyA];
	
	bodyDef.position = [self toMeters:pos];
	bodyDef.userData = (__bridge void*)[self addRandomSpriteAt:pos];
	b2Body* bodyB = world->CreateBody(&bodyDef);
	[self bodyCreateFixture:bodyB];
	
	bodyDef.position = [self toMeters:pos];
	bodyDef.position = bodyDef.position + b2Vec2(1, 1);
	bodyDef.userData = (__bridge void*)[self addRandomSpriteAt:pos];
	b2Body* bodyC = world->CreateBody(&bodyDef);
	[self bodyCreateFixture:bodyC];
	
	b2RevoluteJointDef jointDef;
	jointDef.Initialize(bodyA, bodyB, bodyB->GetWorldCenter());
	bodyA->GetWorld()->CreateJoint(&jointDef);
	
	jointDef.Initialize(bodyB, bodyC, bodyC->GetWorldCenter());
	bodyA->GetWorld()->CreateJoint(&jointDef);
	
	// create an invisible static body to attach to
	bodyDef.type = b2_staticBody;
	bodyDef.position = [self toMeters:pos];
	b2Body* staticBody = world->CreateBody(&bodyDef);
	jointDef.Initialize(staticBody, bodyA, bodyA->GetWorldCenter());
	bodyA->GetWorld()->CreateJoint(&jointDef);
}

-(void) addNewSpriteAt:(CGPoint)pos
{
	// Create a body definition and set it to be a dynamic body
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	
	// position must be converted to meters
	bodyDef.position = [self toMeters:pos];
	
	// assign the sprite as userdata so it's easy to get to the sprite when working with the body
	bodyDef.userData = (__bridge void*)[self addRandomSpriteAt:pos];
	b2Body* body = world->CreateBody(&bodyDef);
	
	[self bodyCreateFixture:body];
}

-(void) update:(ccTime)delta
{
	CCDirector* director = [CCDirector sharedDirector];
	if (director.currentPlatformIsIOS)
	{
		KKInput* input = [KKInput sharedInput];
		if (director.currentDeviceIsSimulator == NO)
		{
			KKAcceleration* acceleration = input.acceleration;
			b2Vec2 gravity = 10.0f * b2Vec2(acceleration.rawX, acceleration.rawY);
			world->SetGravity(gravity);
		}

		if (input.anyTouchEndedThisFrame)
		{
			[self addNewSpriteAt:[input locationOfAnyTouchInPhase:KKTouchPhaseEnded]];
		}
	}
	else if (director.currentPlatformIsMac)
	{
		KKInput* input = [KKInput sharedInput];
		if (input.isAnyMouseButtonUpThisFrame || CGPointEqualToPoint(input.scrollWheelDelta, CGPointZero) == NO)
		{
			[self addNewSpriteAt:input.mouseLocation];
		}
	}
	
	// The number of iterations influence the accuracy of the physics simulation. With higher values the
	// body's velocity and position are more accurately tracked but at the cost of speed.
	// Usually for games only 1 position iteration is necessary to achieve good results.
	float timeStep = 0.03f;
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	world->Step(timeStep, velocityIterations, positionIterations);
	
	// for each body, get its assigned sprite and update the sprite's position
	for (b2Body* body = world->GetBodyList(); body != nil; body = body->GetNext())
	{
		CCSprite* sprite = (__bridge CCSprite*)body->GetUserData();
		if (sprite != NULL)
		{
			// update the sprite's position to where their physics bodies are
			sprite.position = [self toPixels:body->GetPosition()];
			float angle = body->GetAngle();
			sprite.rotation = CC_RADIANS_TO_DEGREES(angle) * -1;
		}
	}
}


// convenience method to convert a CGPoint to a b2Vec2
-(b2Vec2) toMeters:(CGPoint)point
{
	return b2Vec2(point.x / PTM_RATIO, point.y / PTM_RATIO);
}

// convenience method to convert a b2Vec2 to a CGPoint
-(CGPoint) toPixels:(b2Vec2)vec
{
	return ccpMult(CGPointMake(vec.x, vec.y), PTM_RATIO);
}


#if DEBUG
-(void) draw
{
	[super draw];

	if (debugDraw)
	{
		// these GL states must be disabled/enabled otherwise drawing debug data will not render and may even crash
		glDisable(GL_TEXTURE_2D);
		glDisableClientState(GL_COLOR_ARRAY);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glEnableClientState(GL_VERTEX_ARRAY);
		
		world->DrawDebugData();
		
		glDisableClientState(GL_VERTEX_ARRAY);   
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glEnableClientState(GL_COLOR_ARRAY);
		glEnable(GL_TEXTURE_2D);	
	}
}
#endif

@end
