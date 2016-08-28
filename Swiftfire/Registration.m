//
//  Registration.m
//  Swiftfire
//
//  Created by Marinus van der Lugt on 15/08/16.
//  Copyright © 2016 Marinus van der Lugt. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "Test.h"
#import <objc/objc-class.h>

void activateLaunchActions() {
    
    // Get a list of all classes
    int numClasses = 0, newNumClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    while (numClasses < newNumClasses) {
        numClasses = newNumClasses;
        Class newClasses[numClasses];
        classes = newClasses;
        newNumClasses = objc_getClassList(classes, numClasses);
    }
    
    // Get the protocol they have to confirm to
    Protocol *prot = objc_getProtocol("MyProtocol");
    
    // Get the selector to be called
    SEL sel = sel_registerName("launchAction");
    
    // Create the registration caller from objc_msgSend
    typedef void (*send_type)(Class, SEL);
    send_type callRegistration = (send_type)objc_msgSend;
    
    // Call the registration for all classes that confirm to the protocol
    for (int i=0; i<numClasses; i++) {
        if (class_conformsToProtocol(classes[i], prot)) {
            callRegistration(classes[i], sel);
        }
    }
}
