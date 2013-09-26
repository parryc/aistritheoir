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

Create a language object - this stores all of the information you generate
````
hungarian = new Language("hungarian")
hw = hungarian.words
````

Define an orthography - this is accessible by the word.  In this case, I define the different vowel distinctions used for Hungarian vowel harmony
````
hungarian.orthography({
	"vowels": {
		"back": "aáoóuú"
		"front": {
			"rounded": "öőüű"
			"unrounded": "eéií"
		}
	}
})
````

Create some words.  The "VERB" is the POS.  The inflection scheme is defined automatically based on the definition in the Word class and (shouldn't?) isn't specified by the user. 
````
hungarian.word("ért","VERB")
hungarian.word("tanít","VERB")
````

The most interesting bit is creating inflection rules.  It takes a grammatical descriptor (e.g. "1sg" or "DAT") and the morphological form ("+Vk").  The morphological form is described by what replacements need to be done: in this case "V" is replaced by the vowel harmony type (index to the array) and the '+' means it's a suffix. 

````
hungarian.inflection({
	"name":"VERB"
	"1sg":{
			"form":"+Vk"
			"replacements":{"V":["e","ö","o"]}
		}
	"2sg":{
		"form":"+Vsz"
		"replacements":{"V":["e","e","a"]}
	}
	"3sg":{
			"form":"+"
			"replacements":{}
		}
	"1pl":{
			"form":"+Vnk"
			"replacements":{"V":["ü","ü","u"]}
		}
	"2pl":{
			"form":"+VtVk"
			"replacements":{"V":["e","ö","o"]}
		}		
	"3pl":{
		"form":"+VnVk"
		"replacements":{"V":["e","e","a"]}
	}
})
````

## Testing ##
Here there be tests. Mocha and Chai that sholdier boy.