//
//  LHCuttingEngineMgr.m
//  LevelHelperExplodingSprites
//
//  Created by Bogdan Vladu on 3/10/12.
//  Copyright (c) 2012 Bogdan Vladu. All rights reserved.
//

#import "LHCuttingEngineMgr.h"
#import "LHSprite.h"
#import "LevelHelperLoader.h"

// Include STL vector class.
#include <map>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#import "cocos2d.h"
// Typedef an STL vector of vertices which are used to represent
// a polygon/contour and a series of triangles.
typedef std::vector< b2Vec2 > Vector2dVector;

class Triangulate
{
public:

// triangulate a contour/polygon, places results in STL vector
// as series of triangles.
static bool Process(const Vector2dVector &contour,
                    Vector2dVector &result);

// compute area of a contour/polygon
static float Area(const Vector2dVector &contour);

// decide if point Px/Py is inside triangle defined by
// (Ax,Ay) (Bx,By) (Cx,Cy)
static bool InsideTriangle(float Ax, float Ay,
                           float Bx, float By,
                           float Cx, float Cy,
                           float Px, float Py);


private:
static bool Snip(const Vector2dVector &contour,int u,int v,int w,int n,int *V);

};


//#endif

/**************************************************************************/
/*** END OF HEADER FILE TRIANGULATE.H BEGINNING OF CODE TRIANGULATE.CPP ***/
/**************************************************************************/


static const float EPSILON=0.0000000001f;

float Triangulate::Area(const Vector2dVector &contour)
{
    
    int n = contour.size();
    
    float A=0.0f;
    
    for(int p=n-1,q=0; q<n; p=q++)
    {
        A+= contour[p].x*contour[q].y - contour[q].x*contour[p].y;
    }
    return A*0.5f;
}

/*
 InsideTriangle decides if a point P is Inside of the triangle
 defined by A, B, C.
 */
bool Triangulate::InsideTriangle(float Ax, float Ay,
                                 float Bx, float By,
                                 float Cx, float Cy,
                                 float Px, float Py)

{
    float ax, ay, bx, by, cx, cy, apx, apy, bpx, bpy, cpx, cpy;
    float cCROSSap, bCROSScp, aCROSSbp;
    
    ax = Cx - Bx;  ay = Cy - By;
    bx = Ax - Cx;  by = Ay - Cy;
    cx = Bx - Ax;  cy = By - Ay;
    apx= Px - Ax;  apy= Py - Ay;
    bpx= Px - Bx;  bpy= Py - By;
    cpx= Px - Cx;  cpy= Py - Cy;
    
    aCROSSbp = ax*bpy - ay*bpx;
    cCROSSap = cx*apy - cy*apx;
    bCROSScp = bx*cpy - by*cpx;
    
    return ((aCROSSbp >= 0.0f) && (bCROSScp >= 0.0f) && (cCROSSap >= 0.0f));
};

bool Triangulate::Snip(const Vector2dVector &contour,int u,int v,int w,int n,int *V)
{
    int p;
    float Ax, Ay, Bx, By, Cx, Cy, Px, Py;
    
    Ax = contour[V[u]].x;
    Ay = contour[V[u]].y;
    
    Bx = contour[V[v]].x;
    By = contour[V[v]].y;
    
    Cx = contour[V[w]].x;
    Cy = contour[V[w]].y;
    
    if ( EPSILON > (((Bx-Ax)*(Cy-Ay)) - ((By-Ay)*(Cx-Ax))) ) return false;
    
    for (p=0;p<n;p++)
    {
        if( (p == u) || (p == v) || (p == w) ) continue;
        Px = contour[V[p]].x;
        Py = contour[V[p]].y;
        if (InsideTriangle(Ax,Ay,Bx,By,Cx,Cy,Px,Py)) return false;
    }
    
    return true;
}

bool Triangulate::Process(const Vector2dVector &contour,Vector2dVector &result)
{
    /* allocate and initialize list of Vertices in polygon */
    
    int n = contour.size();
    if ( n < 3 ) return false;
    
    int *V = new int[n];
    
    /* we want a counter-clockwise polygon in V */
    
    if ( 0.0f < Area(contour) )
        for (int v=0; v<n; v++) V[v] = v;
    else
        for(int v=0; v<n; v++) V[v] = (n-1)-v;
    
    int nv = n;
    
    /*  remove nv-2 Vertices, creating 1 triangle every time */
    int count = 2*nv;   /* error detection */
    
    for(int m=0, v=nv-1; nv>2; )
    {
        /* if we loop, it is probably a non-simple polygon */
        if (0 >= (count--))
        {
            //** Triangulate: ERROR - probable bad polygon!
            return false;
        }
        
        /* three consecutive vertices in current polygon, <u,v,w> */
        int u = v  ; if (nv <= u) u = 0;     /* previous */
        v = u+1; if (nv <= v) v = 0;     /* new v    */
        int w = v+1; if (nv <= w) w = 0;     /* next     */
        
        if ( Snip(contour,u,v,w,nv,V) )
        {
            int a,b,c,s,t;
            
            /* true names of the vertices */
            a = V[u]; b = V[v]; c = V[w];
            
            /* output Triangle */
            result.push_back( contour[a] );
            result.push_back( contour[b] );
            result.push_back( contour[c] );
            
            m++;
            
            /* remove v from remaining polygon */
            for(s=v,t=v+1;t<nv;s++,t++) V[s] = V[t]; nv--;
            
            /* resest error detection counter */
            count = 2*nv;
        }
    }
    
    delete V;
    
    return true;
}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//a is point 1 on the line - b is point 2 on the line
//c is the point we want to check
bool isLeft(b2Vec2 a, b2Vec2 b, b2Vec2 c)
{
    return ((b.x - a.x)*(c.y - a.y) - (b.y - a.y)*(c.x - a.x)) > 0;
}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
class AllBodiesRayCastCallback : public b2RayCastCallback{
public:
AllBodiesRayCastCallback(){    
}

float32 ReportFixture(b2Fixture* fixture, const b2Vec2& point,
                      const b2Vec2& normal, float32 fraction){

#ifndef LH_ARC_ENABLED
    id userData = (id)fixture->GetBody()->GetUserData();
#else
    id userData = (__bridge id)fixture->GetBody()->GetUserData();
#endif
    if ([userData isKindOfClass:[LHSprite class]]) {
        rayCastInfo[fixture->GetBody()] = point;
    }
    
    return 1;//go to all other points
}
std::map<b2Body*, b2Vec2> rayCastInfo;
};
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
class BodiesInAABBCallback : public b2QueryCallback
{
public:
	virtual ~BodiesInAABBCallback() {}
    
