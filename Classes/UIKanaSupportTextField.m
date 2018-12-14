//
//  UIKanaSupportTextField.m
//  AutoKanaInputter
//
//  Created by MacBook on 11/05/08.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UIKanaSupportTextField.h"

/*
 ** DEFINE
 */
#define OS_VERSION 7.0f

// privateメンバのプロパティ宣言
@interface UIKanaSupportTextField()
@property(nonatomic, retain) NSString *fixedKana;
@property(nonatomic, retain) NSString *_currentKana;
-(BOOL)isAlphabet:(unichar)unic;
-(BOOL)isKana:(unichar)unic;
-(BOOL)isAllKana:(NSString*)inputStr;
@end

@implementation UIKanaSupportTextField

@synthesize fixedKana = _fixedKana;
@synthesize _currentKana;

@synthesize kanaTextField = _kanaTextField;
static NSInteger       _running;               // 入力数

#pragma mark private_methods


//イニシャライザ
-(void) initialize
{
	_fixedLength = [self.text length];		// フィールドの既存状態を初期値とする
	self.fixedKana = [NSString string];		// 空の文字列
	self._currentKana = [NSString string];	// 空の文字列
}

// 入力文字列の変更
-(BOOL)_changeText:(NSString*)inputStr InputKana:(NSString*)inputKana
{
#ifdef DEBUG
	NSLog(@"AutoKanaInputter.inputStr is called input str->%@", inputStr);
#endif
	NSInteger len = [inputStr length];
	
	// 平仮名確定処理後に1文字削除された場合
    //2012 6/26 伊藤 文字数判定を既存数-1=確定前数ではなく、既存数>確定前数に
	if (len < _fixedLength) {
		_fixedLength = len;	// _fixedLength--でもOK
		return NO;
	}
	// 追加文字列を取得
	NSString *addedString = [inputStr substringWithRange:NSMakeRange(_fixedLength, len - _fixedLength)];	// 追加文字列
#ifdef DEBUG
    NSLog(@"%@",addedString);
#endif
	BOOL fixed = NO;	// 確定処理
	NSInteger addedLength = [addedString length];	// 追加文字列文字数
	NSInteger currentKanaLength = [self._currentKana length];	// 現カナ文字数
	
	// 追加文字列が無い場合（漢字変換時に発生する）
	if (addedLength == 0)
	{
		return NO;
	}
	
	if (addedLength == currentKanaLength + 1)
	{
		// 1文字追加された場合
		unichar unic = [[addedString substringWithRange:NSMakeRange(currentKanaLength, 1)] characterAtIndex:0]; // 追加された1文字
		if ([self isKana:unic])
		{
			// 追加された文字が平仮名
			if ([self isAllKana:addedString])
			{
				// 追加文字列全てが平仮名
				self._currentKana = [NSString stringWithString:addedString];
				return NO;
			}
			else
			{
				// 追加文字列に平仮名以外が含まれている
				// 予測変換対応（「やりな」入力後に予測変換の「やり直し」で確定した場合など）
				fixed = YES;
			}
		}
		else if ([self isAlphabet:unic])
		{
			// 追加された文字がアルファベット（入力中）
			return NO;
		}
		else
		{
			// 追加された文字がアルファベット・平仮名以外(記号など）、もしくは予測変換入力で文字数が１文字増えた
			fixed = YES;
		}
	}
	else if (addedLength == currentKanaLength - 1)
	{
		NSString *currentKanaRemoved = [self._currentKana substringWithRange:NSMakeRange(0, currentKanaLength - 1)]; // _currentKanaの1文字削除分
		if ([addedString isEqualToString:currentKanaRemoved])
		{
			// 1文字削除された場合
			self._currentKana = [NSMutableString stringWithString:currentKanaRemoved];
			return NO;
		}
		else
		{
			// 漢字変換などで文字数が減る
			fixed = YES;
		}
	}
	else if (addedLength == currentKanaLength)
	{
		if ([addedString isEqualToString:self._currentKana])
		{
			// 完全に同じ文字列だが，何らかの理由でイベントが発生した場合（確定キーなど）
			fixed = YES;
		}
		else
		{
			// 最後の1文字だけ変化していて、かつ平仮名の場合は、フリック入力キーボードで濁点・半濁点である
			//
			//
			//
            NSString *addOnes = [inputStr substringWithRange:NSMakeRange([inputStr length] - 1 , 1)]; // 最後の1文字
			if (![self isDakuon:addOnes] && [self isKana:[addOnes characterAtIndex:0]]) {
                if (currentKanaLength > 0) {
                    NSString *currentKanaRemoved = [self._currentKana substringWithRange:NSMakeRange(0, currentKanaLength - 1)]; // _currentKanaの1文字削除分
                    self._currentKana = [NSMutableString stringWithString:currentKanaRemoved];
                }
                self._currentKana = [self._currentKana stringByAppendingString:addOnes];
                fixed = NO;
            }else if([self isDakuon:addOnes]){
                fixed = NO;
            }
            else{
                // 漢字変換などで文字が変わる
                fixed = YES;
            }
			

		}
	}
	else if (addedLength == currentKanaLength + 2)
	{
		// 2文字追加された場合
		NSString *added2Char = [addedString substringWithRange:NSMakeRange(currentKanaLength, 2)];
		unichar unic1 = [added2Char characterAtIndex:0]; // 追加された1文字目
		unichar unic2 = [added2Char characterAtIndex:1]; // 追加された1文字目
		if (unic1 == 0x3063)
		{
			// １文字目が「っ」の場合
			self._currentKana = [self._currentKana stringByAppendingString:@"っ"];
			return NO;
		}
		else if (unic1 == 0x3093)
		{
			// １文字目が「ん」の場合（nkで「んk」などに対応）
			self._currentKana = [self._currentKana stringByAppendingString:@"ん"];
			return NO;
		}
		else if ([self isAlphabet:unic1] && [self isAlphabet:unic2])
		{
			// 追加された2文字がアルファベット（入力中）（shaで「しゃ」などの入力中）
			return NO;
		}
		else if ([self isKana:unic1] && [self isKana:unic2])
		{
			// 追加された2文字がアルファベット（入力中）（shaで「しゃ」などが確定）
			self._currentKana = [NSString stringWithString:addedString];
			return NO;
		}
		else
		{
			// 追加された文字がアルファベット・平仮名以外(記号など）、もしくは漢字変換
			fixed = YES;
		}
	}
	else
	{
		// 漢字変換などで文字数が変わる
		fixed = YES;
	}
	
	// 平仮名確定処理
	if (fixed)
	{
		NSString *kana = [inputKana stringByAppendingString:self._currentKana];
		self.fixedKana = kana;
		self._currentKana = [NSString string];
		_fixedLength = len;
		return YES;
	}
	
	return NO;
}

