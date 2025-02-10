TODO: internal storage of say population of candidates should also
follow a common language.

# High Level Guide of AS-MOSES port to Hyperon/MeTTa

This document is a high level guide of the AS-MOSES port from OpenCog
Classic to Hyperon/MeTTa.  It also touches upon the notion of
Cognitive Synergy in a broader context.

## AS-MOSES, a brief history

MOSES, which stands for *Meta-Optimizing Semantic Evolution Search*,
is an evolutionary program learner initially developed by Moshe Looks.
It takes in input a problem description, and outputs a set of programs
supposed to solve that problem.  A typical example is the problem of
fitting data, in that case the problem description may be a table
mapping inputs to outputs alongside a fitness function measuring how
well a candidate fits that data.

I believe the primary motivation behind the creation of MOSES came
from the desire to adapt existing EDA (Estimation of Distribution
Algorithm) methods to evolve programs instead of mere bitstrings.
Upon investigating that space, Moshe (probably with the help of Ben)
discovered that by combining a few tricks, evolving programs using EDA
was actually competitive.  We'll come back to these tricks but, let me
say that, as with anything, these tend to only work well under some
assumptions, which will attempt to recall as well.

Initially, the target programming language (i.e. the representational
language of the candidates being evolved) supported by MOSES was its
own thing, called Combo and described by Moshe as "Lisp with a bad
haircut".  Later on, as OpenCog Classic developed, the need to
integrate MOSES more deeply into OpenCog Classic came to be, and the
work of replacing Combo by Atomese, the language of OpenCog Classic
(the equivalent of MeTTa for Hyperon) was initiated.  The resulting
product was called AS-MOSES, for AtomSpace-MOSES.  That endeavor
however was never completed because the development effort was then
shifted from OpenCog Classic to Hyperon.

The repositories of MOSES can be found [here](URL) and that of
AS-MOSES can be found [there](URL).  There are very similar, the main
difference is that AS-MOSES contains some code for evolving Atomese
programs beside Combo.  The AS-MOSES code base is, in some respects, a
tiny bit cleaner, but also larger due to the additional Atomese
support.  In the rest of the document I will often mention MOSES while
meaning either MOSES or AS-MOSES.

## The Goal of the Port

I believe the goal of the port should not be to verbatimely reproduce
AS-MOSES inside Hyperon.  The goal, in my opinion, should be to create
a *sufficiently open-ended program learning framework that integrates
well with the rest of Hyperon to enable some form of cognitive
synergy*.  Indeed, even though AS-MOSES contains important innovations
that we want to be ported, it largely misses the cognitive synergy
aspect.

Pragmatically speaking, cognitive synergy here means that if MOSES
gets stuck in the process of evolving programs, it can formulate a
request of help to the rest of Hyperon and take advantage of Hyperon
to unstick itself.  Likewise, if other components of Hyperon are
stuck, they can formulate requests of help to MOSES and take advantage
of it.

There are many ways such cognitive synergy could be realized, I will
describe some that I like (or that at least I understand), but
ultimately how to do that well, i.e. producing synergy as opposed to
interference, is an open question.

There is also another form of synergy, perhaps just as important, the
synergy between MOSES and users.  This could for instance be realized
by integrating MOSES to a MeTTa LSP server.  More will be said on that
further below.

## MOSES's (not so) Secret Sauce

Let me briefly recall the main tricks I eluded earlier that
contributed to make MOSES competitive.

1. Reduce candidates to normal form.  That trick consists in applying
   rules to transform candidates into some (ideally unique) canonical
   form while preserving semantics.  For example `(and y x)` would
   become `(and x y)`, thus if MOSES generates both `(and x y)` and
   `(and y x)`, after reduction they would both point to the same
   candidate.  This has the following advantages:

   1.a. Avoid re-evaluating syntactically different, yet semantically
        identical candidates, saving some resources in the process.

   1.b. Candidates that are more consistently formatted are also more
        likely to be recombined meaningfully.

   1.c. Increase syntactic vs semantics correlation.  It is possible
        to design reduction rules so that candidates that are
        syntactically similar are more likely to be semantically
        similar.  This has the effect of making the fitness landscape
        less chaotic, therefore less deceptive.  The Elegant Normal
        Form happens to have such property.

2. Locally vectorize the search space.  Given an exemplar candidate,
   MOSES generates a program subspace around that candidate, called a
   deme.  Such subspace happens to be a vector space, thus amenable to
   a battery of optimization techniques, including EDAs.  Upon
   optimizing a deme, MOSES collects promising candidates that can
   subsequently be used as exemplars to spawn more demes.

