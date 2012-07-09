//
//  LHLayer.h
//  ParallaxTimeBased
//
//  Created by Bogdan Vladu on 4/2/12.
//  Copyright (c) 2012 Bogdan Vladu. All rights reserved.
//

#import "CCLayer.h"

@class LHSprite;
@class LHBatch;
@class LHBezier;
@class LevelHelperLoader;
@interface LHLayer : CCLayer
{
    bool isMainLayer;
    NSString* uniqueName;
    __unsafe_unretained LevelHelperLoader* parentLoader;
}
@property (readonly) NSString* uniqueName;
@property bool isMainLayer;

+(id)layerWithDictionary:(NSDictionary*)dict;

-(void) removeSelf; //will also remove all children

-(LHLayer*)layerWithUniqueName:(NSString*)name; //does not return self
-(LHBatch*)batchWithUniqueName:(NSString*)name;
-(LHSprite*)spriteWithUniqueName:(NSString*)name;
-(LHBezier*)bezierWithUniqueName:(NSString*)name;

-(NSArray*)allLayers; //does not return self
-(NSArray*)allBatches;
-(NSArray*)allSprites;
-(NSArray*)allBeziers;

-(NSArray*)layersWithTag:(int)tag; //does not return self
-(NSArray*)batchesWithTag:(int)tag;
-(NSArray*)spritesWithTag:(int)tag;
-(NSArray*)beziersWithTag:(int)tag;

@end
