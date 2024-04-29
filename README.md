# godot-src

Welcome to ``godot-src``!  The intent of this project is 3 things:

1. Make compiling godot from source easy.
2. Make cross compiling godot from any desktop platform to any supported godot platform easy.
3. Provide a suite of tools to increase efficiency when working on godot from source.

How are we going to accomplish this?

Reduce system dependencies.

I don't think we will be able to get this to 0, but I think we can get pretty close.  Currently the cross compilation logic is being driven by [nushell](https://www.nushell.sh/) scripts.  You will see that there are also some bash scripts using ``zig cc``, ``zig c++``, and other ``zig [compiler-tool]`` throughout the scripts to comile different platforms and map cli args to the ``zig`` equivalent.

Progress has already been made by eliminating the llvm and mingw dependencies via zig's drop in compiler :)

However, with these goals listed, this project currently still requires a significant amount of system dependencies.  So lets get started with those:

## Godot

First we must install the dependencies as documented by godot: https://docs.godotengine.org/en/stable/contributing/development/compiling/index.html

1. python3.6+
2. scons
3. make

Fortunately for linux users, we have distro specific oneliners here: https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_linuxbsd.html#distro-specific-one-liners

^ Note we shouildn't need the gcc, g++, and ming tools anymore.  I'm not sure about the mesa-dev and libx11-dev libs since we are also pulling those in from source now.  I need to test without those.  We don't even need nushell installed!  Running ``gsrc.sh`` will run some brief native programs such as wget or curl to download it to the ``gitignore/nu`` relative to this repo directory folder.  Then it will forward cli args passed to ``gsrc.sh`` to ``gsrc.nu``.

TODO: Create a ``.bat`` and / or ``.ps1`` script for a native windows entrypoint.

## Rust

1. To build the rust example in the project, you can install rust from here: https://www.rust-lang.org/tools/install
2. To build to windows, install cargo-xwin: https://github.com/rust-cross/cargo-xwin
    - I'd like to use zig for this, but I was having trouble targeting msvc with rust and zig.

## Zig

1. This part is automated! :)  It will grab the zig version last tested against this repo unless a custom zig env var is passed.
2. TODO: Document that env var.


# Testing it all out

Now that we've done that, we should be able to try out compiling for linux and windows!  Currently this has only been tested on Linux.  Windows support is comping soon.

### Build Godot

Make sure to clone this repo :)

```
git clone https://github.com/Lange-Studios/godot-src.git
```

Then you can build:

```
./gsrc.sh godot build editor # This will build the godot editor for your host platform
```

You should then see the godot version for your target platform under [gitignore/godot/bin](gitignore/godot/bin)

### Example Projects

NOTE: These were created before nushell.  They are being ported from bash to nushell and may not even work at the moment.

Build the hello world project:
```
./hello_world/export-linux-debug.sh
./hello_world/export-windows-debug.sh
```

Build the hello world rust project:
```
./hello_world_rust/export-linux-debug.sh
./hello_world_rust/export-windows-debug.sh
```

Then you should see the outputs in [examples/gitignore/hello_world/bin](examples/gitignore/hello_world_rust/bin) and [examples/gitignore/hello_world_rust/bin](examples/gitignore/hello_world_rust/bin)

## Current Status

Currently only building from linux is supported with windows and mac coming very soon.  Here is an initial draft of the platform plan chart:

Column = host platform
Row = target platform

✅ = supported
❌ = not supported

|                 | Linux Host | Windows Host | Mac Host |
|-----------------|------------|--------------|----------|
| Linux           | ✅         | ❌           | ❌       |
| Windows Desktop | ✅         | ❌           | ❌       |
| Mac             | ❌         | ❌           | ✅       |
| Android         | ✅         | ❌           | ❌       |
| iOS             | ❌         | ❌           | ✅       |
| Steam Deck      | ❌         | ❌           | ❌       |
| Switch          | ❌         | ❌           | ❌       |
| XBox            | ❌         | ❌           | ❌       |
| PlayStation     | ❌         | ❌           | ❌       |

The goal is to make as many of these as green as possible while maintaining compliance with licensing and NDAs