//
//  main.m
//  iPadCamera
//
//  Created by MacBook on 10/09/07.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal;
    @try {
        retVal = UIApplicationMain(argc, argv, nil, nil);    }
    @catch (NSException *exception) {
        NSLog(@"%@", [exception callStackSymbols]); //< ★1
        @throw exception; //< ★2
    }@finally {
        [pool release];
    }
    return retVal;
}