	/// Called for each fixture found in the query AABB.
	/// @return false to terminate the query.
	bool ReportFixture(b2Fixture* fixture)
    {
        queryInfo[fixture->GetBody()] = fixture;
        return true;
    }
    std::map<b2Body*, b2Fixture*> queryInfo;
};
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation LHCuttingEngineMgr

//this code is an extension from here http://www.cocos2d-iphone.org/forum/topic/2079
-(void) explodeSpritesInRadius:(float)radius
                     withForce:(float)maxForce
                      position:(CGPoint)pos
                       inWorld:(b2World*)world
                       suction:(bool)doSuction
{
    BodiesInAABBCallback callback;
    b2AABB aabb;
    
    aabb.lowerBound = [LevelHelperLoader pointsToMeters:ccp(pos.x - radius, pos.y - radius)];
    aabb.upperBound = [LevelHelperLoader pointsToMeters:ccp(pos.x + radius, pos.y + radius)];

    world->QueryAABB(&callback, aabb);
    
    std::map<b2Body*, b2Fixture*>::iterator it;
    
    for(it = callback.queryInfo.begin(); it != callback.queryInfo.end(); ++it)
    {
        b2Body* b = (*it).first;    
    
		b2Vec2 b2TouchPosition = [LevelHelperLoader pointsToMeters:pos];
		b2Vec2 b2BodyPosition = b2Vec2(b->GetPosition().x, b->GetPosition().y);
        
		float maxDistance = radius/[LevelHelperLoader meterRatio];
		CGFloat distance = 0.0f;
		CGFloat strength = 0.0f;
		float force = 0.0f;
		CGFloat angle = 0.0f;
        
		if(doSuction) 
		{
			distance = b2Distance(b2BodyPosition, b2TouchPosition);
			if(distance > maxDistance) distance = maxDistance - 0.01;
			// Get the strength
			//strength = distance / maxDistance; // Uncomment and reverse these two. and ones further away will get more force instead of less
			strength = (maxDistance - distance) / maxDistance; // This makes it so that the closer something is - the stronger, instead of further
			force  = strength * maxForce;
            
			// Get the angle
			angle = atan2f(b2TouchPosition.y - b2BodyPosition.y, b2TouchPosition.x - b2BodyPosition.x);
            b->ApplyForce(b2Vec2(cosf(angle) * force, sinf(angle) * force), b->GetPosition());
		}
		else
		{
			distance = b2Distance(b2BodyPosition, b2TouchPosition);
			if(distance > maxDistance) distance = maxDistance - 0.01;
            
			strength = (maxDistance - distance) / maxDistance;
			force = strength * maxForce;
			angle = atan2f(b2BodyPosition.y - b2TouchPosition.y, b2BodyPosition.x - b2TouchPosition.x);
            b->ApplyForce(b2Vec2(cosf(angle) * force, sinf(angle) * force), b->GetPosition());
		}
	}
}


+ (LHCuttingEngineMgr*)sharedInstance{
	static id sharedInstance = nil;
	if (sharedInstance == nil){
		sharedInstance = [[LHCuttingEngineMgr alloc] init];
	}
    return sharedInstance;
}
//------------------------------------------------------------------------------
-(void)dealloc
{
#ifndef LH_ARC_ENABLED

    [spritesPreviouslyCut release];
	[super dealloc];
#endif
}
//------------------------------------------------------------------------------
- (id)init
{
	self = [super init];
	if (self != nil) {
        spritesPreviouslyCut = [[NSMutableSet alloc] init];
	}
	return self;
}

