# Changelog
All notable changes will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3]

### Added
- on-Screen Log Traces;
- More Customization with Notesplashes;
- Custom Titlescreen values (BPM, BG Sprite, etc);
- New Placeholder Character (thanks @SuokArts3);
- Flashing Lights warning;
- Event Lines on the Chart Editor;
- Special Animations per Note;


### Fixed
- Packer Atlas files (means that Spirit-like Characters now work);
- Majority of Crashes with Scripts;


### Adjusted
- Changed the Engine save data path;
- Reworked the Credits Menu (thanks @Cherif107);


### Removed
- Custom Language Support
* this was really not needed (for an engine) and made my work harder.


## [0.2.3]

### Added
- (re) Added Crash Dialogue from Forever Engine Legacy (written be sqirra-rng);
- Dynamic Sustain Note Sizes (thanks Yoshubs for letting me borrow your scripts);
- Custom Language Support;
- Automatic Gamepad Detection (by: Stilic);
- Newer Runtime Shader Support (by: MasterEric);
* this basically means psych engine shaders now work


### Fixed
- Note Hold Offsets;
- Infinite Beeping Sound when increasing or decreasing your volume;
* additionally, the beeping sound was replaced with a menu scroll sound (because the default one is annoying lol)

### Adjusted
- Strumlines now have individual cameras, allowing for them to be manipulated individually;
- Freeplay now displays Accuracy and Ranking;
* Additionally, you can also Reset your Score, Accuracy and Ranking on Freeplay by pressing R;
- Player Positions on Stages now use a JSON File;
- Characters now have a `noteHit` function on their scripts, it is executed everytime they hit a note;
- Menus should now be overall faster;


### Removed
- Menu Scripts;


## [0.2.2]

### Added
- a Console for source / script debug traces, press F10 on any screen to enable / disable it, make sure `Allow Console Window` is enabled on preferences in order for it to work;
- `import` can now be used on Scripts (make sure to update your SScript Libraries!!);
- Customizable Judgement / Combo Positions;
- Custom Main Menu Scripts, more information the `docs` folder;
- a "Prepare" sprite for the "Three" sound clip during the countdown sequence;
- You can now have a Dark Background for notes by using the `Opacity Type` option;
- the Original Chart Editor now has a metronome, can help with BPM Syncing;
- Substates can now be created with scripts, refer to the `ExampleSubstate.hx` file inside the `docs` folder;
- Notesplashes are now attached to Noteskins and can be fully customized using the new `splashData.json` file;
- Re-added "Simply Judgements", with a new name, "Judgement Stacking";
- Re-added "hxs" extension for older script support;


### Fixed
- Old Psych Engine Charts (0.4 or prior) should no longer cause a crash;
- Story Mode Menu will now properly show difficulty selectors;
- Girlfriend will no longer spawn twice on Tutorial;
- Non-Pixel Dialogues should now be fully working;
- Receptors should now have their "confirm" animations looped for autoplay;
- Accuracy will no longer go over 100%;
- Health Icons will no longer crash the game if the Character's icon doesn't exist;
- Transitions should no longer skip themselves if you leave a song during story mode;


### Adjusted
- General stability improvemets;
- Receptors are now properly centered;
- Icon animations are now much simpler;
- Combo Breaks are now shown even if you have your Accuracy disabled on Options;
- Scripts now give you output on what went wrong in the event of an error;
- Stages are fully Softcoded and can be used as examples for animated backgrounds and such;
- Judgements and Combo are now recycled sprites, meaning that they won't increase memory once you hit a note;
- Scripts are now fully based on HaxeFlixel, rather than having a bunch of functions for them;
- Engine Watermark can now be disabled from gameplay;
- Controls should now be properly formatted along with bold numbers and symbols having correct offsets;


## DOWN BELOW THERE ARE VERY OUTDATED CHANGES THAT ARE NO LONGER TRUE / WERE CHANGED WITH TIME;

## [0.2.1.1]

### Added
- Full Video Support (with PolybiusProxy's hxCodec extension, we are currently using the stable version);
- Menu Items are now separated on their own unique spritesheets, allowing for easier setup;
- Judgements are now separated on their own unique images;
- `noteMissActions` function for Notetypes;
- New Chart Editor now has infinite scrolling;
- You can now select Characters and Ghost Characters on the Character Debug Menu;
- Engine Watermarks are now displayed on the FPS and can be disabled;
- Both Chart Editors now have Playback Rates, press CTRL+Z to increase speed, CTRL+X to decrease, and CTRL+C to reset;
- The Score Bar now (optionally) flashes depending on your last gotten judgement;
- You can now Change the Song's Difficulty using the Pause Menu;
- Charts made in Psych Engine v0.6 should now work properly;
- Scripts can now specify variable types, things like `function goodNoteHit(coolNote:Note)` shouldn't crash anymore;
- Fully Softcoded Weeks via JSON files;
- Tweens can now be customized on scripts, example use: `doTween('scoreZoom', 'scale.x', hud.scoreBar, 1, 0.2);`, with `scale.x` being the custom value;


### Fixed
- Characters with dancing idles (think gf or skid and pump) will no longer loop on their last animation;
- Antialiasing now works properly for Stages and Menus;
- the BPM Limit was increased to 350 on the Chart Editor;
- Stutters when Pausing shouldn't happen anymore;
- Notetypes should be properly working now;


### Adjusted
- you can now specify character offsets on their script file;
- script files now have the extension `hx`, allowing for VSCode extensions to be properly used with it;
- Credits Menu was completely rewritten, meaning that both the code for it and the json file are different;
- You can now mess with Accuracy and ranking values on scripts using `accuracy`, `trueAccuracy`, `ratingFinal` and `comboRating`;
* there's also the formatted counterparts for making custom score texts, `formattedAccuracy` and `formattedRanking`;
- `Hits` variable for Scripts, returns all your hits on the current song;


## [0.2.1]

### Added
- Notetypes were rewritten as an integer, they should properly save on songs now;
- New Accessibility Options (Notesplash Opacity, Arrow Opacity);
- You can optionally enable a commit hash, mostly something made for bug reporting on the base repository and such;
- Song Metadata will now be injected via a separated file named `meta.json` on your Song's Folder;
- with the Metadata change, you can now add colors to your songs as an RGB format;
- Shaders can now be called via Scripts;
- you can now have Animated Icons via Sparrow Atlas (XML);
- Campaign UI Characters are now separated into Folders and fully Softcoded via JSON Files;
- Dialogues can now use Text Files, meaning that you are no longer limited to just using the Hardcoded `Alphabet.hx` for them;
- Scripted Tweens can now have a `onComplete` function by calling `completeTween(tweenID)` on a script;
- Strumlines can now be moved freely, allowing for **Modcharts** to be made (still planning to make it easier though!);


### Fixed
- Newgrounds Logo now shows up on Title Screen
- Winter Horrorland now has a proper Background;
- Week 6 is completely Fixed;


### Adjusted
- Scripts now use the "hx" file extension, allowing for Haxe Extensions to be used;
- All Menus (excluding Story and Options) now have persistent variables for the item you are currently highlighting;
- Song Information is now available on the `ChartParser.hx` file, rather than being separated by both `Song.hx` and `Section.hx`;
- `Conductor.hx` now handles Song Playback;
- Improved Notetype Handling, Notetypes can now be fully set up on `Note.hx`;
- The Codebase has been entirely formatted (thanks @otallynotdoggogit);
- The `README.md` file has been entirely rewritten (thanks @otallynotdoggogit);

----------------------------------------------