# High Level Guide of AS-MOSES port to Hyperon/MeTTa

This document is a high level guide of the AS-MOSES port from OpenCog
Classic to Hyperon/MeTTa.

## AS-MOSES, a brief history

MOSES, which stands for *Meta-Optimizing Semantic Evolution Search*,
is an evolutionary program learner initially developed by Moshe Looks.
It takes in input a problem description, and outputs a set of programs
supposed to solve that problem.  A typical example is the problem of
fitting data, in that case the problem description is a table mapping
inputs to outputs alongside a fitness function measuring how well a
candidate fits that data.

I believe the primary motivation behind the creation of MOSES came
from the desire to adapt existing EDA (Estimation of Distribution
Algorithm) methods to evolve programs instead of mere bitstrings.
Upon investigating that space, Moshe (possibly with the help of Ben)
discovered that by combining a few tricks, evolving programs in that
manner was actually effective.  We'll come back to these tricks but,
let me say that, as with anything, these tricks only work under some
assumptions, which will attempt to recall as well.

Initially MOSES' candidate representation language was its own thing,
called Combo and described as "Lisp with a bad haircut" by Moshe
himself.  Later on, as OpenCog Classic developed, the need to
integrate MOSES more deeply into OpenCog Classic came to be, and the
work of replacing Combo by Atomese, the language of OpenCog Classic
(the equivalent of MeTTa for Hyperon) was enacted.  The resulting code
was called AS-MOSES, for AtomSpace-MOSES.  That endeavor however never
completed because the development effort was then turned from OpenCog
Classic to Hyperon.

## The Ultimate Goal of that Port

Now let me cut straight to the matter.  The ultimate goal of that port
is not to verbatimely reproduce AS-MOSES inside Hyperon.  The ultimate
goal is to have a *sufficiently open-ended program learning technology
that integrates well with the rest of Hyperon to enable a tight form
of cognitive synergy*.

Pragmatically speaking, cognitive synergy here means that, if MOSES
gets stuck in the process of evolving programs, it can formulate a
demand of help to the rest of Hyperon, and take advantage of the reply
to unstick itself.  Likewise, if other components of Hyperon are
stuck, they can formulate demands of help to MOSES and take advantage
of its reply.

There are many ways such cognitive synergy could be realized, I will
describe one that I like (or at least I understand), but ultimately
how to do that well, i.e. enable synergy as opposed to interference,
is an open question.

There is also another form of synergy, perhaps just as important, is
the synergy between MOSES and its users.  This could for instance be
enabled by integrating MOSES to the MeTTa LSP server.  More will be
said on that further below.

## Set of requirements

### Conceptual requirements

### Pragmatic requirements

## A case for reasoning-based evolution

## Cognitive Synergy

### Between MOSES and Hyperon

### Between MOSES and humans

## Black box vs clear box

