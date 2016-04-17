//
//  markdownInterpreter.m
//  markdownReader
//
//  Created by Robert Diamond on 4/16/16.
//  Copyright © 2016 Robert Diamond. All rights reserved.
//
#import <JavaScriptCore/JavaScriptCore.h>
#import "MarkdownInterpreter.h"

@interface MarkdownInterpreter()
@property JSVirtualMachine *jvm;
@property JSContext *context;
@end

@implementation MarkdownInterpreter

- (instancetype)initWithDelegate:(id<MarkdownInterpreterDelegate>)delegate
{
    if (self = [self init]) {
        _jvm = [JSVirtualMachine new];
        _context = [[JSContext alloc] initWithVirtualMachine:_jvm];
        _context.exceptionHandler = ^(JSContext *context, JSValue *error) {
            NSLog(@"context threw an exception: %@", error);
        };
        _delegate = delegate;
        NSURL *mdInterpreterUrl = [[NSBundle mainBundle] URLForResource:@"marked.min" withExtension:@"js"];
        if (mdInterpreterUrl) {
            NSString *mdInterpreterSource = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:mdInterpreterUrl] encoding:NSUTF8StringEncoding];
            _context[@"renderer"] = [self _rendererCallbacks];
            [_context evaluateScript:mdInterpreterSource withSourceURL:mdInterpreterUrl];
            [_context evaluateScript:@"marked.setOptions({renderer: renderer});\n"];
        }
    }
    return self;
}

- (void)interpretString:(NSString *)data
{
    [_context[@"marked"] callWithArguments:@[data, ^(JSValue *error, JSValue *content) {
        NSDictionary *errorDict = [error toDictionary];
        if (errorDict) {
            [self.delegate
             interpretFailedWithError:[NSError errorWithDomain:@"markdown"
                                                          code:-1
                                                      userInfo:@{NSLocalizedDescriptionKey: errorDict}]];
        } else {
            [self.delegate interpretResult:[content copy]];
        }
    }]];
}

- (NSDictionary *)_rendererCallbacks
{
    return @{
             @"code": ^JSValue *(NSString *code, NSString *language) {
                 //NSLog(@"code %@ %@", code, language);
                 return [JSValue valueWithObject:@{@"type": @"code", @"text": code, @"language": language} inContext:self.context];
             },
             @"blockquote": ^JSValue *(NSString *quote) {
                 //NSLog(@"bq %@", quote);
                 return [JSValue valueWithObject:@{@"type": @"bq", @"text": quote} inContext:self.context];
             },
             @"html": ^JSValue *(NSString *htmltext) {
                 //NSLog(@"html %@", htmltext);
                 return [JSValue valueWithObject:@{@"type": @"html", @"text": htmltext} inContext:self.context];
             },
             @"heading": ^JSValue *(NSString *headingtext, NSNumber *level) {
                 return [JSValue valueWithObject:@{@"type": @"heading", @"text": headingtext, @"level": level} inContext:self.context];
             },
             @"hr": ^JSValue *() {
                 //NSLog(@"hr");
                 return [JSValue valueWithObject:@{@"type": @"hr"} inContext:self.context];
             },
             @"list": ^JSValue *(JSValue *body, NSNumber *ordered) {
                 return [JSValue valueWithObject:@{@"type": @"list", @"body": body, @"ordered": ordered} inContext:self.context];
             },
             @"listitem": ^JSValue *(JSValue *itemtext) {
                 return [JSValue valueWithObject:@{@"type": @"li", @"text": itemtext} inContext:self.context];
             },
             @"paragraph": ^JSValue *(JSValue *ptext) {
                 return [JSValue valueWithObject:@{@"type": @"para", @"text": ptext} inContext:self.context];
             },
             @"table": ^JSValue *(JSValue *header, JSValue *body) {
                 //NSLog(@"table %@ %@", header, body);
                 return [JSValue valueWithObject:@{@"type": @"table", @"header": header, @"body": body} inContext:self.context];
             },
             @"tablerow": ^JSValue *(JSValue *content) {
                 //NSLog(@"tr %@", content);
                 return [JSValue valueWithObject:@{@"type": @"tr", @"text": content} inContext:self.context];
             },
             @"tablecell": ^JSValue *(JSValue *content, NSDictionary *flags) {
                 //NSLog(@"cell %@ %@", content, flags);
                 return [JSValue valueWithObject:@{@"type": @"cell", @"text": content, @"flags": flags} inContext:self.context];
             },
             @"strong": ^JSValue *(JSValue *text) {
                 //NSLog(@"strong %@", text);
                 return [JSValue valueWithObject:@{@"type": @"strong", @"text": text} inContext:self.context];
             },
             @"em": ^JSValue *(JSValue *text) {
                 //NSLog(@"em %@", text.toString);
                 return [JSValue valueWithObject:@{@"type": @"em", @"text": text} inContext:self.context];
             },
             @"codespan": ^JSValue *(JSValue *text) {
                 //NSLog(@"codespan %@", text.toString);
                 return [JSValue valueWithObject:@{@"type": @"codespan", @"text": text} inContext:self.context];
             },
             @"br": ^NSString *() {
                 //NSLog(@"br");
                 return @"\n";
             },
             @"del": ^JSValue *(JSValue *text) {
                 //NSLog(@"del %@", text);
                 return [JSValue valueWithObject:@{@"type": @"del", @"text": text} inContext:self.context];
             },
             @"link": ^JSValue *(NSString *href, NSString *title, JSValue *text) {
                 //NSLog(@"link %@ %@ %@", href, title, text);
                 return [JSValue valueWithObject:@{@"type": @"link", @"href": href, @"title": title, @"text": text} inContext:self.context];
             },
             @"image": ^JSValue *(NSString *href, NSString *title, JSValue *text) {
                 //NSLog(@"image %@ %@ %@", href, title, text);
                 return [JSValue valueWithObject:@{@"type": @"image", @"href": href, @"title": title, @"alt": text} inContext:self.context];
             },
             @"text": ^NSString *(NSString *text) {
                 return text;
             }
             };
}
@end
