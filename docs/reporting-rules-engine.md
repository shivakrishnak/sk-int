# Reporting & Rules Engine Interview Guide

## 1. Overview
At 12+ YOE as a Staff+ engineer, you are expected to design **scalable reporting systems** and **adaptive business rules engines**—two domains that intersect when turning raw data into actionable insights under complex, frequently changing business constraints. This guide covers:

- **Reporting** – reporting architecture, data warehouse/lake patterns, batch vs real-time, OLAP, data modeling for analytics, ETL pipelines, visualization integration, query optimization at scale, multi-tenancy, and compliance.
- **Rules Engine** – business rules management (BRMS), Rete algorithm, forward/backward chaining, decision tables, rule authoring, embedding vs service, testing, governance, and when to use code vs rules engine.

Real-world systems: executive dashboards, real-time fraud detection, regulatory compliance reporting, dynamic pricing engines, insurance underwriting, and personalized marketing platforms.

## 2. Deep Knowledge Structure

### 2.1 Reporting Systems

#### Reporting Architecture Patterns
- **Classic BI**: ETL from transactional DB → Data Warehouse (star/snowflake schema) → OLAP cubes → Reporting tool (Tableau, Power BI).
- **Data Lake**: raw data in object storage (S3) → ETL/ELT → query engines (Presto, Spark SQL, Athena).
- **Embedded Reporting**: report generation within the application; tools like JasperReports, BIRT, custom APIs.
- **Real-time Reporting**: change data capture (CDC) → stream processing (Kafka Streams, Flink) → real-time OLAP (ClickHouse, Druid, Pinot) → live dashboards.
- **Lambda/Kappa Architecture**: batch layer + speed layer; Kappa uses streaming only.

#### Data Modeling for Analytics
- **Star Schema**: fact tables (events, transactions) referencing dimension tables (time, product, customer); denormalized for speed.
- **Snowflake Schema**: normalized dimensions; saves storage but more joins.
- **Data Vault**: hub, link, satellite tables for agility and auditing.
- **Dimensional Modeling** (Kimball): identify business processes, declare grain, choose dimensions and facts.
- **Cube / OLAP**: pre-aggregated multidimensional views; MDX queries.

#### ETL vs ELT
- **ETL**: extract, transform, load (traditional, transformation before load).
- **ELT**: load raw, transform in data warehouse (modern, cloud-native with BigQuery, Snowflake).
- **Incremental loading**: CDC with Debezium, timestamp/version-based, merge/upsert strategies.
- **Data quality checks**: schema validation, freshness, completeness, anomaly detection.

#### Query Optimization for Reports
- **Materialized views** and pre-aggregation for common dashboards.
- **Partitioning and clustering** on time/customer columns.
- **Columnar storage** (Parquet, ORC) for analytics.
- **Caching**: query result cache, Redis cache layer.
- **Indexing** in OLAP databases (bitmap, bloom filter).
- **Cost-based optimization**: understanding query plans, statistics, CBO.

#### Reporting at Scale
- **Multi-tenancy**: row-level security, tenant-specific schemas, or separate databases.
- **Data isolation** and compliance (GDPR, CCPA).
- **Scalable export**: asynchronous report generation with job queue, S3 pre-signed URLs.
- **Scheduled vs. Ad-hoc**: scheduler (Quartz, Airflow) for periodic; on-demand via UI.
- **Failures**: long-running queries impacting production; bad query causing OOM.

#### Tools and Technologies
- **Data Warehouses**: Snowflake, BigQuery, Redshift.
- **Lakehouse**: Databricks, Iceberg, Delta Lake.
- **Real-time OLAP**: Apache Druid, ClickHouse, Apache Pinot.
- **Embedded**: JasperReports, BIRT, Apache POI.
- **Dashboards**: Tableau, Power BI, Apache Superset, Metabase.
- **ETL orchestrators**: Apache Airflow, Dagster, Prefect.

### 2.2 Rules Engine

#### Core Concepts
- **Business Rules Management System (BRMS)**: externalize decision logic from application code.
- **Rule**: a set of conditions and actions (if-then).
- **Fact**: data object evaluated by rules.
- **Working Memory**: facts inserted into the engine.

#### Rule Execution Algorithms
- **Forward Chaining (Rete)**: pattern matching network; facts propagate through alpha nodes (field constraints) and beta nodes (joins). Efficient for many rules and facts.
  - **Rete-DAG**: nodes share conditions, reducing redundancy.
  - **Conflict resolution**: salience, rule ordering, recency, specificity.
