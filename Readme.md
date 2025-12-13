# Zig Roguelike Tutorial

By Martin Lehner ([@anotherlehner](https://github.com/anotherlehner))

12/2025: I have restarted this project this year with the hope of finally finishing a full implementation of the tutorial using libtcod and the latest version of Zig! So far I have fixed all the parts so they once again build on linux and osx and should run without major issues.

## Intro

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

## Parts

[Repository](https://github.com/anotherlehner/zig-roguelike)

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

The roguelike tutorial in python
https://rogueliketutorials.com/tutorials/tcod/v2/

Roguelike dev subreddit
https://www.reddit.com/r/roguelikedev/

## History

Note: I started this project in 2022 using a different username on gitlab.com (clockworkmartian) and have since come back to github and reclaimed my old anotherlehner account.

_AI disclaimer: None of the code in this repository was written with generative AI or LLMs. I do consult Gemini, ChatGPT, or whatever for finding documentation and helping solve a problem but I never copy and paste that code here. This is a personal project on my own time and as such I want to understand as much as possible about what I'm doing, how it feels to write code in Zig, and experiencing all parts of the process. This also includes my own tutorial narrative text, which is solely written by myself with no input from AI._