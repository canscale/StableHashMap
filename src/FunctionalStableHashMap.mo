/// Mutable hash map (aka Hashtable)
///
/// This module is a direct deconstruction of the object oriented HashMap.mo class in motoko-base
/// (https://github.com/dfinity/motoko-base/blob/master/src/HashMap.mo)
/// into a series of functions and is meant to be persistent across updates, with the tradeoff 
/// being larger function signatures.
///
/// One of the main additions/difference between the two modules at this time besides class deconstruction
/// is the differing initialization methods if an initialCapacity is known (to prevent array doubling 
/// slowdown during map initialization)
///
/// The rest of this documentation and code therefore follows directly from HashMap.mo, with minor
/// modifications that do not attempt to change implementation. Please raise and issue if a
/// discrepancy in implementation is found.
///
/// The class is parameterized by the key's equality and hash functions,
/// and an initial capacity.  However, as with the `Buffer` class, no array allocation
/// happens until the first `set`.
///
/// Internally, table growth policy is very simple, for now:
///  Double the current capacity when the expected bucket list size grows beyond a certain constant.

import Prim "mo:⛔";
import Nat "mo:base/Nat";
import A "mo:base/Array";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import AssocList "mo:base/AssocList";

module {


  // key-val list type
  type KVs<K, V> = AssocList.AssocList<K, V>;

  /// Type signature for the StableHashMap object.
  public type StableHashMap<K, V> = {
    initCapacity: Nat;
    var table: [var KVs<K, V>];
    var _count: Nat;
  };

  /// Initializes a HashMap with initCapacity and table size zero
  public func init<K, V>(): StableHashMap<K, V> = {
    initCapacity = 0; 
    var table = [var];
    var _count = 0;
  };  

  /// Initializes a hashMap with given initCapacity. No array allocation will
  /// occur until the first item is inserted 
  public func initPreSized<K, V>(initCapacity: Nat): StableHashMap<K, V> = {
    initCapacity = initCapacity;
    var table = [var];
    var _count = 0;
  };  

  /// Returns the number of entries in this HashMap.
  public func size<K, V>(map: StableHashMap<K, V>): Nat {
    map._count;
  }; 

  /// Deletes the entry with the key `k`. Doesn't do anything if the key doesn't
  /// exist.
  public func delete<K, V>(
    map: StableHashMap<K, V>, 
    keyEq: (K, K) -> Bool,
    keyHash: K -> Hash.Hash, 
    k: K
  ): () {
    ignore remove(map, keyEq, keyHash, k);
  };

  /// Removes the entry with the key `k` and returns the associated value if it
  /// existed or `null` otherwise.
  public func remove<K, V>(
    map: StableHashMap<K, V>, 
    keyEq: (K, K) -> Bool,
    keyHash: K -> Hash.Hash, 
    k: K
  ): ?V {
    let m = map.table.size();
    if (m > 0) {
      let h = Prim.nat32ToNat(keyHash(k));
      let pos = h % m;
      let (kvs2, ov) = AssocList.replace<K, V>(map.table[pos], k, keyEq, null);
      map.table[pos] := kvs2;
      switch(ov){
        case null { };
        case _ { map._count := map._count - 1; }
      };
      ov
    } else {
      null
    };
  };

  /// Gets the entry with the key `k` and returns its associated value if it
  /// existed or `null` otherwise.
  public func get<K, V>(
    map: StableHashMap<K, V>, 
    keyEq: (K, K) -> Bool,
    keyHash: K -> Hash.Hash, 
    k: K
  ): ?V {
    let h = Prim.nat32ToNat(keyHash(k));
    let m = map.table.size();
    let v = if (m > 0) {
      AssocList.find<K, V>(map.table[h % m], k, keyEq)
    } else {
      null
    };
  };

  /// Insert the value `v` at key `k`. Overwrites an existing entry with key `k`
  /// Does not return a value if updating an existing key
  public func put<K, V>(
    map: StableHashMap<K, V>,
    keyEq: (K, K) -> Bool,
    keyHash: K -> Hash.Hash, 
    k: K,
    v: V
  ): () {
    ignore replace(map, keyEq, keyHash, k, v);
  };

  /// Insert the value `v` at key `k` and returns the previous value stored at
  /// `k` or `null` if it didn't exist.
  public func replace<K, V>(
    map: StableHashMap<K, V>,
    keyEq: (K, K) -> Bool,
    keyHash: K -> Hash.Hash, 
    k: K,
    v: V
  ): ?V {
    if (map._count >= map.table.size()) {
      let size = 
        if (map._count == 0) {
          if (map.initCapacity > 0) {
            map.initCapacity
          } else {
            1
          }
        }
        else {
          map.table.size() * 2;
        };
      let table2 = A.init<KVs<K, V>>(size, null);
      for (i in map.table.keys()) {
        var kvs = map.table[i];
        label moveKeyVals: ()
        loop {
          switch kvs {
            case null { break moveKeyVals };
            case (?((k, v), kvsTail)) {
              let h = Prim.nat32ToNat(keyHash(k));
              let pos2 = h % table2.size();
              table2[pos2] := ?((k,v), table2[pos2]);
              kvs := kvsTail;
            };
          }
        };
      };
      map.table := table2;
    };
    let h = Prim.nat32ToNat(keyHash(k));
    let pos = h % map.table.size();
    let (kvs2, ov) = AssocList.replace<K, V>(map.table[pos], k, keyEq, ?v);
    map.table[pos] := kvs2;
    switch(ov){
      case null { map._count += 1 };
      case _ {}
    };
    ov  
  };

  /// An `Iter` over the keys.
  public func keys<K, V>(map: StableHashMap<K, V>): Iter.Iter<K> { 
    Iter.map(entries(map), func (kv: (K, V)): K { kv.0 }) 
  };

  /// An `Iter` over the values.
  public func vals<K, V>(map: StableHashMap<K, V>): Iter.Iter<V> { 
    Iter.map(entries(map), func (kv: (K, V)): V { kv.1 }) 
  };

  /// Returns an iterator over the key value pairs in this
  /// `HashMap`. Does _not_ modify the `HashMap`.
  public func entries<K, V>(map: StableHashMap<K, V>): Iter.Iter<(K, V)> {
    if (map.table.size() == 0) {
      object { public func next(): ?(K, V) { null } }
    }
    else {
      object {
        var kvs = map.table[0];
        var nextTablePos = 1;
        public func next (): ?(K, V) {
          switch kvs {
            case (?(kv, kvs2)) {
              kvs := kvs2;
              ?kv
            };
            case null {
              if (nextTablePos < map.table.size()) {
                kvs := map.table[nextTablePos];
                nextTablePos += 1;
                next()
              } else {
                null
              }
            }
          }
        }
      }
    };
  };

  /// clone cannot be an efficient object method,
  /// ...but is still useful in tests, and beyond.
  public func clone<K, V> (
    h: StableHashMap<K, V>,
    keyEq: (K, K) -> Bool,
    keyHash: K -> Hash.Hash
  ): StableHashMap<K, V> {
    let h2 = init<K, V>();
    for ((k,v) in entries<K, V>(h)) {
      put(h2, keyEq, keyHash, k, v);
    };
    h2
  };

  /// Clone from any iterator of key-value pairs
  public func fromIter<K, V>(
    iter: Iter.Iter<(K, V)>,
    initCapacity: Nat,
    keyEq: (K, K) -> Bool,
    keyHash: K -> Hash.Hash
  ): StableHashMap<K, V> {
    let h = initPreSized<K, V>(initCapacity);
    for ((k, v) in iter) {
      put(h, keyEq, keyHash, k, v);
    };
    h
  };

  public func map<K, V1, V2>(
    h: StableHashMap<K, V1>,
    keyEq: (K, K) -> Bool,
    keyHash: K -> Hash.Hash,
    mapFn: (K, V1) -> V2,
  ): StableHashMap<K, V2> {
    let h2 = init<K, V2>();
    for ((k, v1) in entries<K, V1>(h)) {
      let v2 = mapFn(k, v1);
      put(h2, keyEq, keyHash, k, v2);
    };
    h2
  };

  public func mapFilter<K, V1, V2>(
    h: StableHashMap<K, V1>,
    keyEq: (K, K) -> Bool,
    keyHash: K -> Hash.Hash,
    mapFn: (K, V1) -> ?V2,
  ): StableHashMap<K, V2> {
    let h2 = init<K, V2>();
    for ((k, v1) in entries<K, V1>(h)) {
      switch (mapFn(k, v1)) {
        case null { };
        case (?v2) {
          put(h2, keyEq, keyHash, k, v2);
        };
      }
    };
    h2
  };
}