//
//  FSTStateBarView.m
//  FirstBuild
//
//  Created by John Nolan on 7/14/15.
//  Copyright (c) 2015 FirstBuild. All rights reserved.
//

#import "FSTStateBarView.h"
#import "FSTStateCircleView.h"

@interface FSTStateBarView()

@property (nonatomic, strong) CAShapeLayer* ring; // animated shape that replaces the static circleMarker
@property (nonatomic, strong) NSMutableArray* grayDots;
@property (nonatomic, strong) NSMutableArray* dotTransforms;
@property (nonatomic) CGFloat lineWidth;

@end

@implementation FSTStateBarView
{
    CABasicAnimation *circlePulsingAnimation;
}

@synthesize numberOfStates = _numberOfStates;

-(void)setNumberOfStates:(NSNumber *)numberOfStates
{
    [self setupDots];
    _numberOfStates = numberOfStates;
    [self setNeedsDisplay];
}


- (NSNumber*) numberOfStates
{
    return _numberOfStates;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDots];
        

    }
    return self;
}

-(void) awakeFromNib {
    [super awakeFromNib];
    
    // animations stop and are removed when app is backgrounded, force removal and re-add
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *notification)
     {
         [self.ring addAnimation:circlePulsingAnimation forKey:@"lineWidth"];
     }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *notification)
     {
         [self.ring removeAnimationForKey:@"lineWidth"];
     }];
    
    self.contentMode = UIViewContentModeRedraw;
}

-(void)setupDots { // could happen after init or awake from nib. Initialize subviews
    self.grayDots = [[NSMutableArray alloc] init]; // an array to hold all the dot subviews
    self.dotTransforms = [[NSMutableArray alloc] init];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateCircle];
}

- (void) arrangeTransforms {
    
    if (self.dotTransforms.count > 0) {
        [self.dotTransforms removeAllObjects];
    }
    
    // how much the line width shrinks down (for some reason scaling down the path makes our stroke thinner
    //baseline scale transform that every dot undergoes
    CGFloat ringScale = 0.3;
    CGAffineTransform sizeTransform = CGAffineTransformMakeScale(ringScale, ringScale);
    
    // use these bounds to calculate the size for offsets and scales (never mind, it scales relative to the layer bounds
    CGAffineTransform ringTransform;
    CGRect circleBounds;
    CGSize ringSize;
    CGFloat offsetWidth, offsetHeight;
    CGSize ringOffset;
    
    for (int itr = 0; itr < self.grayDots.count; itr++) {
        circleBounds = CGPathGetBoundingBox(((CAShapeLayer*)self.grayDots[itr]).path);
         // calculate what size the ring will be after this transform for the offset
        ringSize = CGSizeApplyAffineTransform(CGSizeMake(circleBounds.origin.x + circleBounds.size.width/2, circleBounds.origin.y + circleBounds.size.height/2), sizeTransform);
        // get the rectangle of its position in which it scales down
        // establish the offset to place the ring in the center
        offsetWidth = circleBounds.origin.x + circleBounds.size.width/2 - ringSize.width;
        offsetHeight = circleBounds.origin.y + circleBounds.size.height/2 - ringSize.height;
        ringOffset = CGSizeMake(offsetWidth/(ringScale), offsetHeight/(ringScale));
        // mix that transform with the offset
        ringTransform = CGAffineTransformTranslate(sizeTransform, ringOffset.width, ringOffset.height);
        [self.dotTransforms addObject:[NSValue valueWithCGAffineTransform:ringTransform]];//ringOffset.width, ringOffset.height);
        // something goes really wrong
    }
}

- (void) colorDotsForActiveStateNumber: (int)activeStateNumber
{
    CGAffineTransform transform;
    transform = [(NSValue*)self.dotTransforms[activeStateNumber] CGAffineTransformValue];
    self.ring.path = CGPathCreateCopyByTransformingPath(((CAShapeLayer*)self.grayDots[activeStateNumber]).path, &transform);

    for (int i=0; i < self.grayDots.count;i++)
    {
        if (i < activeStateNumber)
        {
            ((CAShapeLayer*)self.grayDots[i]).strokeColor = [UIColor grayColor].CGColor;
        }
        else
        {
            ((CAShapeLayer*)self.grayDots[i]).strokeColor = [UIColor orangeColor].CGColor;
        }
    }
}

