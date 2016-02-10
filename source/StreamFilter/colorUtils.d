module StreamFilter.ColorUtils;

import std.regex,
       std.conv;

immutable throwErrorWhenExecptionOccur = false; // for debug

static enum OptionType : int {
  text,
  fg,
  bg
}

class ColorUtils {
  private int[string][int] options;
  private immutable optionPrefix = "\x1B[";
  private immutable optionSuffix = "m";
  
  this() {
    options = [
      OptionType.text :[
        "off"          : 0,
        "bold"         : 1,
        "underscore"   : 4,
        "blink"        : 5,
        "reverseVideo" : 7,
        "concealed"    : 8
      ],
      OptionType.fg : [
        "black"   : 30,
        "red"     : 31,
        "green"   : 32,
        "yellow"  : 33,
        "blue"    : 34,
        "magenta" : 35,
        "cyan"    : 36,
        "white"   : 37
      ],
      OptionType.bg :[
        "black"   : 40,
        "red"     : 41,
        "green"   : 42,
        "yellow"  : 43,
        "blue"    : 44,
        "magenta" : 45,
        "cyan"    : 46,
        "white"   : 47]
      ];
  }

  @property private bool checkOption(OptionType type, string option) {
    return option in options[type] ? true : false;
  }

  public string addOption(OptionType type, string base, string option) {
    string modifiedString;
    bool hasOffOption;

    if (checkOption(type, option) is false) {
      if (throwErrorWhenExecptionOccur) {
        throw new Error("Not exist such a color or option");
      } else {
        // Nothing to do.
        return base;
      }
    }

    if (base.match(regex(r"\x1B\[" ~ options[OptionType.text]["off"].to!string ~ optionSuffix))) {
      hasOffOption = true;
    }

    modifiedString = optionPrefix ~ options[type][option].to!string ~ optionSuffix ~ base;

    if (hasOffOption is false) {
      modifiedString ~= optionPrefix ~ options[OptionType.text]["off"].to!string ~ optionSuffix;
    }

    return modifiedString;
  }

  import std.stdio,
         std.string;
  public string removeAllOption(string base) {
    return base.replaceAll(regex(r"\x1B\[\d+m"), "");
  }
}
