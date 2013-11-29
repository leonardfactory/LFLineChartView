//
//  LFAverageLineChartView.m
//  MyLibretto
//
//  Created by Leonardo on 05/11/13.
//  Copyright (c) 2013 LeonardFactory. All rights reserved.
//

#import "LFAverageLineChartView.h"

#import "LFStatsCalculator.h"

#import "LFExam+Transient.h"
#import "UIColor+Custom.h"

@interface LFAverageLineChartView ()
{
    LFStatsCalculator *statsCalculator;
    NSInteger firstForecastedIndex;
}

@end

@implementation LFAverageLineChartView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _exams = [NSMutableArray array];
        self.datasource      = self;
        self.chartDelegate   = self;
        
        self.minimumItemRadius = 5.0;
        self.maximumItemRadius = 10.0;
        
        self.itemSpacing       = 100.0;
        self.initialScale      = 1.0;
        
        firstForecastedIndex = -1;
        
        statsCalculator = [[LFStatsCalculator alloc] init];
        [statsCalculator setExams:_exams];
    }
    return self;
}

- (void) setExams:(NSMutableArray *)exams
{
    _exams = [exams mutableCopy];
    
    // Discard not sustained exams.
    NSMutableArray *discardedItems = [NSMutableArray array];
    for(LFExam *exam in _exams)
    {
        if(
           ![exam respondsToSelector:@selector(status)] ||
           ([[exam status] intValue] != LFExamStatusSustained && [[exam status] intValue] != LFExamStatusFuture) ||
           ![exam hasRealScore]
            )
        {
            [discardedItems addObject:exam];
        }
    }
    [_exams removeObjectsInArray:discardedItems];
    
    firstForecastedIndex = -1;
    
    // Calculate first forecasted
    for(int i=0; i<[_exams count]; i++)
    {
        LFExam *exam = [_exams objectAtIndex:i];
        if([[exam status] intValue] == LFExamStatusFuture)
        {
            firstForecastedIndex = i;
            break;
        }
    }
    
    [statsCalculator setExams:_exams];
}

#pragma mark LineChartView data source
- (NSUInteger) numberOfItemsInLineChartView:(LFLineChartView *)lineChartView
{
    return [_exams count];
}

- (CAShapeLayer *) lineChartView:(LFLineChartView *)lineChartView createLayerAtIndex:(NSUInteger)index
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    //layer.path          = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-5.0, -5.0, 10.0, 10.0)].CGPath;
    layer.fillColor     = [UIColor whiteColor].CGColor;
    return layer;
}

- (CAShapeLayer *) lineChartView:(LFLineChartView *)lineChartView createLineLayerBetweenIndex:(NSUInteger)firstIndex andIndex:(NSUInteger)secondIndex
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0.0, 0.0);
    CGPathAddLineToPoint(path, NULL, 1.0, 1.0);
    layer.path          = path;
    CGPathRelease(path);
    
    layer.lineWidth     = 3.0;
    layer.strokeColor   = [UIColor generalColor].CGColor;
    
    // Make it dashed if it's a forecasted value
    if(secondIndex >= firstForecastedIndex)
    {
        layer.lineDashPattern   = @[@0, @(3.0*2)];
        layer.lineDashPhase     = 3.0;
        layer.lineCap           = kCALineCapRound;
    }
    
    return layer;
}

- (CGFloat) yAtIndex:(NSUInteger)index
{
    return (CGFloat)[((LFExam *)[_exams objectAtIndex:index]) countableScore];
}

// -----------------------------------------------------------------
// Size
// -----------------------------------------------------------------
- (CGFloat) sizeAtIndex:(NSUInteger)index
{
    return ((LFExam *)[_exams objectAtIndex:index]).weight.floatValue;
}

// -----------------------------------------------------------------
// Text
// -----------------------------------------------------------------
- (NSString *) scoreTextAtIndex:(NSUInteger)index
{
    return [((LFExam *)[_exams objectAtIndex:index]) scoreText];
}

- (NSString *) textAtIndex:(NSUInteger)index
{
    LFExam *exam = [_exams objectAtIndex:index];
    return [NSString stringWithFormat:@"%@\n%@", exam.name, exam.scoreText];
}

// -----------------------------------------------------------------
// Middle lines (average)
// -----------------------------------------------------------------
- (NSUInteger) numberOfMiddleLinesInLineChartView:(LFLineChartView *)lineChartView
{
    if([_exams count] > 0)
    {
        return 2;
    }
    else
    {
        return 0;
    }
}

- (CAShapeLayer *) lineChartView:(LFLineChartView *)lineChartView createMiddleLineLayerAtIndex:(NSUInteger)index
{
    CAShapeLayer *layer = [CAShapeLayer layer];
    
    // Initialize to path with two points to make it animatable
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0.0, 0.0);
    CGPathAddLineToPoint(path, NULL, 1.0, 1.0);
    layer.path          = path;
    CGPathRelease(path);
    
    layer.lineWidth         = 3.0;
    if(index == LFAverageMiddleLineAverage)
    {
        layer.strokeColor       = [UIColor statsBackgroundColor].CGColor;
    }
    else if(index == LFAverageMiddleLineWeightedAverage)
    {
        layer.strokeColor       = [UIColor averageLineColor].CGColor;
    }
    layer.lineDashPattern   = @[@0, @(3.0*2)];
    layer.lineDashPhase     = 3.0;
    layer.lineCap           = kCALineCapRound;
    
    return layer;
}

- (CGFloat) yForMiddleLineAtIndex:(NSUInteger) index
{
    if(index == LFAverageMiddleLineAverage)
    {
        return statsCalculator.average;
    }
    
    if(index == LFAverageMiddleLineWeightedAverage)
    {
        return statsCalculator.weightedAverage;
    }
    
    return 0.0;
}

- (UIView *) emptyViewForLineChartView:(LFLineChartView *)lineChartView
{
    UIView *emptyView = [[[NSBundle mainBundle] loadNibNamed:@"EmptyBucketView" owner:self options:nil] objectAtIndex:0];
    return emptyView;
}

@end
