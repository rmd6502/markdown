//
//  markdownInterpreter.h
//  markdownReader
//
//  Created by Robert Diamond on 4/16/16.
//  Copyright © 2016 Robert Diamond. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MarkdownInterpreterDelegate <NSObject>
- (void)interpretResult:(NSAttributedString *)result;
- (void)interpretFailedWithError:(NSError *)error;

@optional
- (void)interpretStringStarted;
- (void)interpretStringFinished;

@end

@interface MarkdownInterpreter : NSObject

@property id<MarkdownInterpreterDelegate> delegate;

- (instancetype)initWithDelegate:(id<MarkdownInterpreterDelegate>)delegate;
- (void)interpretString:(NSString *)data;

@end
