#include "streamingpreferences.h"
#include "streaming/session.hpp"

#include <QSettings>

#define SER_STREAMSETTINGS "streamsettings"
#define SER_WIDTH "width"
#define SER_HEIGHT "height"
#define SER_FPS "fps"
#define SER_BITRATE "bitrate"
#define SER_FULLSCREEN "fullscreen"
#define SER_GAMEOPTS "gameopts"
#define SER_HOSTAUDIO "hostaudio"
#define SER_MULTICONT "multicontroller"
#define SER_AUDIOCFG "audiocfg"
#define SER_VIDEOCFG "videocfg"
#define SER_VIDEODEC "videodec"

StreamingPreferences::StreamingPreferences()
{
    reload();
}

void StreamingPreferences::reload()
{
    QSettings settings;

    width = settings.value(SER_WIDTH, 1280).toInt();
    height = settings.value(SER_HEIGHT, 720).toInt();
    fps = settings.value(SER_FPS, 60).toInt();
    bitrateKbps = settings.value(SER_BITRATE, getDefaultBitrate(width, height, fps)).toInt();
    fullScreen = settings.value(SER_FULLSCREEN, true).toBool();
    gameOptimizations = settings.value(SER_GAMEOPTS, true).toBool();
    playAudioOnHost = settings.value(SER_HOSTAUDIO, false).toBool();
    multiController = settings.value(SER_MULTICONT, true).toBool();
    audioConfig = static_cast<AudioConfig>(settings.value(SER_AUDIOCFG,
                                                  static_cast<int>(AudioConfig::AC_AUTO)).toInt());
    videoCodecConfig = static_cast<VideoCodecConfig>(settings.value(SER_VIDEOCFG,
                                                  static_cast<int>(VideoCodecConfig::VCC_AUTO)).toInt());
    videoDecoderSelection = static_cast<VideoDecoderSelection>(settings.value(SER_VIDEODEC,
                                                  static_cast<int>(VideoDecoderSelection::VDS_AUTO)).toInt());
}

void StreamingPreferences::save()
{
    QSettings settings;

    settings.setValue(SER_WIDTH, width);
    settings.setValue(SER_HEIGHT, height);
    settings.setValue(SER_FPS, fps);
    settings.setValue(SER_BITRATE, bitrateKbps);
    settings.setValue(SER_FULLSCREEN, fullScreen);
    settings.setValue(SER_GAMEOPTS, gameOptimizations);
    settings.setValue(SER_HOSTAUDIO, playAudioOnHost);
    settings.setValue(SER_MULTICONT, multiController);
    settings.setValue(SER_AUDIOCFG, static_cast<int>(audioConfig));
    settings.setValue(SER_VIDEOCFG, static_cast<int>(videoCodecConfig));
    settings.setValue(SER_VIDEODEC, static_cast<int>(videoDecoderSelection));
}

bool StreamingPreferences::hasAnyHardwareAcceleration()
{
    // Always use VDS_AUTO to avoid spamming the user with warnings
    // if they've forced software decoding.
    return Session::isHardwareDecodeAvailable(VDS_AUTO,
                                              VIDEO_FORMAT_H264,
                                              1920, 1080, 60);
}

int StreamingPreferences::getMaximumStreamingFrameRate()
{
    // Never let the maximum drop below 60 FPS
    int maxFrameRate = 60;

    if (SDL_InitSubSystem(SDL_INIT_VIDEO) != 0) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
                     "SDL_InitSubSystem(SDL_INIT_VIDEO) failed: %s",
                     SDL_GetError());
        return maxFrameRate;
    }

    for (int i = 0; i < SDL_GetNumVideoDisplays(); i++) {
        SDL_DisplayMode mode;
        if (SDL_GetCurrentDisplayMode(i, &mode) == 0) {
            // Cap the frame rate at 90 FPS, since I can't seem to get
            // much more out of GFE even with the game rendering at > 300 FPS.
            maxFrameRate = qMax(maxFrameRate, qMin(90, mode.refresh_rate));
        }
    }

    SDL_QuitSubSystem(SDL_INIT_VIDEO);

    return maxFrameRate;
}

int StreamingPreferences::getDefaultBitrate(int width, int height, int fps)
{
    if (width * height <= 1280 * 720) {
        return static_cast<int>(5000 * (fps / 30.0));
    }
    else if (width * height <= 1920 * 1080) {
        return static_cast<int>(10000 * (fps / 30.0));
    }
    else if (width * height <= 2560 * 1440) {
        return static_cast<int>(20000 * (fps / 30.0));
    }
    else /* if (width * height <= 3840 * 2160) */ {
        return static_cast<int>(40000 * (fps / 30.0));
    }
}
