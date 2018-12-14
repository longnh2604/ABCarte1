//
//  WaitProcManager.h
//  iPadCamera
//
//  Created by  on 12/04/05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *-----------------------------------------------------------------
 *      処理完了の待機
 *-----------------------------------------------------------------
 */
@interface WaitProcManager : NSObject 
{
    NSInteger _waitCounter;
}

// 処理完了のリセット
- (void) resetWaitProcComplite;

// 処理の完了を待つ
- (BOOL) wait4ProcCommpliteWithTime:(NSInteger)count;

@end
