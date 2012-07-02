//
//  LHFixture.mm
//
//  Created by Bogdan Vladu on 4/3/12.
//  Copyright (c) 2012 Bogdan Vladu. All rights reserved.
//

#import "LHFixture.h"
#import "LHDictionaryExt.h"
#import "LHSettings.h"
#import "LevelHelperLoader.h"
#import "LHSprite.h"

@implementation LHFixture

@synthesize fixtureName;
@synthesize fixtureID;
//------------------------------------------------------------------------------
-(b2Vec2)transformPoint:(CGPoint)point sprite:(LHSprite*)sprite offset:(CGPoint)offset scale:(CGPoint)scale
{
    float ptm = [[LHSettings sharedInstance] lhPtmRatio];
    
    int flipx = [sprite flipX] ? -1.f : 1.f;
    int flipy = [sprite flipY] ? -1.f : 1.f;    
    point.x *= scale.x*flipx;
    point.y *= scale.y*flipy;
    if([[LHSettings sharedInstance] isHDImage:[sprite imageFile]]){
        point.x *=2.0f;
        point.y *=2.0f;
    }
    return b2Vec2(point.x/ptm, point.y/ptm);
}
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
-(id)initWithDictionary:(NSDictionary*)dictionary 
                   body:(b2Body*)body
                    sprite:(LHSprite*)sprite{

    self = [super init];
    if (self != nil){

        
      //  NSLog(@"Sprite name %@", [sprite uniqueName]);
        
        
        fixtureName = [[NSString alloc] initWithString:[dictionary stringForKey:@"Name"]];
        fixtureID   = [dictionary intForKey:@"Tag"];
                
        int category = [dictionary intForKey:@"Category"];
        int group = [dictionary intForKey:@"Group"];
        int mask = [dictionary intForKey:@"Mask"];
        
        float density = [dictionary floatForKey:@"Density"];
        float friction = [dictionary floatForKey:@"Friction"];
        float restitution= [dictionary floatForKey:@"Restitution"];
        
        bool isCircle = [dictionary boolForKey:@"IsCircle"];
        bool isSensor = [dictionary boolForKey:@"IsSensor"];
        
        CGPoint offset = [dictionary pointForKey:@"LHShapePositionOffset"];
        float width = [dictionary floatForKey:@"LHWidth"];
        float height= [dictionary floatForKey:@"LHHeight"];
        
        NSArray* fixturePoints = [dictionary objectForKey:@"Fixture"];
        
        float ptm = [[LHSettings sharedInstance] lhPtmRatio];
        
        CGPoint scale = ccp(sprite.scaleX,sprite.scaleY);
        int flipx = [sprite flipX] ? -1 : 1;
        int flipy = [sprite flipY] ? -1 : 1;

        for(int i = 0; i < (int)[fixturePoints count]; i += 3)
        {
            
            CGPoint pt0 = LHPointFromString([fixturePoints objectAtIndex:i+0]);
            CGPoint pt1 = LHPointFromString([fixturePoints objectAtIndex:i+1]);
            CGPoint pt2 = LHPointFromString([fixturePoints objectAtIndex:i+2]);
            
            if(sprite.scaleX*flipx*sprite.scaleY*flipy < 0){
                pt0 = LHPointFromString([fixturePoints objectAtIndex:i+2]);
                pt1 = LHPointFromString([fixturePoints objectAtIndex:i+1]);
                pt2 = LHPointFromString([fixturePoints objectAtIndex:i+0]);
            }
            
            b2Vec2 *verts = new b2Vec2[3];
            b2PolygonShape shapeDef;

            verts[0] = [self transformPoint:pt0 sprite:sprite offset:offset scale:scale];
            verts[1] = [self transformPoint:pt1 sprite:sprite offset:offset scale:scale];
            verts[2] = [self transformPoint:pt2 sprite:sprite offset:offset scale:scale];
                        
                
            shapeDef.Set(verts, 3);		
            
            b2FixtureDef fixture;
            //------------------------------------------------------------------
            fixture.density = density;
            fixture.friction = friction;
            fixture.restitution = restitution;
            
            fixture.filter.categoryBits = category;
            fixture.filter.maskBits = mask;
            fixture.filter.groupIndex = group;
            
            fixture.isSensor = isSensor;
            
#ifndef LH_ARC_ENABLED
            fixture.userData = self;
#else
            fixture.userData = (__bridge void*)self;
#endif

            
            //------------------------------------------------------------------            
            fixture.shape = &shapeDef;
            body->CreateFixture(&fixture);
            delete[] verts;
        }
            
        //handle isCircle and quads
        if([fixturePoints count] == 0)
        {
            b2PolygonShape shape;
            b2FixtureDef fixture;
            b2CircleShape circle;

            //------------------------------------------------------------------
            fixture.density = density;
            fixture.friction = friction;
            fixture.restitution = restitution;
            
            fixture.filter.categoryBits = category;
            fixture.filter.maskBits = mask;
            fixture.filter.groupIndex = group;
            
            fixture.isSensor = isSensor;

#ifndef LH_ARC_ENABLED
            fixture.userData = self;
#else
            fixture.userData = (__bridge void*)self;
#endif
                        
            //------------------------------------------------------------------            
            
            CGPoint origin = ccp(offset.x*scale.x*flipx,  -offset.y*scale.y*flipy);
            if([[LHSettings sharedInstance] isHDImage:[sprite imageFile]])
            {
                origin.x *=2.0f;
                origin.y *=2.0f;
            }
            
            if(isCircle)
            {
                if([[LHSettings sharedInstance] convertLevel]){
                    //circle look weird if we dont do this
                    float scaleSpr = [sprite scaleX];
                    [sprite setScaleY:scaleSpr];
                }
                
                float circleScale = scale.x; //if we dont do this we dont have collision
                if(circleScale < 0)
                    circleScale = -circleScale;
                
                float radius = (width*circleScale)/ptm;
                
                if(![[LHSettings sharedInstance] isHDImage:[sprite imageFile]]){
                    radius /=2.0f;
                }

                
                if(radius < 0)
                    radius *= -1;
                circle.m_radius = radius; 
                
                circle.m_p.Set(origin.x/ptm,
                               origin.y/ptm);
                
                fixture.shape = &circle;
                body->CreateFixture(&fixture);
            }
            else
            {
                //this is for the case where no shape is defined and user selects the sprite to have physics inside LH
                b2PolygonShape shape;
                
                float boxWidth = width*scale.x/2.f;
                float boxHeight= height*scale.y/2.f;
                
                shape.SetAsBox(boxWidth/ptm, 
                               boxHeight/ptm);
                                
                shape.SetAsBox(boxWidth/ptm, boxHeight/ptm, b2Vec2(origin.x/ptm, origin.y/ptm), 0);

                
                fixture.shape = &shape;
                body->CreateFixture(&fixture);
            }
        }                
    }
    return self;
}
+(id)fixtureWithDictionary:(NSDictionary*)dictionary 
                      body:(b2Body*)body                     
                    sprite:(LHSprite*)sprite
{
#ifndef LH_ARC_ENABLED
    return [[[self alloc] initWithDictionary:dictionary body:body sprite:sprite] autorelease];
#else
    return [[self alloc] initWithDictionary:dictionary body:body sprite:sprite];
#endif     
}
//------------------------------------------------------------------------------
-(void)dealloc{

    //NSLog(@"LH FIXTURE DEALLOC %@", fixtureName);
#ifndef LH_ARC_ENABLED
    [fixtureName release];
	[super dealloc];
#endif
}
//------------------------------------------------------------------------------
@end
