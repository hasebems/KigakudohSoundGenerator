//
//  SoundController.swift
//  SoundGenerator_forMF
//
//  Created by 長谷部 雅彦 on 2015/03/08.
//  Copyright (c) 2015年 長谷部 雅彦. All rights reserved.
//

import Foundation

class SoundController : NSObject
{
	let ssEngine = AudioOutput()

	//------------------------------------------------------------
	//				Variables
	//------------------------------------------------------------
	unowned var vCntr:ViewController
	var mdrv:MIDIDriver

	//------------------------------------------------------------
	//				Constructor
	//------------------------------------------------------------
	init( vc:ViewController ){
		vCntr = vc
		mdrv = MIDIDriver()
		super.init()

		mdrv.onMessageReceived = { (index : Int, data : NSData!, timestamp : UInt64) in
			if data.length >= 3 {
				let bt1 = UnsafePointer<UInt8>(data.bytes)[0]
				let bt2 = UnsafePointer<UInt8>(data.bytes)[1]
				let bt3 = UnsafePointer<UInt8>(data.bytes)[2]
				self.ssEngine.receiveMidi( bt1, msg2: bt2, msg3: bt3 )
				let midiData:NSString = NSString(format:"%02x %02x %02x\n",bt1,bt2,bt3 )
				self.disp(midiData)
				
				if ( bt1 & 0xf0 == 0x90 ) && ( bt3 != 0 ) {
					self.vCntr.displayMidiNote(bt2)
				}
				if ( bt1 & 0xf0 == 0x80 ) ||
					(( bt1 & 0xf0 == 0x90 ) && ( bt3 == 0 )) {
					self.vCntr.deleteMidiNote(bt2)
				}
			}
		}
	}
	
	//------------------------------------------------------------
	//				Display MIDI Message
	//------------------------------------------------------------
	func disp(text:NSString) {
		vCntr.displayMidiInfo(text)
	}
	//------------------------------------------------------------
	//				Send Program Change
	//------------------------------------------------------------
	func changeTimbre( prgNum: UInt8 ){
		ssEngine.receiveMidi(0xc0, msg2: prgNum, msg3: 0)
	}
	//------------------------------------------------------------
	//				Send Note On Message
	//------------------------------------------------------------
	func noteOn( noteNum: UInt8 ){
		ssEngine.receiveMidi(0x90, msg2: noteNum, msg3: 0x7f)
	}
	//------------------------------------------------------------
	//				Send Note Off Message
	//------------------------------------------------------------
	func noteOff( noteNum: UInt8 ){
		ssEngine.receiveMidi(0x90, msg2: noteNum, msg3: 0x00)
		vCntr.deleteMidiNote(noteNum)
	}
	//------------------------------------------------------------
	//				Send Reset
	//------------------------------------------------------------
	func reset(){
		//	Reset All Controller of MagicFlute
		ssEngine.receiveMidi(0xb0, msg2:120, msg3: 0)
		ssEngine.receiveMidi(0xb0, msg2:11, msg3: 0x7f)
		ssEngine.receiveMidi(0xb0, msg2:5, msg3: 0)
	}
	//------------------------------------------------------------
	//				Transpose
	//------------------------------------------------------------
	func transpose( transposeValue: Int8 ){
		var value = transposeValue + 64
		if value < 0 {
			value = 0
		}
		ssEngine.receiveMidi(0xb0, msg2:12, msg3: UInt8(value))
	}
}