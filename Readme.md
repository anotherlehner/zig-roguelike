# Zig Rogulike Tutorial 2022

Each folder in this repository contains the full code to a part of the roguelike tutorial translated for Zig.

_Disclaimer: This is my first Zig project so please do not consider anything here as idiomatic or a demonstration of how Zig programs should be written. This is simply a fun project to explore, try Zig out, and see how it feels. Consider it an anecdata point._

To create this project the following commands were executed:

```
mkdir zig-roguelike
cd zig-roguelike/
git init
```

The .gitignore file was setup with some initial folders. We want to ignore the zig cache and build folders so they're not committed to git.

```
zig-out/
zig-cache/
```

See each part folder for a readme explanation of how that part was written, what issues I encountered, how I solved problems, and what I was thinking.

Enjoy!

# Parts

To run each part cd into the folder and execute `zig build run`. To do this make sure you've installed the libtcod headers and the library itself, along with SDL2, on your system -- see part-0 for some details on that.

[Part-0](part-0)

[Part-1](part-1)

[Part-2](part-2)

[Part-3](part-3)

[Part-4](part-4)

[Part-5](part-5)

[Part-6](part-6)

[Part-7](part-7)

# Links

The Roguelike Tutorials
https://rogueliketutorials.com/

Roguelike dev subreddit
https://www.reddit.com/r/roguelikedev/
