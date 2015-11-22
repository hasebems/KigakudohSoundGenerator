//
//  sample.m
//  SoundGenerator_forMF
//
//  Created by 長谷部 雅彦 on 2015/03/20.
//  Copyright (c) 2015年 長谷部 雅彦. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <mach/mach_time.h>

#import "sample.h"

@interface WebViewDelegate () {
	BOOL _sysexEnabled;
}
@end

@implementation WebViewDelegate

- (void)invokeJSCallback_onNotReady:(WKWebView *)webView
{
	[webView evaluateJavaScript:@"_callback_onNotReady();" completionHandler:nil];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
	if ([message.name isEqualToString:@"onready"] == YES) {
		__block uint64_t timestampOrigin = 0;
		
		mach_timebase_info_data_t base;
		mach_timebase_info(&base);
		
		NSDictionary *dict = message.body;
		
		NSDictionary *MIDIoptions = dict[@"options"];
		NSString *url = dict[@"url"];
		
		_sysexEnabled = NO;
		id sysexOption = MIDIoptions[@"sysex"];
		if ([sysexOption isKindOfClass:[NSNumber class]] && [sysexOption boolValue] == YES) {
			if (_confirmSysExAvailability) {
				if (_confirmSysExAvailability(url) == NO) {
					[self invokeJSCallback_onNotReady:message.webView];
					return;
				} else {
					_sysexEnabled = YES;
				}
			} else {
				[self invokeJSCallback_onNotReady:message.webView];
				return;
			}
		}
		
		if (_midiDriver.isAvailable == NO) {
			[self invokeJSCallback_onNotReady:message.webView];
			return;
		}
		
		// Setup the callback for receiving MIDI message.
		_midiDriver.onMessageReceived = ^(ItemCount index, NSData *receivedData, uint64_t timestamp) {
			NSMutableArray *array = [NSMutableArray arrayWithCapacity:[receivedData length]];
			for (int i = 0; i < [receivedData length]; i++) {
				[array addObject:[NSNumber numberWithUnsignedChar:((unsigned char *)[receivedData bytes])[i]]];
			}
			NSData *dataJSON = [NSJSONSerialization dataWithJSONObject:array options:0 error:nil];
			NSString *dataJSONStr = [[NSString alloc] initWithData:dataJSON encoding:NSUTF8StringEncoding];
			
			double deltaTime_ms = (double)(timestamp - timestampOrigin) * base.numer / base.denom / 1000000.0;
			[message.webView evaluateJavaScript:[NSString stringWithFormat:@"_callback_receiveMIDIMessage(%lu, %f, %@);", index, deltaTime_ms, dataJSONStr] completionHandler:nil];
		};
		
		__weak MIDIDriver *midiDriver = _midiDriver;
		_midiDriver.onDestinationPortAdded = ^(ItemCount index) {
			NSDictionary *info = [midiDriver portinfoFromDestinationEndpointIndex:index];
			NSData *JSON = [NSJSONSerialization dataWithJSONObject:info options:0 error:nil];
			NSString *JSONStr = [[NSString alloc] initWithData:JSON encoding:NSUTF8StringEncoding];
			
			[message.webView evaluateJavaScript:[NSString stringWithFormat:@"_callback_addDestination(%lu, %@);", index, JSONStr] completionHandler:nil];
		};
		
		_midiDriver.onSourcePortAdded = ^(ItemCount index) {
			NSDictionary *info = [midiDriver portinfoFromSourceEndpointIndex:index];
			NSData *JSON = [NSJSONSerialization dataWithJSONObject:info options:0 error:nil];
			NSString *JSONStr = [[NSString alloc] initWithData:JSON encoding:NSUTF8StringEncoding];
			
			[message.webView evaluateJavaScript:[NSString stringWithFormat:@"_callback_addSource(%lu, %@);", index, JSONStr] completionHandler:nil];
		};
		
		_midiDriver.onDestinationPortRemoved = ^(ItemCount index) {
			[message.webView evaluateJavaScript:[NSString stringWithFormat:@"_callback_removeDestination(%lu);", index] completionHandler:nil];
		};
		
		_midiDriver.onSourcePortRemoved = ^(ItemCount index) {
			[message.webView evaluateJavaScript:[NSString stringWithFormat:@"_callback_removeSource(%lu);", index] completionHandler:nil];
		};
		
		// Send all MIDI ports information when the setup request is received.
		ItemCount srcCount  = [_midiDriver numberOfSources];
		ItemCount destCount = [_midiDriver numberOfDestinations];
		
		NSMutableArray *srcs  = [NSMutableArray arrayWithCapacity:srcCount];
		NSMutableArray *dests = [NSMutableArray arrayWithCapacity:destCount];
		
		
		for (ItemCount srcIndex = 0; srcIndex < srcCount; srcIndex++) {
			NSDictionary *info = [_midiDriver portinfoFromSourceEndpointIndex:srcIndex];
			if (info == nil) {
				[self invokeJSCallback_onNotReady:message.webView];
				return;
			}
			[srcs addObject:info];
		}
		
		for (ItemCount destIndex = 0; destIndex < destCount; destIndex++) {
			NSDictionary *info = [_midiDriver portinfoFromDestinationEndpointIndex:destIndex];
			if (info == nil) {
				[self invokeJSCallback_onNotReady:message.webView];
				return;
			}
			[dests addObject:info];
		}
		
		
		NSData *srcsJSON = [NSJSONSerialization dataWithJSONObject:srcs options:0 error:nil];
		if (srcsJSON == nil) {
			[self invokeJSCallback_onNotReady:message.webView];
			return;
		}
		NSString *srcsJSONStr = [[NSString alloc] initWithData:srcsJSON encoding:NSUTF8StringEncoding];
		
		NSData *destsJSON = [NSJSONSerialization dataWithJSONObject:dests options:0 error:nil];
		if (destsJSON == nil) {
			[self invokeJSCallback_onNotReady:message.webView];
			return;
		}
		NSString *destsJSONStr = [[NSString alloc] initWithData:destsJSON encoding:NSUTF8StringEncoding];
		
		timestampOrigin = mach_absolute_time();
		
		[message.webView evaluateJavaScript:[NSString stringWithFormat:@"_callback_onReady(%@, %@);", srcsJSONStr, destsJSONStr] completionHandler:nil];
		
		return;
	} else if ([message.name isEqualToString:@"send"] == YES) {
		NSDictionary *dict = message.body;
		
		NSArray *array = dict[@"data"];
		NSMutableData *message = [NSMutableData dataWithCapacity:[array count]];
		BOOL sysexIncluded = NO;
		for (NSNumber *number in array) {
			uint8_t byte = [number unsignedIntegerValue];
			[message appendBytes:&byte length:1];
			
			if (byte == 0xf0) {
				sysexIncluded = YES;
			}
		}
		
		if (_sysexEnabled == NO && sysexIncluded == YES) {
			// should throw InvalidAccessError exception here
			return;
		}
		
		ItemCount outputIndex = [dict[@"outputPortIndex"] unsignedLongValue];
		float deltatime = [dict[@"deltaTime"] floatValue];
		[_midiDriver sendMessage:message toDestinationIndex:outputIndex deltatime:deltatime];
		
		return;
	}
}

@end
