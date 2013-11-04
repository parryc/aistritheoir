// Generated by CoffeeScript 1.6.3
var Inflection, Language, Marker, Orthography, PhraseStructure, Word,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Language = (function() {
  function Language(id) {
    this.id = id;
  }

  Language.prototype.defaultOrthography = "latin";

  Language.prototype.orthographies = {};

  Language.prototype.words = {};

  Language.prototype.inflections = {};

  Language.prototype.inflectionsRaw = {};

  Language.prototype.markers = {};

  Language.prototype.rules = {};

  Language.prototype.word = function(word, pos) {
    return this.words[word] = new Word(word, pos, this.orthographies[this.defaultOrthography]);
  };

  Language.prototype.orthography = function(orthography) {
    var id;
    id = this.defaultOrthography;
    return this.orthographies[id] = new Orthography(id, orthography);
  };

  Language.prototype.inflection = function(inflection) {
    this.inflectionsRaw[inflection.name] = inflection;
    return this.inflections[inflection.name] = new Inflection(inflection, false);
  };

  Language.prototype.copyInflection = function(inflection, newName, overwrite) {
    var key, newInflection, prop, _results;
    this.inflections[newName] = {};
    this.inflections[newName] = this._clone(this.inflections[inflection]);
    newInflection = this.inflections[newName];
    newInflection.name = newName;
    _results = [];
    for (key in overwrite) {
      prop = overwrite[key];
      _results.push(newInflection[key] = prop);
    }
    return _results;
  };

  Language.prototype.inflect = function(word, form, additional) {
    var fullInflection, inflection, marker, markerList, _i, _len, _ref;
    if ((additional != null) && additional !== "") {
      fullInflection = word.pos + '-' + additional;
    } else {
      fullInflection = word.pos;
    }
    inflection = this.inflections[fullInflection];
    if (inflection) {
      markerList = [];
      if (inflection.markers != null) {
        _ref = inflection.markers;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          marker = _ref[_i];
          markerList.push(this.markers[marker]);
        }
      }
      return inflection.inflect(word, form, markerList);
    } else {
      return console.log("There are no inflections of the type " + word.type);
    }
  };

  Language.prototype.marker = function(marker) {
    return this.markers[marker.name] = new Marker(marker);
  };

  Language.prototype.phraseStructure = function(fromThis, toThis) {
    if (this.rules[fromThis]) {
      return this.rules[fromThis].push(toThis);
    } else {
      return this.rules[fromThis] = [toThis];
    }
  };

  Language.prototype._clone = function(obj) {
    var key, newInstance;
    if ((obj == null) || typeof obj !== 'object') {
      return obj;
    }
    newInstance = new obj.constructor();
    for (key in obj) {
      newInstance[key] = this._clone(obj[key]);
    }
    return newInstance;
  };

  return Language;

})();

Orthography = (function() {
  function Orthography(id, orthography) {
    var key, letterSet, letters;
    this.id = id;
    letterSet = [];
    for (key in orthography) {
      letters = orthography[key];
      this[key] = letters;
    }
  }

  Orthography.prototype.get = function(path) {
    var part, split, temp, _i, _len;
    split = path.split('.');
    temp = this;
    for (_i = 0, _len = split.length; _i < _len; _i++) {
      part = split[_i];
      temp = temp[part];
    }
    return temp;
  };

  Orthography.prototype.getRegExp = function(path) {
    var g, letterSet, letters, ngraphs, _i, _len;
    letterSet = [];
    letters = this.get(path);
    ngraphs = letters.match(/\(([^\()])*\)/gi);
    if (ngraphs != null) {
      for (_i = 0, _len = ngraphs.length; _i < _len; _i++) {
        g = ngraphs[_i];
        letterSet.push(g.substr(1, g.length - 2));
        letters = letters.replace(g, "");
      }
    }
    return letterSet.concat(letters.split('')).join('|');
  };

  return Orthography;

})();

Word = (function() {
  function Word(lemma, pos, orthography) {
    this.lemma = lemma;
    this.pos = pos;
    this.o = orthography;
    this.vowel = this.getVowelType(this.lemma);
  }

  Word.prototype.count = function(letters) {
    return this._match(letters, false);
  };

  Word.prototype.has = function(letters) {
    return this._match(letters, true);
  };

  Word.prototype._match = function(letters, returnBoolean) {
    var match, matchCount, re;
    re = new RegExp(this.o.getRegExp(letters), "gi");
    match = this.lemma.match(re);
    if (match != null) {
      matchCount = match.length;
    } else {
      matchCount = 0;
    }
    if (returnBoolean) {
      return !!matchCount;
    } else {
      return matchCount;
    }
  };

  Word.prototype.getVowelType = function() {
    var back, frontR, frontUR;
    back = this.count("vowels.back");
    frontR = this.count("vowels.front.rounded");
    frontUR = this.count("vowels.front.unrounded");
    switch (Math.max(back, Math.max(frontR, frontUR))) {
      case back:
        return "back";
      case frontR:
        return "front.rounded";
      case frontUR:
        return "front.unrounded";
    }
  };

  return Word;

})();

