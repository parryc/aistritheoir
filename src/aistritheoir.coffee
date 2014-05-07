# Basic Language class
class Language
	constructor: (@id) ->
		# window[id.substr(0,1)+"w"] = @.words

	defaultOrthography: "latin"
	orthographies: { }
	words: { }
	inflections: { }
	inflectionsRaw: { } # Used for the analyzer
	inflectionExceptions: { } # Stores exceptions 
	exceptionMap: { } # Used for the analyzer
	markers: { }
	markersRaw: { } # Used for the analyzer
	derivationsRaw: [ ] # Used for the analyzer, to distinguish between tenses and derivational endings
	rules: { } # Phrase structure rules

	word: (word, pos) -> 
		@words[word] = new Word(word, pos, @orthographies[@defaultOrthography])
	
	# Used with analyzer and exceptions
	tempWord: (word, pos) ->
		new Word(word, pos, @orthographies[@defaultOrthography])
	
	orthography: (orthography) ->
		id = @defaultOrthography
		@orthographies[id] = new Orthography(id, orthography)
		Word::o = @orthographies[id]

	inflection: (inflection) ->
		# !!! It's an exception!
		if(inflection.word?)
			persons = ['1sg','2sg','3sg','1pl','2pl','3pl']
			for tense, groups of inflection when tense isnt 'word'
				verboseRoots = {}
				for group of groups
					root = inflection[tense][group]
					shortTense = tense.replace(/VERB-?/,"")
					@exceptionMap[root+'-'+shortTense] = {'root':inflection.word,'tense':shortTense,'person':group}

					if group is "all"
						personList = persons
					else
						personList = group.split(',')
					for person in personList
						verboseRoots[person] = root
				inflection[tense] = verboseRoots

			@inflectionExceptions[inflection.word] = inflection
		else
			@inflectionsRaw[inflection.name] = inflection
			@inflections[inflection.name] = new Inflection(inflection, false)

	copyInflection: (inflection, newName, overwrite) ->
		@inflections[newName] = {}
		@inflections[newName] = @_clone(@inflections[inflection])
		newInflection = @inflections[newName]
		newInflection.name = newName
		for key, prop of overwrite
			newInflection[key] = prop 

	inflect: (word, form, tense, derivations) ->
		exception = false
		fullException = false # e.g. doesn't need anymore person/tense marking
		if tense? and tense isnt ""
			fullInflection = word.pos + '-' + tense 
		else 
			fullInflection = word.pos
		
		inflection = @inflections[fullInflection]
		potentialException = @inflectionExceptions[word.lemma]
		if potentialException?
			# Only mark non-inflecting changed roots. For all intents and purposes, changed roots are just normal lemmas
			word = @tempWord(potentialException[fullInflection][form],word.pos)
			if word.lemma.slice(-1) isnt '+'
				word.exception = true 
			else
				word.lemma = word.lemma.replace("+","")

			# Check if full inflection or just modified root
		if inflection
			markerList = []
			derivationList = []
			if inflection.markers? and not word.exception
				for marker in inflection.markers
					markerList.push(@markers[marker])
			if derivations?
				for derivation in derivations
					derivationList.push(@markers[derivation])
				markerList = derivationList.concat(markerList)
			inflection.inflect(word, form, markerList)
		else
			console.log("There are no inflections of the type "+word.type)

	marker: (marker, isDerivation) ->
		@markersRaw[marker.name] = marker
		if isDerivation
			@derivationsRaw[marker.order] = marker
		@markers[marker.name] = new Marker(marker)


	phraseStructure: (fromThis, toThis) ->
		if @rules[fromThis]
			@rules[fromThis].push(toThis)
		else
			@rules[fromThis] = [toThis]

	# From the CoffeeScript cookbook
	_clone: (obj) ->
		if not obj? or typeof obj isnt 'object'
			return obj
		newInstance = new obj.constructor()
		for key of obj
			newInstance[key] = @_clone obj[key]
		return newInstance


class Orthography
	constructor: (@id,orthography) -> 
		letterSet = []
		for key, letters of orthography
			@[key] = letters

	get: (path) ->
		split = path.split('.')
		temp = @
		for part in split
			temp = temp[part]
		return temp

	getRegExp: (path) ->
		letterSet = []
		letters = @get(path)
		ngraphs = letters.match(/\(([^\()])*\)/gi)
		if ngraphs?
			for g in ngraphs
				# Remove parens
				letterSet.push(g.substr(1,g.length-2))
				letters = letters.replace(g,"")
		return letterSet.concat(letters.split('')).join('|')


