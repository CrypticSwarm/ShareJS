# nodes -> { parent, value }
# split: tn -> targetnode, nn -> newnode, pos -> position
# merge: tn -> targetnode, on -> oldnode, len -> length
# reparent: tn -> targetnode, op -> oldparent, np -> newparent
# create: cn -> createnode, parent -> parentName
# delete: dn -> deletenode, parent -> parentName

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
    c_ = { tn: c.tn, op: c.np, np: c.op, npp: c.opp, opp: c.npp } if c.op
    c_ = { dn: c.cn, par: c.par, val: c.val } if c.cn
    c_ = { cn: c.dn, par: c.par, val: c.val } if c.dn
  c_

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

# For now nothing fancy just append
tree.append = (dest, c) -> dest.push c

# dispatches based off the types of each component.
tree.transformComponent = (dest, c, otherC, type) ->
  if c.op
    if otherC.op
      tree.transformReparent dest, c, otherC, type
    else if otherC.nn or otherC.on
      tree.transformReparentSplit dest, c, otherC, type
  else if c.on or c.nn
    if otherC.si or otherC.sd
      tree.transformStringManipR dest, c, otherC, type
    else if otherC.nn or otherC.on
      tree.transformSplitMergeR dest, c, otherC, type
    else if otherC.op
      tree.transformReparentSplit dest, c, otherC, type
  else if c.si or c.sd
    if otherC.on or otherC.nn
      tree.transformStringManipL dest, c, otherC, type

  # Probably need to do some things with create/delete node
  else
    json.transformComponent dest, c, otherC, type

# c -> reparent, otherC -> reparent
tree.transformReparent = (dest, c, otherC, type) ->
  if c.tn == otherC.tn
    if type == 'left'
      tree.append dest, { tn: otherC.np, op: otherC.npp, np: c.np, opp: , npp: c.npp }
    else
      tree.append dest, { tn: otherC.tn, op: otherC.np, np: c.np }
      tree.append dest, { tn: c.np, op: null, np: otherC.np }
  else
    tree.append dest, c
  dest

# c -> si/sd, otherC -> split/merge
tree.transformStringManipL = (dest, c, otherC, type) ->

# c -> split/merge, otherC -> si/sd
tree.transformStringManipR = (dest, c, otherC, type) ->

# c-> split/merge, otherC -> split/merge
tree.transformSplitMerge  = (dest, c, otherC, type) ->

# c -> reparent, otherC -> split/merge
tree.transformReparentSplitL = (dest, c, otherC, type) ->

# c -> split/merge, otherC -> reparent
tree.transformReparentSplitR = (dest, c, otherC, type) ->

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
  op = snapshot[c.op]
  np = snapshot[c.np]
  throw new Error "Target's Parent should equal op. (#{tn.parent}, #{c.op}) respectively" unless tn.parent == c.op
  throw new Error "Old Parent's Parent should equal opp. (#{op.parent}, #{c.opp}) respectively" unless op and op.parent == c.opp
  throw new Error "New Parent's Parent should equal npp. (#{np.parent}, #{c.npp}) respectively" unless np and np.parent == c.npp
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
