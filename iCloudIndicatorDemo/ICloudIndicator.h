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

#import "CCNode.h"
#import "cocos2d.h"
#import "OpacityContainerNode.h"
#import "ICloudIndicatorDelegate.h"

/**
 * This enum contians all possible states of the indicator
 */
typedef enum {
    kIndicatorStateIdle = 0,
    kIndicatorStateShouldPulse = 1,
    kIndicatorStatePulsating = 2,
    kIndicatorStateProcessCloudChange = 3,
    kIndicatorStateEndingPulse = 4,
    kIndicatorStateDisplayResumableGame = 5,
    kIndicatorStateDisplayingResumableGame = 6,
    kIndicatorStateTouched = 7,
    kIndicatorStateResumeGame = 8,
    kIndicatorStateTouchedAndHolding = 9,
    kIndicatorStateTouchedAndLoweringPressure = 10,
    kIndicatorStateTouchedAndBuildingPressure = 11,
    kIndicatorStateExplode = 12
} IndicatorState;

@class ICloudIndicatorExplosion;


/**
 * @class ICloudIndicator is a UI element that can be used to let the user
 * resume or remove a game from the iCloud.
 */
@interface ICloudIndicator : CCNode<CCTargetedTouchDelegate> {
    id<ICloudIndicatorDelegate> delegate;
    
    CCSprite *              baseImage;
    CCSprite *              playIcon;
    OpacityContainerNode*   spriteParent;
    IndicatorState          state;
    ccTime                  pulseDuration;
    ccTime                  touchDuration;
    float                   pressure;
    
    CCSprite *              instructionArrow;
    NSMutableArray *        playInstructions;
    
    CCParticleRain *        pressureParticleSystem;
    ICloudIndicatorExplosion *   explosionParticleSystem;
    CGRect                  hitbox;
    dispatch_queue_t        stateQueue;
    BOOL                    isResumableCloudGame;
}
/**
 * Initializes the ICloudIndicator with the given delegate
 * which is notified when the user presses (to resume) or
 * taps and holds (to remove) the indicator
 */
- (id) initWithDelegate: (id<ICloudIndicatorDelegate>) del;

/**
 * Starts and stops the pulse animation meant to indicate that
 * the iCloud is being used. When busy is NO, based on the
 * last call of setIsResumableCloudGame: the indicator will either
 * disappear or show instructions to resume or remove the game
 */
- (void) setBusy: (BOOL) busy;

/**
 * Sets whether there is a resumable game in the iCloud.
 * When [self setBusy: NO] is called afterwards, the indicator
 * will either disappear (if there is no game) or show instructions
 * to resume or remove the game (if a resumable game is found).
 */
- (void) setIsResumableCloudGame: (BOOL) available;

@end
