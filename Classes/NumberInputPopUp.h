//
//  NumberInputPopUp.h
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import "PopUpViewContollerBase.h"
// フリックボタンのタグID定義
typedef enum {
	BTN_HEIGHT              = 1,        //身長
	BTN_WEIGHT              = 2,        //体重
	BTN_TOPBREAST           = 3,        //トップバスト
	BTN_UNDERBREAST         = 4,        //アンダーバスト
    BTN_WAIST               = 5,        //ウエスト
    BTN_HIP                 = 6,        //ヒップ周り
    BTN_THIGH               = 7,        //太もも
    BTN_HIPHEIGHT           = 8,        //ヒップ高
    BTN_WAISTHEIGHT         = 9,        //ウエスト高
    BTN_TOPBREASTHEIGHT     =10,        //トップバスト高
    
    BTN_SET_HEIGHT          = 101,        //着衣身長
	BTN_SET_WEIGHT          = 102,        //着衣体重
	BTN_SET_TOPBREAST		= 103,        //着地トップバスト
	BTN_SET_UNDERBREAST     = 104,        //着衣アンダーバスト
    BTN_SET_WAIST           = 105,        //着衣ウエスト
    BTN_SET_HIP             = 106,        //着衣ヒップ周り
    BTN_SET_THIGH           = 107,        //着衣太もも
    BTN_SET_HIPHEIGHT       = 108,        //着衣ヒップ高
    BTN_SET_WAISTHEIGHT     = 109,        //着衣ウエスト高
    BTN_SET_TOPBREASTHEIGHT = 110,        //着衣トップバスト高
    
} BODY_CHECK_BUTTON_TAG_ID;

@interface NumberInputPopUp : PopUpViewContollerBase{

    //数値キー
    IBOutlet UIButton *num1;
    IBOutlet UIButton *num2;
    IBOutlet UIButton *num3;
    IBOutlet UIButton *num4;
    IBOutlet UIButton *num5;
    IBOutlet UIButton *num6;
    IBOutlet UIButton *num7;
    IBOutlet UIButton *num8;
    IBOutlet UIButton *num9;
    IBOutlet UIButton *num0;
    IBOutlet UIButton *comma;
    
    IBOutlet UIButton *decision;        //決定
    IBOutlet UIButton *cancel;          //キャンセル
    IBOutlet UIButton *backSpace;       //バックスペース
    
    IBOutlet UILabel *lblNumber;        //現在数値
    IBOutlet UILabel *lblTitle;         //タイトルバー
    IBOutlet UILabel *lblUnit;
    
    float           oldNumber;          //変更前数
    float           maxNum;             //最大値
    float           minNum;             //最低値
    NSString        *editNumber;        //編集中数字
    NSString        *strUnit;           //単位(cm,kg)
    NSString        *editEntry;         //編集中項目
    
    UIButton        *editButton;        //呼び出したボタン
    
    BOOL            didInput;          //画面を開いて一度でも入力したか
    
    BOOL            IntMode;            //個数入力
}

@property (nonatomic,retain)    NSString        *editNumber;        //編集中数字
@property (nonatomic,retain)    NSString        *strUnit;           //単位(cm,kg)
@property (nonatomic,retain)    NSString        *editEntry;         //編集中項目

- (id)initWithButton:(UIButton *)selectButton
           selectNum:(CGFloat)selectNum
             popUpID:(NSUInteger)popUpID
            callBack:(id)callBackDelegate;

- (id)initWithIntButton:(UIButton *)selectButton
              selectNum:(NSInteger)selectNum
                popUpID:(NSUInteger)popUpID
               callBack:(id)callBackDelegate;
@end
