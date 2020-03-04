#!/bin/sh

rm -f ~/workspace/terraform.*.plan

# Generate and create terraform overrides for our update ASG test
cat > ~/module/override.tf <<EOF
resource "aws_lambda_function" "lambda" {

    environment = {
        variables={INSTANCE_REPLACEMENT_TAG = "${CIRCLE_BRANCH}-${CIRCLE_BUILD_NUM}"}
    }
}
EOF

cat > ~/layers/test1/override.tf <<EOF
module "asg" {

  instance_type = "t2.small"

  tags = {
    "${CIRCLE_BRANCH}-${CIRCLE_BUILD_NUM}" = true
  }
}
EOF

# Execute the Plan and Apply to initiate the change
~/bin/plan.sh
~/bin/apply.sh

# Grab the ASG and Lambda names from terraform outputs and set env variable
cd ~/layers/test1/
export ASG=$(terraform output asg)
export LAMBDA=$(terraform output lambda)

# Execute ASG verification script.
python3 ~/bin/verify_lambda.py
