procedure parse: .label$
# Parse Brazilian Portuguese segmentation (Ortofon style)
#
# Pablo Arantes <pabloarantes@protonmail.com>
#
# modified: 2019-06-13
#
# changelog:
# - 2019-06-15: modern procedure syntax,
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
# [eo]h[IU]
# [aA]NU
# [ao]NI
#
# * 2-letter segments
# [aAeEiIoOuU]N
# [eolnsz]h
# [IU][AEO]
# [aeIouU]I
# [aeiIoU]U
#
# * 1-letter segments
# [aAbdeEfgiIklmnoOprRsStuUvz]
#
# Parsing of the string consists of the following steps:
#
# 1. Start from the end of the string to be parsed
# 2. Test for presence of a segment represented by a 3-letter combination
# 3. If true, set the start of the segment to index length - 3
# 4. If false, test for the presence s segment represented by a 2-letter combination
# 5. If true, set end of segment to index length - 2
# 6. If false, segment is represent by a single character
# 7. Test if character is an element of one-character Ortofon symbol set 
# 8. If false, save invalid character in string variable that can be used
#    in an error message to the user.
#
# = Output =
# Parsed segments and illegal segments are stored as array elements.
#
# = Example usage =
# lab$ = "aNUpOshehI$s!"
# include parse_por_br_ortofon.praat
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

	## Regular expressions used to search a 2- or 3-letter combination
	## at the beginning of the string
	# 3-letter combinations
	.three$ = "([eo]h[IU]|[aA]NU|[ao]NI)$"
	# 2-letter combinations
	.two_N_h$ = "([aAeEiIoOuU]N|[eolnsz]h)$"
	.two_V$ = "([aeIouU]I|[aeiIoU]U|[IU][AEO])$"
	# 1-letter symbols
	.one$ = "[aAbdeEfgiIklmnoOprRsStuUvz]{1}$"

	# Error counter
	.errors = 0

	# Number of Ortofon segments in label$ string
	.nseg = 0

	# Initial label$ size
	.len = length(.label$)

	while .len > 0

		# Define the size of the current chunk to be analyzed
		.three = index_regex(.label$, .three$)
		.two_N_h = index_regex(.label$, .two_N_h$)
		.two_V = index_regex(.label$, .two_V$)
		.one = index_regex(.label$, .one$)

		if .three <> 0
			#.start = .len - 3
			.parsed = 3
		elsif .two_N_h <> 0
			#.start = .len - 2
			.parsed = 2
		elsif .two_V <> 0
			#.start = .len - 2
			.parsed = 2
		else
			# Either we have a legal one-character segment
			# or an illegal character
			#.start = .len - 1
			.parsed = 1
		endif

		# Extract the current parsed string 
		.current$ = right$(.label$, .parsed)

		# If no valid sequences are found,
		# the parsed character in label$ is illegal
		is_legal = .three + .two_N_h + .two_V + .one

		if is_legal <> 0
			.nseg += 1
			.segments$[.nseg] = .current$
		else
			.errors += 1
			.errors$[.errors] = .current$
		endif

		# Remove current parsed chunk from label$
		.label$ = .label$ - .current$
		.len = length(.label$)
	endwhile
endproc

