//
//  LHCuttingEngineMgr.h
//  LevelHelperExplodingSprites
//
//  Created by Bogdan Vladu on 3/10/12.
//  Copyright (c) 2012 Bogdan Vladu. All rights reserved.
//

#include "Box2D.h"
#include <vector>
@class LHSprite;

@interface LHCuttingEngineMgr : NSObject
{
    std::vector<CGPoint> explosionLines;
    
    NSMutableSet* spritesPreviouslyCut;//keep reference so we can remove them
    //because if we let cocos2d to remove then the box2d world is already destroyed and so we will have a crash
}

+(LHCuttingEngineMgr*) sharedInstance;

-(void)destroyAllPrevioslyCutSprites;

//returns an array of new LHSprite* objects or nil if no other sprite is created from the split action
//location must be inside the sprite

//will triangulate only fixture under point - all other fixtures in the body
//will remain the same
-(void) splitSprite:(LHSprite *)oldSprite atPoint:(CGPoint)location;

//will triangulate all fixtures based on your decision
//will not create bodies that have mass smaller then mass - this will improve performance
//usually mass smaller then 0.04 - 0.06 can be ignore - play with this value until it suit your needs
-(void) splitSprite:(LHSprite *)oldSprite 
                atPoint:(CGPoint)location 
 triangulateAllFixtures:(bool)triangulate
      ignoreSmallerMass:(float)mass;


//returns an array of new LHSprite* objects or nil if no other sprite is created from the cut action
-(void)cutFirstSpriteIntersectedByLine:(CGPoint)lineA 
                                 lineB:(CGPoint)lineB
                             fromWorld:(b2World*)world;

-(void)cutFirstSpriteWithTag:(int)tag
           intersectedByLine:(CGPoint)lineA 
                       lineB:(CGPoint)lineB
                   fromWorld:(b2World*)world;

-(void)cutSprite:(LHSprite*)oldSprite
           withLineA:(CGPoint)lineA
               lineB:(CGPoint)lineB;

//returns an array of new LHSprite* objects or nil if no other sprite is created from the cut action
-(void)cutAllSpritesIntersectedByLine:(CGPoint)lineA
                                lineB:(CGPoint)lineB
                            fromWorld:(b2World*)world;

-(void)cutAllSpritesWithTag:(int)tag
          intersectedByLine:(CGPoint)lineA
                      lineB:(CGPoint)lineB
                  fromWorld:(b2World*)world;


//sprites inside the radius will be cut randomly
//call [[LHCuttingEngineMgr shareInstance] debugDrawing] to see how explosion is performed
-(void)cutSpritesFromPoint:(CGPoint)point
                  inRadius:(float)radius
                      cuts:(int)numberOfCuts //must be even
                 fromWorld:(b2World*)world;

-(void)cutSpritesWithTag:(int)tag
               fromPoint:(CGPoint)point
                inRadius:(float)radius
                    cuts:(int)numberOfCuts //must be even
                fromWorld:(b2World*)world;

//-(NSArray*)cutSprite:(LHSprite*)oldSprite
//           fromPoint:(CGPoint)point
//            inRadius:(float)radius
//                cuts:(int)numberOfCuts; // must be even


-(void) explodeSpritesInRadius:(float)radius
                     withForce:(float)maxForce
                      position:(CGPoint)pos
                       inWorld:(b2World*)world;

-(void) implodeSpritesInRadius:(float)radius
                     withForce:(float)maxForce
                      position:(CGPoint)pos
                       inWorld:(b2World*)world;

//use this only for debuging - performance is slow
-(void)debugDrawing;

@end
