/*****************************************************************************\
     Snes9x - Portable Super Nintendo Entertainment System (TM) emulator.
                This file is licensed under the Snes9x License.
   For further information, consult the LICENSE file in the root directory.
\*****************************************************************************/

#ifndef __S9X_SOUND_DRIVER_PORTAUDIO_HPP
#define __S9X_SOUND_DRIVER_PORTAUDIO_HPP

#include <errno.h>
#include <portaudio.h>

#include "s9x_sound_driver.hpp"

class S9xPortAudioSoundDriver : public S9xSoundDriver
{
  public:
    S9xPortAudioSoundDriver();
    ~S9xPortAudioSoundDriver();
    void init() override;
    void deinit() override;
    bool open_device(int playback_rate, int buffer_size) override;
    void start() override;
    void stop() override;
    bool write_samples(int16_t *data, int samples) override;
    int space_free() override;
    std::pair<int, int> buffer_level() override;
    void samples_available();
    bool tryHostAPI(int index);

  private:
    PaStream *audio_stream;
    int playback_rate;
    int buffer_size_ms;
    int output_buffer_size;
};

#endif /* __S9X_SOUND_DRIVER_PORTAUDIO_HPP */
