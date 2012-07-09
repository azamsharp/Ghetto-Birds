//  This file is part of LevelHelper
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
////////////////////////////////////////////////////////////////////////////////

#import "LevelHelperLoader.h"

@interface LevelHelperLoader (MOUSE_JOINT_EXTENSION) 

-(bool) isBodyTouched:(b2Body*)body touchPoint:(CGPoint)point;

-(b2Body*) bodyWithTag:(enum LevelHelper_TAG)tag touchedAtPoint:(CGPoint*)point withFingerSize:(int)size;
-(b2Body*) bodyWithTag:(enum LevelHelper_TAG)tag touchedAtPoint:(CGPoint)point;
-(bool) isBodyWithUniqueNameTouched:(NSString*)name touchPoint:(CGPoint)point; 
-(b2Body*) bodyWithUniqueName:name touchedAtPoint:(CGPoint*)point withFingerSize:(int)size;

-(b2MouseJoint*) mouseJointForBodyA:(b2Body*)wb_Body bodyB:(b2Body*)ourBody touchPoint:(CGPoint)point;
-(b2MouseJoint*) mouseJointForBody:(b2Body*)body touchPoint:(CGPoint)point;
-(b2MouseJoint*) mouseJointForBodyWithUniqueName:(NSString*)name 
                                      touchPoint:(CGPoint)point;

-(void) setTarget:(CGPoint)point onMouseJoint:(b2MouseJoint*)mouseJoint;

@end	
