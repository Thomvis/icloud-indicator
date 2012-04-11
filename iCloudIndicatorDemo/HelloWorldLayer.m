/*
 * iCloudIndicator
 *
 * https://github.com/Thomvis/icloud-indicator
 *
 * Copyright (c) 2012 Thomas Visser
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */


// Import the interfaces
#import "HelloWorldLayer.h"
#import "ICloudIndicator.h"

// HelloWorldLayer implementation
@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

- (void) dealloc {
	[super dealloc];
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		indicator = [[ICloudIndicator alloc] initWithDelegate: self];
        indicator.position = ccp(440,30);
		
        statusLabel = [[CCLabelTTF alloc] initWithString:@"" fontName:@"Helvetica" fontSize: 18.0f];
        statusLabel.position = ccp(240,180);
        [self addChild: statusLabel];
		// add the label as a child to this Layer
		[self addChild: indicator];
        [indicator release];
	}
	return self;
}

- (void) onEnter {
    [super onEnter];
    [self startDemo];
}

- (void) startDemo {
    dispatch_async(dispatch_get_main_queue(), ^{
        [statusLabel setString: @"Demo initiated"];
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [indicator setBusy: YES];
        sleep(1.5);
        [indicator setIsResumableCloudGame: YES];
        [indicator setBusy: NO];        
    });
}

- (BOOL) resumeGame {
    [statusLabel setString: @"resumeGame callback called"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(2);
        [self startDemo];
    });
    return YES;
}

- (BOOL) removeGame {
    [statusLabel setString: @"removeGame callback called"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(2);
        [self startDemo];
    });
    return YES;
}

@end
