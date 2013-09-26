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

	FRONT_UR: 0
	FRONT_R: 1
	BACK: 2



	getVowelType: ->
		_countBackVowels = =>
			re = new RegExp(@o.vowels.back.split('').join('|'),"gi")
			match = @lemma.match(re)
			if match? then match.length else 0

		_countFrontRounded = =>
			re = new RegExp(@o.vowels.front.rounded.split('').join('|'),"gi")
			match = @lemma.match(re)
			if match? then match.length else 0

		_countFrontUnrounded = =>
			re = new RegExp(@o.vowels.front.unrounded.split('').join('|'),"gi")
			match = @lemma.match(re)
			if match? then match.length else 0
		
		back = _countBackVowels()
		frontR = _countFrontRounded()
		frontUR = _countFrontUnrounded()
		switch Math.max(back,Math.max(frontR,frontUR))
			when back then @BACK
			when frontR then @FRONT_R
			when frontUR then @FRONT_UR

	toLemma: (word) ->
		if word.substr(-2) is "ik" 
			{
				"lemma": word.substr(0,@lemma.length-2) 
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
			if key is "name"
				@[key] = value
			else
				@[key] = @substitutor(value.form, value.replacements)
		return
			
	substitutor: (form, replacements) ->
		(word) -> 
			ending = form
			for key, letters of replacements
				re = new RegExp(key,"gi")
				ending = ending.replace(re,letters[word.vowel])
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
