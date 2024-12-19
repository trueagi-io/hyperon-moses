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
that integrates well with the rest of Hyperon to enable some form of
cognitive synergy*.  As such is could almost be renamed into something
else such as *Hyperon Program Evolutionary Framework*, depending on
how much it departs from the original MOSES.

Pragmatically speaking, cognitive synergy here means that, if MOSES
gets stuck in the process of evolving programs, it can formulate a
demand of help to the rest of Hyperon, and take advantage of the reply
to unstick itself.  Likewise, if other components of Hyperon are
stuck, they can formulate demands of help to MOSES and take advantage
of its reply.

There are many ways such cognitive synergy could be realized, I will
describe some that I like (or at least I understand), but ultimately
how to do that well, i.e. enable synergy as opposed to interference,
is an open question.

There is also another form of synergy, perhaps just as important, the
synergy between MOSES and its users.  This could for instance be
enabled by integrating MOSES to the MeTTa LSP server.  More will be
said on that further below.

## Set of requirements

### Conceptual requirements

### Pragmatic requirements

## A case for reasoning-based evolution

## Cognitive Synergy

### Between MOSES and Hyperon

First we can ask, how can MOSES be helped by Hyperon?  To begin
simply, any hyperparameters controlling MOSES, such as for instance
the portion of evaluations that should be allocated to search any
particular deme, can be tuned by Hyperon.

Second, the biggest help would probably go to the optimization phase.
This is after all where most of the computational resources are going
to be spent.  Selecting the right optimization algorithm for the right
problem is an example, though probably falls under the hyperparameter
tuning aspect described above.  If the optimization algorithm is
EDA-based, then a very important avenue for help is in modelling the
fitness landscape.  This is not an easy thing to do and requires for
instance the ability to properly balance exploration and exploitation,
which some components of Hyperon are (or will be) excellent at, such
as reasoning and planning under uncertainty using PLN.  There is also
the problem of transfering knowledge across demes, and ultimately
across problems as well.  For instance all the wisdom accumulated to
effectively sample a deme should not be thrown away when a new deme is
created.

So how to concretely achieve that?  The precise answer needs research
and development, but some directions can be provided.  The main idea
would be to formulate in logic, PLN or whichever is adequate, the
relationships between problems and various aspects of MOSES.  For
instance in the context of hyperparameter tuning, a formulation
provided may look like

*if problem π has property p, then hyperparameter f should be within
range r to achieve greater than average performance with probably ρ*

Then given many of such statements, a planner would be able to set the
hyperparameters before launching MOSES on a particular problem.

The same idea would apply to finer aspects of MOSES, such as the
optimization phase.  In the case of EDA-based optimization, such
statement could look like

*if deme d has property p, then if candidate c contains operator o₁ at
location l₁ and operator o₂ at location l₂, it is likely to be fit
with probably ρ*

Then the EDA procedure could, at some particular phases, query the
atomspace for such wisdom.  If none is retreived then it would proceed
as usual, but if some is then it would be able to take advantage of it
and diverge from its default behavior.

How these logical statements could be acquired is too broad of a
subject to be properly treated here.  But in essence this would also
be delegated to Hyperon, by providing traces of instances of MOSES
solving past problems.

What it means is that the way MOSES needs to be implemented should
generally follow the rule

*When the decision is hard to make, ask Hyperon for help*

For instance if in the MOSES code you have the conditional

```
(if C B₁ B₂)
```

and C happens to be very difficult to establish, then C should be
formulated as a query to Hyperon.  In other words, delegate to Hyperon
anything that is too hard for MOSES alone.

### Between MOSES and humans

Integrating MOSES in the MeTTa LSP server could be one way to enable
some form of synergy between MOSES and MeTTa programmers.  Imagine for
instance a programmer is writing some function in MeTTa, has some
examples of how it should behave but no algorithm in mind yet.  The
programmer would be able to invoke MOSES via the MeTTa LSP server and
get a list of candates solutions in return.

The other direction, human programmer helping MOSES, should be
possible as well.  Upon launching MOSES, the user should be able to
interrupt it, query its state, inspect its memory content, and even
modify it as to change the direction of the search.

## Black box vs clear box

The most basic way to use a fitness function is as a black box that
can score candidate solutions and nothing more.  That is likely the
only way when it is written in a foreign programming language such as
C++.  However, as soon as it is written in MeTTa it becomes a clear
box.  Such fitness can now be analyzed and reasoned upon.  The
possibilities this offers are limitless, but just to give a simple
example, one could for instance invoke a reasoner to come up with a
fitness estimator that is less accurate but more efficient than the
original fitness, while guarantying properties such as for instance
the estimator is greater than the original fitness pointwise, so that
it will never under-evaluate good candidates, etc.

## Program Evolution as a Form of Reasoning