class Word
	constructor: (@lemma, @pos, orthography) ->
		@o = orthography
		# @vowel = @getVowelType(@lemma)
		for attribute, rule of @attributes
			@[attribute] = @[rule](@lemma)

	setup: (rules, attributes, schemaMap) ->
		Word::schema = schemaMap
		Word::attributes = attributes

		for name, rule of rules
			@buildProperty(name, rule)

	# Only supports one function rules
	# if it starts with a _ it's a built in rule
	buildProperty: (name, rule) ->
		parts = rule.split(/of/gi)
		funct = parts[0].replace(/\s/gi,'')
		inputs = parts[1].replace(/\s/gi,'').split(/,/gi)

		if inputs.length > 1
			input = []
			for part in inputs
				el = part.split(/:/gi)
				input.push(
					@_curry(Word::[el[0]],el[1])
				)

		else
			el = part.split(/:/gi)
			input = @_curry(Word::[el[0]],el[1])

		Word::[name] = @_curry(Word::[funct],input)


	has: (letters) ->
		@_match(letters, true, @lemma)

	_count: (letters, lemma) ->
		Word::_match(letters, false, lemma)

	_match: (letters, returnBoolean, lemma) ->
		re = new RegExp(@o.getRegExp(letters),"gi")
		match = lemma.match(re)
		if match? then matchCount = match.length else matchCount = 0
		if returnBoolean then !!matchCount else matchCount

	_max: (array) ->
		return Math.max(Math,array)

	_labeledMax: (array, lemma) ->
		max = array[0](lemma)
		maxIdx = 0
		for funct, idx in array
			newCount = funct(lemma)
			if newCount > max
				maxIdx = idx
				max = newCount
		@schema[maxIdx]


	_min: (array) ->
		return Math.min(Math.array)

	# From the Javascript Collection
	_curry: (fn) ->
		args = Array::slice.call(arguments, 1)
		return ->
			return fn.apply(@, args.concat(
				Array::slice.call(arguments,0)
			))
	# getVowelType: ->		
	# 	back = @count("vowels.back")
	# 	frontR = @count("vowels.front.rounded")
	# 	frontUR = @count("vowels.front.unrounded")
	# 	switch Math.max(back,Math.max(frontR,frontUR))
	# 		when back then "back"
	# 		when frontR then "front.rounded"
	# 		when frontUR then "front.unrounded"

