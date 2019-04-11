# tetris-love
 ![tetris-love logo][logo]

Guideline Tetris for Love2D

## Another Tetris clone?

Yes, but this one is based on the Guideline, so it has:

+ Super Rotation System (SRS)
+ Hold
+ Marathon, Sprint and Ultra
+ Consistent Tetrimino colors
+ Guideline timings

I designed this game to figure out how Guideline Tetris worked.

## How to play

1. First, [download Love2D](https://love2d.org). 
tetris-love is built on Love 11.2, but does work with versions 0.9.1 and up.

2. Clone the repository.
You can use the Download as ZIP button above. Then rename the extension from `.zip` to `.love`.

**OR**

From the command line:
```bash
git clone https://github.com/nununoisy/tetris-love
```

3. Now launch Love2D - either drag `tetris-love.love` onto `love.exe` or execute `love /path/to/tetris-love`

## Themes

You are free to replace the graphics contained within the `images/` subdirectory to create a custom theme.

## Contributing

Please maintain the code style. PRs are welcome.

This still needs some more stuff, like:
- [ ] 15-rotation limit for SRS on the ground
- [ ] Directions/control layout
- [ ] Button remapping
- [ ] More SFX/music

... and there's probably more stuff missing.

## Credits

+ kikito for [love-loader](https://github.com/kikito/love-loader)
+ itraykov for [profile.lua](https://bitbucket.org/itraykov/profile.lua/) (used during development)
+ MIDIArchive.co.uk for the original [Korobeiniki MIDI file](https://midiarchive.co.uk/midi/Games/Tetris)

[logo]: https://github.com/adam-p/markdown-here/raw/master/images/tetris-love-logo.png "tetris-love"