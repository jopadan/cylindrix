# cylindrix makefile

PLATFORM = $(shell uname)
DEBUG = false

OBJ = build/ai.o build/ai_move.o build/ai_util.o build/base.o build/clipping.o build/collide.o build/commands.o \
	build/config.o build/do_state.o build/energy.o build/events.o build/explode.o build/fli.o build/fx.o build/gameloop.o \
	build/hud.o build/jonsb.o build/keys.o build/level.o build/main.o build/menu.o build/motor.o \
	build/movement.o build/object.o build/omega.o build/path.o build/pcx.o build/prim.o build/project.o build/pylon.o \
	build/radar.o build/states.o build/stats.o build/stub.o build/tanks.o build/text.o \
	build/util.o build/voices.o build/system.o build/sound.o

# libyaml is used for parsing config files
YAML_OBJ = build/libyaml/api.o build/libyaml/dumper.o build/libyaml/emitter.o \
	build/libyaml/loader.o build/libyaml/parser.o build/libyaml/reader.o \
	build/libyaml/scanner.o build/libyaml/writer.o

OPT_FLAG = -O3

# SDL Mac OS X
ifeq ($(PLATFORM),Darwin)
OBJ += build/glcylindrix.o
GCC = llvm-g++
CFLAGS = -Wall -D GLCYLINDRIX -D DARWIN `sdl-config --cflags` -Ilibyaml/include -Ilibyaml
LFLAGS = -framework Cocoa -framework OpenGL -framework GLUT -framework OpenAL -lstdc++ -lmpg123 `sdl-config --libs`
TARGET = cylindrix
endif

# SDL Linux
ifeq ($(PLATFORM),Linux)
OBJ += build/glcylindrix.o
GCC = g++
CFLAGS = -Wall -D GLCYLINDRIX
LFLAGS = -lGL -lGLU -lSDL -lc -lmpg123 -lopenal -lyaml
TARGET = cylindrix
YAML_OBJ =
endif

# SDL Microsoft Windows using MINGW
ifeq ($(PLATFORM),MinGW)
OBJ += build/glcylindrix.o
GCC = g++
CFLAGS = -Wall -D GLCYLINDRIX -I/msys/1.0/include -I/msys/1.0/local/include -I/code/OpenAL-1.1/include
LFLAGS = -lmingw32 -lSDLmain -lSDL -lOpenGL32 -lGlu32 -lmpg123 -lopenal32 -L/msys/1.0/lib -L/msys/1.0/local/lib -L/code/OpenAL-1.1/libs/Win32
TARGET = cylindrix
endif

# Browser build using emscripten
ifeq ($(PLATFORM),Browser)
OBJ += build/glescylindrix.o
GCC = ~/code/emscripten/emcc
CFLAGS = -Wall -D GLCYLINDRIX -D BROWSER -D USE_ABACI_NAMESPACE -Ilibyaml/include -Ilibyaml -Iabaci/src
LFLAGS = -lGL -lGLU -lSDL -lc -lyaml
LFLAGS += --embed-file 3d_data/ --embed-file pcx_data/ --embed-file gamedata --embed-file people.dat --embed-file FLI/CYLINDRX.FLI -O2
TARGET = cylindrix.html
OPT_FLAG =
endif

# debug symbols
ifeq ($(DEBUG),true)
CFLAGS += -g
else
CFLAGS += $(OPT_FLAG)
endif


# Link with SDLMain when on MacOSX
ifeq ($(PLATFORM),Darwin)
OBJ += build/SDLMain.o
endif

# TODO: fix dependencies
DEPENDS = src/ai.h src/ai_move.h src/ai_util.h src/base.h src/clipping.h src/collide.h src/commands.h \
	src/config.h src/do_state.h src/energy.h src/events.h src/explode.h src/fli.h src/fx.h src/gameloop.h \
	src/glcylindrix.h src/hud.h src/jonsb.h src/keys.h src/level.h src/main.h src/menu.h src/motor.h \
	src/movement.h src/object.h src/omega.h src/path.h src/pcx.h src/prim.h src/project.h src/pylon.h \
	src/radar.h src/serial.h src/states.h src/stats.h src/stub.h src/tanks.h src/text.h src/types.h \
	src/util.h src/voices.h src/system/system.h

$(TARGET): $(OBJ) $(YAML_OBJ) rmtarget
	$(GCC) $(OBJ) $(YAML_OBJ) -o $(TARGET) $(LFLAGS)

rmtarget:
	rm -f $(TARGET)

build/%.o : src/%.cpp
	$(GCC) $(CFLAGS) -c $< -o $@

build/libyaml/%.o : libyaml/src/%.c
	$(GCC) $(CFLAGS) -x c -c $< -o $@

$(OBJ) : $(DEPENDS) build/temp.txt

build/temp.txt:
	mkdir build
	mkdir build/libyaml
	touch build/temp.txt

# SDL system files
build/system.o: src/system/sdl/system.cpp $(DEPENDS)
	$(GCC) $(CFLAGS) -c $< -o $@

ifeq ($(PLATFORM),Browser)
# no sound
build/sound.o : src/system/glut/sound.cpp $(DEPENDS)
	$(GCC) $(CFLAGS) -c $< -o $@
else
# OpenAL sound
build/sound.o : src/system/openal/sound.cpp $(DEPENDS)
	$(GCC) $(CFLAGS) -c $< -o $@
endif

# Mac OS X system files
ifeq ($(PLATFORM),Darwin)
build/SDLMain.o : src/system/darwin/SDLMain.m $(DEPENDS)
	$(GCC) $(CFLAGS) -c $< -o $@
endif

.PHONY : clean tags
clean :
	rm -rf build

tags :
	etags `find . -name "*.cpp" -o -name "*.h"`