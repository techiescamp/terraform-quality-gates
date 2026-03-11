# Trunk-Based CI/CD Workflow Guide

This document outlines the standard operating procedure for our Trunk-Based Deployment model, where the `main` branch serves as the single source of truth for all environments. 

There are no long-lived `develop` or `production` branches. Infrastructure is deployed progressively: **Dev** -> **Staging** -> **Production** using automated triggers and manual gates.

---

## 🚀 1. Developing a New Feature

When building a new module, updating an environment configuration, or writing general IaC changes, you will branch off `main`.

1. **Ensure your local `main` is up-to-date:**
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create a new feature branch:**
   ```bash
   git checkout -b feature/add-new-vpc
   ```

3. **Write your Terraform/Terragrunt code and commit:**
   ```bash
   git add .
   git commit -m "feat: Add new VPC module configuration"
   ```

4. **Push the branch to GitHub:**
   ```bash
   git push -u origin feature/add-new-vpc
   ```

---

## 🛡️ 2. PR Quality Gates (Validation)

To integrate your code, you must open a Pull Request (PR) against the `main` branch. 

When you open the PR in the GitHub UI, the **PR Quality Gates** pipeline (`pr-checks.yml`) will automatically run:
* `terragrunt run-all plan` (Dry-run of changes)
* `tflint` (Best practices linter)
* `checkov` (Security and compliance scanner)
* `terraform-docs` (Auto-generation of module documentation)

*You cannot merge the PR until these automated checks pass and a team member approves the code review.*

---

## 🏗️ 3. Continuous Delivery (Dev & Staging)

Once your PR is approved and merged into `main`, the **Deployment Pipeline** (`deploy.yml`) instantly kicks off.

1. **Auto-Deploy to `dev`:** 
   The pipeline automatically runs `terragrunt run-all apply` against the `environments/dev` directory. Your infrastructure is now live in the Development environment for smoke testing.

2. **Manual Gate to `staging`:**
   Once the `dev` deployment succeeds, the pipeline **PAUSES**. It requires manual sign-off before touching the Staging environment.
   * Go to the **Actions** tab in GitHub.
   * Open the running workflow.
   * Click **Review Deployments** and approve it.
   * The pipeline resumes and runs `terragrunt run-all apply` against the `environments/staging` directory. You can now run integration tests.

---

## 🚢 4. Releasing to Production

Code merged to `main` **never** deploys to Production automatically. 

Once the changes in `staging` have been fully tested and management gives sign-off for a live release, you trigger the Production deployment by creating a Git Release Tag.

1. **Ensure you are on `main` and fully updated:**
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create a Semantic Version tag (e.g., v1.0.0, v1.1.0, v2.0.0):**
   ```bash
   git tag v1.0.0
   ```

3. **Push the tag to GitHub:**
   ```bash
   git push origin v1.0.0
   ```

Once that tag is pushed, the **Deployment Pipeline** wakes up, *skips* the Dev and Staging jobs entirely, and natively runs `terragrunt run-all apply` against the `environments/prod` directory.

---

## 🚑 5. Hotfixes

If a critical bug is found in Production that needs an immediate fix:

1. Branch *directly* off `main`:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b hotfix/fix-security-group
   ```
2. Commit and push the fix, then open a fast-tracked PR to `main`.
3. Once merged to `main`, it will auto-deploy to Dev, and you can approve it to Staging.
4. Finally, tag the commit with a patch version to release to Prod immediately:
   ```bash
   git pull origin main
   git tag v1.0.1
   git push origin v1.0.1
   ```
