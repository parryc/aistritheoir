class Analyzer
	constructor: (language) ->
		# Used for calculating Levenshtein distance
		# From TheSpanishInquisition http://jsperf.com/levenshtein-distance/5
		@matrix = []
		i = 0
		while i < 64
			@matrix[i] = [i]
			@matrix[i].length = 64
			i++
		i = 0

		while i < 64
			@matrix[0][i] = i
			i++

		@levenshteinDistance = (__this, that, limit) ->
			thisLength = __this.length
			thatLength = that.length
			return limit or 32 if Math.abs(thisLength - thatLength) > (limit or 32)
			return thatLength if thisLength is 0
			return thisLength if thatLength is 0

			# Calculate @matrix.
			i = 1
			while i <= thisLength
				this_i = __this[i - 1]
				
				j = 1
				while j <= thatLength
				  
					# Check the jagged ld total so far
					return thisLength  if i is j and @matrix[i][j] > 4
					that_j = that[j - 1]
					cost = (if (this_i is that_j) then 0 else 1) # Step 5
					# Calculate the minimum (much faster than Math.min(...)).
					min = @matrix[i - 1][j] + 1 # Deletion.
					min = t  if (t = @matrix[i][j - 1] + 1) < min # Insertion.
					min = t  if (t = @matrix[i - 1][j - 1] + cost) < min # Substitution.
					@matrix[i][j] = min # Update @matrix.
					++j
			++i
			@matrix[thisLength][thatLength]


		@persons = ['1sg','2sg','3sg','1pl','2pl','3pl']
		@markers = []
		verb = language.inflections['VERB']
		for person in @persons
			current = verb[person]
			console.log(current)
			@markers[person] = [];
			if not current['default']
				@markers[person] = @replace(current)
			else
				for rule of current
					@markers[person] = @markers[person].concat(@replace(current[rule]))
	

	replace: (sub) ->
		list = []
		for key, letters of sub['replacements']
			re = new RegExp(key, "gi")
			for letter in letters
				ending = sub['form'].replace(re, letter).replace('+','')
				list.push(ending)
		return list;

	getPerson: (word) ->
		min = 0
		currPers = "error"
		console.log(@markers)
		for person in @persons
			for ending in @markers[person]
				console.log(ending)
				wordEnding = word.substring(word.length-ending.length)
				ld = @levenshteinDistance(wordEnding,ending)
				adjLevenDist = (if ld is 0 then (-10)-ending.length else ld-ending.length)
				if adjLevenDist < min
					min = adjLevenDist
					currPers = person
		return currPers
		
if typeof module isnt 'undefined' and module.exports?
    exports.Analyzer = Analyzer