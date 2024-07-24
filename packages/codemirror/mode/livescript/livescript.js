(function(f){"object"==typeof exports&&"object"==typeof module?f(require("../../lib/codemirror")):"function"==typeof define&&define.amd?define(["../../lib/codemirror"],f):f(CodeMirror)})(function(f){f.defineMode("livescript",function(){var n=function(a,b){var d=b.next||"start";b.next=b.next;var l=g[d];if(l.splice){for(d=0;d<l.length;++d){var e=l[d];if(e.regex&&a.match(e.regex))return b.next=e.next||b.next,e.token}a.next();return"error"}if(a.match(e=g[d])){if(e.regex&&a.match(e.regex))return b.next=
e.next,e.token;a.next();return"error"}a.next();return"error"};return{startState:function(){return{next:"start",lastToken:{style:null,indent:0,content:""}}},token:function(a,b){for(;a.pos==a.start;)var d=n(a,b);b.lastToken={style:d,indent:a.indentation(),content:a.current()};return d.replace(/\./g," ")},indent:function(a){var b=a.lastToken.indent;a.lastToken.content.match(p)&&(b+=2);return b}}});var p=RegExp("(?:[({[=:]|[-~]>|\\b(?:e(?:lse|xport)|d(?:o|efault)|t(?:ry|hen)|finally|import(?:\\s*all)?|const|var|let|new|catch(?:\\s*(?![\\d\\s])[$\\w\\xAA-\\uFFDC](?:(?!\\s)[$\\w\\xAA-\\uFFDC]|-[A-Za-z])*)?))\\s*$"),
c={token:"string",regex:".+"},g={start:[{token:"comment.doc",regex:"/\\*",next:"comment"},{token:"comment",regex:"#.*"},{token:"keyword",regex:"(?:t(?:h(?:is|row|en)|ry|ypeof!?)|c(?:on(?:tinue|st)|a(?:se|tch)|lass)|i(?:n(?:stanceof)?|mp(?:ort(?:\\s+all)?|lements)|[fs])|d(?:e(?:fault|lete|bugger)|o)|f(?:or(?:\\s+own)?|inally|unction)|s(?:uper|witch)|e(?:lse|x(?:tends|port)|val)|a(?:nd|rguments)|n(?:ew|ot)|un(?:less|til)|w(?:hile|ith)|o[fr]|return|break|let|var|loop)(?![$\\w]|-[A-Za-z]|\\s*:(?![:=]))"},
{token:"constant.language",regex:"(?:true|false|yes|no|on|off|null|void|undefined)(?![$\\w]|-[A-Za-z]|\\s*:(?![:=]))"},{token:"invalid.illegal",regex:"(?:p(?:ackage|r(?:ivate|otected)|ublic)|i(?:mplements|nterface)|enum|static|yield)(?![$\\w]|-[A-Za-z]|\\s*:(?![:=]))"},{token:"language.support.class",regex:"(?:R(?:e(?:gExp|ferenceError)|angeError)|S(?:tring|yntaxError)|E(?:rror|valError)|Array|Boolean|Date|Function|Number|Object|TypeError|URIError)(?![$\\w]|-[A-Za-z]|\\s*:(?![:=]))"},{token:"language.support.function",
regex:"(?:is(?:NaN|Finite)|parse(?:Int|Float)|Math|JSON|(?:en|de)codeURI(?:Component)?)(?![$\\w]|-[A-Za-z]|\\s*:(?![:=]))"},{token:"variable.language",regex:"(?:t(?:hat|il|o)|f(?:rom|allthrough)|it|by|e)(?![$\\w]|-[A-Za-z]|\\s*:(?![:=]))"},{token:"identifier",regex:"(?![\\d\\s])[$\\w\\xAA-\\uFFDC](?:(?!\\s)[$\\w\\xAA-\\uFFDC]|-[A-Za-z])*\\s*:(?![:=])"},{token:"variable",regex:"(?![\\d\\s])[$\\w\\xAA-\\uFFDC](?:(?!\\s)[$\\w\\xAA-\\uFFDC]|-[A-Za-z])*"},{token:"keyword.operator",regex:"(?:\\.{3}|\\s+\\?)"},
{token:"keyword.variable",regex:"(?:@+|::|\\.\\.)",next:"key"},{token:"keyword.operator",regex:"\\.\\s*",next:"key"},{token:"string",regex:"\\\\\\S[^\\s,;)}\\]]*"},{token:"string.doc",regex:"'''",next:"qdoc"},{token:"string.doc",regex:'"""',next:"qqdoc"},{token:"string",regex:"'",next:"qstring"},{token:"string",regex:'"',next:"qqstring"},{token:"string",regex:"`",next:"js"},{token:"string",regex:"<\\[",next:"words"},{token:"string.regex",regex:"//",next:"heregex"},{token:"string.regex",regex:"\\/(?:[^[\\/\\n\\\\]*(?:(?:\\\\.|\\[[^\\]\\n\\\\]*(?:\\\\.[^\\]\\n\\\\]*)*\\])[^[\\/\\n\\\\]*)*)\\/[gimy$]{0,4}",
next:"key"},{token:"constant.numeric",regex:"(?:0x[\\da-fA-F][\\da-fA-F_]*|(?:[2-9]|[12]\\d|3[0-6])r[\\da-zA-Z][\\da-zA-Z_]*|(?:\\d[\\d_]*(?:\\.\\d[\\d_]*)?|\\.\\d[\\d_]*)(?:e[+-]?\\d[\\d_]*)?[\\w$]*)"},{token:"lparen",regex:"[({[]"},{token:"rparen",regex:"[)}\\]]",next:"key"},{token:"keyword.operator",regex:"\\S+"},{token:"text",regex:"\\s+"}],heregex:[{token:"string.regex",regex:".*?//[gimy$?]{0,4}",next:"start"},{token:"string.regex",regex:"\\s*#{"},{token:"comment.regex",regex:"\\s+(?:#.*)?"},
{token:"string.regex",regex:"\\S+"}],key:[{token:"keyword.operator",regex:"[.?@!]+"},{token:"identifier",regex:"(?![\\d\\s])[$\\w\\xAA-\\uFFDC](?:(?!\\s)[$\\w\\xAA-\\uFFDC]|-[A-Za-z])*",next:"start"},{token:"text",regex:"",next:"start"}],comment:[{token:"comment.doc",regex:".*?\\*/",next:"start"},{token:"comment.doc",regex:".+"}],qdoc:[{token:"string",regex:".*?'''",next:"key"},c],qqdoc:[{token:"string",regex:'.*?"""',next:"key"},c],qstring:[{token:"string",regex:"[^\\\\']*(?:\\\\.[^\\\\']*)*'",next:"key"},
c],qqstring:[{token:"string",regex:'[^\\\\"]*(?:\\\\.[^\\\\"]*)*"',next:"key"},c],js:[{token:"string",regex:"[^\\\\`]*(?:\\\\.[^\\\\`]*)*`",next:"key"},c],words:[{token:"string",regex:".*?\\]>",next:"key"},c]},h;for(h in g)if(c=g[h],c.splice)for(var k=0,q=c.length;k<q;++k){var m=c[k];"string"===typeof m.regex&&(g[h][k].regex=new RegExp("^"+m.regex))}else"string"===typeof m.regex&&(g[h].regex=new RegExp("^"+c.regex));f.defineMIME("text/x-livescript","livescript")});
