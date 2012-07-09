
#import "LHContactListener.h"


LHContactListener::LHContactListener(){
}

LHContactListener::~LHContactListener() {
}

void LHContactListener::BeginContact(b2Contact* contact) {

    //NSLog(@"BEGIN CONTACT before");
    if(contact->GetFixtureA() != NULL && contact->GetFixtureB() != NULL)
        (*beginEndSolveSelector)(nodeObject,contact, true);
    
    //NSLog(@"BEGIN CONTACT");
}

void LHContactListener::EndContact(b2Contact* contact) {

    //NSLog(@"END CONTACT before");
    if(contact->GetFixtureA() != NULL && contact->GetFixtureB() != NULL)
        (*beginEndSolveSelector)(nodeObject,contact, false);
    
    //NSLog(@"END CONTACT");
}

void LHContactListener::PreSolve(b2Contact* contact, 
								 const b2Manifold* oldManifold) {
    //NSLog(@"PRE SOLVE before");
    if(contact->GetFixtureA() != NULL && contact->GetFixtureB() != NULL)
        (*preSolveSelector)( nodeObject, contact, oldManifold);
    
    //NSLog(@"PRE SOLVE");
}

void LHContactListener::PostSolve(b2Contact* contact, 
								  const b2ContactImpulse* impulse) {

    //NSLog(@"POST SOLVE before");
    if(contact->GetFixtureA() != NULL && contact->GetFixtureB() != NULL)    
    (*postSolveSelector)(nodeObject, contact, impulse);
    
    //NSLog(@"POST SOLVE");
}
