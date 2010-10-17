import tiny.EIter;
import tiny.ArrayExt;

using tiny.ArrayExt;
using tiny.EIter;

class Test {

  static function main() {
    var a = [ 1, 2, 3];

    trace("toEIter test");
    trace([2]);
    trace(a.toEIter(1,-2).toArray());

    trace("backward");
    trace([3,2,1]);
    trace(a.toEIter(-1,0,-1).toArray());

    trace("map test");
    trace([2,3,4]);
    trace(a.toEIter().map($1 + 1).toArray());

    trace("zip2");
    trace([2,4,6]);
    trace(a.toEIter().zip2(a.toEIter(), $1 + $2).toArray());

    trace("chain");
    trace([1,2,3,1,2,3]);
    trace([a.toEIter(),a.toEIter()].toEIter().chain().toArray());
  }    

}
