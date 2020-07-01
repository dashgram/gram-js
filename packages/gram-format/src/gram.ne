@preprocessor typescript

@{% 
import moo from 'moo';
import g from './gram-builder';
import {RE} from './gram-tokens';

let lexer = moo.compile({
    whitespace: {match: /\s+/, lineBreaks: true},
    lineComment: {match:/\/\/.*?$/},
    hexadecimal: RE.hexadecimal,
    octal: RE.octal,
    measurement: RE.measurement,
    decimal: RE.decimal,
    integer: RE.integer,
    taggedString: {match: RE.taggedString},
    doubleQuotedString: {match:RE.doubleQuotedString, value: (s:string) => s.slice(1,-1)},
    singleQuotedString: {match:RE.singleQuotedString, value: (s:string) => s.slice(1,-1)},
    tickedString:       {match:RE.tickedString,       value: (s:string) => s.slice(1,-1)},
    boolean: [ 'true', 'TRUE', 'True', 'false', 'FALSE', 'False' ],
    identifier: RE.identifier,
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
    '\'': '\''
}) as unknown as NearleyLexer

%}

@lexer lexer

Gram -> Block:+ {% (data) => g.seq( g.flatten(data) ) %}
  
Block ->
    PathPattern _  {% ([pp]) => pp %}
  | Comment        {% empty %}

#  
# Graph structure: nodes, edges, paths
# 
PathPattern ->
    "[" _ "]" {% () => g.unit() %}
  | NodePattern {% id %}
  | EdgePattern {% id %}
  | "[" _ ContentSpecification _ PathPattern:? _ PathPattern:? _ "]"
      {% ([,,content,,lhs,,rhs]) => g.cons({operands:[lhs,rhs], id:content.id, labels:content.labels, record:content.record}) %}
  
NodePattern ->
  "(" _ ContentSpecification ")" 
    {% ([,,content]) => g.node(content.id, content.labels, content.record) %}
  
EdgePattern ->
    NodePattern EdgeSpecification EdgePattern 
      {% ([np,es,ep]) => g.cons({operands:[np,ep], operator:es.direction, id:es.id, labels:es.labels, record:es.record} ) %}
  | NodePattern {% id %}

EdgeSpecification ->
    "-[" _ ContentSpecification "]->"   
              {% ([,,content]) => ({direction:'right', ...content}) %}
  | "-[" _ ContentSpecification "]-"    
              {% ([,,content]) => ({direction:'either', ...content}) %}
  | "<-[" _ ContentSpecification "]-"   
              {% ([,,content]) => ({direction:'left', ...content}) %}
  | "-[]->"   {% () => ({direction:'right'}) %}
  | "-[]-"    {% () => ({direction:'either'}) %}
  | "<-[]-"   {% () => ({direction:'left'}) %}
  | "-->"     {% () => ({direction:'right'}) %}
  | "--"      {% () => ({direction:'either'}) %}
  | "<--"     {% () => ({direction:'left'}) %}
  # | ","       {% () => ({direction:'pair'}) %}

ContentSpecification ->
  SymbolicName:? _ LabelList:? _ Record:? {% ([id,,labels,,record]) =>  ( {id, labels, record} )  %}

LabelList -> 
  Label:+ {% ([labels]) => labels %}

Label -> ":" SymbolicName {% ([,label]) => label %}

SymbolicName -> 
    %identifier   {% text %}
  | %tickedString {% ([t]) => t.text.slice(1,-1) %}

#
# Graph content: Records with key/value pairs called Properties.
#

# a Property[]
Record -> 
    "{" _ "}" {% empty  %}
  | "{" _ Property (_ "," _ Property):* "}" {% ([,,p,ps]) =>  g.record([p, ...extractPairs(ps)]) %}

Property -> Key _ ":" _ Value {% ([k,,,,v]) => g.property(k,v) %}

Key -> SymbolicName {% id %}

Value -> 
    StringLiteral  {% id %}
  | NumericLiteral  {% id %}
  | %boolean       {% (d) => g.boolean(JSON.parse(d[0].value.toLowerCase())) %}
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

Comment -> %lineComment [\n]:? {% empty %}

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