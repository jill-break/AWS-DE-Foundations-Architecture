LAB 1.1: IAM SETUP FOR DATA
ENGINEERING
PART 0: UNDERSTANDING WHY THIS MATTERS
Before we start clicking buttons, let's understand WHY we're doing this.
The Big Picture Story
Imagine you work for a company with 100+ people accessing AWS:
Data engineers need to build pipelines
Analysts need to query data
Database administrators need to manage Redshift
Finance needs to track costs
Security teams need to ensure nothing is exposed
What could go wrong if there's no access control?
David (analyst) accidentally deletes the entire S3 data lake (oops!)
Jane (new intern) can see all company financial data (security risk!)
Someone's credentials leaked, and hackers delete everything
Nobody knows who changed what resource (compliance nightmare!)
This is where IAM comes in.
What is IAM? (In Plain English)
IAM = Identity and Access Management
Think of it like a building's security system:
Without IAM:
Everyone has the master key to everything. Bad idea.
With IAM:
Everyone has only the keys they need for their job. Safe and controlled.
Your AWS Account = A Building
├─ Cloud resources (S3, Redshift, etc.) = Rooms in the building
├─ Employees = People who work there
├─ IAM Roles = Job titles (Manager, Janitor, Security Guard)
├─ IAM Policies = Rules (Managers can access all rooms, Janitors only cleaning
rooms)
└─ IAM Users = Individual people assigned job titles
Real-World Example: Data Engineering Team
Each role has EXACTLY the permissions needed, nothing more.
Why This Matters for Your Career
In 6 months: Your company will require role-based access (compliance)
In real jobs: You won't have admin access (security policy)
For interviews: "Tell me about IAM roles you've set up" is a common question
For promotion: Understanding permissions architecture shows senior thinking
PART 1: GOALS FOR THIS LAB
By the end of this lab, you will:
Understand how access control works in AWS
Create 5 different IAM roles for different purposes
Explain why each role has specific permissions
Document all roles for future reference
Apply principle of least privilege (only needed permissions)
PART 2: WHAT YOU'LL CREATE
Role 1: DataEngineerRole
Who: You (the data engineer building pipelines)
Why: Need broad access to build and manage data platforms
Permissions:
S3 (read/write everywhere in data lake)
Glue (create and run jobs)
Redshift (connect and query)
EMR (run Spark clusters)
Your Company
├─ DataEngineer Role
│ └─ Can: Create S3 buckets, run Glue jobs, query Redshift, use Lambda
│ └─ Cannot: Delete Redshift clusters, access billing, delete databases
│
├─ GlueServiceRole
│ └─ Can: Read from S3, write to S3, write logs
│ └─ Cannot: Do anything else (very restricted, for Glue jobs only)
│
├─ AnalystReadOnlyRole
│ └─ Can: Read from Redshift, read from Athena, view dashboards
│ └─ Cannot: Modify or delete anything, write data
│
└─ [Similar for other roles...]
Kinesis (manage streams)
Lambda (create functions)
CloudWatch (monitor everything)
Real-world use: Your daily work role
Role 2: GlueServiceRole
Who: AWS Glue service (not a person, a service)
Why: Glue jobs need permissions to read/write to S3 and other services
Permissions:
S3 read/write (for data processing)
CloudWatch Logs (for job logs)
Secrets Manager (to retrieve database credentials)
Real-world use: When Glue jobs run, they use THIS role's permissions
Key concept: Services assume roles just like people do. This is crucial!
Role 3: LambdaExecutionRole
Who: AWS Lambda functions (serverless code)
Why: Lambda needs permissions to access other AWS services
Permissions:
S3 (read/write)
DynamoDB (read/write)
Kinesis (read)
CloudWatch Logs (write logs)
Secrets Manager (read secrets)
Real-world use: When you write Lambda code that processes data, it runs with THIS role
Role 4: RedshiftIAMRole
Who: Redshift cluster (warehouse)
Why: Redshift needs permission to read data from S3 for COPY commands
Permissions:
S3 GetObject (read only)
CloudWatch Logs (write logs)
Real-world use: When you run COPY FROM 's3://bucket/data' , Redshift uses THIS role
Key learning: Different services need different permission levels
Role 5: AnalystReadOnlyRole
Who: Data analysts and BI team members
Why: They need to query data but shouldn't modify or delete anything
Permissions:
Redshift read-only
Athena read-only
S3 read-only
QuickSight access
Real-world use: Analysts can run reports but can't break anything
Bonus: Custom Policy (DataLakeBucketAccessPolicy)
What: A policy that ONLY allows access to specific S3 bucket
Why: Extra security - limits what data people can access
Permissions:
List and access ONLY data-lake-* buckets
DENY uploads that aren't encrypted
This is super important for compliance
Real-world use: Regulatory requirements (GDPR, HIPAA, etc.) often demand this
PART 3: THE "WHY" BEHIND DECISIONS
Why separate roles instead of one admin role for everyone?
Bad approach (all admin):
Good approach (separate roles):
Why restrict Glue/Lambda/Redshift instead of giving them
everything?
Security principle: "Principle of Least Privilege"
If a service is compromised or exploited:
Bad: Hacker gets admin access to everything
Everyone → Admin Role → Can do ANYTHING
Result: One person's mistake = disaster
Example: Dev accidentally deletes production database
Engineers → DataEngineerRole → Specific permissions only
Analysts → AnalystReadOnlyRole → Can read, can't write
Services → ServiceRoles → Only what they need to function
Result: Damage is contained, mistakes are limited
Good: Hacker can only access 1 S3 bucket and nothing else
Why encrypt uploads?
Your custom policy denies unencrypted uploads. Why?
This is how top companies enforce standards.
PREREQUISITE: CHECK THESE FIRST
Before starting, make sure you have:
1. AWS Account - You should have an AWS account already
2. AWS Management Console Access - You can log in at https://console.aws.amazon.com
3. Admin or PowerUser access - You need permissions to create IAM roles
4. Text Editor - Notepad, VS Code, or similar (to save policies)
5. Time - 3 hours uninterrupted
6. Understanding - Read Part 0-3 above first (15 minutes)
Don't have these? Go set up your AWS account first at https://aws.amazon.com
STEP 0: LOGIN TO AWS CONSOLE
Step 0.1: Open AWS Console
1. Open your web browser (Chrome, Firefox, Safari)
2. Go to: https://console.aws.amazon.com
3. You should see the AWS login page
Step 0.2: Enter Your Credentials
1. Email address field: Type your AWS account email
2. Password field: Type your AWS account password
3. Click: "Sign In" button (blue button)
4. If prompted for MFA: Enter your authenticator app code
Step 0.3: Verify You're Logged In
You should see "Welcome to AWS" with your account name in the top right
If you see "Sign In" button, you're NOT logged in. Go back to Step 0.2
Expected Result: You're now on the AWS Console home page
Compliance Requirement:
→ "All customer data must be encrypted"
→ If someone uploads unencrypted, policy BLOCKS them
→ Forces good security practices
PART 1: CREATE IAM ROLES
Understanding the Process
When we create a role, we do 3 things:
1. Choose who can USE this role (trust policy)
"This role can be used by EC2 instances"
"This role can be used by Lambda functions"
"This role can be used by Glue jobs"
2. Attach permissions (what they can do)
"This role can read from S3"
"This role can write to Redshift"
3. Name it (for future reference)
Let's start:
Role 1: DataEngineerRole
Context: This is YOUR role. You'll use it to build data pipelines. Think of this as your "job
description" in AWS.
Step 1.1: Navigate to IAM Console
1. Click the "Services" menu (top left, usually says "AWS" with menu icon)
2. Type in the search box: IAM
3. Click: "IAM" option that appears in the dropdown (it says "Identity and Access Management")
4. You're now in the IAM Console - You should see on the left sidebar "Users", "Groups",
"Roles", etc.
Why IAM Console? This is where all access control happens. It's your security control center.
Step 1.2: Create a New Role
1. Click "Roles" in the left sidebar (about 3rd option from top)
2. Click the orange "Create role" button (top right area)
3. You're now on the "Create role" page
Step 1.3: Select Trust Entity (Who Can Use This Role?)
Here's where we say "This role will be used by..."
You'll see "Select trusted entity" section with options.
1. Choose "AWS service" (first radio button option) - should already be selected
Why AWS service?
You'll eventually use this role with EC2 instances, Lambda, and other services
So we pick "AWS service" as the trust entity
2. In the "Use case" section, select: "EC2"
Why? EC2 is a common service that assumes roles
You can also assign this to people and other services later
3. Click "Next" button (bottom right)
Expected: You see "Add permissions" page
Step 1.4: Add Permissions to DataEngineerRole
Now we'll add permissions (policies) to this role.
This is where we say "This role CAN DO..."
We'll add 7 AWS managed policies. What's an AWS managed policy?
Pre-made permission set created by AWS
Covers common use cases (S3 full access, Glue full access, etc.)
Saves us from writing policies from scratch
Let's add each policy:
First policy: AmazonS3FullAccess
1. In the "Filter policies" search box, type: s3
2. In the results, find: "AmazonS3FullAccess"
What does this do? Allows all S3 actions (read, write, delete on ALL buckets)
Why? Data engineers need broad S3 access to read raw data, write processed data, etc.
3. Click the checkbox next to "AmazonS3FullAccess"
4. It should now have a checkmark ✓
Second policy: AWSGlueFullAccess
1. In the search box (clear it first), type: glue
2. Find: "AWSGlueFullAccess"
What does this do? Allows all Glue actions (crawlers, jobs, catalog, etc.)
Why? You'll create and run Glue jobs to process data
3. Click the checkbox next to it ✓
Third policy: AmazonRedshiftFullAccess
1. Clear search box, type: redshift
2. Find: "AmazonRedshiftFullAccess"
What does this do? Allows all Redshift actions (create clusters, run queries, etc.)
Why? You'll create Redshift clusters and load/query data
3. Click checkbox ✓
Fourth policy: AmazonEMRFullAccessPolicy_v2
1. Clear search box, type: emr
2. Find: "AmazonEMRFullAccessPolicy_v2"
What does this do? Allows all EMR actions (create clusters, submit jobs, etc.)
Why? EMR runs big Spark jobs for processing massive datasets
3. Click checkbox ✓
Fifth policy: AmazonKinesisFullAccess
1. Clear search box, type: kinesis
2. Find: "AmazonKinesisFullAccess"
What does this do? Allows all Kinesis actions (create streams, produce/consume data,
etc.)
Why? Kinesis handles real-time data streaming (IoT, clickstreams, etc.)
3. Click checkbox ✓
Sixth policy: AWSLambdaFullAccess
1. Clear search box, type: lambda
2. Find: "AWSLambdaFullAccess"
What does this do? Allows all Lambda actions (create functions, execute, etc.)
Why? Lambda is serverless computing for lightweight data processing
3. Click checkbox ✓
Seventh policy: CloudWatchLogsFullAccess
1. Clear search box, type: cloudwatch
2. Find: "CloudWatchLogsFullAccess"
What does this do? Allows viewing and creating logs for troubleshooting
Why? Every job produces logs; you need to read them to debug problems
3. Click checkbox ✓
You should now have 7 policies selected (you'll see them listed below the search)
4. Click "Next" button (bottom right)
Expected: You move to naming page
Step 1.5: Name Your Role
You're now on the "Name, review, and create" page.
1. In the "Role name" field, type: DataEngineerRole
Why this name? Clear, professional, describes what it's for
2. In the "Description" field, type: Role for data engineers to access S3, Glue,
Redshift, EMR, Kinesis, Lambda, and CloudWatch
Why description? In 6 months, you'll forget what this role was for. Future you will thank
current you.
3. Scroll down and review the permissions you added (should see all 7 listed)
4. Click "Create role" button (orange button, bottom right)
Expected Result: You see a success message: "The role DataEngineerRole has been created
successfully"
What just happened?
You created a role that says: "Anyone using this role can do S3, Glue, Redshift, EMR, Kinesis,
Lambda, and CloudWatch operations"
This will be YOUR role in this lab
Services will also assume it
Role 2: GlueServiceRole
Context: This is for the Glue SERVICE (not a person). When a Glue job runs, AWS will use this role
to determine what it can do.
Why separate? If someone's laptop gets hacked, they don't have direct Glue service role access.
Only when they explicitly create a Glue job (and they have permission to do that) does the job use
this role.
Step 2.1: Create the Role
1. Click "Roles" in left sidebar
2. Click "Create role" (orange button)
Step 2.2: Select Trust Entity
1. "AWS service" is already selected
2. In "Use case" dropdown, type or scroll to find: Glue
3. Click "Glue" option
Why Glue? This role will be assumed by Glue jobs, not by people or other services
4. Click "Next"
Step 2.3: Add Permissions
Now we add 4 policies. Why these specific ones?
Policy 1: AWSGlueServiceRole
What? AWS managed policy for Glue
Why? Allows basic Glue operations
1. Search box, type: glue
2. Check: "AWSGlueServiceRole"
Policy 2: AmazonS3FullAccess
What? Full S3 access
Why? Glue jobs read raw data from S3 and write processed data back to S3
1. Search box, type: s3
2. Check: "AmazonS3FullAccess"
Policy 3: CloudWatchLogsFullAccess
What? CloudWatch Logs access
Why? Glue jobs write execution logs; you need to read them for troubleshooting
1. Search box, type: cloudwatch
2. Check: "CloudWatchLogsFullAccess"
Policy 4: SecretsManagerReadWrite
What? Secrets Manager access
Why? Glue jobs often need to connect to databases using credentials (usernames,
passwords). These credentials are stored securely in Secrets Manager.
1. Search box, type: secrets
2. Check: "SecretsManagerReadWrite"
3. Click "Next"
Step 2.4: Name the Role
1. Role name: GlueServiceRole
2. Description: Service role for AWS Glue jobs to access S3, CloudWatch Logs, and
Secrets Manager
3. Click "Create role"
Expected Result: Success message
What just happened?
Created a role for Glue jobs specifically
Limited its permissions to only S3, CloudWatch, and Secrets Manager
This is "Principle of Least Privilege": Glue doesn't need Redshift access, so it doesn't have it
Role 3: LambdaExecutionRole
Context: This is for Lambda functions (serverless code). When Lambda code runs, it uses this
role's permissions.
Why important? If someone exploits your Lambda function, they can only do what this role
allows.
Step 3.1: Create the Role
1. Click "Roles" → Click "Create role"
Step 3.2: Select Trust Entity
1. "AWS service" selected
2. Use case, type: lambda
3. Click "Lambda" option
Why? This role will be assumed by Lambda functions
4. Click "Next"
Step 3.3: Add Permissions
Policy 1: AWSLambdaBasicExecutionRole
What? Allows writing logs to CloudWatch
Why? All Lambda functions produce logs; this is the minimum needed
1. Search, type: basic
2. Check: "AWSLambdaBasicExecutionRole"
Policy 2: AmazonS3FullAccess
Why? Lambda often reads/writes to S3
1. Search, type: s3
2. Check: "AmazonS3FullAccess"
Policy 3: AmazonDynamoDBFullAccess
Why? Lambda might read/write to DynamoDB (NoSQL database for real-time analytics)
1. Search, type: dynamodb
2. Check: "AmazonDynamoDBFullAccess"
Policy 4: AmazonKinesisFullAccess
Why? Lambda might process Kinesis streams (real-time data)
1. Search, type: kinesis
2. Check: "AmazonKinesisFullAccess"
Policy 5: SecretsManagerReadWrite
Why? Lambda might need database credentials
1. Search, type: secrets
2. Check: "SecretsManagerReadWrite"
3. Click "Next"
Step 3.4: Name the Role
1. Role name: LambdaExecutionRole
2. Description: Execution role for Lambda functions to access S3, DynamoDB, Kinesis,
CloudWatch Logs, and Secrets Manager
3. Click "Create role"
Expected Result: Success message
Role 4: RedshiftIAMRole
Context: This is for Redshift cluster to access S3. When you run COPY FROM 's3://bucket/data' ,
Redshift uses this role to read from S3.
Step 4.1: Create the Role
1. Click "Roles" → Click "Create role"
Step 4.2: Select Trust Entity
1. "AWS service" selected
2. Use case, type: redshift
3. Click "Redshift" option (might say "Amazon Redshift")
4. Click "Next"
Step 4.3: Add Permissions
Policy 1: AmazonS3FullAccess
Why? Redshift needs to read data from S3
1. Search, type: s3
2. Check: "AmazonS3FullAccess"
Policy 2: CloudWatchLogsFullAccess
Why? Redshift writes logs for troubleshooting
1. Search, type: cloudwatch
2. Check: "CloudWatchLogsFullAccess"
3. Click "Next"
Step 4.4: Name the Role
1. Role name: RedshiftIAMRole
2. Description: Service role for Redshift to read/write to S3 and write CloudWatch
Logs
3. Click "Create role"
Expected Result: Success message
Role 5: AnalystReadOnlyRole
Context: This is for analysts and BI teams. They need to READ data but shouldn't modify or delete
anything.
Why read-only? Analysts need insights, engineers need to build. Separating concerns reduces
risk.
Step 5.1: Create the Role
1. Click "Roles" → Click "Create role"
Step 5.2: Select Trust Entity
1. "AWS service" selected
2. Use case, type: ec2
3. Click "EC2" (we'll keep it simple for this role)
4. Click "Next"
Step 5.3: Add Permissions
Policy 1: AmazonAthenaFullAccess
What? Athena is for SQL queries on S3 data
Why? Analysts query raw data
1. Search, type: athena
2. Check: "AmazonAthenaFullAccess"
Policy 2: AmazonRedshiftReadOnlyAccess
What? Read-only Redshift access
Why? Analysts read from warehouse but shouldn't modify schemas or data
1. Search, type: redshift
2. Find: "AmazonRedshiftReadOnlyAccess" (not full access)
3. Check: it
Policy 3: AmazonQuickSightReadOnlyAccess
What? Read-only access to QuickSight (BI tool)
Why? Analysts view dashboards but don't create infrastructure
1. Search, type: quicksight
2. Check: "AmazonQuickSightReadOnlyAccess"
Policy 4: AmazonS3ReadOnlyAccess
What? Read-only S3 access
Why? Analysts can read data but not delete or overwrite
1. Search, type: s3
2. Find and check: "AmazonS3ReadOnlyAccess" (NOT full access)
3. Click "Next"
Step 5.4: Name the Role
1. Role name: AnalystReadOnlyRole
2. Description: Read-only role for analysts to access Redshift, Athena, QuickSight,
and S3
3. Click "Create role"
Expected Result: Success message
PART 2: CREATE CUSTOM IAM POLICY
Now we'll create a CUSTOM policy. Why? Because sometimes AWS managed policies are too
broad. We want to restrict access to specific buckets and enforce encryption.
Step 6: Why Custom Policies Matter
Scenario:
You have many S3 buckets
You want people to access ONLY data-lake-prod bucket
You want to PREVENT unencrypted uploads (compliance requirement)
AWS managed policies don't let you do this (they allow all buckets)
Solution: Custom policy
Step 7: Create the Policy
Step 7.1: Go to Policies
1. Click "Policies" in left sidebar
2. Click "Create policy" (orange button, top right)
Step 7.2: Choose JSON Editor
1. Click "JSON" tab (you should see "Visual", "JSON" tabs at top)
2. You see a JSON editor with empty template
What's JSON? It's a way to write machine-readable rules. It looks like:
Think of it as: "Allow [GetObject] action on [s3 resources matching pattern]"
Step 7.3: Paste the Custom Policy
1. Delete all content in the editor (Ctrl+A, then Delete)
2. Copy this policy:
{
"Statement": [
{
"Effect": "Allow",
"Action": "s3:GetObject",
"Resource": "arn:aws:s3:::my-bucket/*"
}
]
}
{
"Version": "2012-10-17",
"Statement": [
{
"Sid": "ListDataLakeBucket",
"Effect": "Allow",
What does this policy do?
1. Statement 1 (ListDataLakeBucket):
Allow listing and getting info about buckets matching data-lake-*
Why? You need to see what's in the bucket
2. Statement 2 (ReadWriteDataLakeObjects):
Allow read, write, delete on all objects in data-lake-* buckets
Why? You need to work with files
3. Statement 3 (DenyUnencryptedUploads):
DENY uploads that aren't encrypted with AES256
Why? Compliance: "All data must be encrypted"
This is DENY (not Allow) so it blocks even if other policies allow it
4. Right-click in the editor and select "Paste" (or Ctrl+V)
5. You should see the JSON policy in the editor
"Action": [
"s3:ListBucket",
"s3:GetBucketLocation"
],
"Resource": "arn:aws:s3:::data-lake-*"
},
{
"Sid": "ReadWriteDataLakeObjects",
"Effect": "Allow",
"Action": [
"s3:GetObject",
"s3:PutObject",
"s3:DeleteObject"
],
"Resource": "arn:aws:s3:::data-lake-*/*"
},
{
"Sid": "DenyUnencryptedUploads",
"Effect": "Deny",
"Action": "s3:PutObject",
"Resource": "arn:aws:s3:::data-lake-*/*",
"Condition": {
"StringNotEquals": {
"s3:x-amz-server-side-encryption": "AES256"
}
}
}
]
}
Step 7.4: Review and Create
1. Click "Next" button (bottom right)
2. Policy name: DataLakeBucketAccessPolicy
3. Description: Custom policy to access data lake S3 bucket with encryption
enforcement. Allows read/write to data-lake-* buckets only. Blocks unencrypted
uploads for compliance.
4. Click "Create policy"
Expected Result: "The policy DataLakeBucketAccessPolicy has been created successfully"
PART 3: VERIFY YOUR WORK
Step 8: Check All Roles Were Created
1. Click "Roles" in left sidebar
2. You should see all 5 roles in the list:
DataEngineerRole
GlueServiceRole
LambdaExecutionRole
RedshiftIAMRole
AnalystReadOnlyRole
If you see all 5, you're good! If not, go back and create the missing ones.
Step 9: Verify Permissions on One Role
Let's verify DataEngineerRole has all the right permissions:
1. Click "DataEngineerRole" (click on the name)
2. You should see a page with role details
3. Scroll down to "Permissions" section
4. You should see a list of all 7 policies:
AmazonS3FullAccess
AWSGlueFullAccess
AmazonRedshiftFullAccess
AmazonEMRFullAccessPolicy_v2
AmazonKinesisFullAccess
AWSLambdaFullAccess
CloudWatchLogsFullAccess
5. If all 7 are there, good! If any are missing, click "Add permissions" and add them.
PART 4: DOCUMENT YOUR SETUP
Create a text file to save all role information for future reference.
Step 10: Save Role Information
Create a file named Lab_1_1_IAM_Setup.txt and save this:
SUCCESS CRITERIA - VERIFY YOU'RE DONE
Check off each item:
=== LAB 1.1: IAM SETUP DOCUMENTATION ===
Date Created: [TODAY'S DATE]
AWS Account ID: [YOUR ACCOUNT ID - find at top right]
ROLES CREATED:
1. DataEngineerRole
Purpose: Main role for data engineers
Permissions: S3, Glue, Redshift, EMR, Kinesis, Lambda, CloudWatch
When used: Your daily work role
ARN: arn:aws:iam::[ACCOUNT_ID]:role/DataEngineerRole
2. GlueServiceRole
Purpose: For Glue jobs to use
Permissions: S3, CloudWatch Logs, Secrets Manager
When used: When Glue jobs run
ARN: arn:aws:iam::[ACCOUNT_ID]:role/GlueServiceRole
3. LambdaExecutionRole
Purpose: For Lambda functions to use
Permissions: S3, DynamoDB, Kinesis, CloudWatch Logs, Secrets Manager
When used: When Lambda code executes
ARN: arn:aws:iam::[ACCOUNT_ID]:role/LambdaExecutionRole
4. RedshiftIAMRole
Purpose: For Redshift to access S3
Permissions: S3, CloudWatch Logs
When used: When Redshift runs COPY commands
ARN: arn:aws:iam::[ACCOUNT_ID]:role/RedshiftIAMRole
5. AnalystReadOnlyRole
Purpose: For analysts to query data safely
Permissions: Redshift (read-only), Athena, QuickSight, S3 (read-only)
When used: Analyst queries and dashboards
ARN: arn:aws:iam::[ACCOUNT_ID]:role/AnalystReadOnlyRole
CUSTOM POLICIES:
1. DataLakeBucketAccessPolicy
Purpose: Restrict S3 access to data-lake buckets only
Special feature: Blocks unencrypted uploads (security enforcement)
DataEngineerRole created with 7 policies
GlueServiceRole created with proper permissions
LambdaExecutionRole created with proper permissions
RedshiftIAMRole created with S3 access
AnalystReadOnlyRole created with read-only permissions
All 5 roles visible in Roles list
DataLakeBucketAccessPolicy custom policy created
Documentation file created and saved
If all checked ✓, you've completed Lab 1.1!
PART 5: CLEANUP - TEAR DOWN TO SAVE COSTS
IMPORTANT: IAM is FREE, so you don't need to delete these roles. However, if you delete the role:
WARNING: Don't delete until you complete Labs 1.2 and 1.3, because the roles are used there!
When to delete (after ALL 3 labs):
1. Only delete if you created test resources you no longer need
2. Do NOT delete the roles if you want to continue with next labs
3. These roles cost NOTHING to keep
If you want to keep everything:
Just leave the roles as-is
They cost $0/month (IAM is always free)
They'll be useful for Tier 2 labs
WHAT YOU LEARNED
What IAM is and why it matters
Principle of Least Privilege (only permissions needed)
Different roles for different purposes (engineers, services, analysts)
How to create and configure IAM roles
What AWS managed policies are
How to write custom policies in JSON
How services assume roles (not just people) 