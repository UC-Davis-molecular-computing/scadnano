(function(g){"object"==typeof exports&&"object"==typeof module?g(require("../../lib/codemirror")):"function"==typeof define&&define.amd?define(["../../lib/codemirror"],g):g(CodeMirror)})(function(g){g.defineMode("ntriples",function(){function f(d,b){var c=d.location;d.location=c==a.PRE_SUBJECT&&"<"==b?a.WRITING_SUB_URI:c==a.PRE_SUBJECT&&"_"==b?a.WRITING_BNODE_URI:c==a.PRE_PRED&&"<"==b?a.WRITING_PRED_URI:c==a.PRE_OBJ&&"<"==b?a.WRITING_OBJ_URI:c==a.PRE_OBJ&&"_"==b?a.WRITING_OBJ_BNODE:c==a.PRE_OBJ&&
'"'==b?a.WRITING_OBJ_LITERAL:c==a.WRITING_SUB_URI&&">"==b?a.PRE_PRED:c==a.WRITING_BNODE_URI&&" "==b?a.PRE_PRED:c==a.WRITING_PRED_URI&&">"==b?a.PRE_OBJ:c==a.WRITING_OBJ_URI&&">"==b?a.POST_OBJ:c==a.WRITING_OBJ_BNODE&&" "==b?a.POST_OBJ:c==a.WRITING_OBJ_LITERAL&&'"'==b?a.POST_OBJ:c==a.WRITING_LIT_LANG&&" "==b?a.POST_OBJ:c==a.WRITING_LIT_TYPE&&">"==b?a.POST_OBJ:c==a.WRITING_OBJ_LITERAL&&"@"==b?a.WRITING_LIT_LANG:c==a.WRITING_OBJ_LITERAL&&"^"==b?a.WRITING_LIT_TYPE:" "!=b||c!=a.PRE_SUBJECT&&c!=a.PRE_PRED&&
c!=a.PRE_OBJ&&c!=a.POST_OBJ?c==a.POST_OBJ&&"."==b?a.PRE_SUBJECT:a.ERROR:c}var a={PRE_SUBJECT:0,WRITING_SUB_URI:1,WRITING_BNODE_URI:2,PRE_PRED:3,WRITING_PRED_URI:4,PRE_OBJ:5,WRITING_OBJ_URI:6,WRITING_OBJ_BNODE:7,WRITING_OBJ_LITERAL:8,WRITING_LIT_LANG:9,WRITING_LIT_TYPE:10,POST_OBJ:11,ERROR:12};return{startState:function(){return{location:a.PRE_SUBJECT,uris:[],anchors:[],bnodes:[],langs:[],types:[]}},token:function(d,b){var c=d.next();if("<"==c){f(b,c);var h="";d.eatWhile(function(e){return"#"!=e&&
">"!=e?(h+=e,!0):!1});b.uris.push(h);if(d.match("#",!1))return"variable";d.next();f(b,">");return"variable"}if("#"==c){var k="";d.eatWhile(function(e){return">"!=e&&" "!=e?(k+=e,!0):!1});b.anchors.push(k);return"variable-2"}if(">"==c)return f(b,">"),"variable";if("_"==c){f(b,c);var l="";d.eatWhile(function(e){return" "!=e?(l+=e,!0):!1});b.bnodes.push(l);d.next();f(b," ");return"builtin"}if('"'==c)return f(b,c),d.eatWhile(function(e){return'"'!=e}),d.next(),"@"!=d.peek()&&"^"!=d.peek()&&f(b,'"'),"string";
if("@"==c){f(b,"@");var m="";d.eatWhile(function(e){return" "!=e?(m+=e,!0):!1});b.langs.push(m);d.next();f(b," ");return"string-2"}if("^"==c){d.next();f(b,"^");var n="";d.eatWhile(function(e){return">"!=e?(n+=e,!0):!1});b.types.push(n);d.next();f(b,">");return"variable"}" "==c&&f(b,c);"."==c&&f(b,c)}}});g.defineMIME("application/n-triples","ntriples");g.defineMIME("application/n-quads","ntriples");g.defineMIME("text/n-triples","ntriples")});