-(void)destroyAllPrevioslyCutSprites{
    
    for(LHSprite* spr in spritesPreviouslyCut){
        [spr removeSelf];
    }
    [spritesPreviouslyCut removeAllObjects];
}
//------------------------------------------------------------------------------
-(LHSprite *)spriteWithVertices:(CGPoint[])vertices 
                         verticesCount:(int)count
                         oldSprite:(LHSprite*)oldSprite{

    if(oldSprite == nil)
    {
        NSLog(@"OLD SPRITE WAS NIL");
        return nil;
    }
    
    if(![oldSprite isKindOfClass:[LHSprite class]])
    {
        NSLog(@"OLD SPRITE IS NOT LHSprite");
        return nil;
    }

    CGRect oldRect = [oldSprite originalRect];
        
    CCTexture2D* oldTexture = [[CCTextureCache sharedTextureCache] addImage:[oldSprite imageFile]];
    
    CCSprite* tempOrigSprite = [CCSprite spriteWithTexture:oldTexture rect:oldRect];
    
    [tempOrigSprite setFlipX:YES];
    [tempOrigSprite setFlipY:YES];
    
    CCRenderTexture *justSprTx = [CCRenderTexture renderTextureWithWidth:oldRect.size.width
                                                                  height:oldRect.size.height];
    [justSprTx beginWithClear:1 g:1 b:1 a:0];
    
    [tempOrigSprite draw];
    
    [justSprTx end];
        
    CCRenderTexture *myCutTexture = [CCRenderTexture renderTextureWithWidth:oldRect.size.width
                                                                     height:oldRect.size.height];
    [myCutTexture beginWithClear:1 g:1 b:1 a:0];
    
#if COCOS2D_VERSION >= 0x00020000 

    //NSLog("Debug draw for cutting engine is disabled on Cocos2d 2.0");
    
    //XXX GLES 2.0 draw call here
#else
    glDisableClientState(GL_COLOR_ARRAY);
    
    glEnable(GL_TEXTURE_2D);		
    glBindTexture(GL_TEXTURE_2D, justSprTx.sprite.texture.name);//sprOrigFrm.texture.name);
    
    CGPoint* uv = new CGPoint[count];
    for(int k = 0; k < count; ++k){
        
        uv[k].x = vertices[k].x/(float)justSprTx.sprite.texture.pixelsWide;
        uv[k].y = vertices[k].y/(float)justSprTx.sprite.texture.pixelsHigh;    
    }
    
    glTexCoordPointer(2, GL_FLOAT, 0, uv);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glDrawArrays(GL_TRIANGLES, 0, count);
    glDrawArrays(GL_LINES, 0, count);
    delete[] uv;
    
#endif
    
    [myCutTexture end];
    
    LHSprite* sprCut = [LHSprite spriteWithTexture:myCutTexture.sprite.texture];    
    
    if(sprCut)
    {
        [sprCut setOriginalRect:oldRect];
        [sprCut setImageFile:[oldSprite imageFile]];
        [sprCut setTag:[oldSprite tag]];
        [sprCut setOpacity:[oldSprite opacity]];
        [sprCut setColor:[oldSprite color]];
        
        [sprCut setScaleX:[oldSprite scaleX]];
        [sprCut setScaleY:[oldSprite scaleY]];
        
        static long long createdSprites = 0;
        [sprCut setUniqueName:[NSString stringWithFormat:@"%d", createdSprites]];
        
        ++createdSprites;
        
        
#if COCOS2D_VERSION >= 0x00020000 
        if(oldSprite.batchNode)
#else
        if([oldSprite usesBatchNode])
#endif
        {
            CCLayer* layer = (CCLayer*)[[oldSprite parent] parent];
            [layer addChild:sprCut];
        }
        else {
            CCLayer* layer = (CCLayer*)[oldSprite parent];
            [layer addChild:sprCut];
        }
        
        [LevelHelperLoader setTouchDispatcherForObject:sprCut tag:[oldSprite tag]];
        
        [spritesPreviouslyCut addObject:sprCut];
        [spritesPreviouslyCut removeObject:oldSprite];

    }
    
    return sprCut;
}
//------------------------------------------------------------------------------
-(LHSprite*)createNewSpriteFromBodyInfo:(b2Body*)body 
                           andOldSprite:(LHSprite*)oldSprite
{
    b2Fixture* fixture = body->GetFixtureList();

    std::vector<CGPoint>triangles;
    
    while (fixture) {
        
        b2PolygonShape* poly = (b2PolygonShape*)fixture->GetShape();
        
        Vector2dVector result;
        Vector2dVector polygon;
        
        for(int k = 0; k < poly->GetVertexCount(); ++k){
            polygon.push_back(poly->m_vertices[k]);                
        }
        
        Triangulate::Process(polygon, result);
        
        for(int i = 0; i < (int)result.size()/3; ++i)
        {
            CGPoint texPoint[3];
            
            texPoint[0] = [LevelHelperLoader metersToPoints:result[i*3+0]];
            texPoint[1] = [LevelHelperLoader metersToPoints:result[i*3+1]];
            texPoint[2] = [LevelHelperLoader metersToPoints:result[i*3+2]];
            
            texPoint[0].x /= [oldSprite scaleX];
            texPoint[0].y /= [oldSprite scaleY];
            
            texPoint[1].x /= [oldSprite scaleX];
            texPoint[1].y /= [oldSprite scaleY];
            
            texPoint[2].x /= [oldSprite scaleX];
            texPoint[2].y /= [oldSprite scaleY];
            
            
            texPoint[0] = ccp(oldSprite.contentSize.width/2 - texPoint[0].x,
                              oldSprite.contentSize.height/2 - texPoint[0].y);
            
            texPoint[1] = ccp(oldSprite.contentSize.width/2 - texPoint[1].x,
                              oldSprite.contentSize.height/2 - texPoint[1].y);
            
            texPoint[2] = ccp(oldSprite.contentSize.width/2 - texPoint[2].x,
                              oldSprite.contentSize.height/2 - texPoint[2].y);
            
            
            triangles.push_back(texPoint[0]);
            triangles.push_back(texPoint[1]);
            triangles.push_back(texPoint[2]);
        }
        
        fixture = fixture->GetNext();
    }   
    
    CGPoint* texPoints = new CGPoint[triangles.size()];
    
    for(int i = 0; i < (int)triangles.size(); ++i){                                                            
        texPoints[i] = triangles[i];
    }
    
    LHSprite* newSprite = [self spriteWithVertices:texPoints
                                     verticesCount:triangles.size()
                                         oldSprite:oldSprite];

    if(newSprite){
        [newSprite setFlipX:YES];
    }  
    
    delete[] texPoints;
    
    return newSprite;
}
//------------------------------------------------------------------------------
-(b2Body*)createBodyWithPoints:(b2Vec2*)verts 
                         count:(int)count 
                       oldBody:(b2Body*)oldBody
                    oldFixture:(b2Fixture*)oldFixture
{
    b2World* world = oldBody->GetWorld();
    
    if(world->IsLocked())
        NSLog(@"Box2d world is locked. Game will assert. Do not perform actions on a body when the Box2d world is locked. Trigger an action at the end of your tick method.");
    
    b2FixtureDef fixture;
    
    b2BodyDef bodyDef;	
    bodyDef.type = oldBody->GetType();        
    bodyDef.position = oldBody->GetPosition();
    bodyDef.angle = oldBody->GetAngle();
    b2Body* body = world->CreateBody(&bodyDef);
    
    bodyDef.fixedRotation = oldBody->IsFixedRotation();
    
    b2PolygonShape shape;
    
    shape.Set(verts, count);		
    
    fixture.density = oldFixture->GetDensity();
    fixture.friction =oldFixture->GetFriction();
    fixture.restitution = oldFixture->GetRestitution();
    fixture.filter = oldFixture->GetFilterData();
    
    fixture.isSensor = oldFixture->IsSensor();
    
    fixture.shape = &shape;
    body->CreateFixture(&fixture);
    
    body->SetGravityScale(oldBody->GetGravityScale());
	body->SetSleepingAllowed(oldBody->IsSleepingAllowed());    
    body->SetBullet(oldBody->IsBullet());
    
    return body;
}
//------------------------------------------------------------------------------

