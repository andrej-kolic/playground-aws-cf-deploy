# Simple S3 Website Deployment with CloudFormation and GitHub Actions

This project contains a simple setup to automatically deploy a static HTML website to an AWS S3 bucket using AWS CloudFormation for infrastructure provisioning and GitHub Actions for continuous deployment.

## Project Structure

.
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions workflow
├── src/
│   └── index.html        # Your simple HTML file
├── template.yml            # CloudFormation template
└── package.json            # Node.js project file

## Prerequisites: AWS & GitHub Setup

Before the GitHub Actions workflow can run, you need to set up a trust relationship between your AWS account and your GitHub repository. This is done using an OIDC Identity Provider and an IAM Role.

### Step 1: Create the OIDC Identity Provider in AWS IAM

1.  Go to the **IAM** service in your AWS Console.
2.  In the navigation pane, go to **Identity providers**.
3.  Click **Add provider**.
4.  For the provider type, select **OpenID Connect**.
5.  For the **Provider URL**, enter: `https://token.actions.githubusercontent.com`
6.  Click **Get thumbprint** to verify the server certificate.
7.  For the **Audience**, enter: `sts.amazonaws.com`
8.  Click **Add provider**.

### Step 2: Create the IAM Role for GitHub Actions

This role will grant GitHub Actions the specific permissions it needs to create AWS resources and upload files.

1.  Go to the **IAM** service in your AWS Console.
2.  In the navigation pane, go to **Roles** and click **Create role**.
3.  For the trusted entity type, select **Web identity**.
4.  Choose the Identity provider you just created (`token.actions.githubusercontent.com`).
5.  For the **Audience**, select `sts.amazonaws.com`.
6.  For the **GitHub organization/repository**, enter your details. You can make it specific to one repository.
    * **Organization**: Your GitHub username or organization name (e.g., `my-github-username`).
    * **Repository**: The name of your repository (e.g., `my-aws-deploy-project`).
    * **Branch (Optional but recommended)**: `main`.
7.  Click **Next**.
8.  On the **Add permissions** page, click **Create policy**. A new browser tab will open. In this new tab, switch to the **JSON** editor and paste the following policy. **Remember to replace `YOUR_UNIQUE_BUCKET_NAME` with the actual unique name you will use for your S3 bucket.**

    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "cloudformation:CreateUploadBucket",
                    "cloudformation:DescribeStacks",
                    "cloudformation:CreateStack",
                    "cloudformation:UpdateStack",
                    "cloudformation:DeleteStack",
                    "cloudformation:GetTemplateSummary"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:ListBucket",
                    "s3:DeleteObject",
                    "s3:GetBucketLocation",
                    "s3:CreateBucket",
                    "s3:PutBucketPolicy",
                    "s3:PutBucketWebsite"
                ],
                "Resource": [
                    "arn:aws:s3:::YOUR_UNIQUE_BUCKET_NAME",
                    "arn:aws:s3:::YOUR_UNIQUE_BUCKET_NAME/*"
                ]
            }
        ]
    }
    ```

9.  Click **Next: Tags**, then **Next: Review**.
10. Give the policy a name (e.g., `GitHubActions-S3-CFN-Policy`) and click **Create policy**.
11. Close the policy creator browser tab and return to the **Create role** tab. Refresh the list of policies and select the policy you just created.
12. Click **Next**.
13. Give the role a name (e.g., `GitHubActions-S3-Deploy-Role`).
14. Review the details and click **Create role**.
15. Click on the role you just created and copy its **ARN**. You will need this for the next step.

### Step 3: Create GitHub Repository Secrets

1.  In your GitHub repository, go to **Settings** > **Secrets and variables** > **Actions**.
2.  Click **New repository secret** and add the following secrets:
    * `AWS_REGION`: The AWS region where you want to deploy (e.g., `us-east-1`).
    * `AWS_ROLE_TO_ASSUME`: The ARN of the IAM role you created in Step 2.
    * `S3_BUCKET_NAME`: The globally unique name for your S3 bucket (e.g., `my-unique-website-bucket-12345`). This **must match** the name you used in the IAM policy.

Now you are ready to commit the files and the deployment will run automatically.
