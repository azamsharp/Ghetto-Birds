//  http://www.levelhelper.org
//
//  Created by Bogdan Vladu
//  Copyright 2011 Bogdan Vladu. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//  The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//  Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//  This notice may not be removed or altered from any source distribution.
//  By "software" the author refers to this code file and not the application 
//  that was used to generate this file.
//  You do not have permission to use this code or any part of it if you don't
//  own a license to LevelHelper application.

#import "LevelHelperLoader.h"
#import <Foundation/Foundation.h>
#import "LHSettings.h"
#import "LHDictionaryExt.h"


#import "SHDocumentLoader.h"

@interface LHSprite (LH_SPRITE_LOADER_PARENT) 
//-(void)setParentLoader:(LevelHelperLoader*)loader;
-(void)setTagTouchBeginObserver:(LHObserverPair*)pair;
-(void)setTagTouchMovedObserver:(LHObserverPair*)pair;
-(void)setTagTouchEndedObserver:(LHObserverPair*)pair;
-(bool)pathDefaultStartAtLaunch;
//-(void) removeFromCocos2dParentNode:(BOOL)cleanup; //added in order to send ERROR message to user in the overloaded LHSprite removeFromParentAndCleanUp method
@end
@implementation LHSprite (LH_SPRITE_LOADER_PARENT)
//-(void)setParentLoader:(LevelHelperLoader*)loader{
//    parentLoader = loader;   
//}
-(void)setTagTouchBeginObserver:(LHObserverPair*)pair{
    tagTouchBeginObserver = pair;
}
-(void)setTagTouchMovedObserver:(LHObserverPair*)pair{
    tagTouchMovedObserver = pair;
}
-(void)setTagTouchEndedObserver:(LHObserverPair*)pair{
    tagTouchEndedObserver = pair;
}
-(bool)pathDefaultStartAtLaunch{
    return pathStartAtLaunch;
}
//-(void) removeFromCocos2dParentNode:(BOOL)cleanup{
//    [super removeFromParentAndCleanup:cleanup];
//}
@end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
@interface LHBezier (LH_BEZIER_LOADER_PARENT) 
-(void)setTagTouchBeginObserver:(LHObserverPair*)pair;
-(void)setTagTouchMovedObserver:(LHObserverPair*)pair;
-(void)setTagTouchEndedObserver:(LHObserverPair*)pair;
@end
@implementation LHBezier (LH_BEZIER_LOADER_PARENT)
-(void)setTagTouchBeginObserver:(LHObserverPair*)pair{
    tagTouchBeginObserver = pair;
}
-(void)setTagTouchMovedObserver:(LHObserverPair*)pair{
    tagTouchMovedObserver = pair;
}
-(void)setTagTouchEndedObserver:(LHObserverPair*)pair{
    tagTouchEndedObserver = pair;
}
@end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
@interface LHParallaxNode (LH_PARALLAX_LOADER_PARENT) 
-(void) setRemoveChildSprites:(bool)val;
@end
@implementation LHParallaxNode (LH_PARALLAX_LOADER_PARENT)
-(void) setRemoveChildSprites:(bool)val{
    removeSpritesOnDelete = val;
}
@end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------



//------------------------------------------------------------------------------


#if TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
CGSize  LHSizeFromString(NSString* val){
    return CGSizeFromString(val);
}
CGPoint LHPointFromValue(NSValue* val){
    return [val CGPointValue];
}
NSValue* LHValueWithCGPoint(CGPoint pt){
    return [NSValue valueWithCGPoint:pt];
}

CGPoint LHPointFromString(NSString* val){
    return CGPointFromString(val);
}

CGRect LHRectFromString(NSString* val){
    return CGRectFromString(val);
}
#else
CGPoint LHPointFromValue(NSValue* val){
    NSPoint pt = [val pointValue];
    return CGPointMake(pt.x, pt.y);
}
NSValue* LHValueWithCGPoint(CGPoint pt){
    return [NSValue valueWithPoint:NSMakePoint(pt.x, pt.y)];
}
CGPoint LHPointFromString(NSString* val){
    NSPoint pt = NSPointFromString(val);
    return CGPointMake(pt.x, pt.y);
}
CGRect LHRectFromString(NSString* val){
    NSRect rect = NSRectFromString(val);
    return CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}
CGSize  LHSizeFromString(NSString* val){
    NSSize size = NSSizeFromString(val);
    return CGSizeMake(size.width, size.height);
}
#endif


////////////////////////////////////////////////////////////////////////////////
@interface LevelHelperLoader (Private)
-(void) createAllNodes;
-(void) createAllJoints;
-(void) startAllPaths;
-(void) createParallaxes;
//------------------------------------------------------------------------------
-(void)loadLevelHelperSceneFile:(NSString*)levelFile 
					inDirectory:(NSString*)subfolder
				   imgSubfolder:(NSString*)imgFolder;

-(void) loadLevelHelperSceneFromDictionary:(NSDictionary*)levelDictionary 
							  imgSubfolder:(NSString*)imgFolder;

-(void)loadLevelHelperSceneFileFromWebAddress:(NSString*)webaddress;

-(void)processLevelFileFromDictionary:(NSDictionary*)dictionary;

@end

