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

## The Goal of the Port

I believe the goal of the port should not be to verbatimely reproduce
AS-MOSES inside Hyperon.  The goal, in my opinion, should be to create
a *sufficiently open-ended program learning technology that integrates
with the rest of Hyperon to enable some form of cognitive synergy*.
Indeed, even though AS-MOSES contains important innovations that we
want to be ported, it misses the cognitive synergy aspect.

Pragmatically speaking, cognitive synergy here means that, if MOSES
gets stuck in the process of evolving programs, it can formulate a
demand of help to the rest of Hyperon, and take advantage of the
response to unstick itself.  Likewise, if other components of Hyperon
are stuck, they can formulate demands of help to MOSES and take
advantage of its response.

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

### Cognitive Synergy between MOSES and Hyperon

#### How can Hyperon helps MOSES?

How can MOSES be helped by Hyperon?  First, any hyperparameters
controlling MOSES, such as for instance the portion of evaluations
that should be allocated to search any particular deme, can be tuned
by Hyperon.  Second, a big help would probably go to the optimization
phase.  This is after all where most of the computational resources
are going to be spent.  Selecting the right optimization algorithm for
the right problem is an example, though may fall under the
hyperparameter tuning aspect mentioned above.  If the optimization
algorithm is EDA-based, then a very important avenue for help is in
modelling the fitness landscape.  This is not an easy thing to do and
requires for instance the ability to properly balance exploration and
exploitation, which some components of Hyperon are (or will be)
excellent at, such as reasoning and planning under uncertainty using
PLN (thanks to its ability to consider both strength and confidence in
a truth value).  There is also the problem of transfering knowledge
across demes, and ultimately across problems as well.  For instance
ideally the wisdom accumulated to effectively sample a deme should not
be thrown away when a new deme is created.

So how to concretely achieve that?  The precise answer needs research
and development, but some directions can be provided.  The main idea
would be to formulate in logic, PLN or whichever logic is adequate,
the relationships between problems and various aspects of MOSES.  For
instance in the context of hyperparameter tuning, such formulation may
look like

*if problem π has property p, then hyperparameter f should be within
range r to achieve greater than average performance with probably ρ*

Then given such statements, a planner would be able to set the
hyperparameters before launching MOSES on a particular problem.

The same idea would apply to finer aspects of MOSES, such as the
optimization phase.  In the case of EDA-based optimization, such
statement could look like

*if deme d has property p, then if candidate c contains operator o₁ at
location l₁ and operator o₂ at location l₂, it is likely to be fit
with probably ρ*

Then the EDA procedure could, at particular phases, query the
atomspace for such wisdom.  If none is retreived then it would proceed
as usual, but if some is then it would be able to take advantage of it
and diverge from its default behavior.

How these logical statements could be acquired is too broad of a
subject to be properly treated here.  But in essence this would also
be delegated to Hyperon, by providing traces of instances of MOSES
solving past problems, asking Hyperon to mine those traces to discover
patterns, and populate a space of logical statements reflecting these
patterns, which would in turn accelerate MOSES in the next runs.

