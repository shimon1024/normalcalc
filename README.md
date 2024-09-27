# normalcalc

A purely functional esoteric programming language

## Run

`runghc nci.hs src.nc`

## Features

- Turing completeness based on the SK calculus
- Monadic IO

## Operators

- `` ` ``: Function application operator
- `*`: Substitution function (the S combinator)
- `/`: Constant function (the K combinator)
- `|`: Bind function (also called flatMap)
- `_`: Return function (also called pure and unit)
- `,`: Input function
- `.`: Output function
- `#`: Line comment

## License

- `nci.hs`, `test.sh`, `play/*`: MIT-0
- `t/*`: CC0-1.0

## Links

- https://github.com/simon-i1-h/normalcalc
- https://esolangs.org/wiki/Normalcalc
