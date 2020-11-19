@preprocessor typescript

@{% 
import moo from 'moo';
import {builder as g} from '@gram-data/gram-builder';
import {tokens} from '@gram-data/gram-ast';

let lexer = moo.compile({
    whitespace: {match: /\s+/, lineBreaks: true},
    lineComment: {match:/\/\/.*?\n?$/},
    hexadecimal: tokens.hexadecimal,
    octal: tokens.octal,
    measurement: tokens.measurement,
    decimal: tokens.decimal,
    integer: tokens.integer,
    taggedString: {match: tokens.taggedString},
    boolean: [ 'true', 'TRUE', 'True', 'false', 'FALSE', 'False' ],
    symbol: tokens.symbol,
    identifier: tokens.identifier,
    doubleQuotedString: {match:tokens.doubleQuotedString, value: (s:string) => s.slice(1,-1)},
    singleQuotedString: {match:tokens.singleQuotedString, value: (s:string) => s.slice(1,-1)},
    tickedString:       {match:tokens.tickedString,       value: (s:string) => s.slice(1,-1)},
    '-->':'-->',
    '--':'--',
    '<--':'<--',
    '-[]->':'-[]->',
    '-[]-':'-[]-',
    '<-[]-':'<-[]-',
    '<-[':'<-[',
    ']->':']->',
    '-[':'-[',
    ']-':']-',
    '{': '{',
    '}': '}',
    '[': '[',
    ']': ']',
    '(': '(',
    ')': ')',
    ',': ',',
    ':': ':',
    '`': '`',
    '\'': '\'',
    'ø': 'ø'
}) as unknown as NearleyLexer

%}

@lexer lexer

PathSequence -> (Path ",":? _  {% ([pp]) => pp %}):+ EOL:? {% ([pp]) => g.seq( g.flatten(pp) ) %}

Path ->
    NodePattern     {% id %}
  | PathComposition {% id %}
  | Comment         {% id %}

NodePattern ->
    Node Edge NodePattern
      {% ([np,es,ep]) => g.cons([np,ep], {kind:es.kind, id:es.id, labels:es.labels, record:es.record} ) %}
  | Node {% id %}

Node ->
  "(" _ Attributes _ ")" 
    {% ([,,content]) => g.node(content.id, content.labels, content.record) %}

Edge ->
    "-[" _ Attributes "]->"   
              {% ([,,content]) => ({kind:'right', ...content}) %}
  | "-[" _ Attributes "]-"    
              {% ([,,content]) => ({kind:'either', ...content}) %}
  | "<-[" _ Attributes "]-"   
              {% ([,,content]) => ({kind:'left', ...content}) %}
  | "-[]->"   {% () => ({kind:'right'}) %}
  | "-[]-"    {% () => ({kind:'either'}) %}
  | "<-[]-"   {% () => ({kind:'left'}) %}
  | "-->"     {% () => ({kind:'right'}) %}
  | "--"      {% () => ({kind:'either'}) %}
  | "<--"     {% () => ({kind:'left'}) %}

PathComposition -> 
    "[" _ "]" {% () => g.empty() %}
  | "[" _ Attributes _ Relation:? _ Path:? _ Path:? _ "]"
      # with both optional, rhs will match first
      {% ([,,attr,,kind,,lhs,,rhs]) => g.cons( (rhs ? lhs ? [lhs,rhs] : [rhs] : []), {kind, id:attr.id, labels:attr.labels, record:attr.record}) %}
  
  # "[" _ Attributes _ Path:? _ "]"
  #   {% ([,,attr,,lhs]) => g.cons(lhs ? [lhs] : undefined, attr) %}
  # | "[" _ Attributes _ (Path ",":? _  
  #     {% ([pp]) => pp %}):+ "]" {% ([,,attr,,pp]) => g.reduce('pair', g.flatten(pp)) %}
      # {% ([pp]) => pp %}):+ "]" {% ([,,attr,,pp]) => g.cons( [g.reduce('pair', g.flatten(pp))], attr ) %}

