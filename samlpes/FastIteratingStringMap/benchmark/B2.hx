package ;

import haxe.Timer;
import org.zamedev.lib.FastIteratingStringMap;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.ExprTools;
#end


@:publicFields
class B2 {
    
    static var keys:Array<String>;
    
    @:extern inline static function iter_only(map:Map.IMap<String,Int>){
        var dummy = 0;
        for (key in map.keys()) {
            dummy++;
        }
        for (value in map) {
            dummy++;
        }
    }
    
    @:extern inline static function setgetremove_only(map:Map.IMap<String,Int>){
        for (key in keys) {
            map.set(key, 1);
            map.set(key, map.exists(key) ? (map.get(key) + 1) : 0);
        }
        for (key in keys) {
            //map.remove(key);
        }
    }
    
    @:extern inline static function iter_get(map:Map.IMap<String,Int>){
        var dummy:Int = 0;
        for (key in map.keys()) {
            dummy += (map.exists(key) ? map.get(key) : 0);
        }
        for (value in map) {
            dummy++;
        }
    }
    
    @:extern inline static function fill(m:Map.IMap<String,Int>){
        for (k in keys) m.set(k,123);
        return m;
    }
    static function run(){

        for (key_n in [10,50,100,250,1000,5000,10000]){
            keys = [for (k in 0...key_n) "KX_$k"];
            var maps = [
                
                {map:function():Map.IMap<String,Int> return new NewStringMap(),msg:          "NewStringMap          "},
                {map:function():Map.IMap<String,Int> return new haxe.ds.StringMap(),msg:     "haxe.ds.StringMap     "},
                {map:function():Map.IMap<String,Int> return new FastIteratingStringMap(),msg:"FastIteratingStringMap"}
                
            ];
            var iter_N = 100000000;
            var iter_N_slow = 1000000;
            trace('KEYS: $key_n');
            trace('-- iter exists get');
            
            bench(['iter exists get      ','iter only            ','set exists get remove','fill                 '      ], // bench type
                  [iter_get,               iter_only,               setgetremove_only,      fill       ], // inner loop body
                  [true    ,               true,                    true,                   false      ], // reuse map
                  [iter_N,                 iter_N,                  iter_N_slow,            iter_N_slow]  // iterations == (keys_n * outer_loop)
            );
        }
         
    }
    
    #if macro
        static function get_expr_arr(e_arr:Expr) return switch e_arr.expr {
            case EArrayDecl(arr):arr;
            case _:throw "invalid expression, expected array";
        }
    #end
    
    macro static function bench(e_titles:Expr,e_bodies:Expr,e_reuse_map_flags:Expr,e_iterations:Expr){
        
        var e_titles = get_expr_arr(e_titles);
        var e_bodies = get_expr_arr(e_bodies);
        var e_reuse  = get_expr_arr(e_reuse_map_flags);
        var e_iterations = get_expr_arr(e_iterations);
        var e_arr = [for (i in 0...e_titles.length){
            var e_title    = e_titles[i];
            var e_body     = e_bodies[i];
            var e_iter_n   = e_iterations[i];
            var reuse_map  = e_reuse[i].getValue();
            var e_iter_n   = macro Std.int($e_iter_n/key_n);
            var e_header   = macro {
                trace("\n\n" + $e_title + " : iterations: " + $e_iter_n + " || map size: " + key_n );
            };
            var expr = if (reuse_map) macro @:mergeBlock {
                @:mergeBlock $e_header;
                for (m in maps) {
                    var map = m.map();
                    bench_inner($e_body,map,m.msg,$e_iter_n);
                }
            } else macro @:mergeBlock {
                $e_header;
                for (m in maps) {
                    bench_inner($e_body,m.map(),m.msg,$e_iter_n);
                }
            };
            expr;
        }];
        var e_benchmarks = macro $b{e_arr};
        //var s = new haxe.macro.Printer().printExpr(e_benchmarks);
        //trace(s);
        return e_benchmarks;
    }
    
    macro static function bench_inner(e_body:Expr,e_new_map:Expr,e_msg:Expr,e_iter_n:Expr){
        var e = macro @:mergeBlock { 
            var t0 = Timer.stamp();
            var map = $e_new_map;
            var iter_n = $e_iter_n;
            for(i in 0...iter_n){
                $e_body(map);
            }
            var t1 = Timer.stamp();
            var t_elapsed = t1 - t0;
            var i_per_sec = iter_n / t_elapsed;
            var msg = $e_msg;
            var s = [msg,': time elapsed: ',Std.string(t_elapsed).substr(0,5),', iterations/s: ',Std.string(i_per_sec).substr(0,10)].join('');
            trace(s);
        }
        var s = new haxe.macro.Printer().printExpr(e);
        //trace(s);
        return e;
    }
    
    static function main(){
        run();
    }
    
}
