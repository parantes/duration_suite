# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [0.1.4] - 2020-01-17
### Fixed
- Fixed a bug related to 'include' statements within 'if' statements; included code were
procedures that deal with parsing segments conditional on language and notation system.
The nature of procedure definition in Praat do not play well with conditionals
(https://groups.io/g/Praat-Users-List/message/8598). This fix puts all parse procedures
at the end of the script. Relevant variables local to parse procedures are made global.

### Changed
- Language options 'Spanish' and 'English' were added as TODO.

## [0.1.3] - 2019-11-26
### Fixed
- Corrected error in a call to @five_point procedure

## [0.1.2] - 2019-05-28
### Changed
- Updated commands to new syntax style

### Fixed
- Corrected error in the por_br Ortofon parser

## [0.1.1] - 2013-02-09
### Changed
- Miscellaneous changes

## [0.1.0] - 2008-05-05
### Added
- Script created