@implementation LevelHelperLoader

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
-(void) initObjects{
    
    jointsInLevel = [[NSMutableDictionary alloc] init];
    parallaxesInLevel = [[NSMutableDictionary alloc] init];
    physicBoundariesInLevel = [[NSMutableDictionary alloc] init];
    
    imageFolder = [[NSMutableString alloc] init];
    
	[[LHSettings sharedInstance] setLhPtmRatio:32.0f];
}
////////////////////////////////////////////////////////////////////////////////
-(id) initWithContentOfFile:(NSString*)levelFile
{
	NSAssert(nil!=levelFile, @"Invalid file given to LevelHelperLoader");
	if(!(self = [super init])){
		NSLog(@"LevelHelperLoader ****ERROR**** : [super init] failer ***");
		return self;
	}
	
	[self initObjects];
	[self loadLevelHelperSceneFile:levelFile inDirectory:@"" imgSubfolder:@""];
	
	return self;
}
////////////////////////////////////////////////////////////////////////////////
-(id) initWithContentOfFileFromInternet:(NSString*)webAddress
{
	NSAssert(nil!=webAddress, @"Invalid file given to LevelHelperLoader");
	
	if(!(self = [super init])){
		NSLog(@"LevelHelperLoader ****ERROR**** : [super init] failer ***");
		return self;
	}
	
	[self initObjects];
	[self loadLevelHelperSceneFileFromWebAddress:webAddress];
	
	return self;
}
////////////////////////////////////////////////////////////////////////////////
-(id) initWithContentOfFile:(NSString*)levelFile 
			 levelSubfolder:(NSString*)levelFolder
{
	NSAssert(nil!=levelFile, @"Invalid file given to LevelHelperLoader");
	
	if(!(self = [super init])){
		NSLog(@"LevelHelperLoader ****ERROR**** : [super init] failer ***");
		return self;
	}
	
	[self initObjects];
	[self loadLevelHelperSceneFile:levelFile inDirectory:levelFolder imgSubfolder:@""];
	
	return self;	
}
////////////////////////////////////////////////////////////////////////////////
-(void)registerLoadingProgressObserver:(id)object selector:(SEL)selector{
    loadingProgressId = object;
    loadingProgressSel = selector;
}
//------------------------------------------------------------------------------
-(void) callLoadingProgressObserverWithValue:(float)val
{
    if(loadingProgressId != nil && loadingProgressSel != nil)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [loadingProgressId performSelector:loadingProgressSel 
                                withObject:[NSNumber numberWithFloat:val]];
#pragma clang diagnostic pop
    }
}
////////////////////////////////////////////////////////////////////////////////
-(id) initWithContentOfFileAtURL:(NSURL*)levelURL imagesPath:(NSString*)imgFolder
{
    NSAssert(nil!=levelURL, @"Invalid URL given to LevelHelperLoader");
	
	if(!(self = [super init])){
		NSLog(@"LevelHelperLoader ****ERROR**** : [super init] failer ***");
		return self;
	}
	
	[self initObjects];
    NSDictionary* levelDictionary = [NSDictionary dictionaryWithContentsOfURL:levelURL];
	[self loadLevelHelperSceneFromDictionary:levelDictionary imgSubfolder:imgFolder];
	
	return self;	

}
-(id) initWithContentOfDictionary:(NSDictionary*)levelDictionary
					  imageFolder:(NSString*)imgFolder;
{
	NSAssert(nil!=levelDictionary, @"Invalid dictionary given to LevelHelperLoader");
	
	if(!(self = [super init])){
		NSLog(@"LevelHelperLoader ****ERROR**** : [super init] failer ***");
		return self;
	}
	
	[self initObjects];
    
//    NSLog(@"IAMGE FOLDER %@", imgFolder);
    
	[self loadLevelHelperSceneFromDictionary:levelDictionary imgSubfolder:imgFolder];
	
	return self;	
}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
-(void) addObjectsToWorld:(b2World*)world 
			 cocos2dLayer:(CCLayer*)_cocosLayer
{	
	cocosLayer = _cocosLayer;
    box2dWorld = world;
    [[LHSettings sharedInstance] setActiveBox2dWorld:world];
	
    //order is important  
    [self callLoadingProgressObserverWithValue:0.10];
    [self createAllNodes];
    [self callLoadingProgressObserverWithValue:0.70f];    
    [self createAllJoints];
    [self callLoadingProgressObserverWithValue:0.80f];    
    [self createParallaxes];
    [self callLoadingProgressObserverWithValue:0.90f];    
    [self startAllPaths];
    [self callLoadingProgressObserverWithValue:1.0f];
}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
+(bool)isPaused{
    return [[LHSettings sharedInstance] levelPaused];
}
+(void)setPaused:(bool)value{
    [[LHSettings sharedInstance] setLevelPaused:value];    
}
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
+(void) dontStretchArtOnIpad{
    [[LHSettings sharedInstance] setStretchArt:false];
}
+(void) useRetinaOnIpad:(bool)useRet{
    [[LHSettings sharedInstance] setUseRetinaOnIpad:useRet];
}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
-(LHLayer*)layerWithUniqueName:(NSString*)name{
    if([[mainLHLayer uniqueName] isEqualToString:name])
        return mainLHLayer;
    return [mainLHLayer layerWithUniqueName:name];
}
-(LHBatch*)batchWithUniqueName:(NSString*)name{
    return [mainLHLayer batchWithUniqueName:name];
}
-(LHSprite*)spriteWithUniqueName:(NSString*)name{
    return [mainLHLayer spriteWithUniqueName:name];
}
-(LHBezier*)bezierWithUniqueName:(NSString*)name{
    return [mainLHLayer bezierWithUniqueName:name];
}
-(LHJoint*) jointWithUniqueName:(NSString*)name{
    return [jointsInLevel objectForKey:name];
}
//------------------------------------------------------------------------------
-(NSArray*)allLayers{
    NSMutableArray* array = [NSMutableArray array];
    //[array addObject:mainLHLayer];//we dont give user access to the main lh layer
    [array addObjectsFromArray:[mainLHLayer allLayers]];
    return array;
}
-(NSArray*)allBatches{
    return [mainLHLayer allBatches];
}
-(NSArray*)allSprites{
    return [mainLHLayer allSprites];
}
-(NSArray*)allBeziers{
    return [mainLHLayer allBeziers];
}
-(NSArray*) allJoints{
    return [jointsInLevel allValues];
}
//------------------------------------------------------------------------------
-(NSArray*)layersWithTag:(enum LevelHelper_TAG)tag{
    NSMutableArray* array = [NSMutableArray array];
    if(tag == [mainLHLayer tag])
        [array addObject:mainLHLayer];
    [array addObjectsFromArray:[mainLHLayer layersWithTag:tag]];
    return array;    
}
-(NSArray*)batchesWithTag:(enum LevelHelper_TAG)tag{
    return [mainLHLayer batchesWithTag:tag];
}
-(NSArray*)spritesWithTag:(enum LevelHelper_TAG)tag{
    return [mainLHLayer spritesWithTag:tag];
}
-(NSArray*)beziersWithTag:(enum LevelHelper_TAG)tag{
    return [mainLHLayer beziersWithTag:tag];
}
-(NSArray*) jointsWithTag:(enum LevelHelper_TAG)tag{
    NSMutableArray* jointsWithTag = [NSMutableArray array];
	NSArray* joints = [jointsInLevel allValues];
	for(LHJoint* jt in joints){
        if([jt tag] == tag){
            [jointsWithTag addObject:jt];
        }
	}
    return jointsWithTag;
}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
-(NSDictionary*)dictionaryInfoForSpriteNodeNamed:(NSString*)name 
                                    inDictionary:(NSDictionary*)dict{
        
    NSArray* children = [dict objectForKey:@"Children"];
    
    if(nil != children)
    {
        for(NSDictionary* childDict in children)
        {
            NSString* nodeType = [childDict stringForKey:@"NodeType"];
           if([nodeType isEqualToString:@"LHSprite"])
           {
               if([[childDict stringForKey:@"UniqueName"] isEqualToString:name])
               {
                   return childDict;
               }
           }
           else if([nodeType isEqualToString:@"LHBatch"] ||
                   [nodeType isEqualToString:@"LHLayer"])
           {
               NSDictionary* retDict = [self dictionaryInfoForSpriteNodeNamed:name 
                                                                 inDictionary:childDict];
               if(retDict)
                   return retDict;
           }
        }
    }
    
    return nil;
}
//------------------------------------------------------------------------------
-(LHSprite*) createSpriteWithUniqueName:(NSString *)name{
   return [self createSpriteWithUniqueName:name parent:mainLHLayer];
}
-(LHSprite*) createSpriteWithUniqueName:(NSString *)name parent:(CCNode*)node{
    for(NSDictionary* dictionary in lhNodes){        
        NSDictionary* spriteInfo = [self dictionaryInfoForSpriteNodeNamed:name 
                                                             inDictionary:dictionary];
        if(spriteInfo){
            
            NSDictionary* texDict = [spriteInfo objectForKey:@"TextureProperties"];
            int tag = [texDict intForKey:@"Tag"];
            Class spriteClass = [[LHCustomSpriteMgr sharedInstance] customSpriteClassForTag:(LevelHelper_TAG)tag];
            LHSprite* spr = [spriteClass spriteWithDictionary:spriteInfo];
            if(spr && node)
                [node addChild:spr z:[spr zOrder]];
            return spr;
        }
    }
    return nil;
}

