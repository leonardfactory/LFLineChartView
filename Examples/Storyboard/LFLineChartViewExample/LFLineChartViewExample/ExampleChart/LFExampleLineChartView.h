//
//  LFAverageLineChartView.h
//  MyLibretto
//
//  Created by Leonardo on 05/11/13.
//  Copyright (c) 2013 LeonardFactory. All rights reserved.
//

#import "LFLineChartView.h"

typedef enum _LFAverageMiddleLine
{
    LFAverageMiddleLineAverage = 0,
    LFAverageMiddleLineWeightedAverage = 1
} LFAverageMiddleLine;

@interface LFAverageLineChartView : LFLineChartView <LFLineChartViewDataSource, LFLineChartViewDelegate>

@property (strong, nonatomic) NSMutableArray *exams;

@end
