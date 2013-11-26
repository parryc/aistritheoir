class Analyzer
	constructor: (@language) ->
		

		@persons = ['1sg','2sg','3sg','1pl','2pl','3pl']
		@inflectionEndings = []
		@inflections = (inflections for inflections of language.inflectionsRaw)
		@markers = language.markersRaw

		for inflection in @inflections
			verb = language.inflectionsRaw[inflection]
			schemaLength = verb.schema.length
			@inflectionEndings[inflection] = []
			for person in @persons
				@inflectionEndings[inflection][person] = []
				current = verb[person]
				if not current['default']
					@inflectionEndings[inflection][person] = @replace(current, schemaLength)
				else
					for rule of current
						@inflectionEndings[inflection][person] = @inflectionEndings[inflection][person].concat(@replace(current[rule], schemaLength))
	
	replace: (sub, schemaLength) ->
		list = []

		replacements = sub['replacements']
		schemaPosition = 0

		while schemaPosition < schemaLength
			ending = sub['form']
			for key, letters of replacements
				re = new RegExp(key,"gi")
				ending = ending.replace(re,letters[schemaPosition])
			list.push(ending.replace('+','').replace('_',' '))
			schemaPosition++
		list.filter (value, index, self) ->
			self.indexOf(value) is index

	getMorphology: (word) ->
		potentials = @getPerson(word)
		@getTense(potentials)

	getPerson: (word) ->
		min = 0
		currPers = "error"
		results = []
		uninflected = []
		for inflection in @inflections
			for person in @persons
				minRoot = 'superlongsuperlongomfgomfg'
				potentialEnding = ''
				for ending in @inflectionEndings[inflection][person]
					potentialRoot = word.substring(0,word.length-ending.length)
					wordEnding = word.substring(word.length-ending.length)
					# we're going for the shortest possible root.  Because.
					if wordEnding is ending and potentialRoot.length < minRoot.length
						minRoot = potentialRoot
						potentialEnding = ending
				if ending.length isnt 0 and minRoot isnt 'superlongsuperlongomfgomfg'
					results.push({'original': word, 'person':person,'root':minRoot, 'inflection': inflection, 'hasMarkedInflection':true})
				else
					uninflected.push({'original': word, 'person':person,'root':minRoot, 'inflection': inflection, 'hasMarkedInflection':false})

		if results.length is 0
			results = uninflected
		return results

	getTense: (potentials) ->
		result = { }
		resultList = []
		seenPairs = []
		ambiguous = false
		hasException = false

		for potential in potentials
			tense = potential.inflection.split('-').pop()

			if tense is 'VERB'
				mark = ''
				tense = ''
			else
				mark = @language.inflections[potential.inflection].markers?[0]

			marker = @markers[mark]
			
			root = potential.root
			if marker?
				# keep from having duplicate roots appear
				# seenPairs = []
				for rule, info of marker when rule isnt 'schema' and rule isnt 'name'
					
					if info.assimilation?
						potential.root = @_unassimilate(info.assimilation,root)
					else
						potential.root = root.substring(0,root.length-info.form.length+1)

					checkDerivation = @getDerivationalInformation(potential.root)
					potential.root = checkDerivation.root
					derivations = checkDerivation.derivations

					exception = @_getException(potential, tense)
					if exception.valid
						potential = exception
						tense = exception.tense
						hasException = true

					if potential.root+"-"+tense not in seenPairs and @language.inflect(@language.tempWord(potential.root, "VERB"), potential.person, tense, derivations) is potential.original
						resultList.push({'root': potential.root, 'person': potential.person, 'tense': tense, 'derivations':derivations, 'exception':false});
						seenPairs.push(potential.root+"-"+tense)

			# Checks for tenses that don't have additional markers (e.g. Hungarian present tense)
			else
				checkDerivation = @getDerivationalInformation(potential.root)
				potential.root = checkDerivation.root
				derivations = checkDerivation.derivations

				exception = @_getException(potential, tense)
				if exception.valid
					potential = exception
					tense = exception.tense
					hasException = true

				if potential.root+"-"+tense not in seenPairs and @language.inflect(@language.tempWord(potential.root, "VERB"), potential.person, tense, derivations) is potential.original
					resultList.push(
						{'root': potential.root, 'person': potential.person, 'tense': tense, 'derivations':derivations, 'exception':hasException }
					)
					seenPairs.push(potential.root+"-"+tense)

		if resultList.length > 1
			ambiguous = true

		# # Look for exceptions among the resultList.  They may be tagged with the wrong person and tense

		# for result in resultList
		# 	console.log(result)
			# exception = @language.exceptionMap[result.root]
			# console.log(@language.exceptionMap)
			# if exception? and not result.hasException
			# 	result.root = exception.root

		return {'ambiguous': ambiguous, 'results': resultList}

	getDerivationalInformation: (root) ->
		# derivations are ordered (free ordering is todo?)
		# so step through the list. If the ending fits, then add that derivation to the list
		derivationsList = []
		potentialRoot = root

		# reverse mutates - copy the array so it's always the same order for subsequent loops
		for derivation in @language.derivationsRaw.slice(0).reverse()
			for rule, info of derivation when rule isnt 'schema' and rule isnt 'name' and rule isnt 'order'
				replacements = @replace(info,derivation.schema.length)
				hasMatch = false
				endingLength = 0
				# It should only ever match one, since it'll only be valid for one part of the schema
				for replacement in replacements
					re = new RegExp(replacement+"$","gi")
					match = potentialRoot.match(re)
					if match?
						hasMatch = true
						endingLength = match[0].length
				if hasMatch
					derivationsList.unshift(derivation.name)
					potentialRoot = potentialRoot.substring(0,potentialRoot.length-endingLength)
					if info.assimilation?
						potentialRoot = @_unassimilate(info.assimilation, potentialRoot)

		{"root":potentialRoot, "derivations":derivationsList}

	# use underscore to indicate space 
	_unassimilate: (rules, word) ->
		rules = rules.split(',').reverse()
		for rule in rules
			rule = rule.trim()
			rule.replace(/\+/gi,"")
			if rule.indexOf('remove') is 0
				word = word + rule.slice("remove".length+1)
			if rule.indexOf('double') is 0
				end = word.match(/(\w)(\1+)/g)
				if end?
					end = end.pop()
					word = word.replace(end,end.substring(end.length-1))

		return word.replace(/\s/gi,"").replace(/_/gi," ")

	_getException: (potential, tense) ->
		if @language.exceptionMap[potential.original+'-'+tense]?
		 	# console.log(@language.exceptionMap[potential.original+'-'+tense])
		 	potential.root = potential.original
		# console.log(@language.exceptionMap[potential.original+'-'+tense])
		exception = @language.exceptionMap[potential.root+'-'+tense]
		# console.log(exception)


		if potential.hasMarkedInflection
			exception = @language.exceptionMap[potential.root+'+-'+tense]

		if exception?
			potential.valid = true
			potential.root = exception.root
			potential.tense = tense
			if not potential.hasMarkedInflection
				potential.person = exception.person
		return potential
		
if typeof module isnt 'undefined' and module.exports?
    exports.Analyzer = Analyzer