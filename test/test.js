var should = require('chai').should(),
    Analyzer = require('../src/analyze.js').Analyzer;
    Language = require('../src/hungarian.js').Language,
    Orthography = require('../src/hungarian.js').Orthography,
    Word = require('../src/hungarian.js').Word,
    Inflection = require('../src/hungarian.js').Inflection;

beforeEach(function(){
  hungarian = new Language("hungarian");

  hw = hungarian.words;

  hungarian.orthography({
    "vowels": {
      "all": "áóúőűéíaoueiöü",
      "back": "aáoóuú",
      "front": {
        "rounded": "öőüű",
        "unrounded": "eéií"
      },
      "long": "áóúőűéí",
      "short": "aoueiöü"
    },
    "consonants" : "bc(cs)d(dz)(dzs)fg(gy)hjkl(ly)mn(ny)prs(sz)t(ty)vz(zs)",
    "sibilants": "s(sz)z(dz)",
    "palatals": "jl(ly)n(ny)r"
  });

  hungarian.word("ért", "VERB");
  ert = hungarian.words.ért;

  hungarian.word("tanít", "VERB");
  tanit = hungarian.words.tanít;

  hungarian.word("játszik","VERB");
  jatszik = hungarian.words.játszik;

  hungarian.word("fordít","VERB");
  fordit = hungarian.words.fordít;

  hungarian.inflection({
    "schema": ["back","front.unrounded","front.rounded"],
    "name": "VERB",
    "preprocess": {"for":"2sg,1pl,2pl,3pl","do":"remove ik"},
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
    "preprocess": {"for":"all","do":"remove ik"},
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
  });

  hungarian.inflection({
    "schema": ["back","front.unrounded","front.rounded"],
    "name": "VERB-SUBJ",
    "markers": ["SUBJ"],
    "1sg": {
      "form": "+Vk",
      "replacements": {"V": ["a","e","e"]}
    },
    "2sg": {
      "form": "+",
      "replacements": {}
    },
    "3sg": {
      "form": "+n",
      "replacements": {"V": ["o","e","ö"]}
    },
    "1pl": {
      "form": "+Vnk",
      "replacements": {"V": ["u","ü","ü"]}
    },
    "2pl": {
      "form": "+AtBk",
      "replacements": {"A": ["a","e","e"], "B": ["o","e","e"]}
    },
    "3pl": {
      "form": "+VnVk",
      "replacements": {"V": ["a","e","e"]}
    }
  });

  hungarian.inflection({
    "schema": ["back","front"],
    "name": "VERB-COND",
    "markers": ["COND"],
    "preprocess": {"for":"all","do":"remove ik"},
    "1sg": {
      "form": "+nék",
      "replacements": {}
    },
    "2sg": {
      "form": "+nVl",
      "replacements": {"V": ["á","é"]}
    },
    "3sg": {
      "form": "+nV",
      "replacements": {"V": ["a","e"]}
    },
    "1pl": {
      "form": "+nVnk",
      "replacements": {"V": ["á","é"]}
    },
    "2pl": {
      "form": "+nAtBk",
      "replacements": {"A":  ["á","é"], "B": ["o","e"]}
    },
    "3pl": {
      "form": "+nAnBk",
      "replacements": {"A":  ["á","é"], "B": ["a","e"]}
    }
  });

  hungarian.inflection({
    "schema": ["back","front"],
    "name": "VERB-FUT",
    "markers": ["INF"],
    "1sg": {
      "form": "_fogok",
      "replacements": {}
    },
    "2sg": {
      "form": "_fogsz",
      "replacements": {}
    },
    "3sg": {
      "form": "_fog",
      "replacements": {}
    },
    "1pl": {
      "form": "_fogunk",
      "replacements": {}
    },
    "2pl": {
      "form": "_fogtok",
      "replacements": {}
    },
    "3pl": {
      "form": "_fognak",
      "replacements": {}
    }
  });

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
  });

  hungarian.marker({
    "schema": [],
    "name": "SUBJ",
    "after 'sibilants'": {
      "assimilation": "double",
      "form":"+",
      "replacements":{}
    },
    "after (s|sz) + t": {
      "assimilation": "remove t, double",
      "form":"+",
      "replacements":{}
    },
    "after 'vowels.long' + t or 'consonants' + t":{
      "form":"+s",
      "replacements":{}
    },
    "after 'vowels.short' + t":{
      "assimilation": "remove t",
      "form":"+ss",
      "replacements":{}
    },
    "default": {
      "form":"+j",
      "replacements":{}
    }
  });

  //Rolled the actual marker into the inflection for ease of rules.
  //It's actually shown that way in Rounds' Hungarian Grammar, too. [4.3.7.1]
  hungarian.marker({
    "schema": ["back","front"],
    "name": "COND",
    "after 'vowels.long' + t or 'consonants' + t":{
      "exceptions":  ["áll","száll","varr","forr"],
      "form":"+V",
      "replacements":{"V":["a","e"]}
    },
    "default": {
      "form":"+",
      "replacements":{}
    }
  });

  hungarian.marker({
    "schema": ["back","front"],
    "name": "INF",
    "after 'vowels.long' + t or 'consonants' + t":{
      "exceptions":  ["áll","száll","varr","forr"],
      "form":"+Vni",
      "replacements":{"V":["a","e"]}
    },
    "default": {
      "form":"+ni",
      "replacements":{}
    }
  });

  /*************************
    Derivational Endings
   *************************/
  hungarian.marker({
    "schema": ["back", "front.unrounded", "front.rounded"],
    "name": "Frequentive",
    "order": 0,
    "only ('consonants')'vowels.all''consonants'":{
      "form":"+AgBt",
      "replacements":{
        "A": ["o","e","ö"],
        "B": ["a","e","e"]
      }
    },
    "default":{
      "form":"+gVt",
      "replacements":{"V":["a","e","e"]}
    }
  }, true);

  hungarian.marker({
    "schema": ["back","front"],
    "name": "Potential",
    "order": 1,
    "default":{
      "form":"+hVt",
      "replacements":{"V":["a","e"]}
    }
  }, true);

  //The Hungarian causative is not like the English causative, and is rarely used generally - mostly in well established verb pairs.
  //http://forum.wordreference.com/showthread.php?t=2148708
  //It also saves me the trouble of trying to figure out how to do syllable structure... 


  hungarian.phraseStructure("S","VERB");

  analyzer = new Analyzer(hungarian);
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
      ert.lemma.should.equal('ért');
    });

    it('should have a pos', function(){
      ert.pos.should.equal('VERB');
    });

    it('should have a vowel category', function(){
      ert.vowel.should.equal('front.unrounded');
    });
  });

  describe('should be able to tell you', function(){
    it('has certain letters', function(){
      tanit.has("vowels.front.unrounded").should.equal(true);
    });
  });
});

