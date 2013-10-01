# Basic Language class
class Language
	constructor: (@id) ->
		# window[id.substr(0,1)+"w"] = @.words

	defaultOrthography: "latin"
	orthographies: {}
	words: {}
	inflections: {}
	rules: {} # Phrase structure rules

	word: (word, pos) -> 
		@words[word] = new Word(word, pos, @orthographies[@defaultOrthography])

	orthography: (orthography) ->
		id = @defaultOrthography
		@orthographies[id] = new Orthography(id, orthography)

	inflection: (inflection) ->
		@inflections[inflection.name] = new Inflection(inflection, false)

	inflect: (word, form) ->
		if @inflections[word.pos]
			@inflections[word.pos].inflect(word, form)
		else
			console.log("There are no inflections of the type "+word.type)

	phraseStructure: (fromThis, toThis) ->
		if @rules[fromThis]
			@rules[fromThis].push(toThis)
		else
			@rules[fromThis] = [toThis]

class Orthography
	constructor: (@id,orthography) -> 
		for key, letters of orthography
			@[key] = letters

	get: (path) ->
		split = path.split('.')
		temp = @
		for part in split
			temp = temp[part]
		return temp

class Word
	constructor: (@lemma, @pos, orthography) ->
		@o = orthography
		@vowel = @getVowelType(@lemma)

	count: (letters) ->
		@_match(letters, false)

	has: (letters) ->
		@_match(letters, true)

	_match: (letters, returnBoolean) ->
		re = new RegExp(letters.split('').join('|'),"gi")
		match = @lemma.match(re)
		if match? then matchCount = match.length else matchCount = 0
		if returnBoolean then !!matchCount else matchCount


	getVowelType: ->		
		back = @count(@o.vowels.back)
		frontR = @count(@o.vowels.front.rounded)
		frontUR = @count(@o.vowels.front.unrounded)
		switch Math.max(back,Math.max(frontR,frontUR))
			when back then "back"
			when frontR then "front.rounded"
			when frontUR then "front.unrounded"

class Inflection
	constructor: (inflection, isException) ->
		if isException then @parseException(inflection) else @parseInflection(inflection)

	#add support for letter change rules
	mergeSuff: (stem, suffix) ->
		stem + suffix.substr(1)

	mergeAff: (stem, affix) ->
		affix.substr(affix.length-1) + stem

	parseException: (inflection) ->
		 # Todo 

	parseInflection: (inflection) ->
		for key, value of inflection
			if key is "name" or key is "schema"
				@[key] = value
			else
				@[key] = {}
				if value.default
					for condition, value of inflection[key]
						parsedCondition = @_parseCondition(condition)
						@[key][parsedCondition] = @substitutor(value.form, value.replacements, inflection.schema)
				else
					@[key]["default"] = @substitutor(value.form, value.replacements, inflection.schema)
		return
			
	substitutor: (form, replacements, schema) ->
		(word) -> 
			ending = form
			for key, letters of replacements
				re = new RegExp(key,"gi")
				ending = ending.replace(re,letters[schema.indexOf(word.vowel)])
			return ending

	inflect: (word, form) ->
		inflector = "default"
		root = word.lemma
		for condition of @[form]
			if @_isDeleter(condition)
				re = new RegExp(condition.substr(1),"gi")
			else
				re = new RegExp(condition,"gi")
			match = word.lemma.match(re)
			if match? then inflector = condition

		if @_isDeleter(inflector)
			trimOff = inflector.substr(1,inflector.indexOf('$')-1)
			root = word.lemma.substr(0,word.lemma.indexOf(trimOff))

		inflection = @[form][inflector](word)
		if inflection.substr(0,1) is '+'
			@mergeSuff(root,inflection)
		else
			@mergeAff(root,inflection)

	_parseCondition: (condition) ->
		# end of word
		if @_isDeleter(condition)
			return condition + '$'
		return condition 

	_isDeleter: (condition) ->
		return condition.substr(0,1) is '-'

class PhraseStructure
	constructor: (@fromThis, @toThis) ->
		if rules[fromThis]
			rules[fromThis].push(toThis)
		else
			rules[fromThis] = [toThis]

	rules: []

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
		"default": {
			"form":"+Vk"
			"replacements":{"V":["e","ö","o"]}
		}
		"-ik": {
			"form":"+Vm"
			"replacements":{"V":["e","ö","o"]}
		}
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
