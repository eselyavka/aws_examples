# AWS ABC project
ABC project is a simple cloudformation script and bash test suite for Haproxy -> WebServers high availability solution

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites
```
Bash - 4.x
Python - 2.7
aws-cli/1.11.115
```

## Running the ABC project

#### I. Preparation steps
Modify `parameters.json` according your aws infrastructure, you have to specify `KeyName`, `VpcId`, `subnetId` inside this VPC,
 VPC must be public, `privateIp` addresses for each of the hosts

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
git clone git@github.com:eselyavka/aws_examples.git && \
cd aws_load_balancer
```

## Uninstall
When you are done with the testing just invoke
```
aws cloudformation delete-stack --stack-name <stack_name>

```

## Versioning
`1.0.0`

## Authors
* **Evgenii Seliavka** - *Complete work*