- **Backward Chaining**: goal-driven; starts with a hypothesis and works backward to find supporting facts. Used in diagnosis/validation.
- **Sequential**: simple priority-ordered rules evaluated sequentially; less powerful but simpler.

#### Rule Authoring & Management
- **Decision Tables**: spreadsheet-like rules; easy for business analysts.
- **DRL (Drools Rule Language)**: Java-like syntax.
- **DMN (Decision Model and Notation)**: standard for modeling decisions; graphical and XML.
- **Natural language rules** via constrained English.
- **Versioning, approval workflow**, and audit trail.
- **Testing**: scenario testing, rule unit tests, impact analysis.

#### Integration Architectures
- **Embedded Engine**: Drools KieContainer in JVM; rules loaded at startup; in-process evaluation, fast but coupled.
- **Rule Service**: separate service exposing REST/gRPC; fact payloads as JSON; stateless, scalable.
- **Event-Driven**: rules engine evaluates on message/event; CQRS where commands update state, rules engine emits decisions.
- **Hybrid**: decision tables in code for simple rules (strategy pattern), BRMS for complex rules.

#### Performance Considerations
- **Rete network memory**: heavy working memory can blow heap; use stateless sessions for request/response patterns.
- **Compilation**: rule compilation to Java bytecode for performance.
- **Hot deployment**: loading/reloading rules without restart; KieScanner polling.
- **Shadow testing**: replay production traffic against new rule version before rollout.

#### When to Use vs Avoid
- **Use when**: business logic changes frequently, non-programmers need to author, complex regulatory compliance, many interrelated rules.
- **Avoid when**: simple static rules, performance-critical where overhead unacceptable, team lacks BRMS expertise.
- **Alternative**: Strategy/Chain of Responsibility patterns, decision trees in code, SpEL expressions, workflow engines (Camunda for process, but rules for decisions).

#### Governance & Testing
- **Rule testing**: JUnit with KieSession, scenario testing with decision table input/output.
- **Canary deployment**: evaluate new rule set on subset of traffic.
- **Monitoring**: rule fire count, latency, conflicts, exceptions.
- **Lineage**: which rule version made which decision (audit).

### 2.3 Synergies Between Reporting & Rules
- **Compliance reports** often need to apply rules to data (e.g., calculate tax, detect suspicious activity).
- **Real-time rules engine** can feed real-time reporting dashboards (e.g., fraud alert counts).
- **Decision audit** can be stored in data warehouse for analytics on rule effectiveness.

## 3. Code & Config Examples

### Reporting SQL (Analytics)
```sql
-- Materialized view for daily sales
CREATE MATERIALIZED VIEW daily_sales AS
SELECT date_trunc('day', order_date) AS day,
       product_id, count(*) AS orders, sum(amount) AS revenue
FROM orders
GROUP BY day, product_id;

-- Window function for running total
SELECT order_date, amount,
       SUM(amount) OVER (ORDER BY order_date) AS running_total
FROM orders;
```

### ETL with Spark (Simplified)
```java
Dataset<Row> df = spark.read().format("jdbc")
    .option("url", "jdbc:postgresql://...")
    .option("dbtable", "orders")
    .load();
df.createOrReplaceTempView("orders");
spark.sql("SELECT customer_id, sum(amount) as total FROM orders GROUP BY customer_id")
    .write().format("parquet").save("s3://bucket/reports/");
```

### Drools Rule Example
```java
// Fact
public class Applicant {
    private String name;
    private int age;
    private boolean criminalRecord;
    // getters/setters
}

// Rule DRL file (loan-approval.drl)
rule "Reject underage"
    when
        $a: Applicant(age < 18)
    then
        $a.setApproved(false);
end

rule "Reject criminal record"
    when
        $a: Applicant(criminalRecord == true)
    then
        $a.setApproved(false);
end

rule "Approve others"
    when
        $a: Applicant(approved == true) // default true
    then
        System.out.println("Approved: " + $a.getName());
end

// Java integration
KieSession session = kieContainer.newKieSession();
Applicant applicant = new Applicant("John", 25, false);
session.insert(applicant);
session.fireAllRules();
```

```yaml
# Airflow DAG for daily report
schedule_interval: "0 6 * * *"
tasks:
  - name: extract_orders
    operator: PostgresOperator
    sql: "SELECT * FROM orders WHERE date = '{{ ds }}'"
  - name: transform_and_load
    operator: SparkSubmitOperator
    main_class: com.example.ReportETL
```

