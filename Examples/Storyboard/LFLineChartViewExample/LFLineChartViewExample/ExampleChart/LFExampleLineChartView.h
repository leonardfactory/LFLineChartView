//
//  LFAverageLineChartView.h
//  MyLibretto
//
//  Created by Leonardo on 05/11/13.
//  Copyright (c) 2013 LeonardFactory. All rights reserved.
//

#import "LFLineChartView.h"

@interface LFExampleLineChartView : LFLineChartView <LFLineChartViewDataSource, LFLineChartViewDelegate>

@property (strong, nonatomic) NSMutableArray *items;

- (id)initWithFrame:(CGRect)frame andItems:(NSArray *) items;

@end
