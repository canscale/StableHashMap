# StableHashMap.mo 

Stable HashMaps in Motoko. 

## Motivation
Inspiration taken from [this back and forth in the Dfinity developer forums](https://forum.dfinity.org/t/clarification-on-stable-types-with-examples/11075).

## Implementation
This implementation is a direct deconstruction of the object oriented [HashMap.mo class in motoko-base]
(https://github.com/dfinity/motoko-base/blob/master/src/HashMap.mo)
into a series of functions and is meant to be persistent across updates, with the tradeoff 
being larger function signatures.

One of the main additions/difference between the two modules at this time besides class deconstruction
is the differing initialization methods if an initialCapacity is known (to prevent array doubling 
slowdown during map initialization)


## API Documentation

API documentation for this library can be found at (CHANGE ME) https://canscale.github.io/StableHashMap.mo


