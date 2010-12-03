/*
  description:
  The Std is using a simple iterator interface:

  interafece<T>{
    function hasNext(): Bool // return true if there is an element
    function next():T        // return that next element
  }

  flaws: For each element you have to call two functions.

  So this E(exception)Iterator tries to use only one function.
  Instead of hasNext() returning false an EndOfIterator is thrown

  Much inilining can take place. This should result in fast code (?)

  I think its hard to get same amount of features with less code.

  The generated code is more verbose due to HaXe's try catch implementation.
  So maybe putting that try catch into a shared fixes that without loosing too
  much performance?

  Now you may think "abusing Exceptions for this purpose is insane". Well maybe
  you're right. But for all targets except PHP this is working very well.

  bencharks: http://mawercer.de/~marc/bench and http://mawercer.de/~marc/bench2

  So this code is somewhere between genious and insane :)

*/

package tiny;
using tiny.ArrayExt;

class EndOfIterator {
  public static var instance = new EndOfIterator();
  public function new() { }
} // end of items (TODO extend from Exception type?)

typedef EIter<T> = Void -> T;

class EIterExt{

  static public function catchEndOfIterator<T>(work: Void -> T, ?else_: Void -> T){
    return try{
      work();
    }catch(e:EndOfIterator){
      if (else_ != null) else_();
    }
  }

  static public function map<A,B>(next:EIter<A>, f:A->B): EIter<B> {
    return function(){ return f(next()); };
  } 

  static public function filter<T>( next:EIter<T>, p: T -> Bool ):EIter<T>{
    return function(){
      var e=next();
      while (!p(e)) e=next();
      return e;
    }
  }

  static public function isEmpty<T>(next: EIter<T>):Bool {
    return EIterExt.catchEndOfIterator(function(){ next(); return true; }, function(){ return false; });
  }

  static public function each<T>(next: EIter<T>, f:T->Void ){
    EIterExt.catchEndOfIterator(function(){ while (true) f(next()); });
  }

  static public function take<T>(next:EIter<T>, n:Int):EIter<T>{
    return function(){
      if (n-- <= 0)
        throw new EndOfIterator(); // why don't I need a colon here?
      else {
        return next();
      }
    }
  }

  static public function drop<T>(next:EIter<T>, n:Int):EIter<T>{
    return function(){
      if (n > 0){
        while (n-- > 0) next();
      }
      return next();
    }
  }

  static public function zip2<A,B,C>(
      next:EIter<A>,
      next2:EIter<B>,
      f:A -> B -> C
  ) :EIter<C> {
    return function(){ return f(next(), next2()); };
  }

  static public function fold<T,B>(next:EIter<T>, f:T -> B -> B, first:B):B{
    var r = first;
    // inline or optimize this!
    EIterExt.each(next, function(n){ r = f(n, r); });
    return r;
  }

  // returns an iterator iterating over all iterators in sequence.
  static public function chain<T>(nexts:EIter<EIter<T>>):EIter<T>{
    return function(){
      var next = null;
      return function(){
        if (next == null)
          next = nexts();
        return EIterExt.catchEndOfIterator(next, function(){ next = nexts(); return next(); });
      }
    }();
  }
  
  static public function count<T>(next:EIter<T>):Int{
    var c = 0;
    EIterExt.each(next, function(e){ c++; });
    return c;
  }

  static public function reverse<T>(next:EIter<T>):EIter<T>{
    return EIterExt.toArray(next).toEIter( -1, 0, -1);
  }

  // get all elements and store them in an array. Then return a new iterator
  static public function strict<T>(next:EIter<T>):EIter<T>{
    return EIterExt.toArray(next).toEIter();
  }

  static public function fold2<T>(next:EIter<T>, f:T -> T -> T, ?ifempty:T):T {
    return EIterExt.catchEndOfIterator(
      function(){
        var first = next();
        return EIterExt.fold(next, f, first);
      },
      function(){ return ifempty; }
    );
  }
  
  public static function mkString(next: EIter<String>, ?prefix: String = '(', ?suffix: String = ')', ?sep = ', '):String {
    return prefix + fold2(next, function(a,b){ return b+sep+a; }, "") + suffix;
  }

  // ARRAY interface

  // see ArrayExt

  /* This version has been used for the benchmark
  static public function arrayToEIter<T>(a:Array<T>):EIter<T>{
    return function(){
      var i = 0;
      return function(){
        if (i >= a.length)
          throw new EndOfIterator();
        else return a[i++];
      }
    }();
  }
  */

  static public function toArray<T>(next:EIter<T>):Array<T>{
    var a = new Array();
    EIterExt.each(next, function(n){ a.push(n); } );
    return a;
  }

  // interfacing with Std iterator:

  // Std to EIter see IteratorExt

  // to Std Iterator
  static public function toIterator<T>(next:EIter<T>):Iterator<T>{
    return function(){
      var e=null; // each iterator must have its own copy of e
      return {
        hasNext: function(){
          return EIterExt.catchEndOfIterator(
          function(){
            e = next();
            return true;
          }, function(){ return false; }
          );
        },
        next: function(){
          return e;
        }
      };
    }();
  }

}
