package tiny;
import tiny.EIterExt;

class ArrayExt {

  // you should not change the array while iterating
  static public function toEIter<T>(a:Array<T>, ?start:Int = 0, ?stop:Int = -1, ?step:Int = 1):EIter<T>{
    if (start < 0) start = a.length + start;
    if (stop < 0) stop = a.length + stop;
      
    return function(){
      // closure containing counters

      // step is incremetned before accessing the array so substract one step first
      var start_ = start - step;
      var stop_  = stop - step;
      return (step > 0)

        // step > 0
        ? function(){
            if (start_ > stop_)
              throw EndOfIterator.instance;
            else {
              start_ += step;
              return a[start_];
            }
          }

        // step < 0
        : function(){
          if (start_ < stop_)
            throw new EndOfIterator();
          else {
            start_ += step;
            return a[start_];
          }
        }
    }();
  }


}
