import {
  GramPathSequence,
  GramPath,
  GramNode,
  GramEdge,
  GramProperty,
  GramLiteral,
  RelationshipOperator,
  BooleanLiteral,
  StringLiteral,
  TaggedLiteral,
  IntegerLiteral,
  DecimalLiteral,
  HexadecimalLiteral,
  OctalLiteral,
  MeasurementLiteral,
  GramRecord,
  GramPathExpression,
  GramUnit,
  GramPathlikeElement,
  isGramNode,
  GramPathlike,
  isGramUnit,
  isGramEdge,
  isGramPath,
} from './gram-types';
import { Node as UnistNode } from 'unist';
import { shortID } from './gram-identity';

export type Children<T> = T | T[] | (() => T | T[]);

function normalizeChildren<T extends UnistNode>(children?: Children<T>): T[] {
  if (Array.isArray(children)) {
    return children;
  } else if (children instanceof Function) {
    const res = children();
    return normalizeChildren<T>(res);
  } else if (typeof children === 'undefined') {
    return [];
  } else {
    return [children];
  }
}

const dateToYMD = (d: Date) => d.toISOString().slice(0, 10);

const dateToDayOfMonth = (d: Date) => '--' + d.toISOString().slice(5, 10);

/**
 * Build a gram representation of a graph.
 *
 * @param paths sequence of paths which merge into a graph
 * @param id optional reference identifier. The "name" of this graph instance.
 * @param labels optional labels
 * @param record optional graph-level data
 */
export const gram = (paths: Children<GramPath>, id?: string, labels = [], record?: GramRecord): GramPathSequence => ({
  type: 'seq',
  ...(id && { id }),
  labels,
  ...(record && { record }),
  children: normalizeChildren<GramPath>(paths),
});

/**
 * Build any path-like element
 * 
 * @param children 
 * @param id 
 * @param labels 
 * @param record 
 */
export const cons = (
  children: [] | [GramPathlikeElement] | [GramPathlikeElement, GramPathlikeElement],
  id?: string,
  labels?: string[],
  record?: GramRecord,
  direction?: RelationshipOperator
): GramPathlike => {
  const element:GramPathlikeElement = {
    type: 'path',
    id,
    labels,
    record,
    children: children.filter( child => !isGramUnit(child))
  }
  if (element.children.length == 0) {
    if (id) {
      element.type = 'node'
      return element as GramNode
    } else {
      element.type = 'unit'
      return element as GramUnit;
    }
  } else if (element.children.length == 1) {
    if (id) {
      return element as GramPath;
    } else {
      const inner = element.children[0];
      if (isGramNode(inner)) return inner as GramNode
      if (isGramEdge(inner)) return inner as GramEdge
      if (isGramPath(inner)) return inner as GramPath
    }
  } else if ((element.children.length == 2) && isGramNode(element.children[0]) && isGramNode(element.children[1])) {
    element.type = 'edge'
    element.direction = direction || 'either';
    return element as GramEdge;
  } 
  element.direction = direction || 'pair'
  return element as GramPath;
};

/**
 * Singleton instance of GramUnit
 */
export const UNIT:GramUnit = {
  type: "unit",
  id: undefined,
  labels: undefined,
  record: undefined,
  children: []
}

/**
 * Convenience function for retrieving the singleton GramUnit.
 */
export const unit = ():GramUnit => UNIT

/**
 * Build a GramNode.
 *
 * @param id identifier
 * @param labels
 * @param record
 * @param annotation
 */
export const node = (id?: string, labels?: string[], record?: GramRecord): GramNode => ({
  type: 'node',
  id: id || shortID(),
  ...(labels && { labels }),
  ...(record && { record }),
  children: [],
});

/**
 * Build an Edge.
 *
 * @param children
 * @param direction
 * @param id
 * @param labels
 * @param record
 */
export const edge = (
  children: [GramNode, GramNode],
  direction: RelationshipOperator = 'right',
  id?: string,
  labels?: string[],
  record?: GramRecord
): GramEdge => ({
  type: 'edge',
  id: id || shortID(),
  ...(labels && { labels }),
  ...(record && { record }),
  direction,
  children,
});

/**
 * Build a path
 * 
 * @param children 
 * @param id 
 * @param labels 
 * @param record 
 */
export const path = (
  children: [GramPathExpression] | [GramPathExpression, GramPathExpression],
  id?: string,
  labels?: string[],
  record?: GramRecord
): GramPath => ({
  type: 'path',
  ...(id && { id }),
  labels,
  ...(record && { record }),
  children: children,
});


export const record = (properties: GramProperty[]): GramRecord => {
  return properties.reduce((acc: GramRecord, p: GramProperty) => {
    acc[p.name] = p.value;
    return acc;
  }, {} as GramRecord);
};


export const property = (name: string, value: GramLiteral | GramLiteral[]): GramProperty => {
  const Node: GramProperty = {
    type: 'property',
    name,
    value,
  };
  return Node;
};

export const boolean = (value: boolean): BooleanLiteral => ({ type: 'boolean', value: value ? 'true' : 'false' });

export const string = (value: string): StringLiteral => ({ type: 'string', value });

export const tagged = (tag: string, value: string): TaggedLiteral => ({ type: 'tagged', value, tag });

export const integer = (value: string | number): IntegerLiteral => ({ type: 'integer', value: String(value) });

export const decimal = (value: string | number): DecimalLiteral => ({ type: 'decimal', value: String(value) });

export const hexadecimal = (value: string): HexadecimalLiteral => ({ type: 'hexadecimal', value });

export const octal = (value: string): OctalLiteral => ({ type: 'octal', value });

export const measurement = (unit: string, value: string | number): MeasurementLiteral => ({
  type: 'measurement',
  value: String(value),
  unit,
});

export const year = (value: string | Date): TaggedLiteral =>
  tagged(value instanceof Date ? value.getFullYear().toString() : value, 'date');

export const date = (value: string | Date): TaggedLiteral =>
  tagged(value instanceof Date ? dateToYMD(value) : value, 'date');

export const dayOfMonth = (value: string | Date): TaggedLiteral =>
  tagged(value instanceof Date ? dateToDayOfMonth(value) : value, 'date');

export const time = (value: string | Date): TaggedLiteral =>
  tagged(value instanceof Date ? dateToYMD(value) : value, 'time');

export const flatten = (xs: any[], depth = 1) => xs.flat(depth);

export default {
  gram,
  path,
  node,
  edge,
  record,
  property,
  boolean,
  string,
  tagged,
  integer,
  decimal,
  hexadecimal,
  octal,
  unit: measurement,
  date,
  time,
  flatten,
};
