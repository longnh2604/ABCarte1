//
//  MicUtil.h
//  iPadCamera
//
//  Created by 西島和彦 on 2014/06/11.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface MicUtil : NSObject

typedef void (^IsMicAccessEnableWithIsShowAlertBlock)(BOOL isMicAccessEnable);

+ (void)isMicAccessEnableWithIsShowAlert:(BOOL)_isShowAlert
                              completion:(IsMicAccessEnableWithIsShowAlertBlock)_completion;

@end
