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
		@getTense(potentials)

	getPerson: (word) ->
		min = 0
		currPers = "error"
		results = []
		baseInflections = []
		for inflection in @inflections
			for person in @persons
				if @inflectionEndings[inflection][person].length is 0
					baseInflections.push({'person':person,'root':word, 'inflection': inflection})
				for ending in @inflectionEndings[inflection][person]
					potentialRoot = word.substring(0,word.length-ending.length)
					wordEnding = word.substring(word.length-ending.length)
					ld = @levenshteinDistance(wordEnding,ending)
					adjLevenDist = (if ld is 0 then (-10)-ending.length else ld-ending.length)
					if adjLevenDist <= -10
						if adjLevenDist < min
							results.push({'original': word, 'person':person,'root':potentialRoot, 'inflection': inflection})
						else
							results.unshift({'original': word, 'person':person,'root':potentialRoot, 'inflection': inflection})
							min = adjLevenDist
							currPers = person
		return results

	getTense: (potentials) ->
		for potential in potentials
			tense = potential.inflection.split('-').pop()
			if tense is 'VERB'
				tense = ''
			marker = @markers[tense]
			if marker?
				root = potential.root
				found = false
				for rule, info of marker when rule isnt 'schema' and rule isnt 'name'
					potentialRoot = root.substring(0,root.length-info.form.length-1)
					if not found and @language.inflect(@language.tempWord(potentialRoot, "VERB"), potential.person, tense) is potential.original
						console.log(potentialRoot + ' ' + potential.person + " " + tense)
						found = true
				# 	replacements = @replace(info, 1)
				# 	for replacement in replacements when root.match(new RegExp(replacement, 'gi'))
				# 		console.log("root: " + root.substring(0,root.length-replacement.length) + " marker " + marker.name + " person " + potential.person)
				# 		if rule.assimilate?
				# 			console.log(@_unassimilate(rule.assimilate,root))

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