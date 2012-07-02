//
//  LHLayer.m
//  ParallaxTimeBased
//
//  Created by Bogdan Vladu on 4/2/12.
//  Copyright (c) 2012 Bogdan Vladu. All rights reserved.
//

#import "LHLayer.h"
#import "LHBatch.h"
#import "LHSprite.h"
#import "LHBezier.h"
#import "LHDictionaryExt.h"
#import "LHSettings.h"
#import "LevelHelperLoader.h"
static int untitledLayersCount = 0;


@interface LHLayer (Private)
-(void)addChildFromDictionary:(NSDictionary*)childDict;
@end


@implementation LHLayer
@synthesize uniqueName;
@synthesize isMainLayer;
//------------------------------------------------------------------------------
-(void)dealloc{
    
   // CCLOG(@"LH Layer Dealloc %@", uniqueName);

#ifndef LH_ARC_ENABLED
    [uniqueName release];
	[super dealloc];
#endif
}
//------------------------------------------------------------------------------
-(id)initWithDictionary:(NSDictionary*)dictionary{
  
    self = [super init];
    if (self != nil)
    {
        isMainLayer = false;
        NSString* uName = [dictionary stringForKey:@"UniqueName"];
        if(uName)
            uniqueName = [[NSString alloc] initWithString:uName];
        else {
            uniqueName = [[NSString alloc] initWithFormat:@"UntitledLayer_%d", untitledLayersCount];
            ++untitledLayersCount;
        }
                
        zOrder_ = [dictionary intForKey:@"ZOrder"];
        
        NSArray* childrenInfo = [dictionary objectForKey:@"Children"];
        for(NSDictionary* childDict in childrenInfo){
            [self addChildFromDictionary:childDict];
        }
    }
    return self;
}
//------------------------------------------------------------------------------
+(id)layerWithDictionary:(NSDictionary*)dictionary{
#ifndef LH_ARC_ENABLED
    return [[[self alloc] initWithDictionary:dictionary] autorelease];
#else
    return [[self alloc] initWithDictionary:dictionary];
#endif        
}
//------------------------------------------------------------------------------
-(void) removeSelf{
    [self removeFromParentAndCleanup:YES];
}
- (void)draw{
    
  //  NSLog(@"MAIN LAYER DRAW");
    [super draw];
    
    if(isMainLayer)
    {
        [[LHSettings sharedInstance] removeMarkedJoints];
        [[LHSettings sharedInstance] removeMarkedSprites];
        [[LHSettings sharedInstance] removeMarkedBeziers];
    }
}
-(void)setParentLoader:(LevelHelperLoader*)p{
    parentLoader = p;
}
//------------------------------------------------------------------------------
-(void)addChildFromDictionary:(NSDictionary*)childDict
{
    if([[childDict stringForKey:@"NodeType"] isEqualToString:@"LHSprite"])
    {
        NSDictionary* texDict = [childDict objectForKey:@"TextureProperties"];
        int sprTag = [texDict intForKey:@"Tag"];
        
        Class spriteClass = [[LHCustomSpriteMgr sharedInstance] customSpriteClassForTag:(LevelHelper_TAG)sprTag];
        LHSprite* sprite = [spriteClass spriteWithDictionary:childDict];
        
        [self addChild:sprite];
        //we use the selector protocol so that we dont get warnings since this method is 
        //hidden from the user
        [sprite performSelector:@selector(setParentLoader:) withObject:parentLoader];
        [sprite postInit];
    }
    else if([[childDict stringForKey:@"NodeType"] isEqualToString:@"LHBezier"])
    {
        LHBezier* bezier = [LHBezier bezierWithDictionary:childDict];
        [self addChild:bezier];
        //we use the selector protocol so that we dont get warnings since this method is 
        //hidden from the user
        [bezier performSelector:@selector(setParentLoader:) withObject:parentLoader];
    }
    else if([[childDict stringForKey:@"NodeType"] isEqualToString:@"LHBatch"]){
        LHBatch* batch = [LHBatch batchWithDictionary:childDict layer:self];
        //it adds self in the layer //this is needed for animations
        //we need to have the layer parent before creating the sprites
        //we use the selector protocol so that we dont get warnings since this method is 
        //hidden from the user
        [batch performSelector:@selector(setParentLoader:) withObject:parentLoader];
    }
    else if([[childDict stringForKey:@"NodeType"] isEqualToString:@"LHLayer"]){
        LHLayer* layer = [LHLayer layerWithDictionary:childDict];
        [self addChild:layer z:[layer zOrder]];
        //we use the selector protocol so that we dont get warnings since this method is 
        //hidden from the user
        [layer performSelector:@selector(setParentLoader:) withObject:parentLoader];
    }
}
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
-(LHLayer*)layerWithUniqueName:(NSString*)name{
    for(id layer in children_){
        if([layer isKindOfClass:[LHLayer class]]){
            if([[(LHLayer*)layer uniqueName] isEqualToString:name])
                return layer;
        }
    }
    
    return nil;
}
//------------------------------------------------------------------------------
-(LHBatch*)batchWithUniqueName:(NSString*)name{
    for(id node in children_){
        if([node isKindOfClass:[LHBatch class]]){
            if([[(LHBatch*)node uniqueName] isEqualToString:name])
                return node;
        }
        else if([node isKindOfClass:[LHLayer class]]){
            id child = [(LHLayer*)node batchWithUniqueName:name];
            if(child)
                return child;
        }
    }
    
    return nil;    
}
//------------------------------------------------------------------------------
-(LHSprite*)spriteWithUniqueName:(NSString*)name{

    for(id node in children_){
        if([node isKindOfClass:[LHSprite class]])
        {
            if([[(LHSprite*)node uniqueName] isEqualToString:name])
                return node;
        }
        else if([node isKindOfClass:[LHBatch class]]){
            id child = [node spriteWithUniqueName:name];
            if(child)
                return child;
        }
        else if([node isKindOfClass:[LHLayer class]]){
            id child = [node spriteWithUniqueName:name];
            if(child)
                return child;
        }
    }
    
    return nil;    
}
//------------------------------------------------------------------------------
-(LHBezier*)bezierWithUniqueName:(NSString*)name{
    for(id node in children_){
        if([node isKindOfClass:[LHBezier class]]){
            if([[node uniqueName] isEqualToString:name])
                return node;
        }
        else if([node isKindOfClass:[LHLayer class]]){
            id child = [node bezierWithUniqueName:name];
            if(child)
                return child;
        }
    }
    
    return nil;    
}
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
-(NSArray*)allLayers{
    NSMutableArray* array = [NSMutableArray array];
    
    for(id layer in children_){
        if([layer isKindOfClass:[LHLayer class]]){
            [array addObject:layer];
        }
    }
    return array;
}
//------------------------------------------------------------------------------
-(NSArray*)allBatches{
    
    NSMutableArray* array = [NSMutableArray array];
    
    for(id node in children_){
        if([node isKindOfClass:[LHBatch class]]){
            [array addObject:node];
        }
        else if([node isKindOfClass:[LHLayer class]]){
            [array addObjectsFromArray:[node allBatches]];
        }
    }
    
    return array;   
}
//------------------------------------------------------------------------------
-(NSArray*)allSprites{

    NSMutableArray* array = [NSMutableArray array];
    
    for(id node in children_){
        if([node isKindOfClass:[LHSprite class]]){
            [array addObject:node];
        }
        else if([node isKindOfClass:[LHBatch class]]){
            [array addObjectsFromArray:[(LHBatch*)node allSprites]];
        }
        else if([node isKindOfClass:[LHLayer class]]){
            [array addObjectsFromArray:[(LHLayer*)node allSprites]];
        }
    }
    return array;    
}
//------------------------------------------------------------------------------
-(NSArray*)allBeziers{

    NSMutableArray* array = [NSMutableArray array];
    
    for(id node in children_){
        if([node isKindOfClass:[LHBezier class]]){
            [array addObject:node];
        }
        else if([node isKindOfClass:[LHLayer class]]){
            [array addObjectsFromArray:[(LHLayer*)node allBeziers]];
        }
    }
    
    return array;    
}
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
-(NSArray*)layersWithTag:(int)tag{
   
    NSMutableArray* array = [NSMutableArray array];
    
    for(id layer in children_){
        if([layer isKindOfClass:[LHLayer class]]){
            if([(CCNode*)layer tag] == tag)
                [array addObject:layer];
        }
    }
    return array;
}
//------------------------------------------------------------------------------
-(NSArray*)batchesWithTag:(int)tag{
    NSMutableArray* array = [NSMutableArray array];
    
    for(id node in children_){
        if([node isKindOfClass:[LHBatch class]]){
            if([(CCNode*)node tag] == tag)
                [array addObject:node];
        }
        else if([node isKindOfClass:[LHLayer class]]){
            [array addObjectsFromArray:[(LHLayer*)node batchesWithTag:tag]];
        }
    }
    
    return array;       
}
-(NSArray*)spritesWithTag:(int)tag{
    NSMutableArray* array = [NSMutableArray array];
    
    for(id node in children_){
        if([node isKindOfClass:[LHSprite class]]){
            if([(CCNode*)node tag] == tag)
                [array addObject:node];
        }
        else if([node isKindOfClass:[LHBatch class]]){
            [array addObjectsFromArray:[(LHBatch*)node spritesWithTag:tag]];
        }
        else if([node isKindOfClass:[LHLayer class]]){
            [array addObjectsFromArray:[(LHLayer*)node spritesWithTag:tag]];
        }
    }
    return array;    
}
-(NSArray*)beziersWithTag:(int)tag{
    NSMutableArray* array = [NSMutableArray array];
    
    for(id node in children_){
        if([node isKindOfClass:[LHBezier class]]){
            if([(CCNode*)node tag] == tag)
                [array addObject:node];
        }
        else if([node isKindOfClass:[LHLayer class]]){
            [array addObjectsFromArray:[(LHLayer*)node beziersWithTag:tag]];
        }
    }
    
    return array;     
}

@end
