# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [0.5.1]
### Fixed
- perf: :zap: move from edmonds blossom to mwm algorithm for 2lo

### Other
- Merge tag 0.5.0 into develop

- added rewarding players with a BYE in the first round of swiss/2lo

## [0.5.0]
### Changed
- feat: :sparkles: add rewarding players with BYE in 2lo

### Other
- Merge branch release/0.5.0
- Merge tag 0.4.1 into develop

- fixed missing options passing for swiss/2lo

## [0.4.1]
### Deprecated
- chore: :bookmark: bump version to 0.4.1

### Fixed
- fix: :ambulance: fix missing opts for swiss/2lo

### Other
- Merge branch release/0.4.1
- Merge tag 0.4.0 into develop

- changed Swiss algorithm to MWM
- divided swiss and 2lo related parts
- fixed case when algorithm doesnt pair players for a rematch when there is no other option

## [0.4.0]
### Changed
- feat: :zap: add mwm algorithm for swiss and fix tests

### Deprecated
- chore: :bookmark: bump version to 0.4.0

### Other
- Merge branch release/0.4.0
- Merge tag 0.3.0 into develop

- add round robin pairing features

## [0.3.0]
### Changed
- feat: :sparkles: add round robin pairing

### Deprecated
- chore: :bookmark: bump version to 0.3.0

### Other
- Merge branch release/0.3.0
- Merge pull request #4 from vi0dine/feature/round-robin

feat: :sparkles: add round robin pairing
- Merge tag 0.2.7 into develop

- fixed Swiss weights calculation

## [0.2.7]
### Deprecated
- chore: :bookmark: bump version to 0.2.7

### Fixed
- fix: :bug: adjust weights calculations to work for both swiss and 2lo

### Other
- Merge branch release/0.2.7
- Merge tag 0.2.6 into develop

- temporarly disabled BYE-factor in the swiss/blossom calculations

## [0.2.6]
### Deprecated
- chore: :bookmark: bump version to 0.2.6

### Fixed
- fix: :ambulance: commented bye-factor for weights in blossom algorithm

### Other
- Merge branch release/0.2.6
- Merge tag 0.2.5 into develop

restrict BYE assigning to the X-1 pool

## [0.2.5]
### Deprecated
- chore: :bookmark: bump version to 0.2.5

### Fixed
- fix: :ambulance: fix assigning byes to only x-1 pool

### Other
- Merge branch release/0.2.5
- Merge tag 0.2.4 into develop

fixes issue with tournaments with 3 or less participants

## [0.2.4]
### Deprecated
- chore: :bookmark: bump version to 0.2.4

### Other
- Merge branch release/0.2.4
- Merge pull request #2 from vi0dine/fmoggia/fix-2player-bracket-single-elimination

fix issue with building brackets with only 2/3 players
- Merge tag 0.2.3 into develop

fix blossom algorithm to work with weights
- fix issue with building brackets with only 2/3 players
- Merge tag 0.2.2 into develop

fix additional bye match
- Merge tag 0.2.1 into develop

fixed rust files for package builds
- Merge tag 0.2.0 into develop

Swiss algorithm implementation

## [0.2.3]
### Fixed
- fix: :bug: fix swiss pairing by weights

### Other
- Merge branch hotfix/0.2.3

## [0.2.2]
### Fixed
- fix: :ambulance: fix additional bye

### Other
- Merge branch hotfix/0.2.2

## [0.2.1]
### Deprecated
- chore: :bookmark: bump version

### Fixed
- fix: :ambulance: add rustler files to released package

### Other
- Merge branch hotfix/0.2.1

## [0.2.0]
### Changed
- docs: :memo: update readme
- feat: :sparkles: add swiss round generator
- feat: :zap: add rust implementation of the blossom algorithm
- feat: :sparkles: init blossom algorithm implementation

### Deprecated
- chore: :bookmark: bump version to 0.2.0

### Other
- Merge branch release/0.2.0
- Merge pull request #1 from vi0dine/feature/swiss_format

Feature/swiss format
- Merge tag 0.1.1 into develop

Changed
- docs: add tools for versioning and changelog generation
- refactor: add docs and specs
- refactor: extract some modules from the pairing services

## [0.1.1]
### Changed
- docs: add tools for versioning and changelog generation
- refactor: add docs and specs
- refactor: extract some modules from the pairing services

### Deprecated
- chore: bump version to 0.1.1

### Other
- Merge branch release/0.1.1
- Merge tag 0.1.0 into develop

Initial release

- Single elimination pairing creation
- Double elimination pairing creation

## [0.1.0]
### Changed
- feat: prep for initial hex publish
- feat: add Match struct
- feat: add single elimination pairing model
- feat: add and fix tests for double elimination
- feat: add double elimination model

### Other
- Merge branch release/0.1.0
- Initial commit

