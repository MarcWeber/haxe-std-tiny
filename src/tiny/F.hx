// Idea taken from scuts library: Use Macro to rewrite short lambda functions

package tiny;
using Lambda;

import haxe.macro.Expr;

/*
   Exapmle F.n:

    trace( [1,2].map(tiny.F.n(_ +2)));  // {3, 4} (a list)
    trace(tiny.F.n(a,b, a+b)(1,2));     // 3
    // _ is special:
    trace(tiny.F.n(_1+_2)(1,2));        // 3
    trace(tiny.F.n(_1+_3)(1,2,3));      // 4
    trace(tiny.F.n(_ + _3)(-10,1,2,3)); // -7

    // note: If you use _1 and _3 only this is treated as (_1, _2, _3, expr)
    // but may be treated as (_1, _2, _3, expr) in the future.
*/

class F 
{


  // this is very similar to scuts but the a=result syntax is not supported.
  // use a, result instead. This is for simplicity

  @:macro public static function n(exprs:Array<Expr>):Expr 
  {
    var p = haxe.macro.Context.currentPos();

    var nameToFunArg = function(s){
      return { name: s, opt: false, type : null, value : null };
    };

    var toFunArg = function(a:Expr):FunctionArg{
                      // EConst(CIdent(a))
                      var name = switch (a.expr){
                            case EConst(x):
                              switch(x){
                                case CIdent(s):
                                  s;
                                default:
                                  throw "unexpected"+x;
                              }
                            default:
                              throw "unexpected : "+a.expr;
                          };
                      return nameToFunArg(name);
                      };


    var with_p : ExprDef -> Expr
                = function(e){return {pos: p, expr: e};};
    var args:Array<FunctionArg> = [];

    for (a in exprs.slice(0, exprs.length - 1))
        args.push(toFunArg(a));

    // if no args has been passed look for _1 _2 or _
    if (exprs.length == 1){
      var args_2 = { no_number: false, max: -1 }
      find_place_holders ([exprs[0]], args_2);
      var names = [];
      if (args_2.no_number) names.push("_");

      for (k in 1...(args_2.max+1)) names.push("_"+k);
      names.sort(function(s1,s2){ return (s1 == s2) ? 0 : (s1 < s2 ? -1 : 1);});
      for (a in names) args.push(nameToFunArg(a));
    }

    return with_p(
        EFunction(
          null,
          {
             args : args,
             ret : null,
             expr : with_p(EBlock([with_p(EReturn( exprs[exprs.length-1]))])),
             params : [],
          }));
  }



  // traverse ast finding _[0-9] identifiers
  static public function find_place_holders (es:Array<Expr>, a:{no_number: Bool, max: Int}){
      var ts = function(e){ find_place_holders(e, a); };
      var t = function(e){ find_place_holders([e], a); };
      var consider = function(s){
        if (s == "_") a.no_number = true;
        else if (s.charAt(0) == '_'){
          var n = Std.parseInt(s.substr(1));
          if (n > a.max) a.max = n;
        }
      };
      for (e in es){
        if (e == null) continue;
        switch (e.expr){
          case EConst( c ):
              switch(c){
                case CString(s) : consider(s);
                case CIdent(s)  : consider(s);
                default: [];
              }
          case EArray( e1, e2): ts([e1,e2]);
          case EBinop( op, e1, e2 ): ts([e1,e2]);
          case EField( e, field ): t(e);
          case EType( e, field ): t(e);
          case EParenthesis( e ): t(e);
          case EObjectDecl( fields ): for (f in fields) t(f.expr);
          case EArrayDecl( values ): ts(values);
          case ECall( e, params): t(e); ts(params); // TODO stop recursion if function is F.n
          case ENew( t , params ): ts(params);
          case EUnop( op , postFix , e ): t(e);
          case EVars( vars ): for (v in vars) t(v.expr);
          case EFunction( name , f ): t(f.expr); for (a in f.args) t(a.value);
          case EBlock( exprs ): ts(exprs);
          case EFor( it, expr): t(expr);
          case EIn( e1, e2): t(e1); t(e2);
          case EIf( econd , eif , eelse ): ts([econd, eif, eelse]);
          case EWhile( econd, e , normalWhile ): t(econd); t(e);
          case ESwitch( e, cases , edef ): t(e); for (c in cases) t(c.expr); t(edef);
          case ETry( e , catches ): t(e); for (c in catches) t(c.expr);
          case EReturn( e ): t(e);
          case EBreak:
          case EContinue:
          case EUntyped( e ): t(e);
          case EThrow( e ): t(e);
          case ECast( e , t_ ): t(e);
          case EDisplay( e , isCall ): t(e);
          case EDisplayNew( t ):
          case ETernary( econd , eif , eelse ): ts([econd, eif, eelse]);
          case ECheckType( e , t_): t(e);
          default:
            throw "unexpected "+ e.expr;
        };
      }
    }
}