class Inflection
	constructor: (inflection, isException) ->
		if isException then @parseException(inflection) else @parseInflection(inflection)

	#add support for letter change rules
	mergeSuff: (stem, suffix) ->
		suffix = suffix.replace("+","").replace("_"," ")
		stem + suffix

	mergeAff: (stem, affix) ->
		affix = affix.replace("+","").replace("_"," ")
		affix + stem

	parseException: (inflection) ->
		 # Todo 

	parseInflection: (inflection) ->
		for key, value of inflection
			if key in ["name","schema","markers","preprocess","coverb"] 
				@[key] = value
			else
				@[key] = { }

				# If there are conditional rules
				if value.default
					for condition, value of inflection[key]
						parsedCondition = @_parseCondition(condition)
						@[key][parsedCondition] = @substitutor(value.form, value.replacements, inflection.schema)
				else
					@[key]["default"] = @substitutor(value.form, value.replacements, inflection.schema)
		return
			
	substitutor: (form, replacements, schema) ->
		(word) => 
			ending = form
			schemaPosition = schema.indexOf(word.vowel)
			if schemaPosition is -1
				schemaPosition = @_findValidSchema(word.vowel, schema)
				if schemaPosition is -1
					console.log("The word does not fit in this schema")					

			for key, letters of replacements
				re = new RegExp(key,"gi")
				ending = ending.replace(re,letters[schemaPosition])
			return ending

	inflect: (word, form, markerList) ->
		inflector = "default"
		root = word.lemma

		if @.preprocess and (@.preprocess.for.indexOf(form) isnt -1 or @.preprocess.for is 'all')
				root = @_assimilate(@.preprocess.do,root)

		for condition of @[form]
			if @_isDeleter(condition)
				re = new RegExp(condition.substr(1),"gi")
			else
				re = @_expandCondition(word, condition)
			match = root.match(re)
			if match? then inflector = condition

		if @_isDeleter(inflector)
			trimOff = inflector.substr(1,inflector.indexOf('$')-1)
			root = word.lemma.substr(0,word.lemma.indexOf(trimOff))
		
		marks = ''
		for marker in markerList
			markData = marker.mark(word, form)
			if markData.replaceThis is ''
				root += markData.withThis
			else
				root = root.replace(markData.replaceThis, markData.withThis)
			
		if not word.exception
			inflection = @[form][inflector](word)
			root = @_combine(root, inflection)
		if @.coverb?
			root = @_combine(root,@.coverb)
		return root

	# combine the root and the inflection
	_combine: (root, inflection) ->
		if inflection.substr(0,1) is '+' or inflection.substr(0,1) is '_'
			@mergeSuff(root,inflection)
		else
			@mergeAff(root,inflection)


	# Returns a regular expression object
	_expandCondition: (word, condition) ->
		# Replace groups with correct orthography
		expandedCondition = condition
		groups = condition.match(/'([^']*)'/gi)
		if groups?
			for group in groups
				groupRegexp = "("+word.o.getRegExp(group.replace(/'/gi,""))+")"
				expandedCondition = expandedCondition.replace(group,groupRegexp)

		re = new RegExp(expandedCondition,"gi")

	# Parse the condition rules
	_parseCondition: (condition) ->
		# end of word
		if @_isDeleter(condition)
			return condition + '$'

		# Parse all the language features!

		# only (X)YZ => ^(X)?(Y)(Z)$ 

		restriction = condition.match(/only\s(.*)/i)
		if restriction?
			restriction = restriction.pop()
			optionals = restriction.match(/\([^()]*\)/gi)
			for option in optionals
				condition = "^"+restriction.replace(option, option.substring(1,option.length-1)+"?")+"$"

		# after X => (X)$
		condition = condition.replace(/after(.*)/gi,"($1)$")

		# exceptions[...] => ^(...|...)$
		exceptions = condition.match(/exceptions\[(.*)\]/i)
		if exceptions? 
			condition = condition.replace(exceptions[0],"^("+exceptions[1].replace(/\s/gi,"|")+")$")

		# + => (blank)
		condition = condition.replace(/\+/gi,"")

		#  xN => {N;}
		condition = condition.replace(/x(\d)/gi,"{$1}")

		# or => |
		condition = condition.replace(/\sor\s/gi,"|")

		# return removed spaces version
		return condition.replace(/\s/gi,"")


	_isDeleter: (condition) ->
		return condition.substr(0,1) is '-'

	# word category, for example, would be the vowel type in Hungarian 
	_findValidSchema: (wordCategory, schema) ->
		valid = ''
		while wordCategory isnt ''
			wordCategory = wordCategory.substr(0,wordCategory.lastIndexOf('.'))
			idx = schema.indexOf(wordCategory) 
			if schema.indexOf(wordCategory) isnt -1
				return idx
		return valid

	# use underscore to indicate space 
	_assimilate: (rules, ending) ->
		rules = rules.split(',')
		for rule in rules
			rule = rule.trim()
			rule.replace(/\+/gi,"")
			if rule.indexOf('remove') is 0
				ending = ending.replace(rule.slice("remove".length+1),"")
			if rule.indexOf('double') is 0
				ending = ending.substr(0,1)+ending

		return ending.replace(/\s/gi,"").replace(/_/gi," ")

class Marker extends Inflection
	constructor: (marker) ->
		@.conditions = { }
		for key, value of marker
			if key is "name" or key is "schema"
				@[key] = value
			else
				parsedCondition = @_parseCondition(key)
				@.conditions[parsedCondition] = { }
				@.conditions[parsedCondition].marker = @substitutor(value.form, value.replacements, marker.schema)
				@.conditions[parsedCondition].exceptions =  value.exceptions

				overrides = value.overrides
				if overrides
					@.conditions[parsedCondition].overrides = { }
					for key, override of overrides
						@.conditions[parsedCondition].overrides[key] = @substitutor(override.form, override.replacements, marker.schema)

				if value.assimilation then @.conditions[parsedCondition].assimilation = value.assimilation

		return

	getException: (word) ->
		for condition, data of @conditions
			if data.exceptions? and word in data.exceptions
				return condition
		return ''

	mark: (word, form) ->
		rule = ""
		replaceThis = ""
		root = word.lemma
		ending = '' 
		for condition, data of @conditions when condition isnt "default"
			# Match only one rule - in case some rules are subsets of other rules
			if rule is ''
				re = @_expandCondition(word, condition)
				match = root.match(re)
				if match?
					ending = match[0]
					rule = condition
		if rule is ''
			rule = "default"

		potentialException = @getException(root)
		if potentialException isnt ""
			rule = potentialException

		if @conditions[rule].overrides?[form]?
			mark = @conditions[rule].overrides[form](word)
		else
			mark = @conditions[rule].marker(word)
		
		withThis = @_combine('', mark)

		if @conditions[rule].assimilation
			replaceThis = ending
			withThis = @_assimilate(@conditions[rule].assimilation,ending)+withThis

		return {'replaceThis': replaceThis, 'withThis': withThis;}



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
