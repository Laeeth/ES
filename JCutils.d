import orange.util.Reflection : nameOfFieldAt;
import std.range : lockstep;

auto class_arr_dup(T)(T[] array) {
	pragma(msg,typeof(array));
    T[] res = new T[array.length]; 
    foreach(el_old, ref el_new; lockstep(array,res)) {
		pragma(msg,typeof(el_old));
        el_new = new T(el_old);
    }
    return res;
}

auto class_arr_dup_mt(T)(T[] array) {
    T[] res = new T[array.length];
    foreach(el_old, ref el_new; taskPool.parallel(lockstep(array,res))) {
        el_new = new T(el_old);
    }
    return res;
}


//provides an associative array, by name, of the fields of obj
//that are of type U. Useful for reading in config files or for
//inspection of variables. 
//Possible future: provide a function that returns all of the
//fields. In a tuple? A class/struct?
auto string_access(U,T)(T obj) {
	U[string] dict;
	mixin(dictString!(T, U, "obj"));
	return(dict);
}

/*
mixin template Object_dict(T, string name) {
	TypeOfField!(T,nameOfFieldAt!(T,0))[string] dict;
}
*/

//initialiser for dictStringImpl
template dictString (T, U , string name) {
	const dictString = dictStringImpl!(T, U, name, 0);
}

//Fun, fun, fun! recursive templates generate the (reference) assignments of
//aggregate members to the associative array as a code string.
template dictStringImpl (T, U, string name, size_t i) {
	static if(T.tupleof.length == 0)
		const dictStringImpl = "";
	else static if(T.tupleof.length -1 == i) {
		static if(is(typeof(T.tupleof[i]) == U))
			const dictStringImpl = "dict[\"" ~ nameOfFieldAt!(T,i)
						~ "\"] = " ~ name ~ "." 
						~ nameOfFieldAt!(T,i) ~ ";";
		else 
			const dictStringImpl = "";
	}
	else {
		static if(is(typeof(T.tupleof[i]) == U))
			const dictStringImpl = "dict[\"" ~ nameOfFieldAt!(T,i) 
						~ "\"] = " ~ name ~ "." 
						~ nameOfFieldAt!(T,i) ~ ";\n" 
						~ dictStringImpl!(T, U, name, i+1);
		else
			const dictStringImpl = dictStringImpl!(T, U, name, i+1);
	}
}
