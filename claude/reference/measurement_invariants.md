# MEASUREMENT INVARIANTS

Generic rules, each derived from a defect that shipped. A monitor that lies costs more than the bug it was watching, because it ends the search for the bug.

## 1. PROGRESS IS FRESHNESS, NEVER EXISTENCE

A step's output is "written" only when it is NEWER than the step that writes it. Comparing against existence reports success from second zero whenever a job writes in place (`--in X --out X`).

## 2. A PRODUCER NEVER REPORTS ITS OWN INPUT BACK AS A FINDING

When a caller stamps a field onto the rows it hands a child, the child counting that field is restating the caller's selection, not measuring the data. Any such line names its own input.

## 3. NEVER KEY A CROSS-CHECK ON AN IDENTITY THAT CAN REPEAT

`{identity: row}` silently keeps the last copy. Collect every copy and union the evidence; a claim is honest when ANY copy supports it, forged when none does. Both directions need a test: the tolerance and the hole it could open.

## 4. A LONG STEP OWNS ITS OWN DEADLINE

A step killed by its parent's timeout loses everything it earned. It stops itself in time to write, records what it reached, and marks the rest as not run. A deadline stop must never satisfy the step it did not finish.

## 5. AN EFFECT CLAIM IS MEASURED AT THE SCOPE IT WILL BE USED AT

A corpus-wide row count is not a run-level verdict change. State which scope a number belongs to before it becomes a reason to act.

## 6. A CAPABILITY THAT NOTHING INVOKES DOES NOT EXIST

A producer on disk makes the capability look present while its artifact never appears, so the step it documents cannot be reconstructed later. Every claimed step leaves an artifact, or it is not a step.

## 7. A UNIT OF WORK IS JUDGED BY WHAT LANDED, AND BY WHETHER IT IS COMPLETE

Count the delivered rows, never the producer's total-hit headline. Completeness is a separate question from count: rows missing required fields are not a delivery. A plan item below its budget is DEFERRED with a reason, never silently absent. Check the denominator at the source, never at the producer's own output; an item in neither the plan nor the deferred list cannot be told apart from one that does not exist.

## 8. OBSERVED DELIVERY NEVER BOUNDS SUPPLY WHILE THE TAKER IS THE SUSPECT

Sizing a limit from what a producer has delivered so far is valid ONLY when the producer was already free to deliver more. When the same investigation found that the producer was itself under-taking (under-paginating, timing out, capped elsewhere), its historical output measures the taker, never the source, and using it to lower a ceiling locks the defect in as policy. Size the limit from the cost the depth actually incurs, price that cost on every run, and let the run report what it found.
