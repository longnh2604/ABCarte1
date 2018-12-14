//
//  DevStatusCheck.h
//  iPadCamera
//
//  Created by 西島和彦 on 2014/10/23.
//
//

#import <Foundation/Foundation.h>
#import <mach/mach.h>

@interface DevStatusCheck : NSObject

+ (unsigned int)getFreeMemory;

@end
