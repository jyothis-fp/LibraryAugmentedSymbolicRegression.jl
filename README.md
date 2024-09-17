<!-- prettier-ignore-start -->
<div align="center">

LibraryAugmentedSymbolicRegression.jl (LaSR.jl) accelerates the search for symbolic expressions using library learning.

| Latest release | Website | Forums | Paper |
| :---: | :---: | :---: | :---: |
| [![version](https://juliahub.com/docs/LibraryAugmentedSymbolicRegression/version.svg)](https://juliahub.com/ui/Packages/LibraryAugmentedSymbolicRegression/X2eIS) | [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://trishullab.github.io/lasr-web/) | [![Discussions](https://img.shields.io/badge/discussions-github-informational)](https://github.com/trishullab/LibraryAugmentedSymbolicRegression.jl/discussions) | [![Paper](https://img.shields.io/badge/arXiv-????.?????-b31b1b)](https://atharvas.net/static/lasr.pdf) |

| Build status | Coverage |
| :---: | :---: |
| [![CI](https://github.com/trishullab/LibraryAugmentedSymbolicRegression.jl/workflows/CI/badge.svg)](.github/workflows/CI.yml) | [![Coverage Status](https://coveralls.io/repos/github/trishullab/LibraryAugmentedSymbolicRegression.jl/badge.svg?branch=master)](https://coveralls.io/github/trishullab/LibraryAugmentedSymbolicRegression.jl?branch=master) |

LaSR is integrated with [SymbolicRegression.jl](https://github.com/MilesCranmer/SymbolicRegression.jl). Check out [PySR](https://github.com/MilesCranmer/PySR) for
a Python frontend.

[Cite this software](https://arxiv.org/abs/????.?????)

</div>
<!-- prettier-ignore-end -->

**Contents**:

- [Quickstart](#quickstart)
- [Benchmarking](#benchmarking)
- [Organization](#organization)
- [LLM Utilities](#llm-utilities)

## Quickstart

Install in Julia with:

```julia
using Pkg
Pkg.add("LibraryAugmentedSymbolicRegression")
```

LaSR uses the same interface as [SymbolicRegression.jl](https://github.com/MilesCranmer/SymbolicRegression.jl). The easiest way to use LibraryAugmentedSymbolicRegression.jl
is with [MLJ](https://github.com/alan-turing-institute/MLJ.jl).
Let's see an example:

```julia
import LibraryAugmentedSymbolicRegression: LaSRRegressor, LLMOptions
import MLJ: machine, fit!, predict, report

# Dataset with two named features:
X = (a = rand(500), b = rand(500))

# and one target:
y = @. 2 * cos(X.a * 23.5) - X.b ^ 2

# with some noise:
y = y .+ randn(500) .* 1e-3

model = LaSRRegressor(
    niterations=50,
    binary_operators=[+, -, *],
    unary_operators=[cos],
    llm_options=LLMOptions(
      ...
    )
)
```

Now, let's create and train this model
on our data:

```julia
mach = machine(model, X, y)

fit!(mach)
```

You will notice that expressions are printed
using the column names of our table. If,
instead of a table-like object,
a simple array is passed
(e.g., `X=randn(100, 2)`),
`x1, ..., xn` will be used for variable names.

Let's look at the expressions discovered:

```julia
report(mach)
```

Finally, we can make predictions with the expressions
on new data:

```julia
predict(mach, X)
```

This will make predictions using the expression
selected by `model.selection_method`,
which by default is a mix of accuracy and complexity.

You can override this selection and select an equation from
the Pareto front manually with:

```julia
predict(mach, (data=X, idx=2))
```

where here we choose to evaluate the second equation.

For fitting multiple outputs, one can use `MultitargetLaSRRegressor`
(and pass an array of indices to `idx` in `predict` for selecting specific equations).
For a full list of options available to each regressor, see the [API page](https://astroautomata.com/LibraryAugmentedSymbolicRegression.jl/dev/api/).

### LLM Options

LaSR uses PromptingTools.jl for zero shot prompting. If you wish to make changes to the prompting options, you can pass an `LLMOptions` object to the `LaSRRegressor` constructor. The options available are:
```julia
llm_options = LLMOptions(
    active=true,                                                                # Whether to use LLM inference or not
    weights=LLMWeights(llm_mutate=0.5, llm_crossover=0.3, llm_gen_random=0.2),  # Probabilities of using LLM for mutation, crossover, and random generation
    num_pareto_context=5,                                                       # Number of equations to sample from the Pareto frontier for summarization.
    prompt_evol=true,                                                           # Whether to evolve natural language concepts through LLM calls.
    prompt_concepts=true,                                                       # Whether to use natural language concepts in the search.
    api_key="token-abc123",                                                     # API key to OpenAI API compatible server.
    model="meta-llama/Meta-Llama-3-8B-Instruct",                                # LLM model to use.
    api_kwargs=Dict("url" => "http://localhost:11440/v1"),                      # Keyword arguments passed to server.
    http_kwargs=Dict("retries" => 3, "readtimeout" => 3600),                    # Keyword arguments passed to HTTP requests.
    llm_recorder_dir="lasr_runs/debug_0",                                       # Directory to log LLM interactions.
    llm_context="",                                                             # Natural language concept to start with. You should also be able to initialize with a list of concepts.
    var_order=nothing,                                                          # Dict(variable_name => new_name).
    idea_threshold=30                                                           # Number of concepts to keep track of.
)
```

## Benchmarking

If you wish to compare against LaSR, we've archived the code we used to run LaSR on top of PySR and SymbolicRegression.jl in the `lasr-experiments` branch. Run
```bash
$ git switch lasr-experiments
```
and follow the instructions in the README to reproduce our results. This directory contains the code for evaluating LaSR on the 

- [x] Feynman Equations dataset
- [x] Synthetic equations dataset
    - [x] and generation code
- [x] Bigbench experiments
    - [x] and evaluation code

## Organization

LibraryAugmentedSymbolicRegression.jl development is kept independent from the main codebase. However, to ensure LaSR can be used easily, it is integrated into SymbolicRegression.jl via the [`ext/SymbolicRegressionLaSRExt`](https://www.example.com) extension module. This, in turn, is loaded into PySR. This cartoon summarizes the interaction between the different packages:

![LibraryAugmentedSymbolicRegression.jl organization](https://raw.githubusercontent.com/trishullab/lasr-web/main/static/lasr-code-interactions.svg)

> [!NOTE]  
> The `ext/SymbolicRegressionLaSRExt` module is not yet available in the released version of SymbolicRegression.jl. It will be available in the release `vX.X.X` of SymbolicRegression.jl.


## Code structure

LibraryAugmentedSymbolicRegression.jl is organized roughly as follows.
Rounded rectangles indicate objects, and rectangles indicate functions.

> (if you can't see this diagram being rendered, try pasting it into [mermaid-js.github.io/mermaid-live-editor](https://mermaid-js.github.io/mermaid-live-editor))

```mermaid
flowchart TB
    op([Options])
    d([Dataset])
    op --> ES
    d --> ES
    subgraph ES[equation_search]
        direction TB
        IP[sr_spawner]
        IP --> p1
        IP --> p2
        subgraph p1[Thread 1]
            direction LR
            pop1([Population])
            pop1 --> src[s_r_cycle]
            src --> opt[optimize_and_simplify_population]
            opt --> pop1
        end
        subgraph p2[Thread 2]
            direction LR
            pop2([Population])
            pop2 --> src2[s_r_cycle]
            src2 --> opt2[optimize_and_simplify_population]
            opt2 --> pop2
        end
        pop1 --> hof
        pop2 --> hof
        hof([HallOfFame])
        hof --> migration
        pop1 <-.-> migration
        pop2 <-.-> migration
        migration[migrate!]
    end
    ES --> output([HallOfFame])
```

The `HallOfFame` objects store the expressions with the lowest loss seen at each complexity.

The dependency structure of the code itself is as follows:

```mermaid
stateDiagram-v2
    AdaptiveParsimony --> Mutate
    AdaptiveParsimony --> Population
    AdaptiveParsimony --> RegularizedEvolution
    AdaptiveParsimony --> SingleIteration
    AdaptiveParsimony --> LaSR
    CheckConstraints --> Mutate
    CheckConstraints --> LaSR
    Complexity --> CheckConstraints
    Complexity --> HallOfFame
    Complexity --> LossFunctions
    Complexity --> Mutate
    Complexity --> Population
    Complexity --> SearchUtils
    Complexity --> SingleIteration
    Complexity --> LaSR
    ConstantOptimization --> Mutate
    ConstantOptimization --> SingleIteration
    Core --> AdaptiveParsimony
    Core --> CheckConstraints
    Core --> Complexity
    Core --> ConstantOptimization
    Core --> HallOfFame
    Core --> InterfaceDynamicExpressions
    Core --> LossFunctions
    Core --> Migration
    Core --> Mutate
    Core --> MutationFunctions
    Core --> PopMember
    Core --> Population
    Core --> Recorder
    Core --> RegularizedEvolution
    Core --> SearchUtils
    Core --> SingleIteration
    Core --> LaSR
    Dataset --> Core
    HallOfFame --> SearchUtils
    HallOfFame --> SingleIteration
    HallOfFame --> LaSR
    InterfaceDynamicExpressions --> LossFunctions
    InterfaceDynamicExpressions --> LaSR
    LossFunctions --> ConstantOptimization
    LossFunctions --> HallOfFame
    LossFunctions --> Mutate
    LossFunctions --> PopMember
    LossFunctions --> Population
    LossFunctions --> LaSR
    Migration --> LaSR
    Mutate --> RegularizedEvolution
    MutationFunctions --> Mutate
    MutationFunctions --> Population
    MutationFunctions --> LaSR
    Operators --> Core
    Operators --> Options
    Options --> Core
    OptionsStruct --> Core
    OptionsStruct --> Options
    PopMember --> ConstantOptimization
    PopMember --> HallOfFame
    PopMember --> Migration
    PopMember --> Mutate
    PopMember --> Population
    PopMember --> RegularizedEvolution
    PopMember --> SingleIteration
    PopMember --> LaSR
    Population --> Migration
    Population --> RegularizedEvolution
    Population --> SearchUtils
    Population --> SingleIteration
    Population --> LaSR
    ProgramConstants --> Core
    ProgramConstants --> Dataset
    ProgressBars --> SearchUtils
    ProgressBars --> LaSR
    Recorder --> Mutate
    Recorder --> RegularizedEvolution
    Recorder --> SingleIteration
    Recorder --> LaSR
    RegularizedEvolution --> SingleIteration
    SearchUtils --> LaSR
    SingleIteration --> LaSR
    Utils --> CheckConstraints
    Utils --> ConstantOptimization
    Utils --> Options
    Utils --> PopMember
    Utils --> SingleIteration
    Utils --> LaSR
```

Bash command to generate dependency structure from `src` directory (requires `vim-stream`):

```bash
echo 'stateDiagram-v2'
IFS=$'\n'
for f in *.jl; do
    for line in $(cat $f | grep -e 'import \.\.' -e 'import \.'); do
        echo $(echo $line | vims -s 'dwf:d$' -t '%s/^\.*//g' '%s/Module//g') $(basename "$f" .jl);
    done;
done | vims -l 'f a--> ' | sort
```

## Search options

Other than `LLMOptions`, We have the same search options as SymbolicRegression.jl. See https://astroautomata.com/SymbolicRegression.jl/stable/api/#Options
