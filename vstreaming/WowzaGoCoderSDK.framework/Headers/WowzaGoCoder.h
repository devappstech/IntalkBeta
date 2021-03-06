//
//  WowzaGoCoder.h
//  WowzaGoCoderSDK
//
//  Copyright 2007 – 2016, Wowza Media Systems, LLC.  All rights
//  reserved.
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import "WowzaConfig.h"
#import "WZStatusCallback.h"
#import "WZCameraPreview.h"
#import "WZVideoSink.h"
#import "WZAudioSink.h"
#import "WZVideoEncoderSink.h"
#import "WZAudioEncoderSink.h"
#import "WZDataEvent.h"


/*!
 *  @class WowzaGoCoder
 *  @discussion The WowzaGoCoder class is the primary API interface for the GoCoder SDK. It provides methods for both device and streaming configuration and control
 */
@interface WowzaGoCoder : NSObject <WZStatusCallback>


/*!
 *  @typedef WowzaGoCoderLogLevel
 *  @constant WowzaGoCoderLogLevelOff Disable logging.
 *  @constant WowzaGoCoderLogLevelDefault Emit a minimum of log statements from the SDK.
 *  @constant WowzaGoCoderLogLevelVerbose Emit a verbose amount of log statements from the SDK.
 *  @discussion Settings for the desired log level for the GoCoder SDK.
 */
typedef NS_ENUM(NSUInteger, WowzaGoCoderLogLevel) {
    WowzaGoCoderLogLevelOff,
    WowzaGoCoderLogLevelDefault,
    WowzaGoCoderLogLevelVerbose
};

/*!
 *  @typedef WowzaGoCoderCapturePermission
 *  @constant WowzaGoCoderCapturePermissionAuthorized Access to a particular capture device has been authorized user.
 *  @constant WowzaGoCoderCapturePermissionDenied Access to a particular capture device has been denied by the user.
 *  @constant WowzaGoCoderCapturePermissionNotDetermined Access to a particular capture device has yet to be determined.
 *  @discussion Permissions for either an audio or video capture device.
 */
typedef NS_ENUM(NSUInteger, WowzaGoCoderCapturePermission) {
    WowzaGoCoderCapturePermissionAuthorized,
    WowzaGoCoderCapturePermissionDenied,
    WowzaGoCoderCapturePermissionNotDetermined
};

/*!
 *  @typedef WowzaGoCoderPermissionType
 *  @constant WowzaGoCoderPermissionTypeCamera The device camera permission type
 *  @constant WowzaGoCoderPermissionTypeMicrophone The device microphone permission type.
 *  @discussion Permission types that are availble in the SDK.
 */
typedef NS_ENUM(NSUInteger, WowzaGoCoderPermissionType) {
    WowzaGoCoderPermissionTypeCamera,
    WowzaGoCoderPermissionTypeMicrophone
};

/*!
 *  @typedef WZPermissionBlock A callback block that is used with requestCameraPermission and requestMicrophonePermission
 */
typedef void (^WZPermissionBlock)(WowzaGoCoderCapturePermission permission);


// Class methods
/*!
 *  Register and validate the GoCoder SDK license key
 *
 *  @param licenseKey The license key
 *
 *  @return An NSError describing the license validation error, or nil if no error
 */
+ (nullable NSError *) registerLicenseKey:(nonnull NSString *)licenseKey;

/*!
 *  Set the SDK log level
 *
 *  @param level The desired log level
 */
+ (void) setLogLevel:(WowzaGoCoderLogLevel)level;


/*!
 *  Explicitly request permission to use the camera or microphone.
 *
 *  @param type The WowzaGoCoderPermissionType for which permission is being requested.
 *  @param response The WZPermissionBlock to be executed once the user responds to the
 *  the device access request.
 */
+ (void) requestPermissionForType:(WowzaGoCoderPermissionType)type response:(nullable WZPermissionBlock)response;

/*!
 *  Get the current permission status for a given WowzaGoCoderPermissionType
 *
 *  @param type The WowzaGoCoderPermissionType to query
 */
+ (WowzaGoCoderCapturePermission) permissionForType:(WowzaGoCoderPermissionType)type;

/*!
 Get the WowzaGoCoder shared instance
 @result
    An instance of the top level GoCoder SDK API interface, or nil if licensing failed
 */
+ (nullable instancetype) sharedInstance;

// Properties

/*!
 *  The video, audio and stream configuration settings
 */
@property (nonatomic, nonnull, copy) WowzaConfig *config;

/*!
 *  The view that the caller wants to use for the camera preview
 */
@property (nonatomic, nullable) UIView *cameraView;

/*!
 *  The WZCameraPreview object (created when the cameraView is set)
 */
@property (nonatomic, nullable, readonly) WZCameraPreview *cameraPreview;

/*!
 @property status
 @discussion Reflects the current live streaming session status
 */
@property (nonatomic, nonnull, readonly) WZStatus *status;

/*!
 *  The muted state of the audio encoder
 */
