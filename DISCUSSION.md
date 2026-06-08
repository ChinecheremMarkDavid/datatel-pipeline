# Discussion Questions

**1. Staging boundary and a late record.** The boundary is the `[t_start, t_end)`
window on `transaction_date`, defaulting to the logical day. Already loaded means
anything a prior run's window covered; new means anything whose `transaction_date`
falls in the current window. Because the load deletes the window then reinserts it,
rerunning a day reproduces the same result. A record that arrives two days late,
with a `transaction_date` inside a window already processed, gets missed by a strict
daily window. The fix is a trailing lookback that reprocesses the last few days each
run, or a targeted backfill for the affected day via params, which the delete-insert
design makes safe.

**2. Keeping aggregates correct.** The aggregates recompute from the staging tables,
not from raw. Staging is kept complete by the incremental loader, which only appends
or replaces the new window and never re-cleans all of history. Recomputing over clean
staging each run keeps history-spanning metrics like total revenue and ARPU correct
and idempotent. I deliberately avoid delta-merging the aggregates, adding today's
totals onto yesterday's, because that breaks under reruns and late data unless you
also subtract the prior contribution, which is fragile. The expensive work, parsing
and cleaning raw, is what we make incremental. Aggregating clean staging is cheap.

**3. stg_customers strategy.** `created_at` is a registration date, not an update
marker, and a profile can change without `created_at` changing, so there is no
reliable column to slice an incremental window on. I load `stg_customers` as a full
refresh every run. It is a small dimension table, so a full rebuild is cheap and
always reflects the latest profile values. Being incremental here would risk serving
stale names or countries.

**4. BigQuery write pattern.** A `MERGE` keyed on `customer_id`. Matched rows are
updated with refreshed metrics, unmatched rows are inserted. A plain overwrite is
only safe while every customer is present in every load; the moment a load carries a
subset, an overwrite wipes everyone not in that batch. An append duplicates rows on
every rerun. MERGE updates what is present, leaves the rest intact, and is safe to
rerun.

**5. Billing arrives six hours late.** If it lands before that day's run, no problem.
If the run already executed and the late data shares the current window's date, a
strict single-day window misses it until that date is reprocessed. To detect it, add
a freshness check comparing today's billing row count against the trailing average
and alert when it falls far below expected, and put an SLA on the load task. To
prevent it, add a small trailing lookback window, or a sensor that waits for the
source's daily load to finish before staging runs.

**6. Customer in billing but not in customers.** Trace it: the row has both IDs, so
it passes the gate and is not quarantined. It lands in `stg_billing` and its revenue
shows up in `agg_user_revenue`. At the warehouse, the LEFT JOIN anchors on
`stg_customers`, which has no row for this customer, so they never appear in
`dw_user_analytics` and their revenue silently disappears. That is a revenue leak,
not acceptable. Fix it two ways: add a Stage 1 referential check that flags billing
`customer_id`s missing from customers, and build the warehouse spine from the union
of all customer IDs seen across customers, billing and sessions, so orphans still
appear with name and country defaulted to Unknown and their revenue is never dropped.

**7. Churn rule flags new customers.** The rule, fewer than 5 sessions and under
₦1,000 revenue, trivially catches anyone who just registered. The data to fix it is
already in the warehouse: `customer_since`. Add a tenure condition so the flag only
applies to accounts older than a threshold:

    SELECT customer_id
    FROM dw_user_analytics
    WHERE total_sessions < 5
      AND total_revenue < 1000
      AND customer_since < CURRENT_DATE - INTERVAL '30 days';