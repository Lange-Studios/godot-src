These are different scripts for building different variations of godot!

1. ``godot-build.sh`` - builds the godot editor for the host machine's OS.  The export scripts depend on this one being already run and the godot editor binary cached.
2. ``godot-build-[platform]-template.sh`` - builds a stripped down version of godot that will ship as the application's binary when exported.
3. ``godot-export-[platform].sh`` - exports the godot project and wraps it into the stripped down template.
4. ``godot-env.sh`` - returns commond env vars used when executing these scripts
5. ``godot-clean-dotnet.sh`` - I'm not aware of a current way to rebuild and cache multiple dotnet platforms for godot.  So currently just cleaning and rebuilding for every target is the solution.  You can pass ``--skip-cs`` to any of the above scripts to prevent the cleaning and rebuilding.  Fortunately it doesn't seem to take too long to build.