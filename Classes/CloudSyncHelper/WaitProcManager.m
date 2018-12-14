//
//  WaitProcManager.m
//  iPadCamera
//
//  Created by  on 12/04/05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WaitProcManager.h"

@implementation WaitProcManager

// 処理完了のリセット
- (void) resetWaitProcComplite
{   _waitCounter = 0; }

// 処理の完了を待つ
- (BOOL) wait4ProcCommpliteWithTime:(NSInteger)count
{
    BOOL stat = YES;
    
    _waitCounter = count * 2;
    
    NSInteger wait;
    while ((wait = _waitCounter) > 0)
    {
        [[NSRunLoop currentRunLoop]
            runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5f]];
        
        if ((-- _waitCounter) <= 0)
        {   
            stat = NO; 
            break;
        }
    }
    
    return (stat);
}

@end
