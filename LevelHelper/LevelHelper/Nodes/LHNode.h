//
//  LHNode.h
//  
//
//  Created by Bogdan Vladu on 4/2/12.
//  Copyright (c) 2012 Bogdan Vladu. All rights reserved.
//

#import "CCNode.h"
#include "Box2D.h"

@interface LHNode : CCNode
{
    NSString* uniqueName;
    b2Body* body;
}

+(id)nodeWithDictionary:(NSDictionary*)dictionary;

-(void)setBody:(b2Body*)body;
-(b2Body*)body;
@end
