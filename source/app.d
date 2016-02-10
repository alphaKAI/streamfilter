import StreamFilter.Filter,
       StreamFilter.ColorUtils;
import std.algorithm.searching,
       std.getopt,
       std.string,
       std.regex,
       std.conv;

void main(string[] args) {
  string[string][][string] table;
  string   opRegex;
  string[] opRegexs;
  Filter filter;

  arraySep = ",";
  auto helpInformation = getopt(
        args,
        "regex|r", &opRegex,
        "regexs|s", &opRegexs
      );

  if (helpInformation.helpWanted) {
    defaultGetoptPrinter("StreamFilter - Filtering stdout stream. Copyright 2016 alphaKAI", helpInformation.options);

    return;
  }

  void addRule(string line) {
    if (line.match("=")) {
      string[] params  = line.split("=");
      string target    = params[0];
      string[] options = params[1].split(",");

      foreach (_option; options) {
        string typeString;
        string option;
        OptionType type;

        if (_option.match("-")) {
          typeString = _option.split("-")[0];
          option     = _option.split("-")[1];

          if (typeString.matchAll(regex("t|text"))) {
            type = OptionType.text;
          } else if (typeString.matchAll(regex("f|fg"))) {
            type = OptionType.fg;
          } else if (typeString.matchAll(regex("b|bg"))) {
            type = OptionType.bg;
          }
        } else {
          //No order for type
          bool isColor;

          foreach (color; Filter.colors) {
            if (Filter.colors.canFind(_option)) {
              option  = _option;
              isColor = true;
              type    = OptionType.fg; //TODO: automatically change if this color is already used.
              break;
            }
          }

          if (isColor is false) {
            type = OptionType.text;
            option = "bold";
          }
        }

        table[target] ~= [
          "type"   : type.to!int.to!string,
          "option" : option 
        ];
      }
    } else {
      // Ordered only pattern -> default
      table[line] = [];
    }
  }

  if (opRegex !is null) {
    addRule(opRegex);
  }
  
  import std.stdio;

  if (opRegexs !is null) {
    string[] lines;
    string[] stack;
    size_t idx;
    bool flag;

    foreach (string element; opRegexs) {
      if (element.match(regex("="))) {
        if (flag is true) {
          lines ~= stack.join(",");
          flag  = false;
          stack = [];
        }
          flag = true;
          stack ~= element;
        
      } else if(flag) {
        stack ~= element;
      }
    }

    if (lines is []) {
      lines = opRegexs;
    } else {
      lines ~= stack.join(",");
    }

    foreach (rule; lines) {
      addRule(rule);
    }
  }

  filter = new Filter(table);
  filter.filter;
}