3. Vectorize the fitness.  Instead of reducing the fitness to a single
   number, the fitness can be represented as a vector of components,
   thus providing some support for multi-objective optimization.  For
   example, MOSES can asked to retain only the Pareto front of a
   population.  Additionally, diversity pressure can be applied during
   search by taking into account the distance between such
   multi-objective scores.  Typically, component would represent the
   fitness of the candidate for each data point, as opposed to just
   its aggregated fitness.

As always, it was observed that these tricks could speed-up evolution
in some situations and slow it down in others.  Choosing the right
hyper-parameters for a given problem was often a difficult task.

## Porting MOSES's tricks to Hyperon

What is enumerated above is not the full set of tricks MOSES used, but
constitute a good starting point for porting to Hyperon.  Let me
provide some high-level guidance, or personal opinions, in that
respect.

1. Reduce candidates to normal form.  I believe this can be elegantly
   ported using either the native MeTTa pattern-based interpreter, or
   the chaining technology developed [here](URL).  It does require to
   redefine the Elegant Normal Form algorithm as an explicit set of
   rewriting rules.  I believe it is worth the effort because it may
   then offert more flexibility and extendability.  Indeed, some
   problems require weaker or stronger forms of reduction.  By
   breaking down a monolithic implementation into rules, one can more
   easily assemble subset of rules to control the reduction strength
   on a per situation basis.  Also, by reframing reduction as a form
   of reasoning, it opens the door to more flexible hybridization
   between evolution and reasoning.

2. Locally vectorize the search space.  Even though vectorizing the
   search space is a convenient and powerful way to represent a space
   to optimize, I do not think the port should be reduced only to
   that.  Indeed, it has also some drawbacks, one being that what is
   learned in a local representation is not necessarily easy to
   transfer to other representations.  In the OpenCog Classic version,
   EDA was taking the form of learning a Bayesian Network over the
   components of such vector.  But since the semantics of each
   component was not the same for other vector spaces (obtained from
   other exemplars), the wisdom accumulated during the optimization of
   a deme would not be directly transferable to other demes.  Thus I
   recommand to port that aspect but also to explore other, perhaps
   less local, representations.  Also, the way Bayesian learning phase
   did not take into account the confidence of the probabilities
   learned, which in turn made difficult to properly balance
   exploitation and exploration during sampling phase.  PLN, which has
   a native support for confidence, could potentially be used as a
   replacement.  I should mention that when vectorizing a program
   space, there is an inherant tension between expressivity and
   regularity.  The more expressively dense a representation is, the
   more deceptive it likely is as well, so vectorizing should be
   flexible and easily reprogrammable as well.  Among the set of
   possibilities, perhaps the following paper is relevant [1](REF).

