/// The below is the reference HashMap.mo file from 
/// https://github.com/dfinity/motoko-base/blob/master/src/HashMap.mo
/// that was used to create StableHashMap.mo
///
/// Mutable stable hash map (aka Hashtable)
///
/// This module defines an imperative hash map (hash table), with a general key and value type.
/// exportProps() and importProps() functions were added to the original implementation in order to allow 
/// the hashtable and it's item count to be retrievable and therefore persistable across upgrades.
///
/// It has a minimal object-oriented interface: `get`, `set`, `delete`, `count` and `entries`.
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

  type HashTable<K, V> = [var KVs<K, V>];

  public type HashTableProps<K, V> = {
    table: HashTable<K, V>;
    _count: Nat;
  };

  // key-val list type
  type KVs<K, V> = AssocList.AssocList<K, V>;

  /// An imperative StableHashMap with a minimal object-oriented interface.
  /// Maps keys of type `K` to values of type `V`.
 public class StableHashMap<K, V>(
    initCapacity : Nat,
    keyEq : (K, K) -> Bool,
    keyHash : K -> Hash.Hash) {

    var table : HashTable<K, V> = [var];
    var _count : Nat = 0;

    // TODO: decide if want to enforce that the imported _count is equal to the populated size of the table 
    // (populated size <= table.size())
    public func importProps(props: HashTableProps<K, V>): () {
      table := props.table;
      _count := 
        if (props._count > props.table.size()) { props.table.size() }
        else { props._count }
    };

    public func exportProps(): HashTableProps<K,V> = { 
      table = table;
      _count = _count;
    };


    /// Returns the number of entries in this StableHashMap.
    public func size() : Nat = _count;

    /// Deletes the entry with the key `k`. Doesn't do anything if the key doesn't
    /// exist.
    public func delete(k : K) = ignore remove(k);

    /// Removes the entry with the key `k` and returns the associated value if it
    /// existed or `null` otherwise.
    public func remove(k : K) : ?V {
      let m = table.size();
      if (m > 0) {
        let h = Prim.nat32ToNat(keyHash(k));
        let pos = h % m;
        let (kvs2, ov) = AssocList.replace<K, V>(table[pos], k, keyEq, null);
        table[pos] := kvs2;
        switch(ov){
          case null { };
          case _ { _count -= 1; }
        };
        ov
      } else {
        null
      };
    };

    /// Gets the entry with the key `k` and returns its associated value if it
    /// existed or `null` otherwise.
    public func get(k : K) : ?V {
      let h = Prim.nat32ToNat(keyHash(k));
      let m = table.size();
      let v = if (m > 0) {
        AssocList.find<K, V>(table[h % m], k, keyEq)
      } else {
        null
      };
    };

    /// Insert the value `v` at key `k`. Overwrites an existing entry with key `k`
    public func put(k : K, v : V) = ignore replace(k, v);

    /// Insert the value `v` at key `k` and returns the previous value stored at
    /// `k` or `null` if it didn't exist.
    public func replace(k : K, v : V) : ?V {
      if (_count >= table.size()) {
        let size =
          if (_count == 0) {
            if (initCapacity > 0) {
              initCapacity
            } else {
              1
            }
          } else {
            table.size() * 2;
          };
        let table2 = A.init<KVs<K, V>>(size, null);
        for (i in table.keys()) {
          var kvs = table[i];
          label moveKeyVals : ()
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
        table := table2;
      };
      let h = Prim.nat32ToNat(keyHash(k));
      let pos = h % table.size();
      let (kvs2, ov) = AssocList.replace<K, V>(table[pos], k, keyEq, ?v);
      table[pos] := kvs2;
      switch(ov){
        case null { _count += 1 };
        case _ {}
      };
      ov
    };

    /// An `Iter` over the keys.
    public func keys() : Iter.Iter<K>
    { Iter.map(entries(), func (kv : (K, V)) : K { kv.0 }) };

    /// An `Iter` over the values.
    public func vals() : Iter.Iter<V>
    { Iter.map(entries(), func (kv : (K, V)) : V { kv.1 }) };

    /// Returns an iterator over the key value pairs in this
    /// `StableHashMap`. Does _not_ modify the `StableHashMap`.
    public func entries() : Iter.Iter<(K, V)> {
      if (table.size() == 0) {
        object { public func next() : ?(K, V) { null } }
      }
      else {
        object {
          var kvs = table[0];
          var nextTablePos = 1;
          public func next () : ?(K, V) {
            switch kvs {
              case (?(kv, kvs2)) {
                kvs := kvs2;
                ?kv
              };
              case null {
                if (nextTablePos < table.size()) {
                  kvs := table[nextTablePos];
                  nextTablePos += 1;
                  next()
                } else {
                  null
                }
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
    h : StableHashMap<K, V>,
    keyEq : (K, K) -> Bool,
    keyHash : K -> Hash.Hash
  ) : StableHashMap<K, V> {
    let h2 = StableHashMap<K, V>(h.size(), keyEq, keyHash);
    for ((k,v) in h.entries()) {
      h2.put(k,v);
    };
    h2
  };

  /// Clone from any iterator of key-value pairs
  public func fromIter<K, V>(
    iter : Iter.Iter<(K, V)>,
    initCapacity : Nat,
    keyEq : (K, K) -> Bool,
    keyHash : K -> Hash.Hash
  ) : StableHashMap<K, V> {
    let h = StableHashMap<K, V>(initCapacity, keyEq, keyHash);
    for ((k, v) in iter) {
      h.put(k, v);
    };
    h
  };

  public func map<K, V1, V2>(
    h : StableHashMap<K, V1>,
    keyEq : (K, K) -> Bool,
    keyHash : K -> Hash.Hash,
    mapFn : (K, V1) -> V2,
  ) : StableHashMap<K, V2> {
    let h2 = StableHashMap<K, V2>(h.size(), keyEq, keyHash);
    for ((k, v1) in h.entries()) {
      let v2 = mapFn(k, v1);
      h2.put(k, v2);
    };
    h2
  };

  public func mapFilter<K, V1, V2>(
    h : StableHashMap<K, V1>,
    keyEq : (K, K) -> Bool,
    keyHash : K -> Hash.Hash,
    mapFn : (K, V1) -> ?V2,
  ) : StableHashMap<K, V2> {
    let h2 = StableHashMap<K, V2>(h.size(), keyEq, keyHash);
    for ((k, v1) in h.entries()) {
      switch (mapFn(k, v1)) {
        case null { };
        case (?v2) {
          h2.put(k, v2);
        };
      }
    };
    h2
  };
} 