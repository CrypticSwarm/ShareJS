tree = require '../../src/types/tree'
{test} = require 'tap'

# Checks two ops applied to two starting docs
# Then exchanged yield the same document.
exchangeOps = (desc, state, cop1, sop1, init, expectedParentList) ->
  test desc, (t) ->
    server = JSON.parse JSON.stringify state
    client = JSON.parse JSON.stringify state
    if init?
      server = tree.apply server, init
      client = tree.apply client, init
    server = tree.apply server, sop1
    client = tree.apply client, cop1
    cop2 = tree.transform sop1, cop1, 'right'
    sop2 = tree.transform cop1, sop1, 'left'
    server = tree.apply server, sop2
    client = tree.apply client, cop2
    t.same client, server
    parentList = client.map (node, index) ->
      (not node.parent? and -1) or node.parent
    t.same parentList, expectedParentList
    do t.end

state = [ { parent: null, value: 'root' },
          { parent: null, value: 'a' },
          { parent: null, value: 'b' },
          { parent: null, value: 'c' },
          { parent: null, value: 'x' },
          { parent: null, value: 'y' } ]

initops = [ { wrap: 1, par: 0, chi: [], seq: 6 },
            { wrap: 2, par: 0, chi: [], seq: 6 },
            { wrap: 3, par: 0, chi: [], seq: 6 } ]


## Wrap

exchangeOps "T(Wrap, Wrap) same op.", state,
  [ { wrap: 4, par: 0, chi: [1], seq: 6 } ],
  [ { wrap: 4, par: 0, chi: [1], seq: 6 } ],
  initops,
  [-1, 4, 0, 0, 0, -1]

exchangeOps "T(Wrap, Wrap) same target, same parent, diff children.", state,
  [ { wrap: 4, par: 0, chi: [1], seq: 6 } ],
  [ { wrap: 4, par: 0, chi: [2], seq: 6 } ],
  initops,
  [-1, 4, 4, 0, 0, -1]

exchangeOps "T(Wrap, Wrap) same target, diff parent.", state,
  [ { wrap: 4, par: 1, chi: [], seq: 6 } ],
  [ { wrap: 4, par: 0, chi: [2], seq: 6 } ],
  initops,
  [-1, 0, 4, 0, 0, -1]

exchangeOps "T(Wrap, Wrap) same target, diff parent.", state,
  [ { wrap: 4, par: 0, chi: [2], seq: 6 } ],
  [ { wrap: 4, par: 1, chi: [], seq: 6 } ],
  initops,
  [-1, 0, 0, 0, 1, -1]

exchangeOps "T(Wrap, Wrap) diff target, diff parent.", state,
  [ { wrap: 5, par: 1, chi: [], seq: 6 } ],
  [ { wrap: 4, par: 0, chi: [2], seq: 6 } ],
  initops,
  [-1, 0, 4, 0, 0, 1]

exchangeOps "T(Wrap, Wrap) diff target, same parent children subset.", state,
  [ { wrap: 5, par: 0, chi: [1,2], seq: 6 } ],
  [ { wrap: 4, par: 0, chi: [2], seq: 6 } ],
  initops,
  [-1, 5, 4, 0, 5, 0]

exchangeOps "T(Wrap, Wrap) diff target, same parent children subset.", state,
  [ { wrap: 5, par: 0, chi: [1], seq: 6 } ],
  [ { wrap: 4, par: 0, chi: [1,2], seq: 6 } ],
  initops,
  [-1, 5, 4, 0, 0, 4]

exchangeOps "T(Wrap, Wrap) diff target, same parent children disjoint.", state,
  [ { wrap: 5, par: 0, chi: [1], seq: 6 } ],
  [ { wrap: 4, par: 0, chi: [2], seq: 6 } ],
  initops,
  [-1, 5, 4, 0, 0, 0]

exchangeOps "T(Wrap, Wrap) diff target, same parent children intersect.", state,
  [ { wrap: 5, par: 0, chi: [1,2], seq: 6 } ],
  [ { wrap: 4, par: 0, chi: [2,3], seq: 6 } ],
  initops,
  [-1, 5, 6, 4, 0, 0, 4]


## Unwrap

