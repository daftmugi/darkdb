# DarkDB.rb

**DarkDB.rb** is a command-line mission data reader/writer for Dark
Engine games, Thief 1/Gold/2 and System Shock 2. This includes `.mis`
and `.sav` files.

**DarkDB.rb** exists to allow players and mission authors to edit
mission parameters as they wish.

Using DromEd to edit the mission data tables, such as Mission Quest
Data, works, of course. But DromEd can introduce or change more
mission data than just the desired values. Perhaps that won't cause
issues, but that's unknown, especially without play testing.

Therefore, this program only changes the desired mission values and
keeps the rest of the mission data untouched so that it matches what
the original mission author intended.

**NOTE:** Mission values can only be edited. Values cannot be added or removed.


## Features

* Operations
    - List all key-value pairs of a DarkDB table.
    - Get DarkDB table key-value pairs by key.
    - Set DarkDB table values.
* Supported Tables
    - DromEd Info Window Data (`BRHEAD`)
    - Mission Quest Data (`QUEST_DB`)
    - Campaign Quest Data (`QUEST_CMP`)


## Requirements

* [Ruby 3.0+](https://www.ruby-lang.org/en/downloads/)
* Linux
    - Ubuntu: `apt install ruby`
* Windows
    - [RubyInstaller](https://rubyinstaller.org/downloads/) 3.0 builds are known to work.
        + [Ruby+Devkit 3.0.6-1 (x64)](https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.0.6-1/rubyinstaller-devkit-3.0.6-1-x64.exe)
        + [Ruby 3.0.6-1 (x64)](https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.0.6-1/rubyinstaller-3.0.6-1-x64.exe)
    - "MSYS2 development toolchain" is not required.
    - "ridk install" is not required.
    - **NOTE:** As of this writing, RubyInstaller 3.1 and 3.2 builds are not compatible,
      since the program may not run due to an error with the message
      ["unexpected ucrtbase.dll"](https://github.com/oneclick/rubyinstaller2/issues/308).


## Installation

* `darkdb` is in the `bin/` directory.
* Use `darkdb` as is or copy it somewhere included in the `PATH`.
* **NOTE:** `darkdb` can be renamed to something else if desired.
* **NOTE:** Windows users may need to prepend `ruby` to `darkdb` to
  run it. For example, `ruby darkdb`.


## Usage

`USAGE_BLOCK`


## Example: Editing Loot Goals

1. Find an FM that you would like to change.
2. Find its mission file, such as `miss20.mis`.
3. (Optional) List loot goals:
   ```
   darkdb questdb miss20.mis loot
   ```
4. Set all loot goals to `500`:
   ```
   darkdb questdb miss20.mis loot 500
   ```
5. (Optional) Find the objectives text file (`goals.str`) and change its
   loot values to match the edited `miss20.mis` file. The `goals.str` file
   is likely at:
   ```
   <thief>/FMs/<fm_name>/intrface/miss20/english/goals.str
   ```
   The reason to edit the `goals.str` file is to make the in-game
   objective screen match the changed loot goals. The edited mission
   loot goals will work regardless of what the objective screen shows.


## Example: Editing Map Screen Pages

In this example, a note page will be added to a mission that does not
have a note page. Some missions only have maps on the map screen
whereas others also include a note page on the map screen. Thief
1/Gold original missions do not have note pages. Note pages on the map
screen were introduced in Thief 2.

First, find a note page from the Thief 2 resource files that you would
like to use. Or, find one that you like from a Thief FM.

Here are some example locations of Thief 2 note page image files:

* `<t2>/intrface/miss1/english/PAGE000.PCX`
* `<t2>/intrface/miss2/english/PAGE005.PCX`
* `<t2>/intrface/miss15/english/PAGE000.PCX`

These note pages are in the `intrface.crf` file. Use a ZIP program to
extract one of those files from the CRF file.

1. Find an FM that you would like to change.
2. Find its mission file, such as `miss20.mis`.
3. (Optional) List the pages defined in the mission file:
   ```
   darkdb questdb miss20.mis page
   ```
4. Let's say the `map_min_page` is `1` and the `map_max_page` is
   `2`. Set `map_min_page` to `0`:
   ```
   darkdb questdb miss20.mis map_min_page 0
   ```

   **NOTE:** Instead of page `0`, the new page can be added as page `3`.
   In that case, set `map_max_page` to `3`.
5. Add the missing page `0` image file. Copy a note image file to:
   ```
   <thief>/FMs/<fm_name>/intrface/miss20/page000.<image_extension>
   ```

   **NOTE:** Page files usually have an image extension of `pcx` or
   `png`, so `page000.<image_extension>` would be `page000.pcx` or
   `page000.png` given `pcx` or `png`.

**NOTE:** Some missions may change `map_min_page` or `map_max_page`
values during gameplay, making additional pages available. So,
changing these values may conflict with or mess up the script that
runs during gameplay to update the min and max pages. For example, the
`map_min_page` may be `1` and the `map_max_page` may be `2` in the
mission (`.mis`) file, but in the mission
`intrface/<miss_name>/english` directory, there are files:
`page001.png`, `page002.png`, `page003.png`, and `page004.png`. That's
a good clue that the mission will increase `map_max_page` to `4`
during gameplay. These changed values will only be in the save
(`.sav`) file. Therefore, some experimentation may be needed to verify
that the `map_min_page` or `map_max_page` can be changed without issue.


## Thanks

Thanks to the work of Tom N Harris and his [Python scripts and DarkLib](https://whoopdedo.org/projects.php?dark),
which I referenced for this project.