## 4. Interview Intelligence

### Topic: Design a Real-time Dashboard for Business Teams

#### ❌ Mid-level Answer
“I’d use a reporting tool like Tableau connecting to a replica. For real-time, schedule frequent refreshes.”

#### ✅ Senior Answer
“I’d use CDC (Debezium) to stream OLTP changes to Kafka, then a stream processor to aggregate, and store in a real-time OLAP database like ClickHouse. The dashboard queries ClickHouse, providing millisecond latency on fresh data.”

#### 🚀 Staff-level Answer
“For a real-time executive dashboard, I’d architect a Lambda pattern: batch layer in Snowflake for daily historical accuracy, and a speed layer using Kafka Streams+Kafka Connect to materialize aggregates into Apache Pinot. We’d use a semantic layer (Cube.js) to provide consistent metrics and handle caching. Multi-tenant isolation via dataset-level ACLs. For write-heavy source, we’d pre-aggregate in the stream app with exactly-once semantics. Failures: speed layer lag monitoring alerts, batch reconciliation to correct errors. Adoption: embedded charts via iframe with row-level security propagating from main app JWT. This reduced query latency from 30s to 200ms.”

### Topic: When to Use a Rules Engine vs Code

#### ❌ Mid-level Answer
“We use Drools because business wants to change rules.”

#### ✅ Senior Answer
“I analyze the volatility and complexity. If rules change weekly and involve many combinations, a BRMS like Drools is suitable. We embed it and load rules from a versioned store, allowing business to author in decision tables. If rules are simple and stable, strategy pattern is enough.”

#### 🚀 Staff-level Answer
“I created a decision framework: for static rules (e.g., tax brackets) we use code. For volatile rules with 50+ conditions, we use Drools with DMN modeling. We built a rule management lifecycle: author, test in sandbox, deploy via CI/CD as versioned artifacts. We monitor rule fire rates and latency. We also built an impact analysis tool: given a set of facts, which rules will fire? This empowers analysts before editing. For performance, we compile rules to executable model (KieBase) and use stateless sessions. Trade-offs: Drools memory footprint; we capped working memory size and used incremental fact insertion for event-driven evaluation.”

## 5. High ROI Questions
- Design a reporting system for 100M daily transactions.
- Explain the differences between a Data Warehouse, Data Lake, and Lakehouse.
- How do you implement real-time analytics using CDC and streaming?
- What is a star schema, and when would you denormalize further?
- How would you optimize a slow dashboard query?
- Explain the Rete algorithm and its computational complexity.
- Compare forward and backward chaining with examples.
- How to combine a rules engine with an event-driven microservice?
- How to test and version business rules?
- Multi-tenant reporting design with data isolation.
- How to handle failover and disaster recovery for reporting data?
- What are the pitfalls of letting business users author rules directly?

**Tricky Follow-ups:**
- “Your dashboard query is scanning too much data despite partitioning. What else can you do?”
- “A business rule deployment caused a production outage. How do you prevent next time?” (shadow testing, canary, rollback)
- “How do you ensure reporting data is consistent with operational data?”

## 6. Cheat Sheet (Revision)
- **Reporting**: star schema for analytics; columnar storage; materialize aggregates; partitioning.
- **Real-time**: CDC → Kafka → stream aggregate → OLAP (Druid/Pinot/ClickHouse).
- **Rules Engine**: Rete network for efficient pattern matching; use when rules volatile; DMN for standards; test thoroughly; monitor fire rate.
- **Integration**: embed or service; stateless sessions for request/response; CQRS for event-driven.
- **Tools**: Snowflake/BigQuery, Airflow, dbt for transforms, Drools for rules, Jasper for embedded reports.

---

### 🎤 Communication Training
- “When designing a reporting system, I start with user questions, define metrics and dimensions, then design the data model to answer them efficiently, choosing between batch and real-time based on freshness requirements.”
- “Rules engines are powerful but can be a footgun. I emphasize a robust CI/CD pipeline with automated testing of rules, and always have a fallback.”

### 📈 Personalised Self-Assessment (12 YOE)
- **Strong areas**: likely familiar with data modeling and maybe basic rules, some reporting.
- **Hidden gaps**: real-time OLAP (ClickHouse, Pinot), deep Rete understanding, DMN standard, regulatory compliance complexities.
- **Overconfidence risks**: underestimating rules engine complexity; assuming reporting is just a SELECT query; not planning for scale and multi-tenancy.

Next topic: "next" for **Behavioral**.