Relation ->
    ","   {% () => ('pair') %}
  | "-->" {% () => ('right') %}
  | "--"  {% () => ('either') %}
  | "<--" {% () => ('left') %}

Attributes ->
  Identity:? _ LabelList:? _ Record:? {% ([id,,labels,,record]) =>  ( {id, labels, record} )  %}

LabelList -> 
  Label:+ {% ([labels]) => labels %}

Label -> ":" Symbol {% ([,label]) => label %}

Identity -> 
    %identifier   {% text %}
  | "ø"           {% text %}
  | %symbol       {% text %}
  | %integer      {% text %}
  | %octal        {% text %}
  | %hexadecimal  {% text %}
  | %measurement  {% text %}
  | %tickedString {% ([t]) => t.text.slice(1,-1) %}

Symbol -> 
    %symbol       {% text %}
  | %tickedString {% ([t]) => t.text.slice(1,-1) %}

Record -> 
    "{" _ "}" {% empty  %}
  | "{" _ Property (_ "," _ Property):* _ "}" {% ([,,p,ps]) =>  [p, ...extractPairs(ps)] %}

Property -> Symbol _ ":" _ Value {% ([k,,,,v]) => g.property(k,v) %}

# Key -> Symbol {% id %}

Value -> 
    StringLiteral   {% id %}
  | NumericLiteral  {% id %}
  | %boolean        {% (d) => g.boolean(JSON.parse(d[0].value.toLowerCase())) %}
  | "[" _ Value (_ "," _ Value):* "]" {% ([,,v,vs]) => ([v, ...extractArray(vs)]) %}

StringLiteral -> 
    %singleQuotedString {% (d) => g.string(d[0].value) %}
  | %doubleQuotedString {% (d) => g.string(d[0].value) %}
  | %tickedString       {% (d) => g.string(d[0].value) %}
  | %taggedString       {% (d) => {
      const parts = separateTagFromString(d[0].value);
      return g.tagged(parts.tag, parts.value) 
    }%}

NumericLiteral -> 
    %integer      {% (d) => g.integer(d[0].value) %}
  | %decimal      {% (d) => g.decimal(d[0].value) %}
  | %hexadecimal  {% (d) => g.hexadecimal(d[0].value) %}
  | %octal        {% (d) => g.octal(d[0].value) %}
  | %measurement  {% (d) => {
      const parts = separateNumberFromUnits(d[0].value);
    return g.measurement(parts.unit, parts.value) 
  }%}


#
#  Whitespace and comments
#
_ -> null | %whitespace {% empty %}

# Comment -> %lineComment [\n]:? {% empty %}
Comment -> %lineComment {% empty %}

EOL -> "\n" {% empty %}

@{%

const empty = () => null;

const text =([token]:Array<any>):string => token.text;

function extractPairs(pairGroups:Array<any>) {
    return pairGroups.map((pairGroup:Array<any>) => {
      return pairGroup[3];
    })
}

function extractArray(valueGroups:Array<any>):Array<any> {
    return valueGroups.map( (valueGroup) => valueGroup[3]);
}

function separateTagFromString(taggedStringValue:string) {
  let valueParts = taggedStringValue.match(/([^`]+)`(.+)`$/);
  if (valueParts === null || valueParts === undefined) throw Error(`Malformed tagged string: ${taggedStringValue}`) 
  return {
    tag: valueParts![1],
    value: valueParts![2]
  }
}


function separateNumberFromUnits(measurementValue:string) {

  let valueParts = measurementValue.match(/(-?[0-9.]+)([a-zA-Z]+)/);
  if (valueParts === null || valueParts === undefined) throw Error(`Malformed measurement : ${measurementValue}`) 
  return {
    value: valueParts![1],
    unit: valueParts![2],
  }
}
%}