Inflection = (function() {
  function Inflection(inflection, isException) {
    if (isException) {
      this.parseException(inflection);
    } else {
      this.parseInflection(inflection);
    }
  }

  Inflection.prototype.mergeSuff = function(stem, suffix) {
    suffix = suffix.replace("+", "").replace("_", " ");
    return stem + suffix;
  };

  Inflection.prototype.mergeAff = function(stem, affix) {
    affix = affix.replace("+", "").replace("_", " ");
    return affix + stem;
  };

  Inflection.prototype.parseException = function(inflection) {};

  Inflection.prototype.parseInflection = function(inflection) {
    var condition, key, parsedCondition, value, _ref;
    for (key in inflection) {
      value = inflection[key];
      if (key === "name" || key === "schema" || key === "markers" || key === "preprocess" || key === "coverb") {
        this[key] = value;
      } else {
        this[key] = {};
        if (value["default"]) {
          _ref = inflection[key];
          for (condition in _ref) {
            value = _ref[condition];
            parsedCondition = this._parseCondition(condition);
            this[key][parsedCondition] = this.substitutor(value.form, value.replacements, inflection.schema);
          }
        } else {
          this[key]["default"] = this.substitutor(value.form, value.replacements, inflection.schema);
        }
      }
    }
  };

  Inflection.prototype.substitutor = function(form, replacements, schema) {
    var _this = this;
    return function(word) {
      var ending, key, letters, re, schemaPosition;
      ending = form;
      schemaPosition = schema.indexOf(word.vowel);
      if (schemaPosition === -1) {
        schemaPosition = _this._findValidSchema(word.vowel, schema);
        if (schemaPosition === -1) {
          console.log("The word does not fit in this schema");
        }
      }
      for (key in replacements) {
        letters = replacements[key];
        re = new RegExp(key, "gi");
        ending = ending.replace(re, letters[schemaPosition]);
      }
      return ending;
    };
  };

  Inflection.prototype.inflect = function(word, form, markerList) {
    var condition, inflection, inflector, markData, marker, marks, match, re, root, trimOff, _i, _len;
    inflector = "default";
    root = word.lemma;
    if (this.preprocess && (this.preprocess["for"].indexOf(form) !== -1 || this.preprocess["for"] === 'all')) {
      root = this._assimilate(this.preprocess["do"], root);
    }
    for (condition in this[form]) {
      if (this._isDeleter(condition)) {
        re = new RegExp(condition.substr(1), "gi");
      } else {
        re = this._expandCondition(word, condition);
      }
      match = root.match(re);
      if (match != null) {
        inflector = condition;
      }
    }
    if (this._isDeleter(inflector)) {
      trimOff = inflector.substr(1, inflector.indexOf('$') - 1);
      root = word.lemma.substr(0, word.lemma.indexOf(trimOff));
    }
    marks = '';
    for (_i = 0, _len = markerList.length; _i < _len; _i++) {
      marker = markerList[_i];
      markData = marker.mark(word, form);
      if (markData.replaceThis === '') {
        root += markData.withThis;
      } else {
        root = root.replace(markData.replaceThis, markData.withThis);
      }
    }
    inflection = this[form][inflector](word);
    root = this._combine(root, inflection);
    if (this.coverb != null) {
      root = this._combine(root, this.coverb);
    }
    return root;
  };

  Inflection.prototype._combine = function(root, inflection) {
    if (inflection.substr(0, 1) === '+' || inflection.substr(0, 1) === '_') {
      return this.mergeSuff(root, inflection);
    } else {
      return this.mergeAff(root, inflection);
    }
  };

  Inflection.prototype._expandCondition = function(word, condition) {
    var expandedCondition, group, groupRegexp, groups, re, _i, _len;
    expandedCondition = condition;
    groups = condition.match(/'([^']*)'/gi);
    if (groups != null) {
      for (_i = 0, _len = groups.length; _i < _len; _i++) {
        group = groups[_i];
        groupRegexp = "(" + word.o.getRegExp(group.replace(/'/gi, "")) + ")";
        expandedCondition = expandedCondition.replace(group, groupRegexp);
      }
    }
    return re = new RegExp(expandedCondition, "gi");
  };

  Inflection.prototype._parseCondition = function(condition) {
    var exceptions;
    if (this._isDeleter(condition)) {
      return condition + '$';
    }
    condition = condition.replace(/after(.*)/gi, "($1)$");
    exceptions = condition.match(/exceptions\[(.*)\]/i);
    if (exceptions != null) {
      condition = condition.replace(exceptions[0], "^(" + exceptions[1].replace(/\s/gi, "|") + ")$");
    }
    condition = condition.replace(/\+/gi, "");
    condition = condition.replace(/x(\d)/gi, "{$1}");
    condition = condition.replace(/\sor\s/gi, "|");
    return condition.replace(/\s/gi, "");
  };

  Inflection.prototype._isDeleter = function(condition) {
    return condition.substr(0, 1) === '-';
  };

  Inflection.prototype._findValidSchema = function(wordCategory, schema) {
    var idx, valid;
    valid = '';
    while (wordCategory !== '') {
      wordCategory = wordCategory.substr(0, wordCategory.lastIndexOf('.'));
      idx = schema.indexOf(wordCategory);
      if (schema.indexOf(wordCategory) !== -1) {
        return idx;
      }
    }
    return valid;
  };

  Inflection.prototype._assimilate = function(rules, ending) {
    var rule, _i, _len;
    rules = rules.split(',');
    for (_i = 0, _len = rules.length; _i < _len; _i++) {
      rule = rules[_i];
      rule = rule.trim();
      rule.replace(/\+/gi, "");
      if (rule.indexOf('remove') === 0) {
        ending = ending.replace(rule.slice("remove".length + 1), "");
      }
      if (rule.indexOf('double') === 0) {
        ending = ending.substr(0, 1) + ending;
      }
    }
    return ending.replace(/\s/gi, "").replace(/_/gi, " ");
  };

  return Inflection;

})();

Marker = (function(_super) {
  __extends(Marker, _super);

  function Marker(marker) {
    var key, override, overrides, parsedCondition, value;
    this.conditions = {};
    for (key in marker) {
      value = marker[key];
      if (key === "name" || key === "schema") {
        this[key] = value;
      } else {
        parsedCondition = this._parseCondition(key);
        this.conditions[parsedCondition] = {};
        this.conditions[parsedCondition].marker = this.substitutor(value.form, value.replacements, marker.schema);
        this.conditions[parsedCondition].exceptions = value.exceptions;
        overrides = value.overrides;
        if (overrides) {
          this.conditions[parsedCondition].overrides = {};
          for (key in overrides) {
            override = overrides[key];
            this.conditions[parsedCondition].overrides[key] = this.substitutor(override.form, override.replacements, marker.schema);
          }
        }
        if (value.assimilation) {
          this.conditions[parsedCondition].assimilation = value.assimilation;
        }
      }
    }
    return;
  }

  Marker.prototype.getException = function(word) {
    var condition, data, _ref;
    _ref = this.conditions;
    for (condition in _ref) {
      data = _ref[condition];
      if ((data.exceptions != null) && __indexOf.call(data.exceptions, word) >= 0) {
        return condition;
      }
    }
    return '';
  };

  Marker.prototype.mark = function(word, form) {
    var condition, data, ending, mark, match, potentialException, re, replaceThis, root, rule, withThis, _ref, _ref1;
    rule = "";
    replaceThis = "";
    root = word.lemma;
    ending = '';
    _ref = this.conditions;
    for (condition in _ref) {
      data = _ref[condition];
      if (condition !== "default") {
        if (rule === '') {
          re = this._expandCondition(word, condition);
          match = root.match(re);
          if (match != null) {
            ending = match[0];
            rule = condition;
          }
        }
      }
    }
    if (rule === '') {
      rule = "default";
    }
    potentialException = this.getException(root);
    if (potentialException !== "") {
      rule = potentialException;
    }
    if (((_ref1 = this.conditions[rule].overrides) != null ? _ref1[form] : void 0) != null) {
      mark = this.conditions[rule].overrides[form](word);
    } else {
      mark = this.conditions[rule].marker(word);
    }
    withThis = this._combine('', mark);
    if (this.conditions[rule].assimilation) {
      replaceThis = ending;
      withThis = this._assimilate(this.conditions[rule].assimilation, ending) + withThis;
    }
    return {
      'replaceThis': replaceThis,
      'withThis': withThis
    };
  };

  return Marker;

})(Inflection);

PhraseStructure = (function() {
  function PhraseStructure(fromThis, toThis) {
    this.fromThis = fromThis;
    this.toThis = toThis;
    if (rules[fromThis]) {
      rules[fromThis].push(toThis);
    } else {
      rules[fromThis] = [toThis];
    }
  }

  PhraseStructure.prototype.rules = [];

  return PhraseStructure;

})();

if (typeof module !== 'undefined' && (module.exports != null)) {
  exports.Language = Language;
  exports.Orthography = Orthography;
  exports.Word = Word;
  exports.Inflection = Inflection;
}
