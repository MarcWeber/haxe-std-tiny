#if !js
import haxe.macro.Expr;
import haxe.macro.Context;
#end

using Lambda;

class Template {

  #if !js

  /*

    var user = {
      name: "Marc<br/>Weber",
      age: "99",
      code: "<h2>computing></h2>",
    };

    trace(MyHTMLTool.html_dsl("
          <h1> `?=user.name</h1>
          age: `?user.age
          code: `?user.code
    "));

    traces:

    || Test.hx:16:
    ||           <h1>Marc<br/>Weber</h1>
    ||           age: 99
    ||           code: &lt;h2&gt;computing&gt;&lt;/h2&gt;
    ||

  */

   @:macro static public function fromString(input:Expr) { return Template.template(input, false); }
   @:macro static public function fromFile  (input:Expr) { return Template.template(input, true); }
   static public function template(input:Expr, file:Bool) {
     var p = function(e) return {expr: e, pos: input.pos};
     var regex = ~/([a-zA-Z_0-9.]+)/;
     var sToExpr = function(s:String){
      #if !js
       if (file){
         s = neko.io.File.getContent("templates/"+s);
       }
      #end

       var pieces = new Array();
       var li = s.split('`?');
       var str = function(s) return EConst(CString(s));
       // var addExprQuoted = pieces.
       for (l in li.slice(1)){
         var quoted = true;
         if (l.charAt(0) == "="){
           quoted = false;
           l = l.substr(1);
         }
         // foo.bar -> EField
         regex.match(l);
         var param = regex.matched(1);
         var rest = l.substr(param.length);
         var items = param.split(".").array();
         var i = items.slice(1).fold(function(s, r){
               return EField(p(r), s);
            }, EConst(CIdent(items[0])));
         if (quoted)
           i = ECall( p(EField(p(EConst(CType("StringTools"))), "htmlEscape")), [p(i)]);
         pieces.push(i);
         pieces.push(str(rest));
       }
       // concatenate pieces by + operator
       // yes, StringBuffer might be faster - I don't care now
       return pieces.fold(function(e,er){
           return EBinop(OpAdd, p(er), p(e));
       },str(li[0]));
     }
     var expr = switch (input.expr){
       case EConst(x):
         switch (x){
           case CString(s):
             sToExpr(s);
           default: throw "invalid input";
         }
       default: throw "invalid input";
     }
     return { expr : expr, pos: input.pos };
   }
  #end

   static public function wrap(s:String, tag:String, ?attributes:String){
     return "<"+tag+" "+attributes+">"+s+"</"+tag+">";
   }

}