// 文字がアルファベットか判定
-(BOOL)isAlphabet:(unichar)unic
{
	if ((unic >= 0x41 && unic <= 0x5A) || (unic >= 0x61 && unic <= 0x7A)){
		return YES;
	}else {
		return NO;
	}
}

// 文字が平仮名か判定
-(BOOL)isKana:(unichar)unic
{
	if (unic >= 0x3041 && unic <= 0x3093){
		return YES;
	}else {
		return NO;
	}
}

//文字に濁音、半濁音が含まれるか判定
-(BOOL)isDakuon:(NSString *)chara
{
    if ([chara isEqualToString:@"が"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ぎ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ぐ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"げ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ご"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ざ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"じ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ず"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ぜ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ぞ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"だ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ぢ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"づ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"で"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ど"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ば"]) {
        return NO;
    }
    if ([chara isEqualToString:@"び"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ぶ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"べ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ぼ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ぱ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ぴ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ぷ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ぺ"]) {
        return YES;
    }
    if ([chara isEqualToString:@"ぽ"]) {
        return YES;
    }
    return NO;
}

// 全ての文字が平仮名か判定
-(BOOL)isAllKana:(NSString*)inputStr
{
	NSInteger len = [inputStr length];
	for(NSInteger i = 0; i < len; i++)
	{
		if(![self isKana:[inputStr characterAtIndex:i]])
		{
			return NO;
		}
	}
	return YES;
}

#pragma mark life_cycle

// InterfaceBuilderからの初期化
- (void)awakeFromNib
{
	[self addTarget:self action:@selector(onTextEditBegin:) forControlEvents:UIControlEventEditingDidBegin];
	[self addTarget:self action:@selector(changeText:) forControlEvents:UIControlEventEditingChanged];
}

// 初期化
- (void) initWithKanaTextField:(UITextField*)kanaTextField
{
	_kanaTextField = kanaTextField;
	[_kanaTextField retain];
    _running = 0;
	[self initialize];
}


- (void) dealloc
{
	if (_kanaTextField)
	{	[_kanaTextField release]; }
	
	[super dealloc];
}

#pragma mark controlEvents

// 編集開始
- (IBAction)onTextEditBegin:(id)sender
{
	[self initialize];
}

// 文字列変更
- (IBAction)changeText:(id)sender
{
    _running++;
	if (! _kanaTextField)
	{	return; }
#if 1 // 潜在的バグ kikuta - start - 2014/02/05
	// iOS7以降
    // 編集開始時、絶対に一文字は無視をしていた。
    // このままだと母音ではじまる「あ〜お」が一文字目だと無視される
    if (!_editBegin)
    {
        _editBegin = YES;
        NSLog(@"editBegin YES");
        if ( [[[UIDevice currentDevice] systemVersion] floatValue] < OS_VERSION )
        {
            _running--;
            return;
        }
    }
#else
//	if (!_editBegin) {
//      _editBegin = YES;
//      _running--;
//      NSLog(@"editBegin YES");
//      return;
//  }
#endif // 潜在的バグ kikuta - end - 2014/02/05

	// 全削除の場合は、かなも削除
	if ([self.text length] <= 0)
	{ 
		_kanaTextField.text = @"";
        _editBegin = NO;
        NSLog(@"editBegin NO");
		[self initialize];
        _running--;
		return;
	}
	
    @try {
    
        if ([self _changeText:self.text InputKana:_kanaTextField.text])
        {
            _kanaTextField.text = self.fixedKana;
        }
    }
    @catch (NSException* exception) {
        NSLog(@"UIKanaSupport changeText: Caught %@: %@", [exception name], [exception reason]);

    }
    _running--;

}

#pragma mark UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField 
			shouldChangeCharactersInRange:(NSRange)range 
				replacementString:(NSString *)string
{
	NSLog (@"shouldChangeCharactersInRange at string:%@", string);
	
	return (YES);
}

@end