describe('Conjugations', function(){
  describe('for each indefinite verb in the present tense,', function(){
    it('if base, should return the correct conjugation', function(){
      hungarian.inflect(ert,"1sg").should.equal('értek');
      hungarian.inflect(ert,"3sg").should.equal('ért');
      hungarian.inflect(ert,"1pl").should.equal('értünk');


      hungarian.inflect(tanit,"1sg").should.equal('tanítok');
      hungarian.inflect(tanit,"2sg").should.equal('tanítasz');
      hungarian.inflect(tanit,"3sg").should.equal('tanít');
      hungarian.inflect(tanit,"1pl").should.equal('tanítunk');
      hungarian.inflect(tanit,"2pl").should.equal('tanítotok');
      hungarian.inflect(tanit,"3pl").should.equal('tanítanak');
    });

    it('if ik verb, should return the correct conjugation', function(){
      hungarian.inflect(jatszik,"1sg").should.equal('játszom');
      hungarian.inflect(jatszik,"2sg").should.equal('játszol');
      hungarian.inflect(jatszik,"3sg").should.equal('játszik');
    });

    it('if after two consonants should return the correct conjugation', function(){
      hungarian.inflect(ert,"2sg").should.equal('értesz');
      hungarian.inflect(ert,"2pl").should.equal('értetek');
      hungarian.inflect(ert,"3pl").should.equal('értenek');
    });

    it('if after a long vowel + t, should return the correct conjugation', function(){
      hungarian.inflect(fordit,"2sg").should.equal("fordítasz");
      hungarian.inflect(fordit,"2pl").should.equal("fordítotok");
      hungarian.inflect(fordit,"3pl").should.equal("fordítanak");
    });

    it('if after a sibilant, should return the correct conjugation', function(){
      hungarian.word('főz','VERB');
      hungarian.inflect(hungarian.words.főz,'2sg').should.equal("főzöl");
    });
  });

  // describe('for each definite verb in the present tense');

  describe('for each indefinite verb in the past tense,', function(){
    it('if class A, should return the correct conjugation', function(){
      hungarian.inflect(tanit,'1sg','PST').should.equal('tanítottam');
    });
    it('if class B, should return the correct conjugation', function(){
      hungarian.word('marad', 'VERB');
      hungarian.inflect(hungarian.words.marad,'1sg','PST').should.equal('maradtam');
    });
    it('if class C, should return the correct conjugation', function(){
      hungarian.word('szeret', 'VERB');
      hungarian.inflect(hungarian.words.szeret,'1sg','PST').should.equal('szerettem');
    });
    it('should catch exceptions', function(){
      hungarian.word('süt', 'VERB');
      hungarian.inflect(hungarian.words.süt,'1sg','PST').should.equal('sütöttem');
    });
    it('should catch overrides of normal paradigm', function(){
      hungarian.inflect(hungarian.words.szeret,'3sg','PST').should.equal('szeretett');
    });
  });

  describe('for each indefinite verb in the subjunctive', function(){
    it('if the ending ends in a sibilant, it should conjugate and assimilate correctly', function(){
      hungarian.word('keres','VERB');
      hungarian.inflect(hungarian.words.keres,'1sg','SUBJ').should.equal('keressek');
    });
    it('if the ending ends in a s or sz with a t, it should conjugate and assimilate correctly', function(){
      hungarian.word('ébreszt','VERB');
      hungarian.inflect(hungarian.words.ébreszt,'1sg','SUBJ').should.equal('ébresszek');
    });
    it('if the ending ends in a long vowel or consonant with a t, it should conjugate and assimilate correctly', function(){
      hungarian.word('segít','VERB');
      hungarian.inflect(hungarian.words.segít,'1sg','SUBJ').should.equal('segítsek');
    });
    it('if the ending ends in a short vowel, it should conjugate and assimilate correctly', function(){
      hungarian.word('mutat','VERB');
      hungarian.inflect(hungarian.words.mutat,'1sg','SUBJ').should.equal('mutassak');
    });
  });

  describe('for each indefinite verb in the conditional', function(){
    before(function(){
      hungarian.word('segít','VERB');
      segit = hungarian.words.segít;
      hungarian.word('mer','VERB');
      mer = hungarian.words.mer;
      hungarian.word('úszik','VERB');
      uszik = hungarian.words.úszik; 
    });

    it('if the ending ends in a long vowel or consonant with a t, it should conjugate and mark correctly', function(){
      hungarian.inflect(segit,'1sg','COND').should.equal('segítenék');
      hungarian.inflect(segit,'2sg','COND').should.equal('segítenél');
      hungarian.inflect(segit,'3sg','COND').should.equal('segítene');
      hungarian.inflect(segit,'1pl','COND').should.equal('segítenénk');
      hungarian.inflect(segit,'2pl','COND').should.equal('segítenétek');
      hungarian.inflect(segit,'3pl','COND').should.equal('segítenének');
      hungarian.inflect(fordit,'1sg','COND').should.equal('fordítanék');
      hungarian.inflect(fordit,'3sg','COND').should.equal('fordítana');
      hungarian.inflect(fordit,'3pl','COND').should.equal('fordítanának');
    });
    it('and for the rest, it should conjugate', function(){
      hungarian.inflect(mer,'1sg','COND').should.equal('mernék');
      hungarian.inflect(mer,'3sg','COND').should.equal('merne');
      hungarian.inflect(mer,'3pl','COND').should.equal('mernének');
      hungarian.inflect(uszik,'1sg','COND').should.equal('úsznék');
      hungarian.inflect(uszik,'3sg','COND').should.equal('úszna');
      hungarian.inflect(uszik,'3pl','COND').should.equal('úsznának');
    });
  });

  describe('for each indefinite verb in the future', function(){
    it('if the ending ends in a long vowel or consonant with a t, it should conjugate and mark correctly', function(){
      hungarian.inflect(segit,'1sg','FUT').should.equal('segíteni fogok');
      hungarian.inflect(segit,'2sg','FUT').should.equal('segíteni fogsz');
      hungarian.inflect(segit,'3sg','FUT').should.equal('segíteni fog');
    });
    it('and for the rest, it should conjugate', function(){
      hungarian.inflect(mer,'1sg','FUT').should.equal('merni fogok');
      hungarian.inflect(mer,'2sg','FUT').should.equal('merni fogsz');
      hungarian.inflect(mer,'3sg','FUT').should.equal('merni fog');
    });
  });
});