-(LHSprite*)spriteWithVertices:(b2Vec2[])vertices 
                         count:(int)count
                     oldSprite:(LHSprite*)oldSprite
                       oldBody:(b2Body*)splitBody
                    oldFixture:(b2Fixture*)fixture
                 massDestroyer:(float)mass
{    
    b2Body* newBody = [self createBodyWithPoints:vertices 
                                           count:count 
                                         oldBody:splitBody
                                      oldFixture:fixture];
    
    if(newBody->GetMass() < mass)
    {
       b2World* world =  newBody->GetWorld();
        
        world->DestroyBody(newBody);
        return nil;
    }
    
    LHSprite* newSprite1 = [self createNewSpriteFromBodyInfo:newBody
                                                andOldSprite:oldSprite];
    
    if(newSprite1){
        
#ifndef LH_ARC_ENABLED
        newBody->SetUserData(newSprite1);
#else
        newBody->SetUserData((__bridge void*)newSprite1);
#endif

        [newSprite1 setBody:newBody];
    }
    
    return newSprite1;
}
//------------------------------------------------------------------------------
-(void) splitSprite:(LHSprite*)oldSprite atPoint:(CGPoint)location
{
    [self splitSprite:oldSprite 
              atPoint:location 
triangulateAllFixtures:NO
            ignoreSmallerMass:0];
}
//------------------------------------------------------------------------------
-(void) splitSprite:(LHSprite *)oldSprite 
                atPoint:(CGPoint)location 
 triangulateAllFixtures:(bool)breakFixturesOutsidePoint
      ignoreSmallerMass:(float)mass
{        
    b2Body* splitBody = [oldSprite body];

    if(splitBody == NULL)
        return;
    
    b2World* world = splitBody->GetWorld();

    b2Vec2 pointInBox2dCoord = [LevelHelperLoader pointsToMeters:location];
        
    b2Fixture* fixture = splitBody->GetFixtureList();
    
    while (fixture) {
        
        if(fixture->GetShape()->GetType() != b2Shape::e_polygon)
            return;
        
        b2PolygonShape* poly = (b2PolygonShape*)fixture->GetShape();
        
        if(fixture->TestPoint(pointInBox2dCoord))
        {
            b2Vec2 prevPoint = poly->GetVertex(0);
            
            for(int i = 1; i < poly->GetVertexCount(); ++i)
            {
                b2Vec2 point = poly->GetVertex(i);
                
                b2Vec2* vertices = new b2Vec2[3];
               
                vertices[0] = prevPoint;
                vertices[1] = point;
                vertices[2] = splitBody->GetLocalPoint(pointInBox2dCoord);
                
                [self spriteWithVertices:vertices
                                   count:3
                               oldSprite:oldSprite
                                 oldBody:splitBody
                              oldFixture:fixture
                           massDestroyer:mass];
                
                prevPoint = point;
                
                delete[] vertices;
            }
            
            b2Vec2* vertices = new b2Vec2[3];
            
            vertices[0] = poly->GetVertex(0);
            vertices[1] = poly->GetVertex(poly->GetVertexCount()-1);
            vertices[2] = splitBody->GetLocalPoint(pointInBox2dCoord);
                        
            
            [self spriteWithVertices:vertices
                               count:3
                           oldSprite:oldSprite
                             oldBody:splitBody
                          oldFixture:fixture
                       massDestroyer:mass];            

            delete[] vertices;
        }
        else {
                        
            Vector2dVector result;
            Vector2dVector polygon;
            
            for(int k = 0; k < poly->GetVertexCount(); ++k){
                polygon.push_back(poly->m_vertices[k]);                
            }
            
            Triangulate::Process(polygon, result);
            
            if(breakFixturesOutsidePoint)
            {
            for(size_t i = 0; i < result.size()/3; ++i)
            {
                b2Vec2* vertices = new b2Vec2[3];
                
                vertices[0] = result[i*3+0];
                vertices[1] = result[i*3+1];
                vertices[2] = result[i*3+2];
                      
                [self spriteWithVertices:vertices
                                   count:3
                               oldSprite:oldSprite
                                 oldBody:splitBody
                              oldFixture:fixture
                           massDestroyer:mass];
                
                delete[] vertices;
            }
            }
            else {
                
                [self spriteWithVertices:poly->m_vertices
                                   count:poly->GetVertexCount()
                               oldSprite:oldSprite
                                 oldBody:splitBody
                              oldFixture:fixture
                           massDestroyer:mass];                
            }
        }
        
        fixture = fixture->GetNext();
    }
    
    if([oldSprite isKindOfClass:[LHSprite class]]){
        [spritesPreviouslyCut removeObject:oldSprite];
        [(LHSprite*)oldSprite removeBodyFromWorld];//we force because of race condition
        [(LHSprite*)oldSprite removeSelf];
    }
    else{
        world->DestroyBody(splitBody);    
        [oldSprite removeFromParentAndCleanup:YES];
    }
}
//------------------------------------------------------------------------------
int sortBasedOnX(const b2Vec2& a, const b2Vec2& b)
{
    if (a.x>b.x) {
        return 1;
    }
    else if (a.x<b.x) {
        return -1;
    }
    return 0;
}    
//------------------------------------------------------------------------------
-(std::vector<b2Vec2>) clockwise:(std::vector<b2Vec2>&)vec
{
    int n =vec.size();
    int i1 =1,i2 =n-1;
    
    std::vector<b2Vec2> tempVec = vec;
    b2Vec2 C;
    b2Vec2 D;
    
    std::sort(vec.begin(), vec.end(), sortBasedOnX);
    
    tempVec[0]=vec[0];
    C=vec[0];
    D=vec[n-1];
    
    for(int i = 1; i < n-1; ++i){
    
        if(isLeft(C, D, vec[i]))
        {
            tempVec[i1++]=vec[i];
        }
        else {
            tempVec[i2--]=vec[i];
        }
    }

    tempVec[i1]=vec[n-1];
    return tempVec;
}
-(bool) testCentroid:(b2Vec2*)vs
                size:(int)count
{
    if(count < 3)
        return false;
    
	b2Vec2 c; c.Set(0.0f, 0.0f);
	float32 area = 0.0f;
    
	// pRef is the reference point for forming triangles.
	// It's location doesn't change the result (except for rounding error).
	b2Vec2 pRef(0.0f, 0.0f);
#if 0
	// This code would put the reference point inside the polygon.
	for (int32 i = 0; i < count; ++i)
	{
		pRef += vs[i];
	}
	pRef *= 1.0f / count;
#endif
    
	const float32 inv3 = 1.0f / 3.0f;
    
	for (int32 i = 0; i < count; ++i)
	{
		// Triangle vertices.
		b2Vec2 p1 = pRef;
		b2Vec2 p2 = vs[i];
		b2Vec2 p3 = i + 1 < count ? vs[i+1] : vs[0];
        
		b2Vec2 e1 = p2 - p1;
		b2Vec2 e2 = p3 - p1;
        
		float32 D = b2Cross(e1, e2);
        
		float32 triangleArea = 0.5f * D;
		area += triangleArea;
        
		// Area weighted centroid
		c += triangleArea * inv3 * (p1 + p2 + p3);
	}
    
	// Centroid
    if(area < b2_epsilon)
        return false;
    
    return true;
}
//------------------------------------------------------------------------------
-(bool) canCreateFixtureWithThisVertices:(b2Vec2*)vertices
                                    size:(int32)count
{
    if(count < 3 || count > b2_maxPolygonVertices)
        return false;
    
	int32 n = b2Min(count, b2_maxPolygonVertices);
    
	// Copy vertices into local buffer
	b2Vec2 ps[b2_maxPolygonVertices];
	for (int32 i = 0; i < n; ++i)
	{
		ps[i] = vertices[i];
	}
    
	// Create the convex hull using the Gift wrapping algorithm
	// http://en.wikipedia.org/wiki/Gift_wrapping_algorithm
    
	// Find the right most point on the hull
	int32 i0 = 0;
	float32 x0 = ps[0].x;
	for (int32 i = 1; i < count; ++i)
	{
		float32 x = ps[i].x;
		if (x > x0 || (x == x0 && ps[i].y < ps[i0].y))
		{
			i0 = i;
			x0 = x;
		}
	}
    
	int32 hull[b2_maxPolygonVertices];
	int32 m = 0;
	int32 ih = i0;
    
	for (;;)
	{
		hull[m] = ih;
        
		int32 ie = 0;
		for (int32 j = 1; j < n; ++j)
		{
			if (ie == ih)
			{
				ie = j;
				continue;
			}
            
			b2Vec2 r = ps[ie] - ps[hull[m]];
			b2Vec2 v = ps[j] - ps[hull[m]];
			float32 c = b2Cross(r, v);
			if (c < 0.0f)
			{
				ie = j;
			}
            
			// Collinearity check
			if (c == 0.0f && v.LengthSquared() > r.LengthSquared())
			{
				ie = j;
			}
		}
        
		++m;
		ih = ie;
        
		if (ie == i0){
			break;
		}
	}
	
	//int m_count = m;
    b2Vec2 m_vertices[b2_maxPolygonVertices];
	b2Vec2 m_normals[b2_maxPolygonVertices];
    
	// Copy vertices.
	for (int32 i = 0; i < m; ++i){
		m_vertices[i] = ps[hull[i]];
	}
    
	// Compute normals. Ensure the edges have non-zero length.
	for (int32 i = 0; i < m; ++i){
		int32 i1 = i;
		int32 i2 = i + 1 < m ? i + 1 : 0;
		b2Vec2 edge = m_vertices[i2] - m_vertices[i1];
        if(edge.LengthSquared() <= b2_epsilon * b2_epsilon)
            return false;
		//b2Assert(edge.LengthSquared() > b2_epsilon * b2_epsilon);
		m_normals[i] = b2Cross(edge, 1.0f);
		m_normals[i].Normalize();
	}
    
	// Compute the polygon centroid.
	return [self testCentroid:m_vertices size:m];
}
//------------------------------------------------------------------------------
-(void)createFixtureWithVertices:(std::vector<b2Vec2>&)fixtureVertices
                          onBody:(b2Body*)body
                 fromOldFixture:(b2Fixture*)fixture
{
    std::vector<b2Vec2> shapeVertices = [self clockwise:fixtureVertices];
    
    int vsize = shapeVertices.size();
    b2Vec2 *verts = new b2Vec2[vsize];
    
    for(size_t i = 0; i<shapeVertices.size(); ++i){
        verts[i].x = shapeVertices[i].x;
        verts[i].y = shapeVertices[i].y;        
    }
    
    if([self canCreateFixtureWithThisVertices:verts
       size:vsize])    
    {    
        b2PolygonShape shape;
        shape.Set(verts, vsize);		
        b2FixtureDef fixtureDef;

        fixtureDef.density = fixture->GetDensity();
        fixtureDef.friction =fixture->GetFriction();
        fixtureDef.restitution = fixture->GetRestitution();
        fixtureDef.filter = fixture->GetFilterData();
        fixtureDef.isSensor = fixture->IsSensor();

        fixtureDef.shape = &shape;
        body->CreateFixture(&fixtureDef);
    }
    else {
        CCLOG(@"Centroid was not ok - dumped the fixture");
    }
    
    delete[] verts;
}
//------------------------------------------------------------------------------
-(void)setInfoOnBody:(b2Body*)body fromBody:(b2Body*)splitBody
{
    if(!body || !splitBody)
        return;
    
    body->SetGravityScale(splitBody->GetGravityScale());
    body->SetSleepingAllowed(splitBody->IsSleepingAllowed());    
    body->SetBullet(splitBody->IsBullet());
}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
-(void) splitBody:(b2Body*)splitBody intersectionPointA:(b2Vec2)origA
                                        intersectionPointB:(b2Vec2)origB
                                                linePointA:(CGPoint)A
                                                linePointB:(CGPoint)B
{
    b2Fixture* fixture = splitBody->GetFixtureList();
    
#ifndef LH_ARC_ENABLED
    id oldSprite = (id)splitBody->GetUserData();
#else
    id oldSprite = (__bridge id)splitBody->GetUserData();
#endif
    
    if(![oldSprite isKindOfClass:[LHSprite class]])
        return;
    
    if([oldSprite imageFile] == nil)
        return;
    
    if([(LHSprite*)oldSprite isTouchedAtPoint:A])
    {
        NSLog(@"We dont't cut old sprite because A is inside");
        //if point is inside the sprite we need to cancel touch or else we will have noise
        return;
    }

    if([(LHSprite*)oldSprite isTouchedAtPoint:B])
    {
        NSLog(@"We don't cut old sprite because B is inside");
        //if point is inside the sprite we need to cancel touch or else we will have noise
        return;
    }
    
    b2World* world = splitBody->GetWorld();
    
    b2Vec2 pointA= splitBody->GetLocalPoint(origA);
    b2Vec2 pointB= splitBody->GetLocalPoint(origB);
    
    b2RayCastInput input1;
    input1.p1 = [LevelHelperLoader pointsToMeters:A];
    input1.p2 = [LevelHelperLoader pointsToMeters:B];
    input1.maxFraction = 1.0f;
    
    b2RayCastInput input2;
    input2.p1 = [LevelHelperLoader pointsToMeters:B];
    input2.p2 = [LevelHelperLoader pointsToMeters:A];
    input2.maxFraction = 1.0f;
    
    b2BodyDef bodyDef;	
    bodyDef.type = splitBody->GetType();        
    bodyDef.position = splitBody->GetPosition();
    bodyDef.angle = splitBody->GetAngle();
    bodyDef.fixedRotation = splitBody->IsFixedRotation();
    
    b2Body* body1 = world->CreateBody(&bodyDef);
    b2Body* body2 = world->CreateBody(&bodyDef);
    
    while (fixture) {
        
        int32 childIndex = 0;        
        b2RayCastOutput output1;
        b2RayCastOutput output2;
        
        if(fixture->GetShape()->GetType() != b2Shape::e_polygon)
        {
            CCLOG(@"FIXTURE IS NOT POLYGON - CANCELING CUT");
            return;
        }
        
        b2PolygonShape* poly = (b2PolygonShape*)fixture->GetShape();
        
        bool hit1 = poly->RayCast(&output1, input1,splitBody->GetTransform(), childIndex);
        
        b2Vec2 hitPoint1;
        
        if(hit1){
            hitPoint1 = input1.p1 + output1.fraction * (input1.p2 - input1.p1);            
        }
        
        bool hit2 = poly->RayCast(&output2, input2,splitBody->GetTransform(), childIndex);
        
        b2Vec2 hitPoint2;
        if(hit2){
            hitPoint2 = input2.p1 + output2.fraction * (input2.p2 - input2.p1);            
        }
        
        if(hit1 && hit2)
        {
            std::vector<b2Vec2>shape1Vertices;
            std::vector<b2Vec2>shape2Vertices;
            
            shape1Vertices.push_back(splitBody->GetLocalPoint(hitPoint1));            
            shape2Vertices.push_back(splitBody->GetLocalPoint(hitPoint1));
            
            //if we have 2 hits we can split the fixture - else we leave it as it is            
            for(int i = 0; i< poly->GetVertexCount(); ++i){                
                bool d = isLeft(pointA, pointB, poly->GetVertex(i));
                
                if(d){
                    shape1Vertices.push_back(poly->GetVertex(i));
                }
                else {
                    shape2Vertices.push_back(poly->GetVertex(i));
                }
			}
            
            if(shape1Vertices.size() < b2_maxPolygonVertices){
                shape1Vertices.push_back(splitBody->GetLocalPoint(hitPoint2));
            }
            
            if(shape2Vertices.size() < b2_maxPolygonVertices){
                shape2Vertices.push_back(splitBody->GetLocalPoint(hitPoint2));
            }
            
            if(shape1Vertices.size() >= 3 && shape1Vertices.size() <= b2_maxPolygonVertices)
            {
                [self createFixtureWithVertices:shape1Vertices
                                         onBody:body1
                                 fromOldFixture:fixture];                
            }
            else {
               // NSLog(@"MORE POINTS IN SHAPE 1 %d", shape1Vertices.size());
            }
            
            if(shape2Vertices.size() >= 3 && shape2Vertices.size() <= b2_maxPolygonVertices)
            {
                [self createFixtureWithVertices:shape2Vertices
                                         onBody:body2
                                 fromOldFixture:fixture];
            }
            else {
              //  NSLog(@"MORE POINTS IN SHAPE 2 %d", shape2Vertices.size());
            }
            
        }
        else {
            //I JUST NEED TO CREATE THE FIXTURE AND PUT IT IN THE APPROPRIATE BODY

            std::vector<b2Vec2>shape1Vertices;
            std::vector<b2Vec2>shape2Vertices;
            
            b2PolygonShape* poly = (b2PolygonShape*)fixture->GetShape();
            
            for(int i = 0; i< poly->GetVertexCount(); ++i){
                bool d = isLeft(pointA, pointB, poly->GetVertex(i));
                
                if(d){
                    shape1Vertices.push_back(poly->GetVertex(i));
                }
                else {
                    shape2Vertices.push_back(poly->GetVertex(i));
                }
			}
            
            if(shape1Vertices.size() >= 3 && shape1Vertices.size() <= b2_maxPolygonVertices)
            {
                [self createFixtureWithVertices:shape1Vertices
                                         onBody:body1
                                 fromOldFixture:fixture];
            }
            else {
               // NSLog(@"MORE POINTS IN SHAPE 1b %d", shape1Vertices.size());
            }
            
            if(shape2Vertices.size() >= 3 && shape2Vertices.size() <= b2_maxPolygonVertices)
            {
                [self createFixtureWithVertices:shape2Vertices
                                         onBody:body2
                                 fromOldFixture:fixture];
            }
            else {
              //  NSLog(@"MORE POINTS IN SHAPE 2b %d", shape2Vertices.size());
            }
            
        }
        
        fixture = fixture->GetNext();
    }
    
    if(body1 != NULL)
    {
    if (body1->GetFixtureList() != NULL) //we have no fixture in this body - lets dump it
    {
        LHSprite* newSprite1 = [self createNewSpriteFromBodyInfo:body1 andOldSprite:oldSprite];
    
        if(newSprite1){
#ifndef LH_ARC_ENABLED
            body1->SetUserData(newSprite1);
#else
            body1->SetUserData((__bridge void*)newSprite1);
#endif

            [newSprite1 setBody:body1];
        }
    }
    else {
        world->DestroyBody(body1);
        body1 = NULL;
    }
    }
    
    if(body2 != NULL)
    {
    if(body2->GetFixtureList() != NULL)
    {
        LHSprite* newSprite2 = [self createNewSpriteFromBodyInfo:body2 andOldSprite:oldSprite];
    
        if(newSprite2){
#ifndef LH_ARC_ENABLED
            body2->SetUserData(newSprite2);
#else
            body2->SetUserData((__bridge void*)newSprite2);
#endif

            [newSprite2 setBody:body2];
        } 
    }
    else {
        world->DestroyBody(body2);
        body2 = NULL;
    }
    }
    
    if(body1)
        [self setInfoOnBody:body1 fromBody:splitBody];
    if(body2)
        [self setInfoOnBody:body2 fromBody:splitBody];
    
    if([oldSprite isKindOfClass:[LHSprite class]]){
        [spritesPreviouslyCut removeObject:oldSprite];
        [(LHSprite*)oldSprite removeBodyFromWorld];//we force because of race condition
        [(LHSprite*)oldSprite removeSelf];
    }
    else{
        world->DestroyBody(splitBody);    
        [LevelHelperLoader removeTouchDispatcherFromObject:oldSprite];
        [oldSprite removeFromParentAndCleanup:YES];
    }
        
    return;
}
//------------------------------------------------------------------------------
+(float) distanceBetweenPoint:(b2Vec2)point1 andPoint:(b2Vec2)point2{
    float xd = point1.x - point2.x;
    float yd = point1.y - point2.y;
    return sqrtf(xd*xd + yd*yd);
}
//------------------------------------------------------------------------------
-(void)cutFirstSpriteIntersectedByLine:(CGPoint)startPt 
                                     lineB:(CGPoint)endPt
                                 fromWorld:(b2World*)world
{
    b2Vec2 meterStart = [LevelHelperLoader pointsToMeters:startPt];
    b2Vec2 meterEnd = [LevelHelperLoader pointsToMeters:endPt];
    
    AllBodiesRayCastCallback callback1;
    world->RayCast(&callback1, 
                   meterStart, 
                   meterEnd);
    
    AllBodiesRayCastCallback callback2;
    world->RayCast(&callback2, 
                   meterEnd , 
                   meterStart);
    
    float distance = 0.0f;
    b2Body* bodyToCut = NULL;
    b2Vec2 pointAOnBody;
    b2Vec2 pointBOnBody;
    
    std::map<b2Body*, b2Vec2>::iterator it;
    for(it = callback1.rayCastInfo.begin(); it != callback1.rayCastInfo.end(); ++it)
    {
        b2Body* key = (*it).first;    
        std::map<b2Body*, b2Vec2>::iterator it2 = callback2.rayCastInfo.find(key);
        if(it2 != callback2.rayCastInfo.end())
        {
            float dist = [LHCuttingEngineMgr distanceBetweenPoint:key->GetPosition() 
                                                         andPoint:meterStart];
            
            if(bodyToCut == NULL)
            {
                distance = dist;
                bodyToCut = key;
                pointAOnBody = (*it).second;
                pointBOnBody = (*it2).second;
            }
            else {
                
                if(dist < distance)
                {                 
                    distance = dist;
                    bodyToCut = key;
                    pointAOnBody = (*it).second;
                    pointBOnBody = (*it2).second;
                }
            }            
        }
    }

    if(bodyToCut)
    {
        [self splitBody:bodyToCut
            intersectionPointA:pointAOnBody
            intersectionPointB:pointBOnBody
                        linePointA:startPt
                        linePointB:endPt];
    }
}
//------------------------------------------------------------------------------
-(void)cutFirstSpriteWithTag:(int)tag
           intersectedByLine:(CGPoint)startPt 
                       lineB:(CGPoint)endPt
                   fromWorld:(b2World*)world
{
    b2Vec2 meterStart = [LevelHelperLoader pointsToMeters:startPt];
    b2Vec2 meterEnd = [LevelHelperLoader pointsToMeters:endPt];
    
    AllBodiesRayCastCallback callback1;
    world->RayCast(&callback1, 
                   meterStart, 
                   meterEnd);
    
    AllBodiesRayCastCallback callback2;
    world->RayCast(&callback2, 
                   meterEnd , 
                   meterStart);
    
    float distance = 0.0f;
    b2Body* bodyToCut = NULL;
    b2Vec2 pointAOnBody;
    b2Vec2 pointBOnBody;
    
    std::map<b2Body*, b2Vec2>::iterator it;
    for(it = callback1.rayCastInfo.begin(); it != callback1.rayCastInfo.end(); ++it)
    {
        b2Body* key = (*it).first;    
        
        
#ifndef LH_ARC_ENABLED
        LHSprite* sprite = (LHSprite*)key->GetUserData();
#else
        LHSprite* sprite = (__bridge LHSprite*)key->GetUserData();
#endif
        
        
        
        if(sprite && [sprite tag] == tag)
        {
            std::map<b2Body*, b2Vec2>::iterator it2 = callback2.rayCastInfo.find(key);
            if(it2 != callback2.rayCastInfo.end())
            {
                float dist = [LHCuttingEngineMgr distanceBetweenPoint:key->GetPosition() 
                                                             andPoint:meterStart];
                
                if(bodyToCut == NULL)
                {
                    distance = dist;
                    bodyToCut = key;
                    pointAOnBody = (*it).second;
                    pointBOnBody = (*it2).second;
                }
                else {
                
                    if(dist < distance)
                    {                 
                        distance = dist;
                        bodyToCut = key;
                        pointAOnBody = (*it).second;
                        pointBOnBody = (*it2).second;
                    }
                }            
            }
        }
    }
    
    if(bodyToCut)
    {
#ifndef LH_ARC_ENABLED
        LHSprite* sprite = (LHSprite*)bodyToCut->GetUserData();
#else
        LHSprite* sprite = (__bridge LHSprite*)bodyToCut->GetUserData();
#endif

        if (sprite && [sprite tag] == tag) {
            [self splitBody:bodyToCut 
                    intersectionPointA:pointAOnBody
                    intersectionPointB:pointBOnBody
                    linePointA:startPt
                    linePointB:endPt];
        }
    }
}
//------------------------------------------------------------------------------
-(void)cutSprite:(LHSprite*)oldSprite
       withLineA:(CGPoint)startPt
           lineB:(CGPoint)endPt
{
    
    b2Body* oldBody = [oldSprite body];
    
    if(oldBody == NULL)
        return;
    
    b2World* world = oldBody->GetWorld();
    
    AllBodiesRayCastCallback callback1;
    world->RayCast(&callback1, 
                   [LevelHelperLoader pointsToMeters:startPt] , 
                   [LevelHelperLoader pointsToMeters:endPt]);
    
    AllBodiesRayCastCallback callback2;
    world->RayCast(&callback2, 
                   [LevelHelperLoader pointsToMeters:endPt] , 
                   [LevelHelperLoader pointsToMeters:startPt]);
    
    std::map<b2Body*, b2Vec2>::iterator it;
    for(it = callback1.rayCastInfo.begin(); it != callback1.rayCastInfo.end(); ++it)
    {
        b2Body* key = (*it).first;    
        std::map<b2Body*, b2Vec2>::iterator it2 = callback2.rayCastInfo.find(key);
        if(it2 != callback2.rayCastInfo.end())
        {
            b2Vec2 pointA = (*it).second;
            b2Vec2 pointB = (*it2).second;
            
#ifndef LH_ARC_ENABLED
            LHSprite* sprite = (LHSprite*)key->GetUserData();
#else
            LHSprite* sprite = (__bridge LHSprite*)key->GetUserData();
#endif

            if(oldSprite == sprite)
            {
                [self splitBody:key 
             intersectionPointA:pointA
             intersectionPointB:pointB
                     linePointA:startPt
                     linePointB:endPt];
            
            }
        }
    }
}
//------------------------------------------------------------------------------
-(void)cutAllSpritesIntersectedByLine:(CGPoint)startPt
                                    lineB:(CGPoint)endPt
                                fromWorld:(b2World*)world
{
    AllBodiesRayCastCallback callback1;
    world->RayCast(&callback1, 
                   [LevelHelperLoader pointsToMeters:startPt] , 
                   [LevelHelperLoader pointsToMeters:endPt]);
    
    AllBodiesRayCastCallback callback2;
    world->RayCast(&callback2, 
                   [LevelHelperLoader pointsToMeters:endPt] , 
                   [LevelHelperLoader pointsToMeters:startPt]);
    
    std::map<b2Body*, b2Vec2>::iterator it;
    for(it = callback1.rayCastInfo.begin(); it != callback1.rayCastInfo.end(); ++it)
    {
        b2Body* key = (*it).first;    
        std::map<b2Body*, b2Vec2>::iterator it2 = callback2.rayCastInfo.find(key);
        if(it2 != callback2.rayCastInfo.end())
        {
            b2Vec2 pointA = (*it).second;
            b2Vec2 pointB = (*it2).second;
            
            [self splitBody:key 
         intersectionPointA:pointA
         intersectionPointB:pointB
                 linePointA:startPt
                 linePointB:endPt];
            
        }
    }
}
//------------------------------------------------------------------------------
-(void)cutAllSpritesWithTag:(int)tag
             intersectedByLine:(CGPoint)startPt
                         lineB:(CGPoint)endPt
                     fromWorld:(b2World*)world{

    AllBodiesRayCastCallback callback1;
    world->RayCast(&callback1, 
                   [LevelHelperLoader pointsToMeters:startPt] , 
                   [LevelHelperLoader pointsToMeters:endPt]);
    
    AllBodiesRayCastCallback callback2;
    world->RayCast(&callback2, 
                   [LevelHelperLoader pointsToMeters:endPt] , 
                   [LevelHelperLoader pointsToMeters:startPt]);
    
    std::map<b2Body*, b2Vec2>::iterator it;
    for(it = callback1.rayCastInfo.begin(); it != callback1.rayCastInfo.end(); it++)
    {
        b2Body* key = (*it).first;    
        
        std::map<b2Body*, b2Vec2>::iterator it2 = callback2.rayCastInfo.find(key);
        if(it2 != callback2.rayCastInfo.end())
        {
            b2Vec2 pointA = (*it).second;
            b2Vec2 pointB = (*it2).second;
        
#ifndef LH_ARC_ENABLED
            LHSprite* sprite = (LHSprite*)key->GetUserData();
#else
            LHSprite* sprite = (__bridge LHSprite*)key->GetUserData();
#endif
            
            if(sprite && [sprite tag] == tag)
            {
                [self splitBody:key 
                   intersectionPointA:pointA
                   intersectionPointB:pointB
                           linePointA:startPt
                           linePointB:endPt];                
            }            
        }
    }
}
//------------------------------------------------------------------------------
- (float)randomFloatBetween:(float)smallNumber andBig:(float)bigNumber {
    float diff = bigNumber - smallNumber;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}
