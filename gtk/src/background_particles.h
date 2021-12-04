#ifndef __BACKGROUND_PARTICLES_H
#define __BACKGROUND_PARTICLES_H
#include <vector>
#include <list>
#include <cstdint>
#include <random>

namespace Background
{

class Particles
{
  public:
    double rate = 0.5;

    enum Mode
    {
        Stars,
        Snow,
        Invalid
    };

    struct Particle
    {
        double x, y, dx, dy;
        unsigned int intensity;
    };

    Particles(enum Mode = Stars);
    ~Particles();
    void advance();
    void copyto(uint16_t *dst, int pitch);
    enum Mode getmode();
    void setmode(enum Mode);
    void set_game_image(uint16_t *src, int pitch);

    std::vector<uint16_t> output;

  private:
    inline void setpixel(int x, int y, uint16_t l);
    void advance_snow();
    void advance_starfield();

    std::minstd_rand mt;
    std::uniform_real_distribution<double> dis;
    std::vector<uint16_t> gameimage;
    std::list<Particle> particles;
    enum Mode mode;
    double wind;
    uint16_t color_table[32];
};

} // namespace Background
#endif // __BACKGROUND_PARTICLES_H