-(LHSprite*) createBatchSpriteWithUniqueName:(NSString*)name{
    for(NSDictionary* dictionary in lhNodes){        
        NSDictionary* spriteInfo = [self dictionaryInfoForSpriteNodeNamed:name 
                                                             inDictionary:dictionary];
        if(spriteInfo){
            LHBatch* batch = [self batchWithUniqueName:[spriteInfo stringForKey:@"ParentName"]];
            if(batch){                
                NSDictionary* texDict = [spriteInfo objectForKey:@"TextureProperties"];
                int tag = [texDict intForKey:@"Tag"];
                Class spriteClass = [[LHCustomSpriteMgr sharedInstance] customSpriteClassForTag:(LevelHelper_TAG)tag];
                return [spriteClass batchSpriteWithDictionary:spriteInfo batch:batch];
            }
        }
    }
    return nil;    
}


-(LHSprite*) createSpriteWithName:(NSString*)name 
                        fromSheet:(NSString*)sheetName
                       fromSHFile:(NSString*)sceneName{

    return [self createSpriteWithName:name
                            fromSheet:sheetName
                           fromSHFile:sceneName
                               parent:mainLHLayer];
}

-(LHSprite*) createSpriteWithName:(NSString*)name 
                        fromSheet:(NSString*)sheetName
                       fromSHFile:(NSString*)shFileNoExt
                           parent:(CCNode*)node{
    
    LHSprite* sprite = [LHSprite spriteWithName:name 
                                      fromSheet:sheetName 
                                         SHFile:shFileNoExt];
    if(sprite && node)
        [node addChild:sprite];
    return sprite;
}


-(LHSprite*) createSpriteWithName:(NSString*)name 
                        fromSheet:(NSString*)sheetName
                       fromSHFile:(NSString*)shFileNoExt 
                              tag:(LevelHelper_TAG)tag{
        
    return [self createSpriteWithName:name 
                            fromSheet:sheetName
                           fromSHFile:shFileNoExt 
                                  tag:tag
                               parent:mainLHLayer];    
}

-(LHSprite*) createSpriteWithName:(NSString*)name 
                        fromSheet:(NSString*)sheetName
                       fromSHFile:(NSString*)shFileNoExt 
                              tag:(LevelHelper_TAG)tag
                           parent:(CCNode*)node{
    NSDictionary* dictionary = [[SHDocumentLoader sharedInstance] dictionaryForSpriteNamed:name 
                                                                              inSheetNamed:sheetName 
                                                                                inDocument:shFileNoExt];
    if(dictionary)
    {
        Class spriteClass = [[LHCustomSpriteMgr sharedInstance] customSpriteClassForTag:(LevelHelper_TAG)tag];
        
        LHSprite* sprite = [spriteClass spriteWithDictionary:dictionary];
        
        if(sprite){
            [sprite setTag:tag];
            if(node){
                [node addChild:sprite];
            }
        }
        return sprite;
    }
    return nil;
}


-(LHSprite*) createBatchSpriteWithName:(NSString*)name 
                             fromSheet:(NSString*)sheetName
                            fromSHFile:(NSString*)shFileNoExt{
    
    NSDictionary* dictionary = [[SHDocumentLoader sharedInstance] dictionaryForSpriteNamed:name 
                                                                              inSheetNamed:sheetName 
                                                                                inDocument:shFileNoExt];
    if(dictionary){
        LHBatch* batch = [self batchWithUniqueName:[dictionary stringForKey:@"SHSheetName"]];
        if(!batch){
            batch = [LHBatch batchWithSheetName:sheetName shFile:shFileNoExt];
            [mainLHLayer addChild:batch z:batch.zOrder];
        }
        if(batch)
            return [LHSprite batchSpriteWithDictionary:dictionary batch:batch];
    }
    return nil;
}