unwrapInit = [ { wrap: 1, par: 0, chi: [], seq: 6 },
               { wrap: 2, par: 0, chi: [], seq: 6 },
               { wrap: 3, par: 0, chi: [], seq: 6 },
               { wrap: 4, par: 0, chi: [1,2], seq: 6 },
               { wrap: 5, par: 4, chi: [2], seq: 6 } ]

exchangeOps "T(Unwrap, Unwrap) same target, same children.", state,
  [ { unwrap: 4, par: 0, chi: [1], seq: 6 } ],
  [ { unwrap: 4, par: 0, chi: [1], seq: 6 } ],
  unwrapInit,
  [-1, 0, 5, 0, -1, 4]

exchangeOps "T(Unwrap, Unwrap) same target, diff children.", state,
  [ { unwrap: 4, par: 0, chi: [1], seq: 6 } ],
  [ { unwrap: 4, par: 0, chi: [5], seq: 6 } ],
  unwrapInit,
  [-1, 0, 5, 0, -1, 0]

exchangeOps "T(Unwrap, Unwrap) disjoint ops.", state,
  [ { unwrap: 3, par: 0, chi: [], seq: 6 } ],
  [ { unwrap: 5, par: 4, chi: [2], seq: 6 } ],
  unwrapInit,
  [-1, 4, 4, -1, 0, -1]

exchangeOps "T(Unwrap, Unwrap) nested targets.", state,
  [ { unwrap: 4, par: 0, chi: [1], seq: 6 } ],
  [ { unwrap: 5, par: 4, chi: [2], seq: 6 } ],
  unwrapInit,
  [-1, 0, 4, 0, -1, -1]

exchangeOps "T(Unwrap, Unwrap) nested targets.", state,
  [ { unwrap: 4, par: 0, chi: [1,5], seq: 6 } ],
  [ { unwrap: 5, par: 4, chi: [2], seq: 6 } ],
  unwrapInit,
  [-1, 0, 0, 0, -1, -1]

exchangeOps "T(Unwrap, Unwrap) nested targets.", state,
  [ { unwrap: 5, par: 4, chi: [2], seq: 6 } ],
  [ { unwrap: 4, par: 0, chi: [1,5], seq: 6 } ],
  unwrapInit,
  [-1, 0, 0, 0, -1, -1]

## Create

exchangeOps "T(Create, Create) nested targets.", state,
  [ { cn: 6, value: 'hello' },
    { cn: 7, value: 'bye bye' }
  ],
  [ { cn: 6, value: 'Help!' },
    { cn: 7, value: 'I am stuck in a testing factory.' }
  ],
  initops,
  [-1, 0, 0, 0, -1, -1, -1, -1, -1, -1]

exchangeOps "T(Create, Create) nested targets.", state,
  [ { cn: 6, value: 'hello' },
    { cn: 7, value: 'bye bye' },
    { wrap: 7, par: 6, chi: [], seq: 8 }
  ],
  [ { cn: 6, value: 'Help!' },
    { wrap: 6, par: 0, chi: [1,2], seq: 7 }
    { cn: 7, value: 'I am stuck in a testing factory.' },
    { wrap: 7, par: 6, chi: [2], seq: 8 }
  ],
  initops,
  [-1, 8, 9, 0, -1, -1, -1, 6, 0, 8]

## Wrap vs Unwrap

wrapUnrapInit = [ { wrap: 1, par: 0, chi: [], seq: 6 },
                  { wrap: 2, par: 0, chi: [], seq: 6 },
                  { wrap: 3, par: 0, chi: [], seq: 6 },
                  { wrap: 4, par: 0, chi: [1,2], seq: 6 } ]

exchangeOps "T(Unwrap, Wrap) Chained. Wrap below.", state,
  [ { wrap: 5, par: 4, chi: [1], seq: 6 } ]
  [ { unwrap: 4, par: 0, chi: [], seq: 6 } ]
  wrapUnrapInit,
  [-1, 5, 4, 0, -1, 0]

exchangeOps "T(Unwrap, Wrap) Chained. Wrap above.", state,
  [ { wrap: 5, par: 0, chi: [4,3], seq: 6 } ]
  [ { unwrap: 4, par: 0, chi: [1,2], seq: 6 } ]
  wrapUnrapInit,
  [-1, 5, 5, 5, -1, 0]