//------------------------------------------------------------------------------
-(void) createExplosionWithCuts:(int)numberOfCuts 
                         radius:(float)radius
                        atPoint:(CGPoint)explosionPoint
{    
    explosionLines.clear();    
    for(int i = 0; i < numberOfCuts; ++i)
    {
        float cutAngle = [self randomFloatBetween:0 andBig:360];
                
        float x = explosionPoint.x + radius * cos (cutAngle);
        float y = explosionPoint.y + radius * sin (cutAngle);
        
        float x1 = explosionPoint.x - radius * cos (cutAngle);
        float y1 = explosionPoint.y - radius * sin (cutAngle);
        
        explosionLines.push_back(CGPointMake(x, y));
        explosionLines.push_back(CGPointMake(x1, y1));
    }
}
//------------------------------------------------------------------------------
-(void)cutSpritesFromPoint:(CGPoint)point
                     inRadius:(float)radius
                          cuts:(int)numberOfCuts
                     fromWorld:(b2World*)world
{
    [self createExplosionWithCuts:numberOfCuts
                           radius:radius
                          atPoint:point];
    
    for(size_t i = 0; i< explosionLines.size()/2; i +=2)
    {
        CGPoint lineA = explosionLines[i*2+0];
        CGPoint lineB = explosionLines[i*2+1];
        [self cutAllSpritesIntersectedByLine:lineA
                                       lineB:lineB
                                   fromWorld:world];
    }
}
//------------------------------------------------------------------------------
-(void)cutSpritesWithTag:(int)tag
               fromPoint:(CGPoint)point
                inRadius:(float)radius
                    cuts:(int)numberOfCuts
               fromWorld:(b2World*)world
{
    [self createExplosionWithCuts:numberOfCuts
                           radius:radius
                          atPoint:point];
    
    for(size_t i = 0; i< explosionLines.size()/2; i +=2)
    {
        CGPoint lineA = explosionLines[i*2+0];
        CGPoint lineB = explosionLines[i*2+1];
        [self cutAllSpritesWithTag:tag
                 intersectedByLine:lineA
                             lineB:lineB
                         fromWorld:world];        
    }
}

