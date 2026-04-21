# Dry Run

**A local companion for your Databricks projects.** Iterate on jobs,
notebooks, and SQL on your laptop in under a second — then ship to your
real [Databricks](https://www.databricks.com/) workspace with confidence.

Dry Run is not a replacement for Databricks. Databricks is where your
production data, real compute, and team collaboration live — that's not
changing. Dry Run is the **inner dev loop**: the place you try things,
debug typos, and write tests before pushing to a cluster. Think of it like
the "preview" build for your data pipelines.

This guide assumes you know nothing. If you can open a terminal and type,
you can use it.

---

## Table of contents

1. [What is Dry Run, in plain English](#1-what-is-dry-run-in-plain-english)
2. [Who is this for?](#2-who-is-this-for)
3. [Things you need installed first](#3-things-you-need-installed-first)
4. [Install Dry Run (3 ways)](#4-install-dry-run-3-ways)
5. [Your first 2 minutes — try the included example](#5-your-first-2-minutes--try-the-included-example)
6. [Use Dry Run on your own Databricks project](#6-use-dry-run-on-your-own-databricks-project)
7. [How the pieces fit together](#7-how-the-pieces-fit-together)
8. [`databricks.yml` — what Dry Run reads from it](#8-databricksyml--what-dry-run-reads-from-it)
9. [Getting data in: `dryrun hydrate`](#9-getting-data-in-dryrun-hydrate)
10. [Running a job: `dryrun run`](#10-running-a-job-dryrun-run)
11. [Passing parameters to jobs](#11-passing-parameters-to-jobs)
12. [The dashboard — tab by tab](#12-the-dashboard--tab-by-tab)
13. [The SQL Workbench](#13-the-sql-workbench)
14. [Writing tests with pytest](#14-writing-tests-with-pytest)
15. [Exporting a table: `dryrun export`](#15-exporting-a-table-dryrun-export)
16. [Comparing two runs: `dryrun diff`](#16-comparing-two-runs-dryrun-diff)
17. [Tracking how much money you saved: `dryrun savings`](#17-tracking-how-much-money-you-saved-dryrun-savings)
18. [Pointing the real Databricks CLI at Dry Run](#18-pointing-the-real-databricks-cli-at-dry-run)
19. [Running notebooks (`.ipynb`)](#19-running-notebooks-ipynb)
20. [The full CLI reference](#20-the-full-cli-reference)
21. [Troubleshooting — common errors](#21-troubleshooting--common-errors)
21a. [How Dry Run fits into your Databricks workflow](#21a-how-dry-run-fits-into-your-databricks-workflow)
21b. [How Dry Run works under the hood](#21b-how-dry-run-works-under-the-hood)
22. [What Dry Run **does** support today](#22-what-dry-run-does-support-today)
23. [What Dry Run **does not** support yet](#23-what-dry-run-does-not-support-yet)
24. [Roadmap](#24-roadmap)
25. [FAQ](#25-faq)

---

## 1. What is Dry Run, in plain English

### First, what is Databricks?

[Databricks](https://www.databricks.com/) is a cloud platform where data
teams run huge data pipelines on fleets of servers ("clusters") powered by
[Apache Spark](https://spark.apache.org/). It's where your company's real
data lives and where production jobs actually run. Most Databricks work
happens through these building blocks:

- [**Clusters**](https://docs.databricks.com/en/compute/index.html) —
  groups of cloud VMs that execute your Spark code. They take 3–5 minutes
  to start and cost real money per second they're alive.
- [**Notebooks**](https://docs.databricks.com/en/notebooks/index.html) —
  interactive Jupyter-style documents where engineers write Python, SQL,
  and visualisations.
- [**Jobs**](https://docs.databricks.com/en/jobs/index.html) — scheduled
  or ad-hoc pipelines made up of one or more tasks (a Python file, a
  notebook, a SQL query).
- [**Unity Catalog**](https://docs.databricks.com/en/data-governance/unity-catalog/index.html)
  — Databricks' governance layer. Every table has a three-part name:
  `catalog.schema.table`.
- [**Databricks Asset Bundles
  (DABs)**](https://docs.databricks.com/en/dev-tools/bundles/index.html)
  — the "infrastructure as code" format. A file called `databricks.yml`
  in your project root describes your jobs, tasks, and environments.

### Where Dry Run fits in

When you're developing — fixing a typo, tweaking a filter, testing a new
aggregation — every iteration against a real cluster takes 3–5 minutes and
costs money. That's the slow part of the day, and it's what Dry Run makes
fast.

Dry Run is a tool you install on your laptop. It reads the same
`databricks.yml`, runs the same Python and SQL tasks, writes to the same
three-part-named tables — but locally, in under a second, for free. When
your change works on Dry Run, you push to Databricks and deploy with
confidence.

Under the hood Dry Run uses two very fast libraries — [**Polars**](https://pola.rs/)
(for Python DataFrames) and [**DuckDB**](https://duckdb.org/) (for SQL and
Unity-Catalog-style table storage). It translates Spark SQL into DuckDB
SQL automatically via [**sqlglot**](https://github.com/tobymao/sqlglot),
so queries like `SELECT ... FROM catalog.schema.table` just work.

**You don't have to change a single line of your existing code.** That's
the whole point. The same job file that runs on Databricks runs on Dry
Run — because `spark`, `dbutils`, and `F` are provided by Dry Run with
the same API surface as the real thing.

### The "inner loop" vs "outer loop" mental model

| Phase | Where it happens | Why |
|---|---|---|
| **Inner loop** — write code, try it, fix bugs, run tests | Dry Run on your laptop | Fast, free, offline-friendly, no cluster wait |
| **Outer loop** — real data, prod pipelines, scheduling, collaboration | Real Databricks | Full scale, governance, team access, Delta, DLT, Workflows |

Great inner loops make great outer loops. That's what Dry Run is for.

---

## 2. Who is this for?

- **Databricks engineers** who want a faster inner dev loop before
  pushing to a shared cluster
- **Students & learners** exploring Spark / Databricks concepts without
  needing a cloud account yet
- **Data teams** doing PR reviews — run the change locally first, see the
  diff, then merge
- **Test authors** — pytest + Dry Run gives you real unit tests for
  Spark SQL and PySpark code without needing a JVM

You don't need to be a pro developer. If you know your way around a Python
file and a YAML config, you're good.

### Quick Databricks vocabulary (skip if you already know)

If any of these words feel unfamiliar, keep this table handy — the rest of
the guide uses them a lot.

| Term | What it means (simplified) |
|---|---|
| **Spark** | The distributed data-processing engine Databricks is built on. Works with Python, SQL, Scala |
| **PySpark** | The Python library to write Spark code |
| **SparkSession** | The object named `spark` in your code. Entry point to everything |
| **DataFrame** | A table-shaped object. The main thing you manipulate |
| [**Bundle (DAB)**](https://docs.databricks.com/en/dev-tools/bundles/index.html) | A Databricks project folder containing `databricks.yml` + code |
| [**`databricks.yml`**](https://docs.databricks.com/en/dev-tools/bundles/settings.html) | The YAML file that declares your bundle's jobs, variables, and environments |
| [**Target**](https://docs.databricks.com/en/dev-tools/bundles/settings.html#targets) | An environment declared in `databricks.yml` — e.g. `local`, `dev`, `prod` |
| [**Task**](https://docs.databricks.com/en/jobs/create-run-jobs.html#task) | One unit of work inside a job: a Python file, SQL query, or notebook |
| [**Unity Catalog**](https://docs.databricks.com/en/data-governance/unity-catalog/index.html) | Databricks' table registry. Tables have three-part names: `catalog.schema.table` |
| [**DBU**](https://www.databricks.com/product/pricing) | The unit Databricks bills in. Roughly "how much cluster-second you used" |
| [**dbutils**](https://docs.databricks.com/en/dev-tools/databricks-utils.html) | Databricks' built-in helper object — file operations, widgets, secrets |
| [**widgets**](https://docs.databricks.com/en/notebooks/widgets.html) | How jobs/notebooks read parameters. `dbutils.widgets.get("date")` |

---

## 3. Things you need installed first

You need Docker and nothing else:

- Docker Desktop — https://www.docker.com/products/docker-desktop
- Or a lightweight alternative like [Colima](https://github.com/abiosoft/colima) or [Rancher Desktop](https://rancherdesktop.io/) — anything that provides the `docker` CLI will work.
- Dry Run ships as a multi-arch image (`linux/amd64` + `linux/arm64`), so Apple Silicon Macs, Intel Macs, Windows, and Linux all work natively.

No Python install, no Java, no virtualenv management. Everything runs
inside the container.

---

## 4. Install Dry Run (2 ways)

### Way 1 — one-line Docker install (easiest)

```bash
curl -fsSL https://raw.githubusercontent.com/bhanotblocker/dryrun/main/install.sh | sh
```

What this does: pulls the Docker image and drops a little wrapper script at
`/usr/local/bin/dryrun` so you can type `dryrun` anywhere on your laptop
and it runs the containerised tool against whatever folder you're in.

After it finishes, test it:

```bash
dryrun --help
```

You should see the list of commands.

### Way 2 — pull the Docker image directly

If you'd rather not run the installer script, the image is on Docker Hub:

```bash
docker pull varundagger/dryrun:latest
docker run --rm -it \
  -p 8000:8000 \
  -v "$(pwd):/workspace" \
  -e DRYRUN_ROOT=/workspace \
  varundagger/dryrun:latest up --host 0.0.0.0 --foreground
```

Run this from inside your Databricks project folder; it mounts your
project as the workspace, starts the dashboard on `http://localhost:8000`,
and exits cleanly on Ctrl-C.

For one-shot commands (run, hydrate, sql, etc.) drop the `-p` and
`-it` flags:

```bash
docker run --rm \
  -v "$(pwd):/workspace" \
  -e DRYRUN_ROOT=/workspace \
  varundagger/dryrun:latest run ingest_job
```

Multi-arch images are published for both `linux/amd64` and
`linux/arm64`, so Docker automatically pulls the right variant for
your machine.

---

## 5. Your first 2 minutes — try the included example

We ship a tiny **retail** project that mimics a typical bronze → silver →
gold data pipeline on Databricks. Let's run it end-to-end.

```bash
dryrun init --example retail   # copies the retail sample into your CWD
cd retail                      # (or whatever folder it was copied into)
dryrun status                  # sanity check — should list 3 jobs
dryrun hydrate                 # pulls sample data into .dryrun/storage/
dryrun run ingest_job          # bronze layer
dryrun run transform_job       # silver + gold
dryrun up                   # open http://localhost:8000 in your browser
```

That's it. You just ran a 3-stage Databricks-style pipeline — bronze →
silver → gold — on your laptop. When it looks right here, push the same
code to your real Databricks workspace with `databricks bundle deploy`
and run it at full scale.

What you should see in the terminal after `dryrun run ingest_job`:

```
╭──────────────────────────────────────╮
│ ▶ Dry Run  LocalStack for Databricks │
╰──────────────────────────────────────╯
▶ running ingest_job...

┏━━━━━━━━━━━━━┳━━━━━━━━━━━┳━━━━━━━┳━━━━━━━┳━━━━━━━┳━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━┓
┃ task        ┃ status    ┃  time ┃ +rows ┃ -rows ┃ would-have-cost ┃ tables       ┃
┡━━━━━━━━━━━━━╇━━━━━━━━━━━╇━━━━━━━╇━━━━━━━╇━━━━━━━╇━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━┩
│ ingest_sal… │ ✓ success │ 0.38s │    18 │     0 │           $0.05 │ retail.bron… │
│ ingest_cus… │ ✓ success │ 0.06s │     9 │     0 │           $0.05 │ retail.bron… │
└─────────────┴───────────┴───────┴───────┴───────┴─────────────────┴──────────────┘

╭───────────────── Dry Run vs Databricks ──────────────────╮
│ $0.10 saved on this run  ·  $0.10 saved total  ·  2 runs │
╰──────────────────────────────────────────────────────────╯
```

Each row is a task. `+rows` is how many rows the task wrote. `would-have-cost` is
the estimated Databricks bill you dodged.

---

## 6. Use Dry Run on your own Databricks project

This is the main use case. You already have a Databricks project folder on
your laptop. It looks something like:

```
my-company-pipeline/
├── databricks.yml       ← the bundle config you already have
├── jobs/
│   ├── ingest.py
│   ├── transform.sql
│   └── report.py
└── notebooks/
    └── exploration.ipynb
```

You don't have to move anything. Just:

```bash
cd my-company-pipeline
dryrun hydrate             # see section 9 — pulls sample data
dryrun run ingest          # replace 'ingest' with your job's name
dryrun up                  # dashboard on http://localhost:8000
```

**No code changes required.** The `spark`, `dbutils`, and `F` variables
inside your jobs are provided by Dry Run automatically, so your existing
`.py` and `.sql` files run as-is.

If you don't have a project yet, run `dryrun init my_project` to scaffold
one.

---

## 7. How the pieces fit together

Here's every file Dry Run creates or reads:

```
your-project/
├── databricks.yml         ← YOU write this (or it already exists)
├── jobs/                  ← YOU write your Python / SQL / notebook tasks
├── data/                  ← optional: drop local CSVs here as fixtures
│
└── .dryrun/               ← created automatically, gitignore this
    ├── catalog.duckdb     ← Unity Catalog — ALL your tables live here
    ├── storage/           ← hydrated sample files (like a local S3)
    ├── runs/              ← one JSON file per run with the diff + stdout
    ├── logs/              ← dashboard server logs
    ├── savings.json       ← cumulative cost savings counter
    └── dryrun.pid         ← pid of the running dashboard (if any)
```

When you run a job:
- Dry Run parses `databricks.yml` to find the job
- It runs each task through its fake `SparkSession` (powered by Polars +
  DuckDB)
- Any `.saveAsTable("retail.bronze.sales")` or `CREATE TABLE
  retail.silver.orders` writes go into `.dryrun/catalog.duckdb`
- Row-level diffs (added / removed / changed) are recorded in `.dryrun/runs/`
- The dashboard reads from these files to show you what happened

> Tip: add `.dryrun/` to your `.gitignore`. You never want to commit it.

---

## 8. `databricks.yml` — what Dry Run reads from it

### What is this file?

`databricks.yml` is the config file at the root of a
[Databricks Asset Bundle](https://docs.databricks.com/en/dev-tools/bundles/index.html).
It's how you describe your project to Databricks without clicking around in
the UI — what jobs exist, what code they run, what environment variables
they need, and which target (dev, staging, prod) to deploy to.

Think of it as:

- `package.json` is to a Node project what `databricks.yml` is to a
  Databricks project
- `docker-compose.yml` is to containers what `databricks.yml` is to data
  pipelines

Databricks' own tooling reads this file when you run `databricks bundle
deploy` or `databricks bundle run`. **Dry Run reads the same file.**
That's why you don't need a separate config for local dev — your existing
bundle just works.

[Full official reference →](https://docs.databricks.com/en/dev-tools/bundles/settings.html)

### A typical `databricks.yml`

Here's a complete example with comments:

```yaml
# The name of your bundle. Shows up in the Databricks UI too.
bundle:
  name: retail

# Variables you can reference elsewhere as ${var.catalog} etc.
# Users can also override them at run time: dryrun run <job> -p catalog=foo
variables:
  catalog: {default: retail}
  schema:  {default: bronze}

# Targets = environments. Databricks uses "dev" / "staging" / "prod".
# Dry Run adds "local" (and uses it as default).
targets:
  local:
    default: true
    variables:
      catalog: retail
      schema:  bronze
  dev:
    variables:
      catalog: retail_dev
      schema:  bronze

# Dry-Run-specific extension: list data URIs so `dryrun hydrate` knows what
# to pull samples of. Optional — Dry Run also auto-discovers URIs from code.
data_sources:
  - s3://retail-raw/sales.csv
  - s3://retail-raw/customers.csv

# The jobs your bundle defines. Each job has one or more tasks.
resources:
  jobs:
    ingest_job:                         # ← this is what you pass to `dryrun run`
      name: ingest_job
      tasks:
        - task_key: ingest_sales        # ← shows up as a row in the run table
          file: jobs/ingest_sales.py
        - task_key: ingest_customers
          file: jobs/ingest_customers.py
```

Dry Run cares about:

| Key | What Dry Run does with it |
|---|---|
| `bundle.name` | Defaults as the catalog name if `variables.catalog` isn't set |
| `variables` | Available as `dbutils.widgets.get("catalog")` in your code |
| `targets.<target>.variables` | Overrides. Pick target with `dryrun run <job> --target dev` |
| `data_sources` | Paths `dryrun hydrate` pulls samples from |
| `resources.jobs.<name>.tasks` | The tasks that run when you `dryrun run <name>` |
| `tasks[].file` | Supports `.py`, `.sql`, `.ipynb` |

You can also use the real Databricks task shapes (`notebook_task`,
`spark_python_task`, `python_wheel_task`, `sql_task`) — Dry Run understands
all of them.

---

## 9. Getting data in: `dryrun hydrate`

Your Databricks job probably reads data like this:

```python
df = spark.read.csv("s3://retail-raw/sales.csv")
```

On your laptop, there's no S3. `dryrun hydrate` solves this in two ways
depending on what you have access to.

### Path A — you have cloud credentials

The Docker image already bundles the S3/ADLS/GCS SDKs. All you need to do
is expose your cloud credentials to the container (Dry Run's install
script forwards `AWS_*`, `AZURE_*`, and `GOOGLE_*` env vars from your
shell):

```bash
aws configure                   # whatever credentials your company uses
dryrun hydrate
```

Dry Run scans `databricks.yml` and every `.py` / `.sql` / `.ipynb` file for
`s3://` / `abfss://` / `gs://` / `dbfs:/` URIs and pulls the **first 10,000
rows** of each file into `.dryrun/storage/`. You only pay for a tiny
sample, not the whole dataset.

### Path B — you DON'T have cloud credentials

Drop local files into a `data/` folder in your project, with filenames
matching the URIs:

```
my-project/
├── databricks.yml             ← references s3://retail-raw/sales.csv
└── data/
    ├── sales.csv              ← Dry Run picks this up automatically
    └── customers.csv
```

Then:

```bash
dryrun hydrate
```

Dry Run finds the matching basename in `data/` and uses that as the "cloud"
copy. Your code still reads `s3://retail-raw/sales.csv` — Dry Run quietly
redirects.

### Path C — you don't care, just let me run something

If neither A nor B applies, Dry Run generates a **synthetic 10-row
placeholder** so your pipeline doesn't crash. This is great for trying the
tool out on a stranger's project.

### Changing the sample size

```bash
dryrun hydrate --sample 100000   # pull 100k rows instead of 10k
```

---

## 10. Running a job: `dryrun run`

Basic form:

```bash
dryrun run <job_name>
```

What happens:

1. Dry Run parses `databricks.yml` to find the job
2. Runs each task in order
3. Prints a table of results with row counts, timing, and estimated cost
4. Stores the run JSON at `.dryrun/runs/<run_id>.json`
5. Updates the live dashboard if it's running

### Useful flags

```bash
dryrun run ingest_job --target dev
#  use the `dev` target from databricks.yml instead of `local`

dryrun run ingest_job --profile premium
#  use the 'i3.xlarge Premium' rate when estimating cost savings
#  options: standard | premium | all_purpose | sql_warehouse

dryrun run ingest_job -p date=2025-04-20 -p env=dev
#  pass parameters — see next section
```

### What counts as "success" vs "failure"

- **success** means every task's Python / SQL / notebook code executed
  without throwing an exception
- **failure** means something blew up. The red panel at the bottom of the
  output contains the full traceback. Fix the bug and re-run — no cluster
  restart needed.

---

## 11. Passing parameters to jobs

Same contract as the real Databricks CLI: `-p key=value`, repeatable.

```bash
dryrun run ingest_job -p date=2025-04-20 -p env=dev
```

Inside your Python task:

```python
target_date = dbutils.widgets.get("date")       # "2025-04-20"
env         = dbutils.widgets.get("env")        # "dev"

# OR via environment variables — both work:
import os
env = os.environ["env"]
```

Inside your SQL task — values declared in `databricks.yml`'s `variables:`
block are already substituted when the file is parsed:

```sql
CREATE OR REPLACE TABLE ${var.catalog}.silver.sales_enriched AS
SELECT * FROM ${var.catalog}.bronze.sales
WHERE order_date = '${var.date}';
```

### Precedence (who wins if two places define the same key)

1. Command-line `-p k=v` (highest)
2. Per-task `parameters:` in `databricks.yml`
3. Per-target `variables:` in `databricks.yml`
4. Top-level `variables:` defaults (lowest)

### Running without any parameters

Totally fine. The defaults from `databricks.yml` are used. Both of these
work:

```bash
dryrun run ingest_job                     # use all defaults
dryrun run ingest_job -p date=2025-04-20  # override just `date`
```

---

## 12. The dashboard — tab by tab

Start it:

```bash
dryrun up
```

Then open **http://localhost:8000** in your browser. The dashboard is a
single-page app — it auto-refreshes every 4 seconds while you're working.

The **header** shows:
- Bundle name and target
- A live yellow **$ saved · N runs** counter (cumulative savings)
- Your project's root path

### The four tabs

#### (a) Catalog

Left column = a tree: **Catalog → Schema → Table**. Exactly what Unity
Catalog looks like on Databricks. Click any table to see a preview of its
data on the right, with:
- Row count + column count + last-updated timestamp
- The first 100 rows with types shown next to each column name
- A link "open in SQL workbench" to run a bigger query

If the tree is empty, you just haven't run any jobs yet that write tables.

#### (b) Jobs

Lists every job from `databricks.yml`. Each job shows its tasks with their
kind (`python`, `sql`, `notebook`). Click the green **▶ Run** button to
execute the job right from the browser — no terminal needed.

When the run finishes, you get auto-taken to the Runs tab with the latest
run selected.

#### (c) Runs

Left column = recent runs, newest first. Each one shows:
- Green/red dot for success/failure
- Job name · task name
- When it started
- Duration
- `+rows / -rows` summary

Click any run to open the right-hand panel with:
- Status + duration + **cost savings for this run**
- Full stdout (collapsed by default — click "stdout" to expand)
- The error traceback in red (if it failed)
- **Per-table diff cards** — one for every table the task wrote, showing
  before/after row counts, +rows / -rows / ~changed chips, plus a sample
  of the actual rows added / removed / changed. This is the "killer
  feature" — you can see the exact 2 rows your new filter removed.

#### (d) SQL Workbench

See next section.

---

## 13. The SQL Workbench

Top tab of the dashboard. A text box where you write Spark SQL and a **▶
Run** button. Results appear below in under a second.

Things that work:
- Three-part names: `SELECT * FROM retail.bronze.sales`
- Full joins, subqueries, window functions, CTEs
- Common Spark SQL functions (`SUM`, `COUNT`, `TO_DATE`, `DATE_TRUNC`, …)
- DDL: `CREATE TABLE … AS SELECT`, `INSERT INTO`
- Databricks extras are auto-stripped: `USING DELTA`, `PARTITIONED BY
  (col)`, `TBLPROPERTIES (…)`, `LOCATION '…'`, `OPTIMIZE`, `VACUUM`

You can also run SQL from the command line:

```bash
dryrun sql "SELECT country, SUM(revenue) FROM retail.gold.country_daily GROUP BY country"
```

---

## 14. Writing tests with pytest

Dry Run ships a pytest plugin that exposes fixtures like `dryrun_spark`
and `dryrun_executor`. Since **0.2.0**, you don't need to install pytest
or Dry Run on your host — everything runs inside the same Docker image
that already powers `dryrun run`. Just use the `dryrun pytest`
subcommand.

### Step 1 — make a `tests/` folder in your project

```
my-project/
├── databricks.yml
├── jobs/
└── tests/
    └── test_silver.py
```

### Step 2 — write a test

```python
# tests/test_silver.py

def test_gold_revenue_is_positive(dryrun_spark, dryrun_executor):
    dryrun_executor.run_job("ingest_job")
    dryrun_executor.run_job("transform_job")

    total = dryrun_spark.sql(
        "SELECT SUM(revenue) AS total FROM retail.gold.country_daily"
    ).collect()[0]["total"]
    assert total > 0
```

### Step 3 — run it

```bash
dryrun pytest -v
```

That's it. No Spark JVM, no cluster — pytest just runs inside the
container, with every Dry Run fixture pre-registered. Extra arguments
forward straight through to pytest (`-k`, `--maxfail`, `-x`, …).

> If you already have pytest installed on your host and prefer your
> own venv, running `pytest -v` still works the same way — you just
> need `pip install dryrun` locally so the plugin is discoverable.
> The `dryrun pytest` path exists so Docker-only users don't have to
> touch a venv at all.

### What fixtures are available

| Fixture | What it gives you |
|---|---|
| `dryrun_workspace` | An **isolated, temporary copy** of your bundle (includes `data/`, `jobs/`, `databricks.yml`). Tests can't pollute your real `.dryrun/`. |
| `dryrun_bundle` | The parsed `Bundle` object for that temp workspace |
| `dryrun_catalog` | A fresh DuckDB-backed Unity Catalog for the test |
| `dryrun_spark` | A ready-to-use `SparkShim` (acts like `SparkSession`) |
| `dryrun_executor` | Runs full jobs end-to-end. Auto-hydrates data sources. |

Each test gets its own tmpdir. No cross-test pollution.

### Helper assertions

```python
from dryrun.pytest_plugin import assert_row_count, assert_columns

def test_bronze_schema(dryrun_spark, dryrun_executor):
    dryrun_executor.run_job("ingest_job")
    assert_row_count(dryrun_spark, "retail.bronze.sales", 18)
    assert_columns(dryrun_spark, "retail.bronze.sales",
                   ["order_id", "customer_id", "qty",
                    "unit_price", "revenue", "order_ts"])
```

### Example: data quality tests

```python
def test_no_negative_revenue(dryrun_spark, dryrun_executor):
    dryrun_executor.run_job("ingest_job")
    bad = dryrun_spark.sql(
        "SELECT COUNT(*) AS n FROM retail.bronze.sales WHERE revenue < 0"
    ).collect()[0]["n"]
    assert bad == 0, f"{bad} rows have negative revenue"


def test_every_order_has_a_customer(dryrun_spark, dryrun_executor):
    dryrun_executor.run_job("ingest_job")
    dryrun_executor.run_job("transform_job")
    orphans = dryrun_spark.sql("""
        SELECT COUNT(*) AS n
        FROM retail.silver.sales_enriched
        WHERE customer_name IS NULL
    """).collect()[0]["n"]
    assert orphans == 0
```

These tests will run in under a second. Run them in GitHub Actions on every
PR and you've got a real data quality gate.

---

## 15. Exporting a table: `dryrun export`

Say you just ran a job and want to share the result with someone who
doesn't have Dry Run.

```bash
dryrun export retail.gold.country_daily /tmp/gold.csv
# ✓ wrote 15 rows → /tmp/gold.csv
```

Supported formats: `.csv`, `.parquet`, `.json`, `.ndjson` / `.jsonl`.

Useful for:
- Attaching to a Slack thread / PR comment
- Feeding into Excel or a BI tool for a quick sanity check
- Sharing a reproducible fixture with a colleague

---

## 16. Comparing two runs: `dryrun diff`

After you've made a change to your code, you probably want to know: *did
the output actually change, and how?* Every run stores its snapshot in
`.dryrun/runs/<run_id>.json`. Compare any two:

```bash
# list run IDs
ls .dryrun/runs/

# compare
dryrun diff 0ce0ef613b5a 2c2484d879cc
```

Output:

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━┳━━━━━━━━━━━━┳━━━━━━━━┓
┃ table                     ┃ run 0ce0ef ┃ run 2c2484 ┃ Δ rows ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━╇━━━━━━━━━━━━╇━━━━━━━━┩
│ retail.bronze.sales       │          0 │         18 │    +18 │
│ retail.gold.country_daily │         15 │          0 │    -15 │
└───────────────────────────┴────────────┴────────────┴────────┘
```

For the per-row diff (which specific rows were added or removed), open the
run in the dashboard — the diff cards show sample rows.

---

## 17. See how much cluster time you avoided: `dryrun savings`

Every time you iterate locally, you're skipping a cluster spin-up you
would have otherwise paid for. Dry Run estimates that dodged cost and
keeps a running total in `.dryrun/savings.json` — handy for justifying
the tool to your manager, or just for fun. (It's not an invoice from
Databricks — see caveats below.)

```bash
dryrun savings
```

```
  total saved      $12.47
  total runs       156
  total compute    312.0s

by cluster profile
  standard       Jobs Compute · Standard_DS3_v2           $9.20
  premium        Jobs Compute · i3.xlarge (Premium)       $3.27
```

**Caveats** — this is a rough estimate for storytelling, not an invoice:
- Assumes single-node jobs compute (most dev workloads)
- Uses conservative public pricing (us-east-1)
- Adds a 3-minute cold-start penalty per task (VMs take time to come up)
- Rounds to 30-second billing granularity (VMs don't bill per millisecond)

If your team runs 40-worker clusters, the real savings are **much higher**
than what Dry Run reports.

### Picking a cluster profile for realistic numbers

```bash
dryrun run ingest_job --profile standard        # $0.80/hr  (default)
dryrun run ingest_job --profile premium         # $1.30/hr
dryrun run ingest_job --profile all_purpose     # $2.20/hr
dryrun run ingest_job --profile sql_warehouse   # $1.10/hr
```

Or set globally:

```bash
export DRYRUN_CLUSTER_PROFILE=premium
```

---

## 18. Pointing the real Databricks CLI at Dry Run

If your team already uses the official [`databricks` CLI](https://docs.databricks.com/en/dev-tools/cli/index.html),
you don't even need to learn `dryrun run`. Start the Dry Run server and
point the CLI at it — your existing `databricks bundle run` commands keep
working, they just execute locally:

```bash
dryrun up                                          # starts on localhost:8000

export DATABRICKS_HOST=http://localhost:8000
export DATABRICKS_TOKEN=dryrun-local
databricks bundle run ingest_job -t local
```

The real Databricks CLI thinks it's talking to your cloud workspace. Dry
Run intercepts the HTTP calls and runs the job on your laptop. Most common
endpoints are mocked:

- `POST /api/2.1/jobs/runs/submit`
- `GET  /api/2.1/jobs/list`
- `POST /api/2.0/sql/statements`
- `GET  /api/2.1/unity-catalog/*`
- `GET  /api/2.0/clusters/list`

Anything unmocked returns a friendly 501 telling you what's missing — no
silent wrong results.

---

## 19. Running notebooks (`.ipynb`)

[Databricks notebooks](https://docs.databricks.com/en/notebooks/index.html)
are the interactive Python-and-SQL documents most data engineers live in.
Dry Run runs them too.

In `databricks.yml`:

```yaml
resources:
  jobs:
    notebook_job:
      tasks:
        - task_key: exploration
          file: notebooks/exploration.ipynb
```

Then:

```bash
dryrun run notebook_job
```

### Cross-cell state — yes, it works like Jupyter / Databricks

This is the question most people ask first, so explicitly: **variables,
imports, and DataFrames defined in one cell are available in every
subsequent cell**, exactly like a real notebook. Dry Run executes every
code cell into a single shared Python namespace.

```python
# Cell 1
customers = spark.table("retail.bronze.customers")
threshold = 100

# Cell 2 — customers and threshold are still available
big_spenders = customers.filter(F.col("total_spent") > threshold)
big_spenders.show()

# Cell 3 — big_spenders is still available
big_spenders.write.mode("overwrite").saveAsTable("retail.gold.vip")
```

Cells always run **top-to-bottom** when executed via `dryrun run` — the
same as running a Databricks notebook as a job. (Dry Run does not yet
support the interactive "run this cell out of order" workflow you get in
Jupyter / the Databricks notebook UI. For interactive exploration, use
the SQL Workbench in the Dry Run dashboard or fall back to plain Jupyter
for now.)

### What you can write in cells

- **Regular Python cells** — `spark`, `dbutils`, `F` are pre-injected. You
  don't need to `from pyspark.sql import ...`.
- **`%sql` magic cells** — translated via sqlglot to DuckDB. Databricks
  notebooks write these as `# MAGIC %sql` at the top of a cell — Dry Run
  handles that form too.
- **`%python` magic cells** — run as Python.
- **`%md` markdown cells** — displayed in Jupyter, skipped during
  execution (same as Databricks).

### What is NOT yet supported in notebooks

- `display(df)` — Databricks' rich table widget. Use `df.show()` instead,
  or open the table in the dashboard
- Auto-generated charts from `display()`
- `%run ./other_notebook` — running another notebook as a cell. On the
  roadmap
- Re-running individual cells out of order (see above)

---

## 20. The full CLI reference

| Command | What it does |
|---|---|
| `dryrun --help` | List every command |
| `dryrun --version` | Print the installed Dry Run version |
| `dryrun init <name>` | Scaffold `databricks.yml` + a sample job |
| `dryrun init --example retail` | Copy the bundled retail sample project |
| `dryrun status` | Show bundle name, jobs, and whether the server is running |
| `dryrun validate` | Static lint of `databricks.yml` — catches missing files, duplicate task keys, undeclared vars |
| `dryrun doctor` | Health check: version, deps, catalog, port 8000, and common gotchas |
| `dryrun hydrate` | Pull sample data from cloud/local fixtures into `.dryrun/storage/` |
| `dryrun hydrate --sample 50000` | Pull 50k rows per source instead of the default 10k |
| `dryrun run <job>` | Run a job from `databricks.yml` |
| `dryrun run <job> --target dev` | Use the `dev` target variables |
| `dryrun run <job> -p k=v -p k2=v2` | Pass parameters to the job |
| `dryrun run <job> --profile premium` | Use a different cluster profile for cost calc |
| `dryrun up` | Start the dashboard on http://localhost:8000 |
| `dryrun up --port 9000` | Use a different port |
| `dryrun up -f` | Run in the foreground (Ctrl-C to stop) |
| `dryrun down` | Stop the dashboard |
| `dryrun sql "SELECT …"` | Run a one-off SQL query |
| `dryrun pytest` | Run pytest against your `tests/` folder with fixtures pre-wired |
| `dryrun pytest -v -k silver` | Pass any extra args straight through to pytest |
| `dryrun export <cat.sch.tbl> <file>` | Export a table to .csv / .parquet / .json |
| `dryrun export <tbl> <file> --limit 1000` | Export only the first 1000 rows |
| `dryrun diff <run_id_a> <run_id_b>` | Compare the tables written by two runs |
| `dryrun savings` | Show cumulative $ saved + breakdown by profile |

---

## 21. Troubleshooting — common errors

### "Job 'foo' not found"
You misspelled the job name, or your `databricks.yml` didn't get picked up.
Run `dryrun status` — the `jobs` row should list every job Dry Run can see.
If it's empty, you're probably running from the wrong folder. Dry Run walks
upward from your current directory looking for the nearest `databricks.yml`.

### "Table with name X does not exist"
You asked for a table that hasn't been written yet. Run the job that
produces it first. For example, before querying `retail.silver.*`, run
`dryrun run transform_job`.

### "could not find an appropriate format to parse dates"
One of your `F.to_date(...)` calls hit a non-standard date string. Dry Run
tries ISO, slash-separated, and US-style formats automatically. If your
dates are in a weird format, pass it explicitly:

```python
F.to_date("order_date", "dd/MM/yyyy HH:mm")
```

### "Schema with name X does not exist" during CREATE TABLE
This should auto-resolve in recent versions of Dry Run. If you still hit
it, run:

```bash
dryrun sql "CREATE SCHEMA IF NOT EXISTS your_catalog__your_schema"
```

### "ModuleNotFoundError: No module named 'pyspark'"
Your job does something like `from pyspark.sql import SparkSession`. Dry
Run doesn't require PySpark — the `spark` variable is already injected
globally. Just remove the import, or guard it:

```python
try:
    from pyspark.sql import SparkSession
except ImportError:
    pass  # running under Dry Run
```

### "File not found" when reading `s3://...`
You didn't hydrate. Run `dryrun hydrate`. If you don't have cloud
credentials, drop a matching file into `./data/` and re-run hydrate.

### Dashboard shows no jobs / no tables
- Restart with `dryrun down && dryrun up`
- Make sure you're in the folder with `databricks.yml`
- Check `.dryrun/logs/server.log` for errors

### Port 8000 already in use
```bash
dryrun up --port 9000
```

### "databricks CLI gives 501 Not Implemented"
Some Databricks API endpoints are mocked, some aren't yet. The error
message tells you which endpoint. Open an issue with the endpoint name and
we'll prioritise it.

---

## 21a. How Dry Run fits into your Databricks workflow

Dry Run lives alongside your existing tools. Nothing about your Databricks
workspace, cluster configuration, or deployment process changes. Here's a
typical day:

```
┌───────────────────────────────────────────────────────────────────────┐
│  YOUR LAPTOP                                         DATABRICKS CLOUD │
│  (inner loop — fast)                                 (outer loop)     │
│                                                                       │
│   ┌─────────────────┐                                                 │
│   │  write code     │                                                 │
│   │  edit .py / .sql│                                                 │
│   └────────┬────────┘                                                 │
│            ▼                                                          │
│   ┌─────────────────┐                                                 │
│   │  dryrun run     │   ← 0.4 seconds, free, your data stays local   │
│   │  dryrun up      │                                                 │
│   │  pytest         │                                                 │
│   └────────┬────────┘                                                 │
│            ▼                                                          │
│   ┌─────────────────┐                                                 │
│   │  git commit     │                                                 │
│   │  git push       │                                                 │
│   └────────┬────────┘                                                 │
│            ▼                                                          │
│   ┌─────────────────┐    ┌──────────────────────────────────────┐    │
│   │ databricks      │──▶ │  real cluster runs real data         │    │
│   │ bundle deploy   │    │  prod job runs on schedule           │    │
│   │ -t prod         │    │  teammates see results in UC         │    │
│   └─────────────────┘    └──────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────────────┘
```

A few things to keep in mind:

- **Dry Run never modifies your real Databricks workspace.** Nothing you
  do locally touches production tables. Hydration pulls *samples* only.
- **Databricks is still the source of truth.** Your real Delta tables,
  Unity Catalog permissions, DLT pipelines, and Workflows all live there.
- **Dry Run is intentionally smaller-scope than Databricks.** It handles
  the "write code and see if it works" loop. It's not trying to replicate
  everything Databricks offers — scheduling, governance, ML, DLT,
  streaming, dashboards. Those remain Databricks' job.
- **When your code works locally, push it.** Dry Run's goal is to make
  you more productive *inside* the Databricks ecosystem, not to pull you
  out of it.

---

## 21b. How Dry Run works under the hood

You don't need to read this section to use Dry Run. It's here because
people keep asking "how on earth did you fit Databricks into 50 MB and
make it start in under a second?" — and the honest answer is "by being
stubborn about what we refused to include."

### The one design choice that matters

Most tools that try to run Databricks locally start from the engine
side: they pick up PySpark, attempt to embed a JVM, and drown in
dependency hell before a single query executes.

Dry Run starts from the other end. **We implement the public API
surface, not the engine underneath it.** Your code talks to a
PySpark-shaped façade; behind that façade we're free to use whatever
actually runs fast on a laptop.

That single choice is why Dry Run is 50 MB instead of 2 GB, boots in
40 ms instead of 4 minutes, and runs anywhere Python runs — Mac,
Windows, Linux, GitHub Actions, an airplane.

### The stack

| Layer | Tool | Why it's there |
|---|---|---|
| SQL translation | [**sqlglot**](https://github.com/tobymao/sqlglot) | Parses Spark/Databricks SQL into a real AST. We rewrite the AST and emit DuckDB dialect. No regex soup, no string hacks. |
| SQL execution | [**DuckDB**](https://duckdb.org) | Columnar, vectorised OLAP engine that speaks ANSI SQL, runs in-process, and stores a whole warehouse in a single file. It *is* our local Unity Catalog. |
| DataFrame runtime | [**Polars**](https://pola.rs) | Rust-backed, columnar, lazy-evaluated. Roughly 10–30× faster than Pandas on the workloads Databricks jobs actually hit. |
| API façade | **Our own shim** | A hand-crafted PySpark-shaped layer over Polars + DuckDB. This is where most of the engineering time goes and where the least code is visible. |

None of these pieces are novel on their own. DuckDB is public, Polars
is public, sqlglot is public. The interesting part is how they're
glued together and, more importantly, which glue was thrown away
after it didn't hold.

### The translation pipeline

When your Python task calls `spark.sql("SELECT ... FROM retail.bronze.sales")`:

```
Your Spark SQL string
       │
       ▼
sqlglot parser  (Databricks dialect, Spark fallback)
       │
       ▼
AST rewrite pass:
  · three-part names  →  DuckDB-friendly namespacing
  · Delta-only keywords stripped without changing semantics
  · governance / maintenance statements become no-ops
  · implicit-type coercions normalised to ANSI
       │
       ▼
DuckDB-dialect SQL emission
       │
       ▼
Pre-flight: ensure schemas exist, register temp views, bind params
       │
       ▼
DuckDB executes against catalog.duckdb
       │
       ▼
Arrow zero-copy  →  Polars DataFrame  →  back to your code
```

The pipeline is what matters, not any one step. sqlglot could be
replaced with a different parser, DuckDB with a different engine, and
the shim wouldn't change. That decoupling is how we ship fixes in
hours instead of weeks.

### Unity Catalog, in one file

Databricks' Unity Catalog is a hierarchical namespace:
`catalog → schema → table`. We emulate it with a convention so
boring it's almost disappointing — one DuckDB schema per
`(catalog, schema)` pair, every table lives inside, metadata sits in
a private sidecar schema in the same file.

Which means:

- Your entire local warehouse is one `.dryrun/catalog.duckdb` file
- You can `duckdb .dryrun/catalog.duckdb` and poke around in raw SQL
  any time you want
- `rm .dryrun/catalog.duckdb` resets everything. No "clean
  environment" dance.
- Sharing a reproducible snapshot with a teammate is `cp`

It's not clever. It's just the kind of decision that stops being
available to you once you've shipped a filesystem-based storage
layout and have to keep backwards compatibility.

### Diffs as a first-class primitive

Every write into the catalog takes a snapshot of the *before* state.
After the write, the two snapshots are diffed row-by-row against a
heuristic primary key, producing three buckets: added, removed,
changed. Sample rows from each bucket land in the run JSON so the
dashboard can render them without re-running anything.

This is why every `dryrun run` can tell you "+18 rows, −2 rows" — not
because we logged deltas incrementally, but because we diffed the
actual data. It costs an extra scan per write. It's also the feature
we refused to compromise on.

### Parameters, variables, env, and secrets — one resolver

Databricks bundles have at least four ways a value can enter a job:
`databricks.yml` variables, target overrides, task parameters, and
environment. Real jobs combine all four. Getting precedence wrong
silently produces the wrong number in production.

Dry Run routes all four through a single resolver with explicit
precedence (CLI `--param` > task params > target overrides > bundle
variables > env > default). Whatever value the resolver picks is the
value your code sees, whether it asks via `dbutils.widgets.get(...)`,
`os.environ[...]`, or a bundle variable substitution in SQL. One
source of truth, no surprises.

### What's deliberately *not* in the box

Half the engineering is saying no. Some things Dry Run actively
refuses to do, because including them would either bloat the image
or lie to the user:

- **No JVM, no Spark, no Hadoop.** Not shipped, not shimmed, not
  optional. If your code genuinely needs Spark internals (RDDs, UDFs
  compiled from Scala, Spark Streaming), Dry Run isn't the tool.
- **No cluster emulation.** We don't pretend to start/stop clusters,
  don't model autoscaling, don't fake node failures. A task either
  runs or it doesn't.
- **No fake governance.** `GRANT`, `REVOKE`, row-level security, and
  column masks are no-ops locally. We say so in the output. We never
  pretend a permission was enforced.
- **No network calls to Databricks by default.** Dry Run never phones
  home, never validates your workspace credentials, never uploads
  telemetry. The only outbound calls are the cloud reads *you* ask
  `dryrun hydrate` to make.

Every one of those is a feature someone has asked for. Every one of
them stays off the list until we can do it honestly.

### Why this is harder than it looks

A weekend clone of this stack gets you to "runs a `SELECT` query."
The next six months of running it on real bundles is where the
actual work lives: the SQL forms sqlglot doesn't translate cleanly,
the PySpark API surface your coworkers rely on without knowing they
do, the places Databricks' type coercion disagrees with ANSI, the
interaction between bundle variables and target overrides and task
parameters, the notebook magics that look like comments on disk, the
cases where `df.filter("col > 0")` must be routed through DuckDB
while `df.filter(F.col("col") > 0)` should stay in Polars for speed.

None of those are hard problems *individually*. The hard thing is
knowing which ones exist. Dry Run's moat isn't any single piece of
tech — it's the catalogue of failure modes we've already walked into
so you don't have to.

---

## 22. What Dry Run **does** support today

This is the "it just works" list.

### Bundle / config
- `databricks.yml` parsing (bundle name, targets, variables, includes,
  per-target overrides)
- Databricks Asset Bundles (DABs) native task shapes: `notebook_task`,
  `spark_python_task`, `python_wheel_task`, `sql_task`
- Dry-Run-native shorthand: `{file: jobs/foo.py}` or `{sql: "SELECT ..."}`

### Spark / PySpark
- `spark.read.csv / .parquet / .json / .load / .table / .format(...).load`
- `spark.sql(...)` with automatic Spark-SQL → DuckDB translation
- `spark.table("cat.sch.tbl")`
- `spark.createDataFrame(...)`
- DataFrame ops: `filter`, `where`, `select`, `withColumn`, `drop`,
  `distinct`, `limit`, `orderBy`, `sort`, `join`, `groupBy`, `agg`,
  `union`, `unionByName`, `dropDuplicates`, `withColumnRenamed`
- DataFrame I/O: `df.write.mode(...).saveAsTable("cat.sch.tbl")`,
  `df.write.save(path)`, `df.createOrReplaceTempView(...)`
- `df.count / collect / toPandas / show / printSchema`
- `pyspark.sql.functions` subset: `col`, `lit`, `sum`, `avg`, `mean`,
  `min`, `max`, `count`, `countDistinct`, `upper`, `lower`, `length`,
  `trim`, `when`, `coalesce`, `concat`, `concat_ws`, `year`, `month`,
  `day`, `to_date`, `to_timestamp`, `expr`, `desc`
- `F.to_date` / `F.to_timestamp` auto-detect common date formats
- `Column` expressions (arithmetic, comparison, `isNull`, `isNotNull`,
  `isin`, `cast`, `alias`)

### SQL (via sqlglot → DuckDB)
- Three-part names: `SELECT * FROM catalog.schema.table`
- `CREATE OR REPLACE TABLE ... AS SELECT`
- `INSERT INTO`, `MERGE INTO` (DuckDB syntax)
- Databricks-specific keywords auto-stripped: `USING DELTA`, `USING
  PARQUET/JSON/CSV`, `LOCATION '…'`, `TBLPROPERTIES (…)`, `PARTITIONED BY
  (col)`, `OPTIMIZE`, `VACUUM`, `ANALYZE`, `REFRESH`, `MSCK REPAIR`, `SET`,
  `USE`
- CTEs, window functions, subqueries, full aggregate surface

### dbutils
- `dbutils.widgets.get(name)` — reads from bundle variables + CLI params
- `dbutils.fs.ls(path)`
- `dbutils.secrets.get(scope, key)` (returns a placeholder)
- `dbutils.notebook.run(...)` (returns a placeholder)

### Notebooks (`.ipynb`)
- Python cells run in a namespace with `spark`, `dbutils`, `F` pre-bound
- `%sql` magic (Spark SQL → DuckDB)
- `%python` magic
- `%md` markdown (displayed, not executed)

### Unity Catalog emulation
- Three-level naming (`catalog.schema.table`)
- `spark.table("cat.sch.tbl")` and `.saveAsTable("cat.sch.tbl")`
- Stored in a single DuckDB file so it's easy to inspect / delete
- Table metadata: row counts, created/updated timestamps, owner, columns

### Data hydration
- `s3://` (requires `boto3` or bring your own local fixture)
- `abfss://`, `gs://`, `dbfs:/` (local fixture or synthetic fallback)
- Local `./data/<basename>` auto-pickup — offline-friendly

### Databricks REST API mock (for the real CLI)
- Clusters: `GET /api/2.0/clusters/list` (returns a fake cluster)
- Jobs: `POST /api/2.1/jobs/runs/submit`, `GET /api/2.1/jobs/list`,
  `GET /api/2.1/jobs/runs/get`
- SQL: `POST /api/2.0/sql/statements`, `GET /api/2.0/sql/statements/{id}`
- Unity Catalog: list catalogs / schemas / tables
- Workspace: `GET /api/2.0/workspace/list`

### Developer experience
- `dryrun` CLI with 11 commands (see section 20)
- Web dashboard with Catalog / Jobs / Runs / SQL Workbench tabs
- pytest plugin with 5 fixtures + helper asserts
- Cost savings estimator with 4 cluster profiles + cumulative ledger
- Row-level diff tracking per run (added / removed / changed rows)
- Docker image (zero host dependencies)

---

## 23. What Dry Run **does not** support yet

Being honest so you don't get surprised. Most of these exist on real
Databricks because that's where they belong — things like streaming
pipelines, DLT, and enforced governance need actual infrastructure. A
few are just things we haven't built yet and plan to. Either way, if one
of these blocks you, fall back to running on a Databricks cluster for
that step and keep using Dry Run for the rest. Open an issue if you want
us to prioritise one.

### Spark features not yet emulated
- **Structured Streaming** (`spark.readStream`, `.writeStream`) — the engine
  is batch-only for now
- **Broadcast joins / explicit join hints** — DuckDB picks its own plan
- **UDFs in Scala / Java** — Python UDFs work, JVM ones don't
- **RDD API** — only the DataFrame API is supported
- **Spark ML / MLflow** — not integrated
- **`spark.sparkContext` low-level ops** — only the `SparkSession`-level
  API is shimmed

### Delta Lake features
- No real Delta transaction log — tables are persisted as DuckDB tables
- `DESCRIBE HISTORY` returns empty
- `RESTORE TABLE … VERSION AS OF` is a no-op
- `OPTIMIZE`, `VACUUM`, `ZORDER BY` are no-ops (they're valid SQL, just not
  meaningful locally)
- Schema evolution works but isn't tracked as versioned changes

### Unity Catalog features
- **Permissions / grants are not enforced** — every table is readable by
  everyone locally
- No **row filters / column masks**
- No **lineage graph** (you can see which jobs touched which tables in the
  Runs tab, but there's no full lineage view yet)
- No **volumes** (`/Volumes/...`) — use `s3://` or local paths

### Databricks-specific
- No **DLT** (Delta Live Tables) pipelines — the `@dlt.table` decorator is
  not shimmed
- No **Databricks SQL dashboards** or **alerts** — only the `sql_task`
  query endpoint is mocked
- No **Workflows** scheduling — jobs only run when you invoke them
- No **init scripts** or **libraries** auto-install — put `pip install` in
  your README
- **Autoloader** (`cloudFiles` format) isn't handled — use plain CSV /
  Parquet reads locally

### CLI parity with `databricks` official CLI
- Not every endpoint is mocked. If you hit a 501, open an issue
- `databricks fs cp` works for small files; large multipart uploads don't

---

## 24. Roadmap

In priority order, roughly:

1. **`dryrun ci`** — a GitHub Action that runs Dry Run against PR changes
   and posts a comment with the data diff. The dream: "this PR removes 3
   rows from `gold.country_daily` and adds 1. Approve?"
2. **Real Delta via `delta-rs`** — swap the "DuckDB-as-catalog" backend
   for genuine Delta tables. Unlocks `MERGE INTO`, `UPDATE`, `DELETE`,
   `VERSION AS OF` and `DESCRIBE HISTORY` in one step.
3. **`dryrun synth`** — synthetic data generator. Say "give me 1 million
   rows like `retail.bronze.sales`" and stress-test locally.
4. **`dryrun pull-schema`** — read a table's schema from a real Databricks
   workspace and create an empty local version, so onboarding doesn't
   start with "table not found".
5. **DLT shim** — recognise `@dlt.table` decorators and wire them through.
6. **Autoloader** — watch a local folder as if it were a streaming source.
7. **Lineage graph** — visualise which jobs read/write which tables.
8. **VS Code extension** — right-click on a `.sql` file, "Run with Dry Run".

Want one of these prioritised? Open an issue and say so — that's literally
how we pick the order.

---

## What's new in 0.2.1

- `dryrun pytest` — run your test suite inside the Docker image with
  every Dry Run fixture pre-registered. No host venv required.
- Fix: `dryrun doctor` no longer crashes on the catalog probe.

## What's new in 0.2.0

- `dryrun validate` — lint your `databricks.yml` before deploying.
- `dryrun doctor` — one command to diagnose 90% of "it doesn't work" problems.
- `dryrun --version` — confirm which build you're on.
- Notebook `%run ./other_notebook` chains now work, with a shared namespace.
- Unsupported PySpark functions (e.g. `F.percentile_approx`) now fail with
  a specific workaround instead of a bare traceback.
- SQL failures surface actionable hints for the ten most common errors
  (ambiguous columns, type mismatches, missing catalogs, DELTA parse, …).
- `dryrun up` warns up-front on port conflicts and on the Colima `/tmp`
  mount quirk.

See [`CHANGELOG.md`](./CHANGELOG.md) for the full list.

---

## 25. FAQ

**Q: Is my data sent anywhere?**
No. Dry Run runs entirely on your laptop. The only network call is during
`dryrun hydrate` if you configure an S3/ADLS/GCS credential — and even
then, only a small sample is downloaded.

**Q: Can I use Dry Run in production?**
No — and it's not designed to. Databricks is where production belongs:
real scale, governance, scheduling, SLAs, team access. Dry Run's job is
to make the *development* phase faster and cheaper. Same relationship
LocalStack has to AWS: nobody runs prod Lambdas on LocalStack.

**Q: Will my team's real Databricks workspace change?**
Never. Dry Run never talks to your real workspace unless you explicitly
give it credentials during `dryrun hydrate`, and even then it only
*reads* samples — it doesn't write anything back.

**Q: Is Dry Run affiliated with or endorsed by Databricks?**
No. Dry Run is an independent open-source project. It reads the same
configuration format (`databricks.yml`) and mocks a subset of the public
[Databricks REST API](https://docs.databricks.com/api/) so your existing
tooling works unchanged. All trademarks belong to their respective
owners.

**Q: My job uses Java UDFs. Will it work?**
No — Dry Run is Java-free. Rewrite the UDF in Python (or contribute a JVM
shim!).

**Q: Why is it so much faster than Spark locally?**
Polars is single-node, columnar, vectorised, written in Rust. For datasets
that fit on one laptop (pretty much every dev dataset), it's 5–30× faster
than local Spark. DuckDB is similar for SQL.

**Q: Can I trust the cost savings number?**
It's a reasonable estimate, not a bill. It uses public Databricks rates
and assumes a single-node cluster with 3-min cold start. If your team uses
40-worker premium clusters, real savings are several times higher.

**Q: Can I use Dry Run without a `databricks.yml`?**
Yes, but then you lose the `dryrun run <job>` command. You can still use
`dryrun sql "..."`, `dryrun up` (dashboard), and the pytest fixtures.
Or run `dryrun init my_project` to scaffold one.

**Q: What happens when my real Databricks uses a feature Dry Run doesn't?**
You get a clear error pointing to the unsupported feature. Open an issue,
we'll triage. Alternative: guard the code with `if dryrun: ...` (Dry Run
injects `dryrun = True` globally in every task).

**Q: Is this open source?**
The CLI and engine are free forever. We're figuring out if there'll be a
paid "team" tier for things like shared run history and CI integrations.

**Q: How do I update Dry Run?**
```bash
docker pull varundagger/dryrun:latest
```
That's it — the next time you invoke `dryrun`, the wrapper uses the new
image.

**Q: Where do I file bugs / feature requests?**
GitHub Issues. Include the command you ran, the error message, and
`.dryrun/logs/server.log` if the dashboard was involved.

---

Made for data engineers who want a faster inner loop — and still love
Databricks for everything else.
