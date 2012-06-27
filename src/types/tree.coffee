# nodes -> { parent, value }
# split: tn -> targetnode, nn -> newnode, pos -> position
# merge: tn -> targetnode, on -> oldnode, len -> length
# warp: wrap -> targetnode, par -> parent, chi -> child
# unwarp: unwrap -> targetnode, par -> parent, chi -> child
# create: cn -> createnode, value -> value
# delete: dn -> deletenode, value -> value

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
    c_ = { unwrap: c.wrap, par: c.par, chi: c.chi, seq: c.seq } if c.wrap
    c_ = { wrap: c.unwrap, par: c.par, chi: c.chi, seq: c.seq } if c.unwrap
    c_ = { dn: c.cn, val: c.val } if c.cn
    c_ = { cn: c.dn, val: c.val } if c.dn
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
    throw new Error "Component should contain tn, wrap, unwrap, cn or dn attrs" unless c.tn or c.wrap or c.unwrap or c.cn or c.dn or c.blah != null or c.del

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
  if c.wrap
    if otherC.wrap
      tree.transformWrap dest, c, otherC, type
    else if otherC.nn or otherC.on
      tree.transformWrapSplitL dest, c, otherC, type
  else if c.on or c.nn
    if otherC.si or otherC.sd
      tree.transformStringManipR dest, c, otherC, type
    else if otherC.nn or otherC.on
      tree.transformSplitMergeR dest, c, otherC, type
    else if otherC.wrap
      tree.transformWrapSplitR dest, c, otherC, type
  else if c.si or c.sd
    if otherC.on or otherC.nn
      tree.transformStringManipL dest, c, otherC, type
  else if c.cn
    if otherC.cn
      tree.transformCreateNode dest, c, otherC, type
    else
      dest.push c
  else if c.seq 
    if otherC.seq
      tree.transformSeq dest, c, otherC, type
    else
      dest.push c
  else if c.ref
    if otherC.cn
      tree.transformRef dest, c, otherC, type
    else
      dest.push c
  else if c.del
    dest.push c
  # Probably need to do some things with create/delete node
  else
    json.transformComponent dest, c, otherC, type

difference = (a, b) ->
  diff = []
  for x in a
    diff.push x if -1 == b.indexOf x
  diff

tree.transformCreateNode = (dest, c, otherC, type) ->
  if otherC.cn <= c.cn and type == 'right'
      dest.push { cn: c.cn + 1, value: c.value }
  else
    dest.push c

tree.transformWrapRef = (dest, c, otherC, type) ->
  c = clone c
  # not needed to check right.
  # any cn should already be incremented.
  # due to the fact that any references
  # need to be made after create
  if c.wrap != undefined and otherC.cn <= c.wrap
    c.wrap += 1
  if c.unwrap != undefined and otherC.cn <= c.unwrap
    c.unwrap += 1
  if otherC.cn <= c.par
    c.par += 1
  for ref, loc in c.chi
    if otherC.cn <= ref
      c.chi[loc] += 1
  dest.push c

tree.transformSeq = (dest, c, otherC, type) ->
  if type == 'right'
    dest.push { cn: otherC.seq, value: 'seq' }
  else
    dest.push { cn: c.seq, value: 'seq' }

tree.transformRef = (dest, c, otherC, type) ->
  # technically not needed to check 'right' because should always
  # have created all nums under ref before referencing
  # and right side op(CreateNode) get incremented.
  if otherC.cn <= c.ref and type == 'right'
    dest.push { ref: c.ref + 1 }
  else
    dest.push c



