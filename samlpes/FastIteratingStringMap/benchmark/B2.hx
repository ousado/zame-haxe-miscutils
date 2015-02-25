package ;

import haxe.Timer;
import org.zamedev.lib.FastIteratingStringMap;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
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
            var iter_n = 1000000;
            trace('KEYS: $key_n');
            trace('-- fill ');
            untyped global.gc();
            for (m in maps){
                //var map = m.map();
                bench(fill,m.map(),m.msg);
            }
            trace('-- iter exists get');
            untyped global.gc();
            for (m in maps){
                var map = fill(m.map());
                bench(iter_get,map,m.msg);
            }
            trace('-- iter only');
            untyped global.gc();
            for (m in maps){
                var map = fill(m.map());
                bench(iter_only,map,m.msg);
            }
            trace('-- set exists get remove');
            untyped global.gc();
            var iter_n = 500;
            for (m in maps){
                var map = m.map();
                bench(setgetremove_only,map,m.msg);
            }
            trace('--');
            trace('--');
        }
         
    }
    
    macro static function bench(e_body:Expr,e_new_map:Expr,e_msg:Expr){
        var e = macro @:mergeBlock { 
            var t0 = Timer.stamp();
            var map = $e_new_map;
            
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
        trace(s);
        return e;
    }
    
    static function main(){
        run();
    }
    
}
