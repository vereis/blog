alias Credo.Check

%{
  configs: [
    %{
      name: "default",
      files: %{
        included: [
          "apps/*/lib/",
          "apps/*/test/"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      plugins: [],
      requires: [],
      strict: true,
      parse_timeout: 5000,
      color: true,
      checks: %{
        enabled: [
          {Check.Consistency.ExceptionNames, []},
          {Check.Consistency.LineEndings, []},
          {Check.Consistency.ParameterPatternMatching, []},
          {Check.Consistency.SpaceAroundOperators, []},
          {Check.Consistency.SpaceInParentheses, []},
          {Check.Consistency.TabsOrSpaces, []},

          {Check.Design.AliasUsage,
           [priority: :low, if_nested_deeper_than: 2, if_called_more_often_than: 0]},
          {Check.Design.DuplicatedCode, []},

          {Check.Readability.AliasOrder, []},
          {Check.Readability.FunctionNames, []},
          {Check.Readability.LargeNumbers, []},
          {Check.Readability.MaxLineLength, [priority: :low, max_length: 120]},
          {Check.Readability.ModuleAttributeNames, []},
          {Check.Readability.ModuleDoc, []},
          {Check.Readability.ModuleNames, []},
          {Check.Readability.ParenthesesInCondition, []},
          {Check.Readability.ParenthesesOnZeroArityDefs, []},
          {Check.Readability.PipeIntoAnonymousFunctions, []},
          {Check.Readability.PredicateFunctionNames, []},
          {Check.Readability.PreferImplicitTry, []},
          {Check.Readability.RedundantBlankLines, []},
          {Check.Readability.Semicolons, []},
          {Check.Readability.SpaceAfterCommas, []},
          {Check.Readability.StringSigils, []},
          {Check.Readability.TrailingBlankLine, []},
          {Check.Readability.TrailingWhiteSpace, []},
          {Check.Readability.UnnecessaryAliasExpansion, []},
          {Check.Readability.VariableNames, []},

          {Check.Refactor.CondStatements, []},
          {Check.Refactor.CyclomaticComplexity, [max_complexity: 12]},
          {Check.Refactor.FunctionArity, []},
          {Check.Refactor.LongQuoteBlocks, []},
          {Check.Refactor.MapInto, []},
          {Check.Refactor.MatchInCondition, []},
          {Check.Refactor.NegatedConditionsInUnless, []},
          {Check.Refactor.NegatedConditionsWithElse, []},
          {Check.Refactor.Nesting, []},
          {Check.Refactor.UnlessWithElse, []},
          {Check.Refactor.WithClauses, []},

          {Check.Warning.ApplicationConfigInModuleAttribute, []},
          {Check.Warning.BoolOperationOnSameValues, []},
          {Check.Warning.ExpensiveEmptyEnumCheck, []},
          {Check.Warning.IExPry, []},
          {Check.Warning.IoInspect, []},
          {Check.Warning.LazyLogging, []},
          {Check.Warning.MapGetUnsafePass, []},
          {Check.Warning.OperationOnSameValues, []},
          {Check.Warning.OperationWithConstantResult, []},
          {Check.Warning.RaiseInsideRescue, []},
          {Check.Warning.SpecWithStruct, []},
          {Check.Warning.WrongTestFileExtension, []},
          {Check.Warning.UnusedEnumOperation, []},
          {Check.Warning.UnusedFileOperation, []},
          {Check.Warning.UnusedKeywordOperation, []},
          {Check.Warning.UnusedListOperation, []},
          {Check.Warning.UnusedPathOperation, []},
          {Check.Warning.UnusedRegexOperation, []},
          {Check.Warning.UnusedStringOperation, []},
          {Check.Warning.UnusedTupleOperation, []},
          {Check.Warning.UnsafeExec, []}
        ],
        disabled: [
          {Check.Design.TagTODO, []},
          
          {Check.Refactor.ABCSize, []},
          {Check.Refactor.AppendSingleItem, []},
          {Check.Refactor.DoubleBooleanNegation, []},
          {Check.Refactor.ModuleDependencies, []},
          {Check.Refactor.NegatedIsNil, []},
          {Check.Refactor.PipeChainStart, []},
          {Check.Refactor.VariableRebinding, []},
          
          {Check.Readability.AliasAs, []},
          {Check.Readability.BlockPipe, []},
          {Check.Readability.ImplTrue, []},
          {Check.Readability.MultiAlias, []},
          {Check.Readability.SeparateAliasRequire, []},
          {Check.Readability.SinglePipe, []},
          {Check.Readability.StrictModuleLayout, []},
          {Check.Readability.WithSingleClause, []}
        ]
      }
    }
  ]
}