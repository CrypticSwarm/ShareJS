# nodes -> { parent, value }
# split: tn -> maintext, nn -> alttext, pos -> position
# merge: tn -> maintext, on -> alttext, len -> length
# reparent: op -> oldparent, np -> newparent
# create: cn -> name, parent -> parentName
# delete: dn -> name, parent -> parentName

if WEB?
  json = exports.types.json
else
  json = require './json'

# hax, copied from test/types/json
clone = (o) -> JSON.parse(JSON.stringify o)

tree = {}

tree.name = 'tree'

tree.create = -> {}

tree.invert = (op) -> tree.invertComponent c for c in op.slice().reverse()
tree.invertComponent = (c) ->
  if c.p?.length > 0
    c_ = json.invertComponent c
  else
    c_ = { tn: c.tn, on: c.nn, len: c.pos } if c.nn
    c_ = { tn: c.tn, nn: c.on, pos: c.len } if c.on
    c_ = { tn: c.tn, op: c.np, np: c.op } if c.op
    c_ = { dn: c.cn, par: c.par, val: c.val } if c.cn
    c_ = { cn: c.dn, par: c.par, val: c.val } if c.dn
  c_

tree.checkList = json.checkList
tree.checkObj = json.checkObj
tree.pathMatches = json.pathMatches
tree.normalize = json.normalize
tree.commonPath = json.commonPath 

tree.checkValidOp = (op) ->
  tree.checkValidComponent(c) for c in op

tree.checkValidComponent = (c) ->
  if c.p?.length > 1
    if c.p[1] == 'value'
      json.checkValidOp c
    else
      throw new Error "Don't try to modify nodes directly."
  else
    throw new Error "Component should contain tn, op, cn or dn attrs" unless c.tn or c.op or c.cn or c.dn

tree.compose = (op1, op2) ->
  tree.checkValidOp op1
  tree.checkValidOp op2

  newOp = clone op1
  tree.append newOp, c for c in op2

  newOp

tree.append = (op) ->

tree.transformComponent = (dest, c, otherC, type) ->

tree.apply = (snapshot, op) ->
  tree.checkValidOp op
  op = clone op

  container = {data: clone snapshot}
  for c in op
    tree.applyComponent container, c

  container.data

tree.applyComponent = (container, c) ->
  snapshot = container.data
  if c.nn
    tree.applySplit snapshot, c
  else if c.on
    tree.applyMerge snapshot, c
  else if c.op
    tree.applyReparent snapshot, c
  else if c.cn
    tree.applyCreateNode snapshot, c
  else if c.dn
    tree.applyDeleteNode snapshot, c
  else 
    json.applyComponent container, c
  snapshot

tree.applySplit = (snapshot, c) ->
  tn = snapshot[c.tn]
  throw new Error "Referenced main node not a string (it was #{JSON.stringify tn.value})" unless typeof tn.value is 'string'
  snapshot[c.nn] = { parent: tn.parent, value: tn.value[c.pos...] }
  tn.value = tn.value[...c.pos]

tree.applyMerge = (snapshot, c) ->
  tn = snapshot[c.tn]
  old = snapshot[c.on]
  throw new Error "Referenced main node not a string (it was #{JSON.stringify tn.value})" unless typeof tn.value is 'string'
  throw new Error "Referenced old node not a string (it was #{JSON.stringify tn.value})" unless typeof old.value is 'string'
  throw new Error "The len should equal main nodes length" unless c.len == tn.value.length
  tn.value = tn.value + old.value
  delete snapshot[c.on]

tree.applyReparent = (snapshot, c) ->
  tn = snapshot[c.tn]
  throw new Error "Parent should equal par." unless tn.parent == c.op
  tn.parent = c.np

tree.applyCreateNode = (snapshot, c) ->
  snapshot[c.cn] = {parent: c.par, value: c.val}

tree.applyDeleteNode = (snapshot, c) ->
  # Probably should check that the current parent and value is correct.
  delete snapshot[c.dn]

if WEB?
  exports.types ||= {}

  # This is kind of awful - come up with a better way to hook this helper code up.
  exports._bt(tree, tree.transformComponent, tree.checkValidOp, tree.append)

  # [] is used to prevent closure from renaming types.text
  exports.types.tree = tree
else
  module.exports = tree

  require('./helpers').bootstrapTransform(tree, tree.transformComponent, tree.checkValidOp, tree.append)
