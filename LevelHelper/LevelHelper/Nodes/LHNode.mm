//
//  LHNode.m
//  
//
//  Created by Bogdan Vladu on 4/2/12.
//  Copyright (c) 2012 Bogdan Vladu. All rights reserved.
//

#import "LHNode.h"
#import "LHBatch.h"
#import "LHSprite.h"
#import "LHBezier.h"
#import "LHJoint.h"

#import "LevelHelperLoader.h"
//------------------------------------------------------------------------------
static int untitledNodesCount = 0;
//------------------------------------------------------------------------------
@interface LHNode (LH_NODE_PRIVATE) 
-(bool) removeBodyFromWorld;
@end

@implementation LHNode
-(void)dealloc{
    
   // NSLog(@"LHNODE DEALLOC %@", uniqueName);
    
    [self removeBodyFromWorld];
    
#ifndef LH_ARC_ENABLED    
    [uniqueName release];
    [super dealloc];
#endif
}
-(LHNode*)initWithDictionary:(NSDictionary*)dictionary;
{
    self = [super init];
    if (self != nil)
    {
        NSString* uName = [dictionary objectForKey:@"UniqueName"];
        if(uName)
            uniqueName = [[NSString alloc] initWithString:uName];
        else {
            uniqueName = [[NSString alloc] initWithFormat:@"UntitledNode_%d", untitledNodesCount];
            ++untitledNodesCount;
        }
        
        
        NSArray* childrenInfo = [dictionary objectForKey:@"Children"];
        for(NSDictionary* childDict in childrenInfo)
        {
            if([[childDict objectForKey:@"NodeType"] isEqualToString:@"LHLayer"])
            {
                //nothing to do yet.
            }
            else if([[childDict objectForKey:@"NodeType"] isEqualToString:@"LHBatch"])
            {
                //nothing to do yet.
            }
            else if([[childDict objectForKey:@"NodeType"] isEqualToString:@"LHBezier"])
            {
                //nothing to do yet.
            }
            else if([[childDict objectForKey:@"NodeType"] isEqualToString:@"LHSprite"])
            {
                //nothing to do yet.
            }
        }
    }
    return self;
}
//------------------------------------------------------------------------------
+(id)nodeWithDictionary:(NSDictionary*)dictionary{

#ifndef LH_ARC_ENABLED
    return [[(LHNode*)[self alloc] initWithDictionary:dictionary] autorelease];
#else
    return [(LHNode*)[self alloc] initWithDictionary:dictionary];
#endif

}
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
-(void)setBody:(b2Body*)b{
    body = b;
}
-(b2Body*)body{
    return body;
}

-(NSArray*) jointList{
    NSMutableArray* array = [NSMutableArray array];
    if(body != NULL){
        b2JointEdge* jtList = body->GetJointList();
        while (jtList) {
            LHJoint* lhJt = [LHJoint jointFromBox2dJoint:jtList->joint];
            if(lhJt != NULL)
                [array addObject:lhJt];
            jtList = jtList->next;
        }
    }
    return array;
}
-(bool) removeBodyFromWorld{
    if(NULL != body){
		b2World* _world = body->GetWorld();
		if(0 != _world){
            
            NSMutableArray* list = (NSMutableArray*)[self jointList];
            for(LHJoint* jt in list){
                [jt setShouldDestroyJointOnDealloc:NO];
                [jt removeSelf];
            }
            [list removeAllObjects];
            
			_world->DestroyBody(body);
			body = NULL;
            
            return true;
		}
	}
    return false;
}
@end
