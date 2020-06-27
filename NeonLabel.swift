//
//  NeonLabel.swift
//  NeonLabel
//
//  Created by Anton Tsyndrin on 27.06.2020.
//  Copyright © 2020 NeonLabel. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class NeonLabel: UILabel {
    
    private struct Const {
        struct Color {
            static let onColor: UIColor = .white
            static let offColor: UIColor = UIColor.white.withAlphaComponent(0.1)
        }
        
        struct Alpha {
            static let onAlpha: CGFloat = 1
            static let offAlpha: CGFloat = 0.4
        }
        
        struct Variables {
    
            static let neonBGCollorAlpha: CGFloat = 0.3
            static let updateInterval: Double = 0.5
        }
    }
    
    enum NeonState {
        case ON
        case OFF
    }
    
    @IBInspectable var neonLightParting: CGFloat = 6
    @IBInspectable var neonColor: UIColor = .orange
    @IBInspectable var blink: Bool {
        set {
            blinks = newValue
            if newValue, neonLight { startTimer() }
            else { stopTimer() }
        }
        get { return blinks }
    }
    
    @IBInspectable var neonLight: Bool {
        set { currentState = newValue ? .ON : .OFF }
        get { return currentState == .ON  }
    }

    
    private var blinks: Bool = false
    private var currentState: NeonState = .ON
    private var textSize: CGSize {
        return text?.size(withAttributes: [.font: font!]) ?? CGSize(width: 0, height: 0)
    }
      
    private var timer: Timer?

    
    ///Livecicle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupData()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupData()
        setupUI()
    }
}


//MARK: - Override
extension NeonLabel {

    override func drawText(in rect: CGRect) {
        
        generateLabelImage(rect: rect, state: currentState)?.draw(in: rect)
    }
}


//MARK: - Setup
extension NeonLabel {
    
    private func setupUI() {}
    
    private func setupData() {
        
        startTimer()
    }
}

//MARK: - Public
extension NeonLabel {
    
    public func turnON() {
        
        if blink { startTimer() }
        else { stopTimer() }
        
        currentState = .ON
        setNeedsDisplay()
    }
    
    public func turnOFF() {
        
        stopTimer()
        currentState = .OFF
        setNeedsDisplay()
    }
}

//MARK: - Timer
extension NeonLabel {
    
    private func startTimer() {
        
        guard timer == nil || currentState == .OFF else { return }

        timer = Timer(timeInterval: Const.Variables.updateInterval,
                          target: self,
                          selector: #selector(tick),
                          userInfo: nil,
                          repeats: true)

        guard let timer = timer else { return }
        RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
    }
    
    private func stopTimer() {
        
        timer?.invalidate()
        timer = nil
    }
}


//MARK: - Generate
extension NeonLabel {
        
    private func generateLabelImage(rect: CGRect, state: NeonState) -> UIImage? {
        
        let textRect = CGRect(x: rect.origin.x,
                              y: frame.height / 2 - textSize.height / 2,
                              width: rect.width,
                              height: rect.height)
                

        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        if state == .ON, let backLightImage = generateLightImageWith(rect: rect) {
            
            var height = textSize.height * 2.5
            if height > frame.size.height { height = frame.size.height }
            
            var width = textSize.width * 2
            if width > frame.size.width { width = frame.size.width }
            
            let backLightSize = CGSize(width: width, height: height)
            
            backLightImage.draw(in:  CGRect(x: frame.width / 2 - backLightSize.width / 2,
                                                 y: frame.height / 2 - backLightSize.height / 2,
                                                 width: backLightSize.width,
                                                 height: backLightSize.height),
                                blendMode: .lighten, alpha: Const.Variables.neonBGCollorAlpha)
        }
        
        if state == .ON, let neonLightImage = generateNeonLightImageWith(rect: textRect) {
            neonLightImage.draw(in: rect, blendMode: .lighten, alpha: 1)
        }
        
        if let textImage = generateTextImageWith(rect: textRect) {
            textImage.draw(in: rect, blendMode: .lighten, alpha: state == .ON ? Const.Alpha.onAlpha : Const.Alpha.offAlpha)
        }
        
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    private func generateTextImageWith(rect: CGRect) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        text?.draw(in: rect, withAttributes: attributedText?.attributes(at: 0, effectiveRange: nil))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    private func generateLightImageWith(rect: CGRect) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: rect.size.width, height: rect.size.width), false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        let currentContext = UIGraphicsGetCurrentContext()
        currentContext?.saveGState()
        
        let colors = [UIColor.white.withAlphaComponent(0.4).cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
        let endRadius = sqrt(pow(rect.size.width/2.2, 2) + pow(rect.size.height/2.2, 2))
        let center = CGPoint(x: rect.size.width / 2, y: rect.size.width / 2)
        let gradient = CGGradient(colorsSpace: nil, colors: colors, locations: nil)
        currentContext?.drawRadialGradient(gradient!, startCenter: center, startRadius: 0.0, endCenter: center, endRadius: endRadius, options: .drawsBeforeStartLocation)
              
        currentContext?.restoreGState()
              
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    private func generateNeonLightImageWith(rect: CGRect) -> UIImage? {

        let currentContext = UIGraphicsGetCurrentContext()
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        let textAttributes = attributedText?.attributes(at: 0, effectiveRange: nil)
        text?.draw(in: rect, withAttributes: textAttributes)

        currentContext?.setShadow(offset: CGSize.zero, blur:
            self.font.pointSize / neonLightParting
            , color: neonColor.cgColor)
         
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}


//MARK: - #Selector/@Actions
extension NeonLabel {
    
    @objc private func tick() {
            
        let currentState = Bool.random()
        if (self.currentState == .ON) != currentState {
            self.currentState = currentState ? .ON : .OFF
            debugPrint(self.currentState)
            setNeedsDisplay()
        }
    }
}
