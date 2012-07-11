tree = require '../../src/types/tree'
{test} = require 'tap'
{randomInt, randomReal} = require('../helpers')
randomWord = require './randomWord'
treeTest = require './tree'

# Checks two ops applied to two starting docs
# Then exchanged yield the same document.
exchangeOps = (desc, state, cop1, sop1, expectedParentList) ->
  test desc, (t) ->
    {server2: server, client2: client, ce, se} = treeTest.applyOps state, cop1, sop1
    throw ce if ce?
    throw se if se?
    t.same client, server
    parentList = client.map (node, index) ->
      (not node.parent? and -1) or node.parent
    t.same parentList, expectedParentList
    do t.end


genRandomComponent = (state) ->
  if randomReal() < .2 
    { cn: state.length, value: randomWord() }
  else
    num = randomInt state.length
    node = state[num]
    if node.parent == -1
      par = num
      par = randomInt state.length
      chi = []
      for child in state[par].chi
        chi.push child if randomReal() < .3 and child != par
      { wrap: num, par: par, chi: chi, seq: state.length }
    else
      par = node.parent
      chi = []
      for child in node.chi
        chi.push child if randomReal() < .3
      { unwrap: num, par: par, chi: chi, seq: state.length }

testCase = (t, client, server) ->
  cop1 = []
  sop1 = []
  locS = []
  locC = []
  while randomReal() < .85
    scomp = genRandomComponent server
    server = tree.applyComponent server, scomp
    locS.push scomp
  while randomReal() < .85
    ccomp = genRandomComponent client
    client = tree.applyComponent client, ccomp
    locC.push ccomp
  tree.append sop1, c for c in locS
  tree.append cop1, c for c in locC
  cop2 = tree.transform sop1, cop1, 'right'
  sop2 = tree.transform cop1, sop1, 'left'
  try
    server = tree.apply server, sop2
  catch e
    console.log 'left'
    console.log cop1
    console.log '---'
    console.log sop1
    console.log '==='
    console.log server
    console.log sop2
    throw e
  try
    client = tree.apply client, cop2
  catch e
    console.log 'right'
    console.log sop1
    console.log '---'
    console.log cop1
    console.log '==='
    console.log client
    console.log cop2
    throw e
  t.same client, server
  [client, server]

randTests = (startState, numTests, style) ->
  server = JSON.parse JSON.stringify startState
  client = JSON.parse JSON.stringify startState
  msg = "Randomized op test " + style + " state"
  if style == 'fresh'
    test msg, (t) ->
      if numTests > 0
        randTests startState, numTests - 1, style
      testCase t, client, server
      do t.end
  else
    test msg, (t) ->
      for tx in [0..numTests]
        [client, server] = testCase t, client, server
      do t.end


state = [ { parent: -1, value: 'root', chi: [1,2,3] },
          { parent: 0, value: 'a', chi: [] },
          { parent: 0, value: 'b', chi: [] },
          { parent: 0, value: 'c', chi: [] },
          { parent: -1, value: 'x', chi: [] },
          { parent: -1, value: 'y', chi: [] } ]

randTests state, 30, 'continuous'
randTests state, 1000000, 'fresh'

for _, testGroup of treeTest.tests
  for args in testGroup
    exchangeOps.apply null, args

