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

#import "ICloudIndicator.h"
#import "ICloudIndicatorExplosion.h"
#import "AppDelegate.h"

// the minimum time (in seconds) that the indicator will pulse when busy
#define kIndicatorMinPulseTime 0.5
// an internal constant to identify the pulse action
#define kIndicatorPulseActionTag 1
// the size of the indicator's instruction font
#define kIndicatorFontSize 11.0f

@interface ICloudIndicator ()
/**
 * Loads the assets and creates the sub-nodes of the indicator
 */
- (void) build;
/**
 * Is called to cycle through the instructions for removing
 * and resuming a game from the iCloud
 */
- (void) nextInstruction: (CCNode *) sender;
/**
 * Shows the triangle (play icon) in the cloud to indicate that
 * a resumable game is present
 */
- (void) displayPlayIcon;
/**
 *
 */
- (void) hidePlayIcon;

- (void) startCloudGameInstructions;
- (void) endCloudGameInstructions;

- (void) startPulsating;
- (void) stopPulsating;
- (BOOL) isPulsating;

- (BOOL) isTouchedByPoint: (CGPoint) point;

@end

@implementation ICloudIndicator

- (id) initWithDelegate: (id<ICloudIndicatorDelegate>) del {
    self = [super init];
    if (self) {
        delegate = del;
        state = kIndicatorStateIdle;
        stateQueue = dispatch_queue_create("iCloudIndicatorStateQueue", NULL);
        [self build];
    }
    
    return self;
}

- (void) dealloc {
    [baseImage release];
    [playIcon release];
    [playInstructions release];
    dispatch_release(stateQueue);
    [super dealloc];
}

- (void) build {
    spriteParent = [[OpacityContainerNode alloc] init];
    [self addChild: spriteParent];
    [spriteParent release];
    
    baseImage = [[CCSprite alloc] initWithFile: @"icloud.png"];
    baseImage.scale = 0.7f;
    baseImage.opacity = 0;
    [spriteParent addChild: baseImage z: 0];
    
    // remember the hitbox to be able to detect touches while the cloud 'rises'
    hitbox = CGRectInset([baseImage boundingBox],-20.0f,-20.0f);
    
    playIcon = [[CCSprite alloc] initWithFile: @"icloud-play.png"];
    playIcon.scale = 0.7f;
    playIcon.anchorPoint = ccp(0.40f, 0.6f);
    playIcon.visible = NO;
    [spriteParent addChild: playIcon z: 1];
    
    // play instructions
    instructionArrow = [[CCSprite alloc] initWithFile: @"icloud-instruction-arrow.png"];
    instructionArrow.position = ccp(-30, -2);
    instructionArrow.opacity = 0.0f;
    [self addChild: instructionArrow];
    [instructionArrow release];
    
    playInstructions = [[NSMutableArray alloc] init];
    
    CCLabelTTF *instruction1 = [[CCLabelTTF alloc] initWithString:@"A game was found in iCloud" fontName:@"Helvetica" fontSize:kIndicatorFontSize];
    instruction1.anchorPoint = ccp(1,0.5);
    instruction1.position = ccp(-40, -2);
    instruction1.opacity = 0.0f;
    [self addChild: instruction1];
    [playInstructions addObject: instruction1];
    [instruction1 release];
    
    CCLabelTTF *instruction2 = [[CCLabelTTF alloc] initWithString:@"Tap to resume the game" fontName:@"Helvetica" fontSize:kIndicatorFontSize];
    instruction2.anchorPoint = ccp(1,0.5);
    instruction2.position = ccp(-40, -2);
    instruction2.opacity = 0.0f;
    [self addChild: instruction2];
    [playInstructions addObject: instruction2];
    [instruction2 release];
    
    CCLabelTTF *instruction3 = [[CCLabelTTF alloc] initWithString:@"Tap and hold to remove the game" fontName:@"Helvetica" fontSize: kIndicatorFontSize];
    instruction3.anchorPoint = ccp(1,0.5);
    instruction3.position = ccp(-40, -2);
    instruction3.opacity = 0.0f;
    [self addChild: instruction3];
    [playInstructions addObject: instruction3];
    [instruction3 release];
    
    // particle systems
    pressureParticleSystem = [[CCParticleRain alloc] init];
    pressureParticleSystem.position = CGPointZero;
    pressureParticleSystem.posVar = ccp(15,2);
    pressureParticleSystem.startSize = 2;
    pressureParticleSystem.startSizeVar = 1;
    pressureParticleSystem.life = 1.0f;
    [pressureParticleSystem stopSystem];
    [self addChild: pressureParticleSystem z: -1];
    [pressureParticleSystem release];
    
    explosionParticleSystem = [[ICloudIndicatorExplosion alloc] init];
    explosionParticleSystem.position = ccp(0,80);
    [self addChild: explosionParticleSystem];
    [explosionParticleSystem release];
    [explosionParticleSystem stopSystem];
}

