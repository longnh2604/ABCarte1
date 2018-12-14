//
//  GojyuonSearchPopup.h
//  iPadCamera
//
//  Created by MacBook on 10/11/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PopUpViewContollerBase.h"

// あいうえお...... など個別文字の定義
/*
 各ボタンのtagの内容 
 行：0x00*0  0x10=あ行 0x20=か行 0x30=さ行 ..... 0x90=ら行 0xA0=わ行
 　　例）あ＝0x11=17  い=0x12=18 .... か=0x21=33
 段：0x000*  0x01=あ段 0x02=い段 0x03=う段 0x04=え段 0x05=お段
 選択中：0x8000  選択なし：0x0000
 */
// 個別文字ボタンの選択中を示す
#define BUTTON_STATE_PUSH	(NSInteger)0x8000 

// 五十音の行数
#define GOJYUON_ROW_NUM		(NSInteger)10
// 五十音の列数
#define GOJYUON_COL_NUM		(NSInteger)5

@interface GojyuonSearchPopup : PopUpViewContollerBase {

	NSInteger			clickedID;				// ClickされたボタンのtagID
	
	// 個別文字ボタンの押されている状態：行×段で構成
	NSString			*btnState[GOJYUON_ROW_NUM][GOJYUON_COL_NUM];
    
    IBOutlet UIButton   *btnSearch;     // 検索ボタン
    IBOutlet UIButton   *btnCancel;     // キャンセルボタン
    IBOutlet UIButton   *btnAAline;     // あ行ボタン
    IBOutlet UIButton   *btnKAline;     // か行ボタン
    IBOutlet UIButton   *btnSAline;     // さ行ボタン
    IBOutlet UIButton   *btnTAline;     // た行ボタン
    IBOutlet UIButton   *btnNAline;     // な行ボタン
    IBOutlet UIButton   *btnHAline;     // は行ボタン
    IBOutlet UIButton   *btnMAline;     // ま行ボタン
    IBOutlet UIButton   *btnYAline;     // や行ボタン
    IBOutlet UIButton   *btnRAline;     // ら行ボタン
    IBOutlet UIButton   *btnWAline;     // わ行ボタン
}

// 個別文字ボタンのクリック
- (IBAction) OnOneStringButton:(id)sender;

// 個別文字ボタンの検索文字列作成
- (void)  searchStringMake4OneString: (NSMutableArray*)searchStrings;

@end
