//
//  ViewController.swift
//  SoundGenerator_forMF
//
//  Created by 長谷部 雅彦 on 2015/03/02.
//  Copyright (c) 2015年 長谷部 雅彦. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate {

	//------------------------------------------------------------
	//				Table & Const Value
	//------------------------------------------------------------
	let MAX_TRANSPOSE_NUM:Int8 = 5
	let MIN_TRANSPOSE_NUM:Int8 = -6
	let tKeyName = [ "Gb","G","Ab","A","Bb","B","C","C#","D","Eb","E","F" ]

	let MAX_OCT_NUM:Int8 = 3
	let MIN_OCT_NUM:Int8 = -3
	let tOctName = [ "-3","-2","-1","0","+1","+2","+3" ]
	
	//------------------------------------------------------------
	//				Variables
	//------------------------------------------------------------
	var aout:SoundController? = nil
	var transposeValue:Int8 = 0
	var octaveNum:Int8 = 0

	//@IBOutlet weak var textArea: UILabel!
	@IBOutlet var midiDisplay: [UITextView]!
	@IBOutlet var transposeKeyName: [UILabel]!
	@IBOutlet var octaveNumber: [UILabel]!
	@IBOutlet weak var vce1: UIButton!
	@IBOutlet weak var vce2: UIButton!
	@IBOutlet weak var midiDispEnable: UISwitch!
	
	@IBOutlet weak var smView: HSBScrollViewWithTouch!
	var smusic: HSBSheetmusic!

	//------------------------------------------------------------
	//				Init
	//------------------------------------------------------------
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		aout = SoundController(vc: self)
		transposeKeyName[0].text = "C"
		octaveNumber[0].text = "0"

		smusic = HSBSheetmusic()
		smusic.drawAllKey()
		smView.addSubview(smusic)
		
		smView.contentSize = CGSizeMake(smusic.TOTAL_VIEW_WIDTH,smusic.TOTAL_VIEW_HEIGHT)
		smView.clipsToBounds = true
		smView.scrollEnabled = false
		smView.pagingEnabled = true
		smView.directionalLockEnabled = true
		smView.alwaysBounceVertical = true
		smView.alwaysBounceHorizontal = true
		smView.delegate = self	//	add 2015.5.21

		changeDisplayToAppropriateKey()
		smusic.inputMute = true

		vce1.setTitleColor(UIColor(red:1.0,green:0.0,blue:0.0,alpha:1.0), forState:UIControlState.Normal)
		vce2.setTitleColor(UIColor(red:1.0,green:1.0,blue:1.0,alpha:1.0), forState:UIControlState.Normal)
	}
	//------------------------------------------------------------
	//
	//------------------------------------------------------------
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	//------------------------------------------------------------
	//				Display Note
	//------------------------------------------------------------
	func displayMidiNote( noteNum:UInt8 ) {
		if let sm = smusic {
			sm.midiNoteOn(Int(noteNum))
		}
	}
	func deleteMidiNote( noteNum:UInt8 ) {
		if let sm = smusic {
			sm.midiNoteOff(Int(noteNum))
		}
	}

	//------------------------------------------------------------
	//
	//------------------------------------------------------------
	func displayExternalInfo(msg:NSString) {
//		textArea.text = msg as String
	}
	
	//------------------------------------------------------------
	//			Display MIDI Message
	//------------------------------------------------------------
	func displayMidiInfo(msg:NSString) {

		if !midiDispEnable.on { return }
		
		//	count how much letters are
		var strSize = 0
		if let mdstr:NSString = midiDisplay[0].text {
			strSize = mdstr.length
			if strSize > 1000 {
				//	clear text
				midiDisplay[0].text = ""
			}
		}

		//	Display String
		midiDisplay[0].replaceRange( midiDisplay[0].selectedTextRange!, withText:msg as String )

		//	Scroll to new line
		let scrollPosition:CGPoint = CGPointMake(0, midiDisplay[0].contentSize.height)
		midiDisplay[0].setContentOffset( scrollPosition, animated:false )
	}

	
	//------------------------------------------------------------
	//		Change Musical Key
	//------------------------------------------------------------
	let tKeyPage = [ 7,14,9,4,11,6,1,8,3,10,5,12 ]
	//------------------------------------------------------------
	func changeDisplayToAppropriateKey() {
		var key:Int = Int(transposeValue)
		if key < 0 { key += 12 }
		
		//	Display C major
		smView.scrollRectToVisible(CGRectMake(	smusic.ONE_VIEW_WIDTH*CGFloat(tKeyPage[key]),0,
		smusic.ONE_VIEW_WIDTH,smusic.ONE_VIEW_HEIGHT), animated: false)
		smusic.currentViewNum = tKeyPage[key]*2
	}
	
	//------------------------------------------------------------
	//
	//------------------------------------------------------------
	func sendNoteShift(){
		if let ao = aout {
			ao.transpose(transposeValue+octaveNum*12)
		}
		changeDisplayToAppropriateKey()
	}

	//------------------------------------------------------------
	//			Mute
	//------------------------------------------------------------
	func mute() {
		if let ao = aout {
			ao.reset()
		}
		smusic.allNoteClear()
	}
	//------------------------------------------------------------
	//			Transpose
	//------------------------------------------------------------
	func setTranspose() {
		if transposeValue > MAX_TRANSPOSE_NUM {
			transposeValue = MIN_TRANSPOSE_NUM + transposeValue - (MAX_TRANSPOSE_NUM+1)
		}
		else if transposeValue < MIN_TRANSPOSE_NUM {
			transposeValue = MAX_TRANSPOSE_NUM - (MIN_TRANSPOSE_NUM - (transposeValue+1))
		}
		mute()
		sendNoteShift()
		transposeKeyName[0].text = tKeyName[numericCast(transposeValue-MIN_TRANSPOSE_NUM)]
	}
	//------------------------------------------------------------
	//				Get Switch Event
	//------------------------------------------------------------
	@IBAction func touchButton(sender: UIButton) {
		switch sender.tag {
			case 0:
				displayMidiInfo("PC 00h\n")
				if let ao = aout {
					ao.changeTimbre(0)
					vce1.setTitleColor(UIColor(red:1.0,green:0.0,blue:0.0,alpha:1.0), forState:UIControlState.Normal)
					vce2.setTitleColor(UIColor(red:1.0,green:1.0,blue:1.0,alpha:1.0), forState:UIControlState.Normal)
				}
			case 1:
				displayMidiInfo("PC 01h\n")
				if let ao = aout {
					ao.changeTimbre(1)
					vce1.setTitleColor(UIColor(red:1.0,green:1.0,blue:1.0,alpha:1.0), forState:UIControlState.Normal)
					vce2.setTitleColor(UIColor(red:1.0,green:0.0,blue:0.0,alpha:1.0), forState:UIControlState.Normal)
				}
			case 2:
				displayMidiInfo("Reset\n")
				mute()
			case 3:
				transposeValue += 1
				setTranspose()
			case 4:
				transposeValue -= 1
				setTranspose()
			case 5:
				if ++octaveNum > MAX_OCT_NUM {
					octaveNum = MAX_OCT_NUM
				}
				sendNoteShift()
				octaveNumber[0].text = tOctName[numericCast(octaveNum-MIN_OCT_NUM)]
			case 6:
				if --octaveNum < MIN_OCT_NUM {
					octaveNum = MIN_OCT_NUM
				}
				sendNoteShift()
				octaveNumber[0].text = tOctName[numericCast(octaveNum-MIN_OCT_NUM)]
			case 7:
				transposeValue += 3
				setTranspose()
			case 8:
				transposeValue += 5
				setTranspose()
			default:
				break
		}
	}

}

