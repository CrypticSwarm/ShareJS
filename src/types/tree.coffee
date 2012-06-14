# nodes -> { parent, value }
# split: mn -> maintext, nn -> alttext, pos -> position
# merge: mn -> maintext, on -> alttext, len -> length
# reparent: op -> oldparent, np -> newparent
# create: cn -> name, parent -> parentName
# delete: dn -> name, parent -> parentName

if WEB?
  json = exports.types.json
else
  json = require './json'

tree = {}

tree.name = 'tree'

tree.create = -> {}

tree.invertComponent = (c) ->
  if c.p.length > 0
    c_ = json.invertComponent c
  else
    c_ = { p: [], mn: c.mn, on: c.nn, len: c.pos } if c.nn
    c_ = { p: [], mn: c.mn, nn: c.on, pos: c.len } if c.on
    c_ = { p: [], op: c.np, cp: c.op } if c.op
    c_ = { p: [], dn: c.cn, par: c.par } if c.cn
    c_ = { p: [], cn: c.dn, par: c.par } if c.dn
  c_

tree.invert = json.invert
tree.checkList = json.checkList
tree.checkObj = json.checkObj
tree.pathMatches = json.pathMatches
tree.normalize = json.normalize
tree.commonPath = json.commonPath 

tree.checkValidOp = (op) ->
  tree.checkValidComponent(c) for c in op
  true

tree.checkValidComponent = (c) ->
  if c.p.length > 1
    if c.p[1] == 'value'
      json.checkValidOp c
    else
      throw new Error "Don't try to modify nodes directly."
  else
    throw new Error "Component should contain mn, op, cn or dn attrs" unless c.mn or c.op or c.cn or c.dn

tree.compose = (op1, op2) ->
  tree.checkValidOp op1
  tree.checkValidOp op2

  newOp = clone op1
  tree.append newOp, c for c in op2

  newOp

tree.transformComponent = (dest, c, otherC, type) ->

tree.apply = (snapshot, op) ->
  tree.checkValidOp op


