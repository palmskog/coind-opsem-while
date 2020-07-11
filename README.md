# Trace-Based Coinductive Operational Semantics for While

[![CI][action-shield]][action-link]

[action-shield]: https://github.com/palmskog/coind-opsem-while/workflows/CI/badge.svg?branch=master
[action-link]: https://github.com/palmskog/coind-opsem-while/actions?query=workflow%3ACI




Four equivalent coinductive operational semantics in Coq for the While language accounting
for both terminating and non-terminating program runs through coinductive traces.

## Meta

- Author(s):
  - Keiko Nakata (initial)
  - Tarmo Uustalu (initial)
- Compatible Coq versions: 8.10 or later
- Additional dependencies: none
- Coq namespace: `CoindOpSemWhile`
- Related publication(s):
  - [Trace-Based Coinductive Operational Semantics for While](https://link.springer.com/chapter/10.1007/978-3-642-03359-9_26) doi:[10.1007/978-3-642-03359-9_26](https://doi.org/10.1007/978-3-642-03359-9_26)

## Building instructions

``` shell
git clone https://github.com/palmskog/coind-opsem-while
cd coind-opsem-while
make   # or make -j <number-of-cores-on-your-machine>
```

## Documentation

- `Trace.v` defines traces and bisimilarity. It proves
  bisimilarity is reflexive, symmetric and transitive.
- `Language.v` defines the While language.
- BigRel.v defines the big-step relational semantics
  and proves that it is deterministic and a setoid predicate.
- `SmallRel.v` defines the small-step relational semantics
  and proves that it is deterministic and a setoid predicate
  and that the big-step relational and small-step relational
  semantics are equivalent.
- `BigFunct.v` defines the big-step functional semantics and
  proves that the big-step relational and the big-step functional
  semantics are equivalent.
- `SmallFunct.v` defines the small-step functional semantics
  and proves that the small-step relational and the small-step
  functional semantics are equivalent and that the small-step
  functional and the big-step functional semantics are equivalent.
- `Alternatives.v` gives the complete formalizations of the alternative
  big-step semantics considered in the accompanying paper.