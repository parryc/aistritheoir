class Analyzer
	constructor: (@language) ->
		# Used for calculating Levenshtein distance
		# From TheSpanishInquisition http://jsperf.com/levenshtein-distance/5
		@matrix = []
		i = 0
		while i < 32
			@matrix[i] = [i]
			@matrix[i].length = 32
			i++
		i = 0

		while i < 32
			@matrix[0][i] = i
			i++

		@levenshteinDistance = (__this, that, limit) ->
			thisLength = __this.length
			thatLength = that.length
			return limit or 16 if Math.abs(thisLength - thatLength) > (limit or 16)
			return thatLength if thisLength is 0
			return thisLength if thatLength is 0
			# Calculate @matrix.
			i = 1
			while i <= thisLength
				this_i = __this[i - 1]
				j = 1
				while j <= thatLength
					# Check the jagged ld total so far
					if i is j and @matrix[i][j] > 4
						return thisLength
					that_j = that[j - 1]
					cost = (if (this_i is that_j) then 0 else 1) # Step 5
					# Calculate the minimum (much faster than Math.min(...)).
					min = @matrix[i - 1][j] + 1 # Deletion.
					min = t  if (t = @matrix[i][j - 1] + 1) < min # Insertion.
					min = t  if (t = @matrix[i - 1][j - 1] + cost) < min # Substitution.
					@matrix[i][j] = min # Update @matrix.
					j++
				i++
			@matrix[thisLength][thatLength]


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
			list.push(ending.replace('+',''))
			schemaPosition++
		list.filter (value, index, self) ->
			self.indexOf(value) is index

	getMorphology: (word) ->
		potentials = @getPerson(word)
		# console.log(potentials)
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
					ld = @levenshteinDistance(wordEnding,ending)
					# we're going for the shortest possible root.  Because.
					if ld is 0 and potentialRoot.length < minRoot.length
						minRoot = potentialRoot
						potentialEnding = ending
				if ending.length isnt 0 and minRoot isnt 'superlongsuperlongomfgomfg'
					results.push({'original': word, 'person':person,'root':minRoot, 'inflection': inflection})
				else
					uninflected.push({'original': word, 'person':person,'root':minRoot, 'inflection': inflection})

		if results.length is 0
			results = uninflected
		return results

	getTense: (potentials) ->
		result = {}
		found = false
		for potential in potentials
			tense = potential.inflection.split('-').pop()
			if tense is 'VERB'
				tense = ''
			marker = @markers[tense]
			root = potential.root
			if marker?
				for rule, info of marker when rule isnt 'schema' and rule isnt 'name'
					potentialRoot = root.substring(0,root.length-info.form.length-1)
					if not found and @language.inflect(@language.tempWord(potentialRoot, "VERB"), potential.person, tense) is potential.original
						result.root = potentialRoot
						result.person = potential.person
						result.tense = tense
						found = true
			# Checks for tenses that don't have additional markers (e.g. Hungarian present tense)
			else if not found and @language.inflect(@language.tempWord(root, "VERB"), potential.person, tense) is potential.original
				result.root = root
				result.person = potential.person
				result.tense = tense
				found = true

		return result

	# use underscore to indicate space 
	_unassimilate: (rules, word) ->
		rules = rules.split(',').reverse()
		for rule in rules
			rule = rule.trim()
			rule.replace(/\+/gi,"")
			if rule.indexOf('remove') is 0
				word = word + rule.slice("remove".length+1)
			if rule.indexOf('double') is 0
				end = word.match(/(\w)(\1+)/g).pop()
				word = word.replace(end,end.substring(end.length+1))

		return word.replace(/\s/gi,"").replace(/_/gi," ")
		
if typeof module isnt 'undefined' and module.exports?
    exports.Analyzer = Analyzer