-(void) onEnter {
    [super onEnter];
    [self scheduleUpdate];
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate: self priority:1 swallowsTouches:YES];
}

- (void) onExit {
    [super onExit];
    [[CCTouchDispatcher sharedDispatcher] removeDelegate: self];
}

- (void) update: (ccTime) delta {
    dispatch_sync(stateQueue, ^{
    switch (state) {
        case kIndicatorStateIdle:
            // do nothing
            break;
        case kIndicatorStateShouldPulse:
            [self startPulsating];
            state = kIndicatorStatePulsating;
            break;
        case kIndicatorStatePulsating:
            pulseDuration += delta;
            break;
        case kIndicatorStateProcessCloudChange:
            if (isResumableCloudGame) {
                state = kIndicatorStateDisplayResumableGame;
            } else {
                state = kIndicatorStateEndingPulse;
            }
            break;
        case kIndicatorStateEndingPulse:
            pulseDuration += delta;
            if (pulseDuration > kIndicatorMinPulseTime) {
                [self stopPulsating];
                state = kIndicatorStateIdle;
            }
            break;
        case kIndicatorStateDisplayResumableGame:
            [self stopPulsating];
            [self displayPlayIcon];
            [self startCloudGameInstructions];
            state = kIndicatorStateDisplayingResumableGame;
            break;
        case kIndicatorStateDisplayingResumableGame:
            // do nothing
            break;
        case kIndicatorStateTouched:
            if (touchDuration == 0) {
                [self endCloudGameInstructions];
            }
            
            touchDuration += delta;
            
            if (touchDuration > 0.4f) {
                state = kIndicatorStateTouchedAndHolding;
            }
            break;
        case kIndicatorStateTouchedAndHolding:
            // start stressing
            touchDuration += delta;
            if (touchDuration > 0.3f) {
                pressure = 0;
                state = kIndicatorStateTouchedAndBuildingPressure;
            }
            break;
        case kIndicatorStateTouchedAndBuildingPressure:
            if (pressure == 0) {
                pressure = 0.1f;
                [pressureParticleSystem resetSystem];
                [spriteParent stopAllActions];
                [pressureParticleSystem stopAllActions];
                [spriteParent runAction: [CCEaseExponentialOut actionWithAction: 
                                          [CCMoveBy actionWithDuration:4.0f position:ccp(0,80)]]];
                [pressureParticleSystem runAction: [CCEaseExponentialOut actionWithAction: 
                                          [CCMoveBy actionWithDuration:4.0f position:ccp(0,80)]]];
            } else if(pressure < 0.7f) {
                pressure *= 1.0f + (0.9f*delta);
                pressureParticleSystem.emissionRate = pressure * 80;
            } else if (pressure > 0.7f) {
                pressure = 0.7f;
                state = kIndicatorStateExplode;
            }
            break;
        case kIndicatorStateTouchedAndLoweringPressure:
            if ([spriteParent getActionByTag: 23] == nil) {
                [spriteParent stopAllActions];
                [pressureParticleSystem stopAllActions];
                CCAction * act =[[CCEaseExponentialOut actionWithAction: 
                                [CCMoveTo actionWithDuration:1.0f position:ccp(0,0)]] retain];
                act.tag = 23;
                [spriteParent runAction: act];
                [act release];
                
                [pressureParticleSystem runAction: 
                    [CCSpawn actionOne:[CCEaseExponentialOut actionWithAction: 
                           [CCMoveTo actionWithDuration:1.0f position:CGPointZero]]
                      two: [CCActionTween actionWithDuration:3.0f key:@"emissionRate" from:20 to:0]]];
            }
            
            if (pressure < 0.1f) {
                pressure = 0;
                state = kIndicatorStateDisplayResumableGame;
            } else if (pressure >= 0.1f) {
                pressure *= 1.0f - (1.5f*delta);
                pressureParticleSystem.emissionRate = 20 + (pressure * 60);
            }
            break;
        case kIndicatorStateExplode:
            [spriteParent stopAllActions];
            baseImage.opacity = 0;
            playIcon.visible = NO;
            spriteParent.position = ccp(0,0);
            [pressureParticleSystem stopAllActions];
            pressureParticleSystem.position = ccp(0,0);
            pressure = 0;
            [pressureParticleSystem stopSystem];
            [explosionParticleSystem resetSystem];
            if ([delegate removeGame]) {
                isResumableCloudGame = NO;
                state = kIndicatorStateIdle;
            }
            break;
        case kIndicatorStateResumeGame:
            if ([delegate resumeGame]) {
                isResumableCloudGame = NO;
                
                [spriteParent stopAllActions];
                baseImage.opacity = 0;
                playIcon.visible = NO;
                spriteParent.position = ccp(0,0);
                
                state = kIndicatorStateIdle;
            }
            break;
    }
    });
    
    // consider pressure
    if (pressure > 0.0f) {
        float angle = CCRANDOM_0_1()*2*M_PI;
        float length = CCRANDOM_0_1()*powf(pressure,2)*20;
        CGPoint pDelta = ccpForAngle(angle);
        pDelta = ccpMult(pDelta, length);
        [baseImage setPosition: pDelta];
        [playIcon setPosition: pDelta];
    } else {
        baseImage.position = ccp(0,0);
        playIcon.position = ccp(0,0);
    }
}

