//
//  BroadcastMailUserInfo.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/04.
//
//

/*
 ** IMPORT
 */
#import <Foundation/Foundation.h>
#import "userInfo.h"

/*
 ** INTERFACE
 */
@interface BroadcastMailUserInfo : NSObject
{
	BOOL _selected;			// ユーザーが選択されている
	BOOL _blockMail;		// ユーザーの受信拒否状態
	userInfo* _userInfo;	// ユーザー情報
    NSString* _mailAddress; // ユーザーメールアドレス
    NSIndexPath* _indexPath;//
}

/*
 ** PROPERTY
 */
@property BOOL selected;
@property BOOL blockMail;
@property(nonatomic, retain) NSString* mailAddress;
@property(nonatomic, retain) userInfo* userInfo;
@property(nonatomic, retain) NSIndexPath* indexPath;

@end
