# Power BI deliverable status

This repository contains a complete semantic-model specification, verified KPI outputs, DAX measures, page design, interaction contract, mobile layout, and reconciliation checklist.

A `.pbix` file is intentionally not included. The execution environment did not provide Power BI Desktop, so a native report could not be created or opened for verification. The static SVG in `visuals/dashboard-overview.svg` is an evidence-backed design preview generated from the verified CSV outputs; it is not presented as a Power BI screenshot.

To build the report:

1. Run the Oracle scripts and import the sources listed in `model.md`.
2. Create the relationships exactly as documented.
3. Add the measures from `dax_measures.dax`.
4. Build the four pages described in `model.md`.
5. Reconcile cards and peer medians to the two committed processed CSV files.
6. Save the `.pbix`, test interactions and mobile layout, and only then add it to this folder.