- (void) displayPlayIcon {
    playIcon.visible = YES;
}

- (void) hidePlayIcon {
    playIcon.visible = NO;
}

- (void) startCloudGameInstructions {
    [self nextInstruction: [playInstructions lastObject]];
}

- (void) nextInstruction: (CCNode *) sender {
    if (state != kIndicatorStateDisplayingResumableGame && state != kIndicatorStateDisplayResumableGame) {
        return;
    }
    NSUInteger index = [playInstructions indexOfObject: sender];
    CCNode *next = [playInstructions objectAtIndex: (index+1)%[playInstructions count]];
    [next runAction: [CCSequence actions:[CCFadeIn actionWithDuration: 0.2f], 
                      [CCDelayTime actionWithDuration: 2.5f],
                      [CCFadeOut actionWithDuration: 0.2f],
                      [CCCallFuncN actionWithTarget:self selector:@selector(nextInstruction:)],
                      nil]];
    instructionArrow.position = ccpAdd(instructionArrow.position, ccp(-20,0));
    [instructionArrow runAction: [CCSequence actions:
                                  [CCSpawn actionOne: [CCFadeIn actionWithDuration: 0.2f] two:[CCEaseExponentialOut actionWithAction: [CCMoveBy actionWithDuration:0.2f position: ccp(20,0)]]],
                                  [CCDelayTime actionWithDuration: 2.5f],
                                  [CCFadeOut actionWithDuration: 0.2f],
                                  nil]];
}


