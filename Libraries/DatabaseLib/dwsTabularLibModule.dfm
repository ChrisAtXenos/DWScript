object dwsTabularLib: TdwsTabularLib
  OldCreateOrder = False
  Height = 150
  Width = 215
  object dwsTabular: TdwsUnit
    Classes = <
      item
        Name = 'TabularData'
        Constructors = <
          item
            Name = 'CreateFromDataSet'
            Parameters = <
              item
                Name = 'ds'
                DataType = 'DataSet'
              end>
            OnEval = dwsTabularClassesTabularDataConstructorsCreateFromDataSetEval
          end>
        Methods = <
          item
            Name = 'EvaluateAggregate'
            Parameters = <
              item
                Name = 'aggregateFunc'
                DataType = 'String'
              end
              item
                Name = 'opcodes'
                DataType = 'array of String'
              end>
            ResultType = 'Float'
            OnEval = dwsTabularClassesTabularDataMethodsEvaluateAggregateEval
            Kind = mkFunction
          end
          item
            Name = 'EvaluateNewColumn'
            Parameters = <
              item
                Name = 'columnName'
                DataType = 'String'
              end
              item
                Name = 'opcodes'
                DataType = 'array of String'
              end>
            ResultType = 'Float'
            OnEval = dwsTabularClassesTabularDataMethodsEvaluateNewColumnEval
            Kind = mkFunction
          end
          item
            Name = 'ExportToSeparated'
            Parameters = <
              item
                Name = 'columnNames'
                DataType = 'array of String'
              end
              item
                Name = 'separator'
                DataType = 'String'
                HasDefaultValue = True
                DefaultValue = ','
              end
              item
                Name = 'quoteChar'
                DataType = 'String'
                HasDefaultValue = True
                DefaultValue = '"'
              end>
            ResultType = 'String'
            OnEval = dwsTabularClassesTabularDataMethodsExportToSeparatedEval
            Kind = mkFunction
          end
          item
            Name = 'DropColumn'
            Parameters = <
              item
                Name = 'columnName'
                DataType = 'String'
              end>
            ResultType = 'Boolean'
            OnEval = dwsTabularClassesTabularDataMethodsDropColumnEval
            Kind = mkFunction
          end>
        OnCleanUp = dwsTabularClassesTabularDataCleanUp
      end>
    Dependencies.Strings = (
      'System.Data')
    UnitName = 'System.Data.Tabular'
    StaticSymbols = True
    Left = 80
    Top = 24
  end
end