-(LHSprite*) createBatchSpriteWithName:(NSString*)name 
                             fromSheet:(NSString*)sheetName
                            fromSHFile:(NSString*)shFileNoExt 
                                   tag:(LevelHelper_TAG)tag{
    
    NSDictionary* dictionary = [[SHDocumentLoader sharedInstance] dictionaryForSpriteNamed:name 
                                                                              inSheetNamed:sheetName 
                                                                                inDocument:shFileNoExt];
    if(dictionary){
        LHBatch* batch = [self batchWithUniqueName:[dictionary stringForKey:@"SHSheetName"]];
        if(!batch){
            batch = [LHBatch batchWithSheetName:sheetName shFile:shFileNoExt];
            [mainLHLayer addChild:batch z:batch.zOrder];
        }
        if(batch)
        {
            Class spriteClass = [[LHCustomSpriteMgr sharedInstance] customSpriteClassForTag:(LevelHelper_TAG)tag];            
            LHSprite* spr = [spriteClass batchSpriteWithDictionary:dictionary batch:batch];
            if(spr)
                [spr setTag:tag];
            return spr;
        }
    }
    return nil;
}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
-(void) useLevelHelperCollisionHandling{
    if(0 == box2dWorld){
        NSLog(@"LevelHelper WARNING: Please call useLevelHelperCollisionHandling after addObjectsToWorld");
        return;
    }
    
    contactNode = [LHContactNode contactNodeWithWorld:box2dWorld];
    if(nil != cocosLayer){
        [cocosLayer addChild:contactNode];
    }
}
//------------------------------------------------------------------------------
-(void) registerBeginOrEndCollisionCallbackBetweenTagA:(enum LevelHelper_TAG)tagA
                                          andTagB:(enum LevelHelper_TAG)tagB
                                       idListener:(id)obj
                                      selListener:(SEL)selector{
    if(nil == contactNode){
        NSLog(@"LevelHelper WARNING: Please call registerPreColisionCallbackBetweenTagA after useLevelHelperCollisionHandling");
    }
    [contactNode registerBeginOrEndColisionCallbackBetweenTagA:(int)tagA 
                                                  andTagB:(int)tagB 
                                               idListener:obj 
                                              selListener:selector];

}
-(void) cancelBeginOrEndCollisionCallbackBetweenTagA:(enum LevelHelper_TAG)tagA
                                        andTagB:(enum LevelHelper_TAG)tagB{
    if(nil == contactNode){
        NSLog(@"LevelHelper WARNING: Please call registerPreColisionCallbackBetweenTagA after useLevelHelperCollisionHandling");
    }
    [contactNode cancelBeginOrEndColisionCallbackBetweenTagA:(int)tagA 
                                                andTagB:(int)tagB];

}