# warp: wrap -> targetnode, par -> parent, chi -> child
# unwarp: unwrap -> targetnode, par -> parent, chi -> child
tree.transformWrap = (dest, c, otherC, type) ->
  # same target node
  if c.wrap == otherC.wrap
    # same parent grab all children
    if c.par == otherC.par
      diff = difference c.chi, otherC.chi
      if diff.length != 0
        dest.push { unwrap: c.wrap, par: c.par, chi: null, seq: c.seq }
        dest.push { wrap: c.wrap, par: c.par, chi: diff, seq: c.seq }
    # not same parent right applies the new one
    else if type == 'right'
      dest.push tree.invertComponent otherC
      dest.push c
  # diff target node, but same parents
  else if c.par == otherC.par
    ldiff = difference c.chi, otherC.chi
    rdiff = difference otherC.chi, c.chi
    # disjoint children both occur unchanged
    if ldiff.length == c.chi.length and rdiff.length == otherC.chi.length
      dest.push c
    # same children... nest them
    else if ldiff.length == 0 and rdiff.length == 0
      if type == 'left'
        dest.push { wrap: c.wrap, par: c.par, chi: [otherC.wrap], seq: c.seq }
      else
        dest.push { wrap: c.wrap, par: otherC.wrap, chi: c.chi, seq: c.seq }
    # c.chi is a subset of otherC.chi... c.wrap is nested
    else if ldiff.length == 0
      dest.push { wrap: c.wrap, par: otherC.wrap, chi: c.chi, seq: c.seq }
    # otherC.chi is a subset of c.chi... otherC.wrap is nested
    else if rdiff.length == 0
      dest.push { wrap: c.wrap, par: otherC.par, chi: (ldiff.concat otherC.wrap), seq: c.seq }
    # else there is an intersection.... Need to figure out cloning to work right
    else
      dest.push c
  # diff target, diff parents, c is unchanged
  else
    dest.push c

  dest

tree.transformUnwrap = (dest, c, otherC, type) ->

# c -> si/sd, otherC -> split/merge
tree.transformStringManipL = (dest, c, otherC, type) ->

# c -> split/merge, otherC -> si/sd
tree.transformStringManipR = (dest, c, otherC, type) ->

# c-> split/merge, otherC -> split/merge
tree.transformSplitMerge  = (dest, c, otherC, type) ->

# c -> wrap, otherC -> split/merge
tree.transformWrapSplitL = (dest, c, otherC, type) ->

# c -> split/merge, otherC -> wrap
tree.transformWrapSplitR = (dest, c, otherC, type) ->

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
  else if c.wrap
    tree.applyWrap snapshot, c
  else if c.unwrap
    tree.applyUnwrap snapshot, c
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

tree.applyWrap = (snapshot, c) ->
  wrap = snapshot[c.wrap]
  par = snapshot[c.par]
  chiOk = not c.chi or c.chi.map (child) -> snapshot[child].parent == c.par
  throw new Error "Op(Wrap): Target's for wrap should exist." unless wrap
  throw new Error "Op(Wrap): Target's for wrap shouldn't have a parent. (#{wrap.parent})" unless wrap.parent == null
  throw new Error "Op(Wrap): all children's parent should equal par" unless chiOk
  if c.chi
    c.chi.map (child) -> snapshot[child].parent = c.wrap
  wrap.parent = c.par

tree.applyUnwrap = (snapshot, c) ->
  unwrap = snapshot[c.unwrap]
  par = snapshot[c.par]
  chiOk = not c.chi or c.chi.map (child) -> snapshot[child].parent == c.unwrap
  throw new Error "Op(Unwrap): Target should exist." unless unwrap
  throw new Error "Op(Unwrap): Target's parent should be par. (#{unwrap.parent})" unless unwrap.parent == c.par
  throw new Error "Op(Wrap): all children's parent should equal unwrap" unless chiOk
  if c.chi
    c.chi.map (child) -> snapshot[child].parent = c.par
  unwrap.parent = null

tree.applyCreateNode = (snapshot, c) ->
  snapshot.splice(c.cn, 0, { parent: null, value: c.val })

tree.applyDeleteNode = (snapshot, c) ->
  # Probably should check that the current value and value is correct.
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