- (void) endCloudGameInstructions {
    [instructionArrow stopAllActions];
    [instructionArrow runAction: [CCFadeOut actionWithDuration: 0.2f]];
    for (CCLabelBMFont *instr in playInstructions) {
        [instr stopAllActions];
        [instr runAction: [CCFadeTo actionWithDuration:0.2f opacity:0]];
    }
}

- (void) startPulsating {
    [baseImage stopAllActions];
    CCAction *act = [[CCRepeatForever actionWithAction: 
                            [CCSequence actionOne:
                                    [CCEaseIn actionWithAction: [CCFadeIn actionWithDuration: 0.2f]] 
                                two:[CCFadeOut actionWithDuration: 0.8f]]] retain];
    act.tag = kIndicatorPulseActionTag;
    [baseImage runAction: act];
    [act release];
}

- (void) stopPulsating {
    if (state == kIndicatorStateDisplayResumableGame) {
        [baseImage stopActionByTag: kIndicatorPulseActionTag];
        [baseImage runAction:[CCFadeTo actionWithDuration:0.2f opacity: 255]];
    } else {
        if ([baseImage getActionByTag: kIndicatorPulseActionTag] != nil) {
            [baseImage stopActionByTag: kIndicatorPulseActionTag];
            [baseImage runAction:[CCFadeTo actionWithDuration:0.2f opacity: 0]];
        }
    }
}

- (BOOL) isPulsating {
    return state == kIndicatorStatePulsating || state == kIndicatorStateShouldPulse;
}

- (void) setBusy: (BOOL) busy {
    dispatch_async(stateQueue, ^{
        if (busy) {
            if (state == kIndicatorStateIdle) {
                state = kIndicatorStateShouldPulse;
            }
        } else if ([self isPulsating]) {
            state = kIndicatorStateProcessCloudChange;
        }
    });
}

- (void) setIsResumableCloudGame: (BOOL) available {
    dispatch_async(stateQueue, ^{
        isResumableCloudGame = available;
    });
}

#pragma mark Touch handling

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL __block res = NO;
    dispatch_sync(stateQueue, ^{
        if (state != kIndicatorStateDisplayingResumableGame || !self.visible) {
            res = NO;
        } else {        
            CGPoint p = [self convertTouchToNodeSpaceAR: touch];
            if ([self isTouchedByPoint: p]) {
                state = kIndicatorStateTouched;
                touchDuration = 0;
                res = YES;
            }
        }
    });
    return res;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    dispatch_sync(stateQueue, ^{
        CGPoint p = [self convertTouchToNodeSpaceAR: touch];
        if ([self isTouchedByPoint: p]) {
            if (state == kIndicatorStateTouchedAndLoweringPressure) {
                state = kIndicatorStateTouchedAndBuildingPressure;
            }
        } else {
            if (state == kIndicatorStateTouchedAndBuildingPressure) {
                state = kIndicatorStateTouchedAndLoweringPressure;
            }
        }
    });
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    dispatch_sync(stateQueue, ^{
        CGPoint p = [self convertTouchToNodeSpaceAR: touch];

        if ([self isTouchedByPoint: p]) {
            // touch ended inside
            if (state == kIndicatorStateTouched) {
                state = kIndicatorStateResumeGame;
            } else if (state == kIndicatorStateTouchedAndHolding || state == kIndicatorStateTouchedAndBuildingPressure) {
                state = kIndicatorStateTouchedAndLoweringPressure;
            }
        } else {
            // touch ended outside
            if (state == kIndicatorStateTouched) {
                state = kIndicatorStateDisplayResumableGame;
            } else if (state == kIndicatorStateTouchedAndHolding || state == kIndicatorStateTouchedAndBuildingPressure) {
                state = kIndicatorStateTouchedAndLoweringPressure;
            }
        }
    });
}

- (BOOL) isTouchedByPoint: (CGPoint) point {
    return CGRectContainsPoint(hitbox, point);
}



@end
