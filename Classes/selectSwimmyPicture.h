//
//  selectSwimmyPicture.h
//  iPadCamera
//
//  Created by 西島和彦 on 2014/04/18.
//
//

#import "PopUpViewContollerBase.h"
#import "OKDThumbnailItemView.h"
#import "def64bit_common.h"

@protocol selectSwimmyPictureDelegate;

@interface selectSwimmyPicture : PopUpViewContollerBase
<
OKDThumbnailItemViewDelegate
>
{

	NSMutableArray      *tumbnailItems; // サムネイルItemのリスト
    UIScrollView        *_scrollView;   // スクロールビュー
	UIView              *_drawView;     // 描画View
	USERID_INT           _selectedUserID;    // 選択されたユーザのID

    NSMutableArray      *selectItemOrder;   // 選択サムネイルItemの順序Table
    NSString            *_lblText;
    
    IBOutlet UIButton   *btnSet;        // 設定ボタン
    IBOutlet UIButton   *btnCancel;     // 取消ボタン
    IBOutlet UILabel    *lblTitle;      // タイトルラベル
    
}
@property (nonatomic, assign) id<selectSwimmyPictureDelegate>   myDelegate;

- (IBAction)OnSelectOK:(id)sender;      // 設定ボタンアクション
- (IBAction)OnSelectCancel:(id)sender;  // 取消ボタンアクション

// 初期化
- (id) initWithSwimmyPicture:(NSUInteger)popUpID
           popOverController:(UIPopoverController *)controller
                    callBack:(id)callBackDelegate
                selectUserID:(USERID_INT)userID              // ユーザID
                       title:(NSString *)lblString;
@end

@protocol selectSwimmyPictureDelegate <NSObject>

// Swimmy画像設定
- (void)OnSelectComparePictureSet:(NSMutableArray *)view;
// キャンセル
- (void)OnSelectComparePictureCancel;

@end