describe('Derivational endings and suffixes', function(){
  describe('for all tenses', function(){
    it('should insert the potential marking correctly', function(){
      hungarian.inflect(jatszik,'1sg','',['Potential']).should.equal('játszhatom');
      hungarian.inflect(jatszik,'1sg','PST',['Potential']).should.equal('játszhattam');
    });

    it('should insert the frequentive marking correctly for polysyllabic words', function(){
      hungarian.inflect(jatszik,'1sg','',['Frequentive']).should.equal('játszgatom');
      hungarian.inflect(jatszik,'1sg','PST',['Frequentive']).should.equal('játszgattam');
    });

    before(function(){
      hungarian.word("mos","VERB");
      mos = hungarian.words.mos;
      hungarian.word("néz","VERB");
      nez = hungarian.words.néz;
    });

    it('should insert the frequentive marking correctly for monosyllabic', function(){
      hungarian.inflect(mos,'1sg','',['Frequentive']).should.equal('mosogatok');
      hungarian.inflect(mos,'1sg','PST',['Frequentive']).should.equal('mosogattam');
    });

    it('should insert both the frequentive and potential correctly', function(){
       hungarian.inflect(mos,'1sg','',['Frequentive','Potential']).should.equal('mosogathatok');
       hungarian.inflect(nez,'1sg','',['Frequentive','Potential']).should.equal('nézegethetek');
    });
  });
});

