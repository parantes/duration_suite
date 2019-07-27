# Parse American English segmentation
#
# Pablo Arantes <pabloarantes@protonmail.com>
#
# created: 2019-06-16
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
# can be represented by one character or a combination of two characters,
# listed below in regular expression notation.
#
# * 2-letter segments
# [aEeiou]R
# [aeo]I
# [ao]U
# [aiou]:
# tS
# dZ
#
# * 1-letter segments
# [@ADENSTZabdefghijklmnoprstuvwz]
#
# Parsing of the string consists of the following steps:
#
# 1. Start from the beginning of string.
# 2. Test for the presence of a segment represented by a 2-letter combination.
# 3. If true, set end of segment to index 2.
# 4. If false, segment is represent by a single character.
# 5. Test if character is an element of the one-character symbol set.
# 6. If false, save invalid character in string variable that can be used
#    in an error message to the user.
#
# = Output =
# Parsed segments and illegal segments are stored as array elements.
#
# = Example usage = 
# lab$ = ""
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

	# 2-letter combinations
	.two$ = "^([aEeiou]R|[aeo]I|[ao]U|[aiou]:|tS|dZ)"
	# 1-letter symbols
	.one$ = "^[@ADENSTZabdefghijklmnoprstuvwz]{1}"

