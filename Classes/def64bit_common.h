//
//  def64bit_common.h
//  iPadCamera
//
//  Created by 西島和彦 on 2014/12/17.
//
//

#ifndef iPadCamera_def64bit_common_h
#define iPadCamera_def64bit_common_h

/**
 * UserID, HistID などを64bit対応にする時に、int->NSIntegerに変更を検討する
 */
// ユーザID用の定義 intで4byte扱いとする
typedef int                     USERID_INT;     // ユーザーIDを4byteに統一させる
typedef int                     HISTID_INT;     // histIDを4byteに統一させる
typedef HISTID_INT              WORKITEM_INT;   // workItemIDを4byteに統一
                                                // [histIDと共通のテーブル使用の箇所が有るため]
typedef int                     SHOPID_INT;

#define USERID_INTMIN           INT32_MIN
#define HISTID_INTMIN           INT32_MIN
#define WORKID_INTMIN           INT32_MIN

#endif
