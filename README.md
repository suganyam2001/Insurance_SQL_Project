SQL Database Project: Insurance Data Analysis & Infrastructure

Project Overview
This project involves analyzing insurance data to generate a monthly commission report for Wild West AB, 
based on specific eligibility criteria and commission rules. The deliverables include a detailed SQL logic explanation and 
aggregated monthly reports from January 2024 to August 2024, along with additional analysis insights.


Project Data
The project is based on four key datasets:

Portfolio Data: Contains details of current and historical insurance policies.
Policy Data: Provides metadata about each policy, including status and key dates.
Policy Transactions: Logs transactional changes for each policy.
Sales Organization Data: Includes sales agent details and sales channels.


Commission Rules
Policies must meet the following criteria:

Portfolio Code: Either WILDWEST-2 or WILDWEST-3.
Duration: The portfolio code must apply throughout the policy's lifetime.
Product Scope: Only products Product 1–8 and Product 13–31.
Payment Status: Policy premiums must be paid.
Sales Channel:
Outbound Sales or Internet Sales: Portfolio code = WILDWEST-3
Inbound Sales: Portfolio code = WILDWEST-2
Commission Rates:

First 1500 policies: 12% of the annual premium.
Policies beyond 1500: 14% of the annual premium.
Clawbacks:

For cancelled policies, the commission is proportional to the active policy term.


Deliverables
SQL Logic:

Queries to filter and join datasets.
Calculations for commissions and clawbacks.
Aggregations for monthly reports.

Monthly Reports:

Timeframe: January 2024 – August 2024.
Metrics:
Total policies sold.
Total commissions paid.
Total clawbacks applied.

Additional Analysis:

Insights and trends in policy sales, cancellations, and commissions.
