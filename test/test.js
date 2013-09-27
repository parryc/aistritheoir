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
      }
    }
  });

  hungarian.word("ért", "VERB");
  word1 = hungarian.words.ért;

  hungarian.word("tanít", "VERB");
  word2 = hungarian.words.tanít;

  hungarian.word("hazudik","VERB");
  word3 = hungarian.words.hazudik;

  hungarian.inflection({
    "schema": ["front.unrounded","front.rounded","back"],
    "name": "VERB",
    "1sg": {
      "form": "+Vk",
      "replacements": {
        "V": ["e", "ö", "o"]
      }
    },
    "2sg": {
      "form": "+Vsz",
      "replacements": {
        "V": ["e", "e", "a"]
      }
    },
    "3sg": {
      "form": "+",
      "replacements": {}
    },
    "1pl": {
      "form": "+Vnk",
      "replacements": {
        "V": ["ü", "ü", "u"]
      }
    },
    "2pl": {
      "form": "+VtVk",
      "replacements": {
        "V": ["e", "ö", "o"]
      }
    },
    "3pl": {
      "form": "+VnVk",
      "replacements": {
        "V": ["e", "e", "a"]
      }
    }
  });

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
      word3.lemma.should.equal('hazud');
    });

    it('should have a type', function(){
      word1.type.should.equal('VERB');
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
      word2.has(word2.o.vowels.front.unrounded).should.equal(true);
    })
  });
});

describe('Conjugations', function(){
  describe('for each verb,', function(){
    it('if base, should return the correct conjugation', function(){
      hungarian.inflect(word1,"1sg").should.equal('értek');
      hungarian.inflect(word1,"2sg").should.equal('értesz');
      hungarian.inflect(word1,"3sg").should.equal('ért');
      hungarian.inflect(word1,"1pl").should.equal('értünk');
      hungarian.inflect(word1,"2pl").should.equal('értetek');
      hungarian.inflect(word1,"3pl").should.equal('értenek');
      hungarian.inflect(word2,"1sg").should.equal('tanítok');
      hungarian.inflect(word2,"2sg").should.equal('tanítasz');
      hungarian.inflect(word2,"3sg").should.equal('tanít');
      hungarian.inflect(word2,"1pl").should.equal('tanítunk');
      hungarian.inflect(word2,"2pl").should.equal('tanítotok');
      hungarian.inflect(word2,"3pl").should.equal('tanítanak');
    });

    it('if ik verb, should return the correct conjugation');
  })
});

describe('Phrase Structure rules', function(){
  describe('on creation', function(){
    it('should store rules correctly', function(){
      hungarian.rules['S'] = ["VERB"];
    });
  });
});