@property (nonatomic, assign, getter=isAudioMuted) BOOL audioMuted;

/*!
 *  The AVAudioSessionCategoryOptions to use if streaming with audio. Default is AVAudioSessionCategoryOptionAllowBluetooth.
 *  Note that this property must be set before starting a preview session.
 */
@property (nonatomic, assign) AVAudioSessionCategoryOptions audioSessionOptions;

/*!
 *  Returns true if a live streaming broadcast is active
 */
@property (nonatomic, readonly) BOOL isStreaming;

// Instance methods
+ (nonnull instancetype) alloc __attribute__((unavailable("alloc not available, call the sharedInstance class method instead")));
- (nonnull instancetype) init __attribute__((unavailable("init not available, call the sharedInstance class method instead")));
+ (nonnull instancetype) new __attribute__((unavailable("new not available, call the sharedInstance class method instead")));
- (nonnull instancetype) copy __attribute__((unavailable("copy not available, call the sharedInstance class method instead")));



/*!
 Starts a live streaming session
 @param statusCallback
    A callback that will be invoked with streaming session status updates and errors.
 */
- (void) startStreaming:(nullable id<WZStatusCallback>)statusCallback;

/*!
 Starts a live streaming session
 @param statusCallback
 A callback that will be invoked with streaming session status updates and errors.
 @param aConfig
 The configuration settings for the live streaming session.
 */
- (void) startStreamingWithConfig:(nullable id<WZStatusCallback>)statusCallback config:(nonnull WowzaConfig *)aConfig;

/*!
 Starts a live streaming session
 @param statusCallback
 A callback that will be invoked with streaming session status updates and errors.
 @param aPreset
 The WZFrameSizePreset for the live streaming session.
 */
- (void) startStreamingWithPreset:(nullable id<WZStatusCallback>)statusCallback preset:(WZFrameSizePreset)aPreset;

/*!
 End the active streaming session
 @param statusCallback
    A callback that will be invoked with streaming session status updates and errors.
 */
- (void) endStreaming:(nullable id<WZStatusCallback>)statusCallback;

/*!
 *  Send user-defined metadata within the current broadcast stream.
 *
 *  @param event A WZDataEvent object containing the event data and the event name.
 *
 */
- (void) sendDataEvent:(nonnull WZDataEvent *)event;

#pragma mark -

/*!
 *  Registers an object that conforms to the WZVideoSink protocol with WowzaGoCoder.
 *  the WZVideoSink protocol methods will be called when video capture and/or encoding
 *  are active.
 *
 *  @param sink An object conforming to the WZVideoSink protocol
 */
- (void) registerVideoSink:(nonnull id<WZVideoSink>)sink;

/*!
 *  Unregisters an object that conforms to the WZVideoSink protocol with WowzaGoCoder.
 *
 *  @param sink An object conforming to the WZVideoSink protocol
 */
- (void) unregisterVideoSink:(nonnull id<WZVideoSink>)sink;

/*!
 *  Registers an object that conforms to the WZAudioSink protocol with WowzaGoCoder.
 *  the WZAudioSink protocol methods will be called when audio capture and/or encoding
 *  are active.
 *
 *  @param sink An object conforming to the WZAudioSink protocol
 */
- (void) registerAudioSink:(nonnull id<WZAudioSink>)sink;

/*!
 *  Unregisters an object that conforms to the WZAudioSink protocol with WowzaGoCoder.
 *
 *  @param sink An object conforming to the WZAudioSink protocol
 */
- (void) unregisterAudioSink:(nonnull id<WZAudioSink>)sink;

/*!
 *  Registers an object that conforms to the WZVideoEncoderSink protocol with WowzaGoCoder.
 *  The WZVideoEncoderSink protocol methods will be called when video encoding
 *  is active.
 *
 *  @param sink An object conforming to the WZVideoEncoderSink protocol
 */
- (void) registerVideoEncoderSink:(nonnull id<WZVideoEncoderSink>)sink;

/*!
 *  Unregisters an object that conforms to the WZVideoEncoderSink protocol with WowzaGoCoder.
 *
 *  @param sink An object conforming to the WZVideoEncoderSink protocol
 */
- (void) unregisterVideoEncoderSink:(nonnull id<WZVideoEncoderSink>)sink;

/*!
 *  Registers an object that conforms to the WZAudioEncoderSink protocol with WowzaGoCoder.
 *  The WZAudioEncoderSink protocol methods will be called when video encoding
 *  is active.
 *
 *  @param sink An object conforming to the WZAudioEncoderSink protocol
 */
- (void) registerAudioEncoderSink:(nonnull id<WZAudioEncoderSink>)sink;

/*!
 *  Unregisters an object that conforms to the WZAudioEncoderSink protocol with WowzaGoCoder.
 *
 *  @param sink An object conforming to the WZAudioEncoderSink protocol
 */
- (void) unregisterAudioEncoderSink:(nonnull id<WZAudioEncoderSink>)sink;


@end
