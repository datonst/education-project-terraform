# GITHUB ACTION FLOW

**tf-apply.yml**
1. Trigger when:
   1. workflow_dispatch(Manual click)
   2. Pull request on branch main
2. Missions:
   1. Terraform Plan
   2. Create an issue to manual approve
   3. Terraform **Apply** or **Denied** after issue confirmed

tf-drift.yml

**tf-infracost.yml**
1. Trigger when:
   1. Pull request on branch main
2. Missions:
   1. Check cost when we apply new changes of code

**tf-plan.yml**
1. Trigger when:
   1. Pull request on branch main
2. Missions:
   1. Terraform init & fmt
   2. Terraform Plan

**tf-unit-tests.yml**
1. Trigger when:
   1. Pull request on branch main
2. Missions:
   1. Terraform init & fmt
   2. Checkov action
