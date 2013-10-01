# Aistritheoir #

## What is this? ##
After seeing some cool work by @nmashton with [GF](https://github.com/GrammaticalFramework/GF), I was super excited to start hacking around in it...however, the syntax is kind of opaque and I couldn't quite figure out how to get it onto the web. So this is an attempt to take the idea of describing a natural language grammar programmatically to the web. At the moment it's mostly being used to help me learn Hungarian (and Test Driven Development/Coffeescript, but those aren't nearly as important), so approach with caution. 

## Onwards and upwards! ##
As I mentioned above, it's currently oriented towards Hungarian, but the goal is to make it language agnostic as I use it to help me learn the grammar of more languages. It would be cool to be able to take the Language object and generate an interactive website from it. 

## Language feature support ##
* Orthography: minimal
* Words: minimal
* Inflections: probably just enough to frustrate

## How to use it ##
This set up is taken directly from the tests. 

Create a language object - this stores all of the information you generate
````
hungarian = new Language("hungarian");
````

Define an orthography - this is accessible by the word.  Surround n-graphs (digraphs etc.) with parentheses. 
````
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
    "sibilants": "s(sz)z(dz)"
  });

````

Create some words - make sure to use the dictionary form [(also known as the lemma)](http://en.wikipedia.org/wiki/Lemma_(morphology)).  The "VERB" is the POS.  The inflection scheme is chosen automatically based on the part of speech and matching rules defined in the . 
````
hungarian.word("ért","VERB")
hungarian.word("tanít","VERB")
````

The most interesting bit is creating inflection rules.  It takes a grammatical descriptor (e.g. "1sg" or "DAT") and the morphological form ("+Vk").  The morphological form is described by what replacements need to be done: in this case "V" is replaced by the vowel harmony type (index to the array) and the '+' means it's a suffix. You'll notice that there are some more verbose conditions. These are described with a (at the moment) reduced grammar: 

* ```after``` means that what follows must appear at the end of the word
* orthographic lists are accessed with their path in quotes, e.g. ```'vowels.back'``` will match any ```aáoóuú```
* use ```or``` to have multiple conditions
* strings of words are denoted with an ```xN```, where N is the number of times it should be repeated
* ```+``` is basic concatenation

For example, ```after 'consonants' x2 or 'vowels.long' + t``` expands to ```/([b|c|...|zs]{2}|[á|ó|...|í]t)$/```

````
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
````

## Testing ##
Here there be tests. Mocha and Chai that sholdier boy.