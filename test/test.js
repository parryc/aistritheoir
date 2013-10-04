var should = require('chai').should(),
    Language = require('../src/hungarian.js').Language,
    Orthography = require('../src/hungarian.js').Orthography,
    Word = require('../src/hungarian.js').Word,
    Inflection = require('../src/hungarian.js').Inflection;

beforeEach(function(){
  hungarian = new Language("hungarian");

  hw = hungarian.words;

  hungarian.orthography({
    "vowels": {
      "back": "aáoóuú",
      "front": {
        "rounded": "öőüű",
        "unrounded": "eéií"
      },
      "long": "áóúőűéí"
    },
    "consonants" : "bc(cs)d(dz)(dzs)fg(gy)hjkl(ly)mn(ny)prs(sz)t(ty)vz(zs)",
    "sibilants": "s(sz)z(dz)",
    "palatals": "jl(ly)n(ny)r"
  });

  hungarian.word("ért", "VERB");
  word1 = hungarian.words.ért;

  hungarian.word("tanít", "VERB");
  word2 = hungarian.words.tanít;

  hungarian.word("játszik","VERB");
  word3 = hungarian.words.játszik;

  hungarian.word("fordít","VERB");
  word4 = hungarian.words.fordít;

  hungarian.inflection({
    "schema": ["back","front.unrounded","front.rounded"],
    "name": "VERB",
    "1sg": {
      "default": {
        "form": "+Vk",
        "replacements": {
          "V": ["o", "e", "ö"]
        }
      },
      "-ik": {
        "form": "+Vm",
        "replacements": {
          "V": ["o", "e", "ö"]
        }
      }
    },
    "2sg": {
      "default": {
        "form":"+sz",
        "replacements":{"V":["a","e","e"]}
      },
      "after 'consonants' x2 or 'vowels.long' + t": {
        "form":"+Vsz",
        "replacements":{"V":["a","e","e"]}
      },
      "after 'sibilants'": {
        "form":"+Vl",
        "replacements":{"V":["o","e","ö"]}
      }
    },
    "3sg": {
      "form": "+",
      "replacements": {}
    },
    "1pl": {
      "form": "+Vnk",
      "replacements": {
        "V": ["u", "ü", "ü"]
      }
    },
    "2pl": {
      "default":{
        "form": "+tVk",
        "replacements": {"V": ["o", "e", "ö"]}
      },
      "after 'consonants' x2 or 'vowels.long' + t": {
        "form": "+VtVk",
        "replacements": {"V": ["o", "e", "ö"]}
      }
    },
    "3pl": {
      "default": {
        "form": "+nVk",
        "replacements": {"V": ["a", "e", "e"]}
      },
      "after 'consonants' x2 or 'vowels.long' + t": {
        "form": "+VnVk",
        "replacements": {"V": ["a", "e", "e"]}
      }
    }
  });


  hungarian.inflection({
    "schema": ["back","front"],
    "name": "VERB-PST",
    "markers": ["PST"],
    "1sg": {
      "form": "+Vm",
      "replacements": {"V": ["a","e"]}
    },
   "2sg": {
      "form": "+Vl",
      "replacements": {"V": ["ú","é"]}
    },
    "3sg": {
      "form": "+",
      "replacements": {}
    },
    "1pl": {
      "form": "+Vnk",
      "replacements": {"V": ["u","ü"]}
    },
    "2pl": {
      "form": "+AtBk",
      "replacements": {"A": ["a","e"], "B": ["o","e"]}
    },
    "3pl": {
      "form": "+Vk",
      "replacements": {"V": ["a","e"]}
    }
  })

  hungarian.marker({
    "schema": ["back", "front.unrounded", "front.rounded"],
    "name": "PST",
    "after 'consonants' x2 or 'vowels.long' + t": {
      "exceptions": ["fut","hat", "jut", "köt", "nyit", "süt", "üt", "vet"],
      "form": "+Vtt",
      "replacements": {"V": ["o","e","ö"]}
    },
    "after 'palatals' or +ad or +ed": {
      "exceptions": ["áll","száll","varr","forr"],
      "form": "+t",
      "replacements":{}
    },
    "default": {
      "exceptions": ["lát", "küld", "mond", "keyd", "függ", "fedd"],
      "overrides": {"3sg" :{
          "form": "+Vtt",
          "replacements": {"V": ["o","e","ö"]}
        }
      },
      "form": "+t",
      "replacements": {}
    }
  })

  hungarian.phraseStructure("S","VERB");
});

describe('Language', function() {
  describe('instance', function(){
    it('should construct correctly', function(){
      hungarian.id.should.equal('hungarian');
    });
  });
});

describe('Words', function(){
  describe('on creation', function(){
    it('should have a lemma', function(){
      word1.lemma.should.equal('ért');
    });

    it('should have a pos', function(){
      word1.pos.should.equal('VERB');
    });

    it('should have a vowel category', function(){
      word1.vowel.should.equal('front.unrounded');
    });
  });

  describe('should be able to tell you', function(){
    it('has certain letters', function(){
      word2.has("vowels.front.unrounded").should.equal(true);
    })
  });
});

describe('Conjugations', function(){
  describe('for each verb in the present tense,', function(){
    it('if base, should return the correct conjugation', function(){
      hungarian.inflect(word1,"1sg").should.equal('értek');
      hungarian.inflect(word1,"3sg").should.equal('ért');
      hungarian.inflect(word1,"1pl").should.equal('értünk');


      hungarian.inflect(word2,"1sg").should.equal('tanítok');
      hungarian.inflect(word2,"2sg").should.equal('tanítasz');
      hungarian.inflect(word2,"3sg").should.equal('tanít');
      hungarian.inflect(word2,"1pl").should.equal('tanítunk');
      hungarian.inflect(word2,"2pl").should.equal('tanítotok');
      hungarian.inflect(word2,"3pl").should.equal('tanítanak');
    });

    it('if ik verb, should return the correct conjugation', function(){
      hungarian.inflect(word3,"1sg").should.equal('játszom');
      hungarian.inflect(word3,"3sg").should.equal('játszik');
    });

    it('if after two consonants should return the correct conjugation', function(){
      hungarian.inflect(word1,"2sg").should.equal('értesz');
      hungarian.inflect(word1,"2pl").should.equal('értetek');
      hungarian.inflect(word1,"3pl").should.equal('értenek');
    })

    it('if after a long vowel + t, should return the correct conjugation', function(){
      hungarian.inflect(word4,"2sg").should.equal("fordítasz");
      hungarian.inflect(word4,"2pl").should.equal("fordítotok");
      hungarian.inflect(word4,"3pl").should.equal("fordítanak");
    })

    it('if after a sibilant, should return the correct conjugation', function(){
      hungarian.word('főz','VERB')
      hungarian.inflect(hungarian.words.főz,'2sg').should.equal("főzöl")
    })
  })

  describe('for each verb in the past tense,', function(){
    it('if class A, should return the correct conjugation')
    it('if class B, should return the correct conjugation')
    it('if class C, should return the correct conjugation')
  })
});

describe('Phrase Structure rules', function(){
  describe('on creation', function(){
    it('should store rules correctly', function(){
      hungarian.rules['S'] = ["VERB"];
    });
  });
});