An alternate, though somewhat equivalent in spirit way, suggested by
Ben Goertzel a while ago would be to formulate tasks as calls to a
universal sampler (a function able to sample any distribution layered
with any constraint), called
[SampleLink](https://wiki.opencog.org/w/OpenCoggy_Probabilistic_Programming#SAMPLE_LINK).
The difficulty then comes does down to providing an implementation of
such universal sampler that can utilize Hyperon accumulated wisdom.

Generally speaking it means is that the way MOSES (or SampleLink)
needs to be implemented should follow the rule

*When the decision is hard to make, ask Hyperon for help*

For instance if there is a conditional in the MOSES code

```
(if C B₁ B₂)
```

and C happens to be difficult to establish, then C should be
formulated as a query to Hyperon.  In other words, anything that is
too hard for MOSES alone should be delegate to Hyperon.  When a trace
of MOSES' run is recorded, it should also record these queries and
their results, because it can inform Hyperon about what needs to be
improved.  If the query corresponding to condition `C` often came back
unanswered, or answered with low confidence, it gives a cue to Hyperon
that, in order to better help MOSES, it must find ways to better
answer that query in the future.

I have left undefined the notion of *query to Hyperon*, but for
starter one can simply have in mind a *pattern matching query*,
because Hyperon should hopefully be hyper optimized to fulfill these.
Thus the idea is

*If Hyperon already knows how to help, then it can help on the spot at
almost no cost by answering the query.  Otherwise, it does not help,
thus MOSES defers such a default behavior, but Hyperon can keep a
trace of the interaction for future improvements.*

Such notion of *query to Hyperon* can be extended by for instance
using the chainer.  In that case *pattern matching query* would be
replaced by *reasoning*, or perhaps *shallow reasoning*.  It means
however that the effort spent in such reasoning needs to be properly
controlled.  That could be done by for instance guarantying some
temporal upper bound as to make reasoning about MOSES' overall
efficiency easier.

#### How can MOSES helps Hyperon?

Any problem that can be formulated as being solved by finding programs
fulfilling some fitness can likely be solved by MOSES.  That may or
may not encompass any problem.  Of course MOSES will tend to perform
better on some problems and worse on others.  So, determining whether
MOSES can help is some particular situation amounts to being able to
formulate the proper fitness function and then evaluate how efficient
MOSES can be on that fitness function.  Thus Hyperon should
progressively accumulate knowledge to be able to estimate how well
MOSES can come up with a solution for a particular problem, given some
amount of available resources.

#### How can MOSES helps MOSES?

MOSES should be able to discover pattern inside its own traces, in the
manner as described in [How can MOSES helps MOSES?](#how-can-hyperon-helps-moses?).
Thus by applying MOSES at the meta-level, MOSES could in fact help itself.

### Cognitive Synergy between MOSES and Humans

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

## Program Evolution as Reasoning Process

One way to realize cognitive synergy is to never really leave the
logical side.  That is, having MOSES explicitely operate as a form of
reasoning.  I am not necessarily advocating for that, because it has a
number of drawbacks, but it is likely the way I would do it if I were
tasked to do the MOSES port myself.  The main drawbacks are

1. the unfront cost of formulating evoluationary learning as a form of
reasoning;
2. the run-time cost of doing evolution using reasoning.

The main benefit in my view, is that it enables, at least in
potential, the deepest levels of cognitive synergy one can hope to
achieve.  Besides, over time the run-time cost can be mitigated by
*schematizing* (as Ben Goertzel likes to say), or *specializing* (as
Alexey Potapov likes to say) the parts of MOSES that require the least
amount of synergy with the rest of Hyperon.

Perhaps a hybrid approach can be considered from the get go, where
MOSES is partly implemented in a functional way, and partly
implemented as an explicit form of reasoning.  The non-determinism of
MeTTa can actually make these distinctions somewhat blurried.

The general idea of framing evoluation as a form of reasoning is that
the problem of finding good program candidates is directly formulated
as a query in logic, then MOSES merely provides an efficient inference
control mechanism to fulfill such query, and by that discover such
program candidates.

There are at least two ways to formulate such query, in a
non-constructive vs constructive way.  Explaining in depth the
difference between the two is probably outside of the scope of that
document but for our concern it suffices to say that in constructive
mathematics proving an existential statement, such as `∃x P(x)`,
garanties that there is a way to construct an object `a` such that
`P(a)` is true.  While in non-constructive mathematics one could
indeed prove the existence of an object without ever having to be able
to construct it.

Due to that major difference, formulating such query will take a
different shape if it is done in a constructive vs non-constructive
way.

### Constructive Way

In the constructive case a statement leading to finding a program
candidate may merely look like

```
∃x GoodFit(x)
```

Then finding a proof of such statement will provide a program
candidate.  To find more candidates one may simply finding more
proofs.

### Non-constructive Way

In the non-constructive way, it is also possible to use reasoning to
find program candidates, but the candidate must instead be represented
as a free variable inside the statement, and the reasoning must be
able to instantiate that variable during reasoning.  At the end of the
reasoning process, the candidate may be absent from the proof, but
present inside a refined version of the statement.  For instance such
statement may initially look like

```
GoodFit(x)
```

Then finding a proof will result in a program candidate appearing in
the now grounded statement

```
GoodFit(CANDIDATE)
```

The backward and forward chainers of Hyperon support both,
constructive and non-constructive, ways.  Thus it is not immediately
obvious which way is best.  Ultimately we will have to experiment with
both ways to really know.

### Type Theoretical Way

The Type Theoretical way can be used both constructively and
non-constructively, though particularily shines when used
constructively.

We will give below an example of how to use dependent types, and more
specifically the Sigma type, Σ, to represent such existentially
quantified statements and to discover program candidates.

### GoodFit as Type Predicate

The standard way to represent existential quantification with
dependent types is via the Sigma type, Σ, which can be defined in
MeTTa as follows

```
(: MkΣ (-> (: $p (-> $a Type))
           (: $x $a)
           (: $prf ($p $x))
           (Σ $a $p)))
```

where
- `$p` is a predicate type,
- `$a` is the domain of `$p`,
- `($p $x)` is `$p` applied to an element `$x` of `$a`,
- `$prf` is a proof of `($p $x)`,
- `(Σ $a $p)` is the Sigma type expressing that there exists an
  element of `$a` which satisfied property `$p`.

In our case the property will be the goodness of fit.  However,
because we want to be able to quantify that fitness, the predicate is
parameterized by the fitness score.  In the end the type we are
looking for looks something like

```
(Σ (-> Bool Bool Bool) (Fit 0.7))
```

where `(-> Bool Bool Bool)` represents the domain of the candidates,
in this case, binary Boolean functions, and `(Fit 0.7)` represents the
predicate expressing the class of candidates that are fit with degree
of fitness 0.7.  Thus `GoodFit` has been replaced by the parameterized
type `(Fit FITNESS)`.

A proof for such type may look like

```
(MkΣ (Fit 0.7) (λ $x (λ $y (and $x $y))) PROOF_OF_FITNESS)
```

One can verify that each argument is an inhabitant of the argument
types of `MkΣ`, meaning

- `(: (Fit 0.7) (-> (-> Bool Bool Bool) Type))`
- `(: (λ $x (λ $y (and $x $y))) (-> Bool Bool Bool))`
- `(: PROOF_OF_FITNESS ((Fit 0.7) (λ $x (λ $y (and $x $y)))))`

`PROOF_OF_FITNESS` is left unspecified for efficiency reasons.  We
will see indeed that we can inject computations in that reasoning
process, thus not necessarily framed as a form of reasoning, to speed
up some aspects of it.

Note that a proof of `(-> Bool Bool Bool)` is a program, and the
reasoning process will be able to build that program in the same
manner that it can build a proof.

A prototype of such evolutionary program learner framed as a reasoning
process can be found [here](URL).  Beware though that a few of things
have been changed.

1. In order to quote the programs, to avoid spontaneous reduction by
   the MeTTa interpreter over a reducable MeTTa expression such as
   `(and True False)`, the vocabulary does not include MeTTa built-ins
   such as `and`, `True`, etc.  Instead new symbols are introduced
   using unicode, so that `and` in MeTTa becomes `𝐚𝐧𝐝` in the
   reasoning process, etc.  This could perhaps be avoided by a clever
   use of the `quote` built-in, or by implementing the chainer in
   Minimal MeTTa.  But for the sake of simplicity and speed, this
   prototype uses that unicode trick instead.

2. Similarily, to avoid spontaneous unification from taking placed
   during reasoning, variables inside programs are replaced by
   DeBruijn indices.  So for instance `(λ $x (λ $y (and $x $y)))`
   becomes `(λ (λ (and z (s z))))` where `z` is the first DeBruijn
   index, `(s z)` is the second, etc.

3. To avoid exacerbating combinatorial explosion, lambda abstraction
   is actually completely eliminated.  So instead of introducing
   program variables (i.e. DeBruijn indices) via lambda abstraction,
   these are manually added to the environment at the beginning of
   reasoning.  As a result instead of evolving a program with the type
   signature `(-> Bool Bool Bool)`, the following assumptions are
   added `(: z Bool)` and `(: (s z) Bool)` representing the types of
   the first two arguments of the program to evolve.  And thus the
   type signature of the program `(-> Bool Bool Bool)` is replaced by
   `Bool`.  Note that this gymnastic is actually exactly what the
   chainer does when encountering a lambda abstraction, so it is a
   rather natural trick.  The difference is that it is done before
   reasoning and never during reasoning, because, as I said,
   introducing lambda abstraction on the fly during reasoning
   exacerbates combinatorial explosion.  Indeed, every new lambda
   abstraction increases the possibilities of function applications,
   and every new function application provides one more body for
   lambda abstraction.  That situation becomes rapidely unmanageable,
   thus why we try to avoid it.  It may be that at some point
   reasoning becomes so efficient that lambda abstraction can be
   re-introduced.

### Reasoning Efficiently

Of course framing learning as a form of reasoning, as elegant as it
may be, is only worth it if it results in an efficient process.  There
are at least two ways this can be accomplished:

1. Injecting regular computation in the reasoning process.  The idea
   is to outsource some proof obligations to some external
   computational processes that we trust.  For instance, let's say we
   want to prove that 2 + 3 = 5.  One way to do this is to use
   reasoning exclusively, progressively transforming 2 + 3 to 1 + 4,
   then to 0 + 5, then finally to 5 by manipulating the laws of
   equality and addition.  Even though this way is perfectly correct
   it is also quite costly.  Another way to do this is to query the
   CPU with an ADD instruction with 2 and 3 as arguments, get the
   results, and trust that the resulting equation is indeed true.
   This is how `PROOF_OF_FITNESS` would be typically obtained in our
   evolutionary programming case.  In fact in the prototype referenced
   earlier such proof is labelled `CPU` to convey the idea that it can
   be read as "it is true because the CPU said so".  Of course, in
   reality, more that the CPU has to say so, the function that is part
   of that external computational process has to be properly
   implemented, but we call it `CPU` merely to capture that idea.

2. Leveraging inference control.  NEXT

## Modularity

## Author

Nil Geisweiller