3. Vectorize the fitness.  I think MOSES did a good job there and it
   can probably be ported almost as it is.  There are a number of
   diversity distances that could be ported as well.  Although to be
   perfectly clear, as every hyper-parameters in MOSES, choosing when
   and when not to use such diversity pressures very difficult.  For
   instance, retaining only the Pareto front would speed up the search
   for some problems, but slow it down for others.  Same thing for
   diversity pressure and other hyper-parameters related to diversity.
   Regarding porting the various fitness functions, there is something
   that can be brought to the next level though, which is to treat the
   fitness as a clear box as opposed to a black box.  See Section
   [Black box vs clear box](black-box-vs-clear-box) for a discussion
   on the matter.

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
manner described in [How can Hyperon helps MOSES?](#how-can-hyperon-helps-moses?).
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

### The Case for a Common Language

As I said there are multiple ways cognitive synergy can be realized.
What I am going to present is simply the use of a common language to
communicate between parts of Hyperon.  Let me reuse the old notion of
*mind agent* from OpenCog Classic, as cognitive process that would
operate within Hyperon.  Mind agents would be for instance MOSES, the
backward chainer, ECAN, etc.  So the idea is that all mind agents
share a common language to formulate requests of help to each others.
Which brings the question of what language to use.

Of course the answer is MeTTa, but there are many ways MeTTa can be
used.  So more specifically, for starter, I suggest to borrow standard
constructs from Dependently Typed Languages, such as dependent sums
and products.  To be clear, I am not necessarily advocating that we
use such a language in the long term, even though I believe it is a
good start due to its expressive power and popularity.  But it also
has drawbacks, probably the main one being that it is based on a crisp
typing relationship.  So we may for instance want to replace that by
some probabilistic extension as explored by Jonathan Warrell, Greg
Meredith and Mike Stay.  Of course, one ought to mention PLN as a
potential candidate as well.  PLN was in fact the primary candidate
for such common language back in the OpenCog Classic days, but with
the recent developments of probabilistic dependent types that question
requires reconsiderations.  PLN has also some drawbacks, one being
that, at least as formulated in the PLN book, it is non-constructive,
unlike dependent types.  But it is conceivable that a future version
of PLN, built on top of such probabilistically dependently typed
languages, may become once again that common language.  These
questions will need to be carefully re-examined as conceptual and
technical progress are being made.  For now let me simply explain how
such common language, as a regular dependently typed language crafted
for MeTTa, can be used for cognitive synergy.

The idea would be that when calling a mind-agent, the description of
the problem to solve is provided in that common language.  So, it does
not matter if the mind agent is MOSES, the backward chainer, or
something else, the query would essentially look the same.  That
approach is reminiscent to Ben Goertzel `SampleLink` idea, but
materialized somewhat more conventially, using type theoretic query
answering at the center rather than sampling.  Which does not exclude,
far from it, to re-introduce explicit forms of sampling later on.

So the basic format for calling such mind agent would be as follows

```
(<MIND_AGENT> <HYPER_PARAMETER> <QUERY>)
```

where
- `<MIND_AGENT>` is a MeTTa function, such as `moses`, for MOSES, or
  `bc` for the backward chainer, etc.
- `<HYPER_PARAMETER>` is a data structure containing all the
  hyper-parameter for the call.  That structure would contain for
  instance the effort to allocate, various default heuristics, how
  much complexity pressure to apply, pointers to spaces containing
  meta-knowledge, etc.
- `<QUERY>` is the query itself, a description of the problem to
  solve.  That description does not necessarily have to be big and
  complex because it can take advantage of a vocabulary defined in
  spaces referenced inside the `<HYPER_PARAMETER>` structure.

For instance, if one wishes to evolve a program computing a binary
function that fits a certain data set, one may express that with

```
(moses `<MOSES_HYPER_PARAMETER>`
       (: $cnd_prf (Σ (-> Bool Bool Bool) (FitMyData $fitness))))
```

where
- `(-> Bool Bool Bool)` is the type signature of the candidate we are
  look for.
- `FitMyData` is a parameterized type representing a particular custom
  fitness measure.  For the query to be understood, `FitMyData` must
  be defined in a space referenced inside `<MOSES_HYPER_PARAMETER>`.
- `$fitness` is a MeTTa variable representing a hole in the query to
  be determined by MOSES for each candidate, corresponding to the
  actual fitness score of that candidate.
- `Σ` is a Sigma type, a dependent sum, expressing the existence of
  such candidates in a constructive manner.
- `$cnd_prf` is a hole representing an inhabitant of that sigma type,
  which, upon answering the query, should contain both the candidate
  and the proof that this candidate fulfills the query.  If more than
  one such candidate exists, then the result should be a superposition
  of the inhabitants.

In that example `FitMyData` is used to hide the complexity of the
query, it does mean though that a space containing the definition of
`FitMyData` must be provided in the hyper-parameter, and other
mind-agents will need to have access to that space to fully unpack the
meaning of `FitMeData`.  More self contained definitions can also be
provided by a structured type instead of a mere symbol referring to a
predefined type.  How exactly that structured type would look like is
beyond the scope of that document and does not matter too much.  All
that matters is that the resulting type follows the type signature
required by `Σ`, which in that specific example would be

```
(-> (-> Bool Bool Bool) Type)
```

meaning that `FitMeData`, or whatever equivalent structured type, must
describe a type constructor that takes a binary boolean function and
returns a type.  This is a common way to represent predicates in
Dependently Typed Languages.

Maybe one realizes that MOSES is in fact inadequate to discover such
candidate, thus may attempt to call the backward chainer instead

```
(bc `<BC_HYPER_PARAMETER>`
    (: $cnd_prf (Σ (-> Bool Bool Bool) (FitMyData $fitness))))
```

As you can see the query remains the same, only the function being
called and its hyper-parameters are different.

But the use of that common language does not stop here as mind agents
can use such querying format internally.  Let's say for instance that
MOSES, within the course of its execution has an important decision to
make, which could be for instance: should I search a given deme more
deeply, or abandon that deme and create a new one?  A sketch of the
code could like like:

```
(= (moses $hps $query)
   <BODY ...
         (if (continue-search-deme $deme)
             <SEARCH_DEME>
             <CREATE_NEW_DEME>)
         ...>)
```

The idea is that instead of having `continue-search-deme` make that
decision in isolation, MOSES can formulate that question to Hyperon.
If Hyperon knows the answer, then MOSES can take advantance of that
knowledge, ortherwise it can defer to a default behavior.  What it
means that is the code of `continue-search-deme`, instead of solely
consisting of hardcoded heuristics, may contain queries such as

`(bc <BC_HYPER_PARAMETERS> <QUERY_ABOUT_DEME_CONTINUATION>)`

Here the backward chainer is used as example because it is assumed to
be somewhat unversal, maybe we want to have an even more universal
access point such as `hyperon`, this looking even closer to the
`SampleLink` idea.  Regardless, what will typically happen is that
such query will be parameterized to have a minimal cost, to not slow
down MOSES in its process flow.  For instance the depth of reasoning
used to answer that query could be null or almost null, keeping the
reasoning shallow and inexpensive, if any.  That way, if Hyperon knows
the answer it can help MOSES right away, otherwise, a record of that
innability to answer can be kept and used as feedback to incentivize
Hyperon to learn to succeed in the future.

One could envision a scenario where MOSES is being called on a series
of problems, while in the background other mind-agents operate some
forms of meta-learning and meta-reasoning to build-up the knowledge to
eventually help MOSES.  This can be illustrated as follows:

```
(moses HPS1 QUERY1)  <- Hyperon fails to help   |   Meta-learning ...
(moses HPS2 QUERY2)  <- Hyperon fails to help   |   Meta-learning ...
(moses HPS3 QUERY3)  <- Hyperon fails to help   |   Meta-learning ...
(moses HPS4 QUERY4)  <- Hyperon fails to help   |   Meta-learning (discovery)
(moses HPS5 QUERY5)  <- Hyperon succeeds!       |   Meta-learning ...
```

At each run towards the beginning, Hyperon fails to help MOSES at a
particular decision point (such as deme continuation), till the
knowledge to help is finally discovered.

## Black box vs clear box

The most basic way to use a fitness function is as a black box that
can score candidate solutions and nothing more.  That is likely the
only way when it is written in a foreign programming language such as
C++.  However, as soon as it is written in MeTTa it becomes a clear
box.  Such fitness can now be analyzed and reasoned upon.  The
possibilities this offers are limitless.  Just to give a simple
example, one could for instance invoke a reasoner to come up with a
fitness estimator that is less accurate but more efficient than the
original fitness, while guarantying properties such that for instance
the estimator pointwise dominate the original fitness, so that it will
never under-evaluate good candidates, etc.

I mentioned earlier that MOSES was able to handle multi-objective
fitness, it was in fact the only available transparency with respect
to the fitness function MOSES had.  Using MeTTa to describe such
fitness would allow to go much beyond that.

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
process can be found
[here](https://github.com/trueagi-io/chaining/tree/main/experimental/evolutionary-programming).
Beware though that a few of things have been changed.

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
   then to 0 + 5, then finally to 5, all that by manipulating the laws
   of equality and addition.  Even though this way is perfectly
   correct it is also quite costly.  Another way to do this is to
   query the CPU with an ADD instruction with 2 and 3 as arguments,
   get the results, and trust that the resulting equation is indeed
   true.  This is how `PROOF_OF_FITNESS` would be typically obtained
   in our evolutionary programming case.  In fact in the prototype
   referenced earlier such proof is labelled `CPU` to convey the idea
   that "it is true because the CPU said so".  Of course, in reality,
   more that the CPU has to say so, the function that is part of that
   external computational process has to be properly implemented, but
   we call it `CPU` to capture that idea.

2. Leveraging inference control.  This is where the most speed-up can
   be obtained, but this is also the most difficult way.  It is one of
   those "AGI-complete" problems, one that if you achieve it, you
   likely achieve AGI.  A potential solution for this problem is
   almost the same as the one presented for cognitive synergy.  A
   record of past inferences is stored and analyzed to extract
   predictive patterns used to guide an inference control mechanism
   for subsequent inferences.  This would be the most generic
   solution.  But one can also consider more specific handcrafted
   solutions, by implementing good old heuristics.  Indeed, one can
   see a particular Genetic Programming algorithm as implementing such
   heuristics.  There are then two ways to do that

   a. Substitute the chaining by an specific searching algorithm.  In
      that case the only remnant of a notion of reasoning is in the
      way the problem and the solutions are described (using a logical
      language as explained above).  The advantage is that one, by
      re-using existing search algorithms, can achieve speed quickly.
      The inconvenient is that it is somewhat inflexible to
      improvements, unless one is willing to learn search algorithms
      (which MOSES could potentially do, BTW).

   b. Reframe the heuristics as a set of procedural rules guiding an
      explicit inference control mechanism.  For an example of how to
      do that, see the following
      [experiment](https://github.com/trueagi-io/chaining/tree/main/experimental/inference-control)
      (beware that it is a very early stage prototype).  The
      inconvenient of that approach is that one needs to rethinking
      how to map the heuritics to that rule-based format.  The
      advantage is that it can then easily be combined with more
      generic meta-learning forms.  What that means is that the
      developer may initially provide a search heuristic, and then let
      Hyperon improve that heuristic over time.

## Modularity

Break up MOSES into subcomponents, using the same dependent types
format.

## Author

Nil Geisweiller
