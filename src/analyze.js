// Generated by CoffeeScript 1.6.3
var Analyzer;

Analyzer = (function() {
  function Analyzer(language) {
    var current, i, person, rule, verb, _i, _len, _ref;
    this.matrix = [];
    i = 0;
    while (i < 64) {
      this.matrix[i] = [i];
      this.matrix[i].length = 64;
      i++;
    }
    i = 0;
    while (i < 64) {
      this.matrix[0][i] = i;
      i++;
    }
    this.levenshteinDistance = function(__this, that, limit) {
      var cost, j, min, t, thatLength, that_j, thisLength, this_i;
      thisLength = __this.length;
      thatLength = that.length;
      if (Math.abs(thisLength - thatLength) > (limit || 32)) {
        return limit || 32;
      }
      if (thisLength === 0) {
        return thatLength;
      }
      if (thatLength === 0) {
        return thisLength;
      }
      i = 1;
      while (i <= thisLength) {
        this_i = __this[i - 1];
        j = 1;
        while (j <= thatLength) {
          if (i === j && this.matrix[i][j] > 4) {
            return thisLength;
          }
          that_j = that[j - 1];
          cost = (this_i === that_j ? 0 : 1);
          min = this.matrix[i - 1][j] + 1;
          if ((t = this.matrix[i][j - 1] + 1) < min) {
            min = t;
          }
          if ((t = this.matrix[i - 1][j - 1] + cost) < min) {
            min = t;
          }
          this.matrix[i][j] = min;
          ++j;
        }
      }
      ++i;
      return this.matrix[thisLength][thatLength];
    };
    this.persons = ['1sg', '2sg', '3sg', '1pl', '2pl', '3pl'];
    this.markers = [];
    verb = language.inflections['VERB'];
    _ref = this.persons;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      person = _ref[_i];
      current = verb[person];
      console.log(current);
      this.markers[person] = [];
      if (!current['default']) {
        this.markers[person] = this.replace(current);
      } else {
        for (rule in current) {
          this.markers[person] = this.markers[person].concat(this.replace(current[rule]));
        }
      }
    }
  }

  Analyzer.prototype.replace = function(sub) {
    var ending, key, letter, letters, list, re, _i, _len, _ref;
    list = [];
    _ref = sub['replacements'];
    for (key in _ref) {
      letters = _ref[key];
      re = new RegExp(key, "gi");
      for (_i = 0, _len = letters.length; _i < _len; _i++) {
        letter = letters[_i];
        ending = sub['form'].replace(re, letter).replace('+', '');
        list.push(ending);
      }
    }
    return list;
  };

  Analyzer.prototype.getPerson = function(word) {
    var adjLevenDist, currPers, ending, ld, min, person, wordEnding, _i, _j, _len, _len1, _ref, _ref1;
    min = 0;
    currPers = "error";
    console.log(this.markers);
    _ref = this.persons;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      person = _ref[_i];
      _ref1 = this.markers[person];
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        ending = _ref1[_j];
        console.log(ending);
        wordEnding = word.substring(word.length - ending.length);
        ld = this.levenshteinDistance(wordEnding, ending);
        adjLevenDist = (ld === 0 ? (-10) - ending.length : ld - ending.length);
        if (adjLevenDist < min) {
          min = adjLevenDist;
          currPers = person;
        }
      }
    }
    return currPers;
  };

  return Analyzer;

})();

if (typeof module !== 'undefined' && (module.exports != null)) {
  exports.Analyzer = Analyzer;
}
