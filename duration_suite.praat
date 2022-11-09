# duration_suite.praat
# --------------
# A script for duration extraction
#
# Author: Pablo Arantes <pabloarantes@protonmail.com>
#
# Purpose:
# Takes one or multiple segmented TextGrid files and extracts duration values
# in milliseconds for non-empty intervals in a user-specified interval tier.
# The script also offers the following three transformations
# to the raw duration contour. The user chooses which ones are applied:
# 1. Normalize raw duration contour by a z-score transformation;
# 2. Smooth the contour by applying one of two moving average techniques;
# 3. Find peaks in duration contour.
#
# Input:
# Previously segmented TextGrid files.
#
# Output:
# A report in tabular format listing duration for each labelled interval in
# the input TextGrid files.
#
# Comments:
# Script file and user files don't need to be in the same file directory.
#
# Copyright (C) 2008-2022  Pablo Arantes
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

form duration_suite
	comment "Single file": user will be prompted to select a TextGrid file.
	comment "Multiple files": user has to provide a folder containing TextGrid files.
	optionmenu Mode: 1
		button Multiple files
		button Single file
	comment Directory where the TextGrid files are:
	sentence Folder /path/to/textgrids/
	comment Tier from which duration should be extracted:
	integer Tier 2
	optionmenu Language: 1
		button por_br_sampa
		button por_br_ortofon
		button eng_us
		button spa
	comment Choice of smoothing method
	optionmenu Smoothing_method: 1
		button 5-point Moving Average
		button Exponential Smoothing
	real Alpha 0.4
	comment What information should be in the report:
	boolean Normalized_duration 1
	boolean Smoothed_normalized_duration 1
	boolean Stress_group_boundary 1
	comment Report folder and name
	sentence Report /path/to/report/dur.txt
endform

# Shorten GUI variable name
do_z = normalized_duration
do_sm = smoothed_normalized_duration
do_bd = stress_group_boundary

# Read reference values table
if language = 1
	ref = Read Table from tab-separated file: "por_br_sampa.txt"
elsif language = 2
	ref = Read Table from tab-separated file: "por_br_ortofon.txt"
elsif language = 3
	ref = Read Table from tab-separated file: "eng_us.txt"
else
	ref = Read Table from tab-separated file: "spa.txt"
endif

if mode = 1
	# Multiple files mode
	list = Create Strings as file list: "fileList", folder$ + "*.TextGrid"
	files = Get number of strings
	if files < 1
		exitScript: "Found no TextGrid files at ", folder$ "."
	endif
else
	# Single file mode
	files = 1
	file$ = chooseReadFile$ ("Choose a TextGrid file")
	if file$ <> ""
		grid = Read from file: file$
	endif
endif

