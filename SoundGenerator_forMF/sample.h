//
//  sample.h
//  SoundGenerator_forMF
//
//  Created by 長谷部 雅彦 on 2015/03/20.
//  Copyright (c) 2015年 長谷部 雅彦. All rights reserved.
//

#ifndef SoundGenerator_forMF_sample_h
#define SoundGenerator_forMF_sample_h

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "MIDIDriver.h"
@interface WebViewDelegate : NSObject <WKScriptMessageHandler>
@property (nonatomic, strong) MIDIDriver *midiDriver;
@property (nonatomic, copy) BOOL (^confirmSysExAvailability)(NSString *url);
@end
#endif