-(void) registerPreCollisionCallbackBetweenTagA:(enum LevelHelper_TAG)tagA 
                                    andTagB:(enum LevelHelper_TAG)tagB 
                                 idListener:(id)obj 
                                selListener:(SEL)selector{

    if(nil == contactNode){
        NSLog(@"LevelHelper WARNING: Please call registerPreColisionCallbackBetweenTagA after useLevelHelperCollisionHandling");
    }
    [contactNode registerPreColisionCallbackBetweenTagA:(int)tagA 
                                                andTagB:(int)tagB 
                                             idListener:obj 
                                            selListener:selector];
}
//------------------------------------------------------------------------------
-(void) cancelPreCollisionCallbackBetweenTagA:(enum LevelHelper_TAG)tagA 
                                      andTagB:(enum LevelHelper_TAG)tagB
{
    if(nil == contactNode){
        NSLog(@"LevelHelper WARNING: Please call registerPreColisionCallbackBetweenTagA after useLevelHelperCollisionHandling");
    }
    [contactNode cancelPreColisionCallbackBetweenTagA:(int)tagA 
                                              andTagB:(int)tagB];
}
//------------------------------------------------------------------------------
-(void) registerPostCollisionCallbackBetweenTagA:(enum LevelHelper_TAG)tagA 
                                        andTagB:(enum LevelHelper_TAG)tagB 
                                     idListener:(id)obj 
                                    selListener:(SEL)selector{
    if(nil == contactNode){
        NSLog(@"LevelHelper WARNING: Please call registerPostColisionCallbackBetweenTagA after useLevelHelperCollisionHandling");
    }
    [contactNode registerPostColisionCallbackBetweenTagA:(int)tagA 
                                                 andTagB:(int)tagB 
                                              idListener:obj 
                                             selListener:selector];
    
}
//------------------------------------------------------------------------------
-(void) cancelPostCollisionCallbackBetweenTagA:(enum LevelHelper_TAG)tagA 
                                      andTagB:(enum LevelHelper_TAG)tagB
{
    if(nil == contactNode){
        NSLog(@"LevelHelper WARNING: Please call registerPreColisionCallbackBetweenTagA after useLevelHelperCollisionHandling");
    }
    [contactNode cancelPostColisionCallbackBetweenTagA:(int)tagA 
                                              andTagB:(int)tagB];
}
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
-(CGSize) gameScreenSize{
    return CGSizeMake(safeFrame.x, safeFrame.y);
}
//------------------------------------------------------------------------------
-(CGRect) gameWorldSize{
    CGPoint  wbConv = [[LHSettings sharedInstance] convertRatio];
	
    CGRect ws = gameWorldRect;
    
    ws.origin.x *= wbConv.x;
    ws.origin.y *= wbConv.y;
    ws.size.width *= wbConv.x;
    ws.size.height *= wbConv.y;
    
    return ws;
}
//------------------------------------------------------------------------------
-(void) dealloc{  
    
   NSLog(@"LH DEALLOC");

    [[LHCuttingEngineMgr sharedInstance] destroyAllPrevioslyCutSprites];
    [[LHTouchMgr sharedInstance] removeTouchBeginObserver:cocosLayer];
    
    [[LHSettings sharedInstance] removeLHMainLayer:mainLHLayer];
    
    
    [parallaxesInLevel removeAllObjects];
    [jointsInLevel removeAllObjects];
    [physicBoundariesInLevel removeAllObjects];
    
    [mainLHLayer removeAllChildrenWithCleanup:YES];
    
    [mainLHLayer removeSelf];
    mainLHLayer = nil;
    
    if(nil != contactNode){
        [contactNode removeFromParentAndCleanup:YES];
    }
#ifndef LH_ARC_ENABLED
    [lhNodes release];
    [lhJoints release];
    [lhParallax release];

    [jointsInLevel release];
    [parallaxesInLevel release];
    
    [physicBoundariesInLevel release];
    [imageFolder release];
    [super dealloc];
#endif
}
////////////////////////////////////////////////////////////////////////////////
//GRAVITY
////////////////////////////////////////////////////////////////////////////////
-(bool) isGravityZero{
    if(gravity.x == 0 && gravity.y == 0)
        return true;
    return false;
}
//------------------------------------------------------------------------------
-(void) createGravity:(b2World*)world{
	if([self isGravityZero])
		NSLog(@"LevelHelper Warning: Gravity is not defined in the level. Are you sure you want to set a zero gravity?");
    world->SetGravity(b2Vec2(gravity.x, gravity.y));
}
////////////////////////////////////////////////////////////////////////////////
//PHYSIC BOUNDARIES
////////////////////////////////////////////////////////////////////////////////
-(b2Body*)physicBoundarieForKey:(NSString*)key{
    LHSprite* spr = [physicBoundariesInLevel objectForKey:key];
    if(nil == spr)
        return 0;
    return [spr body];
}
//------------------------------------------------------------------------------
-(b2Body*) leftPhysicBoundary{
    return [self physicBoundarieForKey:@"LHPhysicBoundarieLeft"];
}
-(LHSprite*) leftPhysicBoundarySprite{
    return [physicBoundariesInLevel objectForKey:@"LHPhysicBoundarieLeft"];
}
//------------------------------------------------------------------------------
-(b2Body*) rightPhysicBoundary{
	return [self physicBoundarieForKey:@"LHPhysicBoundarieRight"];
}
-(LHSprite*) rightPhysicBoundarySprite{
    return [physicBoundariesInLevel objectForKey:@"LHPhysicBoundarieRight"];
}
//------------------------------------------------------------------------------
-(b2Body*) topPhysicBoundary{
    return [self physicBoundarieForKey:@"LHPhysicBoundarieTop"];
}
-(LHSprite*) topPhysicBoundarySprite{
    return [physicBoundariesInLevel objectForKey:@"LHPhysicBoundarieTop"];
}
//------------------------------------------------------------------------------
-(b2Body*) bottomPhysicBoundary{
    return [self physicBoundarieForKey:@"LHPhysicBoundarieBottom"];
}
-(LHSprite*) bottomPhysicBoundarySprite{
    return [physicBoundariesInLevel objectForKey:@"LHPhysicBoundarieBottom"];
}
//------------------------------------------------------------------------------
-(bool) hasPhysicBoundaries{
	if(wb == nil){
		return false;
	}
    CGRect rect = [wb rectForKey:@"WBRect"];    
    if(rect.size.width == 0 || rect.size.height == 0)
        return false;
	return true;
}
//------------------------------------------------------------------------------
-(CGRect) physicBoundariesRect{
    CGPoint  wbConv = [[LHSettings sharedInstance] convertRatio];
    CGRect rect = [wb rectForKey:@"WBRect"];    
    rect.origin.x = rect.origin.x*wbConv.x,
    rect.origin.y = rect.origin.y*wbConv.y;
    rect.size.width = rect.size.width*wbConv.x;
    rect.size.height= rect.size.height*wbConv.y;
    return rect;
}
//------------------------------------------------------------------------------
-(void) setFixtureDefPropertiesFromDictionary:(NSDictionary*)spritePhysic 
									  fixture:(b2FixtureDef*)shapeDef
{
	shapeDef->density = [spritePhysic floatForKey:@"Density"];
	shapeDef->friction = [spritePhysic floatForKey:@"Friction"];
	shapeDef->restitution = [spritePhysic floatForKey:@"Restitution"];
	
	shapeDef->filter.categoryBits = [spritePhysic intForKey:@"Category"];
	shapeDef->filter.maskBits = [spritePhysic intForKey:@"Mask"];
	shapeDef->filter.groupIndex = [spritePhysic intForKey:@"Group"];
    
    shapeDef->isSensor = [spritePhysic boolForKey:@"IsSensor"];
}
-(void) createPhysicBoundariesHelper:(b2World*)_world 
                        convertRatio:(CGPoint)wbConv 
                              offset:(CGPoint)pos_offset{
	if(![self hasPhysicBoundaries]){
        NSLog(@"LevelHelper WARNING - Please create physic boundaries in LevelHelper in order to call method \"createPhysicBoundaries\"");
        return;
    }	
        
    b2BodyDef bodyDef;		
	bodyDef.type = b2_staticBody;
	bodyDef.position.Set(0.0f, 0.0f);
    b2Body* wbBodyT = _world->CreateBody(&bodyDef);
	b2Body* wbBodyL = _world->CreateBody(&bodyDef);
	b2Body* wbBodyB = _world->CreateBody(&bodyDef);
	b2Body* wbBodyR = _world->CreateBody(&bodyDef);
	
	{
        LHNode* spr = [LHNode nodeWithDictionary:[NSDictionary dictionaryWithObject:@"LHPhysicBoundarieLeft" 
                                                                             forKey:@"UniqueName"]];     
		[spr setTag:[wb intForKey:@"TagLeft"]]; 
		[spr setVisible:false];
        [spr setBody:wbBodyL];    
#ifndef LH_ARC_ENABLED
        wbBodyL->SetUserData(spr);
#else
        wbBodyL->SetUserData((__bridge void*)spr);
#endif
        [physicBoundariesInLevel setObject:spr forKey:@"LHPhysicBoundarieLeft"];
	}
	
	{
        LHNode* spr = [LHNode nodeWithDictionary:[NSDictionary dictionaryWithObject:@"LHPhysicBoundarieRight" 
                                                                             forKey:@"UniqueName"]];
		[spr setTag:[wb intForKey:@"TagRight"]]; 

		[spr setVisible:false];
        [spr setBody:wbBodyR];  
#ifndef LH_ARC_ENABLED
        wbBodyR->SetUserData(spr);
#else
        wbBodyR->SetUserData((__bridge void*)spr);
#endif
        [physicBoundariesInLevel setObject:spr forKey:@"LHPhysicBoundarieRight"];
	}
	
	{
        LHNode* spr = [LHNode nodeWithDictionary:[NSDictionary dictionaryWithObject:@"LHPhysicBoundarieTop" 
                                                                             forKey:@"UniqueName"]];     
		[spr setTag:[wb intForKey:@"TagTop"]]; 
		[spr setVisible:false];
        [spr setBody:wbBodyT];  
        
#ifndef LH_ARC_ENABLED
        wbBodyT->SetUserData(spr);        
#else
        wbBodyT->SetUserData((__bridge void*)spr);        
#endif
        [physicBoundariesInLevel setObject:spr forKey:@"LHPhysicBoundarieTop"];
	}
	
	{
        LHNode* spr = [LHNode nodeWithDictionary:[NSDictionary dictionaryWithObject:@"LHPhysicBoundarieBottom" 
                                                                             forKey:@"UniqueName"]];     
		[spr setTag:[wb intForKey:@"TagBottom"]]; 
		[spr setVisible:false];
        [spr setBody:wbBodyB];  
#ifndef LH_ARC_ENABLED
        wbBodyB->SetUserData(spr);        
#else
        wbBodyB->SetUserData((__bridge void*)spr);        
#endif
        [physicBoundariesInLevel setObject:spr forKey:@"LHPhysicBoundarieBottom"];
	}
	
    bool canSleep = [wb boolForKey:@"CanSleep"];
	wbBodyT->SetSleepingAllowed(canSleep);  
	wbBodyL->SetSleepingAllowed(canSleep);  
	wbBodyB->SetSleepingAllowed(canSleep);  
	wbBodyR->SetSleepingAllowed(canSleep);  
	
    CGRect rect = [wb rectForKey:@"WBRect"];    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
	
    float ptm = [[LHSettings sharedInstance] lhPtmRatio];
    
    #ifndef LH_SCENE_TESTER
        rect.origin.x += pos_offset.x;
        rect.origin.y += pos_offset.y;
    #else
        rect.origin.x += pos_offset.x*2.0f;
        rect.origin.y += pos_offset.y*2.0f;
    #endif
    {//TOP
        b2EdgeShape shape;
		
        b2Vec2 pos1 = b2Vec2(rect.origin.x/ptm*wbConv.x,
							 (winSize.height - rect.origin.y*wbConv.y)/ptm);
        
        b2Vec2 pos2 = b2Vec2((rect.origin.x + rect.size.width)*wbConv.x/ptm, 
							 (winSize.height - rect.origin.y*wbConv.y)/ptm);		
		shape.Set(pos1, pos2);
		
        b2FixtureDef fixture;
        [self setFixtureDefPropertiesFromDictionary:wb fixture:&fixture];
        fixture.shape = &shape;
        wbBodyT->CreateFixture(&fixture);
    }
	
    {//LEFT
        b2EdgeShape shape;
		
		b2Vec2 pos1 = b2Vec2(rect.origin.x*wbConv.x/ptm,
							 (winSize.height - rect.origin.y*wbConv.y)/ptm);
        
		b2Vec2 pos2 = b2Vec2((rect.origin.x*wbConv.x)/ptm, 
							 (winSize.height - (rect.origin.y + rect.size.height)*wbConv.y)/ptm);
        shape.Set(pos1, pos2);
		
        b2FixtureDef fixture;
        [self setFixtureDefPropertiesFromDictionary:wb fixture:&fixture];
        fixture.shape = &shape;
        wbBodyL->CreateFixture(&fixture);
    }
	
    {//RIGHT
        b2EdgeShape shape;
        
        b2Vec2 pos1 = b2Vec2((rect.origin.x + rect.size.width)*wbConv.x/ptm,
							 (winSize.height - rect.origin.y*wbConv.y)/ptm);
        
        b2Vec2 pos2 = b2Vec2((rect.origin.x+ rect.size.width)*wbConv.x/ptm, 
							 (winSize.height - (rect.origin.y + rect.size.height)*wbConv.y)/ptm);
        shape.Set(pos1, pos2);
		
        b2FixtureDef fixture;
        [self setFixtureDefPropertiesFromDictionary:wb fixture:&fixture];
        fixture.shape = &shape;
        wbBodyR->CreateFixture(&fixture);
    }
	
    {//BOTTOM
        b2EdgeShape shape;
        
        b2Vec2 pos1 = b2Vec2(rect.origin.x*wbConv.x/ptm,
							 (winSize.height - (rect.origin.y + rect.size.height)*wbConv.y)/ptm);
        
        b2Vec2 pos2 = b2Vec2((rect.origin.x+ rect.size.width)*wbConv.x/ptm, 
							 (winSize.height - (rect.origin.y + rect.size.height)*wbConv.y)/ptm);
        shape.Set(pos1, pos2);
		
        b2FixtureDef fixture;
        [self setFixtureDefPropertiesFromDictionary:wb fixture:&fixture];
        fixture.shape = &shape;
        wbBodyB->CreateFixture(&fixture);
    }
}
//------------------------------------------------------------------------------
-(void) createPhysicBoundariesNoStretching:(b2World *)_world{
    
    CGPoint pos_offset = [[LHSettings sharedInstance] possitionOffset];
    CGPoint  wbConv = [[LHSettings sharedInstance] convertRatio];
    
    [self createPhysicBoundariesHelper:_world convertRatio:wbConv 
                                offset:CGPointMake(pos_offset.x/2.0f, 
                                                   pos_offset.y/2.0f)];
}
//------------------------------------------------------------------------------
-(void) createPhysicBoundaries:(b2World*)_world{
    CGPoint  wbConv = [[LHSettings sharedInstance] realConvertRatio];
    [self createPhysicBoundariesHelper:_world convertRatio:wbConv offset:CGPointMake(0.0f, 0.0f)];
}
//------------------------------------------------------------------------------
-(void) removePhysicBoundaries{    
    [physicBoundariesInLevel removeAllObjects];
}
//------------------------------------------------------------------------------
-(void) releasePhysicBoundaries{
    [self removePhysicBoundaries];
#ifndef LH_ARC_ENABLED
    [physicBoundariesInLevel release];
#endif
    physicBoundariesInLevel = nil;
}
////////////////////////////////////////////////////////////////////////////////
//PHYSICS
////////////////////////////////////////////////////////////////////////////////
+(void) setMeterRatio:(float)ratio{
	[[LHSettings sharedInstance] setLhPtmRatio:ratio];
}
//------------------------------------------------------------------------------
+(float) meterRatio{
	return [[LHSettings sharedInstance] lhPtmRatio];
}
//------------------------------------------------------------------------------
+(float) pixelsToMeterRatio{
    return [[LHSettings sharedInstance] lhPtmRatio]*[[LHSettings sharedInstance] convertRatio].x;
}
//------------------------------------------------------------------------------
+(float) pointsToMeterRatio{
    return [[LHSettings sharedInstance] lhPtmRatio];
}
//------------------------------------------------------------------------------
+(b2Vec2) pixelToMeters:(CGPoint)point{
    return b2Vec2(point.x / [LevelHelperLoader pixelsToMeterRatio], point.y / [LevelHelperLoader pixelsToMeterRatio]);
}
//------------------------------------------------------------------------------
+(b2Vec2) pointsToMeters:(CGPoint)point{
    return b2Vec2(point.x / [[LHSettings sharedInstance] lhPtmRatio], point.y / [[LHSettings sharedInstance] lhPtmRatio]);
}
//------------------------------------------------------------------------------
+(CGPoint) metersToPoints:(b2Vec2)vec{
    return CGPointMake(vec.x*[[LHSettings sharedInstance] lhPtmRatio], vec.y*[[LHSettings sharedInstance] lhPtmRatio]);
}
//------------------------------------------------------------------------------
+(CGPoint) metersToPixels:(b2Vec2)vec{
    return ccpMult(CGPointMake(vec.x, vec.y), [LevelHelperLoader pixelsToMeterRatio]);
}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
-(void)createAllNodes
{
    for(NSDictionary* dictionary in lhNodes)
    {
    
//    for(int i = 0; i < (int)[lhNodes count]; ++i)
//	{
//        NSDictionary* dictionary = [lhNodes objectAtIndex:i];
        
        if([[dictionary objectForKey:@"NodeType"] isEqualToString:@"LHLayer"]){
            LHLayer* layer = [LHLayer layerWithDictionary:dictionary];
            [cocosLayer addChild:layer z:[layer zOrder]];
            mainLHLayer = layer;
            [mainLHLayer setIsMainLayer:YES];
            //we use the selector protocol so that we dont get warnings since this method is 
            //hidden from the user
            [layer performSelector:@selector(setParentLoader:) withObject:self];
            [[LHSettings sharedInstance] addLHMainLayer:mainLHLayer];
        }
    }
}
//------------------------------------------------------------------------------
-(void) createAllJoints{
    
    for(NSDictionary* jointDict in lhJoints)
	{
        LHJoint* joint = [LHJoint jointWithDictionary:jointDict 
                                                world:box2dWorld 
                                               loader:self];
        
        if(joint)
            [jointsInLevel setObject:joint forKey:[jointDict objectForKey:@"UniqueName"]];                
	}	
}
//------------------------------------------------------------------------------
-(void)startAllPaths{
    if(!mainLHLayer)return;
    
   NSArray* allSprites = [mainLHLayer allSprites];
    
    for(LHSprite* spr in allSprites){
        NSString* pathName = [spr pathUniqueName];
        if(pathName)
            [spr prepareMovementOnPathWithUniqueName:pathName];
           
        if([spr pathDefaultStartAtLaunch])
            [spr startPathMovement];
    }
}