//-(NSArray*)cutSprite:(LHSprite*)oldSprite
//           fromPoint:(CGPoint)point
//            inRadius:(float)radius
//                cuts:(int)numberOfCuts
//{
//    if(numberOfCuts %2 != 0)
//    {
//        NSLog(@"numberOfCuts must be EVEN");
//        return nil;
//    }
//    
//    [self createExplosionWithCuts:numberOfCuts
//                           radius:radius
//                          atPoint:point];
//    
//    NSMutableSet* spritesSet = [[[NSMutableSet alloc] init] autorelease];
//    for(int i = 0; i< explosionLines.size(); i +=2)
//    {
//        CGPoint lineA = explosionLines[i];
//        CGPoint lineB = explosionLines[i+1];
//        
//        NSArray* createdSprites =  [self cutSprite:oldSprite
//                                         withLineA:lineA
//                                             lineB:lineB];
//        
//        [spritesSet addObjectsFromArray:createdSprites];
//    }
//    
//    return [spritesSet allObjects];    
//}
//

-(void) explodeSpritesInRadius:(float)radius
                     withForce:(float)maxForce
                      position:(CGPoint)pos
                       inWorld:(b2World*)world
{
    [self explodeSpritesInRadius:radius withForce:maxForce position:pos inWorld:world suction:NO];
}

-(void) implodeSpritesInRadius:(float)radius
                     withForce:(float)maxForce
                      position:(CGPoint)pos
                       inWorld:(b2World*)world
{
    [self explodeSpritesInRadius:radius withForce:maxForce position:pos inWorld:world suction:YES];
}

//------------------------------------------------------------------------------
-(void)debugDrawing{
    
    for(size_t i = 0; i < explosionLines.size(); i+=2)
    {
#if COCOS2D_VERSION >= 0x00020000 
        
        //XXX - GLES 2.0 draw call here
#else
        
        glDisable(GL_TEXTURE_2D);		
        glColor4f(1, 0, 0, 1);
        CGPoint vertices[2];
        
        vertices[0] = explosionLines[i];
        vertices[1] = explosionLines[i+1];
        
        glVertexPointer(2, GL_FLOAT, 0, &vertices);
        glDrawArrays(GL_LINES, 0, 2);
#endif
    }
}

@end
