module MutateModule

using SymbolicRegression
using .SymbolicRegression: @recorder

using ..LLMOptionsModule: LaSROptions
using ..LLMFunctionsModule:
    llm_mutate_tree, llm_recorder, llm_crossover_trees, llm_randomize_tree

function mutate!(
    tree::N,
    ::P,
    ::Val{:llm_mutate},
    ::SymbolicRegression.AbstractMutationWeights,
    options::LaSROptions;
    recorder::SymbolicRegression.RecordType,
    curmaxsize,
    nfeatures,
    kws...,
) where {T,N<:SymbolicRegression.AbstractExpression{T},P<:SymbolicRegression.PopMember}
    tree = llm_mutate_tree(tree, options)
    @recorder recorder["type"] = "llm_mutate"
    return MutationResult{N,P}(; tree=tree)
end

function mutate!(
    tree::N,
    ::P,
    ::Val{:llm_randomize},
    ::SymbolicRegression.AbstractMutationWeights,
    options::LaSROptions;
    recorder::SymbolicRegression.RecordType,
    curmaxsize,
    nfeatures,
    kws...,
) where {T,N<:SymbolicRegression.AbstractExpression{T},P<:SymbolicRegression.PopMember}
    tree = llm_randomize_tree(tree, curmaxsize, options, nfeatures)
    @recorder recorder["type"] = "llm_randomize"
    return MutationResult{N,P}(; tree=tree)
end

"""Generate a generation via crossover of two members."""
function crossover_generation(
    member1::P, member2::P, dataset::D, curmaxsize::Int, options::LaSROptions
)::Tuple{P,P,Bool,Float64} where {T,L,D<:Dataset{T,L},N,P<:PopMember{T,L,N}}
    llm_skip = false
    if options.use_llm && (rand() < options.llm_operation_weights.llm_crossover)
        tree1 = member1.tree
        tree2 = member2.tree

        # add simplification for crossover
        tree1 = simplify_tree!(tree1, options.operators)
        tree1 = combine_operators(tree1, options.operators)
        tree2 = simplify_tree!(tree2, options.operators)
        tree2 = combine_operators(tree2, options.operators)

        crossover_accepted = false
        nfeatures = dataset.nfeatures

        if check_constant(tree1)
            tree1 = with_contents(
                tree1, gen_random_tree_fixed_size(rand(1:curmaxsize), options, nfeatures, T)
            )
        end
        if check_constant(tree2)
            tree2 = with_contents(
                tree2, gen_random_tree_fixed_size(rand(1:curmaxsize), options, nfeatures, T)
            )
        end

        child_tree1, child_tree2 = llm_crossover_trees(tree1, tree2, options)

        child_tree1 = simplify_tree!(child_tree1, options.operators)
        child_tree1 = combine_operators(child_tree1, options.operators)
        child_tree2 = simplify_tree!(child_tree2, options.operators)
        child_tree2 = combine_operators(child_tree2, options.operators)

        afterSize1 = compute_complexity(child_tree1, options)
        afterSize2 = compute_complexity(child_tree2, options)

        successful_crossover =
            (!check_constant(child_tree1)) &&
            (!check_constant(child_tree2)) &&
            check_constraints(child_tree1, options, curmaxsize, afterSize1) &&
            check_constraints(child_tree2, options, curmaxsize, afterSize2)

        if successful_crossover
            recorder_str =
                render_expr(child_tree1, options) *
                " && " *
                render_expr(child_tree2, options)
            llm_recorder(options.llm_options, recorder_str, "crossover")
            llm_skip = true
        else
            recorder_str =
                render_expr(child_tree1, options) *
                " && " *
                render_expr(child_tree2, options)
            llm_recorder(options.llm_options, recorder_str, "crossover|failed")
            child_tree1, child_tree2 = crossover_trees(tree1, tree2)
        end
    end
    if !llm_skip
        return crossover_generation(
            member1, member2, dataset, curmaxsize, options.sr_options
        )
    end
end

end
