var should = require('chai').should(),
    Language = require('../src/hungarian.js').Language,
    Orthography = require('../src/hungarian.js').Orthography,
    Word = require('../src/hungarian.js').Word,
    Inflection = require('../src/hungarian.js').Inflection;

beforeEach(function(){
  var FRONT_UR = 0;
      FRONT_R = 1;
      BACK = 2;

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

  hungarian.inflection({
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

    it('should have a type', function(){
      word1.type.should.equal('VERB');
    });

    it('should have a pos', function(){
      word1.pos.should.equal('VERB');
    });

    it('should have a vowel category', function(){
      word1.vowel.should.equal(0);
    });
  });
});

describe('Conjugations', function(){
  describe('for each verb,', function(){
    it('if base, should return the correct conjugation', function(){
      hungarian.conjugate(word1,"1sg").should.equal('értek');
      hungarian.conjugate(word1,"2sg").should.equal('értesz');
      hungarian.conjugate(word1,"3sg").should.equal('ért');
      hungarian.conjugate(word1,"1pl").should.equal('értünk');
      hungarian.conjugate(word1,"2pl").should.equal('értetek');
      hungarian.conjugate(word1,"3pl").should.equal('értenek');
    });

    it('if ik verb, should return the correct conjugation');
  })
})
