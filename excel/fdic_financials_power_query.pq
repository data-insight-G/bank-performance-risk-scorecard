let
    ApiEndpoint = "https://api.fdic.gov/banks/financials",
    SourceFilter = "REPDTE:[20200331 TO 20241231]",
    PageSize = 10000,
    ExpectedFixedRowCount = 96902,
    SourceFields = {
        "CERT", "REPDTE", "NAME", "STALP", "SPECGRPDESC", "CB", "ASSET",
        "DEP", "DEPDOM", "COREDEP", "LNLSNET", "NETINC", "ROA", "ROE",
        "NIMY", "EQ", "EQV", "LNLSDEPR", "NCLNLSR", "NTLNLSR",
        "LNATRESR", "OFFDOM", "SZLNRES", "SZLNCI", "SZLNCRCD", "SZLNAUTO",
        "SZLNCON", "SZLNHEL", "SZLNOTH"
    },
    ExpectedReportDates = {
        "20200331", "20200630", "20200930", "20201231",
        "20210331", "20210630", "20210930", "20211231",
        "20220331", "20220630", "20220930", "20221231",
        "20230331", "20230630", "20230930", "20231231",
        "20240331", "20240630", "20240930", "20241231"
    },
    GetPage = (Offset as number) as record =>
        Json.Document(
            Web.Contents(
                ApiEndpoint,
                [
                    Query = [
                        filters = SourceFilter,
                        fields = Text.Combine(SourceFields, ","),
                        sort_by = "REPDTE",
                        sort_order = "ASC",
                        limit = Text.From(PageSize),
                        offset = Text.From(Offset)
                    ],
                    Headers = [Accept = "application/json"]
                ]
            )
        ),
    FirstPage = GetPage(0),
    ExpectedRowCount = FirstPage[meta][total],
    PageOffsets = List.Generate(
        () => 0,
        each _ < ExpectedRowCount,
        each _ + PageSize
    ),
    PagePayloads = List.Transform(
        PageOffsets,
        each if _ = 0 then FirstPage else GetPage(_)
    ),
    ExtractPageRows = (PagePayload as record) as list =>
        List.Transform(PagePayload[data], each _[data]),
    SourceRows = List.Combine(List.Transform(PagePayloads, each ExtractPageRows(_))),
    SourceTable = Table.FromRecords(SourceRows),
    SelectedColumns = Table.SelectColumns(SourceTable, SourceFields, MissingField.Error),
    TypedColumns = Table.TransformColumnTypes(
        SelectedColumns,
        {
            {"CERT", Int64.Type}, {"REPDTE", type text}, {"NAME", type text},
            {"STALP", type text}, {"SPECGRPDESC", type text}, {"CB", Int64.Type},
            {"ASSET", type number}, {"DEP", type number}, {"DEPDOM", type number},
            {"COREDEP", type number}, {"LNLSNET", type number}, {"NETINC", type number},
            {"ROA", type number}, {"ROE", type number}, {"NIMY", type number},
            {"EQ", type number}, {"EQV", type number}, {"LNLSDEPR", type number},
            {"NCLNLSR", type number}, {"NTLNLSR", type number},
            {"LNATRESR", type number}, {"OFFDOM", Int64.Type},
            {"SZLNRES", type number}, {"SZLNCI", type number},
            {"SZLNCRCD", type number}, {"SZLNAUTO", type number},
            {"SZLNCON", type number}, {"SZLNHEL", type number},
            {"SZLNOTH", type number}
        },
        "en-US"
    ),
    DuplicateKeys = Table.SelectRows(
        Table.Group(
            TypedColumns,
            {"CERT", "REPDTE"},
            {{"RowCount", each Table.RowCount(_), Int64.Type}}
        ),
        each [RowCount] > 1
    ),
    ActualReportDates = List.Sort(List.Distinct(Table.Column(TypedColumns, "REPDTE"))),
    ValidatedRows =
        if ExpectedRowCount <> ExpectedFixedRowCount then
            error "FDIC metadata no longer matches the approved 96,902-row snapshot."
        else if Table.RowCount(TypedColumns) <> ExpectedRowCount then
            error "FDIC row count does not match API metadata."
        else if Table.RowCount(DuplicateKeys) <> 0 then
            error "Duplicate CERT/report-date keys were returned."
        else if ActualReportDates <> ExpectedReportDates then
            error "The extract does not contain exactly the 20 expected quarter ends."
        else
            TypedColumns
in
    ValidatedRows
