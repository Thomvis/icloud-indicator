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

#import "OpacityContainerNode.h"

@implementation OpacityContainerNode

- (void)addChild:(CCNode *)node z:(NSInteger)z tag:(NSInteger)tag {
    NSAssert([node conformsToProtocol: @protocol(CCRGBAProtocol)], @"Children of OpacityContainerNode must implement the CCRGBAProtocol");
    [super addChild:node z:z tag:tag];
}

-(GLubyte) opacity {
    return [(CCNode<CCRGBAProtocol> *)[[self children] objectAtIndex: 0] opacity];
}

-(void) setOpacity: (GLubyte) opacity {
    CCSprite *sprite;
    CCARRAY_FOREACH([self children], sprite) {
        [sprite setOpacity: opacity];
    }
}

@end
