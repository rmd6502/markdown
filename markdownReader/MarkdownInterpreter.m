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
             @"code": ^NSString *(NSString *code, NSString *language) {
                 //NSLog(@"code %@ %@", code, language);
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"code", @"text": code, @"language": language} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"blockquote": ^NSString *(NSString *quote) {
                 //NSLog(@"bq %@", quote);
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"bq", @"text": quote} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"html": ^NSString *(NSString *htmltext) {
                 //NSLog(@"html %@", htmltext);
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"html", @"text": htmltext} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"heading": ^NSString *(NSString *headingtext, NSNumber *level) {
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"heading", @"text": headingtext, @"level": level} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"hr": ^NSString *() {
                 //NSLog(@"hr");
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"hr"} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"list": ^NSString *(NSString *body, NSNumber *ordered) {
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"list", @"body": body, @"ordered": ordered} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"listitem": ^NSString *(NSString *itemtext) {
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"li", @"text": itemtext} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"paragraph": ^NSString *(NSString *ptext) {
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"para", @"text": ptext} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"table": ^NSString *(NSString *header, NSString *body) {
                 //NSLog(@"table %@ %@", header, body);
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"table", @"header": header, @"body": body} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"tablerow": ^NSString *(NSString *content) {
                 //NSLog(@"tr %@", content);
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"tr", @"text": content} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"tablecell": ^NSString *(NSString *content, NSDictionary *flags) {
                 //NSLog(@"cell %@ %@", content, flags);
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"cell", @"text": content, @"flags": flags} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"strong": ^NSString *(NSString *text) {
                 //NSLog(@"strong %@", text);
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"strong", @"text": text} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"em": ^NSString *(NSString *text) {
                 //NSLog(@"em %@", text.toString);
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"em", @"text": text} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"codespan": ^NSString *(NSString *text) {
                 //NSLog(@"codespan %@", text.toString);
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"codespan", @"text": text} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"br": ^NSString *() {
                 //NSLog(@"br");
                 return @"\n";
             },
             @"del": ^NSString *(NSString *text) {
                 //NSLog(@"del %@", text);
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"del", @"text": text} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"link": ^NSString *(NSString *href, NSString *title, NSString *text) {
                 //NSLog(@"link %@ %@ %@", href, title, text);
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"link", @"href": href, @"title": title, @"text": text} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"image": ^NSString *(NSString *href, NSString *title, NSString *text) {
                 //NSLog(@"image %@ %@ %@", href, title, text);
                 return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type": @"image", @"href": href, @"title": title, @"alt": text} options:0 error:nil] encoding:NSUTF8StringEncoding];
             },
             @"text": ^NSString *(NSString *text) {
                 return text;
             }
             };
}
@end
