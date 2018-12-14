//
//  NSString+Validation.m
//  iPadCamera
//
//  Created by Long on 2018/02/09.
//

#import "NSString+Validation.h"

@implementation NSString(Validation)

- (BOOL)isAllHalfWidthCharacter
{
    NSUInteger nsStringlen = [self length];
    const char *utf8 = [self UTF8String];
    size_t cStringlen = strlen(utf8);
    if (nsStringlen == cStringlen) {
        return YES;
    } else {
        return NO;
    }
}

@end