# Process all files in file list
for file to files
	if mode = 1
		selectObject: list
		file$ = Get string: file
		grid = Read from file: folder$ + file$
	endif

	file$ = selected$("TextGrid")
	is_inter_tier = Is interval tier: tier

	if is_inter_tier = 0
		exitScript: "Tier ", tier, " in TextGrid ", file$, " is not an interval tier."
	endif

	sel = Extract one tier: tier
	Set tier name: 1, file$
	tab = Down to Table: "no", 6, "yes", "no"
	Rename: file$
	tab[file] = tab
	units = Get number of rows

	# Consider only tiers with at least one non-empty intervals
	if units = 0
		exitScript: "Tier ", tier, " in TextGrid ", file$, " has no filled intervals."
	endif

	# Add raw duration column (in milliseconds)
	Append difference column: "tmax", "tmin", "dur"
	Formula: "dur", "round(self * 1000)"
	Remove column: "tmin"
	Remove column: "tmax"
	# Add information columns
	Insert column: 2, "position"
	Set column label (index): 1, "file"
	Set column label (index): 3, "label"
	# Sanitize "label" column: remove whitespace characters
	Formula: "label", "replace_regex$(self$, ""\s+"", """", 0)"

	# Write "position" column
	# Index of each unit in the user-specified tier
	for unit to units
		selectObject: tab[file]
		Set numeric value: unit, "position", unit
	endfor

	# Normalize raw duration if that option was selected
	if do_z
		selectObject: tab
		Append column: "norm"

		for unit to units
			label$ = object$[tab, unit, "label"]
			if language = 1
				@parse_por_br_sampa: label$
			elsif language = 2
				@parse_por_br_ortofon: label$
			elsif language = 3
				@parse_eng: label$
			else
				@parse_spa: label$
			endif

			if parse_errors > 0
				writeInfoLine: "Invalid character(s) in file ", file$, ", position ", unit, "."
				appendInfoLine: "Label: ", label$
				appendInfoLine: "Errors: ", parse_errors
				for i to parse_errors
					appendInfoLine: parse_errors$[i]
				endfor
				exitScript: "Invalid character in file ", file$, ". See Info window."
			endif

			sum_means = 0
			sum_vars = 0
			for j to parse_nseg
				seg$ = parse_segments$[j]
				selectObject: ref
				row = Search column: "phone", seg$
				mean = object[ref, row, "mean"]
				var = object[ref, row, "var"]
				sum_means += mean
				sum_vars += var
			endfor

			dur = object[tab, unit, "dur"]
			selectObject: tab
			Set numeric value: unit, "norm", (dur - sum_means) / sqrt(sum_vars)
		endfor
	endif

	# Apply smoothing if option was selected
	if do_sm
		selectObject: tab
		Append column: "smooth"
		if smoothing_method = 1
			@five_point: tab, "norm", "smooth"
		else
			@exponential: alpha, tab, "norm", "smooth"
		endif
	endif

	# Detect boundaries if option was selected
	if do_bd
		selectObject: tab
		Append column: "bound"
		if do_sm
			@boundaries: tab, "smooth", "bound"
		else
			@boundaries: tab, "norm", "bound"
		endif
	endif

	# Round numbers in normalized and smoothed duration columns
	if do_z
		selectObject: tab
		Formula: "norm", "fixed$(self, 3)"
	endif
	if do_sm
		selectObject: tab
		Formula: "smooth", "fixed$(self, 3)"
	endif

	# Clean up objects
	removeObject: grid, sel
endfor

selectObject: tab[1]
if mode = 1
	for file from 2 to files
		plusObject: tab[file]
	endfor
	merged = Append
endif

Save as tab-separated file: report$

# Clean up objects
selectObject: ref
if mode = 1
	plusObject: list, merged
	for file from 1 to files
		plusObject: tab[file]
	endfor
endif
Remove

writeInfo: "Finished at ", date$(), "."

######################################################################
#----- PROCEDURES ---------------------------------------------------#
######################################################################

procedure five_point: .tab, .col$, .sm_col$
# = Arguments =
# .tab: numerical ID of Table object where the data is.
# .col$: column label of Table object.
#
# = Description =
# Applies 5-point smoothing to normalized (z-scored) durations.
# The general function takes the current duration value (t_i), the two
# previous (t_i-1, t_i-2), the two following values (t_i+1, t_i+2) and
# applies a weighted average given using the the formula:
# sm_i = (5*t_i + 3*t_i-1 + 3*t_i+1 + t_i-2 + t_i+2) / 13
#
# There are special cases to be considered:
# 1. the 1st position has no previous data points
# 2. the last position has no following data points
# 3. the 2nd position has only one previous data point
# 4. the 2nd to last position has only one following data point
#
# In cases 1 and 2 we do a 2-point weighted average. In cases
# 3 and 4 we do a 3-point weighted average.

	selectObject: .tab
	.rows = object[.tab].nrow
	for .row to .rows
		if .row = 1
			.t = object[.tab, .row, .col$]
			.t_f1 = object[.tab, .row + 1, .col$]
			.sm = (2/3 * .t) + (1/3 * .t_f1)
		elsif .row = .rows
			.t = object[.tab, .row, .col$]
			.t_p1 = object[.tab, .row - 1, .col$]
			.sm = (2/3 * .t) + (1/3 * .t_p1)
		elsif (.row = 2) or (.row = .rows - 1)
			.t = object[.tab, .row, .col$]
			.t_p1 = object[.tab, .row - 1, .col$]
			.t_f1 = object[.tab, .row + 1, .col$]
			.sm = (3/5 * .t) + (1/5 * .t_p1) + (1/5 * .t_f1)
		else
			.t = object[.tab, .row, .col$]
			.t_p1 = object[.tab, .row - 1, .col$]
			.t_p2 = object[.tab, .row - 2, .col$]
			.t_f1 = object[.tab, .row  + 1, .col$]
			.t_f2 = object[.tab, .row + 2, .col$]
			.sm = (5 / 13 * .t) + (3 / 13 * .t_p1) + (3 / 13 * .t_f1) + (1 / 13 * .t_p2) + (1 / 13 * .t_f2)
		endif
		Set numeric value: .row, .sm_col$, .sm
	endfor
endproc

procedure exponential: .alpha, .tab, .in_col$, .out_col$
# = Arguments =
# .alpha: smoothing constant
# .tab: numerical ID of Table object where the data is
# .in_col$: name of column holding the values of the input series
# .out_col$: name of column holding the values of the smoothed series
#
# = Description =
# Applies exponential smoothing to normalized (z-scored) duration points.
# The general function takes the current normalized duration value (t_i)
# and the previous value of the smoothed series (sm_i-1) following the
# formula sm_i = alpha * t_i + ((1 - alpha) * sm_i-1).
#
# There is one special case: at the first position there are no previous
# smoothed values. The following formula is used in that position:
# sm_1 = alpha * t_1 + (1 - alpha) * t_2
#
# = Reference =
# https://grisha.org/blog/2016/01/29/triple-exponential-smoothing-forecasting/
# https://www.itl.nist.gov/div898/handbook/pmc/section4/pmc431.htm

	selectObject: .tab
	.rows = object[.tab].nrow
	for .row to .rows
		if .row = 1
			.t_1 = object[.tab, .row, .in_col$]
			.t_2 = object[.tab, .row + 1, .in_col$]
			.sm = (.alpha * .t_1) + ((1 - .alpha) * .t_2)
		else
			.t = object[.tab, .row, .in_col$]
			.sm_p = object[.tab, .row - 1, .out_col$]
			.sm = (.alpha * .t) + ((1 - .alpha) * .sm_p)
		endif
		Set numeric value: .row, .out_col$, .sm
	endfor
endproc

procedure boundaries: .tab, .in_col$, .out_col$
# = Arguments =
# .tab: numerical ID of Table object where the data is
# .in_col$: name of column holding the values of the input series
# .out_col$: name of column holding the values of the boundary series
#
# = Description =
# Finds maxima in a series of smoothed duration values.
# A maximum is a relation that a data point (t_i) has with its imediate
# neighbours t_i-1 and t_i+1. A maximum defines a boundary (bd = 1)
# according to the rule:
# bd = 1 if t_i-1 <= t_i > t_i+1 and bd = 0 otherwise.
#
# Two special cases are the first and last data points in the series.
# For the firt case, t_1 is a maximum if it is greater than t_2.
# For the second case, t_n is a maximum if it is equal or greater than t_n-1.

	selectObject: .tab
	.rows = object[.tab].nrow
	for .row to .rows
		if .row = 1
			.sm_1 = object[.tab, .row, .in_col$]
			.sm_2 = object[.tab, .row + 1, .in_col$]
			if .sm_1 > .sm_2
				.bd = 1
			else
				.bd = 0
			endif
		elsif .row = .rows
			.sm = object[.tab, .rows, .in_col$]
			.sm_p = object[.tab, .rows - 1, .in_col$]
			if .sm >= .sm_p
				.bd = 1
			else
				.bd = 0
			endif
		else
			.sm_i = object[.tab, .row, .in_col$]
			.sm_p = object[.tab, .row - 1, .in_col$]
			.sm_f = object[.tab, .row + 1, .in_col$]
			if (.sm_i >= .sm_p) and (.sm_i > .sm_f)
				.bd = 1
			else
				.bd = 0
			endif
		endif
		Set numeric value: .row, .out_col$, .bd
	endfor
endproc

procedure parse_por_br_sampa: .label$
# Parse Brazilian Portuguese segmentation (SAMPA style)
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
#s
# = Observartions =
# All relevant variables are internal to the procedure, except for two
# numerical variables (number of parse errors and segments in .label$)
# and two string arrays (string errors and valid segments) that are global.
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

	## Regular expressions used to search for 2- or 3-letter combination
	## at the beginning of a string
	# 3-letter combinations
	.three$ = "^([ao]Nj|[aA]Nw)"
	# 2-letter combinations
	.two$ = "^([aeouEIOU]j|[aeioEOU]w|[IU][@&6]|[aeiouAIU&@]N)"
	# 1-letter symbols
	.one$ = "^[ptkbdgfsSvzZ54mnJrXlLRDTaeiouEOAIU&@6]{1}"

	# Error counter
	parse_errors = 0

	# Number of Sampa-PB segments in label$ string
	parse_nseg = 0

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
		.is_legal = .three + .two + .one

		if .is_legal <> 0
			parse_nseg += 1
			parse_segments$[parse_nseg] = .current$
		else
			parse_errors += 1
			parse_errors$[parse_errors] = .current$
		endif

		# Remove current parsed chunk from label$
		.label$ = replace$(.label$, .current$, "", 1)
		.len = length(.label$)
	endwhile
endproc

procedure parse_por_br_ortofon: .label$
# Parse Brazilian Portuguese segmentation (Ortofon style)
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
# = Observartions =
# All relevant variables are internal to the procedure, except for two
# numerical variables (number of parse errors and segments in .label$)
# and two string arrays (string errors and valid segments) that are global.
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
	parse_errors = 0

	# Number of Ortofon segments in label$ string
	parse_nseg = 0

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
		.is_legal = .three + .two_N_h + .two_V + .one

		if .is_legal <> 0
			parse_nseg += 1
			parse_segments$[parse_nseg] = .current$
		else
			parse_errors += 1
			parse_errors$[parse_errors] = .current$
		endif

		# Remove current parsed chunk from label$
		.label$ = .label$ - .current$
		.len = length(.label$)
	endwhile
endproc

procedure parse_eng: .label$
# Parse English segmentation
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
# The procedure parses a phonetic label comprised of a string of
# at least one ASCII character into phonetic segments. Phonetic segments
# can be represented by one character or a combination of two characters,
# listed below.
#
# = Observartions =
# All relevant variables are internal to the procedure, except for two
# numerical variables (number of parse errors and segments in .label$)
# and two string arrays (string errors and valid segments) that are global.
#
#
# * 2-letter segments
# [aeEiou]R
# [aeo]I
# [ao]U
# [aiou]:
# tS
# dZ
#
# Parsing of the string consists of the following steps:
#
# 1. Start from the beginning of string.
# 2. Test for presence of a segment represented by a 2-letter combination.
# 3. If true, set end of segment to index 2.
# 4. If false, segment is represent by a single character.
# 5. Test if character is a valid one-character element of English symbol set.
# 6. If false, save invalid character in string variable that can be used
#    in an error message to the user.
#
# = Output =
# Parsed segments and illegal segments are stored as array elements.
#

	## Regular expressions used to search for 2- and 1-letter combinations
	## at the beginning of a string
	# 2-letter combinations
	.two$ = "^([aeEiou]R|[aeo]I|[ao]U|[aiou]:|tS|dZ)"
	# 1-letter symbols
	.one$ = "^[aAE@eiouTDrSZbdfghjklmnNpstvwz]{1}"

	# Error counter
	parse_errors = 0

	# Number of segments in label$ string
	parse_nseg = 0

	# Initial label$ size
	.len = length(.label$)

	while .len > 0
		# Define the size of the current chunk to be analyzed
		.two = index_regex(.label$, .two$)
		.one = index_regex(.label$, .one$)

		if .two = 1
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
		.is_legal = .two + .one

		if .is_legal <> 0
			parse_nseg += 1
			parse_segments$[parse_nseg] = .current$
		else
			parse_errors += 1
			parse_errors$[parse_errors] = .current$
		endif

		# Remove current parsed chunk from label$
		.label$ = replace$(.label$, .current$, "", 1)
		.len = length(.label$)
	endwhile
endproc

procedure parse_spa: .label$
# Parse Spanish segmentation
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
# The procedure parses a phonetic label comprised of a string of
# at least one ASCII character into phonetic segments. Phonetic segments
# can be represented by one character or a combination of two characters,
# listed below.
#
# = Observartions =
# All relevant variables are internal to the procedure, except for two
# numerical variables (number of parse errors and segments in .label$)
# and two string arrays (string errors and valid segments) that are global.
#
# All elements in the Spanish symbol set are one-character in length.
#
# Parsing of the string consists of the following steps:
#
# 1. Start from the beginning of string.
# 2. Test if character is a valid one-character element of English symbol set.
# 3. If false, save invalid character in string variable that can be used
#    in an error message to the user.
#
# = Output =
# Parsed segments and illegal segments are stored as array elements.
#

	## Regular expressions used to search for 1-letter symbols 
	# 1-letter symbols
	.one$ = "^[BCDGJLNRTabdefgijklmnopqrstuwxz]{1}"

	# Error counter
	parse_errors = 0

	# Number of segments in label$ string
	parse_nseg = 0

	# Initial label$ size
	.len = length(.label$)

	while .len > 0
		# Define the size of the current chunk to be analyzed
		.one = index_regex(.label$, .one$)
		.end = 1

		# Extract the current parsed string
		.current$ = left$(.label$, .end)

		# If no valid sequences are found,
		# First character in label$ is illegal
		.is_legal = .one

		if .is_legal <> 0
			parse_nseg += 1
			parse_segments$[parse_nseg] = .current$
		else
			parse_errors += 1
			parse_errors$[parse_errors] = .current$
		endif

		# Remove current parsed chunk from label$
		.label$ = replace$(.label$, .current$, "", 1)
		.len = length(.label$)
	endwhile
endproc
