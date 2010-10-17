class IteratorExt {

  static public function toEIter<T>(iter:Iterator<T>):EIter<T>{
    return function(){
      if (iter.hasNext())
        return iter.next();
      else throw new EndOfIterator();
    }
  }

}
