package tiny;

class Benchmark {

  static public function time(){
#if (js || flash9)
    return Date.now().getTime();
#else
    return neko.Sys.time();
#end
  }

  static public function takeTime(f:Void -> Void, ?n:Int = 1) {
    var t = time();
    for (i in 1...n) f();
    return time() - t;
  }
  
}

