# AWS ABC project
ABC project is a simple cloudformation script and bash test suite for Haproxy -> WebServers high availability solution

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites
```
Bash - 4.x
Python - 2.7.x
aws-cli - 1.11.115
```

## Running the ABC project

#### I. Preparation steps
Modify `parameters.json` according to your aws infrastructure, you have to specify
`KeyName`, `SubnetId` `VpcId` - VPC must be public and `privateIp[A-C]` addresses for each of the hosts

#### II. Execution steps
From the root directory execute the bash script

```
bash run.sh [path_to_json_template] [path_to_json_parameters] [stack_name]
```

* `path_to_json_template` - cloudformation template json file path, default to `file://cf.json`
* `path_to_json_parameters` - cloudformation parameters json file path, default to `file://parameters.json`
* `stack_name` - name of the stack, default to `abc`

During the execution script will perform several checks:
* check that both B and C are healthy
* check that B is working when C was stopped
* check that C is working when B was stopped
* check again that B and C are healthy

## Deployment
Deployment could be accomplished with this one-linear

```
mkdir -p $HOME/deploy && \
git clone git@github.com:eselyavka/aws_examples.git $HOME/deploy && \
cd $HOME/deploy/aws_load_balancer
```

## Troubleshooting and additional testing
To get ssh access to particular host you can retrieve it's public IP address with the command below

```
aws ec2 describe-instances \
--filters 'Name=instance-state-name,Values=running' \
'Name=tag:Name,Values=LETTER' \
--query 'Reservations[*].Instances[*].PublicIpAddress' \
--output=text
```

* `LETTER` - one of the letter from the set - **A**, **B** or **C**

## Uninstall
When you are done with the testing, invoke the command below to delete a stack

```
aws cloudformation delete-stack --stack-name <stack_name> && \
rm -rf $HOME/deploy
```

## Version
`1.0.0`

## Authors
* **Evgenii Seliavka** - *Complete work*
