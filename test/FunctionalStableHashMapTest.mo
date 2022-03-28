import Debug "mo:base/Debug";
import HM "../src/FunctionalStableHashMap";
import Hash "mo:base/Hash";
import Text "mo:base/Text";

Debug.print("functional stable");

debug {
  let a = HM.init<Text, Nat>();
  assert HM.size<Text, Nat>(a) == 0;

  func putHelper(map: HM.StableHashMap<Text, Nat>, t: Text, n: Nat): () {
    HM.put(map, Text.equal, Text.hash, t, n);
  };

  func getHelper(map: HM.StableHashMap<Text, Nat>, t: Text): ?Nat {
    HM.get(map, Text.equal, Text.hash, t);
  };

  func removeHelper(map: HM.StableHashMap<Text, Nat>, t: Text): ?Nat {
    HM.remove(map, Text.equal, Text.hash, t);
  };

  func deleteHelper(map: HM.StableHashMap<Text, Nat>, t: Text): () {
    HM.delete(map, Text.equal, Text.hash, t);
  };

  putHelper(a, "apple", 1);
  putHelper(a, "banana", 2);
  putHelper(a, "pear", 3);
  putHelper(a, "avocado", 4);
  putHelper(a, "Apple", 11);
  putHelper(a, "Banana", 22);
  putHelper(a, "Pear", 33);
  putHelper(a, "Avocado", 44);
  putHelper(a, "ApplE", 111);
  putHelper(a, "BananA", 222);
  putHelper(a, "PeaR", 333);
  putHelper(a, "AvocadO", 444);

  // need to resupply the constructor args; they are private to the object; but, should they be?
  assert HM.size<Text, Nat>(a) == 12;
  let b = HM.clone<Text, Nat>(a, Text.equal, Text.hash);
  assert HM.size<Text, Nat>(b) == 12;

  // ensure clone has each key-value pair present in original
  for ((k,v) in HM.entries(a)) {
    Debug.print(debug_show (k,v));
    switch (getHelper(b, k)) {
    case null { assert false };
    case (?w) { assert v == w };
    };
  };

  // ensure original has each key-value pair present in clone
  for ((k,v) in HM.entries(b)) {
    Debug.print(debug_show (k,v));
    switch (getHelper(a, k)) {
    case null { assert false };
    case (?w) { assert v == w };
    };
  };

  // ensure clone has each key present in original
  for (k in HM.keys(a)) {
    switch (getHelper(b, k)) {
    case null { assert false };
    case (?_) {  };
    };
  };

  // ensure clone has each value present in original
  for (v in HM.vals(a)) {
    var foundMatch = false;
    for (w in HM.vals(b)) {
      if (v == w) { foundMatch := true }
    };
    assert foundMatch
  };

  // do some more operations:
  putHelper(a, "apple", 1111);
  putHelper(a, "banana", 2222);
  switch( removeHelper(a, "pear")) {
    case null { assert false };
    case (?three) { assert three == 3 };
  };
  assert HM.size<Text, Nat>(a) == 11;
  deleteHelper(a, "avocado");
  assert HM.size<Text, Nat>(a) == 10;

  // check them:
  switch (getHelper(a, "apple")) {
  case (?1111) { };
  case _ { assert false };
  };
  switch (getHelper(a, "banana")) {
  case (?2222) { };
  case _ { assert false };
  };
  switch (getHelper(a, "pear")) {
  case null {  };
  case (?_) { assert false };
  };
  switch (getHelper(a, "avocado")) {
  case null {  };
  case (?_) { assert false };
  };

  // undo operations above:
  putHelper(a, "apple", 1);
  // .. and test that replace works
  switch (HM.replace<Text, Nat>(a, Text.equal, Text.hash, "apple", 666)) {
    case null { assert false };
    case (?one) { assert one == 1; // ...and revert
                  putHelper(a, "apple", 1)
         };
  };
  putHelper(a, "banana", 2);
  putHelper(a, "pear", 3);
  putHelper(a, "avocado", 4);
  assert HM.size<Text, Nat>(a) == 12;

  // ensure clone has each key-value pair present in original
  for ((k,v) in HM.entries(a)) {
    Debug.print(debug_show (k,v));
    switch (getHelper(b, k)) {
    case null { assert false };
    case (?w) { assert v == w };
    };
  };

  // ensure original has each key-value pair present in clone
  for ((k,v) in HM.entries(b)) {
    Debug.print(debug_show (k,v));
    switch (getHelper(a, k)) {
    case null { assert false };
    case (?w) { assert v == w };
    };
  };


  // test fromIter method
  let c = HM.fromIter<Text, Nat>(HM.entries(b), 0, Text.equal, Text.hash);

  // c agrees with each entry of b
  for ((k,v) in HM.entries(b)) {
    Debug.print(debug_show (k,v));
    switch (getHelper(c, k)) {
    case null { assert false };
    case (?w) { assert v == w };
    };
  };

  // b agrees with each entry of c
  for ((k,v) in HM.entries(c)) {
    Debug.print(debug_show (k,v));
    switch (getHelper(b, k)) {
    case null { assert false };
    case (?w) { assert v == w };
    };
  };

  // Issue #228
  // let d = H.HashMap<Text, Nat>(50, Text.equal, Text.hash);
  let d = HM.init<Text, Nat>();
  switch(removeHelper(d, "test")) {
    case null { };
    case (?_) { assert false };
  };
  assert HM.size<Text, Nat>(d) == 0;
};