-(NSArray*)  spritesWithTag:(enum LevelHelper_TAG)tag ordered:(NSComparisonResult)sortOrder{
    NSMutableArray* spritesWithTag = (NSMutableArray*)[self spritesWithTag:tag];
    if(sortOrder == NSOrderedAscending){
        [spritesWithTag sortUsingSelector:@selector(sortAscending:)];        
    }
    else if(sortOrder == NSOrderedDescending){
        [spritesWithTag sortUsingSelector:@selector(sortDescending:)]; 
    }
    return spritesWithTag;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//PARALLAX
////////////////////////////////////////////////////////////////////////////////
-(LHParallaxNode*) parallaxNodeWithUniqueName:(NSString*)uniqueName{
    return [parallaxesInLevel objectForKey:uniqueName];
}
//------------------------------------------------------------------------------
-(NSArray*) allParallaxes{
    return [parallaxesInLevel allValues];
}
//------------------------------------------------------------------------------
-(LHParallaxNode*) parallaxNodeFromDictionary:(NSDictionary*)parallaxDict 
                                        layer:(CCLayer*)layer 
{
	LHParallaxNode* node = [LHParallaxNode nodeWithDictionary:parallaxDict loader:self];
    
    if(layer != nil && node != nil){
        int z = [parallaxDict intForKey:@"ZOrder"];
        [layer addChild:node z:z];
    }
    NSArray* spritesInfo = [parallaxDict objectForKey:@"Sprites"];
    for(NSDictionary* sprInf in spritesInfo){
        float ratioX = [sprInf floatForKey:@"RatioX"];
        float ratioY = [sprInf floatForKey:@"RatioY"];
        NSString* sprName = [sprInf stringForKey:@"SpriteName"];
        
		LHSprite* spr = [self spriteWithUniqueName:sprName];
		if(nil != node && spr != nil){
			[node addSprite:spr parallaxRatio:ccp(ratioX, ratioY)];
		}
    }
    return node;
}
//------------------------------------------------------------------------------
-(void) createParallaxes
{
    for(NSDictionary* parallaxDict in lhParallax){
		LHParallaxNode* node = [self parallaxNodeFromDictionary:parallaxDict layer:cocosLayer];
        if(nil != node){
			[parallaxesInLevel setObject:node forKey:[parallaxDict stringForKey:@"UniqueName"]];
		}
    }
}
//------------------------------------------------------------------------------
-(void)removeParallaxNode:(LHParallaxNode*)node{
    [self removeParallaxNode:node removeChildSprites:NO];
}
//------------------------------------------------------------------------------
-(void) removeParallaxNode:(LHParallaxNode*)node removeChildSprites:(bool)rem{
    
    if(NULL == node)
        return;    
    
    [node setRemoveChildSprites:rem];
    [parallaxesInLevel removeObjectForKey:[node uniqueName]];
    [node removeFromParentAndCleanup:YES];
}
//------------------------------------------------------------------------------
-(void) removeAllParallaxes{
    [self removeAllParallaxesAndChildSprites:NO];
}
//------------------------------------------------------------------------------
-(void) removeAllParallaxesAndChildSprites:(bool)remChilds{

    NSArray* keys = [parallaxesInLevel allKeys];
    
	for(NSString* key in keys){
		LHParallaxNode* par = [parallaxesInLevel objectForKey:key];
		if(nil != par){
            [par setRemoveChildSprites:remChilds];
            [par removeFromParentAndCleanup:YES];
		}
	}
	[parallaxesInLevel removeAllObjects];
}
//------------------------------------------------------------------------------
-(void) releaseAllParallaxes
{
    [self removeAllParallaxes];
#ifndef LH_ARC_ENABLED
	[parallaxesInLevel release];
#endif
    parallaxesInLevel = nil;
}


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+(void)setTouchDispatcherForObject:(id)object tag:(int)tag
{
    //NSLog(@"SET TOUCH DISPATCHER ON %@", [object uniqueName]);
    
    [object setTagTouchBeginObserver:[[LHTouchMgr sharedInstance] onTouchBeginObserverForTag:tag]];
    [object setTagTouchMovedObserver:[[LHTouchMgr sharedInstance] onTouchMovedObserverForTag:tag]];
    [object setTagTouchEndedObserver:[[LHTouchMgr sharedInstance] onTouchEndedObserverForTag:tag]];
    
    
    int priority = [[LHTouchMgr sharedInstance] priorityForTag:tag];
#if COCOS2D_VERSION >= 0x00020000 
    #ifdef __CC_PLATFORM_IOS
        bool swallow = [[LHTouchMgr sharedInstance] shouldTouchesBeSwallowedForTag:tag];
        CCDirectorIOS *director = (CCDirectorIOS*) [CCDirector sharedDirector];
        CCTouchDispatcher *dispatcher = [director touchDispatcher];
        [dispatcher addTargetedDelegate:object 
                               priority:priority 
                        swallowsTouches:swallow];
    
    #else //MAC
        CCEventDispatcher* dispatcher = [[CCDirector sharedDirector] eventDispatcher];
        [dispatcher addMouseDelegate:object priority:priority];
    #endif
#else //cocos2d 1.0.1
    bool swallow = [[LHTouchMgr sharedInstance] shouldTouchesBeSwallowedForTag:tag];
    [object setSwallowTouches:swallow];
    #ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
        [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:object 
                                                         priority:priority 
                                                  swallowsTouches:swallow];
    
    #ifndef LH_ARC_ENABLED 
    //[object release];
    //since the object is retain we must release it once in order 
    //to have an empty memory when we release the level
    //XXX on ARC this may create problems.
    #endif
    
    #else //MAC//if defined(__MAC_OS_X_VERSION_MAX_ALLOWED)
        [[CCEventDispatcher sharedDispatcher] addMouseDelegate:object priority:priority];
    
        #ifndef LH_ARC_ENABLED 
      //      [object release];
        #endif
    #endif
#endif
    
}
//------------------------------------------------------------------------------
+(void)removeTouchDispatcherFromObject:(id)object
{
//#if COCOS2D_VERSION >= 0x00020000 
//    CCDirectorIOS *director = (CCDirectorIOS*) [CCDirector sharedDirector];
//    CCTouchDispatcher *touchDisPatcher = [director touchDispatcher];
//    [touchDisPatcher removeDelegate:object];
//#else    
//    
//
//#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
//    [[CCTouchDispatcher sharedDispatcher] removeDelegate:object];    
//#elif defined(__MAC_OS_X_VERSION_MAX_ALLOWED)
//    [[CCEventDispatcher sharedDispatcher] removeMouseDelegate:object];
//#endif
//
//#endif

#if COCOS2D_VERSION >= 0x00020000 
    
#ifdef __CC_PLATFORM_IOS
    CCDirectorIOS *director = (CCDirectorIOS*) [CCDirector sharedDirector];
    CCTouchDispatcher *touchDisPatcher = [director touchDispatcher];
    [touchDisPatcher removeDelegate:object];
#else //MAC
    CCEventDispatcher* dispatcher = [[CCDirector sharedDirector] eventDispatcher];
    [dispatcher removeMouseDelegate:object];
#endif
    
#else   //cocos2d 1.0.1
    
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
    [[CCTouchDispatcher sharedDispatcher] removeDelegate:object];    
#elif defined(__MAC_OS_X_VERSION_MAX_ALLOWED)
    [[CCEventDispatcher sharedDispatcher] removeMouseDelegate:object];
#endif
    
#endif
    
}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
-(void)loadLevelHelperSceneFile:(NSString*)levelFile inDirectory:(NSString*)subfolder imgSubfolder:(NSString*)imgFolder
{
	NSString *path = [[NSBundle mainBundle] pathForResource:levelFile ofType:@"plhs" inDirectory:subfolder]; 
	
	NSAssert(nil!=path, @"Invalid level file. Please add the LevelHelper scene file to Resource folder. Please do not add extension in the given string.");
	
	NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
	
	[self processLevelFileFromDictionary:dictionary];
}

-(void)loadLevelHelperSceneFileFromWebAddress:(NSString*)webaddress
{	
	NSURL *url = [NSURL URLWithString:webaddress];
	
	NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfURL:url];
	
	if(dictionary == nil)
		NSLog(@"Provided web address is wrong or connection error.");
	
	[self processLevelFileFromDictionary:dictionary];
}

