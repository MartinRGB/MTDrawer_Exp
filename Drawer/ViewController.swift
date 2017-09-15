//
//  ViewController.swift
//  Drawer
//
//  Created by KingMartin on 15/9/22.
//  Copyright © 2015年 KingMartin. All rights reserved.
//

import UIKit

//init

//1.line part
private let mtControlPointRatio: CGFloat = 0.6
private let mtControlPointPulledDistance:CGFloat = 80
private let mtControlPointRoundedDistance : CGFloat = 120

//2.rounded Part
private let mtExtenedEdgesOffset:CGFloat = 100
private let mtCaptureDistance:CGFloat = 80
private let mtThresholdRatio:CGFloat = 0.6
//260 before
private let mtDrawerWidth:CGFloat = 260

var view1:UIView!
var view2:UIView!
var view3:UIView!
var view4:UIView!
var view5:UIView!

var imageview:UIImageView!



class ViewController: UIViewController {
    
    //3.枚举状态机
    enum State{
        case Collapsed
        case Expanded
    }
    //4.覆盖层
    let overlayview:UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white:0,alpha:0.5)
        return view
        }()
    
    //5.抽屉层
    let drawerView:UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red:0.9118,green:0.9163,blue:0.9532,alpha:1.0)
        return view
        }()
    
    //6.Shape蒙板
    let shapeLayer:CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
        }()
    
    
    //7.track or not，跟踪状态
    var tracking: Bool = false
    //8.初始状态为关闭
    var state: State = .Collapsed
    
    
    
    // I.MARK - Method 1 pull path
    func createPulledPath(width:CGFloat,point:CGPoint) -> UIBezierPath{
        let height = view.bounds.height
        let offset = width + point.x
        
        let point1:CGPoint = CGPointMake(-mtExtenedEdgesOffset, -mtExtenedEdgesOffset)
        let point2:CGPoint = CGPointMake(width,-mtExtenedEdgesOffset)
        let point3:CGPoint = CGPointMake(offset, point.y)
        let point3cp1:CGPoint = CGPointMake(width, point.y * mtControlPointRatio)
        let point3cp2:CGPoint = CGPointMake(offset, point.y - mtControlPointPulledDistance)
        let point4:CGPoint = CGPointMake(width, height + mtExtenedEdgesOffset)
        let point4cp1:CGPoint = CGPointMake(offset, point.y + mtControlPointPulledDistance)
        let point4cp2:CGPoint = CGPointMake(width, point.y + (height - point.y) * (1 - mtControlPointRatio))
        let point5 = CGPointMake(-mtExtenedEdgesOffset, height + mtExtenedEdgesOffset)
        
        /*
        print("point1 is \(point1)")
        print("point2 is \(point2)")
        print("point3 is \(point3)")
        print("point4 is \(point4)")
        print("point5 is \(point5)")
        
        print("3cp1 is \(point3cp1)")
        print("3cp2 is \(point3cp2)")
        
        print("4cp1 is \(point4cp1)")
        print("4cp2 is \(point4cp2)")
        */
        
        let path = UIBezierPath()
        path.moveToPoint(point1)
        path.addLineToPoint(point2)
        
        // add curve
        path.addCurveToPoint(point3,
            controlPoint1: point3cp1,
            controlPoint2: point3cp2)
        
        path.addCurveToPoint(point4,
            controlPoint1: point4cp1,
            controlPoint2: point4cp2)
        
        path.addLineToPoint(point5)
        
        path.closePath()
        
        return path
        
        
    }
    
    // II. MARK - Method 2 - Rounded Path
    func createRoundedPath(width:CGFloat,point:CGPoint) -> UIBezierPath{
        let height = view.bounds.height
        //因为是Rect形变，所以要加width
        let offset = width + point.x
        let path = UIBezierPath()
        
        //5 points
        path.moveToPoint(CGPointZero)
        path.addLineToPoint(CGPoint(x: width, y: 0))
        path.addCurveToPoint(CGPoint(x: offset, y: point.y), controlPoint1: CGPoint(x: width, y: 0), controlPoint2: CGPoint(x: offset, y: point.y - mtControlPointRoundedDistance))
        path.addCurveToPoint(CGPoint(x: width, y: height), controlPoint1: CGPoint(x: offset, y: point.y + mtControlPointRoundedDistance), controlPoint2: CGPoint(x: width, y: height))
        path.addLineToPoint(CGPoint(x: 0, y: height))
        
        path.closePath()
        return path
        
    }
    
    // III. MARK - Method 3 松手后的返回动画方法 for Method 1
    func animateShapeLayerToPath(path: CGPathRef, duration: NSTimeInterval) {
        let animation = CABasicAnimation(keyPath: "path")
        animation.toValue = path
        animation.duration = duration
        animation.fillMode = kCAFillModeForwards
        animation.removedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.5, 1.8, 1, 1)
        
        shapeLayer.addAnimation(animation, forKey: "morph")
    }
    
    // IV. MARK - Method 4 松手后的返回动画方法 for Method 2
    
    func animateShapeLayerWithKeyFrames(values:[AnyObject],times:[CGFloat],duration:NSTimeInterval){
        let keyFrameAnimation = CAKeyframeAnimation(keyPath: "path")
        keyFrameAnimation.fillMode = kCAFillModeForwards
        keyFrameAnimation.removedOnCompletion = false
        keyFrameAnimation.values = values
        keyFrameAnimation.keyTimes = times
        keyFrameAnimation.duration = duration
        
        shapeLayer.addAnimation(keyFrameAnimation, forKey: "morph")
        
        
    }
    
    
    
    //4.handle Pan Gesture
    func handlePan(pan:UIPanGestureRecognizer){
        let location = pan.locationInView(view)
        switch pan.state{
        case .Began:
            //移除所有动画
            shapeLayer.removeAllAnimations()
            
            //(1).如果抽屉没有打开，且在范围内，跟踪
            if state == .Collapsed && location.x < mtCaptureDistance{
                tracking = true
                print("Began Case closed")
            }
            //(2).如果抽屉已经打开，且手指在右边一定范围内，跟踪
            else if state == .Expanded && location.x > mtDrawerWidth - mtCaptureDistance {
                tracking = true
                print("Began Case opened")
            }
            //(3).其余不动
            else{
                shapeLayer.path = nil
                print("Began Case nothing")
            }
            
            if tracking{
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                    [overlayview] in
                    overlayview.alpha = 1
                    }, completion: nil)
                
                fallthrough
            }

            
        case .Changed:
            //(1). 如果停止跟踪，则返送当前数值
            if !tracking {
                return
            }
            //(2)如果抽屉关闭，且超出一定范围，触发打开效果，但不X位移,回弹，并停止状态跟踪
            if state == .Collapsed && location.x > mtThresholdRatio * mtDrawerWidth{
                tracking = false
                
                
                let centerY = view.bounds.height/2
                
                let point1:CGPoint = CGPoint(x: 30, y: (location.y+centerY)/2)
                let point2:CGPoint = CGPoint(x: -30, y: centerY)
                let point3:CGPoint = CGPoint(x: 0, y: centerY)
                
                
                animateShapeLayerWithKeyFrames([
                    shapeLayer.path!,
                    createRoundedPath(mtDrawerWidth, point: point1).CGPath,
                    createRoundedPath(mtDrawerWidth, point: point2).CGPath,
                    createRoundedPath(mtDrawerWidth, point: point3).CGPath
                    ], times: [0, 0.5, 0.8, 1.0], duration: 0.3)
                
                state = .Expanded
                
                
                print("Huge Change->")
                
                UIView.animateWithDuration(0.15, delay: 0, options: [], animations: {
                    () -> Void in
                
                    
                    let xtestvalue1:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point1, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point1.x, x3: mtDrawerWidth+point1.x,t:0.22)
                    
                    let xtestvalue2:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point1, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point1.x, x3: mtDrawerWidth+point1.x,t:0.33)
                    
                    let xtestvalue3:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point1, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point1.x, x3: mtDrawerWidth+point1.x,t:0.48)
                    
                    let xtestvalue4:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point1, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point1.x, x3: mtDrawerWidth+point1.x,t:0.636)
                    
                    let xtestvalue5:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point1, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point1.x, x3: mtDrawerWidth+point1.x,t:0.789)
                    
                    
                    view1.frame = CGRectMake(xtestvalue1-25,25, 25, 25)
                    view2.frame = CGRectMake(xtestvalue2-25,125, 25, 25)
                    view3.frame = CGRectMake(xtestvalue3-25,225, 25, 25)
                    view4.frame = CGRectMake(xtestvalue4-25,325, 25, 25)
                    view5.frame = CGRectMake(xtestvalue5-25,425, 25, 25)
                    
                    }, completion: nil)
                
                UIView.animateWithDuration(0.09, delay: 0.15, options: [], animations: {
                    () -> Void in
                    
                    let xtestvalue1:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point2, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point2.x, x3: mtDrawerWidth+point2.x,t:0.22)
                    
                    let xtestvalue2:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point2, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point2.x, x3: mtDrawerWidth+point2.x,t:0.33)
                    
                    let xtestvalue3:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point2, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point2.x, x3: mtDrawerWidth+point2.x,t:0.48)
                    
                    let xtestvalue4:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point2, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point2.x, x3: mtDrawerWidth+point2.x,t:0.636)
                    
                    let xtestvalue5:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point2, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point2.x, x3: mtDrawerWidth+point2.x,t:0.789)
                    
                    
                    view1.frame = CGRectMake(xtestvalue1-25,25, 25, 25)
                    view2.frame = CGRectMake(xtestvalue2-25,125, 25, 25)
                    view3.frame = CGRectMake(xtestvalue3-25,225, 25, 25)
                    view4.frame = CGRectMake(xtestvalue4-25,325, 25, 25)
                    view5.frame = CGRectMake(xtestvalue5-25,425, 25, 25)
                    
                    }, completion: nil)
                
                
                
                UIView.animateWithDuration(0.06, delay: 0.24, options: [], animations: {
                    () -> Void in
                    
                    let xtestvalue1:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point3, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point3.x, x3: mtDrawerWidth+point3.x,t:0.22)
                    
                    let xtestvalue2:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point3, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point3.x, x3: mtDrawerWidth+point3.x,t:0.33)
                    
                    let xtestvalue3:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point3, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point3.x, x3: mtDrawerWidth+point3.x,t:0.48)
                    
                    let xtestvalue4:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point3, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point3.x, x3: mtDrawerWidth+point3.x,t:0.636)
                    
                    let xtestvalue5:CGFloat = self.usecubicbezierfourmulagetX(mtDrawerWidth, point: point3, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point3.x, x3: mtDrawerWidth+point3.x,t:0.789)
                    
                    
                    view1.frame = CGRectMake(xtestvalue1-25,25, 25, 25)
                    view2.frame = CGRectMake(xtestvalue2-25,125, 25, 25)
                    view3.frame = CGRectMake(xtestvalue3-25,225, 25, 25)
                    view4.frame = CGRectMake(xtestvalue4-25,325, 25, 25)
                    view5.frame = CGRectMake(xtestvalue5-25,425, 25, 25)
                    
                    }, completion: nil)
                
                
                
                
            }
            //(3)如果抽屉打开状态，且超出一定范围，触发关闭效果，但不X位移,回弹，并停止状态跟踪
            else if state == .Expanded && location.x < (1-mtThresholdRatio) * mtDrawerWidth{
                tracking = false
                
                let centerY = view.bounds.height/2
                let point1:CGPoint = CGPoint(x: 30, y: (location.y+centerY)/2)
                let point2:CGPoint = CGPoint(x: -30, y: centerY)
                let point3:CGPoint = CGPoint(x: 0, y: centerY)
                
                
                animateShapeLayerWithKeyFrames([
                    shapeLayer.path!,
                    createRoundedPath(0, point: point1).CGPath,
                    createRoundedPath(0, point: point2).CGPath,
                    createRoundedPath(0, point: point3).CGPath
                    ], times: [0, 0.5, 0.8, 1.0], duration: 0.3)
                
                state = .Collapsed
                
                print("<-Huge Change")
                
                
                UIView.animateWithDuration(0.15, delay: 0, options: [], animations: {
                    () -> Void in
                    
                    let xtestvalue1:CGFloat = self.usecubicbezierfourmulagetX(0, point: point1, x0: 0, x1: 0, x2: 0+point1.x, x3: 0+point1.x,t:0.22)
                    
                    let xtestvalue2:CGFloat = self.usecubicbezierfourmulagetX(0, point: point1, x0: 0, x1: 0, x2: 0+point1.x, x3: 0+point1.x,t:0.33)
                    
                    let xtestvalue3:CGFloat = self.usecubicbezierfourmulagetX(0, point: point1, x0: 0, x1: 0, x2: 0+point1.x, x3: 0+point1.x,t:0.48)
                    
                    let xtestvalue4:CGFloat = self.usecubicbezierfourmulagetX(0, point: point1, x0: 0, x1: 0, x2: 0+point1.x, x3: 0+point1.x,t:0.636)
                    
                    let xtestvalue5:CGFloat = self.usecubicbezierfourmulagetX(0, point: point1, x0: 0, x1: 0, x2: 0+point1.x, x3: 0+point1.x,t:0.789)
                    
                    
                    view1.frame = CGRectMake(xtestvalue1*1.2-25,25, 25, 25)
                    view2.frame = CGRectMake(xtestvalue2*1.2-25,125, 25, 25)
                    view3.frame = CGRectMake(xtestvalue3*1.2-25,225, 25, 25)
                    view4.frame = CGRectMake(xtestvalue4*1.2-25,325, 25, 25)
                    view5.frame = CGRectMake(xtestvalue5*1.2-25,425, 25, 25)
                    
                    }, completion: nil)
                
                UIView.animateWithDuration(0.09, delay: 0.15, options: [], animations: {
                    () -> Void in
                    
                    
                    let xtestvalue1:CGFloat = self.usecubicbezierfourmulagetX(0, point: point2, x0: 0, x1: 0, x2: 0+point2.x, x3: 0+point2.x,t:0.22)
                    
                    let xtestvalue2:CGFloat = self.usecubicbezierfourmulagetX(0, point: point2, x0: 0, x1: 0, x2: 0+point2.x, x3: 0+point2.x,t:0.33)
                    
                    let xtestvalue3:CGFloat = self.usecubicbezierfourmulagetX(0, point: point2, x0: 0, x1: 0, x2: 0+point2.x, x3: 0+point2.x,t:0.48)
                    
                    let xtestvalue4:CGFloat = self.usecubicbezierfourmulagetX(0, point: point2, x0: 0, x1: 0, x2: 0+point2.x, x3: 0+point2.x,t:0.636)
                    
                    let xtestvalue5:CGFloat = self.usecubicbezierfourmulagetX(0, point: point2, x0: 0, x1: 0, x2: 0+point2.x, x3: 0+point2.x,t:0.789)
                    
                    
                    view1.frame = CGRectMake(xtestvalue1*1.2-25,25, 25, 25)
                    view2.frame = CGRectMake(xtestvalue2*1.2-25,125, 25, 25)
                    view3.frame = CGRectMake(xtestvalue3*1.2-25,225, 25, 25)
                    view4.frame = CGRectMake(xtestvalue4*1.2-25,325, 25, 25)
                    view5.frame = CGRectMake(xtestvalue5*1.2-25,425, 25, 25)
                    
                    }, completion: nil)
                
                
                
                UIView.animateWithDuration(0.06, delay: 0.24, options: [], animations: {
                    () -> Void in
                    
                    let xtestvalue1:CGFloat = self.usecubicbezierfourmulagetX(0, point: point3, x0: 0, x1: 0, x2: 0+point3.x, x3: 0+point3.x,t:0.22)
                    
                    let xtestvalue2:CGFloat = self.usecubicbezierfourmulagetX(0, point: point3, x0: 0, x1: 0, x2: 0+point3.x, x3: 0+point3.x,t:0.33)
                    
                    let xtestvalue3:CGFloat = self.usecubicbezierfourmulagetX(0, point: point3, x0: 0, x1: 0, x2: 0+point3.x, x3: 0+point3.x,t:0.48)
                    
                    let xtestvalue4:CGFloat = self.usecubicbezierfourmulagetX(0, point: point3, x0: 0, x1: 0, x2: 0+point3.x, x3: 0+point3.x,t:0.636)
                    
                    let xtestvalue5:CGFloat = self.usecubicbezierfourmulagetX(0, point: point3, x0: 0, x1: 0, x2: 0+point3.x, x3: 0+point3.x,t:0.789)
                    
                    
                    view1.frame = CGRectMake(xtestvalue1*1.2-25,25, 25, 25)
                    view2.frame = CGRectMake(xtestvalue2*1.2-25,125, 25, 25)
                    view3.frame = CGRectMake(xtestvalue3*1.2-25,225, 25, 25)
                    view4.frame = CGRectMake(xtestvalue4*1.2-25,325, 25, 25)
                    view5.frame = CGRectMake(xtestvalue5*1.2-25,425, 25, 25)
                    
                    }, completion: nil)
                
                
                //处理覆盖层
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                    [overlayview] in
                    overlayview.alpha = 0
                    }, completion: nil)
            }
            //(4)未触发位移的正常滑动状态
            else{
                //未触发状态的左滑
                if state == .Collapsed {
                    let point = CGPoint (x:location.x * 0.5,y:location.y)
                    shapeLayer.path = createPulledPath(0, point: point).CGPath
                    
                    
                    //print("->>>>>")
                    
                    ///////SUper TEST***** Read to convert to func
                    
                    if point.y >= 425{
                    
                    let xtestvalue1:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:125/(point.y+100))
                    
                    let xtestvalue2:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:225/(point.y+100))
                    
                    let xtestvalue3:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:325/(point.y+100))
                    
                    let xtestvalue4:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:425/(point.y+100))
                    
                    let xtestvalue5:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:525/(point.y+100))
                        
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                            () -> Void in
                            
                            view1.frame = CGRectMake(xtestvalue1*1.2-25,25, 25, 25)
                            view2.frame = CGRectMake(xtestvalue2*1.2-25,125, 25, 25)
                            view3.frame = CGRectMake(xtestvalue3*1.2-25,225, 25, 25)
                            view4.frame = CGRectMake(xtestvalue4*1.2-25,325, 25, 25)
                            view5.frame = CGRectMake(xtestvalue5*1.2-25,425, 25, 25)
                            
                            }, completion: nil)
                        
                        
                        
                    }
                    
                    else if(point.y < 425 && point.y >= 325){
                        
                        let xtestvalue1:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:125/(point.y+100))
                        
                        let xtestvalue2:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:225/(point.y+100))
                        
                        let xtestvalue3:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:325/(point.y+100))
                        
                        let xtestvalue4:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:425/(point.y+100))
                        
                        
                        let xtestvalue5:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(425-point.y)/(668 - point.y))
                        
                        
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                            () -> Void in
                            
                            view1.frame = CGRectMake(xtestvalue1*1.2-25,25, 25, 25)
                            view2.frame = CGRectMake(xtestvalue2*1.2-25,125, 25, 25)
                            view3.frame = CGRectMake(xtestvalue3*1.2-25,225, 25, 25)
                            view4.frame = CGRectMake(xtestvalue4*1.2-25,325, 25, 25)
                            view5.frame = CGRectMake(xtestvalue5*1.2-25,425, 25, 25)
                            
                            }, completion: nil)
                        
                        
                        
                    }
                    
                    else if(point.y < 325 && point.y >= 225){
                        
                        let xtestvalue1:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:125/(point.y+100))
                        
                        let xtestvalue2:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:225/(point.y+100))
                        
                        let xtestvalue3:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:325/(point.y+100))
                        
                        //
                        let xtestvalue4:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(325-point.y)/(668 - point.y))
                        
                        
                        let xtestvalue5:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(425-point.y)/(668 - point.y))
                        
                        
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                            () -> Void in
                            
                            view1.frame = CGRectMake(xtestvalue1*1.2-25,25, 25, 25)
                            view2.frame = CGRectMake(xtestvalue2*1.2-25,125, 25, 25)
                            view3.frame = CGRectMake(xtestvalue3*1.2-25,225, 25, 25)
                            view4.frame = CGRectMake(xtestvalue4*1.2-25,325, 25, 25)
                            view5.frame = CGRectMake(xtestvalue5*1.2-25,425, 25, 25)
                            
                            }, completion: nil)
                        
                        
                        
                    }
                    
                    else if(point.y < 225 && point.y >= 125){
                        
                        let xtestvalue1:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:125/(point.y+100))
                        
                        let xtestvalue2:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:225/(point.y+100))
                        //
                        let xtestvalue3:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(225-point.y)/(668 - point.y))
                        
                        let xtestvalue4:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(325-point.y)/(668 - point.y))
                        
                        
                        let xtestvalue5:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(425-point.y)/(668 - point.y))
                        
                        
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                            () -> Void in
                            
                            view1.frame = CGRectMake(xtestvalue1*1.2-25,25, 25, 25)
                            view2.frame = CGRectMake(xtestvalue2*1.2-25,125, 25, 25)
                            view3.frame = CGRectMake(xtestvalue3*1.2-25,225, 25, 25)
                            view4.frame = CGRectMake(xtestvalue4*1.2-25,325, 25, 25)
                            view5.frame = CGRectMake(xtestvalue5*1.2-25,425, 25, 25)
                            
                            }, completion: nil)
                        
                        
                    }
                    
                    else if(point.y < 125 && point.y >= 25){
                        
                        let xtestvalue1:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0, x1: 0, x2: 0+point.x, x3: 0+point.x,t:125/(point.y+100))
                        
                        let xtestvalue2:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(125-point.y)/(668 - point.y))
                        
                        let xtestvalue3:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(225-point.y)/(668 - point.y))
                        
                        let xtestvalue4:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(325-point.y)/(668 - point.y))
                        
                        
                        let xtestvalue5:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(425-point.y)/(668 - point.y))
                        
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                            () -> Void in
                            
                            view1.frame = CGRectMake(xtestvalue1*1.2-25,25, 25, 25)
                            view2.frame = CGRectMake(xtestvalue2*1.2-25,125, 25, 25)
                            view3.frame = CGRectMake(xtestvalue3*1.2-25,225, 25, 25)
                            view4.frame = CGRectMake(xtestvalue4*1.2-25,325, 25, 25)
                            view5.frame = CGRectMake(xtestvalue5*1.2-25,425, 25, 25)
                            
                            }, completion: nil)
                        
                        
                        
                        
                    }
                    
                    else{
                       
                        let xtestvalue1:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(25-point.y)/(668 - point.y))
                        
                        let xtestvalue2:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(125-point.y)/(668 - point.y))
                        
                        let xtestvalue3:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(225-point.y)/(668 - point.y))
                        
                        let xtestvalue4:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(325-point.y)/(668 - point.y))
                        
                        
                        let xtestvalue5:CGFloat = usecubicbezierfourmulagetX(0, point: point, x0: 0+point.x, x1: 0+point.x, x2: 0, x3: 0,t:(425-point.y)/(668 - point.y))
                        
                        
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                            () -> Void in
                            
                            view1.frame = CGRectMake(xtestvalue1*1.2-25,25, 25, 25)
                            view2.frame = CGRectMake(xtestvalue2*1.2-25,125, 25, 25)
                            view3.frame = CGRectMake(xtestvalue3*1.2-25,225, 25, 25)
                            view4.frame = CGRectMake(xtestvalue4*1.2-25,325, 25, 25)
                            view5.frame = CGRectMake(xtestvalue5*1.2-25,425, 25, 25)
                            
                            }, completion: nil)
                        
                        
                    }
                    
                    
                    
                    
                    
                    
                    
                    
                }
                //未触发状态的右滑, -max->取最左面的点
                else{
                    let point = CGPoint (x:-max(0,mtDrawerWidth - location.x) * 0.5,y:location.y)
                    shapeLayer.path = createPulledPath(mtDrawerWidth, point: point).CGPath
                    
                    if point.y >= 425{
                        
                        let xtestvalue1:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:125/(point.y+100))
                        
                        let xtestvalue2:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:225/(point.y+100))
                        
                        let xtestvalue3:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:325/(point.y+100))
                        
                        let xtestvalue4:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:425/(point.y+100))
                        
                        let xtestvalue5:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:525/(point.y+100))
                        
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                            () -> Void in
                            
                            view1.frame = CGRectMake(xtestvalue1-25,25, 25, 25)
                            view2.frame = CGRectMake(xtestvalue2-25,125, 25, 25)
                            view3.frame = CGRectMake(xtestvalue3-25,225, 25, 25)
                            view4.frame = CGRectMake(xtestvalue4-25,325, 25, 25)
                            view5.frame = CGRectMake(xtestvalue5-25,425, 25, 25)
                            
                            }, completion: nil)
                        
                        
                        
                    }
                        
                    else if(point.y < 425 && point.y >= 325){
                        
                        let xtestvalue1:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:125/(point.y+100))
                        
                        let xtestvalue2:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:225/(point.y+100))
                        
                        let xtestvalue3:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:325/(point.y+100))
                        
                        let xtestvalue4:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:425/(point.y+100))
                        
                        
                        let xtestvalue5:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(425-point.y)/(668 - point.y))
                        
                        
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                            () -> Void in
                            
                            view1.frame = CGRectMake(xtestvalue1-25,25, 25, 25)
                            view2.frame = CGRectMake(xtestvalue2-25,125, 25, 25)
                            view3.frame = CGRectMake(xtestvalue3-25,225, 25, 25)
                            view4.frame = CGRectMake(xtestvalue4-25,325, 25, 25)
                            view5.frame = CGRectMake(xtestvalue5-25,425, 25, 25)
                            
                            }, completion: nil)
                        
                        
                        
                    }
                        
                    else if(point.y < 325 && point.y >= 225){
                        
                        let xtestvalue1:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:125/(point.y+100))
                        
                        let xtestvalue2:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:225/(point.y+100))
                        
                        let xtestvalue3:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:325/(point.y+100))
                        
                        //
                        let xtestvalue4:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(325-point.y)/(668 - point.y))
                        
                        
                        let xtestvalue5:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(425-point.y)/(668 - point.y))
                        
                        
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                            () -> Void in
                            
                            view1.frame = CGRectMake(xtestvalue1-25,25, 25, 25)
                            view2.frame = CGRectMake(xtestvalue2-25,125, 25, 25)
                            view3.frame = CGRectMake(xtestvalue3-25,225, 25, 25)
                            view4.frame = CGRectMake(xtestvalue4-25,325, 25, 25)
                            view5.frame = CGRectMake(xtestvalue5-25,425, 25, 25)
                            
                            }, completion: nil)
                        
                        
                        
                    }
                        
                    else if(point.y < 225 && point.y >= 125){
                        
                        let xtestvalue1:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:125/(point.y+100))
                        
                        let xtestvalue2:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:225/(point.y+100))
                        //
                        let xtestvalue3:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(225-point.y)/(668 - point.y))
                        
                        let xtestvalue4:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(325-point.y)/(668 - point.y))
                        
                        
                        let xtestvalue5:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(425-point.y)/(668 - point.y))
                        
                        
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                            () -> Void in
                            
                            view1.frame = CGRectMake(xtestvalue1-25,25, 25, 25)
                            view2.frame = CGRectMake(xtestvalue2-25,125, 25, 25)
                            view3.frame = CGRectMake(xtestvalue3-25,225, 25, 25)
                            view4.frame = CGRectMake(xtestvalue4-25,325, 25, 25)
                            view5.frame = CGRectMake(xtestvalue5-25,425, 25, 25)
                            
                            }, completion: nil)
                        
                        
                    }
                        
                    else if(point.y < 125 && point.y >= 25){
                        
                        let xtestvalue1:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth, x1: mtDrawerWidth, x2: mtDrawerWidth+point.x, x3: mtDrawerWidth+point.x,t:125/(point.y+100))
                        
                        let xtestvalue2:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(125-point.y)/(668 - point.y))
                        
                        let xtestvalue3:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(225-point.y)/(668 - point.y))
                        
                        let xtestvalue4:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(325-point.y)/(668 - point.y))
                        
                        
                        let xtestvalue5:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(425-point.y)/(668 - point.y))
                        
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                            () -> Void in
                            
                            view1.frame = CGRectMake(xtestvalue1-25,25, 25, 25)
                            view2.frame = CGRectMake(xtestvalue2-25,125, 25, 25)
                            view3.frame = CGRectMake(xtestvalue3-25,225, 25, 25)
                            view4.frame = CGRectMake(xtestvalue4-25,325, 25, 25)
                            view5.frame = CGRectMake(xtestvalue5-25,425, 25, 25)
                            
                            }, completion: nil)
                        
                        
                        
                        
                    }
                        
                    else{
                        
                        let xtestvalue1:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(25-point.y)/(668 - point.y))
                        
                        let xtestvalue2:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(125-point.y)/(668 - point.y))
                        
                        let xtestvalue3:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(225-point.y)/(668 - point.y))
                        
                        let xtestvalue4:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(325-point.y)/(668 - point.y))
                        
                        
                        let xtestvalue5:CGFloat = usecubicbezierfourmulagetX(mtDrawerWidth, point: point, x0: mtDrawerWidth+point.x, x1: mtDrawerWidth+point.x, x2: mtDrawerWidth, x3: mtDrawerWidth,t:(425-point.y)/(668 - point.y))
                        
                        
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                            () -> Void in
                            
                            view1.frame = CGRectMake(xtestvalue1-25,25, 25, 25)
                            view2.frame = CGRectMake(xtestvalue2-25,125, 25, 25)
                            view3.frame = CGRectMake(xtestvalue3-25,225, 25, 25)
                            view4.frame = CGRectMake(xtestvalue4-25,325, 25, 25)
                            view5.frame = CGRectMake(xtestvalue5-25,425, 25, 25)
                            
                            }, completion: nil)
                        
                        
                    }
                    
                    
                    

                    //print("<<<<<<-")
                }
                
            }
                
        
            
            
        case .Ended:
            fallthrough
        //*******半路取消的返回
        case .Cancelled:
            
            if tracking{
                //移到右边缘
                //平移点
                let point = CGPoint(x:0,y:location.y)
                animateShapeLayerToPath(createPulledPath(state == .Collapsed ? 0 : mtDrawerWidth, point: point).CGPath, duration: 0.2)
                tracking = false
                
                let newwidth:CGFloat = state == .Collapsed ? 0 : mtDrawerWidth
                
                let xtestvalue1:CGFloat = usecubicbezierfourmulagetX(newwidth, point: point, x0: newwidth, x1: newwidth, x2: newwidth+point.x, x3: newwidth+point.x,t:0.22)
                
                let xtestvalue2:CGFloat = usecubicbezierfourmulagetX(newwidth, point: point, x0: newwidth, x1: newwidth, x2: newwidth+point.x, x3: newwidth+point.x,t:0.33)
                
                let xtestvalue3:CGFloat = usecubicbezierfourmulagetX(newwidth, point: point, x0: newwidth, x1: newwidth, x2: newwidth+point.x, x3: newwidth+point.x,t:0.48)
                
                let xtestvalue4:CGFloat = usecubicbezierfourmulagetX(newwidth, point: point, x0: newwidth, x1: newwidth, x2: newwidth+point.x, x3: newwidth+point.x,t:0.636)
                
                let xtestvalue5:CGFloat = usecubicbezierfourmulagetX(newwidth, point: point, x0: newwidth, x1: newwidth, x2: newwidth+point.x, x3: newwidth+point.x,t:0.789)
                
                
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                    () -> Void in
                    
                    view1.frame = CGRectMake(xtestvalue1-25,25, 25, 25)
                    view2.frame = CGRectMake(xtestvalue2-25,125, 25, 25)
                    view3.frame = CGRectMake(xtestvalue3-25,225, 25, 25)
                    view4.frame = CGRectMake(xtestvalue4-25,325, 25, 25)
                    view5.frame = CGRectMake(xtestvalue5-25,425, 25, 25)
                    }, completion: nil)
                
            
                
                    
                
                
                
                if state == .Collapsed{
                    //底部覆盖层根据手势的变化
                    UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                        //***
                        [overlayview] in
                        overlayview.alpha = 0
                        }, completion: nil)
                    print("CLOSED!")
                }
                else{
                    print("OPENED!")
                }
            }
        default:
             ()
        }
    }
    
    //2.View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        //add subview
        view.addSubview(overlayview)
        view.addSubview(drawerView)
        drawerView.alpha = 1
        //add mask
        drawerView.layer.mask = shapeLayer
        overlayview.alpha = 0
        //add gesture
        let pan = UIPanGestureRecognizer(target: self, action: "handlePan:")
        view.addGestureRecognizer(pan)
        
        //test part
        
        
        
        view1 = UIView(frame: CGRectMake(-25, 25, 25, 25))
        view1.backgroundColor = UIColor.redColor()
        self.view .addSubview(view1)
        
        view2 = UIView(frame: CGRectMake(-25, 125, 25, 25))
        view2.backgroundColor = UIColor.blueColor()
        self.view .addSubview(view2)
        
        view3 = UIView(frame: CGRectMake(-25, 225, 25, 25))
        view3.backgroundColor = UIColor.greenColor()
        self.view .addSubview(view3)
        
        view4 = UIView(frame: CGRectMake(-25, 325, 25, 25))
        view4.backgroundColor = UIColor.blackColor()
        self.view .addSubview(view4)
        
        view5 = UIView(frame: CGRectMake(-25, 425, 25, 25))
        view5.backgroundColor = UIColor.brownColor()
        self.view .addSubview(view5)
        
        
    }
    
    //3.layout setting
    override func viewWillLayoutSubviews() {
        overlayview.frame = view.bounds
        drawerView.frame = view.bounds
    }

    //4.Memory
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func usecubicbezierfourmulagetX (width:CGFloat,point:CGPoint,x0:CGFloat,x1:CGFloat,x2:CGFloat,x3:CGFloat,t:CGFloat) -> CGFloat{
        let xvalue:CGFloat = x0*(1-t)*(1-t)*(1-t) + 3*x1*t*(1-t)*(1-t) + 3*x2*t*t*(1-t) + x3*t*t*t
        return xvalue
        
    }
    
    func usecubicbezierfourmulagetY (width:CGFloat,point:CGPoint,y0:CGFloat,y1:CGFloat,y2:CGFloat,y3:CGFloat,t:CGFloat) -> CGFloat{
        
        
        let yvalue:CGFloat = y0*(1-t)*(1-t)*(1-t) + 3*y1*t*(1-t)*(1-t) + 3*y2*t*t*(1-t) + y3*t*t*t
        return yvalue
        
    }
    


}

