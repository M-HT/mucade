#!/bin/sh

# ODE library must be compiled with singles as floating point datatype and not with doubles
# otherwise parameter dSINGLE must be changed to dDOUBLE
FLAGS="-frelease -fdata-sections -ffunction-sections -fno-section-anchors -c -O2 -Wall -pipe -fversion=PYRA -fversion=dSINGLE -fversion=USE_SIMD -ffast-math -fversion=BindSDL_Static -fversion=SDL_201 -fversion=SDL_Mixer_202 -I`pwd`/import -march=armv7ve+simd -mcpu=cortex-a15 -mtune=cortex-a15 -mfpu=neon-vfpv4 -mfloat-abi=hard -mthumb"
CFLAGS="-c -O2 -Wall -pipe -ffast-math -march=armv7ve+simd -mcpu=cortex-a15 -mtune=cortex-a15 -mfpu=neon-vfpv4 -mfloat-abi=hard -mthumb"

rm import/*.o*
rm import/ode/*.o*
rm import/sdl/*.o*
rm import/bindbc/sdl/*.o*
rm src/abagames/util/*.o*
rm src/abagames/util/bulletml/*.o*
rm src/abagames/util/ode/*.o*
rm src/abagames/util/sdl/*.o*
rm src/abagames/mcd/*.o*

cd import
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS \{\} \;
cd sdl
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS \{\} \;
cd ../bindbc/sdl
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS \{\} \;
cd ../../ode
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS -I.. \{\} \;
cd ../..

cd src/abagames/util
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS -I../.. \{\} \;
cd ../../..

cd src/abagames/util/bulletml
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS -I../../.. \{\} \;
cd ../../../..

cd src/abagames/util/ode
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS -I../../.. \{\} \;
cd ../../../..

cd src/abagames/util/sdl
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS -I../../.. \{\} \;
cd ../../../..

cd src/abagames/mcd
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS -I../.. \{\} \;
gcc $CFLAGS shape-simd.c
cd ../../..

gdc -o Mu-cade -s -Wl,--gc-sections -static-libphobos import/*.o* import/ode/*.o* import/sdl/*.o* import/bindbc/sdl/*.o* src/abagames/util/*.o* src/abagames/util/bulletml/*.o* src/abagames/util/ode/*.o* src/abagames/util/sdl/*.o* src/abagames/mcd/*.o* -lGLU -lGL -lSDL2_mixer -lSDL2 -lbulletml_d -lode -L./lib/armhf