-(void) loadLevelHelperSceneFromDictionary:(NSDictionary*)levelDictionary 
							  imgSubfolder:(NSString*)imgFolder
{	
    [imageFolder setString:imgFolder];
    [[LHSettings sharedInstance] setActiveFolder:imageFolder];
	[self processLevelFileFromDictionary:levelDictionary];
}

-(void)processLevelFileFromDictionary:(NSDictionary*)dictionary
{
	if(nil == dictionary)
		return;
	
	bool fileInCorrectFormat =	[[dictionary stringForKey:@"Author"] isEqualToString:@"Bogdan Vladu"] && 
	[[dictionary objectForKey:@"CreatedWith"] isEqualToString:@"LevelHelper"];
	
	if(fileInCorrectFormat == false)
		NSLog(@"This file was not created with LevelHelper or file is damaged.");
	
    NSDictionary* scenePref = [dictionary objectForKey:@"ScenePreference"];
    safeFrame = [scenePref pointForKey:@"SafeFrame"];
    
    gameWorldRect = [scenePref rectForKey:@"GameWorld"];
	
    
    [[LHSettings sharedInstance] setHDSuffix:[scenePref stringForKey:@"HDSuffix"]];
    [[LHSettings sharedInstance] setHD2xSuffix:[scenePref stringForKey:@"2HDSuffix"]];
    [[LHSettings sharedInstance] setDevice:[scenePref intForKey:@"Device"]];
    
	CGRect color = [scenePref rectForKey:@"BackgroundColor"];
	glClearColor(color.origin.x, color.origin.y, color.size.width, 1);
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];

    if(safeFrame.x == 0 || safeFrame.y == 0)
        safeFrame = CGPointMake(winSize.width, winSize.height);

