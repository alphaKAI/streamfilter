module StreamFilter.Filter;

import StreamFilter.ColorUtils;

import std.stdio,
       std.regex,
       std.conv;

class Filter {
  // Avoiding duplication of option(automatically change option)
  private int[string][OptionType] usedCounter;
  private string[string][][Regex!char] conversionTable;
  public static immutable string[] colors = ["red", "yellow", "green", "magenta", "bulue", "cyan", "white"];
  public static immutable string[] textAttrs = ["bold", "underscore", "reverseVideo"];
  private ColorUtils colorUtils;


  /*
    _table form:
      [
        "filter1": [
          [
            "type":"0",
           "option":"bold"
          ],
          [
            "type":"1",
            "option":"red"
          ]
        ],
        "filter2": [
          [
            "type":"1",
            "option":"red"
          ]
        ]
      ]
   */

  this(string[string][][string] _table) {
    foreach (color; colors) {
      usedCounter[OptionType.fg][color] = 0;
      usedCounter[OptionType.bg][color] = 0;
    }
    
    foreach (textAttr; textAttrs) {
      usedCounter[OptionType.text][textAttr] = 0;
    }

    foreach (k, v; _table) {
      if (v !is []) {
        conversionTable[regex(k)] = [];
        bool used;
        foreach (v2; v) {
          if ("option" in v2 && "type" in v2) {
            if (usedCounter[v2["type"].to!int.to!OptionType][v2["option"]]) {
              used = true;
            }

            conversionTable[regex(k)] ~= [
              "type"   : v2["type"],
              "option" : v2["option"],
              "string" : k
            ];

            usedCounter[v2["type"].to!int.to!OptionType][v2["option"]]++;
          } else {
            OptionType colorType;
            string color;
            bool foundAvailable;

            foreach (optionType; [OptionType.fg, OptionType.bg]) {
              foreach (_color; colors) {
                if (usedCounter[optionType][_color] == 0) {
                  colorType  = optionType;
                  color = _color;

                  usedCounter[colorType][color] = 1;
                  foundAvailable = true;
                }
              }

              if (foundAvailable) {
                break;
              }
            }

            if (foundAvailable) {
              conversionTable[regex(k)] ~= [
                "type"   : colorType.to!int.to!string,
                "option" : color,
                "string" : k
              ];
            } else {
              // Failed to avoid duplication; TODO: automatically detect another combination(Ex: bold and red(fg)...)
              conversionTable[regex(k)] ~= [
                "type"   : "1",
                "option" : "red",
                "string" : k
              ];

              conversionTable[regex(k)] ~= [
                "type"   : "0",
                "option" : "bold",
                "string" : k
              ];
            }
          }
        }
      } else {
        conversionTable[regex(k)] ~= [
          "type"   : "1",
          "option" : "red",
          "string" : k
        ];
      }
    }

    colorUtils = new ColorUtils;
  }

  void filter() {
    foreach (output; stdin.byLine) {
      if (stdin.eof) return;
      foreach (key, value; conversionTable) {
        if (output.matchAll(key)) {
          foreach (matched; output.matchAll(key)) {
            foreach (table; value) {
              OptionType type = table["type"].to!int.to!OptionType;
              string option   = table["option"];

              string modifiedString = colorUtils.addOption(type, matched[0].to!string, option);
              output = output.replaceAll(regex( matched[0].to!string), modifiedString);

            }
          }
        }
      }

      stdout.writeln(output);
    }
  }
}
