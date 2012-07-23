//
//  GameLayer.h
//  AngryBirds
//
//  Created by Mohammad Azam on 6/30/12.
//  Copyright (c) 2012 HighOnCoding. All rights reserved.
//

#import "cocos2d.h" 
#import "Box2D.h" 
#import "LevelHelperLoader.h" 

@interface GameLayer : CCLayer
{
    b2World *world; 
    LevelHelperLoader *loader; 
    LHSprite *angryBird; 
    LHSprite *poof; 
    LHParallaxNode *parallaxNode; 
    CCSprite *dummySprite;
    
}
@end
