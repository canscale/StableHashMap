import Debug "mo:base/Debug";
import HM "../src/ClassStableHashMap";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Nat "mo:base/Nat";

import List "mo:base/List";

Debug.print("class stable");

debug {
  let a = HM.StableHashMap<Text, Nat>(3, Text.equal, Text.hash);

  a.put("apple", 1);
  a.put("banana", 2);
  a.put("pear", 3);
  a.put("avocado", 4);
  a.put("Apple", 11);
  a.put("Banana", 22);
  a.put("Pear", 33);
  a.put("Avocado", 44);
  a.put("ApplE", 111);
  a.put("BananA", 222);
  a.put("PeaR", 333);
  a.put("AvocadO", 444);

  // need to resupply the constructor args; they are private to the object; but, should they be?
  let b = HM.clone<Text, Nat>(a, Text.equal, Text.hash);

  // ensure clone has each key-value pair present in original
  for ((k,v) in a.entries()) {
    Debug.print(debug_show (k,v));
    switch (b.get(k)) {
    case null { assert false };
    case (?w) { assert v == w };
    };
  };

  // ensure original has each key-value pair present in clone
  for ((k,v) in b.entries()) {
    Debug.print(debug_show (k,v));
    switch (a.get(k)) {
    case null { assert false };
    case (?w) { assert v == w };
    };
  };

  // ensure clone has each key present in original
  for (k in a.keys()) {
    switch (b.get(k)) {
    case null { assert false };
    case (?_) {  };
    };
  };

  // ensure clone has each value present in original
  for (v in a.vals()) {
    var foundMatch = false;
    for (w in b.vals()) {
      if (v == w) { foundMatch := true }
    };
    assert foundMatch
  };

  // do some more operations:
  a.put("apple", 1111);
  a.put("banana", 2222);
  switch( a.remove("pear")) {
    case null { assert false };
    case (?three) { assert three == 3 };
  };
  a.delete("avocado");

  // check them:
  switch (a.get("apple")) {
  case (?1111) { };
  case _ { assert false };
  };
  switch (a.get("banana")) {
  case (?2222) { };
  case _ { assert false };
  };
  switch (a.get("pear")) {
  case null {  };
  case (?_) { assert false };
  };
  switch (a.get("avocado")) {
  case null {  };
  case (?_) { assert false };
  };

  // undo operations above:
  a.put("apple", 1);
  // .. and test that replace works
  switch (a.replace("apple", 666)) {
    case null { assert false };
    case (?one) { assert one == 1; // ...and revert
                  a.put("apple", 1)
         };
  };
  a.put("banana", 2);
  a.put("pear", 3);
  a.put("avocado", 4);

  // ensure clone has each key-value pair present in original
  for ((k,v) in a.entries()) {
    Debug.print(debug_show (k,v));
    switch (b.get(k)) {
    case null { assert false };
    case (?w) { assert v == w };
    };
  };

  // ensure original has each key-value pair present in clone
  for ((k,v) in b.entries()) {
    Debug.print(debug_show (k,v));
    switch (a.get(k)) {
    case null { assert false };
    case (?w) { assert v == w };
    };
  };


  // test fromIter method
  let c = HM.fromIter<Text, Nat>(b.entries(), 0, Text.equal, Text.hash);

  // c agrees with each entry of b
  for ((k,v) in b.entries()) {
    Debug.print(debug_show (k,v));
    switch (c.get(k)) {
    case null { assert false };
    case (?w) { assert v == w };
    };
  };

  // b agrees with each entry of c
  for ((k,v) in c.entries()) {
    Debug.print(debug_show (k,v));
    switch (b.get(k)) {
    case null { assert false };
    case (?w) { assert v == w };
    };
  };

  // Issue #228
  let d = HM.StableHashMap<Text, Nat>(50, Text.equal, Text.hash);
  switch(d.remove("test")) {
    case null { };
    case (?_) { assert false };
  };

  // test exportProps
  let e = HM.StableHashMap<Text, Nat>(3, Text.equal, Text.hash);
  var tbl = e.exportProps();
  assert tbl._count == 0;
  assert tbl.table.size() == 0;

  e.put("a", 0);
  tbl := e.exportProps();
  assert tbl._count == 1;
  assert tbl.table.size() == 3; // table should be sized now 

  e.put("b", 1);
  e.put("c", 2);
  e.put("d", 3);
  tbl := e.exportProps();
  assert tbl._count == 4;
  assert tbl.table.size() == 6; // table should have doubled once

  let lst: List.List<Nat> = ?(5, null);

  let asclst: List.List<(Text, Nat)> = ?(("a", 1), ?(("b", 2), null));

  // test importProps
  e.importProps({ 
    table = [var
      ?(("a", 2), null), ?(("b", 4),null)
    ];
    _count = 2;
  });
  tbl := e.exportProps();
  assert tbl._count == 2;
  assert tbl.table.size() == 2;
  assert e.get("a") == ?2;
  assert e.get("b") == ?4;
  assert e.get("c") == null;
  assert e.get("d") == null;

  e.importProps({ 
    table = [var
      ?(("a", 2), null), ?(("b", 4),null)
    ];
    _count = 6;
  });
  tbl := e.exportProps();
  assert tbl._count == 2;

};
