# demoslides

If you're working in a company with agile processes, chances are you have a demo or review every once in a while to present the things you worked on to members of other teams. `demoslides` gets the issues of the current sprint in JIRA for a project and puts them on slides in a PDF so you don't have to create a presentation manually.

## Installation
demoslides requires macOS 10.2 with Swift 5 installed. The following clones the repository, builds the release version and creates a symbolic link from your binaries to the built executable.

```
git clone https://github.com/sebastianpixel/demoslides.git \
&& cd demoslides \
&& swift build -c release \
&& ln -s `pwd`/.build/release/demoslides /usr/local/bin/demoslides
```

You can then execute the tool via `demoslides`. If there is no configuration file in the directory in which you're running the tool, the file `demoslides.yml` will be created. For this you need to provide the host of your JIRA server (like "jira.mycompany.com") and select the JIRA project for which you'd like to create demo slides.

## Configuration
The tool is based on the assumption that you categorize your JIRA issues by fixVersions and epics. FixVersions can optionally be mapped to emoji (like when you use the fixVersions "iOS" => "🍏" or "Android" => "🤖"). If there is no mapping the default is to just print the fixVersion.

The issues can also be mapped to "categories" if you want to bundle multiple epics to one like "Infrastructure", "Design" or "Analytics". When the config file is created at first a category is created for each epic. You can change this  by collecting multiple epics under the `epics` key of one category in `demoslides.yml`. If an issue has no epic link it will be mapped to the default category "Feature".

The options to set in the config are:

* textResouces: naming of the "aim" part of the ticket (omitted if empty)
* fixVersionEmojis: the mapping of fixVersion strings to emojis
* descriptionPatterns: regex patterns for the relevant part in the issue description to use in the PDF
* descriptionLinesMax: how many lines should appear on the PDF (font size is shrinked if the set size would cause the text to be clipped)
* insets: the paddings of the colored area and the text areas (each has additional paddings set in fontSettings)
* fontSettings: font name, size and paddings for each text
* issuesPerPage: how many issues should be printed on one page
* limitToPrintableArea: if set the content will only fill the area the current default printer can print on
* categories: the list of issue categories with their color and associated epics

If the config file exits, running `demoslides` will create the PDF right away and open it.

The credentials for JIRA are saved in keychain and can be reset by running `demoslides --reset-login`

The help description is available via `demoslides --help`.
