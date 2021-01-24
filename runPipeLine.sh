#!/bin/bash

echo "*******************************************************************************************************************"
echo "* This pipeline will deploy a static website in an S3 bucket                                                      *"
echo "* The S3 bucket will be secured as it will be configured as private                                               *"
echo "* The S3 bucket will allow cloudFront to access the private S3 index page                                         *"
echo "* S3 cannot be placed within a VPC but can be accessed via a VPC endpoint - Alternitavely I have used CloudFront  *"
echo "*******************************************************************************************************************"
echo ""
#delete old s3 bucket
echo "attempting to delete s3 in case it exists - this might error as i'm not checking if it exists"
echo "============================================================================================"
aws s3 rb s3://technical-test-bucket --force
sleep 5
echo "============================================================================================"

#delete cloudformation stack in case it exists. for testing purposes.
echo "attempting to delete the cloudFormation stack in case it exists - this might error as i'm not checking if it exists"
echo "============================================================================================"
aws cloudformation delete-stack --stack-name cloudfront-s3-stack
stackStatus=$(aws cloudformation describe-stacks --stack-name cloudfront-s3-stack --query 'Stacks[].StackStatus' --output text)
while [[ ${stackStatus} == "DELETE_IN_PROGRESS" ]]
do
  echo ${stackStatus}
  sleep 5
  stackStatus=$(aws cloudformation describe-stacks --stack-name cloudfront-s3-stack --query 'Stacks[].StackStatus' --output text)
done
echo "============================================================================================"

#run new cloudFormation stack
echo "Start creating the infrastructure"
echo "============================================================================================"
aws cloudformation deploy --stack-name cloudfront-s3-stack --template-file cloudFormation-cloudFront.yaml
stackStatus=$(aws cloudformation describe-stacks --stack-name cloudfront-s3-stack --query 'Stacks[].StackStatus' --output text)
while [[ ${stackStatus} == "CREATE_IN_PROGRESS" ]]
do
  echo ${stackStatus}
  sleep 5
  stackStatus=$(aws cloudformation describe-stacks --stack-name cloudfront-s3-stack --query 'Stacks[].StackStatus' --output text)
done
echo "============================================================================================"

#upload index.html to the s3 bucket
echo "Start uploading the website to the S3 bucket"
echo "============================================================================================"
if [[ ${stackStatus} == "CREATE_COMPLETE" ]]
then
  aws s3 cp index.html s3://technical-test-bucket
else
  echo "couldn't upload index file as infrastructure wasn't created properly"
fi
echo "============================================================================================"
