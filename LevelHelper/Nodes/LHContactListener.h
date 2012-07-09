//
//  LHContactListener.h

#import "Box2D.h"
#import <vector>
#import <algorithm>

class LHContactListener : public b2ContactListener {
	
public:	
    void* nodeObject;
    void (*preSolveSelector)(void*, 
                             b2Contact* contact, 
                             const b2Manifold* oldManifold);
    
    void (*postSolveSelector)(void*, 
                              b2Contact* contact, 
                              const b2ContactImpulse* impulse);

    void (*beginEndSolveSelector)(void*, 
                              b2Contact* contact, 
                              bool isBegin);

    LHContactListener();
    ~LHContactListener();
	
    virtual void BeginContact(b2Contact* contact);
    virtual void EndContact(b2Contact* contact);
    virtual void PreSolve(b2Contact* contact, const b2Manifold* oldManifold);    
    virtual void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse);
	
};
