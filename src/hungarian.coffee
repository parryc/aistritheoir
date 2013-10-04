# Basic Language class
class Language
	constructor: (@id) ->
		# window[id.substr(0,1)+"w"] = @.words

	defaultOrthography: "latin"
	orthographies: {}
	words: {}
	inflections: {}
	markers: {}
	rules: {} # Phrase structure rules

	word: (word, pos) -> 
		@words[word] = new Word(word, pos, @orthographies[@defaultOrthography])

	orthography: (orthography) ->
		id = @defaultOrthography
		@orthographies[id] = new Orthography(id, orthography)

	inflection: (inflection) ->
		@inflections[inflection.name] = new Inflection(inflection, false)

	inflect: (word, form, additional) ->
		if additional?
			fullInflection = word.pos + '-' + additional 
		else 
			fullInflection = word.pos
		
		inflection = @inflections[fullInflection]
		if inflection
			markerList = []
			if inflection.markers?
				for marker in inflection.markers
					markerList.push(@markers[marker])
			inflection.inflect(word, form, markerList)
		else
			console.log("There are no inflections of the type "+word.type)

	marker: (marker) ->
		@markers[marker.name] = new Marker(marker)

	phraseStructure: (fromThis, toThis) ->
		if @rules[fromThis]
			@rules[fromThis].push(toThis)
		else
			@rules[fromThis] = [toThis]

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
		@vowel = @getVowelType(@lemma)

	count: (letters) ->
		@_match(letters, false)

	has: (letters) ->
		@_match(letters, true)

	_match: (letters, returnBoolean) ->
		re = new RegExp(@o.getRegExp(letters),"gi")
		match = @lemma.match(re)
		if match? then matchCount = match.length else matchCount = 0
		if returnBoolean then !!matchCount else matchCount


	getVowelType: ->		
		back = @count("vowels.back")
		frontR = @count("vowels.front.rounded")
		frontUR = @count("vowels.front.unrounded")
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
			if key is "name" or key is "schema" or key is "markers"
				@[key] = value
			else
				@[key] = {}

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
		for condition of @[form]
			if @_isDeleter(condition)
				re = new RegExp(condition.substr(1),"gi")
			else
				re = @_expandCondition(word, condition)
			match = word.lemma.match(re)
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
			# marks += marker.mark(word, form)

		# root += marks

		inflection = @[form][inflector](word)
		return @_combine(root, inflection)


	# combine the root and the inflection
	_combine: (root, inflection) ->
		if inflection.substr(0,1) is '+'
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

		# after X => (X)$
		condition = condition.replace(/after(.*)/gi,"($1)$")

		# exceptions[...] => ^(...|...)$
		exceptions = condition.match(/exceptions\[(.*)\]/i)
		if exceptions? 
			condition = condition.replace(exceptions[0],"^("+exceptions[1].replace(/\s/gi,"|")+")$")

		# + => (blank)
		condition = condition.replace(/\+/gi,"")

		#  xN => {N}
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

	_assimilate: (rules, ending) ->
		rules = rules.split(',')
		for rule in rules
			rule = rule.trim()
			rule.replace(/\+/gi,"")
			if rule.indexOf('remove') is 0
				ending = ending.replace(rule.slice("remove".length+1),"")
			if rule.indexOf('double') is 0
				ending = ending.substr(0,1)+ending
		return ending.replace(/\s/gi,"")

class Marker extends Inflection
	constructor: (marker) ->
		@.conditions = {}
		for key, value of marker
			if key is "name" or key is "schema"
				@[key] = value
			else
				parsedCondition = @_parseCondition(key)
				@.conditions[parsedCondition] = {}
				@.conditions[parsedCondition].marker = @substitutor(value.form, value.replacements, marker.schema)
				@.conditions[parsedCondition].exceptions =  value.exceptions

				overrides = value.overrides
				if overrides
					@.conditions[parsedCondition].overrides = {}
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
		rule = "default"
		replaceThis = ""
		root = word.lemma
		ending = '' 
		for condition, data of @conditions when condition isnt "default"
			re = @_expandCondition(word, condition)
			match = root.match(re)
			# Match only one rule - in case some rules are subsets of other rules
			if match? and rule isnt "default"
				ending = match[0]
				rule = condition

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
			console.log(ending)
			withThis = @_assimilate(@conditions[rule].assimilation,ending)

		return {'replaceThis': replaceThis, 'withThis': withThis}


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