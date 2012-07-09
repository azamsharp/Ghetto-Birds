//
//  GameLayer.m
//  Ghetto360iDev
//
//  Created by Mohammad Azam on 6/30/12.
//  Copyright (c) 2012 HighOnCoding. All rights reserved.
//

#import "GameLayer.h"

@implementation GameLayer

const float32 FIXED_TIMESTEP = 1.0f / 60.0f;
const float32 MINIMUM_TIMESTEP = 1.0f / 600.0f;  
const int32 VELOCITY_ITERATIONS = 8;
const int32 POSITION_ITERATIONS = 8;
const int32 MAXIMUM_NUMBER_OF_STEPS = 25;

////////////////////////////////////////////////////////////////////////////////
-(void)step:(ccTime)dt {
	float32 frameTime = dt;
	int stepsPerformed = 0;
	while ( (frameTime > 0.0) && (stepsPerformed < MAXIMUM_NUMBER_OF_STEPS) ){
		float32 deltaTime = std::min( frameTime, FIXED_TIMESTEP );
		frameTime -= deltaTime;
		if (frameTime < MINIMUM_TIMESTEP) {
			deltaTime += frameTime;
			frameTime = 0.0f;
		}
		world->Step(deltaTime,VELOCITY_ITERATIONS,POSITION_ITERATIONS);
		stepsPerformed++;
		//[self afterStep]; // process collisions and result from callbacks called by the step
	}
	world->ClearForces ();
}

-(void) initializeWorld 
{
    isTouchEnabled_ = YES; 
    
    b2Vec2 gravity = b2Vec2(0.0f, -5.0f);
    bool doSleep = false; 
    world = new b2World(gravity);
    world->SetAllowSleeping(doSleep);
    
    loader = [[LevelHelperLoader alloc] initWithContentOfFile:@"Level1"];
    
    [loader addObjectsToWorld:world cocos2dLayer:self];
    
    [loader useLevelHelperCollisionHandling];
    
    [self schedule: @selector(tick:) interval:1.0f/60.0f];	
    
    if([loader hasPhysicBoundaries])
        [loader createPhysicBoundaries:world];
    
    angryBird = [loader spriteWithUniqueName:@"ghetto_bird"];
    
    // register collisions 
   
    [loader registerBeginOrEndCollisionCallbackBetweenTagA:ANGRY_BIRD andTagB:PIG idListener:self selListener:@selector(collisionBetweenAngryBirdAndPig:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(poofAnimationHasEnded:) 
                                                 name:LHAnimationHasEndedNotification
                                               object:poof];
    
    
    // create parallax
    parallaxNode = [loader parallaxNodeWithUniqueName:@"ColdFrontParallax"];
    
    [parallaxNode setPaused:TRUE];
    
    
}

-(void) collisionBetweenAngryBirdAndPig:(LHContactInfo *) contact
{
    if([contact contactType] == LH_BEGIN_CONTACT) 
    {
        poof = [loader spriteWithUniqueName:@"poof1"];
        poof.position = contact.spriteB.position;
        poof.visible = YES;
        [poof prepareAnimationNamed:@"PoofAnimation" fromSHScene:@"AngryBirdsSpriteHelper"];
        [poof playAnimation];
        
        [contact.spriteB removeSelf];
    }
}


-(void)poofAnimationHasEnded:(NSNotification*) notification
{
    NSLog(@"notification ended");
    
    LHSprite* sprite = [notification object];    
        
    [sprite removeSelf];
}


-(id) init
{
    if ((self = [super init]))
    {
        [self initializeWorld];
    }
    return self;
}

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:[touch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    
    float distance = pow(angryBird.position.x - location.x, 2) + pow(angryBird.position.y - location.y, 2);
    
    distance = sqrt(distance);
    
    if(distance <= 10) 
    {
        
        [angryBird makeDynamic];
        
        angryBird.body->ApplyLinearImpulse(b2Vec2(0.5f,0.25f), angryBird.body->GetWorldCenter());
       
    }

}

-(void) tick: (ccTime) dt
{
	[self step:dt];
    
	//Iterate over the bodies in the physics world
	for (b2Body* b = world->GetBodyList(); b; b = b->GetNext())
	{
		if (b->GetUserData() != NULL) 
        {
			//Synchronize the AtlasSprites position and rotation with the corresponding body
			CCSprite *myActor = (__bridge CCSprite*)b->GetUserData();
            
            if(myActor != 0)
            {
                //THIS IS VERY IMPORTANT - GETTING THE POSITION FROM BOX2D TO COCOS2D
                myActor.position = [LevelHelperLoader metersToPoints:b->GetPosition()];
                myActor.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());		
            }
            
        }	
	}
    
}


@end
