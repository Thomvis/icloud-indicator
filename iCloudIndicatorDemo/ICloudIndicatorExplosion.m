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

#import "ICloudIndicatorExplosion.h"

@implementation ICloudIndicatorExplosion

-(id) init {
	return [self initWithTotalParticles:60];
}

-(id) initWithTotalParticles:(NSUInteger)p {
	if( (self=[super initWithTotalParticles:p]) ) {
        
		// duration
		duration = 0.1f;
		
		self.emitterMode = kCCParticleModeGravity;
        
		// Gravity Mode: gravity
		self.gravity = ccp(-118.0f,0);
		
		// Gravity Mode: speed of particles
		self.speed = 30;
		self.speedVar = 5;
		
		// Gravity Mode: radial
		self.radialAccel = 0;
		self.radialAccelVar = 0;
		
		// Gravity Mode: tagential
		self.tangentialAccel = 0;
		self.tangentialAccelVar = 0;
		
		// angle
		angle = 360;
		angleVar = 360;
        
		// emitter position
        self.position = ccp(0,0);
//		CGSize winSize = [[CCDirector sharedDirector] winSize];
//		self.position = ccp(winSize.width/2, winSize.height/2);
		posVar = ccp(25,5);
		
		// life of particles
		life = 0.0f;
		lifeVar = 0.58f;
		
		// size, in pixels
		startSize = 8.0f*CC_CONTENT_SCALE_FACTOR();
		startSizeVar = 8.0f*CC_CONTENT_SCALE_FACTOR();
		endSize = 2*CC_CONTENT_SCALE_FACTOR();
        
		// emits per second
		emissionRate = totalParticles/duration;
		
        startSpinVar = 100;
        
		// color of particles
		startColor.r = 1.0f;
		startColor.g = 1.0f;
		startColor.b = 1.0f;
		startColor.a = 1.0f;
		startColorVar.r = 0;
		startColorVar.g = 0;
		startColorVar.b = 0;
		startColorVar.a = 0;
		endColor.r = 1.0f;
		endColor.g = 1.0f;
		endColor.b = 1.0f;
		endColor.a = 1.0f;
		endColorVar.r = 0;
		endColorVar.g = 0;
		endColorVar.b = 0;
		endColorVar.a = 0.28f;
		
		self.texture = [[CCTextureCache sharedTextureCache] addImage: @"icloud-indicator-explosion-particle.png"];
        
		// additive
		self.blendAdditive = NO;
	}
	
	return self;
}
@end
