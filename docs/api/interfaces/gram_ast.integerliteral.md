---
title: gram_ast.integerliteral
layout: api
---

**[gram.js API](../README.md)**

> [Globals](../globals.md) / [gram-ast](../modules/gram_ast.md) / IntegerLiteral

# Interface: IntegerLiteral

Represents an integer number, like 235276234.
Note: there is no explicit min or max value.

## Hierarchy

* TextLiteral

  ↳ **IntegerLiteral**

## Indexable

▪ [key: string]: unknown

Represents an integer number, like 235276234.
Note: there is no explicit min or max value.

## Index

### Properties

* [data](gram_ast.integerliteral.md#data)
* [position](gram_ast.integerliteral.md#position)
* [type](gram_ast.integerliteral.md#type)
* [value](gram_ast.integerliteral.md#value)

## Properties

### data

• `Optional` **data**: Data

*Inherited from [GramSeq](gram_ast.gramseq.md).[data](gram_ast.gramseq.md#data)*

*Defined in packages/gram-ast/node_modules/@types/unist/index.d.ts:23*

Information from the ecosystem.

___

### position

• `Optional` **position**: Position

*Inherited from [GramSeq](gram_ast.gramseq.md).[position](gram_ast.gramseq.md#position)*

*Defined in packages/gram-ast/node_modules/@types/unist/index.d.ts:29*

Location of a node in a source document.
Must not be present if a node is generated.

___

### type

•  **type**: \"integer\"

*Overrides void*

*Defined in [packages/gram-ast/src/index.ts:344](https://github.com/gram-data/gram-js/blob/594b46d/packages/gram-ast/src/index.ts#L344)*

___

### value

•  **value**: string

*Inherited from [StringLiteral](gram_ast.stringliteral.md).[value](gram_ast.stringliteral.md#value)*

*Overrides void*

*Defined in [packages/gram-ast/src/index.ts:277](https://github.com/gram-data/gram-js/blob/594b46d/packages/gram-ast/src/index.ts#L277)*
