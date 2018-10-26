#!/bin/sh

# Generate and create terraform overrides for our update ASG test
MODULE_OVERRIDE=$(cat <<EOF
resource "aws_lambda_function" "lambda" {

    environment = {
        variables={INSTANCE_REPLACEMENT_TAG = "${CIRCLE_BRANCH}-${CIRCLE_BUILD_NUM}"}
    }
}
EOF
)

TEST_OVERRIDE=$(cat <<EOF
module "asg" {
  instance_type            = "t2.small"

  additional_tags = [
    {
      key                 = "${CIRCLE_BRANCH}-${CIRCLE_BUILD_NUM}"
      value               = true
      propagate_at_launch = true
    },
  ]
}
EOF
)

echo $MODULE_OVERRIDE > ~/module/override.tf
echo $TEST_OVERRIDE > ~/layers/test1/override.tf

# Execute the Plan and Apply to initiate the change
~/bin/plan.sh
~/bin/apply.sh

# Grab the ASG and Lambda names from terraform outputs and set env variable
cd ~/layers/test1/
export ASG=$(terraform output asg)
export LAMBDA=$(terraform output lambda)

# Execute ASG verification script.
python3 ~/bin/verify_lambda.py
