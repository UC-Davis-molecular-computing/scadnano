(function(d){"object"==typeof exports&&"object"==typeof module?d(require("../../lib/codemirror"),require("../javascript/javascript"),require("../css/css"),require("../htmlmixed/htmlmixed")):"function"==typeof define&&define.amd?define(["../../lib/codemirror","../javascript/javascript","../css/css","../htmlmixed/htmlmixed"],d):d(CodeMirror)})(function(d){d.defineMode("pug",function(e){function g(){this.javaScriptArguments=this.javaScriptLineExcludesColon=this.javaScriptLine=!1;this.javaScriptArgumentsDepth=
0;this.isInterpolating=!1;this.interpolationNesting=0;this.jsState=d.startState(f);this.restOfLine="";this.isEach=this.isIncludeFiltered=!1;this.scriptType=this.lastTag="";this.isAttrs=!1;this.attrsNest=[];this.inAttributeName=!0;this.attributeIsType=!1;this.attrValue="";this.indentOf=Infinity;this.indentToken="";this.innerState=this.innerMode=null;this.innerModeForLine=!1}function k(c,b){if(c.match("#{"))return b.isInterpolating=!0,b.interpolationNesting=0,"punctuation"}function l(c,b){if(c.match(/^:([\w\-]+)/)){var a;
e&&e.innerModes&&(a=e.innerModes(c.current().substring(1)));a||(a=c.current().substring(1));"string"===typeof a&&(a=d.getMode(e,a));h(c,b,a);return"atom"}}function m(c,b){if(b.isAttrs){n[c.peek()]&&b.attrsNest.push(n[c.peek()]);if(b.attrsNest[b.attrsNest.length-1]===c.peek())b.attrsNest.pop();else if(c.eat(")"))return b.isAttrs=!1,"punctuation";if(b.inAttributeName&&c.match(/^[^=,\)!]+/)){if("="===c.peek()||"!"===c.peek())b.inAttributeName=!1,b.jsState=d.startState(f),"script"===b.lastTag&&"type"===
c.current().trim().toLowerCase()?b.attributeIsType=!0:b.attributeIsType=!1;return"attribute"}var a=f.token(c,b.jsState);b.attributeIsType&&"string"===a&&(b.scriptType=c.current().toString());if(0===b.attrsNest.length&&("string"===a||"variable"===a||"keyword"===a))try{return Function("","var x "+b.attrValue.replace(/,\s*$/,"").replace(/^!/,"")),b.inAttributeName=!0,b.attrValue="",c.backUp(c.current().length),m(c,b)}catch(q){}b.attrValue+=c.current();return a||!0}}function h(c,b,a){a=d.mimeModes[a]||
a;a=e.innerModes?e.innerModes(a)||a:a;a=d.mimeModes[a]||a;a=d.getMode(e,a);b.indentOf=c.indentation();a&&"null"!==a.name?b.innerMode=a:b.indentToken="string"}function p(c,b,a){if(c.indentation()>b.indentOf||b.innerModeForLine&&!c.sol()||a){if(b.innerMode)return b.innerState||(b.innerState=b.innerMode.startState?d.startState(b.innerMode,c.indentation()):{}),c.hideFirstChars(b.indentOf+2,function(){return b.innerMode.token(c,b.innerState)||!0});c.skipToEnd();return b.indentToken}c.sol()&&(b.indentOf=
Infinity,b.indentToken=null,b.innerMode=null,b.innerState=null)}var n={"{":"}","(":")","[":"]"},f=d.getMode(e,"javascript");g.prototype.copy=function(){var c=new g;c.javaScriptLine=this.javaScriptLine;c.javaScriptLineExcludesColon=this.javaScriptLineExcludesColon;c.javaScriptArguments=this.javaScriptArguments;c.javaScriptArgumentsDepth=this.javaScriptArgumentsDepth;c.isInterpolating=this.isInterpolating;c.interpolationNesting=this.interpolationNesting;c.jsState=d.copyState(f,this.jsState);(c.innerMode=
this.innerMode)&&this.innerState&&(c.innerState=d.copyState(this.innerMode,this.innerState));c.restOfLine=this.restOfLine;c.isIncludeFiltered=this.isIncludeFiltered;c.isEach=this.isEach;c.lastTag=this.lastTag;c.scriptType=this.scriptType;c.isAttrs=this.isAttrs;c.attrsNest=this.attrsNest.slice();c.inAttributeName=this.inAttributeName;c.attributeIsType=this.attributeIsType;c.attrValue=this.attrValue;c.indentOf=this.indentOf;c.indentToken=this.indentToken;c.innerModeForLine=this.innerModeForLine;return c};
return{startState:function(){return new g},copyState:function(c){return c.copy()},token:function(c,b){var a;(a=p(c,b))||(c.sol()&&(b.restOfLine=""),b.restOfLine?(c.skipToEnd(),a=b.restOfLine,b.restOfLine=""):a=void 0);if(!a)a:if(b.isInterpolating){if("}"===c.peek()){if(b.interpolationNesting--,0>b.interpolationNesting){c.next();b.isInterpolating=!1;a="punctuation";break a}}else"{"===c.peek()&&b.interpolationNesting++;a=f.token(c,b.jsState)||!0}else a=void 0;a||(b.isIncludeFiltered?(a=l(c,b),b.isIncludeFiltered=
!1,b.restOfLine="string"):a=void 0);if(!a)a:{if(b.isEach)if(c.match(/^ in\b/)){b.javaScriptLine=!0;b.isEach=!1;a="keyword";break a}else if(c.sol()||c.eol())b.isEach=!1;else if(c.next()){for(;!c.match(/^ in\b/,!1)&&c.next(););a="variable";break a}a=void 0}(a=a||m(c,b))||(c.sol()&&(b.javaScriptLine=!1,b.javaScriptLineExcludesColon=!1),b.javaScriptLine?b.javaScriptLineExcludesColon&&":"===c.peek()?(b.javaScriptLine=!1,b.javaScriptLineExcludesColon=!1,a=void 0):(a=f.token(c,b.jsState),c.eol()&&(b.javaScriptLine=
!1),a=a||!0):a=void 0);a||(b.javaScriptArguments?0===b.javaScriptArgumentsDepth&&"("!==c.peek()?(b.javaScriptArguments=!1,a=void 0):("("===c.peek()?b.javaScriptArgumentsDepth++:")"===c.peek()&&b.javaScriptArgumentsDepth--,0===b.javaScriptArgumentsDepth?(b.javaScriptArguments=!1,a=void 0):a=f.token(c,b.jsState)||!0):a=void 0);a||(b.mixinCallAfter?(b.mixinCallAfter=!1,c.match(/^\( *[-\w]+ *=/,!1)||(b.javaScriptArguments=!0,b.javaScriptArgumentsDepth=0),a=!0):a=void 0);a||(a=c.match(/^yield\b/)?"keyword":
void 0);a||(a=c.match(/^(?:doctype) *([^\n]+)?/)?"meta":void 0);(a=a||k(c,b))||(c.match(/^case\b/)?(b.javaScriptLine=!0,a="keyword"):a=void 0);a||(c.match(/^when\b/)?(b.javaScriptLine=!0,b.javaScriptLineExcludesColon=!0,a="keyword"):a=void 0);a||(a=c.match(/^default\b/)?"keyword":void 0);a||(c.match(/^extends?\b/)?(b.restOfLine="string",a="keyword"):a=void 0);a||(c.match(/^append\b/)?(b.restOfLine="variable",a="keyword"):a=void 0);a||(c.match(/^prepend\b/)?(b.restOfLine="variable",a="keyword"):a=
void 0);a||(c.match(/^block\b *(?:(prepend|append)\b)?/)?(b.restOfLine="variable",a="keyword"):a=void 0);a||(c.match(/^include\b/)?(b.restOfLine="string",a="keyword"):a=void 0);a||(c.match(/^include:([a-zA-Z0-9\-]+)/,!1)&&c.match("include")?(b.isIncludeFiltered=!0,a="keyword"):a=void 0);a||(c.match(/^mixin\b/)?(b.javaScriptLine=!0,a="keyword"):a=void 0);a||(c.match(/^\+([-\w]+)/)?(c.match(/^\( *[-\w]+ *=/,!1)||(b.javaScriptArguments=!0,b.javaScriptArgumentsDepth=0),a="variable"):c.match("+#{",!1)?
(c.next(),b.mixinCallAfter=!0,a=k(c,b)):a=void 0);a||(c.match(/^(if|unless|else if|else)\b/)?(b.javaScriptLine=!0,a="keyword"):a=void 0);a||(c.match(/^(- *)?(each|for)\b/)?(b.isEach=!0,a="keyword"):a=void 0);a||(c.match(/^while\b/)?(b.javaScriptLine=!0,a="keyword"):a=void 0);a||((a=c.match(/^(\w(?:[-:\w]*\w)?)\/?/))?(b.lastTag=a[1].toLowerCase(),"script"===b.lastTag&&(b.scriptType="application/javascript"),a="tag"):a=void 0);(a=a||l(c,b))||(c.match(/^(!?=|-)/)?(b.javaScriptLine=!0,a="punctuation"):
a=void 0);a||(a=c.match(/^#([\w-]+)/)?"builtin":void 0);a||(a=c.match(/^\.([\w-]+)/)?"qualifier":void 0);a||("("==c.peek()?(c.next(),b.isAttrs=!0,b.attrsNest=[],b.inAttributeName=!0,b.attrValue="",b.attributeIsType=!1,a="punctuation"):a=void 0);a||(c.match(/^&attributes\b/)?(b.javaScriptArguments=!0,b.javaScriptArgumentsDepth=0,a="keyword"):a=void 0);a||(a=c.sol()&&c.eatSpace()?"indent":void 0);a||(c.match(/^(?:\| ?| )([^\n]+)/)?a="string":c.match(/^(<[^\n]*)/,!1)?(h(c,b,"htmlmixed"),b.innerModeForLine=
!0,a=p(c,b,!0)):a=void 0);a||(c.match(/^ *\/\/(-)?([^\n]*)/)?(b.indentOf=c.indentation(),a=b.indentToken="comment"):a=void 0);a||(a=c.match(/^: */)?"colon":void 0);a||(c.eat(".")?(a=null,"script"===b.lastTag&&-1!=b.scriptType.toLowerCase().indexOf("javascript")?a=b.scriptType.toLowerCase().replace(/"|'/g,""):"style"===b.lastTag&&(a="css"),h(c,b,a),a="dot"):a=void 0);(b=a)||(c.next(),b=null);c=b;return!0===c?null:c}}},"javascript","css","htmlmixed");d.defineMIME("text/x-pug","pug");d.defineMIME("text/x-jade",
"pug")});