// describe('for each definite verb in the past tense');

describe('Phrase Structure rules', function(){
  describe('on creation', function(){
    it('should store rules correctly', function(){
      hungarian.rules['S'] = ["VERB"];
    });
  });
});



//Analyzer
describe('The analyzer', function(){
  describe('for the present tense', function(){
    it('should detect the correct number and person for a verbal ending', function(){
      analyzer.getMorphology('játszol').results[0].person.should.equal('2sg');
      analyzer.getMorphology('játszol').results[0].tense.should.equal('');
      analyzer.getMorphology('fordítanak').results[0].person.should.equal('3pl');
      analyzer.getMorphology('fordítanak').results[0].tense.should.equal('');
    });

    it('should correctly identify ambiguous constructions', function(){
      analyzer.getMorphology('értek').ambiguous.should.equal(true);
      analyzer.getMorphology('értek').results[0].person.should.equal('1sg');
      analyzer.getMorphology('értek').results[0].tense.should.equal('');
      analyzer.getMorphology('értek').results[1].person.should.equal('2pl');
      analyzer.getMorphology('értek').results[1].tense.should.equal('');
    });
  });

  describe('for the past tense', function(){
    it('should detect the correct number and person for a verbal ending', function(){
      console.log(analyzer.getMorphology('szeretett'))
      analyzer.getMorphology('tanítottam').results[0].person.should.equal('1sg');
      analyzer.getMorphology('tanítottam').results[0].tense.should.equal('PST');
      analyzer.getMorphology('szeretett').results[1].person.should.equal('3sg');
      analyzer.getMorphology('szeretett').results[1].tense.should.equal('PST');
      analyzer.getMorphology('sütöttem').results[0].person.should.equal('1sg');
      analyzer.getMorphology('sütöttem').results[0].tense.should.equal('PST');
    });
  });

  describe('for the subjunctive tense', function(){
    it('should detect the correct number and person for a verbal ending', function(){
      analyzer.getMorphology('keressek').results[1].person.should.equal('1sg');
      analyzer.getMorphology('keressek').results[1].tense.should.equal('SUBJ');
      analyzer.getMorphology('ébresszek').results[2].person.should.equal('1sg');
      analyzer.getMorphology('ébresszek').results[2].tense.should.equal('SUBJ');
      analyzer.getMorphology('segítsek').results[1].person.should.equal('1sg');
      analyzer.getMorphology('segítsek').results[1].tense.should.equal('SUBJ');
      analyzer.getMorphology('mutassak').results[0].person.should.equal('1sg');
      analyzer.getMorphology('mutassak').results[0].tense.should.equal('SUBJ');
    });
  });

  describe('for the conditional tense', function(){
    it('should detect the correct number and person for a verbal ending', function(){
      analyzer.getMorphology('fordítanának').results[1].person.should.equal('3pl');
      analyzer.getMorphology('fordítanának').results[1].tense.should.equal('COND');
      analyzer.getMorphology('mernék').results[0].person.should.equal('1sg');
      analyzer.getMorphology('mernék').results[0].tense.should.equal('COND');
      analyzer.getMorphology('úszna').results[0].person.should.equal('3sg');
      analyzer.getMorphology('úszna').results[0].tense.should.equal('COND');
    });
  });

  describe('for the future tense', function(){
    it('should detect the correct number and person for a verbal ending', function(){
      analyzer.getMorphology('segíteni fogok').results[0].person.should.equal('1sg');
      analyzer.getMorphology('segíteni fogok').results[0].tense.should.equal('FUT');
      analyzer.getMorphology('merni fog').results[0].person.should.equal('3sg');
      analyzer.getMorphology('merni fog').results[0].tense.should.equal('FUT');
    });
  });

  describe('for words with derivational endings', function(){
    it('should identify them correctly for the potential ending', function(){
      analyzer.getMorphology('moshatok').results[0].derivations[0].should.equal('Potential');
      analyzer.getMorphology('moshattam').results[0].derivations[0].should.equal('Potential');
      analyzer.getMorphology('moshattam').results[0].tense.should.equal('PST');
    });

    it('should identify correctly for -ik verbs')
      // analyzer.getMorphology('játszhatom').results[0].derivations[0].should.equal('Potential');
      // analyzer.getMorphology('játszhattam').results[0].derivations[0].should.equal('Potential');
      // analyzer.getMorphology('játszhattam').results[0].tense.should.equal('PST');

    it('should identify them correctly for the frequentive ending', function(){
      analyzer.getMorphology('mosogatok').results[0].derivations[0].should.equal('Frequentive');
      analyzer.getMorphology('mosogattam').results[0].derivations[0].should.equal('Frequentive');
    });

    it('should identify them correctly with both the frequentive and potential ending', function(){
      // console.log(analyzer.getMorphology('mosogathatok').results[0]);
      analyzer.getMorphology('mosogathatok').results[0].derivations.join().should.equal('Frequentive,Potential');
      analyzer.getMorphology('nézegethetek').results[0].derivations.join().should.equal('Frequentive,Potential');
    });
  });
});