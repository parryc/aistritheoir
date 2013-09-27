# Basic Language class
class Language
	constructor: (@id) ->
		# window[id.substr(0,1)+"w"] = @.words

	defaultOrthography: "latin"
	orthographies: {}
	words: {}
	inflections: {}

	word: (word, pos) -> 
		@words[word] = new Word(word, pos, @orthographies[@defaultOrthography])

	orthography: (orthography) ->
		id = @defaultOrthography
		@orthographies[id] = new Orthography(id, orthography)

	inflection: (inflection) ->
		@inflections[inflection.name] = new Inflection(inflection, false)

	inflect: (word, form) ->
		if @inflections[word.type]
			@inflections[word.type].inflect(word, form)
		else
			console.log("There are no inflections of the type "+word.type)

class Orthography
	constructor: (@id,orthography) -> 
		for key, letters of orthography
			@[key] = letters

class Word
	constructor: (word, @pos, orthography) ->
		lemmaInfo = @toLemma(word)
		@lemma = lemmaInfo.lemma
		@type = lemmaInfo.type
		@o = orthography
		@vowel = @getVowelType(@lemma)

	count: (letters) ->
		@match(letters, false)

	has: (letters) ->
		@match(letters, true)

	match: (letters, returnBoolean) ->
		re = new RegExp(letters.split('').join('|'),"gi")
		match = @lemma.match(re)
		if match? then matchCount = match.length else matchCount = 0
		if returnBoolean then !matchCount else matchCount


	getVowelType: ->		
		back = @count(@o.vowels.back)
		frontR = @count(@o.vowels.front.rounded)
		frontUR = @count(@o.vowels.front.unrounded)
		switch Math.max(back,Math.max(frontR,frontUR))
			when back then "back"
			when frontR then "front.rounded"
			when frontUR then "front.unrounded"

	toLemma: (word) ->
		if word.substr(-2) is "ik" 
			{
				"lemma": word.substr(0,word.length-2) 
				"type": @pos+"+ik"
			}
		else 
			{
				"lemma": word
				"type": @pos 
			} 

class Inflection
	constructor: (inflection, isException) ->
		if isException then @parseException(inflection) else @parseInflection(inflection)

	#add support for letter change rules
	mergeSuff: (stem, suffix) ->
		stem + suffix.substr(1)

	mergeAff: (affix, stem) ->
		affix.substr(affix.length-1) + stem

	parseException: (inflection) ->
		 # Todo 

	parseInflection: (inflection) ->
		for key, value of inflection
			if key is "name" or key is "schema"
				@[key] = value
			else
				@[key] = @substitutor(value.form, value.replacements, inflection.schema)
		return
			
	substitutor: (form, replacements, schema) ->
		(word) -> 
			ending = form
			for key, letters of replacements
				re = new RegExp(key,"gi")
				ending = ending.replace(re,letters[schema.indexOf(word.vowel)])
			return ending

	inflect: (word, form) ->
		@mergeSuff(word.lemma,@[form](word))

if typeof module isnt 'undefined' and module.exports?
    exports.Language = Language
    exports.Orthography = Orthography
    exports.Word = Word
    exports.Inflection = Inflection



hungarian = new Language("hungarian")
hw = hungarian.words
hungarian.orthography({
	"vowels": {
		"back": "aáoóuú"
		"front": {
			"rounded": "öőüű"
			"unrounded": "eéií"
		}
	}
})
hungarian.word("ért","VERB")
hungarian.word("tanít","VERB")
hungarian.inflection({
	"name":"VERB"
	"schema": ["front.unrounded","front.rounded","back"]
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