- (void) updateCircle { // problem on ipad, all layers need to update their position
    
    // ring is about a third the width of those gray dots
    // sometimes can enter updateCircle before drawing the rect, so grayDots need to be set first.

    if (self.grayDots.count >= 1) {
        switch (self.circleState)
        {
            case FSTCookingStatePrecisionCookingReachingTemperature:
                [self colorDotsForActiveStateNumber:0];
                break;
            case FSTCookingStatePrecisionCookingTemperatureReached:
                [self colorDotsForActiveStateNumber:1];
                break;
            case FSTCookingStatePrecisionCookingReachingMinTime:
            case FSTCookingStatePrecisionCookingCurrentStageDone:
                [self colorDotsForActiveStateNumber:2];
                break;
            case FSTCookingStatePrecisionCookingReachingMaxTime:
            case FSTCookingStatePrecisionCookingPastMaxTime:
                [self colorDotsForActiveStateNumber:3];
                break;
            case FSTCookingStatePrecisionCookingWithoutTime:
                [self colorDotsForActiveStateNumber:1];
                break;
            default:
                NSLog(@"NO STATE FOR STAGE BAR\n");
                break;
        }
    }
}

- (void)setCircleState:(ParagonCookMode)circleState { // state changed externally
    _circleState = circleState;
    [self updateCircle];
}

-(void)addState:(CGRect)rect
{
    CGFloat y = rect.size.height/2;
    CGFloat dotRadius = rect.size.height/8;
    
    //distance between the dots
    CGFloat barXSpacing = .2 * rect.size.width;
    
    //the width of the entire state bar
    CGFloat barWidth = rect.size.width * (.2 * ([self.numberOfStates intValue]-1));
    
    //the beginning of the state bar
    CGFloat barXOrigin = (rect.size.width - barWidth) / 2;
    
    //the current point's position
    CGFloat point = barXOrigin + (barXSpacing * self.grayDots.count);
    
    CAShapeLayer* grayLayer = [CAShapeLayer layer];
    grayLayer.strokeColor = [UIColor orangeColor].CGColor;
    
    grayLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(point, y) radius:dotRadius startAngle:0 endAngle:2*M_PI clockwise:false].CGPath;
    grayLayer.lineWidth = dotRadius*2;
    
    [self.layer insertSublayer:grayLayer above:self.layer];
    [self.grayDots addObject:grayLayer];
    
}

- (void)drawRect:(CGRect)rect
{
    self.layer.sublayers = nil;
    [self setupDots];
    
    CGFloat barWidth = rect.size.width * (.2 * ([self.numberOfStates intValue]-1));
    CGFloat barXOrigin = (rect.size.width - barWidth) / 2;
    CGFloat y = rect.size.height/2;
    UIBezierPath* underPath = [UIBezierPath bezierPath];
    CGFloat dotRadius = rect.size.height/8;
    
    for (int i=0; i < [self.numberOfStates intValue]; i++)
    {
        [self addState:rect];
    }
    self.lineWidth = barWidth ;
    [underPath moveToPoint:CGPointMake(barXOrigin, y)];
    [underPath addLineToPoint:CGPointMake(barXOrigin + self.lineWidth, y)];
    [[UIColor lightGrayColor] setStroke];
    [underPath stroke];
    
    //pulsing ring
    self.ring = [CAShapeLayer layer];
    self.ring.fillColor = [UIColor clearColor].CGColor;
    self.ring.strokeColor = [[UIColor orangeColor] CGColor];
    [self.layer addSublayer:self.ring];
    circlePulsingAnimation = [CABasicAnimation animationWithKeyPath:@"lineWidth"];
    circlePulsingAnimation.duration = 3.0;
    circlePulsingAnimation.autoreverses = YES;
    circlePulsingAnimation.repeatCount = HUGE_VAL;
    circlePulsingAnimation.fromValue = [NSNumber numberWithFloat:dotRadius*8];//*4];
    circlePulsingAnimation.toValue = [NSNumber numberWithFloat:dotRadius*4];
    [self.ring addAnimation:circlePulsingAnimation forKey:@"lineWidth"];
    [self arrangeTransforms];
}

@end
