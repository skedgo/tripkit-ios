//
//  TKUIPulsingAnnotationView.swift
//  TripKitUI-iOS
//
//  Created by Sam Vermette on 01.03.13.
//  Modified and simpliefied by Adrian Schönig
//  https://github.com/samvermette/SVPulsingAnnotationView
//

import MapKit

class TKUIPulsingAnnotationView: MKAnnotationView {
  /// Default is same as `MKUserLocationView`
  var annotationColor: UIColor {
    didSet { rebuildLayers() }
  }
  
  var pulseAnimationDuration: TimeInterval = 3
  
  var delayBetweenPulseCycles: TimeInterval = 1 {
    didSet { rebuildLayers() }
  }
  
  private var haloLayer: CALayer?
  private var pulseAnimation: CAAnimationGroup?
  
  override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
    annotationColor = #colorLiteral(red: 0, green: 0.478, blue: 1, alpha: 1)
    
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    
    layer.anchorPoint = .init(x: 0.5, y: 0.5)
    calloutOffset = .zero
    bounds = .init(x: 0, y: 0, width: 22, height: 22)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func willMove(toSuperview newSuperview: UIView?) {
    if newSuperview != nil {
      rebuildLayers()
    }
    super.willMove(toSuperview: newSuperview)
  }
  
  private func rebuildLayers() {
    haloLayer?.removeFromSuperlayer()
    haloLayer = nil
    
    let haloLayer = buildColorLayer()
    self.layer.insertSublayer(haloLayer, at: 0)
    self.haloLayer = haloLayer

    DispatchQueue.global().async {
      guard self.delayBetweenPulseCycles < .infinity else { return }
      
      let animationGroup = self.pulseAnimation ?? self.buildPulseAnimation()
      self.pulseAnimation = animationGroup
      
      DispatchQueue.main.async {
        self.haloLayer?.add(animationGroup, forKey: "pulse")
      }
    }
  }
  
  private func buildColorLayer() -> CALayer {
    let layer = CALayer()
    layer.bounds = .init(x: 0, y: 0, width: 120, height: 120)
    layer.position = .init(x: bounds.width / 2, y: bounds.height / 2)
    layer.contents = UIScreen.main.scale
    layer.backgroundColor = annotationColor.cgColor
    layer.cornerRadius = 60
    layer.opacity = 0
    return layer
  }
  
  private func buildPulseAnimation() -> CAAnimationGroup {
    let group = CAAnimationGroup()
    group.duration = pulseAnimationDuration - delayBetweenPulseCycles
    group.repeatCount = .infinity
    group.isRemovedOnCompletion = false
    group.timingFunction = CAMediaTimingFunction(name: .default)
    
    var animations: [CAAnimation] = []
    let pulse = CABasicAnimation(keyPath: "transform.scale.xy")
    pulse.fromValue = 0
    pulse.toValue = 1
    pulse.duration = pulseAnimationDuration
    animations.append(pulse)
    
    let fade = CAKeyframeAnimation(keyPath: "opacity")
    fade.duration = pulseAnimationDuration
    fade.values = [0.45, 0.45, 0, 0]
    fade.keyTimes = [0, 0.2, 0.9, 1]
    fade.isRemovedOnCompletion = false
    animations.append(fade)
    
    group.animations = animations
    return group
  }
}
