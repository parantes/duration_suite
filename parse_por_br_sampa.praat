procedure parse: .label$
# Parse Brazilian Portuguese segmentation (SAMPA style)
#
# Pablo Arantes <pabloarantes@protonmail.com>
#
# modified: 2019-06-13
#
# changelog:
# - 2017-04-12: modern procedure syntax, two- or three-letter segments 
#   not being recognized when in initial position 
#
# = Input parameters =
# .label$: string of characters to be parsed
#
# = Output variables = 
# .segments$: array holding parsed segments
# .nseg: segments$ array size
# .errors$: array holding illegal characters in label
# .errors: errors$ array size
#
# = How it works =
# The procedure will parse a phonetic label comprised of a string of
# at least one ASCII character into phonetic segments. Phonetic segments
# can be represented by one character or a combination of two or three
# characters, listed below.
# 
# * 3-letter segments
# [ao]Nj
# [aA]Nw
#
# * 2-letter segments
# [aeouEIOU]j
# [aeioEOU]w
# [IU][@&]
# [aeiouAIU&@]N
#
# Parsing of the string consists of the following steps:
#
# 1. Start from the beginning of string.
# 2. Test for presence of a segment represented by a 3-letter combination.
# 3. If true, set end of segment to index 3.
# 4. If false, test for the presence of a segment represented by a 2-letter
#    combination.
# 5. If true, set end of segment to index 2.
# 6. If false, segment is represent by a single character.
# 7. Test if character is an element of one-character Sampa-PB symbol set.
# 8. If false, save invalid character in string variable that can be used
#    in an error message to the user.
#
# = Output =
# Parsed segments and illegal segments are stored as array elements.
#
# = Example usage = 
# lab$ = "paNjtRiw!"
# include parse_por_br_sampa.praat
# @parse: lab$
# 
# writeInfoLine: "Input: ", lab$
# appendInfoLine: "Segments: ", parse.nseg
# for i to parse.nseg
# 	appendInfoLine: parse.segments$[i]
# endfor
#
# appendInfoLine: "Errors: ", parse.errors
# for i to parse.errors
# 	appendInfoLine: parse.errors$[i]
# endfor

	## Regular expressions used to search for 2- or 3-letter combination
	## at the beginning of a string
	# 3-letter combinations
	.three$ = "^([ao]Nj|[aA]Nw)"
	# 2-letter combinations
	.two$ = "^([aeouEIOU]j|[aeioEOU]w|[IU][@&6]|[aeiouAIU&@]N)"
	# 1-letter symbols
	.one$ = "^[ptkbdgfsSvzZ54mnJrXlLRDTaeiouEOAIU&@6]{1}"

	# Error counter
	.errors = 0

	# Number of Sampa-PB segments in label$ string
	.nseg = 0

	# Initial label$ size
	.len = length(.label$)

	while .len > 0

		# Define the size of the current chunk to be analyzed
		.three = index_regex(.label$, .three$)
		.two = index_regex(.label$, .two$)
		.one = index_regex(.label$, .one$)

		if .three = 1
			.end = 3
		elsif .two = 1
			.end = 2
		else
			# Either we have a legal one-character segment
			# or an illegal character
			.end = 1
		endif

		# Extract the current parsed string 
		.current$ = left$(.label$, .end)

		# If no valid sequences are found,
		# First character in label$ is illegal
		is_legal = .three + .two + .one

		if is_legal <> 0
			.nseg += 1
			.segments$[.nseg] = .current$
		else
			.errors += 1
			.errors$[.errors] = .current$
		endif

		# Remove current parsed chunk from label$
		.label$ = replace$(.label$, .current$, "", 1)
		.len = length(.label$)
	endwhile

endproc
