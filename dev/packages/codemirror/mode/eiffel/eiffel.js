(function(d){"object"==typeof exports&&"object"==typeof module?d(require("../../lib/codemirror")):"function"==typeof define&&define.amd?define(["../../lib/codemirror"],d):d(CodeMirror)})(function(d){d.defineMode("eiffel",function(){function h(b){for(var a={},c=0,e=b.length;c<e;++c)a[b[c]]=!0;return a}function k(b,a){if(b.eatSpace())return null;var c=b.next();return'"'==c||"'"==c?(c=l(c,"string"),a.tokenize.push(c),c(b,a)):"-"==c&&b.eat("-")?(b.skipToEnd(),"comment"):":"==c&&b.eat("=")?"operator":
/[0-9]/.test(c)?(b.eatWhile(/[xXbBCc0-9\.]/),b.eat(/[\?!]/),"ident"):/[a-zA-Z_0-9]/.test(c)?(b.eatWhile(/[a-zA-Z_0-9]/),b.eat(/[\?!]/),"ident"):/[=+\-\/*^%<>~]/.test(c)?(b.eatWhile(/[=+\-\/*^%<>~]/),"operator"):null}function l(b,a,c){return function(e,m){for(var f=!1,g;null!=(g=e.next());){if(g==b&&(c||!f)){m.tokenize.pop();break}f=!f&&"%"==g}return a}}var n=h("note across when variant until unique undefine then strip select retry rescue require rename reference redefine prefix once old obsolete loop local like is inspect infix include if frozen from external export ensure end elseif else do creation create check alias agent separate invariant inherit indexing feature expanded deferred class Void True Result Precursor False Current create attached detachable as and implies not or".split(" ")),
p=h(":=;and then;and;or;<<;>>".split(";"));return{startState:function(){return{tokenize:[k]}},token:function(b,a){a=a.tokenize[a.tokenize.length-1](b,a);"ident"==a&&(a=b.current(),a=n.propertyIsEnumerable(b.current())?"keyword":p.propertyIsEnumerable(b.current())?"operator":/^[A-Z][A-Z_0-9]*$/g.test(a)?"tag":/^0[bB][0-1]+$/g.test(a)?"number":/^0[cC][0-7]+$/g.test(a)?"number":/^0[xX][a-fA-F0-9]+$/g.test(a)?"number":/^([0-9]+\.[0-9]*)|([0-9]*\.[0-9]+)$/g.test(a)?"number":/^[0-9]+$/g.test(a)?"number":
"variable");return a},lineComment:"--"}});d.defineMIME("text/x-eiffel","eiffel")});
