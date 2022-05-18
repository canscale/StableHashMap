# StableHashMap 

Stable HashMaps in Motoko. 

## Motivation
Inspiration taken from [this back and forth in the Dfinity developer forums](https://forum.dfinity.org/t/clarification-on-stable-types-with-examples/11075).

## API Documentation

API documentation for this library can be found at https://canscale.github.io/StableHashMap

## Implementation
Two different StableHashMap implementations are accessible via this module.

### FunctionalStableHashMap (**Recommended**)
  This module is a direct deconstruction of the object oriented [HashMap.mo class in motoko-base]
  (https://github.com/dfinity/motoko-base/blob/master/src/HashMap.mo)
  into a series of functions and is meant to be persistent across updates, with the tradeoff 
  being larger function signatures.

  One of the main additions/difference between the two modules at this time besides class deconstruction
  is the differing initialization methods if an initialCapacity is known (to prevent array doubling 
  slowdown during map initialization)

### ClassStableHashMap
  **Note**: If using this module the `exportProps()` and `importProps()` class methods must be used in conjunction with the system pre/post-upgrade methods to assure stability.

  This module is nearly identical to [https://github.com/dfinity/motoko-base/blob/master/src/HashMap.mo](https://github.com/dfinity/motoko-base/blob/master/src/HashMap.mo), except public `exportProps()` and `importProps()` class methods were added to the original implementation in order to allow the hashtable and it's item count to be retrievable and therefore persistable across upgrades.

## License
StableHashMap is distributed under the terms of the Apache License (Version 2.0).

See LICENSE for details.