//    bool usesCustomSize = false;
//    if(4 == [[scenePref objectForKey:@"ScreenSize"] intValue])
//        usesCustomSize = true;
    
    [[LHSettings sharedInstance] setConvertRatio:CGPointMake(winSize.width/safeFrame.x, 
                                                             winSize.height/safeFrame.y)];
//                                  usesCustomSize:usesCustomSize];
    
    float safeFrameDiagonal = sqrtf(safeFrame.x* safeFrame.x + safeFrame.y* safeFrame.y);
    float winDiagonal = sqrtf(winSize.width* winSize.width + winSize.height*winSize.height);
    float PTM_conversion = winDiagonal/safeFrameDiagonal;
    
    [LevelHelperLoader setMeterRatio:[[LHSettings sharedInstance] lhPtmRatio]*PTM_conversion];
    
	////////////////////////LOAD WORLD BOUNDARIES//////////////////////////////////////////////
	if(nil != [dictionary objectForKey:@"WBInfo"]){
		wb = [dictionary objectForKey:@"WBInfo"];
	}
	
	////////////////////////LOAD SPRITES////////////////////////////////////////////////////
    lhNodes = [[NSArray alloc] initWithArray:[dictionary objectForKey:@"NODES_INFO"]];
		
	///////////////////////LOAD JOINTS//////////////////////////////////////////////////////////
	lhJoints = [[NSArray alloc] initWithArray:[dictionary objectForKey:@"JOINTS_INFO"]];	
	
    //////////////////////LOAD PARALLAX/////////////////////////////////////////
    lhParallax = [[NSArray alloc] initWithArray:[dictionary objectForKey:@"PARALLAX_INFO"]];
    
    gravity = [dictionary pointForKey:@"Gravity"];
}
////////////////////////////////////////////////////////////////////////////////////
@end
